import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/anilist_facts.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/contract_test_runner.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_types.dart';

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

  group('ContractTestRunner', () {
    test('animation fixtures produce 100 minimal core drafts offline', () {
      final nodes = List.generate(100, (i) {
        return {
          'id': 300000 + i,
          'format': 'TV',
          'title': {'english': 'Anime $i'},
          'seasonYear': 2010,
        };
      });

      final runner = ContractTestRunner(
        channelId: 'anilist_animation',
        config: config,
        registryAnilistIds: const {},
      );
      final kpi = runner.runOnNodes(nodes);

      expect(kpi.fetched, 100);
      expect(kpi.policyRejected, 0);
      expect(kpi.missingTitle, 0);
      expect(kpi.missingYearOrExternalId, 0);
      expect(kpi.minimalCoreDrafts, 100);
      expect(kpi.dedupeCandidates, 0);
      expect(kpi.contractPassed, isTrue);
    });

    test('manga format rejected for animation channel', () {
      final runner = ContractTestRunner(
        channelId: 'anilist_animation',
        config: config,
        registryAnilistIds: const {},
      );
      final outcome = runner.processNode({
        'id': 101922,
        'format': 'MANGA',
        'title': {'english': 'Chainsaw Man'},
        'startDate': {'year': 2018},
      });
      expect(outcome, ContractNodeOutcome.policyRejected);
    });

    test('registry anilist id counts as dedupe candidate', () {
      final runner = ContractTestRunner(
        channelId: 'anilist_animation',
        config: config,
        registryAnilistIds: {'1535'},
      );
      final outcome = runner.processNode({
        'id': 1535,
        'format': 'TV',
        'title': {'english': 'Death Note'},
        'seasonYear': 2006,
      });
      expect(outcome, ContractNodeOutcome.dedupeCandidate);
    });

    test('missing title classified separately', () {
      final runner = ContractTestRunner(
        channelId: 'anilist_animation',
        config: config,
        registryAnilistIds: const {},
      );
      final outcome = runner.processNode({
        'id': 999,
        'format': 'TV',
        'title': {'english': '', 'romaji': ''},
        'seasonYear': 2020,
      });
      expect(outcome, ContractNodeOutcome.missingTitle);
    });

    test('facts never contain forbidden keys from polluted API node', () {
      final runner = ContractTestRunner(
        channelId: 'anilist_animation',
        config: config,
        registryAnilistIds: const {},
      );
      final kpi = runner.runOnNodes([
        {
          'id': 1,
          'format': 'TV',
          'title': {'english': 'Clean Anime'},
          'seasonYear': 2020,
          'description': 'must be ignored',
          'coverImage': {'large': 'https://example.com/x.jpg'},
          'tags': [{'name': 'Action'}],
        },
      ]);
      expect(kpi.policyRejected, 0);
      expect(kpi.minimalCoreDrafts, 1);
      expect(findForbiddenKeysInMap({'title': 'Clean Anime'}), isEmpty);
    });
  });
}
