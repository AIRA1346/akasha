import '../models/enums.dart';
import '../models/registry_models.dart';

/// 검색어 정규화 (공백 제거, 소문자)
String normalizeRegistryQuery(String query) =>
    query.toLowerCase().replaceAll(' ', '');

bool registryEntryMatchesQuery(RegistrySearchIndexEntry entry, String query) {
  final q = normalizeRegistryQuery(query);
  if (q.isEmpty) return false;
  final title = entry.title.toLowerCase().replaceAll(' ', '');
  final creator = entry.creator.toLowerCase().replaceAll(' ', '');
  final tagsMatch = entry.tags.any((tag) => tag.toLowerCase().contains(q));
  return title.contains(q) || creator.contains(q) || tagsMatch;
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
