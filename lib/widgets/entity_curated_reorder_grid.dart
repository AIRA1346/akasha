import 'package:flutter/material.dart';

import '../models/browse_card.dart';
import '../models/collectible_browse_item.dart';
import '../models/collectible_collection.dart';
import '../models/collectible_kind.dart';
import '../models/collectible_ref.dart';
import '../models/entity_browse_card.dart';
import '../widgets/entity_collectible_card.dart';

/// Entity-only curated collection reorder — separate from Work CuratedReorderGrid.
class EntityCuratedReorderGrid extends StatelessWidget {
  const EntityCuratedReorderGrid({
    super.key,
    required this.cards,
    required this.onReorder,
    this.highlightEntityId,
    required this.onOpenEntity,
  });

  final List<EntityBrowseCard> cards;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String? highlightEntityId;
  final void Function(EntityBrowseCard card) onOpenEntity;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      buildDefaultDragHandles: false,
      itemCount: cards.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final card = cards[index];
        return ReorderableDragStartListener(
          key: ValueKey(card.entity.entityId),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFF252535),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpenEntity(card),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: EntityCollectibleCard(
                            card: card,
                            highlighted:
                                card.entity.entityId == highlightEntityId,
                            onTap: () => onOpenEntity(card),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mixed Work + Entity curated reorder (Phase 5).
class CollectibleCuratedReorderGrid extends StatelessWidget {
  const CollectibleCuratedReorderGrid({
    super.key,
    required this.items,
    required this.onReorder,
    this.highlightEntityId,
    required this.onOpenEntity,
    required this.onOpenWork,
    required this.posterCardBuilder,
  });

  final List<CollectibleBrowseItem> items;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String? highlightEntityId;
  final void Function(EntityBrowseCard card) onOpenEntity;
  final void Function(BrowseCard card) onOpenWork;
  final Widget Function(BrowseCard card) posterCardBuilder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final item = items[index];
        return ReorderableDragStartListener(
          key: ValueKey(collectibleRefKey(item.ref)),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFF252535),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openItem(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SizedBox(
                          height: 132,
                          child: _buildCell(item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openItem(CollectibleBrowseItem item) {
    switch (item) {
      case WorkCollectibleBrowseItem(:final card):
        onOpenWork(card);
      case EntityCollectibleBrowseItem(:final card):
        onOpenEntity(card);
    }
  }

  Widget _buildCell(CollectibleBrowseItem item) {
    return switch (item) {
      WorkCollectibleBrowseItem(:final card) => posterCardBuilder(card),
      EntityCollectibleBrowseItem(:final card) => EntityCollectibleCard(
          card: card,
          highlighted: card.entity.entityId == highlightEntityId,
          onTap: () => onOpenEntity(card),
        ),
    };
  }
}

/// Reorders [memberOrder] to reflect drag within visible [refs].
List<CollectibleRef> reorderRefsInMemberOrder({
  required List<CollectibleRef> fullOrder,
  required List<CollectibleRef> visibleRefs,
  required int oldIndex,
  required int newIndex,
}) {
  if (visibleRefs.isEmpty) return fullOrder;
  final reordered = List<CollectibleRef>.from(visibleRefs);
  final moved = reordered.removeAt(oldIndex);
  final insertAt = newIndex.clamp(0, reordered.length);
  reordered.insert(insertAt, moved);

  final visibleKeys = visibleRefs.map(collectibleRefKey).toSet();
  final result = <CollectibleRef>[];
  var visibleCursor = 0;
  for (final ref in fullOrder) {
    if (!visibleKeys.contains(collectibleRefKey(ref))) {
      result.add(ref);
      continue;
    }
    if (visibleCursor < reordered.length) {
      result.add(reordered[visibleCursor++]);
    }
  }
  for (; visibleCursor < reordered.length; visibleCursor++) {
    result.add(reordered[visibleCursor]);
  }
  return result;
}

List<String> reorderEntityIdsInMemberOrder({
  required List<String> fullOrder,
  required List<String> visibleEntityIds,
  required int oldIndex,
  required int newIndex,
}) {
  if (visibleEntityIds.isEmpty) return fullOrder;
  final reordered = List<String>.from(visibleEntityIds);
  final moved = reordered.removeAt(oldIndex);
  final insertAt = newIndex.clamp(0, reordered.length);
  reordered.insert(insertAt, moved);

  final visibleSet = visibleEntityIds.toSet();
  final result = <String>[];
  var visibleCursor = 0;
  for (final id in fullOrder) {
    if (!visibleSet.contains(id)) {
      result.add(id);
      continue;
    }
    if (visibleCursor < reordered.length) {
      result.add(reordered[visibleCursor++]);
    }
  }
  for (; visibleCursor < reordered.length; visibleCursor++) {
    result.add(reordered[visibleCursor]);
  }
  return result;
}

CollectibleCollection applyCollectibleReorderToCollection({
  required CollectibleCollection collection,
  required List<CollectibleBrowseItem> visibleItems,
  required int oldIndex,
  required int newIndex,
}) {
  final visibleRefs = visibleItems.map((item) => item.ref).toList();
  final newOrder = reorderRefsInMemberOrder(
    fullOrder: collection.memberOrder,
    visibleRefs: visibleRefs,
    oldIndex: oldIndex,
    newIndex: newIndex,
  );
  collection.memberOrder = newOrder;
  collection.touch();
  return collection;
}

CollectibleCollection applyEntityReorderToCollection({
  required CollectibleCollection collection,
  required List<EntityBrowseCard> visibleCards,
  required int oldIndex,
  required int newIndex,
}) {
  final visibleRefs = visibleCards
      .map(
        (card) => CollectibleRef(
          kind: collectibleKindFromUserEntity(card.entity) ??
              CollectibleKind.person,
          id: card.entity.entityId,
        ),
      )
      .toList();
  final newOrder = reorderRefsInMemberOrder(
    fullOrder: collection.memberOrder,
    visibleRefs: visibleRefs,
    oldIndex: oldIndex,
    newIndex: newIndex,
  );
  collection.memberOrder = newOrder;
  collection.touch();
  return collection;
}
