// ignore_for_file: avoid_print
/// Shadow Write — Registry 영향 측정 (실제 shard 쓰기 없음).
///
/// Usage:
///   dart run tool/discovery/shadow_write.dart --offline
///   dart run tool/discovery/shadow_write.dart --live
///
/// Contract Test → Shadow Write 파이프라인:
///   Minimal Core Draft → wk_ 할당 → shard·dedupe → registry_builder 시뮬레이션

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'anilist_client.dart';
import 'contract_test_runner.dart';
import 'discovery_manifest.dart';
import 'shadow_write_kpi.dart';
import 'shadow_write_runner.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final channelId = _argValue(args, '--channel') ?? 'anilist_animation';

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/shadow_write.dart --offline | --live',
    );
    exit(64);
  }

  if (channelId != 'anilist_animation') {
    stderr.writeln('ERROR: shadow write supports anilist_animation only');
    exit(1);
  }

  final root = _findProjectRoot();
  final manifest = DiscoveryManifest.load(root);
  final config = manifest.channel(channelId);
  if (config == null) {
    stderr.writeln('ERROR: unknown channel $channelId');
    exit(1);
  }

  print('shadow_write — $channelId');
  print('  mode: ${offline ? 'offline' : 'live'}');
  print('  trialBatchSize: ${config.trialBatchSize}');
  print('  registry: read-only snapshot');
  print('  disk write: none');
  print('');

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  final List<Map<String, dynamic>> nodes;
  if (offline) {
    nodes = _contractFixtures(config.trialBatchSize);
  } else {
    print('fetching AniList (${config.trialBatchSize} animation nodes)...');
    nodes = await fetchAnilistAnimationBatch(
      batchSize: config.trialBatchSize,
      requiredCategory: config.category,
    );
  }

  final inputs = shadowInputsFromNodes(contractRunner, nodes);
  final shadowRunner = ShadowWriteRunner.fromProject(root);
  final result = shadowRunner.run(inputs);
  _printKpi(result.kpi);

  if (result.kpi.mergeCandidates > 0) {
    print('\nMerge candidates — fuzzy dedupe (up to 5):');
    var shown = 0;
    for (final item in result.items) {
      if (item.outcome != ShadowWriteOutcome.mergeCandidate) continue;
      print('  - anilist:${item.externalId} ${item.title} → ${item.matchedWorkId}');
      if (++shown >= 5) break;
    }
  }

  if (result.kpi.wouldReject > 0) {
    print('\nPolicy reject (up to 5):');
    var shown = 0;
    for (final item in result.items) {
      if (item.outcome != ShadowWriteOutcome.wouldReject) continue;
      print('  - anilist:${item.externalId} ${item.title}');
      print('    reason: ${item.reason}');
      if (++shown >= 5) break;
    }
  }

  if (result.kpi.wouldCreate > 0) {
    print('\nCreate samples (up to 3):');
    var shown = 0;
    for (final item in result.items) {
      if (item.outcome != ShadowWriteOutcome.wouldCreate) continue;
      print(
        '  - ${item.shadowWorkId} anilist:${item.externalId} '
        'score=${item.qualityScore} tier=${item.qualityTier} '
        'shard=${item.targetShard}',
      );
      if (++shown >= 3) break;
    }
  }

  print('\n${json.encode(result.kpi.toJson())}');

  if (!result.kpi.mirroringIntegrityPassed) {
    stderr.writeln(
      '\nNOTE: mirroringIntegrityPassed=false — policy/contract 위반 검토',
    );
    exit(1);
  }
  print('\nOK: shadow write analysis complete');
}

void _printKpi(ShadowWriteKpi kpi) {
  print('Shadow KPI:');
  print('  wouldCreate: ${kpi.wouldCreate}');
  print('  wouldMerge: ${kpi.wouldMerge}');
  print('  mergeCandidates: ${kpi.mergeCandidates}');
  print('  wouldReject: ${kpi.wouldReject}');
  print('  mirroringIntegrityPassed: ${kpi.mirroringIntegrityPassed}');
  print('  duplicateRate: ${kpi.duplicateRate.toStringAsFixed(3)}');
  print('  qualityScore: min=${kpi.qualityScoreMin} max=${kpi.qualityScoreMax} '
      'mean=${kpi.qualityScoreMean.toStringAsFixed(1)}');
  print('  qualityTierDistribution: ${kpi.qualityTierDistribution}');
  print('  maxShardConcentration: ${kpi.maxShardConcentration.toStringAsFixed(3)}');
  print('  lowTierRatio (tier 0~1): ${kpi.lowTierRatio.toStringAsFixed(3)}');
  print('  registrySimulation: ${kpi.registrySimulation.durationMs}ms '
      '${kpi.registrySimulation.existingEntryCount} → '
      '${kpi.registrySimulation.projectedEntryCount} entries');
}

List<Map<String, dynamic>> _contractFixtures(int count) {
  return List.generate(count, (i) {
    final id = 400000 + i;
    return {
      'id': id,
      'format': 'TV',
      'title': {
        'english': 'Shadow Fixture $id',
        'romaji': 'Shadow Fixture $id',
      },
      'seasonYear': 2000 + (i % 25),
      'studios': {
        'nodes': [
          {'name': 'Shadow Studio'},
        ],
      },
    };
  });
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
