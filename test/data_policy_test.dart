import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/data_policy_utils.dart';

void main() {
  group('lintWorkEntry', () {
    test('allows minimal core work entry', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000001',
        work: {
          'workId': 'wk_000000001',
          'title': '원피스',
          'category': 'manga',
          'domain': 'subculture',
          'releaseYear': 1997,
          'externalIds': {'mal': '13'},
        },
        relativePath: 'shards/manga/00.json',
      );
      expect(issues, isEmpty);
    });

    test('rejects forbidden synopsis field', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000002',
        work: {
          'workId': 'wk_000000002',
          'title': '테스트',
          'category': 'manga',
          'domain': 'subculture',
          'synopsis': '외부 시놉 복사',
        },
        relativePath: 'shards/manga/01.json',
      );
      expect(issues.any((i) => i.rule == 'forbidden_field'), isTrue);
    });

    test('rejects API blob signature map', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000003',
        work: {
          'workId': 'wk_000000003',
          'title': '테스트',
          'category': 'animation',
          'domain': 'subculture',
          'extensions': {
            'averageScore': 85,
            'favourites': 1000,
            'siteUrl': 'https://anilist.co/1',
          },
        },
        relativePath: 'shards/animation/02.json',
      );
      expect(issues.any((i) => i.rule == 'api_blob'), isTrue);
    });

    test('rejects tier1 description', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000004',
        work: {
          'workId': 'wk_000000004',
          'title': '테스트',
          'category': 'manga',
          'domain': 'subculture',
          'description': 'AKASHA 자체 요약',
        },
        relativePath: 'shards/manga/03.json',
      );
      expect(issues.any((i) => i.rule == 'tier1_description'), isTrue);
    });

    test('rejects Tier 1 posterPath regardless of provider', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000005',
        work: {
          'workId': 'wk_000000005',
          'title': '테스트',
          'category': 'game',
          'domain': 'subculture',
          'posterPath':
              'https://cdn.akamai.steamstatic.com/steam/apps/1/header.jpg',
        },
        relativePath: 'shards/game/04.json',
      );
      expect(issues.any((i) => i.rule == 'tier1_poster'), isTrue);
    });

    test('rejects empty Tier 1 presentation keys by presence', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000006',
        work: {
          'workId': 'wk_000000006',
          'title': '테스트',
          'category': 'game',
          'domain': 'subculture',
          'posterPath': null,
          'description': '',
        },
        relativePath: 'shards/game/05.json',
      );
      expect(issues.any((i) => i.rule == 'tier1_poster'), isTrue);
      expect(issues.any((i) => i.rule == 'tier1_description'), isTrue);
    });

    test('rejects searchTokens in shard', () {
      final issues = lintWorkEntry(
        workId: 'wk_000000006',
        work: {
          'workId': 'wk_000000006',
          'title': '테스트',
          'category': 'manga',
          'domain': 'subculture',
          'searchTokens': ['a'],
        },
        relativePath: 'shards/manga/05.json',
      );
      expect(issues.any((i) => i.rule == 'build_artifact'), isTrue);
    });
  });
}
