import '../models/enums.dart';
import '../models/registry_models.dart';

/// 검색·매칭 SSOT — 소문자, 공백류·구분자(`: / × · -`) 제거.
///
/// 3자 미만이 되면 `Re:` 등 초단편 쿼리 보호를 위해 공백 제거만 적용.
String normalizeRegistryQuery(String query) {
  final aggressive = _stripSearchDelimiters(query.toLowerCase().replaceAll(RegExp(r'\s+'), ''));
  if (aggressive.length >= 3) return aggressive;
  return query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

String _stripSearchDelimiters(String t) {
  return t
      .replaceAll('：', '')
      .replaceAll(':', '')
      .replaceAll('／', '')
      .replaceAll('/', '')
      .replaceAll('×', '')
      .replaceAll('✕', '')
      .replaceAll('⨯', '')
      .replaceAll('·', '')
      .replaceAll('・', '')
      .replaceAll(RegExp(r'[-–—－]'), '');
}

/// 정규화된 [token]이 정규화된 [query]를 포함하는지.
///
/// 3자 미만 aggressive 쿼리(`Re:`)는 토큰도 공백 제거만 적용해 부분일치 유지.
bool registryTokenMatchesQuery(String token, String query) {
  final q = normalizeRegistryQuery(query);
  if (q.isEmpty) return false;

  final queryCompact = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final useAggressive = _stripSearchDelimiters(queryCompact).length >= 3;

  if (useAggressive) {
    return normalizeRegistryQuery(token).contains(q);
  }
  return token.toLowerCase().replaceAll(RegExp(r'\s+'), '').contains(q);
}

bool registryEntryMatchesQuery(RegistrySearchIndexEntry entry, String query) {
  final q = normalizeRegistryQuery(query);
  if (q.isEmpty) return false;

  if (entry.searchTokens.isNotEmpty) {
    for (final token in entry.searchTokens) {
      if (registryTokenMatchesQuery(token, query)) return true;
    }
    return false;
  }

  // v2 search_index 하위 호환
  if (registryTokenMatchesQuery(entry.title, query)) return true;
  if (registryTokenMatchesQuery(entry.creator, query)) return true;
  return entry.tags.any((tag) => registryTokenMatchesQuery(tag, query));
}

/// search_index에서 쿼리에 해당하는 shardId 집합 (중복 제거)
Set<String> shardIdsForQuery(
  List<RegistrySearchIndexEntry> index,
  String query,
) {
  final ids = <String>{};
  for (final entry in index) {
    if (registryEntryMatchesQuery(entry, query)) {
      ids.add(entry.shardId);
    }
  }
  return ids;
}

/// search_index에서 필터(도메인/카테고리)에 해당하는 shardId 집합 (중복 제거)
Set<String> shardIdsForFilters(
  List<RegistrySearchIndexEntry> index, {
  AppDomain? domain,
  MediaCategory? category,
}) {
  if (domain == null && category == null) return {};
  final ids = <String>{};
  for (final entry in index) {
    if (domain != null && entry.domain != domain) continue;
    if (category != null && entry.category != category) continue;
    ids.add(entry.shardId);
  }
  return ids;
}
