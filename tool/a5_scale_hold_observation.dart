// ignore_for_file: avoid_print
/// A5 Scale — SD2.6 hold 구간 정기 관측 (insert 없음).
///
/// O8 · O9 · O12 · O7(ja backlog) · coverage 스냅샷.
///
/// Usage: dart run tool/a5_scale_hold_observation.dart [--apply]
///
/// 산출: akasha-db/pipeline/artifacts/coverage_dashboard/scale_hold_observation.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'coverage_quality.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final root = _root();
  final sw = Stopwatch()..start();

  print('=== Scale hold observation (SD2.6 — no insert) ===\n');

  final steps = <Map<String, dynamic>>[];
  var failed = false;

  for (final spec in _subprocessSteps) {
    final stepSw = Stopwatch()..start();
    final r = Process.runSync(
      Platform.resolvedExecutable,
      ['run', 'tool/${spec.$1}', '--report'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stepSw.stop();
    final ok = r.exitCode == 0;
    if (!ok) failed = true;
    print('${ok ? "PASS" : "FAIL"} ${spec.$1} — ${stepSw.elapsedMilliseconds}ms');
    steps.add({
      'tool': spec.$1,
      'observation': spec.$2,
      'wallMs': stepSw.elapsedMilliseconds,
      'exitCode': r.exitCode,
      'status': ok ? 'PASS' : 'FAIL',
    });
  }

  final works = loadRegistryWorkMaps(root);
  final jaBacklog = _maintainerJaBacklog(works);
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;

  Map<String, dynamic>? coverageSnapshot;
  final snapFile = File(
    p.join(
      root.path,
      'akasha-db',
      'pipeline',
      'artifacts',
      'coverage_dashboard',
      'coverage_snapshot.json',
    ),
  );
  if (snapFile.existsSync()) {
    coverageSnapshot = jsonDecode(snapFile.readAsStringSync()) as Map<String, dynamic>;
  }

  sw.stop();

  final o7PauseRisk = jaBacklog.length >= 4;

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'phase': 'SD2.6_hold',
    'insertAllowed': false,
    'works': manifest['entryCount'],
    'wallMsTotal': sw.elapsedMilliseconds,
    'bundleStatus': failed ? 'FAIL' : 'PASS',
    'steps': steps,
    'o7': {
      'maintainerStubJaBacklog': jaBacklog.length,
      'sd35PauseThreshold': 4,
      'pauseRisk': o7PauseRisk,
      'backlogWorkIds': jaBacklog,
    },
    'coverage': coverageSnapshot != null
        ? {
            'titles_en': coverageSnapshot['titles_en'],
            'titles_ja': coverageSnapshot['titles_ja'],
            'external_id': coverageSnapshot['external_id'],
          }
        : null,
    'artifacts': [
      'scale_governance_o8.json',
      'scale_semantic_o9.json',
      'scale_franchise_o12.json',
      'coverage_snapshot.json',
    ],
  };

  print('\nO7 ja backlog (maintainer stub): ${jaBacklog.length}');
  print('SD3.5 pause risk: $o7PauseRisk');
  print('Bundle: ${failed ? "FAIL" : "PASS"} (${sw.elapsedMilliseconds}ms)');

  if (apply) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    );
    outDir.createSync(recursive: true);
    final out = File(p.join(outDir.path, 'scale_hold_observation.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  } else {
    print('Dry-run — pass --apply to write report');
  }

  exit(failed ? 1 : 0);
}

const _subprocessSteps = [
  ('a5_scale_governance_observation.dart', 'O8'),
  ('a5_scale_semantic_spotcheck.dart', 'O9'),
  ('a5_scale_franchise_queue.dart', 'O12'),
  ('coverage_dashboard.dart', 'O7_coverage'),
];

List<String> _maintainerJaBacklog(List<Map<String, dynamic>> works) {
  final backlog = <String>[];
  for (final work in works) {
    final workId = work['workId']?.toString() ?? '';
    if (!workId.contains('_scale-supply-') && !workId.contains('_pilot-h1-supply-')) {
      continue;
    }
    final titles = work['titles'];
    if (titles is! Map) {
      backlog.add(workId);
      continue;
    }
    final ja = titles['ja']?.toString().trim();
    if (ja == null || ja.isEmpty) backlog.add(workId);
  }
  return backlog;
}

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
