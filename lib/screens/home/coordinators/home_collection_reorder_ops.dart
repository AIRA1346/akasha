import '../../../models/collectible_browse_item.dart';
import '../../../models/entity_browse_card.dart';
import '../../../widgets/entity_curated_reorder_grid.dart';
import '../home_collectible_collection_controller.dart';

/// Collectible collection curated reorder.
abstract final class HomeCollectionReorderOps {
  static Future<bool> reorderEntityCollection({
    required HomeCollectibleCollectionController collectionCtrl,
    required List<EntityBrowseCard> visibleCards,
    required int oldIndex,
    required int newIndex,
  }) async {
    final col = collectionCtrl.activeCollection;
    if (col == null || !col.isCurated) return false;
    applyEntityReorderToCollection(
      collection: col,
      visibleCards: visibleCards,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await collectionCtrl.save();
    return true;
  }

  static Future<bool> reorderCollectibleCollection({
    required HomeCollectibleCollectionController collectionCtrl,
    required List<CollectibleBrowseItem> visibleItems,
    required int oldIndex,
    required int newIndex,
  }) async {
    final col = collectionCtrl.activeCollection;
    if (col == null || !col.isCurated) return false;
    applyCollectibleReorderToCollection(
      collection: col,
      visibleItems: visibleItems,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await collectionCtrl.save();
    return true;
  }
}
