import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ports/registry_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/vault_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/library_theme.dart';
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
    linkIndex = RecordLinkIndexService(vault: vault, eventLedger: eventLedger);
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

  /// [RecordLinkIndexService] 재빌드마다 증가 — 프리뷰 패널 연결 섹션 갱신용.
  int linkIndexRevision = 0;

  StreamSubscription<void>? vaultUpdateSubscription;
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

  Future<void> loadItems() async {
    final loadedItems = await HomeVaultLoader.loadItems(vault);
    await userCatalog.load();
    if (!isMounted()) return;
    await rebuildLinkIndex(vaultItems: loadedItems);
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

  Future<void> rebuildLinkIndex({List<AkashaItem>? vaultItems}) async {
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
    if (count > 0) await loadItems();
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

    // A list belongs to one Vault only. Never let an on-demand legacy view
    // render records from the previously selected archive while the new Vault
    // has not been read yet.
    scheduleRebuild(() {
      items = [];
      _hasLoadedItems = false;
    });
    onVaultItemsSynced(const []);
  }

  void bindVaultWatch({required VoidCallback onVaultChanged}) {
    vaultUpdateSubscription?.cancel();
    vaultUpdateSubscription = vault.onVaultUpdated.listen((_) {
      vaultReloadDebounce?.cancel();
      vaultReloadDebounce = Timer(const Duration(milliseconds: 400), () {
        if (isMounted()) onVaultChanged();
      });
    });
  }

  void dispose() {
    vaultReloadDebounce?.cancel();
    vaultUpdateSubscription?.cancel();
  }
}
