// ignore_for_file: avoid_print
// Product Value Review CLI — 5b 전 제품·정책 게이트.
//
// Usage:
//   dart run tool/discovery/product_value_review_cli.dart --live

import 'dart:io';

import 'package:path/path.dart' as p;

import 'contract_test_runner.dart';
import 'discovery_fixtures.dart';
import 'discovery_source_fetch.dart';
import 'discovery_manifest.dart';
import 'product_value_review.dart';
import 'registry_coverage_utils.dart';
import 'registry_diff_compare.dart';
import 'registry_impact_selector.dart';
import 'registry_snapshot.dart';
import 'registry_virtual_state.dart';
import 'shadow_write_runner.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final outputPath =
      _argValue(args, '--output') ??
      'akasha-db/pipeline/artifacts/product_value_report.md';
  final maxSelect = int.tryParse(_argValue(args, '--max') ?? '') ?? 10;
  final minSelect = int.tryParse(_argValue(args, '--min') ?? '') ?? 5;

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/product_value_review_cli.dart '
      '--offline | --live',
    );
    exit(64);
  }

  final channelId = _argValue(args, '--channel') ?? 'wikidata_manga';
  final root = _findProjectRoot();
  final manifest = DiscoveryManifest.load(root);
  final config = manifest.channel(channelId);
  if (config == null) {
    stderr.writeln('ERROR: unknown channel $channelId');
    exit(1);
  }

  print('product_value_review — $channelId — 5b 보류 / Product gate');
  print('  question: 외부 spine 존재 vs AKASHA 사용자 가치');
  print('');

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  final nodes = offline
      ? contractFixturesForChannel(config, config.trialBatchSize)
      : await fetchDiscoveryBatch(
          config: config,
          projectRoot: root,
        );

  final registry = RegistrySnapshot.load(root);
  final coverage = loadRegistryCoverage(root);
  final franchiseIndex = FranchiseAffinityIndex.load(
    projectRoot: root,
    registry: registry,
  );

  final shadowResult = ShadowWriteRunner.fromProject(root)
      .run(shadowInputsFromNodes(contractRunner, nodes));

  final scored = <ImpactSelectionScore>[];
  for (final item in shadowResult.items) {
    if (item.outcome != ShadowWriteOutcome.wouldCreate) continue;
    if (item.draft == null || item.draft!.isEmpty) continue;
    scored.add(
      scoreImpactCandidate(
        item: item,
        draft: item.draft!,
        coverage: coverage,
        franchiseIndex: franchiseIndex,
      ),
    );
  }

  final selected = selectImpactCandidates(
    scored: scored,
    minSelect: minSelect,
    maxSelect: maxSelect,
  );

  if (selected.isEmpty) {
    stderr.writeln('FAIL: no selection');
    exit(1);
  }

  final before = RegistryVirtualState.fromSnapshot(registry);
  final after = before.withAddedDrafts(
    selected.map((s) => s.item.draft!).toList(),
  );
  final diff = compareRegistrySnapshots(
    before: before,
    after: after,
    selected: selected,
  );

  final report = buildProductValueReview(
    selected: selected,
    diff: diff,
  );

  print('Discovery Product KPI:');
  print('  userValueCoverage: ${report.kpi.userValueCoverage.toStringAsFixed(3)}');
  print(
    '  userSearchGapResolved: ${report.kpi.userSearchGapResolved.toStringAsFixed(3)}',
  );
  print(
    '  independentRegistryValue: '
    '${report.kpi.independentRegistryValue.toStringAsFixed(3)}',
  );
  print('  recommend5bPatch: ${report.kpi.recommend5bPatch}');
  print('  (5b patch: ON HOLD until manual Product Review)');
  print('');

  final markdown = formatProductValueMarkdown(report);
  final out = File(p.join(root.path, outputPath));
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(markdown);
  print('Wrote: ${out.path}');
  print(markdown);
  print(formatProductValueJson(report));

  if (!report.kpi.recommend5bPatch) {
    stderr.writeln(
      '\nNOTE: Product KPI 미달 — 5b 보류 유지, 선정·정책 재검토',
    );
    exit(1);
  }
  print('\nOK: Product Value auto-gate passed — 수동 Review 후 5b 검토');
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
  return null;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
