import 'collectible_kind.dart';

/// Entity collection member reference — Phase 3 entity IDs only.
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
