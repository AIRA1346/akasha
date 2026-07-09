import 'package:flutter/material.dart';

import '../../../models/browse_card.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/collectible_browse_item.dart';
import '../../../models/entity_browse_card.dart';
import '../../../models/enums.dart';
import '../../../core/archiving/entity_anchor.dart';
import 'coordinators/home_collection_reorder_ops.dart';
import 'home_shell_controller_base.dart';
mixin HomeShellControllerBrowseMixin on HomeShellControllerBase {
  Future<void> openSearchDialog() => dialogs.openSearchDialog();

  Future<void> onAddWorksFromLibraryEdit() => dialogs.onAddWorksFromLibraryEdit();

  void toggleCategory(MediaCategory category) => browse.toggleCategory(category);

  void clearCategories() => browse.clearCategories();

  void toggleWorkStatus(String label) => browse.toggleWorkStatus(label);

  void toggleMyStatus(String label) => browse.toggleMyStatus(label);

  void onEntityScopeChanged(BrowseEntityScope scope) =>
      browse.onEntityScopeChanged(scope);

  Widget buildPosterCard(BrowseCard card) => browse.buildPosterCard(card);

  Future<void> clearRegistryCache() => registryUi.clearDiskCacheAndReload(
        host.context,
        registry: registry,
        dashboardCtrl: dashboardCtrl,
        filterCtrl: filterCtrl,
        onCatalogLoadingChanged: (v) => catalog.isCatalogLoading = v,
        isMounted: () => host.mounted,
        setState: wrapSetState,
        onDataChanged: rebuild,
      );

  Future<void> showCustomUrlDialog() => dialogs.showCustomUrlDialog();

  Future<void> showLibraryThemePicker() => dialogs.showLibraryThemePicker();

  Future<void> openCatalogContributionsInbox() =>
      dialogs.openCatalogContributionsInbox();

  Future<void> openVaultSettingsDialog() => dialogs.openVaultSettingsDialog();

  Future<void> openClipboardImportDialog() => dialogs.openClipboardImportDialog();

  Future<void> openTimelineQuickCapture() => dialogs.openTimelineQuickCapture();

  Future<void> openJournalQuickCapture() => dialogs.openJournalQuickCapture();

  Future<void> selectVaultFolder() => dialogs.selectVaultFolder();

  Future<void> createDefaultVault() => dialogs.createDefaultVault();

  Future<void> openAddEntityDialog(EntityAnchorType? forceType) =>
      dialogs.openAddEntityDialog(forceType);

  Future<void> onCuratedReorder(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) =>
      browse.onCuratedReorder(cards, oldIndex, newIndex);

  Future<void> onEntityCollectionCuratedReorder(
    List<EntityBrowseCard> visibleCards,
    int oldIndex,
    int newIndex,
  ) async {
    final changed = await HomeCollectionReorderOps.reorderEntityCollection(
      collectionCtrl: collectionCtrl,
      visibleCards: visibleCards,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (changed) rebuild();
  }

  Future<void> onCollectibleCollectionCuratedReorder(
    List<CollectibleBrowseItem> visibleItems,
    int oldIndex,
    int newIndex,
  ) async {
    final changed = await HomeCollectionReorderOps.reorderCollectibleCollection(
      collectionCtrl: collectionCtrl,
      visibleItems: visibleItems,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (changed) rebuild();
  }
}
