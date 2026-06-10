import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_source_fetch.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_types.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/wikidata_client.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/wikidata_facts.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/wikidata_q_validation.dart';

void main() {
  group('wikidata_facts', () {
    test('binding to node extracts qid and ko-primary title', () {
      final node = wikidataBindingToNode({
        'item': {'value': 'http://www.wikidata.org/entity/Q1048'},
        'itemLabel': {'value': 'One Piece'},
        'itemLabelKo': {'value': '원피스'},
        'itemLabelJa': {'value': 'ワンピース'},
        'authorLabel': {'value': 'Eiichiro Oda'},
        'startYear': {'value': '1997'},
      });
      expect(node['qid'], 'Q1048');
      expect(node['title'], '원피스');
      final titles = node['titles'] as Map;
      expect(titles['ko'], '원피스');
      expect(titles['en'], 'One Piece');
      expect(node['releaseYear'], 1997);
    });

    test('binding falls back to en when ko absent', () {
      final node = wikidataBindingToNode({
        'item': {'value': 'http://www.wikidata.org/entity/Q1'},
        'itemLabel': {'value': 'Test Manga'},
      });
      expect(node['title'], 'Test Manga');
    });
  });

  group('wikidata_client', () {
    test('fetch batch parses SPARQL JSON', () async {
      const fakeJson = '''
{
  "results": {
    "bindings": [
      {
        "item": {"value": "http://www.wikidata.org/entity/Q1"},
        "itemLabel": {"value": "Test Manga"},
        "startYear": {"value": "2000"}
      }
    ]
  }
}
''';
      final nodes = await fetchWikidataMangaBatch(
        batchSize: 1,
        runQuery: ({required query, required client}) async => fakeJson,
      );
      expect(nodes, hasLength(1));
      expect(nodes.first['qid'], 'Q1');
    });
  });

  group('wikidata_q_validation', () {
    test('blocks known bad Kimetsu hallucination Q-id', () {
      final r = validateWikidataQidForIngest(
        qid: 'Q61093122',
        category: 'animation',
        title: 'Demon Slayer',
      );
      expect(r.verdict, WikidataQValidationVerdict.block);
      expect(r.code, 'V0_known_bad');
    });

    test('passes Kimetsu manga SSOT Q-id', () {
      final r = validateWikidataQidForIngest(
        qid: kimetsuWikidataSsot['manga']!,
        category: 'manga',
        title: 'Demon Slayer: Kimetsu no Yaiba',
        entityP31Qids: {'Q21198342'},
      );
      expect(r.verdict, WikidataQValidationVerdict.pass);
    });

    test('blocks duplicate Q in registry set', () {
      final r = validateWikidataQidForIngest(
        qid: 'Q24862683',
        category: 'manga',
        title: 'Kimetsu',
        registryWikidataQids: {'Q24862683'},
      );
      expect(r.verdict, WikidataQValidationVerdict.block);
      expect(r.code, 'V4_duplicate');
    });
  });

  group('discovery_source_fetch', () {
    test('anilist source throws unsupported', () async {
      const config = DiscoveryChannelConfig(
        id: 'anilist_manga',
        source: 'anilist',
        category: 'manga',
        domain: 'subculture',
        enabled: false,
        dailyLimit: 500,
        trialBatchSize: 10,
        cursorPath: 'x',
      );
      expect(
        () => fetchDiscoveryBatch(config: config),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
