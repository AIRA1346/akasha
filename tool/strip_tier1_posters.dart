// ignore_for_file: avoid_print
// Tier 1 shard에서 posterPath·포스터 provenance 제거 (v1 유저 볼트 전용 정책).
//
// Usage:
//   dart run tool/strip_tier1_posters.dart [--apply] [--sync-assets]
//
// --apply 없으면 dry-run. --sync-assets 시 registry_builder + assets 동기화.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final syncAssets = args.contains('--sync-assets');
  final root = _findProjectRoot();
  final shardsRoot = Directory(p.join(root.path, 'akasha-db', 'shards'));

  var stripped = 0;
  var filesTouched = 0;

  for (final shardFile in shardsRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    final decoded = json.decode(shardFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) continue;

    var dirty = false;
    final shard = Map<String, dynamic>.from(decoded);

    for (final entry in shard.entries.toList()) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key;
      final hadPoster = work.containsKey('posterPath') &&
          (work['posterPath']?.toString().isNotEmpty ?? false);

      if (work.containsKey('posterPath')) {
        work.remove('posterPath');
        dirty = true;
      }

      final extensions = work['extensions'];
      if (extensions is Map) {
        final ext = Map<String, dynamic>.from(extensions);
        var extDirty = false;
        for (final key in ['posterSource', 'posterVerified']) {
          if (ext.remove(key) != null) extDirty = true;
        }
        if (extDirty) {
          work['extensions'] = ext.isEmpty ? null : ext;
          if (work['extensions'] == null) work.remove('extensions');
          dirty = true;
        }
      }

      final signals = work['qualitySignals'];
      if (signals is Map) {
        final qs = Map<String, dynamic>.from(signals);
        if (qs.remove('hasPoster') != null ||
            qs.remove('posterVerified') != null) {
          work['qualitySignals'] = qs.isEmpty ? null : qs;
          if (work['qualitySignals'] == null) work.remove('qualitySignals');
          dirty = true;
        }
      }

      if (hadPoster) {
        stripped++;
        print('STRIP $workId');
      }
      if (dirty) shard[entry.key] = work;
    }

    if (dirty) {
      filesTouched++;
      if (apply) {
        shardFile.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
        );
      }
    }
  }

  print(
    'Done: posterPath stripped from $stripped works, $filesTouched shard files',
  );
  if (!apply && stripped > 0) {
    print('Dry-run. Pass --apply to write shards.');
    exit(0);
  }

  if (apply && syncAssets) {
    print('Running registry_builder --sync-assets ...');
    final result = await Process.run(
      Platform.executable,
      ['run', 'tool/registry_builder.dart', '--sync-assets'],
      workingDirectory: root.path,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      exit(result.exitCode);
    }
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find project root');
    }
    dir = parent;
  }
}
