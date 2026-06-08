/// AniList API 노드 → Discovery Facts만 추출 (금지 필드 폐기).
library;

import 'discovery_types.dart';

/// AniList `format` → AKASHA category
String? anilistFormatToCategory(String? format) {
  if (format == null || format.isEmpty) return null;
  switch (format.toUpperCase()) {
    case 'TV':
    case 'TV_SHORT':
    case 'SPECIAL':
    case 'OVA':
    case 'ONA':
    case 'MUSIC':
      return 'animation';
    case 'MANGA':
    case 'NOVEL':
    case 'ONE_SHOT':
      return 'manga';
    default:
      return null;
  }
}

int? _yearFromAnilist(Map<String, dynamic> media) {
  final start = media['startDate'];
  if (start is Map) {
    final y = int.tryParse(start['year']?.toString() ?? '');
    if (y != null && y > 0) return y;
  }
  final seasonYear = int.tryParse(media['seasonYear']?.toString() ?? '');
  if (seasonYear != null && seasonYear > 0) return seasonYear;
  return null;
}

String _pickTitle(Map<String, dynamic> title) {
  for (final key in ['english', 'romaji', 'native', 'userPreferred']) {
    final v = title[key]?.toString().trim() ?? '';
    if (v.isNotEmpty) return v;
  }
  return '';
}

Map<String, String> _pickTitles(Map<String, dynamic> title) {
  final map = <String, String>{};
  void put(String tag, String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isNotEmpty) map[tag] = v;
  }
  put('en', title['english']?.toString());
  put('romaji', title['romaji']?.toString());
  put('ja', title['native']?.toString());
  return map;
}

List<String> _pickAliases(dynamic synonyms) {
  if (synonyms is! List) return const [];
  final out = <String>[];
  for (final s in synonyms) {
    final t = s?.toString().trim() ?? '';
    if (t.length >= 2 && t.length <= 80 && out.length < 5) {
      out.add(t);
    }
  }
  return out;
}

String _pickCreator(Map<String, dynamic> media) {
  final studios = media['studios'];
  if (studios is Map) {
    final nodes = studios['nodes'];
    if (nodes is List && nodes.isNotEmpty) {
      final name = nodes.first is Map
          ? (nodes.first as Map)['name']?.toString().trim() ?? ''
          : '';
      if (name.isNotEmpty) return name;
    }
  }
  final staff = media['staff'];
  if (staff is Map) {
    final edges = staff['edges'];
    if (edges is List) {
      for (final edge in edges) {
        if (edge is! Map) continue;
        final role = edge['role']?.toString().toLowerCase() ?? '';
        if (!role.contains('director') && !role.contains('original')) {
          continue;
        }
        final node = edge['node'];
        if (node is Map) {
          final name = node['name']?['full']?.toString().trim() ?? '';
          if (name.isNotEmpty) return name;
        }
      }
    }
  }
  return '';
}

/// AniList Media 노드(런타임) → Facts. **description·cover 등은 읽지 않음.**
DiscoveryFacts extractAnilistFacts(Map<String, dynamic> media) {
  final titleObj = media['title'];
  final titleMap = titleObj is Map
      ? Map<String, dynamic>.from(titleObj)
      : <String, dynamic>{};

  return DiscoveryFacts(
    title: _pickTitle(titleMap),
    titles: _pickTitles(titleMap),
    releaseYear: _yearFromAnilist(media),
    creator: _pickCreator(media),
    aliases: _pickAliases(media['synonyms']),
    format: media['format']?.toString(),
  );
}

/// 금지 키가 Facts JSON에 섞였는지 검사 (추출 버그 방지)
List<String> findForbiddenKeysInMap(Map<String, dynamic> map) {
  final found = <String>[];
  void walk(Object? node, String prefix) {
    if (node is! Map) return;
    for (final entry in node.entries) {
      final key = entry.key.toString();
      final lower = key.toLowerCase();
      if (discoveryForbiddenFactKeys.contains(key) ||
          discoveryForbiddenFactKeys.contains(lower)) {
        found.add(prefix.isEmpty ? key : '$prefix.$key');
      }
      if (entry.value is Map) {
        walk(entry.value, prefix.isEmpty ? key : '$prefix.$key');
      }
    }
  }
  walk(map, '');
  return found;
}
