import 'package:flutter/material.dart';

import '../models/collectible_collection.dart';
import '../models/collectible_ref.dart';
import '../models/entity_browse_card.dart';
import '../widgets/entity_collectible_card.dart';

/// Entity curated collection reorder — separate from Work CuratedReorderGrid.
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
      onReorder: onReorder,
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

/// Reorders [memberOrder] to reflect drag within visible [cards].
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

CollectibleCollection applyEntityReorderToCollection({
  required CollectibleCollection collection,
  required List<EntityBrowseCard> visibleCards,
  required int oldIndex,
  required int newIndex,
}) {
  final fullOrder = collection.memberOrder.map((r) => r.id).toList();
  final visibleIds = visibleCards.map((c) => c.entity.entityId).toList();
  final newOrder = reorderEntityIdsInMemberOrder(
    fullOrder: fullOrder,
    visibleEntityIds: visibleIds,
    oldIndex: oldIndex,
    newIndex: newIndex,
  );
  final byId = {for (final ref in collection.memberOrder) ref.id: ref};
  final nextRefs = newOrder
      .map((id) => byId[id])
      .whereType<CollectibleRef>()
      .toList();
  collection.memberOrder = nextRefs;
  collection.touch();
  return collection;
}
