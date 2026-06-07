import '../config/catalog_locale.dart';

/// akasha-db v3 — 로케일별 작품명 (`titles` 필드)
class WorkTitles {
  final Map<String, String> byTag;

  const WorkTitles([this.byTag = const {}]);

  factory WorkTitles.fromJson(dynamic json) {
    if (json is! Map) return const WorkTitles();
    final map = <String, String>{};
    json.forEach((key, value) {
      final tag = key?.toString() ?? '';
      final text = value?.toString().trim() ?? '';
      if (tag.isNotEmpty && text.isNotEmpty) map[tag] = text;
    });
    return WorkTitles(map);
  }

  Map<String, String> toJson() => Map<String, String>.from(byTag);

  bool get isEmpty => byTag.isEmpty;

  String? operator [](String tag) => byTag[tag];

  /// [fallbackTags] 순으로 첫 non-empty 제목 반환
  String? resolve(List<String> fallbackTags) {
    for (final tag in fallbackTags) {
      final value = byTag[tag];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String resolveForLocale(
    CatalogLocale locale, {
    required String legacyTitle,
  }) {
    final resolved = resolve(locale.titleFallbackTags);
    if (resolved != null && resolved.isNotEmpty) return resolved;
    if (legacyTitle.isNotEmpty) return legacyTitle;
    return byTag.values.firstWhere(
      (v) => v.isNotEmpty,
      orElse: () => '',
    );
  }
}
