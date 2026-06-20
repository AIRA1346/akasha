import 'collectible_collection_filter.dart';
import 'collectible_ref.dart';

enum CollectibleCollectionMode {
  curated,
  filter,
}

/// Entity-only collection — independent from Work PersonalLibrary.
class CollectibleCollection {
  final String id;
  String title;
  String? iconKey;
  CollectibleCollectionMode mode;
  List<CollectibleRef> memberOrder;
  CollectibleCollectionFilter? filter;
  final DateTime createdAt;
  DateTime updatedAt;

  CollectibleCollection({
    required this.id,
    required this.title,
    this.iconKey,
    required this.mode,
    List<CollectibleRef>? memberOrder,
    this.filter,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : memberOrder = _normalizeMemberOrder(memberOrder ?? const []),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isCurated => mode == CollectibleCollectionMode.curated;
  bool get isFilter => mode == CollectibleCollectionMode.filter;

  static List<CollectibleRef> _normalizeMemberOrder(List<CollectibleRef> order) {
    final seen = <String>{};
    final result = <CollectibleRef>[];
    for (final ref in order) {
      if (ref.id.isEmpty || seen.contains(ref.id)) continue;
      seen.add(ref.id);
      result.add(ref);
    }
    return result;
  }

  void touch() => updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (iconKey != null) 'iconKey': iconKey,
        'mode': mode.name,
        'memberOrder': memberOrder.map((r) => r.toJson()).toList(),
        if (filter != null) 'filter': filter!.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CollectibleCollection.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String? ?? CollectibleCollectionMode.filter.name;
    final mode = CollectibleCollectionMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => CollectibleCollectionMode.filter,
    );
    final memberRaw = json['memberOrder'] as List<dynamic>? ?? const [];
    final members = memberRaw
        .map((e) => CollectibleRef.fromJson(e as Map<String, dynamic>))
        .toList();
    final filterJson = json['filter'];
    return CollectibleCollection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      iconKey: json['iconKey'] as String?,
      mode: mode,
      memberOrder: members,
      filter: filterJson == null
          ? null
          : CollectibleCollectionFilter.fromJson(
              filterJson as Map<String, dynamic>,
            ),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
