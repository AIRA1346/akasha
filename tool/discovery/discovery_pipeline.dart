/// Discovery 파이프라인 공용 — Contract → Shadow → Impact → Diff.
library;

import 'dart:io';

import 'anilist_client.dart';
import 'contract_test_runner.dart';
import 'discovery_manifest.dart';
import 'discovery_types.dart';
import 'registry_coverage_utils.dart';
import 'registry_diff_compare.dart';
import 'registry_impact_selector.dart';
import 'registry_snapshot.dart';
import 'registry_virtual_state.dart';
import 'shadow_write_runner.dart';

class DiscoveryPipelineResult {
  final List<ImpactSelectionScore> selected;
  final List<ImpactSelectionScore> scored;
  final ShadowWriteResult shadow;
  final RegistryDiffResult diff;
  final RegistryVirtualState before;
  final RegistryVirtualState after;
  final RegistryCoverageSnapshot coverage;

  const DiscoveryPipelineResult({
    required this.selected,
    required this.scored,
    required this.shadow,
    required this.diff,
    required this.before,
    required this.after,
    required this.coverage,
  });
}

Future<DiscoveryPipelineResult> runDiscoveryPipeline({
  required Directory projectRoot,
  required List<Map<String, dynamic>> nodes,
  int minSelect = 5,
  int maxSelect = 10,
  String channelId = 'anilist_animation',
}) async {
  final manifest = DiscoveryManifest.load(projectRoot);
  final config = manifest.channel(channelId);
  if (config == null) {
    throw StateError('unknown channel $channelId');
  }

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: projectRoot,
  );

  final registry = RegistrySnapshot.load(projectRoot);
  final coverage = loadRegistryCoverage(projectRoot);
  final franchiseIndex = FranchiseAffinityIndex.load(
    projectRoot: projectRoot,
    registry: registry,
  );

  final shadow = ShadowWriteRunner.fromProject(projectRoot)
      .run(shadowInputsFromNodes(contractRunner, nodes));

  final scored = <ImpactSelectionScore>[];
  for (final item in shadow.items) {
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

  final before = RegistryVirtualState.fromSnapshot(registry);
  final after = before.withAddedDrafts(
    selected.map((s) => s.item.draft!).toList(),
  );

  final diff = compareRegistrySnapshots(
    before: before,
    after: after,
    selected: selected,
  );

  return DiscoveryPipelineResult(
    selected: selected,
    scored: scored,
    shadow: shadow,
    diff: diff,
    before: before,
    after: after,
    coverage: coverage,
  );
}

Future<List<Map<String, dynamic>>> fetchPipelineNodes({
  required DiscoveryChannelConfig config,
  required bool offline,
  required int fixtureOffset,
}) async {
  if (offline) {
    return List.generate(config.trialBatchSize, (i) {
      final id = fixtureOffset + i;
      return {
        'id': id,
        'format': 'TV',
        'title': {'english': 'Pipeline Fixture $id', 'romaji': 'PF$id'},
        'synonyms': ['PF-$id'],
        'seasonYear': 1998 + (i % 25),
        'studios': {
          'nodes': [
            {'name': 'Fixture Studio'},
          ],
        },
      };
    });
  }
  return fetchAnilistAnimationBatch(
    batchSize: config.trialBatchSize,
    requiredCategory: config.category,
  );
}
