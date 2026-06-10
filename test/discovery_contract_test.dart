import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/contract_test_runner.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_types.dart';

void main() {
  const config = DiscoveryChannelConfig(
    id: 'wikidata_manga',
    source: 'wikidata',
    category: 'manga',
    domain: 'subculture',
    enabled: false,
    dailyLimit: 500,
    trialBatchSize: 100,
    cursorPath: 'pipeline/discovery/cursors/wikidata_manga.json',
  );

  group('ContractTestRunner', () {
    test('wikidata manga fixtures produce 100 minimal core drafts offline', () {
      final nodes = List.generate(100, (i) {
        return {
          'qid': 'Q${700000 + i}',
          'title': 'Manga $i',
          'releaseYear': 2010,
          'category': 'manga',
        };
      });

      final runner = ContractTestRunner(
        channelId: 'wikidata_manga',
        config: config,
        registryExternalIds: const {},
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

    test('anilist source channel rejects all nodes', () {
      const anilistConfig = DiscoveryChannelConfig(
        id: 'anilist_manga',
        source: 'anilist',
        category: 'manga',
        domain: 'subculture',
        enabled: false,
        dailyLimit: 500,
        trialBatchSize: 100,
        cursorPath: 'pipeline/discovery/cursors/anilist_manga.json',
      );
      final runner = ContractTestRunner(
        channelId: 'anilist_manga',
        config: anilistConfig,
        registryExternalIds: const {},
      );
      final outcome = runner.processNode({
        'id': 101922,
        'format': 'MANGA',
        'title': {'english': 'Chainsaw Man'},
        'startDate': {'year': 2018},
      });
      expect(outcome, ContractNodeOutcome.policyRejected);
    });

    test('registry wikidata id counts as dedupe candidate', () {
      final runner = ContractTestRunner(
        channelId: 'wikidata_manga',
        config: config,
        registryExternalIds: {'Q1048'},
      );
      final outcome = runner.processNode({
        'qid': 'Q1048',
        'title': 'One Piece',
        'releaseYear': 1997,
        'category': 'manga',
      });
      expect(outcome, ContractNodeOutcome.dedupeCandidate);
    });

    test('missing title classified separately', () {
      final runner = ContractTestRunner(
        channelId: 'wikidata_manga',
        config: config,
        registryExternalIds: const {},
      );
      final outcome = runner.processNode({
        'qid': 'Q999',
        'title': '',
        'releaseYear': 2020,
        'category': 'manga',
      });
      expect(outcome, ContractNodeOutcome.missingTitle);
    });
  });
}
