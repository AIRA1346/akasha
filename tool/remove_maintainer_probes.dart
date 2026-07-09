// ignore_for_file: avoid_print
// A5 Scale/Pilot maintainer probe 엔트리를 registry shard에서 제거.
//
// Usage:
//   dart run tool/remove_maintainer_probes.dart
//   dart run tool/remove_maintainer_probes.dart --apply --build

import 'dart:convert';
import 'dart:io';

bool _isMaintainerProbeWorkId(String workId) {
  return workId.contains('scale-supply') ||
      workId.contains('scale-exp') ||
      workId.contains('pilot-h1-supply') ||
      workId.contains('pilot-h2-smoke');
}

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final build = args.contains('--build');
  final root = _findProjectRoot();
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  var removed = 0;
  var touchedShards = 0;

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final raw = shardFile.readAsStringSync();
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) continue;

      final shard = Map<String, dynamic>.from(decoded);
      final toRemove =
          shard.keys.where((k) => _isMaintainerProbeWorkId(k)).toList();
      if (toRemove.isEmpty) continue;

      for (final key in toRemove) {
        print('${apply ? "REMOVE" : "WOULD_REMOVE"} $key (${shardFile.path})');
        if (apply) shard.remove(key);
        removed++;
      }
      if (!apply) continue;

      touchedShards++;
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    }
  }

  print('');
  print(
    'Summary: ${apply ? "removed" : "would remove"} $removed probe(s), '
    '$touchedShards shard(s) touched',
  );
  if (!apply && removed > 0) {
    print('Dry-run. Pass --apply to write shards.');
  }

  if (apply && build && removed > 0) {
    print('');
    print('==> registry_builder --sync-assets');
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'tool/registry_builder.dart', '--sync-assets'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) exit(result.exitCode);
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find project root (pubspec.yaml)');
    }
    dir = parent;
  }
}
