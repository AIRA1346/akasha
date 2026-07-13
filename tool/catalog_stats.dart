// ignore_for_file: avoid_print
// 카탈로그 규모·카테고리·v3 title 필드 통계
// Usage: dart run tool/catalog_stats.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final projectRoot = _findProjectRoot();
  final manifest =
      jsonDecode(
            File(
              '${projectRoot.path}/akasha-db/manifest.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final shards = manifest['shards'] as List<dynamic>;
  final byCat = <String, int>{};
  var total = 0;
  var v3Titles = 0;

  for (final shardMeta in shards) {
    final path = '${projectRoot.path}/akasha-db/${shardMeta['path']}';
    final shard =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final cat = shardMeta['category'] as String;
    for (final entry in shard.entries) {
      if (entry.value is! Map<String, dynamic>) continue;
      final w = entry.value as Map<String, dynamic>;
      byCat[cat] = (byCat[cat] ?? 0) + 1;
      total++;
      if (w['titles'] != null) v3Titles++;
    }
  }

  print('Total: $total');
  print('v3 titles field: $v3Titles');
  print('By category:');
  for (final e
      in byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
    print('  ${e.key}: ${e.value}');
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('Could not find project root (pubspec.yaml)');
}
