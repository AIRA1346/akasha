import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';

/// 최근 탐색 키 → 표시용 [AkashaItem] 목록.
List<AkashaItem> resolveRecentExplorationItems({
  required List<String> itemKeys,
  required List<AkashaItem> vaultItems,
  required UserCatalogPort userCatalog,
  int limit = 8,
}) {
  final byWorkId = <String, AkashaItem>{
    for (final item in vaultItems)
      if (item.workId.isNotEmpty) item.workId: item,
  };

  final resolved = <AkashaItem>[];
  for (final key in itemKeys) {
    if (resolved.length >= limit) break;

    if (key.startsWith('work:')) {
      final workId = key.substring(5);
      final item = byWorkId[workId];
      if (item != null) resolved.add(item);
      continue;
    }

    if (key.startsWith('entity:')) {
      final entityId = key.substring(7);
      final entity = userCatalog.getById(entityId);
      if (entity == null) continue;

      if (entity.isWorkEntity) {
        final work = byWorkId[entity.entityId];
        if (work != null) {
          resolved.add(work);
          continue;
        }
      }

      resolved.add(_entityAsItem(entity));
    }
  }
  return resolved;
}

EntityItem _entityAsItem(UserCatalogEntity entity) {
  return EntityItem(
    entityType: entity.anchorType,
    entityId: entity.entityId,
    title: entity.title,
    category: entity.subtype,
    domain: entity.domain,
    creator: entity.creator,
    releaseYear: entity.releaseYear,
    posterPath: entity.posterPath,
    tags: List<String>.from(entity.tags),
    addedAt: entity.addedAt,
  );
}
