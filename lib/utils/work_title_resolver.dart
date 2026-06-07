import '../config/catalog_locale.dart';
import '../models/work_titles.dart';
import 'registry_search_utils.dart';

/// 검색·인덱스용 토큰 생성 (v3 search_index.searchTokens)
List<String> buildWorkSearchTokens({
  required String legacyTitle,
  WorkTitles titles = const WorkTitles(),
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
  for (final value in titles.byTag.values) {
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

/// UI·카드·검색 표시용 제목
String resolveWorkDisplayTitle({
  required String legacyTitle,
  WorkTitles titles = const WorkTitles(),
  CatalogLocale locale = CatalogLocale.ko,
}) {
  return titles.resolveForLocale(locale, legacyTitle: legacyTitle);
}

/// 레거시 단일 `title` → v3 `titles` 추정 (마이그레이션·시드용)
WorkTitles inferTitlesFromLegacyTitle(String title) {
  if (title.isEmpty) return const WorkTitles();
  final tag = _inferTitleLocaleTag(title);
  return WorkTitles({tag: title});
}

String _inferTitleLocaleTag(String title) {
  if (RegExp(r'[\uAC00-\uD7A3]').hasMatch(title)) return 'ko';
  if (RegExp(r'[\u3040-\u30FF]').hasMatch(title)) return 'ja';
  if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(title)) return 'zh';
  return 'en';
}

/// franchise_groups `displayNames` 해석
String resolveFranchiseDisplayName({
  required String legacyDisplayName,
  Map<String, String> displayNames = const {},
  CatalogLocale locale = CatalogLocale.ko,
}) {
  if (displayNames.isEmpty) return legacyDisplayName;
  final titles = WorkTitles(displayNames);
  final resolved = titles.resolveForLocale(
    locale,
    legacyTitle: legacyDisplayName,
  );
  return resolved.isNotEmpty ? resolved : legacyDisplayName;
}
