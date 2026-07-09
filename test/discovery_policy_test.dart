import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/anilist_facts.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_types.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/signal_gate.dart';

void main() {
  final sampleMedia = {
    'id': 101922,
    'format': 'MANGA',
    'title': {
      'romaji': 'Chainsaw Man',
      'english': 'Chainsaw Man',
      'native': 'チェンソーマン',
    },
    'synonyms': ['CSM', 'チェンソーマン'],
    'startDate': {'year': 2018},
    'description': '외부 시놉 — 반드시 폐기',
    'coverImage': {'large': 'https://anilistcdn.example/x.jpg'},
    'bannerImage': {'large': 'https://example.com/banner.jpg'},
    'tags': [{'name': 'Action'}],
    'averageScore': 85,
    'popularity': 120000,
  };

  group('extractAnilistFacts', () {
    test('extracts only allowed facts', () {
      final facts = extractAnilistFacts(sampleMedia);
      expect(facts.title, 'Chainsaw Man');
      expect(facts.releaseYear, 2018);
      expect(facts.titles['en'], 'Chainsaw Man');
      expect(facts.aliases, contains('CSM'));
      expect(facts.format, 'MANGA');

      final json = facts.toJson();
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('coverImage'), isFalse);
      expect(json.containsKey('tags'), isFalse);
      expect(json.containsKey('popularity'), isFalse);
      expect(findForbiddenKeysInMap(json), isEmpty);
    });

    test('picks manga creator from staff role', () {
      final facts = extractAnilistFacts({
        'id': 1,
        'format': 'MANGA',
        'title': {'english': 'Test Manga'},
        'startDate': {'year': 2020},
        'staff': {
          'edges': [
            {
              'role': 'Story & Art',
              'node': {
                'name': {'full': 'Test Mangaka'},
              },
            },
          ],
        },
      });
      expect(facts.creator, 'Test Mangaka');
    });

    test('wikidata node produces minimal core draft', () {
      final signal = wikidataNodeToSignal(
        channelId: 'wikidata_manga',
        node: {
          'qid': 'Q1048',
          'title': 'One Piece',
          'titles': {'en': 'One Piece', 'ja': 'ワンピース'},
          'releaseYear': 1997,
          'creator': 'Eiichiro Oda',
          'category': 'manga',
        },
      );
      final draft = signalToMinimalCoreDraft(
        signal: signal,
        workId: 'wk_000000001',
      );
      expect(draft['externalIds'], {'wikidata': 'Q1048'});
      expect(draft['category'], 'manga');
      expect(findForbiddenKeysInMap(draft), isEmpty);
    });

    test('format maps to category via signal', () {
      final signal = anilistNodeToSignal(
        channelId: 'anilist_animation',
        media: sampleMedia,
      );
      expect(signal.externalId, '101922');
      expect(signal.source, 'anilist');
      expect(signal.category, 'manga');
    });
  });

  group('signalToMinimalCoreDraft', () {
    test('produces minimal core without description or poster', () {
      final signal = anilistNodeToSignal(
        channelId: 'anilist_animation',
        media: sampleMedia,
      );
      final draft = signalToMinimalCoreDraft(
        signal: signal,
        workId: 'wk_000009999',
      );

      expect(draft['workId'], 'wk_000009999');
      expect(draft['title'], 'Chainsaw Man');
      expect(draft['category'], 'manga');
      expect(draft['externalIds'], {'anilist': '101922'});
      expect(draft.containsKey('description'), isFalse);
      expect(draft.containsKey('posterPath'), isFalse);
      expect(draft.containsKey('tags'), isFalse);
      expect(findForbiddenKeysInMap(draft), isEmpty);
    });

    test('rejects signal without title', () {
      final bad = Map<String, dynamic>.from(sampleMedia)..remove('title');
      expect(
        () => anilistNodeToSignal(channelId: 'anilist_animation', media: bad),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('DiscoveryRunKpi', () {
    test('dedupePassRate uses wkCreated over signalsNew', () {
      const kpi = DiscoveryRunKpi(signalsNew: 10, wkCreated: 7);
      expect(kpi.dedupePassRate, closeTo(0.7, 0.001));
    });
  });
}
