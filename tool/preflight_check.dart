// ignore_for_file: avoid_print
/// Registry 변경 후 4종 핵심 gate 일괄 실행.
///
/// Usage: dart run tool/preflight_check.dart

import 'dart:io';

void main() {
  final root = _root();
  final steps = [
    ('registry_builder', ['run', 'tool/registry_builder.dart']),
    ('dedupe_linter', ['run', 'tool/dedupe_linter.dart']),
    ('quality_gate --strict', ['run', 'tool/quality_gate.dart', '--strict']),
    ('coverage_dashboard', ['run', 'tool/coverage_dashboard.dart']),
  ];

  var failed = false;
  for (final step in steps) {
    print('\n==> ${step.$1}');
    final r = Process.runSync(
      Platform.resolvedExecutable,
      step.$2,
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(r.stdout);
    stderr.write(r.stderr);
    if (r.exitCode != 0) {
      print('FAIL: ${step.$1} exited ${r.exitCode}');
      failed = true;
    } else {
      print('OK: ${step.$1}');
    }
  }

  exit(failed ? 1 : 0);
}

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final p = dir.parent;
    if (p.path == dir.path) return Directory.current;
    dir = p;
  }
}
