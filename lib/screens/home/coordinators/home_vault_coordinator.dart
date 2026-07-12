import 'dart:async';

import 'package:path/path.dart' as p;

import '../../../core/ports/registry_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/vault_change.dart';
import '../../../core/ports/vault_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/library_theme.dart';
import '../../../services/archive_index_manager.dart';
import '../../../services/entitlement_service.dart';
import '../../../services/library_theme_preferences.dart';
import '../../../services/record_link_index_service.dart';
import '../../../services/event_ledger_service.dart';
import '../../../core/archiving/vault_ledger_event.dart';
import '../../../services/user_preferences.dart';
import '../../../services/user_registry_preferences.dart';
import '../home_auto_archive.dart';
import '../home_vault_loader.dart';

/// 볼트·사용자 설정·auto-archive (E2-2).
///
/// Bounded Home Read Closure: interactive Vault watch applies precise path
/// updates only. [loadItems] remains an explicit legacy acquisition; it must
/// not rebuild the full link index (repair uses [rebuildLinkIndexForRepair]).
class HomeVaultCoordinator {
  HomeVaultCoordinator({
    required this.vault,
    required this.registry,
    required this.userCatalog,
    required this.isMounted,
    required this.scheduleRebuild,
    required this.onVaultItemsSynced,
    required this.prefetchRegistry,
  }) {
    eventLedger = EventLedgerService(vault: vault);
    linkIndex = RecordLinkIndexService.shared;
  }

  final VaultPort vault;
  final RegistryPort registry;
  final UserCatalogPort userCatalog;
  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final void Function(List<AkashaItem> items) onVaultItemsSynced;
  final Future<void> Function() prefetchRegistry;

  List<AkashaItem> items = [];
  bool _hasLoadedItems = false;
  String displayName = UserPreferences.defaultDisplayName;
  bool autoArchiveRegistry = false;
  LibraryTheme libraryTheme = LibraryTheme.classic;

  /// Bumped when link index memory changes — preview connection sections.
  int linkIndexRevision = 0;

  /// Bumped when precise watch cannot describe the change set (repair UX).
  int vaultReconciliationRevision = 0;

  StreamSubscription<VaultChangeBatch>? vaultChangeSubscription;
  Timer? vaultReloadDebounce;

  late final EventLedgerService eventLedger;
  late final RecordLinkIndexService linkIndex;

  Future<void> initService() async {
    await vault.init();
  }

  Future<void> loadPreferences() async {
    displayName = await UserPreferences.getDisplayName();
    autoArchiveRegistry = await UserPreferences.isAutoArchiveRegistryEnabled();
    await UserRegistryPreferences.instance.load();
    await EntitlementService.instance.load();
    libraryTheme = await LibraryThemePreferences.load();
    if (isMounted()) scheduleRebuild(() {});
  }

  /// Explicit legacy complete-item load (vault settings / rare surfaces).
  /// Does **not** full-rebuild the link index.
  Future<void> loadItems() async {
    final loadedItems = await HomeVaultLoader.loadItems(vault);
    await userCatalog.load();
    if (!isMounted()) return;
    scheduleRebuild(() {
      items = loadedItems;
      _hasLoadedItems = true;
    });
    onVaultItemsSynced(loadedItems);
    await eventLedger.append(
      VaultLedgerEvent(
        type: VaultLedgerEventType.vaultReloaded,
        at: DateTime.now().toUtc(),
        meta: {'itemCount': loadedItems.length},
      ),
    );
  }

  /// Loads the legacy complete-item surface only when a caller explicitly
  /// enters a Home area that has not yet moved to bounded queries.
  Future<void> ensureItemsLoaded() =>
      _hasLoadedItems ? Future.value() : loadItems();

  bool get hasLoadedItems => _hasLoadedItems;

  /// Explicit repair / maintenance only (C-02).
  Future<void> rebuildLinkIndexForRepair({List<AkashaItem>? vaultItems}) async {
    await linkIndex.rebuildIndex(
      userCatalog: userCatalog,
      vaultItems: vaultItems ?? items,
      onRebuilt: (stats) => eventLedger.append(
        VaultLedgerEvent(
          type: VaultLedgerEventType.linkIndexRebuilt,
          at: DateTime.now().toUtc(),
          meta: stats,
        ),
      ),
    );
    if (isMounted()) {
      scheduleRebuild(() => linkIndexRevision++);
    }
  }

  /// @deprecated Use [rebuildLinkIndexForRepair] — kept for call-site migration.
  Future<void> rebuildLinkIndex({List<AkashaItem>? vaultItems}) =>
      rebuildLinkIndexForRepair(vaultItems: vaultItems);

