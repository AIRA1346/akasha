// ignore_for_file: avoid_print
/// v3 슬러그 샤드 → v4 해시 샤드 (`hash(wk_) % 256`)
///
/// Usage:
///   dart run tool/migrate_shards_v3_to_v4_hash.dart
///   dart run tool/migrate_shards_v3_to_v4_hash.dart --apply --sync-assets
///
/// 산출물: `shards/{category}/{00..ff}.json` (sparse — 작품 있는 버킷만)

import 'dart:convert';
import 'dart:io';

import 'registry_hash_utils.dart';
import 'wk_id_utils.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final syncAssets = args.contains('--sync-assets');
  final root = _findProjectRoot();
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  final buckets = <String, Map<String, dynamic>>{};
  final legacyFiles = <File>[];
  var workCount = 0;

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    final category = p.basename(categoryDir.path);
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final base = p.basenameWithoutExtension(shardFile.path);
      if (isV4ShardFileName(base)) continue;

      legacyFiles.add(shardFile);
      final decoded = json.decode(shardFile.readAsStringSync());
      if (decoded is! Map) continue;

      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final work = Map<String, dynamic>.from(entry.value as Map);
        final workId = work['workId']?.toString() ?? entry.key.toString();
        if (!isWkId(workId)) {
          stderr.writeln('WARN: skip non-wk work in ${shardFile.path}: $workId');
          continue;
        }

        final hex = shardHexForWorkId(workId);
        final bucketKey = '$category::$hex';
        buckets.putIfAbsent(bucketKey, () => {});
        if (buckets[bucketKey]!.containsKey(workId)) {
          stderr.writeln('ERROR: duplicate workId $workId in bucket $bucketKey');
          exit(1);
        }
        buckets[bucketKey]![workId] = work;
        workCount++;
      }
    }
  }

  if (legacyFiles.isEmpty) {
    print('OK: no v3 slug shard files found (already v4?)');
    exit(0);
  }

  print('migrate_shards_v3_to_v4_hash');
  print('  works: $workCount');
  print('  v3 files to remove: ${legacyFiles.length}');
  print('  v4 buckets (sparse): ${buckets.length}');
  for (final key in buckets.keys.toList()..sort()) {
    final count = buckets[key]!.length;
    if (count > 8) {
      print('  WARN hot bucket $key: $count works');
    }
  }

  if (!apply) {
    print('\nDry-run — pass --apply to write v4 shards');
    exit(0);
  }

  final encoder = const JsonEncoder.withIndent('  ');
  for (final entry in buckets.entries) {
    final parts = entry.key.split('::');
    final category = parts[0];
    final hex = parts[1];
    final path = File('${shardsRoot.path}/$category/$hex.json');
    path.parent.createSync(recursive: true);
    path.writeAsStringSync('${encoder.convert(entry.value)}\n');
  }

  for (final f in legacyFiles) {
    f.deleteSync();
    print('  removed: ${f.path}');
  }

  print('\nOK: wrote ${buckets.length} v4 shard file(s)');

  final builder = await Process.start(
    Platform.resolvedExecutable,
    [
      'run',
      'tool/registry_builder.dart',
      if (syncAssets) '--sync-assets',
    ],
    workingDirectory: root.path,
    runInShell: true,
  );
  await stdout.addStream(builder.stdout);
  await stderr.addStream(builder.stderr);
  if (await builder.exitCode != 0) exit(1);
}

class p {
  static String basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  static String basenameWithoutExtension(String path) {
    final base = basename(path);
    final dot = base.lastIndexOf('.');
    return dot == -1 ? base : base.substring(0, dot);
  }
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
