// ignore_for_file: avoid_print
// 검증된 TMDB TV ID로 posterPath를 재등록합니다.
// Usage:
//   dart run tool/poster_fixup_tmdb.dart --fetch-posters --apply

import 'dart:convert';
import 'dart:io';

import 'poster_verification.dart';
import 'tmdb_tv_legacy_map.dart';

const _posterCacheFile = 'akasha-db/tmdb_poster_cache.json';
const _batch5SeedFile = 'tool/seed_expansion_batch5.dart';
const _batch6SeedFile = 'tool/seed_expansion_batch6.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final fetchPosters = args.contains('--fetch-posters');
  final root = _findProjectRoot();
  final shardsRoot = Directory('${root.path}/akasha-db/shards');
  final map = _buildTmdbMap(root);
  final cache = _loadPosterCache(root);

  if (fetchPosters) {
    await _warmPosterCache(map.values.toSet(), cache, root);
  }

  var applied = 0;
  var failed = 0;
  final client = createTmdbHttpClient();

  for (final shardFile in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!shardFile.path.endsWith('.json')) continue;

    final decoded = json.decode(shardFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) continue;

    var dirty = false;
    final shard = Map<String, dynamic>.from(decoded);

    for (final entry in shard.entries.toList()) {
      final workId = entry.key.toString();
      if (entry.value is! Map) continue;
      if (tmdbTvExplicitSkip.contains(workId)) continue;

      final tmdbId = map[workId];
      if (tmdbId == null) continue;

      final work = Map<String, dynamic>.from(entry.value as Map);
      final cachePath = cache[tmdbId];
      if (cachePath == null || cachePath.isEmpty) {
        failed++;
        print('FAIL $workId: no cache for tmdb $tmdbId');
        continue;
      }

      final pageTitle = await fetchTmdbPageTitle(client, tmdbId);
      if (pageTitle == null || !titlesMatchWork(work, pageTitle)) {
        failed++;
        print(
          'FAIL $workId: title mismatch tmdb $tmdbId '
          'page="${pageTitle ?? '?'}"',
        );
        continue;
      }

      final posterUrl = buildTmdbPosterUrl(cachePath);
      work['posterPath'] = posterUrl;

      final externalIds = Map<String, dynamic>.from(
        work['externalIds'] is Map
            ? Map<String, dynamic>.from(work['externalIds'] as Map)
            : {},
      );
      externalIds['tmdb'] = '$tmdbId';
      work['externalIds'] = externalIds;

      final extensions = Map<String, dynamic>.from(
        work['extensions'] is Map
            ? Map<String, dynamic>.from(work['extensions'] as Map)
            : {},
      );
      extensions['posterSource'] = 'tmdb';
      extensions['posterVerified'] = true;
      work['extensions'] = extensions;

      if (!isPosterVerified(work, cache)) {
        failed++;
        print('FAIL $workId: cache mismatch tmdb $tmdbId');
        continue;
      }

      applied++;
      shard[workId] = work;
      dirty = true;
      print('OK $workId → tmdb $tmdbId ($pageTitle)');
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    if (dirty && apply) {
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    } else if (dirty) {
      skipped += applied;
    }
  }

  client.close();
  print('Done: applied=$applied failed=$failed');
  if (!apply && applied > 0) {
    print('Dry-run. Pass --apply to write shards.');
  }
}

Map<String, int> _buildTmdbMap(Directory root) {
  final map = <String, int>{};
  map.addAll(_parseBatchTmdbIds(File('${root.path}/$_batch5SeedFile')));
  map.addAll(_parseBatchTmdbIds(File('${root.path}/$_batch6SeedFile')));
  map.addAll(tmdbTvOverrides);
  return map;
}

Map<String, int> _parseBatchTmdbIds(File seedFile) {
  if (!seedFile.existsSync()) return {};
  final src = seedFile.readAsStringSync();
  final map = <String, int>{};
  final entryRe = RegExp(
    r"workId:\s*'([^']+)'[\s\S]*?tmdbTvId:\s*(\d+)",
  );
  for (final m in entryRe.allMatches(src)) {
    final workId = m.group(1)!;
    final id = int.parse(m.group(2)!);
    if (id > 0) map[workId] = id;
  }
  return map;
}

Map<int, String> _loadPosterCache(Directory projectRoot) {
  final file = File('${projectRoot.path}/$_posterCacheFile');
  if (!file.existsSync()) return {};
  final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
}

void _savePosterCache(Directory projectRoot, Map<int, String> cache) {
  final sorted = Map.fromEntries(
    cache.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  final file = File('${projectRoot.path}/$_posterCacheFile');
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted.map((k, v) => MapEntry('$k', v)))}\n',
  );
}

Future<void> _warmPosterCache(
  Set<int> ids,
  Map<int, String> cache,
  Directory root,
) async {
  final client = createTmdbHttpClient();
  for (final id in ids) {
    await _scrapeTmdbPoster(client, 'tv', id, cache);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  client.close();
  _savePosterCache(root, cache);
  print('Poster cache: ${cache.length} entries');
}

Future<void> _scrapeTmdbPoster(
  HttpClient client,
  String type,
  int id,
  Map<int, String> cache,
) async {
  for (final mediaType in [type, 'tv', 'movie']) {
    final uri = Uri.parse('https://www.themoviedb.org/$mediaType/$id');
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      );
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) continue;
      final html = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      for (final pattern in [
        RegExp(
          r'property="og:image" content="https://media\.themoviedb\.org/t/p/w500([^"]+)"',
        ),
        RegExp(
          r'property="og:image" content="https://image\.tmdb\.org/t/p/w500([^"]+)"',
        ),
        RegExp(r'"poster_path":"(/[^"]+)"'),
      ]) {
        final m = pattern.firstMatch(html);
        if (m == null) continue;
        var path = m.group(1)!;
        if (!path.startsWith('/')) path = '/$path';
        cache[id] = path;
        return;
      }
    } catch (_) {}
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
