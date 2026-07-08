import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import 'home_shell_controller_base.dart';

/// Workbench open·save·recent exploration.
mixin HomeShellControllerWorkbenchMixin on HomeShellControllerBase {
  AkashaItem resolveItemForOpen(AkashaItem item) =>
      workbenchCoord.resolveItemForOpen(item);

  void openBrowseItem(AkashaItem item) {
    preview.clearReturnSnapshot();
    preview.closeAllPreviews();
    workbenchCoord.openBrowseItem(item);
    recentExplore.store.recordWork(item.workId);
    rebuild();
  }

  void openWorkFromCanvas(AkashaItem item) {
    workbenchCoord.openWorkFromCanvas(item);
    recentExplore.store.recordWork(item.workId);
    rebuild();
  }

  Future<bool> openEntityFromCanvas(String entityId) async {
    final opened = await workbenchCoord.openEntityFromCanvas(entityId);
    if (opened) {
      await recentExplore.store.recordEntity(entityId);
    }
    rebuild();
    return opened;
  }

  Future<void> openItemDetail(AkashaItem item) async {
    if (item is EntityItem) {
      final entity = userCatalog.getById(item.entityId) ??
          UserCatalogEntity.userLocal(
            entityId: item.entityId,
            type: item.entityType,
            title: item.title,
            subtype: item.category,
            addedAt: item.addedAt,
          );
      await openEntity(entity);
      return;
    }
    await preview.openWorkDetail(item);
  }

  Future<void> openEntity(UserCatalogEntity entity) async {
    preview.clearReturnSnapshot();
    preview.closeAllPreviews();
    await workbenchCoord.openEntity(entity);
    await recentExplore.store.recordEntity(entity.entityId);
    rebuild();
  }

  void openCanvas(String canvasId, String title) {
    preview.clearReturnSnapshot();
    preview.closeAllPreviews();
    workbenchCoord.openCanvas(canvasId, title);
    rebuild();
  }

  void openRecentExploreItem(AkashaItem item) {
    if (workbench.hasOpenDetail) {
      openItemDetail(item);
      return;
    }
    recentExplore.openItem(
      item,
      openEntityPreview: preview.openEntityPreview,
      openWorkPreview: preview.openWorkPreview,
    );
  }

  void openMostRecentWorkForRecord() {
    final sorted = List<AkashaItem>.from(vault.items)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    if (sorted.isEmpty) return;
    openBrowseItem(sorted.first);
  }

  Future<void> onWorkbenchWorkSaved(AkashaItem saved, {bool silent = false}) async {
    await workbenchCoord.onWorkbenchWorkSaved(saved, silent: silent);
    if (!silent) {
      preview.maybeReturnAfterSave(workId: saved.workId);
    }
  }

  Future<void> onWorkbenchWorkDeleted(String tabId, AkashaItem item) async {
    preview.maybeClearReturnForWork(item.workId);
    await workbenchCoord.onWorkbenchWorkDeleted(tabId, item);
  }

  Future<void> onWorkbenchEntitySaved(
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    bool silent = false,
  }) async {
    await workbenchCoord.onWorkbenchEntitySaved(entity, journal);
    if (!silent) {
      preview.maybeReturnAfterSave(entityId: entity.entityId);
    }
  }

  Future<void> onWorkbenchEntityDeleted(String tabId) async {
    final tab = workbench.activeEntityTab;
    if (tab != null) {
      preview.maybeClearReturnForEntity(tab.entity.entityId);
    }
    await workbenchCoord.onWorkbenchEntityDeleted(tabId);
  }
}
