import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/utils/journal_reflection_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JournalReflectionPreview', () {
    test('formatMemo truncates long review', () {
      final long = '가' * 200;
      final out = JournalReflectionPreview.formatMemo(long, maxLength: 50);
      expect(out.length, lessThanOrEqualTo(51));
      expect(out.endsWith('…'), isTrue);
    });

    test('hasAnyReflection detects memo rating status tags', () {
      final empty = createItem(
        workId: 'wk_u_1',
        title: 't',
        category: MediaCategory.animation,
      );
      expect(JournalReflectionPreview.hasAnyReflection(empty), isFalse);

      final full = createItem(
        workId: 'wk_u_1',
        title: 't',
        category: MediaCategory.animation,
        rating: 4,
        myStatus: '전부 봄',
        tags: ['재미'],
        review: '좋았다',
      );
      expect(JournalReflectionPreview.hasAnyReflection(full), isTrue);
    });

    test('hasMeaningfulStatus ignores watchlist default', () {
      final backlog = createItem(
        workId: 'wk_u_1',
        title: 't',
        category: MediaCategory.animation,
        myStatus: '볼 예정',
      );
      expect(JournalReflectionPreview.hasMeaningfulStatus(backlog), isFalse);

      final done = createItem(
        workId: 'wk_u_1',
        title: 't',
        category: MediaCategory.animation,
        myStatus: '전부 봄',
      );
      expect(JournalReflectionPreview.hasMeaningfulStatus(done), isTrue);
    });
  });
}
