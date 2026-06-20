import '../core/archiving/entity_anchor.dart';
import 'user_catalog_entity.dart';

/// Phase 3+ — collectibles including Work (Phase 5 curated mixed).
enum CollectibleKind {
  work,
  person,
  concept,
  event,
  place,
  organization,
}

CollectibleKind? collectibleKindFromAnchor(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.work => CollectibleKind.work,
    EntityAnchorType.person => CollectibleKind.person,
    EntityAnchorType.concept => CollectibleKind.concept,
    EntityAnchorType.event => CollectibleKind.event,
    EntityAnchorType.place => CollectibleKind.place,
    EntityAnchorType.organization => CollectibleKind.organization,
    _ => null,
  };
}

CollectibleKind? collectibleKindFromUserEntity(UserCatalogEntity entity) {
  if (entity.isWorkEntity) return CollectibleKind.work;
  return collectibleKindFromAnchor(entity.anchorType);
}

EntityAnchorType entityAnchorFromCollectibleKind(CollectibleKind kind) {
  return switch (kind) {
    CollectibleKind.work => EntityAnchorType.work,
    CollectibleKind.person => EntityAnchorType.person,
    CollectibleKind.concept => EntityAnchorType.concept,
    CollectibleKind.event => EntityAnchorType.event,
    CollectibleKind.place => EntityAnchorType.place,
    CollectibleKind.organization => EntityAnchorType.organization,
  };
}
