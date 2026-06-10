// ignore_for_file: avoid_print
/// Discovery 수동 검증 리포트 — wouldCreate 샘플 10건.
///
/// Usage:
///   dart run tool/discovery/review_report.dart --offline
///   dart run tool/discovery/review_report.dart --live
///   dart run tool/discovery/review_report.dart --live --output akasha-db/pipeline/artifacts/review.md

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'contract_test_runner.dart';
import 'discovery_fixtures.dart';
import 'discovery_manifest.dart';
import 'discovery_source_fetch.dart';
import 'discovery_review_report.dart';
import 'registry_snapshot.dart';
import 'shadow_write_runner.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final channelId = _argValue(args, '--channel') ?? 'wikidata_manga';
  final outputPath = _argValue(args, '--output');
  final sampleSize =
      int.tryParse(_argValue(args, '--sample') ?? '') ?? 10;

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/review_report.dart --offline | --live '
      '[--sample 10] [--output path]',
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

  print('review_report — $channelId');
  print('  mode: ${offline ? 'offline' : 'live'}');
  print('  sample: $sampleSize / wouldCreate');
  print('  purpose: AKASHA Identity 검증 (Trial Write 전 수동 리뷰)');
  print('');

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  final List<Map<String, dynamic>> nodes;
  if (offline) {
    nodes = contractFixturesForChannel(config, config.trialBatchSize);
  } else {
    print('fetching ${config.source} (${config.trialBatchSize} nodes)...');
    nodes = await fetchDiscoveryBatch(
      config: config,
      projectRoot: root,
    );
  }

  final registry = RegistrySnapshot.load(root);
  final shadowResult = ShadowWriteRunner.fromProject(root)
      .run(shadowInputsFromNodes(contractRunner, nodes));

  print('Shadow summary:');
  print('  wouldCreate: ${shadowResult.kpi.wouldCreate}');
  print('  mergeCandidates: ${shadowResult.kpi.mergeCandidates}');
  print('  wouldMerge: ${shadowResult.kpi.wouldMerge}');
  print('  wouldReject: ${shadowResult.kpi.wouldReject}');
  print('  mirroringIntegrityPassed: ${shadowResult.kpi.mirroringIntegrityPassed}');
  print('');

  if (shadowResult.kpi.mergeCandidates > 0) {
    print('mergeCandidates (fuzzy dedupe success):');
    for (final item in shadowResult.items
        .where((i) => i.outcome == ShadowWriteOutcome.mergeCandidate)
        .take(5)) {
      print(
        '  - ${config.source}:${item.externalId} "${item.title}" → ${item.matchedWorkId}',
      );
    }
    print('');
  }

  final report = buildDiscoveryReviewReport(
    channelId: channelId,
    shadowResult: shadowResult,
    registry: registry,
    sampleSize: sampleSize,
  );

  final markdown = formatReviewReportMarkdown(report);
  if (outputPath != null) {
    final out = File(p.join(root.path, outputPath));
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(markdown);
    print('Wrote: ${out.path}');
  }

  print(markdown);

  print('User Value (sample): ${report.userValueSummary}');
  print('');
  print('JSON summary:');
  print(json.encode({
    'readyForTrialWrite': report.readyForTrialWrite,
    'mirroringIntegrityPassed': report.shadowKpi.mirroringIntegrityPassed,
    'wouldCreate': report.wouldCreateTotal,
    'mergeCandidates': report.mergeCandidatesTotal,
    'userValueSummary': report.userValueSummary,
    'sampleCount': report.samples.length,
  }));

  if (!report.readyForTrialWrite) {
    stderr.writeln(
      '\nNOTE: readyForTrialWrite=false — 수동 체크리스트 검토 후 Phase B 진행',
    );
    exit(1);
  }
  print('\nOK: review report generated (auto gates passed)');
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
