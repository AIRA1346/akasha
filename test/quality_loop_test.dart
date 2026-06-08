import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/quality_loop_utils.dart';
// ignore: avoid_relative_lib_imports
import '../tool/quality_score_utils.dart';

void main() {
  group('applyFixToWork', () {
    test('posterPath fix sets posterVerified', () {
      final result = applyFixToWork(
        {'workId': 'wk_1', 'title': '테스트', 'category': 'manga'},
        {'posterPath': 'https://image.tmdb.org/t/p/w500/x.jpg'},
      );
      expect(result.work['posterPath'], contains('tmdb'));
      expect(result.verifiedSignals, contains('posterVerified'));
      final signals = result.work['qualitySignals'] as Map;
      expect(signals['posterVerified'], isTrue);
      expect(signals['hasPoster'], isTrue);
    });

    test('externalIds fix merges and sets externalIdVerified', () {
      final result = applyFixToWork(
        {
          'workId': 'wk_1',
          'title': '테스트',
          'externalIds': {'mal': '13'},
        },
        {
          'externalIds': {'tmdb': '37854'},
        },
      );
      final ext = result.work['externalIds'] as Map;
      expect(ext['mal'], '13');
      expect(ext['tmdb'], '37854');
      expect(result.verifiedSignals, contains('externalIdVerified'));
    });

    test('franchise fix sets signal without writing top-level field', () {
      final result = applyFixToWork(
        {'workId': 'wk_1', 'title': '테스트'},
        {'franchise': 'franchise_fate'},
      );
      expect(result.work.containsKey('franchise'), isFalse);
      expect(result.verifiedSignals, contains('franchiseVerified'));
    });

    test('description fix sets descriptionVerified', () {
      final result = applyFixToWork(
        {'workId': 'wk_1', 'title': '테스트'},
        {'description': '자체 작성 설명 문장.'},
      );
      expect(result.verifiedSignals, contains('descriptionVerified'));
      final signals = result.work['qualitySignals'] as Map;
      expect(signals['descriptionVerified'], isTrue);
      expect(signals['hasDescription'], isTrue);
    });

    test('forbidden field is skipped, not written', () {
      final result = applyFixToWork(
        {'workId': 'wk_1', 'title': '테스트'},
        {'synopsis': '외부 시놉 복사'},
      );
      expect(result.work.containsKey('synopsis'), isFalse);
      expect(result.skippedFields, contains('synopsis'));
    });

    test('does not mutate input work', () {
      final input = {'workId': 'wk_1', 'title': '원본'};
      applyFixToWork(input, {'title': '수정'});
      expect(input['title'], '원본');
    });
  });

  group('loop raises qualityScore', () {
    test('poster + externalId verification increases score and tier', () {
      final before = {
        'workId': 'wk_1',
        'title': '테스트',
        'category': 'manga',
        'domain': 'subculture',
        'releaseYear': 2020,
        'creator': '작가',
        'externalIds': {'mal': '1'},
      };
      final beforeSignals =
          resolveQualitySignals(before, franchiseMember: false);
      final beforeScore = computeQualityScore(before, beforeSignals);

      final result = applyFixToWork(before, {
        'posterPath': 'https://image.tmdb.org/t/p/w500/x.jpg',
        'externalIds': {'tmdb': '37854'},
        'description': '자체 작성 2~3문장 설명입니다.',
      });
      final afterSignals =
          resolveQualitySignals(result.work, franchiseMember: false);
      final afterScore = computeQualityScore(result.work, afterSignals);

      expect(afterScore, greaterThan(beforeScore));
      expect(
        qualityTierFromScore(afterScore),
        greaterThanOrEqualTo(qualityTierFromScore(beforeScore)),
      );
    });
  });
}
