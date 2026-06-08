import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/contract_test_runner.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_types.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_snapshot.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_runner.dart';

void main() {
  const config = DiscoveryChannelConfig(
    id: 'anilist_animation',
    source: 'anilist',
    category: 'animation',
    domain: 'subculture',
    enabled: false,
    dailyLimit: 500,
    trialBatchSize: 100,
    cursorPath: 'pipeline/discovery/cursors/anilist_animation.json',
  );

  RegistrySnapshot emptyRegistry() =>
      RegistrySnapshot.fromWorks(const []);

  ShadowWriteRunner runner({
    RegistrySnapshot? registry,
    int nextSeq = 500,
  }) {
    return ShadowWriteRunner(
      projectRoot: Directory.systemTemp,
      registry: registry ?? emptyRegistry(),
      allowedPairs: const {},
      franchisePeers: const {},
      nextWkSequence: nextSeq,
    );
  }

  group('ShadowWriteRunner', () {
    test('wouldCreate assigns shadow wk_ and shard', () {
      final result = runner().run([
        ShadowDraftInput(
          contractOutcome: ContractNodeOutcome.minimalCoreDraft,
          externalId: '900001',
          title: 'Unique Anime Alpha',
          draft: {
            'workId': 'wk_CONTRACT_DRAFT',
            'title': 'Unique Anime Alpha',
            'category': 'animation',
            'domain': 'subculture',
            'releaseYear': 2020,
            'externalIds': {'anilist': '900001'},
          },
        ),
      ]);

      expect(result.kpi.wouldCreate, 1);
      expect(result.kpi.wouldMerge, 0);
      expect(result.kpi.wouldReject, 0);
      expect(result.items.first.shadowWorkId, 'wk_000000500');
      expect(result.items.first.targetShard, isNotNull);
      expect(result.items.first.qualityScore, greaterThan(0));
      expect(result.kpi.shadowPassed, isTrue);
    });

    test('wouldMerge when anilist id already in registry', () {
      final registry = RegistrySnapshot.fromWorks([
        RegistryWorkEntry(
          workId: 'wk_000000010',
          title: 'Existing Anime',
          category: 'animation',
          releaseYear: 2010,
          externalIds: {'anilist': '1535'},
          legacyIds: const [],
          normalizedTitles: const {'existinganime'},
          work: const {
            'workId': 'wk_000000010',
            'title': 'Existing Anime',
            'category': 'animation',
            'domain': 'subculture',
            'externalIds': {'anilist': '1535'},
          },
        ),
      ]);

      final result = runner(registry: registry).run([
        ShadowDraftInput(
          contractOutcome: ContractNodeOutcome.minimalCoreDraft,
          externalId: '1535',
          title: 'Death Note',
          draft: {
            'workId': 'wk_CONTRACT_DRAFT',
            'title': 'Death Note',
            'category': 'animation',
            'domain': 'subculture',
            'releaseYear': 2006,
            'externalIds': {'anilist': '1535'},
          },
        ),
      ]);

      expect(result.kpi.wouldMerge, 1);
      expect(result.kpi.wouldCreate, 0);
      expect(result.kpi.duplicateRate, 1.0);
    });

    test('fuzzy title duplicate is mergeCandidate not wouldReject', () {
      final registry = RegistrySnapshot.fromWorks([
        RegistryWorkEntry(
          workId: 'wk_000000020',
          title: 'Naruto',
          category: 'animation',
          releaseYear: 2002,
          externalIds: const {},
          legacyIds: const [],
          normalizedTitles: const {'naruto'},
          work: const {
            'workId': 'wk_000000020',
            'title': 'Naruto',
            'category': 'animation',
            'domain': 'subculture',
            'releaseYear': 2002,
          },
        ),
      ]);

      final result = runner(registry: registry).run([
        ShadowDraftInput(
          contractOutcome: ContractNodeOutcome.minimalCoreDraft,
          externalId: '999001',
          title: 'Naruto',
          draft: {
            'workId': 'wk_CONTRACT_DRAFT',
            'title': 'Naruto',
            'category': 'animation',
            'domain': 'subculture',
            'releaseYear': 2002,
            'externalIds': {'anilist': '999001'},
          },
        ),
      ]);

      expect(result.kpi.mergeCandidates, 1);
      expect(result.kpi.wouldReject, 0);
      expect(result.kpi.wouldCreate, 0);
      expect(result.items.first.outcome, ShadowWriteOutcome.mergeCandidate);
      expect(result.items.first.matchedWorkId, 'wk_000000020');
      expect(result.kpi.mirroringIntegrityPassed, isTrue);
    });

    test('quality scores are not all tier 0-1 for minimal core batch', () {
      final contractRunner = ContractTestRunner(
        channelId: 'anilist_animation',
        config: config,
        registryAnilistIds: const {},
      );
      final nodes = List.generate(10, (i) {
        return {
          'id': 500000 + i,
          'format': 'TV',
          'title': {'english': 'Score Test $i'},
          'seasonYear': 2015,
          'studios': {
            'nodes': [
              {'name': 'Studio $i'},
            ],
          },
        };
      });
      final inputs = shadowInputsFromNodes(contractRunner, nodes);
      final result = runner().run(inputs);

      expect(result.kpi.wouldCreate, 10);
      expect(result.kpi.qualityScoreMin, greaterThanOrEqualTo(20));
      expect(result.kpi.lowTierRatio, lessThan(1.0));
    });
  });
}
