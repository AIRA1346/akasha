import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/browse_card.dart';
import '../../../models/collectible_browse_item.dart';
import '../../../models/entity_browse_card.dart';
import '../../../models/entity_gallery_sort.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_related_works_discovery.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../utils/entity_body_preview.dart';
import '../../../utils/entity_browse_sort.dart';

/// CatalogEntityBrowseView — 카드·컬렉션 browse 데이터 로드·정렬.
abstract final class CatalogEntityBrowseLoader {
  static EntityGallerySortCriteria effectiveSortCriteria({
    required EntityGallerySortCriteria requested,
    required bool collectionIsCurated,
  }) {
    if (collectionIsCurated && requested.isManualOrder) {
      return EntityGallerySortCriteria.manualOrder;
    }
    return requested;
  }

  static List<EntityBrowseCard> applySort(
    List<EntityBrowseCard> cards,
    EntityGallerySortCriteria criteria,
  ) {
    if (criteria.isManualOrder) return cards;
    return sortEntityBrowseCards(cards, criteria);
  }

  static List<CollectibleBrowseItem> sortCollectibleBrowseItems(
    List<CollectibleBrowseItem> items,
    EntityGallerySortCriteria criteria,
  ) {
    if (criteria.isManualOrder) return items;
    final entityItems = items.whereType<EntityCollectibleBrowseItem>().toList();
    if (entityItems.length != items.length) return items;
    final sortedCards = sortEntityBrowseCards(
      entityItems.map((item) => item.card).toList(),
      criteria,
    );
    final byId = {for (final card in sortedCards) card.entity.entityId: card};
    return [
      for (final item in items)
        if (item is EntityCollectibleBrowseItem)
          EntityCollectibleBrowseItem(
            ref: item.ref,
            card: byId[item.card.entity.entityId] ?? item.card,
          )
        else
          item,
    ];
  }

  static Future<List<EntityBrowseCard>> buildBrowseCards({
    required List<UserCatalogEntity> entities,
    required RecordLinkPort? linkIndex,
    String? vaultPath,
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final cachedJournals = relatedWorksDiscovery?.cachedJournalsByEntityId;
    final Map<String, EntityJournalEntry> byId;
    if (cachedJournals != null) {
      byId = cachedJournals;
    } else {
      final journals = await const EntityVaultLoader().loadFromVault(vaultPath);
      byId = {for (final j in journals) j.entityId: j};
    }

    final cards = <EntityBrowseCard>[];
    final uncachedIncoming = <int>[];
    final incomingByEntity = List<int?>.filled(entities.length, null);

    if (linkIndex != null) {
      for (var i = 0; i < entities.length; i++) {
        final cached = relatedWorksDiscovery?.cachedIncomingRecordCount(
          entities[i].entityId,
        );
        if (cached != null) {
          incomingByEntity[i] = cached;
        } else {
          uncachedIncoming.add(i);
        }
      }

      if (uncachedIncoming.isNotEmpty) {
        final fetched = await Future.wait(
          uncachedIncoming.map(
            (i) => linkIndex.incomingRecordPaths(entities[i].entityId),
          ),
        );
        for (var j = 0; j < uncachedIncoming.length; j++) {
          incomingByEntity[uncachedIncoming[j]] = fetched[j].length;
        }
      }
    }

    for (var i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final journal = byId[entity.entityId];
      final incoming = linkIndex != null ? (incomingByEntity[i] ?? 0) : 0;
      final body = journal?.body.trim() ?? '';
      cards.add(
        EntityBrowseCard(
          entity: entity,
          journal: journal,
          isArchived: journal != null,
          incomingRecordCount: incoming,
          bodyPreview: body.isEmpty ? '' : EntityBodyPreview.format(body),
        ),
      );
    }
    return cards;
  }

  static Future<List<CollectibleBrowseItem>> buildCollectibleBrowseItems({
    required List<CollectibleMember> members,
    required RecordLinkPort? linkIndex,
    String? vaultPath,
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final entities = members
        .whereType<EntityCollectibleMember>()
        .map((member) => member.entity)
        .toList();
    final entityCards = await buildBrowseCards(
      entities: entities,
      linkIndex: linkIndex,
      vaultPath: vaultPath,
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
    final entityCardById = {
      for (final card in entityCards) card.entity.entityId: card,
    };

    return [
      for (final member in members)
        switch (member) {
          WorkCollectibleMember(:final ref, :final item) =>
            WorkCollectibleBrowseItem(
              ref: ref,
              card: BrowseCard(item: item),
            ),
          EntityCollectibleMember(:final ref, :final entity) =>
            EntityCollectibleBrowseItem(
              ref: ref,
              card: entityCardById[entity.entityId] ??
                  EntityBrowseCard(entity: entity, isArchived: false),
            ),
        },
    ];
  }
}
