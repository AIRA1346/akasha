import 'collectible_kind.dart';
import 'user_catalog_entity.dart';

/// Collection member reference — Entity or Work (Phase 5).
class CollectibleRef {
  final CollectibleKind kind;
  final String id;

  const CollectibleRef({required this.kind, required this.id});

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
      };

  factory CollectibleRef.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? CollectibleKind.person.name;
    final kind = CollectibleKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => CollectibleKind.person,
    );
    return CollectibleRef(
      kind: kind,
      id: json['id'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectibleRef && kind == other.kind && id == other.id;

  @override
  int get hashCode => Object.hash(kind, id);
}

CollectibleRef collectibleRefFromEntity(UserCatalogEntity entity) {
  final kind = collectibleKindFromUserEntity(entity);
  return CollectibleRef(
    kind: kind ?? CollectibleKind.person,
    id: entity.entityId,
  );
}

CollectibleRef collectibleRefFromWorkId(String workId) {
  return CollectibleRef(kind: CollectibleKind.work, id: workId);
}
