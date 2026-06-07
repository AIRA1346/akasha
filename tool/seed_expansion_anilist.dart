// ignore_for_file: avoid_print
/// AniList 인기작으로 akasha-db 시드를 ~1,000작까지 확장
///
/// Usage:
///   dart run tool/seed_expansion_anilist.dart
///   dart run tool/seed_expansion_anilist.dart --target=1000
///   dart run tool/registry_builder.dart --sync-assets
///
/// 기존 workId·AniList id 매핑은 건너뜁니다.

import 'dart:convert';
import 'dart:io';

const _anilistEndpoint = 'https://graphql.anilist.co';

void main(List<String> args) async {
  final target = _parseTarget(args);
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');

  final existingIds = _collectExistingWorkIds(shardsRoot);
  print('Existing works: ${existingIds.length}, target: $target');

  if (existingIds.length >= target) {
    print('Already at or above target. Nothing to do.');
    return;
  }

  var added = 0;
  for (final spec in _fetchSpecs) {
    if (existingIds.length + added >= target) break;

    var page = 1;
    var emptyStreak = 0;
    while (existingIds.length + added < target && page <= 30) {
      final batch = await _fetchMediaPage(
        type: spec.type,
        category: spec.category,
        sort: spec.sort,
        page: page,
        perPage: 50,
      );
      if (batch.isEmpty) {
        emptyStreak++;
        if (emptyStreak >= 2) break;
        page++;
        continue;
      }
      emptyStreak = 0;

      for (final media in batch) {
        if (existingIds.length + added >= target) break;
        final seed = _mediaToSeed(media, spec.category);
        if (seed == null) continue;

        final workId = seed['workId'] as String;
        if (existingIds.contains(workId)) continue;

        _writeShard(shardsRoot, seed);
        existingIds.add(workId);
        added++;
        if (added % 25 == 0) {
          print('… $added added (${existingIds.length} total)');
        }
      }
      page++;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  print('\nDone: $added added → ${existingIds.length} total works');
  print('Next: dart run tool/registry_builder.dart --sync-assets');
}

int _parseTarget(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--target=')) {
      return int.tryParse(arg.split('=').last) ?? 1000;
    }
  }
  return 1000;
}

class _FetchSpec {
  final String type;
  final String category;
  final String sort;
  const _FetchSpec(this.type, this.category, [this.sort = 'POPULARITY_DESC']);
}

const _fetchSpecs = [
  _FetchSpec('MANGA', 'manga', 'POPULARITY_DESC'),
  _FetchSpec('ANIME', 'animation', 'POPULARITY_DESC'),
  _FetchSpec('MANGA', 'manga', 'SCORE_DESC'),
  _FetchSpec('ANIME', 'animation', 'SCORE_DESC'),
  _FetchSpec('MANGA', 'manga', 'TRENDING_DESC'),
  _FetchSpec('ANIME', 'animation', 'TRENDING_DESC'),
  _FetchSpec('MANGA', 'manga', 'FAVOURITES_DESC'),
  _FetchSpec('ANIME', 'animation', 'FAVOURITES_DESC'),
  _FetchSpec('MANGA', 'manga', 'START_DATE_DESC'),
  _FetchSpec('ANIME', 'animation', 'START_DATE_DESC'),
  _FetchSpec('MANGA', 'manga', 'UPDATED_AT_DESC'),
  _FetchSpec('ANIME', 'animation', 'UPDATED_AT_DESC'),
];

Set<String> _collectExistingWorkIds(Directory shardsRoot) {
  final ids = <String>{};
  if (!shardsRoot.existsSync()) return ids;

  for (final entity in shardsRoot.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final decoded = json.decode(entity.readAsStringSync());
    if (decoded is Map<String, dynamic>) {
      ids.addAll(decoded.keys);
    }
  }
  return ids;
}

