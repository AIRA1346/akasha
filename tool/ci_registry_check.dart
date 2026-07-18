// ignore_for_file: avoid_print
// CI/로컬 레지스트리 검증 — 샤드 유효성 + 프랜차이즈 누락 탐지
//
// Usage: dart run tool/ci_registry_check.dart [--skip-bundle] [--skip-dedupe]
//
// Exit 0 = OK, 1 = validation or franchise linter issues

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final root = _findProjectRoot();
  final skipBundle =
      args.contains('--skip-bundle') || args.contains('--skip-builder');
  final skipDedupe = args.contains('--skip-dedupe');
  var failed = false;

  if (!skipBundle) {
    print('==> deterministic full-bundle contract');
    final builder = Process.runSync(
      Platform.resolvedExecutable,
      ['run', 'tool/registry_bundle_ci.dart'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(builder.stdout);
    stderr.write(builder.stderr);
    if (builder.exitCode != 0) {
      failed = true;
      print('FAIL: registry_bundle_ci exited ${builder.exitCode}');
    } else {
      print('OK: registry_bundle_ci');
    }
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

  print('\n==> legacy works_registry Fact-only check');
  if (_legacyHasForbiddenTier1Content(root)) {
    failed = true;
    print(
      'FAIL: akasha-db/works_registry.json still contains '
      'posterPath or description',
    );
  } else {
    print('OK: legacy works_registry is Fact-only');
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

  print('\n==> id_registry consistency');
  final idReg = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/id_registry_check.dart'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(idReg.stdout);
  stderr.write(idReg.stderr);
  if (idReg.exitCode != 0) {
    failed = true;
    print('FAIL: id_registry_check exited ${idReg.exitCode}');
  }

  print('\n==> manifest v4');
  final v4 = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/manifest_v4_check.dart'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(v4.stdout);
  stderr.write(v4.stderr);
  if (v4.exitCode != 0) {
    failed = true;
    print('FAIL: manifest_v4_check exited ${v4.exitCode}');
  }

  print('\n==> discovery_manifest_check');
  final discoveryManifest = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/discovery_manifest_check.dart'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(discoveryManifest.stdout);
  stderr.write(discoveryManifest.stderr);
  if (discoveryManifest.exitCode != 0) {
    failed = true;
    print(
      'FAIL: discovery_manifest_check exited ${discoveryManifest.exitCode}',
    );
  } else {
    print('OK: discovery_manifest_check');
  }

  print('\n==> data_policy_linter (strict)');
  final dataPolicy = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/data_policy_linter.dart', '--strict'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(dataPolicy.stdout);
  stderr.write(dataPolicy.stderr);
  if (dataPolicy.exitCode != 0) {
    failed = true;
    print('FAIL: data_policy_linter exited ${dataPolicy.exitCode}');
  } else {
    print('OK: data_policy_linter');
  }

  if (!skipDedupe) {
    print('\n==> dedupe_linter');
    final dedupe = Process.runSync(
      Platform.resolvedExecutable,
      ['run', 'tool/dedupe_linter.dart'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(dedupe.stdout);
    stderr.write(dedupe.stderr);
    if (dedupe.exitCode != 0) {
      failed = true;
      print('FAIL: dedupe_linter exited ${dedupe.exitCode}');
    } else {
      print('OK: dedupe_linter');
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

bool _legacyHasForbiddenTier1Content(Directory root) {
  final file = File('${root.path}/akasha-db/works_registry.json');
  if (!file.existsSync()) return false;
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map) return true;
  for (final value in decoded.values) {
    if (value is! Map) continue;
    if (value.containsKey('posterPath') || value.containsKey('description')) {
      return true;
    }
  }
  return false;
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
