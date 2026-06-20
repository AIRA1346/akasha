import 'collectible_kind.dart';

/// Filter predicate for dynamic Entity collections.
class CollectibleCollectionFilter {
  final List<CollectibleKind>? kinds;
  final List<String>? tagsAll;

  /// Phase 4 resolver — stored only in Phase 3.
  final String? relatedWorkId;

  const CollectibleCollectionFilter({
    this.kinds,
    this.tagsAll,
    this.relatedWorkId,
  });

  Map<String, dynamic> toJson() => {
        if (kinds != null) 'kinds': kinds!.map((k) => k.name).toList(),
        if (tagsAll != null) 'tagsAll': tagsAll,
        if (relatedWorkId != null) 'relatedWorkId': relatedWorkId,
      };

  factory CollectibleCollectionFilter.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CollectibleCollectionFilter();
    final parsedKinds = <CollectibleKind>[];
    if (json['kinds'] != null) {
      for (final raw in json['kinds'] as List<dynamic>) {
        try {
          parsedKinds.add(
            CollectibleKind.values.firstWhere((k) => k.name == raw),
          );
        } catch (_) {}
      }
    }
    final tagsRaw = json['tagsAll'];
    final tagsAll = tagsRaw == null
        ? null
        : List<String>.from(tagsRaw as List).map((e) => e.toString()).toList();
    return CollectibleCollectionFilter(
      kinds: parsedKinds.isEmpty ? null : parsedKinds,
      tagsAll: tagsAll,
      relatedWorkId: json['relatedWorkId'] as String?,
    );
  }
}
