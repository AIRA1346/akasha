import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/recall_picker.dart';

void main() {
  group('RecallPicker', () {
    AkashaItem item(String title, List<String> quotes) => ContentItem(
          workId: 'sub_manga_test_2020',
          title: title,
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
          memorableQuotes: quotes,
        );

    test('returns null when no quotes exist', () {
      expect(
        RecallPicker.pickDailyRecall([
          item('A', []),
          item('B', ['  ']),
        ]),
        isNull,
      );
    });

    test('picks deterministically for the same date', () {
      final items = [
        item('Alpha', ['quote A']),
        item('Beta', ['quote B']),
        item('Gamma', ['quote C']),
      ];
      final day = DateTime(2026, 6, 6);

      final first = RecallPicker.pickDailyRecall(items, date: day);
      final second = RecallPicker.pickDailyRecall(items, date: day);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second!.quote, first!.quote);
      expect(second.item.title, first.item.title);
    });

    test('can pick different quotes on different days', () {
      final items = [
        item('One', ['q1']),
        item('Two', ['q2']),
        item('Three', ['q3']),
      ];

      final a = RecallPicker.pickDailyRecall(
        items,
        date: DateTime(2026, 1, 1),
      );
      final b = RecallPicker.pickDailyRecall(
        items,
        date: DateTime(2026, 12, 31),
      );

      expect(a, isNotNull);
      expect(b, isNotNull);
      // 365-day span with 3 candidates — very likely different
      expect(a!.quote == b!.quote && a.item.title == b.item.title, isFalse);
    });
  });
}
