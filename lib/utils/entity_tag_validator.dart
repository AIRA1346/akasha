import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';

/// Soft validation — semantic tags must not mirror work titles.
abstract final class EntityTagValidator {
  static String normalizeTitle(String raw) => raw.trim().toLowerCase();

  static Set<String> buildWorkTitleIndex({
    required Iterable<UserCatalogEntity> catalogEntities,
    Iterable<AkashaItem> vaultItems = const [],
  }) {
    final titles = <String>{};
    for (final entity in catalogEntities) {
      if (!entity.isWorkEntity) continue;
      _addTitle(titles, entity.title);
      for (final alias in entity.aliases) {
        _addTitle(titles, alias);
      }
      for (final variant in entity.titles.byTag.values) {
        _addTitle(titles, variant);
      }
    }
    for (final item in vaultItems) {
      _addTitle(titles, item.title);
    }
    return titles;
  }

  static void _addTitle(Set<String> out, String raw) {
    final normalized = normalizeTitle(raw);
    if (normalized.isNotEmpty) out.add(normalized);
  }

  /// Tags that look like work titles (case-insensitive).
  static List<String> findWorkTitleTags(
    List<String> tags,
    Set<String> workTitles,
  ) {
    if (workTitles.isEmpty) return const [];
    return tags
        .where((tag) => workTitles.contains(normalizeTitle(tag)))
        .toList();
  }

  static String warningMessage(List<String> offendingTags) {
    if (offendingTags.isEmpty) return '';
    final quoted = offendingTags.map((t) => '「$t」').join(', ');
    return '태그 $quoted 은(는) 작품명과 같습니다. '
        'semantic 축(영웅, 성장 등)을 권장합니다 — relation은 link graph로 표현하세요.';
  }
}
