// ignore_for_file: avoid_print
/// TMDB TV 페이지 제목과 작품명을 대조해 오매핑 포스터를 null 처리합니다.
/// Usage: dart run tool/poster_validate_tmdb.dart [--apply] [--fetch]

import 'dart:convert';
import 'dart:io';

import 'poster_verification.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final fetch = args.contains('--fetch');
  final root = _findProjectRoot();
  final shardsRoot = Directory('${root.path}/akasha-db/shards');
  final client = createTmdbHttpClient();

  var checked = 0;
  var kept = 0;
  var nulled = 0;
  var skipped = 0;

  for (final shardFile in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!shardFile.path.endsWith('.json')) continue;
    final decoded = json.decode(shardFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) continue;

    var dirty = false;
    final shard = Map<String, dynamic>.from(decoded);

    for (final entry in shard.entries.toList()) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final poster = work['posterPath']?.toString() ?? '';
      if (poster.isEmpty || !poster.contains('image.tmdb.org')) {
        skipped++;
        continue;
      }

      final tmdbId = resolveTmdbId(work);
      if (tmdbId == null) {
        print('NULL ${work['workId'] ?? entry.key}: no tmdb id');
        _stripPoster(work);
        nulled++;
        dirty = true;
        shard[entry.key] = work;
        continue;
      }

      checked++;
      if (fetch) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      final tmdbTitle =
          fetch ? await fetchTmdbPageTitle(client, tmdbId) : null;
      final ok = tmdbTitle != null && titlesMatchWork(work, tmdbTitle);

      if (ok) {
        kept++;
        stdout.writeln('KEEP ${work['workId'] ?? entry.key}: tmdb $tmdbId');
        continue;
      }

      nulled++;
      stdout.writeln(
        'NULL ${work['workId'] ?? entry.key}: tmdb $tmdbId '
        'page="${tmdbTitle ?? '?'}"',
      );
      _stripPoster(work);
      dirty = true;
      shard[entry.key] = work;
    }

    if (dirty && apply) {
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    }
  }

  client.close();
  print('Done: checked=$checked kept=$kept nulled=$nulled skipped=$skipped');
  if (!apply && nulled > 0) print('Dry-run. Pass --apply to write.');
}

void _stripPoster(Map<String, dynamic> work) {
  work.remove('posterPath');
  final ext = work['extensions'];
  if (ext is Map) {
    final copy = Map<String, dynamic>.from(ext);
    copy.remove('posterVerified');
    if (copy.isEmpty) {
      work.remove('extensions');
    } else {
      work['extensions'] = copy;
    }
  }
  final ids = work['externalIds'];
  if (ids is Map) {
    final copy = Map<String, dynamic>.from(ids);
    copy.remove('tmdb');
    if (copy.isEmpty) {
      work.remove('externalIds');
    } else {
      work['externalIds'] = copy;
    }
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
