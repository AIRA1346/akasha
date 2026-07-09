// ignore_for_file: avoid_print
// manifest v4 + 샤드 sha256 일관성 검증
//
// Usage: dart run tool/manifest_v4_check.dart

import 'dart:convert';
import 'dart:io';

import 'registry_hash_utils.dart';

void main() {
  final root = _findProjectRoot();
  final manifestFile = File('${root.path}/akasha-db/manifest.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('FAIL: manifest.json not found');
    exit(1);
  }

  final errors = <String>[];
  final manifest = Map<String, dynamic>.from(
    json.decode(manifestFile.readAsStringSync()) as Map,
  );

  final version = int.tryParse(manifest['version']?.toString() ?? '') ?? 0;
  if (version != 4) {
    errors.add('manifest.version must be 4 (got $version)');
  }

  final shardBits =
      int.tryParse(manifest['shardBits']?.toString() ?? '') ?? 0;
  if (shardBits != defaultShardBits) {
    errors.add('manifest.shardBits must be $defaultShardBits (got $shardBits)');
  }

  final shards = manifest['shards'];
  if (shards is! List) {
    errors.add('manifest.shards must be a list');
    exit(1);
  }

  var totalEntries = 0;
  final seenIds = <String>{};
  final seenPaths = <String>{};

  for (final item in shards) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final id = map['id']?.toString() ?? '';
    final path = map['path']?.toString() ?? '';
    final category = map['category']?.toString() ?? '';
    final entryCount =
        int.tryParse(map['entryCount']?.toString() ?? '') ?? -1;
    final expectedSha = map['sha256']?.toString() ?? '';

    if (id.isEmpty || path.isEmpty) {
      errors.add('shard missing id/path');
      continue;
    }
    if (!seenIds.add(id)) errors.add('duplicate shard id: $id');
    if (!seenPaths.add(path)) errors.add('duplicate shard path: $path');

    final hex = id.startsWith('${category}_')
        ? id.substring(category.length + 1)
        : '';
    if (!isV4ShardFileName(hex)) {
      errors.add('shard id not v4 hex format: $id');
    }
    if (path != v4ShardPath(category, hex)) {
      errors.add('shard path mismatch for $id: $path');
    }

    final file = File('${root.path}/akasha-db/$path');
    if (!file.existsSync()) {
      errors.add('shard file missing: $path');
      continue;
    }

    final content = file.readAsStringSync();
    final actualSha = sha256HexUtf8(content);
    if (expectedSha.isEmpty) {
      errors.add('shard $id missing sha256');
    } else if (expectedSha != actualSha) {
      errors.add('shard $id sha256 mismatch');
    }

    final decoded = json.decode(content);
    if (decoded is! Map) {
      errors.add('shard $id root must be object');
      continue;
    }
    if (decoded.length != entryCount) {
      errors.add(
        'shard $id entryCount $entryCount != file keys ${decoded.length}',
      );
    }
    totalEntries += decoded.length;

    for (final entry in decoded.entries) {
      final workId = entry.key.toString();
      final expectedHex = shardHexForWorkId(workId);
      if (expectedHex != hex) {
        errors.add(
          'work $workId in $id but hash bucket is $expectedHex',
        );
      }
    }
  }

  final declaredTotal =
      int.tryParse(manifest['entryCount']?.toString() ?? '');
  if (declaredTotal != null && declaredTotal != totalEntries) {
    errors.add(
      'manifest.entryCount $declaredTotal != summed shards $totalEntries',
    );
  }

  if (errors.isNotEmpty) {
    stderr.writeln('FAIL: ${errors.length} manifest v4 issue(s):');
    for (final e in errors.take(25)) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }

  print(
    'OK: manifest v4 (${shards.length} shards, $totalEntries works, '
    'shardBits=$shardBits)',
  );
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
