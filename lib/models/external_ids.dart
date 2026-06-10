/// akasha-db v3 — 제휴·중복 제거용 외부 식별자 (`externalIds` 필드)
class ExternalIds {
  final Map<String, String> byProvider;

  const ExternalIds([this.byProvider = const {}]);

  factory ExternalIds.fromJson(dynamic json) {
    if (json is! Map) return const ExternalIds();
    final map = <String, String>{};
    json.forEach((key, value) {
      final provider = key?.toString() ?? '';
      final id = value?.toString().trim() ?? '';
      if (provider.isNotEmpty && id.isNotEmpty) map[provider] = id;
    });
    return ExternalIds(map);
  }

  Map<String, String> toJson() => Map<String, String>.from(byProvider);

  String? operator [](String provider) => byProvider[provider];

  /// 레거시 `extensions` → v3 `externalIds` 정규화
  static ExternalIds mergeFromExtensions(
    Map<String, dynamic> extensions, {
    ExternalIds? explicit,
  }) {
    final merged = <String, String>{};
    if (explicit != null) merged.addAll(explicit.byProvider);

    void put(String provider, dynamic raw) {
      final id = raw?.toString().trim() ?? '';
      if (id.isNotEmpty) merged[provider] = id;
    }

    put('wikidata', extensions['wikidataId'] ?? extensions['wikidata']);
    put('anilist', extensions['anilistId'] ?? extensions['anilist']);
    put('steam', extensions['steamAppId'] ?? extensions['steam']);
    put('isbn', extensions['isbn']);
    put('igdb', extensions['igdbId'] ?? extensions['igdb']);
    put('tmdb', extensions['tmdbId'] ?? extensions['tmdb']);
    put('mal', extensions['malId'] ?? extensions['mal']);

    return ExternalIds(merged);
  }
}
