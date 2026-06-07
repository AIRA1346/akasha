// ignore_for_file: avoid_print
/// akasha-db v3 — tool 전용 순수 Dart (Flutter 의존 없음)

Map<String, String> parseTitlesJson(dynamic json) {
  if (json is! Map) return {};
  final map = <String, String>{};
  json.forEach((key, value) {
    final tag = key?.toString() ?? '';
    final text = value?.toString().trim() ?? '';
    if (tag.isNotEmpty && text.isNotEmpty) map[tag] = text;
  });
  return map;
}

String normalizeRegistryQuery(String query) =>
    query.toLowerCase().replaceAll(' ', '');

String inferTitleLocaleTag(String title) {
  if (RegExp(r'[\uAC00-\uD7A3]').hasMatch(title)) return 'ko';
  if (RegExp(r'[\u3040-\u30FF]').hasMatch(title)) return 'ja';
  if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(title)) return 'zh';
  return 'en';
}

Map<String, String> inferTitlesFromLegacyTitle(String title) {
  if (title.isEmpty) return {};
  return {inferTitleLocaleTag(title): title};
}

List<String> buildWorkSearchTokens({
  required String legacyTitle,
  Map<String, String> titles = const {},
  List<String> aliases = const [],
  String creator = '',
  List<String> tags = const [],
}) {
  final raw = <String>{};

  void addPhrase(String? phrase) {
    final trimmed = phrase?.trim() ?? '';
    if (trimmed.isEmpty) return;
    raw.add(trimmed);
    raw.add(normalizeRegistryQuery(trimmed));
  }

  addPhrase(legacyTitle);
  for (final value in titles.values) {
    addPhrase(value);
  }
  for (final alias in aliases) {
    addPhrase(alias);
  }
  addPhrase(creator);
  for (final tag in tags) {
    addPhrase(tag);
  }

  return raw.where((t) => t.isNotEmpty).toList()..sort();
}

Map<String, String> mergeExternalIds({
  Map<String, dynamic> extensions = const {},
  Map<String, String> explicit = const {},
}) {
  final merged = Map<String, String>.from(explicit);

  void put(String provider, dynamic raw) {
    final id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty) merged[provider] = id;
  }

  put('anilist', extensions['anilistId'] ?? extensions['anilist']);
  put('steam', extensions['steamAppId'] ?? extensions['steam']);
  put('isbn', extensions['isbn']);
  put('igdb', extensions['igdbId'] ?? extensions['igdb']);
  put('tmdb', extensions['tmdbId'] ?? extensions['tmdb']);
  put('mal', extensions['malId'] ?? extensions['mal']);

  return merged;
}
