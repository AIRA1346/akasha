import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/quality_score_utils.dart';

void main() {
  group('resolveQualitySignals', () {
    test('externalIdVerified requires stored flag and externalIds', () {
      final signals = resolveQualitySignals(
        {
          'title': '테스트',
          'externalIds': {'mal': '13'},
          'qualitySignals': {'externalIdVerified': true},
        },
        franchiseMember: false,
      );
      expect(signals.externalIdVerified, isTrue);
      expect(signals.franchiseVerified, isFalse);
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
    test('minimal stub scores tier 1 range', () {
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
        'externalIds': {'anilist': '1'},
        'qualitySignals': {
          'externalIdVerified': true,
        },
      };
      final signals = resolveQualitySignals(work, franchiseMember: true);
      final score = computeQualityScore(work, signals);
      expect(score, greaterThanOrEqualTo(95));
      expect(qualityTierFromScore(score), 5);
    });
  });
}