  Future<void> applyVaultChange(VaultChangeBatch change) async {
    final vaultPath = this.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return;

    if (!change.hasPrecisePaths) {
      if (isMounted()) {
        scheduleRebuild(() => vaultReconciliationRevision++);
      }
      return;
    }

    final manager = ArchiveIndexManager(linkIndex: linkIndex);
    for (final entry in change.changes) {
      if (!_isMarkdownRelativePath(entry.relativePath)) continue;
      final absolutePath = p.normalize(p.join(vaultPath, entry.relativePath));
      if (entry.kind == VaultPathChangeKind.delete) {
        await manager.removeRecord(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        _removeLoadedItemByAbsolutePath(absolutePath);
      } else {
        await manager.updateChangedRecord(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
          userCatalog: userCatalog,
          vaultItems: items,
        );
        if (_hasLoadedItems) {
          await _upsertLoadedItemFromRelativePath(entry.relativePath);
        }
      }
    }

    if (isMounted()) {
      scheduleRebuild(() => linkIndexRevision++);
    }
  }

  Future<void> autoArchiveRegistryWorks({
    bool showFeedback = false,
    void Function(String message)? showMessage,
  }) async {
    final count = await HomeAutoArchive.run(
      registry: registry,
      vault: vault,
      prefetchFilters: prefetchRegistry,
      showFeedback: showFeedback,
      showMessage: showMessage,
    );
    // Saves already emit precise VaultChangeBatch; do not loadAllItems here.
    if (count > 0 && isMounted()) {
      scheduleRebuild(() => linkIndexRevision++);
    }
  }

  Future<void> runStartupAutoArchiveIfNeeded() async {
    if (isVaultLinked && autoArchiveRegistry) {
      await autoArchiveRegistryWorks();
    }
  }

  String? get vaultPath => vault.vaultPath;

  bool get isVaultLinked =>
      vault.vaultPath != null && vault.vaultPath!.isNotEmpty;

  bool isArchivedInVault(AkashaItem item) => vault.isArchivedInVault(item);

  Future<void> saveVaultItem(AkashaItem item, {String? oldTitle}) =>
      vault.saveItem(item, oldTitle: oldTitle);

  Future<void> setVaultPath(String path) async {
    await vault.setVaultPath(path);
    linkIndex.resetSession();

    // A list belongs to one Vault only. Never let an on-demand legacy view
    // render records from the previously selected archive while the new Vault
    // has not been read yet.
    scheduleRebuild(() {
      items = [];
      _hasLoadedItems = false;
    });
    onVaultItemsSynced(const []);
  }

  void bindVaultWatch({
    required Future<void> Function(VaultChangeBatch change) onVaultChanged,
  }) {
    vaultChangeSubscription?.cancel();
    vaultChangeSubscription = vault.onVaultChanges.listen((change) {
      vaultReloadDebounce?.cancel();
      vaultReloadDebounce = Timer(const Duration(milliseconds: 400), () {
        if (isMounted()) {
          unawaited(onVaultChanged(change));
        }
      });
    });
  }

  void dispose() {
    vaultReloadDebounce?.cancel();
    vaultChangeSubscription?.cancel();
  }

  static bool _isMarkdownRelativePath(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.endsWith('.md') && !lower.contains('..');
  }

  void _removeLoadedItemByAbsolutePath(String absolutePath) {
    if (!_hasLoadedItems) return;
    final normalized = p.normalize(absolutePath);
    final next = items
        .where(
          (item) =>
              item.filePath == null ||
              p.normalize(item.filePath!) != normalized,
        )
        .toList(growable: false);
    if (next.length == items.length) return;
    scheduleRebuild(() => items = next);
    onVaultItemsSynced(next);
  }

  Future<void> _upsertLoadedItemFromRelativePath(String relativePath) async {
    final loaded = await vault.loadItemByRelativePath(relativePath);
    if (loaded == null) {
      final vaultPath = this.vaultPath;
      if (vaultPath != null) {
        _removeLoadedItemByAbsolutePath(p.join(vaultPath, relativePath));
      }
      return;
    }
    final key = loaded.workId.isNotEmpty
        ? loaded.workId
        : (loaded.filePath ?? relativePath);
    final next = <AkashaItem>[];
    var replaced = false;
    for (final item in items) {
      final itemKey = item.workId.isNotEmpty
          ? item.workId
          : (item.filePath ?? '');
      if (itemKey == key ||
          (item.filePath != null &&
              loaded.filePath != null &&
              p.equals(item.filePath!, loaded.filePath!))) {
        next.add(loaded);
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) next.add(loaded);
    scheduleRebuild(() => items = next);
    onVaultItemsSynced(next);
  }
}
