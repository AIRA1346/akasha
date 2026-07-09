// ignore_for_file: avoid_print
// 레거시 정리 — posterPath 없는데 extensions.posterSource/posterVerified만
// 남은 작품에서 해당 provenance 키를 제거 (docs/data-policy.md provenance_warn).
//
// Usage:
//   dart run tool/cleanup_poster_source.dart            # dry-run
//   dart run tool/cleanup_poster_source.dart --apply    # 샤드 수정
//   dart run tool/cleanup_poster_source.dart --apply --sync-assets
//
// posterPath가 있는 작품은 건드리지 않는다. seasons/latestSeason 등은 보존.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

void main(List<String> args) {
  final apply = args.contains('--apply');
  final syncAssets = args.contains('--sync-assets');
  final root = _findProjectRoot();
  final shardsRoot = Directory(p.join(root.path, 'akasha-db', 'shards'));

  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  var worksCleaned = 0;
  var filesChanged = 0;
  final samples = <String>[];

  for (final dir in shardsRoot.listSync().whereType<Directory>()) {
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;

      final shard = Map<String, dynamic>.from(
        json.decode(file.readAsStringSync()) as Map,
      );
      var fileTouched = false;

      for (final entry in shard.entries) {
        if (entry.value is! Map) continue;
        final work = Map<String, dynamic>.from(entry.value as Map);
        final poster = work['posterPath']?.toString() ?? '';
        if (poster.isNotEmpty) continue;

        final ext = work['extensions'];
        if (ext is! Map) continue;
        final extensions = Map<String, dynamic>.from(ext);

        final removed = <String>[];
        if (extensions.containsKey('posterSource')) {
          extensions.remove('posterSource');
          removed.add('posterSource');
        }
        if (extensions.containsKey('posterVerified')) {
          extensions.remove('posterVerified');
          removed.add('posterVerified');
        }
        if (removed.isEmpty) continue;

        if (extensions.isEmpty) {
          work.remove('extensions');
        } else {
          work['extensions'] = extensions;
        }

        shard[entry.key] = work;
        worksCleaned++;
        fileTouched = true;
        if (samples.length < 10) {
          samples.add('${entry.key} (${removed.join(', ')})');
        }
      }

      if (fileTouched) {
        filesChanged++;
        if (apply) {
          final sorted = Map.fromEntries(
            shard.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          );
          file.writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
          );
        }
      }
    }
  }

  print('Poster provenance cleanup');
  print('  works to clean : $worksCleaned');
  print('  files affected : $filesChanged');
  for (final s in samples) {
    print('    - $s');
  }
  if (worksCleaned > samples.length) {
    print('    ... +${worksCleaned - samples.length} more');
  }

  if (!apply) {
    print('\nDry-run. Pass --apply to write shards.');
    return;
  }

  print('\nWrote $filesChanged shard file(s).');

  if (syncAssets) {
    print('\n==> registry_builder --sync-assets');
    final builder = Process.runSync(
      Platform.resolvedExecutable,
      ['run', 'tool/registry_builder.dart', '--sync-assets'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(builder.stdout);
    stderr.write(builder.stderr);
    if (builder.exitCode != 0) exit(builder.exitCode);
  } else {
    print('Next: dart run tool/registry_builder.dart --sync-assets');
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
