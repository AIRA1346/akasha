// ignore_for_file: avoid_print
/// official_sync — Discovery Contract Test Runner + sample dry-run.
///
/// Usage:
///   dart run tool/discovery/official_sync.dart --sample
///   dart run tool/discovery/official_sync.dart --contract-test
///   dart run tool/discovery/official_sync.dart --contract-test --offline
///
/// 원칙 (docs/discovery-policy.md):
/// - Fact만 생성, raw API·Signal Git 저장 금지
/// - Registry 쓰기 없음 (Contract Test 단계)
/// - enabled=false여도 --contract-test는 수동 실행 허용

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'contract_test_runner.dart';
import 'discovery_contract_kpi.dart';
import 'discovery_manifest.dart';
import 'discovery_types.dart';

void main(List<String> args) async {
  final channelId = _argValue(args, '--channel') ?? 'anilist_animation';
  final sample = args.contains('--sample');
  final contractTest = args.contains('--contract-test');
  final offline = args.contains('--offline');

  if (!sample && !contractTest) {
    stderr.writeln(
      'Usage: dart run tool/discovery/official_sync.dart '
      '--sample | --contract-test [--offline]',
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

  if (channelId != 'anilist_animation') {
    stderr.writeln('ERROR: contract test supports anilist_animation only');
    exit(1);
  }

  print('official_sync — $channelId');
  print('  mode: ${contractTest ? 'contract-test' : 'sample'}');
  print('  source: ${config.source}');
  print('  category: ${config.category}');
  print('  enabled: ${config.enabled} (ignored for manual contract-test)');
  print('  trialBatchSize: ${config.trialBatchSize}');
  print('  policy: docs/discovery-policy.md');
  print('');

  if (sample) {
    _runSample(channelId: channelId, config: config);
    return;
  }

  await _runContractTest(
    projectRoot: root,
    channelId: channelId,
    config: config,
    offline: offline,
  );
}

Future<void> _runContractTest({
  required Directory projectRoot,
  required String channelId,
  required DiscoveryChannelConfig config,
  required bool offline,
}) async {
  final runner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: projectRoot,
  );

  final DiscoveryContractKpi kpi;
  if (offline) {
    print('offline: fixture batch (${config.trialBatchSize} nodes)');
    kpi = runner.runOnNodes(_contractFixtures(config.trialBatchSize));
  } else {
    print('live: AniList GraphQL (${config.trialBatchSize} nodes, no disk write)');
    kpi = await runner.runLive(batchSize: config.trialBatchSize);
  }

  print('');
  print('Contract KPI:');
  print('  fetched: ${kpi.fetched}');
  print('  policyRejected: ${kpi.policyRejected}');
  print('  dedupeCandidates: ${kpi.dedupeCandidates}');
  print('  minimalCoreDrafts: ${kpi.minimalCoreDrafts}');
  print('  missingTitle: ${kpi.missingTitle}');
  print('  missingYearOrExternalId: ${kpi.missingYearOrExternalId}');
  print('');
  print(json.encode(kpi.toJson()));

  if (!kpi.contractPassed) {
    stderr.writeln('FAIL: Discovery contract not satisfied');
    exit(1);
  }
  print('\nOK: Discovery contract test passed');
}

void _runSample({
  required String channelId,
  required DiscoveryChannelConfig config,
}) {
  final runner = ContractTestRunner(
    channelId: channelId,
    config: config,
    registryAnilistIds: const {},
  );
  final kpi = runner.runOnNodes(_sampleAnilistNodes());
  print('Contract KPI (sample): ${json.encode(kpi.toJson())}');
  for (final node in _sampleAnilistNodes().take(3)) {
    final title = (node['title'] as Map?)?['english'] ?? node['id'];
    print('  - anilist:${node['id']} $title');
  }
  if (!kpi.contractPassed) exit(1);
  print('\nOK: official_sync sample (dry-run)');
}

/// 오프라인 계약 검증용 animation fixture (100건 고정 가능).
List<Map<String, dynamic>> _contractFixtures(int count) {
  return List.generate(count, (i) {
    final id = 200000 + i;
    final format = switch (i % 5) {
      0 => 'TV',
      1 => 'OVA',
      2 => 'ONA',
      3 => 'SPECIAL',
      _ => 'TV_SHORT',
    };
    final node = <String, dynamic>{
      'id': id,
      'format': format,
      'title': {
        'english': 'Contract Fixture $id',
        'romaji': 'Contract Fixture $id',
      },
      'seasonYear': 1990 + (i % 35),
      'studios': {
        'nodes': [
          {'name': 'Fixture Studio'},
        ],
      },
    };
    if (i.isEven) {
      node['synonyms'] = ['CF-$id'];
    }
    return node;
  });
}

List<Map<String, dynamic>> _sampleAnilistNodes() => [
      {
        'id': 1535,
        'format': 'TV',
        'title': {
          'romaji': 'Death Note',
          'english': 'Death Note',
          'native': 'デスノート',
        },
        'seasonYear': 2006,
        'studios': {
          'nodes': [{'name': 'Madhouse'}],
        },
        // fetch 응답에 섞일 수 있으나 Facts·draft에는 남지 않아야 함
        'description': 'MUST NOT APPEAR IN DRAFT',
        'coverImage': {'large': 'https://anilistcdn.example/x.jpg'},
      },
      {
        'id': 16498,
        'format': 'TV',
        'title': {
          'romaji': 'Shingeki no Kyojin',
          'english': 'Attack on Titan',
        },
        'startDate': {'year': 2013},
      },
    ];

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
