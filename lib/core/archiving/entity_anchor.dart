/// Tier 1 / vault Entity 닻 ([ADR-008](docs/adr/ADR-008-record-entity-time-model.md)).
enum EntityAnchorType {
  work,
  person,
  event,
  concept,
  phenomenon,
  custom,
}

class EntityAnchor {
  const EntityAnchor({
    required this.entityId,
    required this.type,
  });

  final String entityId;
  final EntityAnchorType type;

  bool get isWork => type == EntityAnchorType.work && entityId.startsWith('wk_');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityAnchor &&
          entityId == other.entityId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(entityId, type);
}