Future<List<Map<String, dynamic>>> _fetchMediaPage({
  required String type,
  required String category,
  required String sort,
  required int page,
  required int perPage,
}) async {
  const query = r'''
query ($page: Int, $perPage: Int, $type: MediaType, $sort: [MediaSort]) {
  Page(page: $page, perPage: $perPage) {
    media(sort: $sort, type: $type, isAdult: false) {
      id
      title { romaji english native }
      startDate { year }
      description(asHtml: false)
      genres
      coverImage { large }
    }
  }
}
''';

  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(_anilistEndpoint));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.add(
      utf8.encode(
        json.encode({
          'query': query,
          'variables': {
            'page': page,
            'perPage': perPage,
            'type': type,
            'sort': sort,
          },
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      print('AniList HTTP ${response.statusCode} ($type p$page)');
      return const [];
    }

    final decoded = json.decode(body) as Map<String, dynamic>;
    final pageData = decoded['data']?['Page'] as Map<String, dynamic>?;
    final media = pageData?['media'] as List<dynamic>? ?? const [];
    return media.whereType<Map<String, dynamic>>().toList();
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic>? _mediaToSeed(
  Map<String, dynamic> media,
  String category,
) {
  final anilistId = media['id'];
  if (anilistId is! int) return null;

  final titles = media['title'] as Map<String, dynamic>? ?? {};
  final romaji = titles['romaji']?.toString() ?? '';
  final english = titles['english']?.toString() ?? '';
  final native = titles['native']?.toString() ?? '';
  final displayTitle = native.isNotEmpty
      ? native
      : (english.isNotEmpty ? english : romaji);
  if (displayTitle.isEmpty) return null;

  final startDate = media['startDate'] as Map<String, dynamic>? ?? {};
  final year = (startDate['year'] as int?) ?? 2000;

  final slugBase = _slugify(romaji.isNotEmpty ? romaji : english);
  if (slugBase.isEmpty) return null;

  final slug = '$slugBase-a$anilistId';
  final workId = 'sub_${category}_${slug}_$year';

  final description = _stripHtml(media['description']?.toString() ?? '');
  final genres = (media['genres'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];

  final cover = media['coverImage'] as Map<String, dynamic>?;
  final poster = cover?['large']?.toString();
  final kind = category == 'animation' ? 'anime' : 'manga';
  final posterPath = poster ??
      'https://s4.anilist.co/file/anilistcdn/media/$kind/cover/large/bx$anilistId.jpg';

  return {
    'workId': workId,
    'title': displayTitle,
    'category': category,
    'domain': 'subculture',
    'creator': '',
    'releaseYear': year,
    'description': description.isEmpty
        ? 'AniList 인기 $category 작품 (id: $anilistId).'
        : description,
    'tags': genres.take(8).toList(),
    'posterPath': posterPath,
    'extensions': {
      'anilistId': anilistId,
      'seedSource': 'anilist_popularity',
    },
  };
}

String _slugify(String input) {
  final lower = input.toLowerCase();
  final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return replaced
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _stripHtml(String raw) {
  return raw
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&amp;', '&')
      .trim();
}

void _writeShard(Directory shardsRoot, Map<String, dynamic> seed) {
  final workId = seed['workId'] as String;
  final shardId = _shardIdFor(workId);
  final category = seed['category'] as String;
  final shardPath = '${shardsRoot.path}/$category/$shardId.json';
  final shardFile = File(shardPath);

  Map<String, dynamic> shardMap = {};
  if (shardFile.existsSync()) {
    final decoded = json.decode(shardFile.readAsStringSync());
    if (decoded is Map<String, dynamic>) {
      shardMap = Map<String, dynamic>.from(decoded);
    }
  }

  shardMap[workId] = seed;
  shardFile.parent.createSync(recursive: true);
  shardFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
  );
}

String _shardIdFor(String workId) {
  final parts = workId.split('_');
  if (parts.length < 4) return 'misc';
  final category = parts[1];
  final identifier = parts[2];

  if (category == 'game' && identifier.startsWith('appid')) {
    final appId = identifier.replaceFirst('appid', '');
    return 'game_steam_$appId';
  }

  if (category == 'manga' && RegExp(r'^\d').hasMatch(identifier)) {
    return 'manga_numeric';
  }

  final letter = identifier.isNotEmpty ? identifier[0].toUpperCase() : 'X';
  return '${category}_$letter';
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
