import '../core/archiving/entity_anchor.dart';

/// Phase 3 — non-work collectibles. Work reserved for Phase 5 schema.
enum CollectibleKind {
  person,
  concept,
  event,
  place,
  organization,
}

CollectibleKind? collectibleKindFromAnchor(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => CollectibleKind.person,
    EntityAnchorType.concept => CollectibleKind.concept,
    EntityAnchorType.event => CollectibleKind.event,
    EntityAnchorType.place => CollectibleKind.place,
    EntityAnchorType.organization => CollectibleKind.organization,
    _ => null,
  };
}

EntityAnchorType entityAnchorFromCollectibleKind(CollectibleKind kind) {
  return switch (kind) {
    CollectibleKind.person => EntityAnchorType.person,
    CollectibleKind.concept => EntityAnchorType.concept,
    CollectibleKind.event => EntityAnchorType.event,
    CollectibleKind.place => EntityAnchorType.place,
    CollectibleKind.organization => EntityAnchorType.organization,
  };
}
