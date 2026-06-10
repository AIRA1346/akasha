// ignore_for_file: avoid_print
/// Phase B — Registry Impact Test (실제 쓰기 전 영향·선정 리포트).
///
/// Usage:
///   dart run tool/discovery/registry_impact_test.dart --live
///   dart run tool/discovery/registry_impact_test.dart --offline
///   dart run tool/discovery/registry_impact_test.dart --live \
///     --output akasha-db/pipeline/artifacts/impact_report.md
///
/// 산출물: 왜 5~10건을 선택했는가 + Coverage·검색 품질 KPI
/// 실제 shard patch는 수동 승인 후 별도 단계

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'contract_test_runner.dart';
import 'discovery_fixtures.dart';
import 'discovery_manifest.dart';
import 'discovery_source_fetch.dart';
import 'registry_coverage_utils.dart';
import 'registry_impact_report.dart';
import 'registry_impact_selector.dart';
import 'registry_snapshot.dart';
import 'shadow_write_runner.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final channelId = _argValue(args, '--channel') ?? 'wikidata_manga';
  final outputPath = _argValue(args, '--output');
  final maxSelect = int.tryParse(_argValue(args, '--max') ?? '') ?? 10;
  final minSelect = int.tryParse(_argValue(args, '--min') ?? '') ?? 5;

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/registry_impact_test.dart '
      '--offline | --live [--min 5] [--max 10] [--output path]',
    );
    exit(64);
  }

  final root = _findProjectRoot();
  final manifest = DiscoveryManifest.load(root);
  final config = manifest.channel(channelId);
  if (config == null) {
    stderr.writeln('ERROR: unknown channel $channelId');
    exit(1);
  }

  print('registry_impact_test — Phase B');
  print('  channel: $channelId');
  print('  mode: ${offline ? 'offline' : 'live'}');
  print('  select: $minSelect~$maxSelect (Gap·Core·Franchise)');
  print('  disk write: none (Impact Report only)');
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

  final report = buildRegistryImpactReport(
    channelId: channelId,
    shadowResult: shadowResult,
    coverageBefore: coverage,
    selected: selected,
  );

  print('Impact selection: ${selected.length} / ${scored.length} wouldCreate');
  print('  gapFills: ${report.kpi.gapFillsCount}');
  print('  novelSearchTokens: ${report.kpi.totalNovelSearchTokens}');
  print('  mergeCandidates: ${report.kpi.mergeCandidateCount} (link queue)');
  print('  recommendPhaseC: ${report.kpi.recommendPhaseC}');
  print('');

  final markdown = formatRegistryImpactMarkdown(report);
  if (outputPath != null) {
    final out = File(p.join(root.path, outputPath));
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(markdown);
    print('Wrote: ${out.path}');
  }

  print(markdown);
  print('JSON: ${json.encode(report.toJson())}');

  if (selected.isEmpty) {
    stderr.writeln('FAIL: no impact candidates selected');
    exit(1);
  }
  print('\nOK: Registry Impact Report generated');
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
