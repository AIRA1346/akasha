import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/quality_score_utils.dart';

void main() {
  group('resolveQualitySignals', () {
    test('derives hasPoster and hasDescription from work fields', () {
      final signals = resolveQualitySignals(
        {
          'title': '테스트',
          'posterPath': 'https://example.com/p.jpg',
          'description': 'a' * qualityDescriptionMinChars,
        },
        franchiseMember: false,
      );
      expect(signals.hasPoster, isTrue);
      expect(signals.hasDescription, isTrue);
      expect(signals.posterVerified, isFalse);
    });

    test('stored posterVerified overrides extensions', () {
      final signals = resolveQualitySignals(
        {
          'title': '테스트',
          'qualitySignals': {'posterVerified': true},
          'extensions': {'posterVerified': false},
        },
        franchiseMember: false,
      );
      expect(signals.posterVerified, isTrue);
    });

    test('franchiseMember sets franchiseVerified when not stored', () {
      final signals = resolveQualitySignals(
        {'title': '테스트'},
        franchiseMember: true,
      );
      expect(signals.franchiseVerified, isTrue);
    });
  });

  group('computeQualityScore', () {
    test('minimal stub scores tier 0 range', () {
      final work = {'title': 'Stub'};
      final signals = resolveQualitySignals(work, franchiseMember: false);
      final score = computeQualityScore(work, signals);
      expect(score, qualityWeightTitle);
      expect(qualityTierFromScore(score), 1);
    });

    test('full verification reaches tier 5', () {
      final work = {
        'title': '완성',
        'creator': '작가',
        'releaseYear': 2020,
        'posterPath': 'https://example.com/p.jpg',
        'description': 'a' * qualityDescriptionMinChars,
        'externalIds': {'anilist': '1'},
        'qualitySignals': {
          'posterVerified': true,
          'externalIdVerified': true,
          'descriptionVerified': true,
        },
      };
      final signals = resolveQualitySignals(work, franchiseMember: true);
      final score = computeQualityScore(work, signals);
      expect(score, greaterThanOrEqualTo(95));
      expect(qualityTierFromScore(score), 5);
    });
  });
}
