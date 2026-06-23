import '../core/archiving/entity_anchor.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/entity_fact.dart';
import '../models/enums.dart';
import '../models/user_catalog_entity.dart';

/// PersonSeed 등 Tier-1 Fact → userCatalog 승격 (R8 P0).
abstract final class EntitySeedCatalogPromotion {
  static UserCatalogEntity entityFromFact(EntityFact fact) {
    return UserCatalogEntity(
      entityId: fact.entityId,
      entityType: fact.entityType.name,
      subtype: _defaultSubtype(fact.entityType),
      title: fact.title,
      aliases: List<String>.from(fact.aliases),
      addedAt: DateTime.now().toUtc(),
    );
  }

  static MediaCategory _defaultSubtype(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.concept => MediaCategory.book,
      EntityAnchorType.event => MediaCategory.book,
      _ => MediaCategory.manga,
    };
  }

  /// catalog에 없으면 upsert 후 반환.
  static Future<UserCatalogEntity> ensureInCatalog({
    required UserCatalogPort userCatalog,
    required EntityFact fact,
  }) async {
    await userCatalog.load();
    final existing = userCatalog.getById(fact.entityId);
    if (existing != null) return existing;

    final entity = entityFromFact(fact);
    await userCatalog.upsert(entity);
    return entity;
  }
}
