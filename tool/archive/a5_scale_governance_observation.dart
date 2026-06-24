// ignore_for_file: avoid_print
/// A5 Scale ??O8 governance bundle wall-time ê´€ì¸?
///
/// Usage: dart run tool/archive/a5_scale_governance_observation.dart [--apply]
///
/// ?°ì¶œ: akasha-db/pipeline/artifacts/coverage_dashboard/scale_governance_o8.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

void main(List<String> args) {
  final apply = args.contains('--apply') || args.contains('--report');
  final root = _root();
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final works = manifest['entryCount'] as int? ?? manifest['works'] as int? ?? 0;

  final steps = [
    ('registry_builder', ['run', 'tool/registry_builder.dart']),
    ('dedupe_linter', ['run', 'tool/dedupe_linter.dart']),
    ('quality_gate_strict', ['run', 'tool/quality_gate.dart', '--strict']),
    ('coverage_dashboard', ['run', 'tool/coverage_dashboard.dart']),
    ('sw1_a_validation', ['run', 'tool/sw1_a_validation.dart']),
    ('urv_a_validation', ['run', 'tool/urv_a_validation.dart']),
    ('franchise_linter', ['run', 'tool/franchise_linter.dart']),
  ];

  print('=== Scale O8 governance bundle (@$works works) ===\n');
  final results = <Map<String, dynamic>>[];
  var totalWallMs = 0;

  for (final step in steps) {
    final sw = Stopwatch()..start();
    final r = Process.runSync(
      Platform.resolvedExecutable,
      step.$2,
      workingDirectory: root.path,
      runInShell: true,
    );
    sw.stop();
    totalWallMs += sw.elapsedMilliseconds;

    final ok = r.exitCode == 0;
    print(
      '${ok ? "PASS" : "FAIL"} ${step.$1} ??${sw.elapsedMilliseconds}ms (exit ${r.exitCode})',
    );
    results.add({
      'tool': step.$1,
      'wallMs': sw.elapsedMilliseconds,
      'exitCode': r.exitCode,
      'status': ok ? 'PASS' : 'FAIL',
    });
  }

  final extrapolate = (int targetWorks) {
    final factor = works == 0 ? 1.0 : targetWorks / works;
    return {
      'targetWorks': targetWorks,
      'linearWallMs': (totalWallMs * factor).round(),
      'linearWallMinutes': ((totalWallMs * factor) / 60000).toStringAsFixed(2),
    };
  };

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'observation': 'O8',
    'works': works,
    'bundleWallMs': totalWallMs,
    'bundleWallMinutes': (totalWallMs / 60000).toStringAsFixed(2),
    'steps': results,
    'bundleStatus': results.every((s) => s['status'] == 'PASS') ? 'PASS' : 'FAIL',
    'extrapolationLinear': [extrapolate(5000), extrapolate(50000)],
    'cadenceHypothesis': {
      'releaseBlock': 'preflight_check + SW1 + URV per registry release',
      'sd4Reference': 'docs/programs/a5-scale-operational-decisions.md SD4.1',
    },
  };

  print('\nBundle total: ${totalWallMs}ms (${report['bundleWallMinutes']} min)');

  if (apply) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    );
    outDir.createSync(recursive: true);
    final out = File(p.join(outDir.path, 'scale_governance_o8.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  } else {
    print('\nDry-run ??pass --apply to write report');
  }
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
