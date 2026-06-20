import '../models/akasha_item.dart';
import '../models/collectible_browse_item.dart';
import '../models/collectible_collection.dart';
import '../models/collectible_kind.dart';
import '../models/collectible_ref.dart';
import '../models/user_catalog_entity.dart';
import 'entity_related_works_discovery.dart';

/// Resolves Entity collections from catalog — kind + tagsAll + relatedWorkId.
abstract final class CollectibleCollectionPipeline {
  static Future<List<UserCatalogEntity>> resolve({
    required CollectibleCollection collection,
    required Iterable<UserCatalogEntity> catalog,
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final members = await resolveMembers(
      collection: collection,
      catalog: catalog,
      vaultItems: const [],
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
    return members
        .whereType<EntityCollectibleMember>()
        .map((m) => m.entity)
        .toList();
  }

  /// Ordered members for gallery — Work + Entity (Phase 5 curated mixed).
  static Future<List<CollectibleMember>> resolveMembers({
    required CollectibleCollection collection,
    required Iterable<UserCatalogEntity> catalog,
    required List<AkashaItem> vaultItems,
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    if (collection.isCurated) {
      return _resolveCuratedMembers(collection, catalog, vaultItems);
    }
    return _resolveFilterMembers(
      collection,
      catalog,
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
  }

  static List<CollectibleMember> _resolveCuratedMembers(
    CollectibleCollection collection,
    Iterable<UserCatalogEntity> catalog,
    List<AkashaItem> vaultItems,
  ) {
    final byEntityId = {for (final e in catalog) e.entityId: e};
    final byWorkId = {
      for (final item in vaultItems)
        if (item.workId.isNotEmpty) item.workId: item,
    };

    final result = <CollectibleMember>[];
    for (final ref in collection.memberOrder) {
      if (ref.kind == CollectibleKind.work) {
        final item = byWorkId[ref.id];
        if (item != null) {
          result.add(WorkCollectibleMember(ref: ref, item: item));
        }
        continue;
      }

      final entity = byEntityId[ref.id];
      if (entity == null || entity.isWorkEntity) continue;
      final kind = collectibleKindFromAnchor(entity.anchorType);
      if (kind == null || kind != ref.kind) continue;
      result.add(EntityCollectibleMember(ref: ref, entity: entity));
    }
    return result;
  }

  static Future<List<CollectibleMember>> _resolveFilterMembers(
    CollectibleCollection collection,
    Iterable<UserCatalogEntity> catalog, {
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final entities = catalog.where((e) => !e.isWorkEntity);
    final filtered = await _resolveFilter(
      collection,
      entities,
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
    return filtered
        .map(
          (entity) => EntityCollectibleMember(
            ref: collectibleRefFromEntity(entity),
            entity: entity,
          ),
        )
        .toList();
  }

  static Future<List<UserCatalogEntity>> _resolveFilter(
    CollectibleCollection collection,
    Iterable<UserCatalogEntity> catalog, {
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final filter = collection.filter;
    if (filter == null) return const [];

    final kindSet = (filter.kinds ?? const [CollectibleKind.person]).toSet();
    if (kindSet.contains(CollectibleKind.work)) {
      kindSet.remove(CollectibleKind.work);
    }
    final tagsAll = filter.tagsAll ?? const [];
    final relatedWorkId = filter.relatedWorkId;

    final candidates = catalog.where((entity) {
      final kind = collectibleKindFromAnchor(entity.anchorType);
      if (kind == null || !kindSet.contains(kind)) return false;
      if (tagsAll.isNotEmpty && !entity.matchesTagsAll(tagsAll)) return false;
      return true;
    }).toList();

    if (relatedWorkId == null || relatedWorkId.isEmpty) {
      return candidates;
    }
    if (relatedWorksDiscovery == null) {
      return const [];
    }

    final linkedEntityIds =
        await relatedWorksDiscovery.entityIdsForWork(relatedWorkId);
    final discoverTargets = linkedEntityIds.isEmpty
        ? candidates.map((e) => e.entityId)
        : candidates
            .where((e) => linkedEntityIds.contains(e.entityId))
            .map((e) => e.entityId);

    final relatedByEntity = await relatedWorksDiscovery.discoverAll(
      discoverTargets,
    );

    return candidates.where((entity) {
      final related = relatedByEntity[entity.entityId];
      return related?.workIds.contains(relatedWorkId) ?? false;
    }).toList();
  }
}
