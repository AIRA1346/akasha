// ignore_for_file: avoid_print
/// AniList Removal Test — AKASHA 독립 Registry 증명.
///
/// Usage:
///   dart run tool/discovery/anilist_removal_cli.dart --live

import 'dart:io';

import 'package:path/path.dart' as p;

import 'anilist_removal_test.dart';
import 'discovery_kpi.dart';
import 'discovery_manifest.dart';
import 'discovery_pipeline.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final outputPath =
      _argValue(args, '--output') ??
      'akasha-db/pipeline/artifacts/anilist_removal_report.md';

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/anilist_removal_cli.dart --offline | --live',
    );
    exit(64);
  }

  final root = _findProjectRoot();
  final manifest = DiscoveryManifest.load(root);
  final channelId = _argValue(args, '--channel') ?? 'wikidata_manga';
  final config = manifest.channel(channelId);
  if (config == null) exit(1);

  print('source_independence_test — Registry identity gate');
  print('  channel: $channelId (no AniList ingest)');
  print('  5b: ON HOLD');
  print('');

  final nodes = await fetchPipelineNodes(
    config: config,
    offline: offline,
    fixtureOffset: 1_000_000,
  );

  final pipeline = await runDiscoveryPipeline(
    projectRoot: root,
    nodes: nodes,
    channelId: channelId,
  );

  if (pipeline.selected.isEmpty) {
    stderr.writeln('FAIL: no selection');
    exit(1);
  }

  var gapResolved = 0;
  var gapFills = 0;
  for (final s in pipeline.selected) {
    final title = s.item.title;
    final id = s.item.shadowWorkId;
    if (pipeline.diff.searchWins.any(
      (w) => w.query == title && w.wasZeroBefore && w.newTopWorkId == id,
    )) {
      gapResolved++;
    }
    if (s.gap.fillsTitleGap) gapFills++;
  }

  final coverageDelta = pipeline.selected.isEmpty
      ? 0.0
      : gapFills / pipeline.selected.length;

  final aliasBefore = pipeline.diff.coverageBefore.rate(
    pipeline.diff.coverageBefore.withAliases,
  );
  final aliasAfter = pipeline.diff.coverageAfter.rate(
    pipeline.diff.coverageAfter.withAliases,
  );

  final productKpi = buildProductKpiV2(
    selectedCount: pipeline.selected.length,
    searchGapResolvedCount: gapResolved,
    aliasCoverageBefore: aliasBefore,
    aliasCoverageAfter: aliasAfter,
    zeroToHit: pipeline.diff.zeroToHitCount,
    searchProbeCount: pipeline.diff.searchWins.length,
    franchiseGainCount: pipeline.diff.franchiseGains.length,
  );

  final technicalKpi = buildTechnicalKpi(
    wouldCreate: pipeline.shadow.kpi.wouldCreate,
    mergeCandidates: pipeline.shadow.kpi.mergeCandidates,
    coverageDelta: coverageDelta,
    zeroToHit: pipeline.diff.zeroToHitCount,
  );

  final removalReport = buildAniListRemovalReport(
    selected: pipeline.selected,
    registryBefore: pipeline.before,
    diff: pipeline.diff,
  );

  final patchGate = DiscoveryPatchGate(
    recommend5bPatch: pipeline.diff.recommend5bPatch,
    productReviewApproved: productKpi.productReviewApproved,
    anilistRemovalTestPassed: removalReport.kpi.anilistRemovalTestPassed,
  );

  print('Independence KPI:');
  print(
    '  percentWorksJustifiedWithoutAniList: '
    '${(removalReport.kpi.percentWorksJustifiedWithoutAniList * 100).toStringAsFixed(1)}%',
  );
  print('  PASS: ${removalReport.kpi.passCount} FAIL: ${removalReport.kpi.failCount}');
  print('  anilistRemovalTestPassed: ${removalReport.kpi.anilistRemovalTestPassed}');
  print('  allow5bReview: ${patchGate.allow5bReview}');
  print('');

  final markdown = formatAniListRemovalMarkdown(
    report: removalReport,
    technical: technicalKpi,
    product: productKpi,
    patchGate: patchGate,
  );

  final out = File(p.join(root.path, outputPath));
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(markdown);
  print('Wrote: ${out.path}');
  print(markdown);
  print(formatAniListRemovalJson(removalReport));

  if (!patchGate.anilistRemovalTestPassed) {
    stderr.writeln('\nNOTE: AniList Removal Test 미달 — 5b 보류');
    exit(1);
  }
  if (!patchGate.allow5bReview) {
    stderr.writeln('\nNOTE: Patch gate 미완 — 5b 보류 (수동 검토)');
    exit(1);
  }
  print('\nOK: Independence + Patch gate — 수동 승인 후 5b 검토 가능');
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
