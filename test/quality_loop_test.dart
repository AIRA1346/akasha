import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/quality_loop_utils.dart';
// ignore: avoid_relative_lib_imports
import '../tool/quality_score_utils.dart';

void main() {
  group('applyFixToWork', () {
    test('posterPath and description fixes are skipped for Tier 1', () {
      final result = applyFixToWork(
        {'workId': 'wk_1', 'title': '테스트', 'category': 'manga'},
        {
          'posterPath': 'https://image.tmdb.org/t/p/w500/x.jpg',
          'description': '글로벌 사전에 저장하면 안 되는 설명',
        },
      );
      expect(result.work.containsKey('posterPath'), isFalse);
      expect(result.work.containsKey('description'), isFalse);
      expect(result.skippedFields, containsAll(['posterPath', 'description']));
      expect(result.verifiedSignals, isEmpty);
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
    test('externalId + franchise verification increases score and tier', () {
      final before = {
        'workId': 'wk_1',
        'title': '테스트',
        'category': 'manga',
        'domain': 'subculture',
        'releaseYear': 2020,
        'creator': '작가',
      };
      final beforeSignals = resolveQualitySignals(
        before,
        franchiseMember: false,
      );
      final beforeScore = computeQualityScore(before, beforeSignals);

      final result = applyFixToWork(before, {
        'externalIds': {'tmdb': '37854'},
        'franchise': 'franchise_test',
      });
      final afterSignals = resolveQualitySignals(
        result.work,
        franchiseMember: false,
      );
      final afterScore = computeQualityScore(result.work, afterSignals);

      expect(afterScore, greaterThan(beforeScore));
      expect(
        qualityTierFromScore(afterScore),
        greaterThanOrEqualTo(qualityTierFromScore(beforeScore)),
      );
    });
  });
}
