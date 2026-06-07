// ignore_for_file: avoid_print
/// CI/로컬 레지스트리 검증 — 샤드 유효성 + 프랜차이즈 누락 탐지
///
/// Usage: dart run tool/ci_registry_check.dart
///
/// Exit 0 = OK, 1 = validation or franchise linter issues

import 'dart:convert';
import 'dart:io';

import 'poster_url_policy.dart';

void main(List<String> args) {
  final root = _findProjectRoot();
  final updateBaseline = args.contains('--update-poster-baseline');
  var failed = false;

  print('==> registry_builder (validate shards)');
  final builder = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/registry_builder.dart'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(builder.stdout);
  stderr.write(builder.stderr);
  if (builder.exitCode != 0) {
    failed = true;
    print('FAIL: registry_builder exited ${builder.exitCode}');
  } else {
    print('OK: registry_builder');
  }

  print('\n==> franchise_linter');
  final linter = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/franchise_linter.dart'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(linter.stdout);
  stderr.write(linter.stderr);
  if (linter.exitCode != 0) {
    failed = true;
    print('FAIL: franchise_linter exited ${linter.exitCode}');
  } else {
    print('OK: franchise_linter');
  }

  print('\n==> legacy works_registry JustWatch check');
  if (_legacyHasJustWatch(root)) {
    failed = true;
    print('FAIL: akasha-db/works_registry.json still contains justwatch URLs');
  } else {
    print('OK: no justwatch in legacy works_registry');
  }

  print('\n==> AniList bulk seed prohibition');
  final bulkCount = _countAnilistBulkShards(root);
  if (bulkCount > 0) {
    failed = true;
    print('FAIL: found $bulkCount AniList bulk work(s) in akasha-db/shards');
  } else {
    print('OK: no AniList bulk seeds');
  }

  if (File('${root.path}/tool/seed_expansion_anilist.dart').existsSync()) {
    failed = true;
    print('FAIL: tool/seed_expansion_anilist.dart must be removed');
  } else {
    print('OK: seed_expansion_anilist.dart absent');
  }

  print('\n==> poster URL policy (link-only, denylist)');
  final posterScan = scanRegistryPosters(root);
  if (updateBaseline) {
    final counts = <String, int>{
      for (final pattern in incrementDenylistPatterns)
        pattern: posterScan.patternCounts[pattern] ?? 0,
    };
    writePosterBaseline(root, counts);
    print('OK: updated $posterUrlBaselineFile → $counts');
  } else {
    final baseline = readPosterBaseline(root);
    final posterErrors = validatePosterScan(posterScan, baseline);
    if (posterErrors.isNotEmpty) {
      failed = true;
      print('FAIL: ${posterErrors.length} poster policy violation(s):');
      for (final e in posterErrors.take(20)) {
        print('  - $e');
      }
      if (posterErrors.length > 20) {
        print('  ... and ${posterErrors.length - 20} more');
      }
    } else {
      print(
        'OK: poster policy (${posterScan.workCount} works, '
        'baseline $baseline)',
      );
    }
  }

  exit(failed ? 1 : 0);
}

int _countAnilistBulkShards(Directory root) {
  final shardsRoot = Directory('${root.path}/akasha-db/shards');
  if (!shardsRoot.existsSync()) return 0;
  var count = 0;
  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;
    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = entry.key.toString();
      final ext = work['extensions'];
      if (ext is Map && ext['seedSource']?.toString() == 'anilist_popularity') {
        count++;
        continue;
      }
      final parts = workId.split('_');
      if (parts.length >= 4 && RegExp(r'-a\d+$').hasMatch(parts[2])) {
        count++;
      }
    }
  }
  return count;
}

bool _legacyHasJustWatch(Directory root) {
  final file = File('${root.path}/akasha-db/works_registry.json');
  if (!file.existsSync()) return false;
  return file.readAsStringSync().contains('justwatch.com');
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
