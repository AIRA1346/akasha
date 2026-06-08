import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_runner.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/user_value_assessment.dart';

void main() {
  group('assessUserValue', () {
    test('rich metadata + search gap scores high', () {
      final result = assessUserValue(
        draft: {
          'title': 'Trigun',
          'category': 'animation',
          'releaseYear': 1998,
          'creator': 'MADHOUSE',
          'titles': {'en': 'Trigun', 'romaji': 'TRIGUN'},
          'aliases': ['トライガン', 'Триган'],
          'externalIds': {'anilist': '6'},
        },
        item: const ShadowWriteItem(
          outcome: ShadowWriteOutcome.wouldCreate,
          externalId: '6',
          title: 'Trigun',
          qualityScore: 60,
        ),
        titleDistinctInRegistry: true,
        searchTokenCount: 9,
      );

      expect(result.tier, UserValueTier.high);
      expect(result.highSignals, isNotEmpty);
      expect(result.lowSignals, isEmpty);
    });

    test('sparse metadata scores low', () {
      final result = assessUserValue(
        draft: {
          'title': 'X',
          'category': 'animation',
          'externalIds': {'anilist': '999'},
        },
        item: const ShadowWriteItem(
          outcome: ShadowWriteOutcome.wouldCreate,
          externalId: '999',
          title: 'X',
          qualityScore: 30,
        ),
        titleDistinctInRegistry: true,
        searchTokenCount: 1,
      );

      expect(result.tier, UserValueTier.low);
      expect(result.lowSignals, isNotEmpty);
    });
  });
}
