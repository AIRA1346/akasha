import '../../models/work_id_codec.dart';

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

  bool get isGlobalWork =>
      type == EntityAnchorType.work && WorkIdCodec.isGlobalWorkId(entityId);

  bool get isUserLocalWork =>
      type == EntityAnchorType.work && WorkIdCodec.isUserLocalWorkId(entityId);

  bool get isWork =>
      type == EntityAnchorType.work &&
      (WorkIdCodec.isGlobalWorkId(entityId) ||
          WorkIdCodec.isUserLocalWorkId(entityId) ||
          WorkIdCodec.isLegacyMasterId(entityId) ||
          entityId.startsWith('wk_'));

  /// Timeline·Record import용 entityId → anchor type.
  static EntityAnchorType typeForEntityId(String entityId) {
    if (WorkIdCodec.isGlobalWorkId(entityId) ||
        WorkIdCodec.isUserLocalWorkId(entityId) ||
        WorkIdCodec.isLegacyMasterId(entityId) ||
        entityId.startsWith('wk_')) {
      return EntityAnchorType.work;
    }
    return EntityAnchorType.custom;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityAnchor &&
          entityId == other.entityId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(entityId, type);
}
