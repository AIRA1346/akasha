// ignore_for_file: avoid_print
/// Registry Snapshot Compare — 5b 전 마지막 검증.
///
/// Usage:
///   dart run tool/discovery/registry_diff_test.dart --live
///   dart run tool/discovery/registry_diff_test.dart --live \
///     --output akasha-db/pipeline/artifacts/registry_diff_report.md

import 'dart:io';

import 'package:path/path.dart' as p;

import 'anilist_client.dart';
import 'contract_test_runner.dart';
import 'discovery_manifest.dart';
import 'registry_coverage_utils.dart';
import 'registry_diff_compare.dart';
import 'registry_diff_report.dart';
import 'registry_impact_selector.dart';
import 'registry_snapshot.dart';
import 'registry_virtual_state.dart';
import 'shadow_write_runner.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final channelId = _argValue(args, '--channel') ?? 'anilist_animation';
  final outputPath =
      _argValue(args, '--output') ??
      'akasha-db/pipeline/artifacts/registry_diff_report.md';
  final maxSelect = int.tryParse(_argValue(args, '--max') ?? '') ?? 10;
  final minSelect = int.tryParse(_argValue(args, '--min') ?? '') ?? 5;

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/registry_diff_test.dart --offline | --live',
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

  print('registry_diff_test — Snapshot Compare (5b gate)');
  print('  before: current Registry');
  print('  after:  virtual + selected drafts');
  print('  disk write: none');
  print('');

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  final nodes = offline
      ? _fixtures(config.trialBatchSize)
      : await fetchAnilistAnimationBatch(
          batchSize: config.trialBatchSize,
          requiredCategory: config.category,
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
    stderr.writeln('FAIL: no candidates for diff');
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

  print('Compare: ${diff.entriesBefore} → ${diff.entriesAfter} (virtual)');
  print('  zeroToHit: ${diff.zeroToHitCount}');
  print('  userVisibleWins: ${diff.userVisibleWins.length}');
  print('  diffStrong: ${diff.diffStrong}');
  print('  recommend5bPatch: ${diff.recommend5bPatch}');
  print('');

  final markdown = formatRegistryDiffMarkdown(
    diff: diff,
    selectedTitles: selected.map((s) => s.item.title).toList(),
  );

  final out = File(p.join(root.path, outputPath));
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(markdown);
  print('Wrote: ${out.path}');
  print('');
  print(markdown);
  print(formatRegistryDiffJson(diff));

  if (!diff.recommend5bPatch) {
    stderr.writeln(
      '\nNOTE: diff 미달 — Product Value Review 전 5b 보류',
    );
    exit(1);
  }
  print('\nOK: Registry Improvement (기술) — 다음: Product Value Review');
  print('  5b patch: ON HOLD (제품·정책 게이트)');
}

List<Map<String, dynamic>> _fixtures(int count) {
  return List.generate(count, (i) {
    final id = 800000 + i;
    return {
      'id': id,
      'format': 'TV',
      'title': {'english': 'Diff Unique $id', 'romaji': 'Diff$id'},
      'synonyms': ['DU-$id'],
      'seasonYear': 1998,
      'studios': {
        'nodes': [
          {'name': 'Diff Studio'},
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
