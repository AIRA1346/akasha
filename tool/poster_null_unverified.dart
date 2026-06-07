// ignore_for_file: avoid_print
/// 검증되지 않은 posterPath를 null 처리합니다.
/// Usage: dart run tool/poster_null_unverified.dart [--apply]

import 'dart:convert';
import 'dart:io';

import 'poster_verification.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final root = _findProjectRoot();
  final cache = _loadPosterCache(root);
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  var scanned = 0;
  var nulled = 0;
  var kept = 0;

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
      if (poster.isEmpty) continue;

      scanned++;
      if (isPosterVerified(work, cache)) {
        kept++;
        continue;
      }

      nulled++;
      work.remove('posterPath');
      shard[entry.key] = work;
      dirty = true;
      print('NULL ${work['workId'] ?? entry.key}');
    }

    if (dirty && apply) {
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    }
  }

  print('Done: scanned=$scanned kept=$kept nulled=$nulled');
  if (!apply && nulled > 0) {
    print('Dry-run. Pass --apply to write shards.');
  }
}

Map<int, String> _loadPosterCache(Directory projectRoot) {
  final file = File('${projectRoot.path}/akasha-db/tmdb_poster_cache.json');
  if (!file.existsSync()) return {};
  final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
