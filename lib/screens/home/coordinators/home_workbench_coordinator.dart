import '../../../core/archiving/entity_journal_entry.dart';
import '../../../features/workbench/data/workbench_controller.dart';
import '../../../features/workbench/presentation/collectible_tab.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/file_service.dart';

/// 워크벤치 탭·Collectible 열기/저장 (E2-3 · Phase 6).
class HomeWorkbenchCoordinator {
  HomeWorkbenchCoordinator({
    required this.workbench,
    required this.isMounted,
    required this.rebuild,
    required this.getItems,
    required this.mutateItems,
    required this.reloadItems,
  });

  final WorkbenchController workbench;
  final bool Function() isMounted;
  final void Function() rebuild;
  final List<AkashaItem> Function() getItems;
  final void Function(void Function(List<AkashaItem> items) mutate) mutateItems;
  final Future<void> Function() reloadItems;

  bool _lastWorkbenchShowsDetail = false;
  bool _lastWorkbenchHadTabs = false;

  void attach() => workbench.addListener(onWorkbenchChanged);

  void dispose() => workbench.removeListener(onWorkbenchChanged);

  void onWorkbenchChanged() {
    if (!isMounted()) return;
    final showsDetail = workbench.hasOpenDetail;
    final hasTabs = workbench.hasTabs;
    if (showsDetail == _lastWorkbenchShowsDetail &&
        hasTabs == _lastWorkbenchHadTabs) {
      return;
    }
    _lastWorkbenchShowsDetail = showsDetail;
    _lastWorkbenchHadTabs = hasTabs;
    rebuild();
  }

  void captureWorkbenchLayout() {
    _lastWorkbenchShowsDetail = workbench.hasOpenDetail;
    _lastWorkbenchHadTabs = workbench.hasTabs;
  }

  AkashaItem resolveItemForOpen(AkashaItem item) {
    final items = getItems();
    for (final existing in items) {
      if (item.workId.isNotEmpty && existing.workId == item.workId) {
        return existing;
      }
      if (existing.title == item.title &&
          existing.category == item.category) {
        return existing;
      }
    }
    return item;
  }

  void openBrowseItem(AkashaItem item) {
    workbench.openWork(resolveItemForOpen(item));
    if (isMounted()) rebuild();
  }

  Future<void> openEntity(UserCatalogEntity entity) async {
    if (entity.isWorkEntity) {
      for (final item in getItems()) {
        if (item.workId == entity.entityId) {
          openBrowseItem(item);
          return;
        }
      }
      return;
    }

    EntityJournalEntry? entry;
    final vaultPath = AkashaFileService().vaultPath;
    if (vaultPath != null && vaultPath.isNotEmpty) {
      entry = await const EntityVaultLoader().findByEntityId(
        vaultPath,
        entity.entityId,
      );
    }

    if (!isMounted()) return;
    workbench.openEntity(entity, journal: entry);
    rebuild();
  }

  Future<void> onWorkbenchWorkSaved(AkashaItem saved, {bool silent = false}) async {
    await reloadItems();
    if (!isMounted()) return;
    if (silent) {
      // WorkbenchShell.onSaved already synced the open tab from the editor.
      return;
    }
    final tabId = WorkCollectibleTab.idFor(saved);
    AkashaItem resolved = saved;
    for (final item in getItems()) {
      if (saved.workId.isNotEmpty && item.workId == saved.workId) {
        resolved = item;
        break;
      }
    }
    workbench.updateTabItem(tabId, resolved, dirty: false);
  }

  Future<void> onWorkbenchWorkDeleted(String tabId, AkashaItem item) async {
    workbench.closeTab(tabId);
    if (isMounted()) {
      mutateItems((items) {
        items.removeWhere((e) =>
            (item.workId.isNotEmpty && e.workId == item.workId) ||
            (e.title == item.title && e.category == item.category));
      });
    }
    await reloadItems();
  }

  Future<void> onWorkbenchEntitySaved(
    UserCatalogEntity entity,
    EntityJournalEntry? journal,
  ) async {
    if (!isMounted()) return;
    workbench.updateEntityTab(
      EntityCollectibleTab.idFor(entity.entityId),
      entity,
      journal,
      dirty: false,
    );
    rebuild();
  }

  Future<void> onWorkbenchEntityDeleted(String tabId) async {
    workbench.closeTab(tabId);
    if (isMounted()) rebuild();
  }
}
