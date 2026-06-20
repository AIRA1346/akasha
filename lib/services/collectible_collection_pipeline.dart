import '../models/collectible_collection.dart';
import '../models/collectible_kind.dart';
import '../models/user_catalog_entity.dart';
import 'entity_related_works_discovery.dart';

/// Resolves Entity collections from catalog — kind + tagsAll + relatedWorkId.
abstract final class CollectibleCollectionPipeline {
  static Future<List<UserCatalogEntity>> resolve({
    required CollectibleCollection collection,
    required Iterable<UserCatalogEntity> catalog,
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final entities = catalog.where((e) => !e.isWorkEntity);
    if (collection.isCurated) {
      return _resolveCurated(collection, entities);
    }
    return _resolveFilter(
      collection,
      entities,
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
  }

  static List<UserCatalogEntity> _resolveCurated(
    CollectibleCollection collection,
    Iterable<UserCatalogEntity> catalog,
  ) {
    final byId = {for (final e in catalog) e.entityId: e};
    final result = <UserCatalogEntity>[];
    for (final ref in collection.memberOrder) {
      final entity = byId[ref.id];
      if (entity == null) continue;
      final kind = collectibleKindFromAnchor(entity.anchorType);
      if (kind == null || kind != ref.kind) continue;
      result.add(entity);
    }
    return result;
  }

  static Future<List<UserCatalogEntity>> _resolveFilter(
    CollectibleCollection collection,
    Iterable<UserCatalogEntity> catalog, {
    EntityRelatedWorksDiscovery? relatedWorksDiscovery,
  }) async {
    final filter = collection.filter;
    if (filter == null) return const [];

    final kindSet = (filter.kinds ?? const [CollectibleKind.person]).toSet();
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

    final relatedByEntity = await relatedWorksDiscovery.discoverAll(
      candidates.map((e) => e.entityId),
    );

    return candidates.where((entity) {
      final related = relatedByEntity[entity.entityId];
      return related?.workIds.contains(relatedWorkId) ?? false;
    }).toList();
  }
}
