import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/exploration_progress.dart';

void main() {
  group('explorationProgress', () {
    test('returns baseline for minimally explored item', () {
      final item = ContentItem(
        workId: 'work-1',
        title: 'Test',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
      );

      expect(explorationProgress(item), greaterThanOrEqualTo(0.08));
      expect(explorationProgressPercent(item), greaterThanOrEqualTo(8));
    });

    test('increases with review and tags', () {
      final sparse = ContentItem(
        workId: 'work-1',
        title: 'Sparse',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
      );
      final rich = ContentItem(
        workId: 'work-2',
        title: 'Rich',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
        review: 'A' * 400,
        tags: const ['fantasy', 'isekai'],
        rating: 8.5,
        bodyRaw: 'B' * 200,
      );

      expect(explorationProgress(rich), greaterThan(explorationProgress(sparse)));
    });
  });
}
