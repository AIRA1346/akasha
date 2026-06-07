// ignore_for_file: avoid_print
/// CI/로컬 레지스트리 검증 — 샤드 유효성 + 프랜차이즈 누락 탐지
///
/// Usage: dart run tool/ci_registry_check.dart
///
/// Exit 0 = OK, 1 = validation or franchise linter issues

import 'dart:io';

void main(List<String> args) {
  final root = _findProjectRoot();
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

  exit(failed ? 1 : 0);
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
