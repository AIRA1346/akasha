import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/journal_entry.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/core/archiving/timeline_entry.dart';
import 'package:akasha/services/same_day_record_service.dart';

void main() {
  group('SameDayRecordService', () {
    test('sameLocalDay compares calendar date in local timezone', () {
      final a = DateTime(2026, 6, 19, 23);
      final b = DateTime(2026, 6, 20, 1);
      final c = DateTime(2026, 6, 18, 12);
      expect(SameDayRecordService.sameLocalDay(a, a), isTrue);
      expect(SameDayRecordService.sameLocalDay(a, b), isFalse);
      expect(SameDayRecordService.sameLocalDay(a, c), isFalse);
    });

    test('collectFromEntries filters timeline and journal by anchor day', () {
      final anchor = DateTime(2026, 6, 19, 12);
      final refs = SameDayRecordService.collectFromEntries(
        anchor: anchor,
        timeline: [
          TimelineEntry(
            recordId: 'tl1',
            title: '콘서트',
            body: '',
            occurredAt: DateTime(2026, 6, 19, 20),
            addedAt: DateTime(2026, 6, 19, 21),
            storagePath: '/vault/timeline/a.md',
          ),
          TimelineEntry(
            recordId: 'tl2',
            title: '다른 날',
            body: '',
            occurredAt: DateTime(2026, 6, 18, 20),
            addedAt: DateTime(2026, 6, 18, 21),
            storagePath: '/vault/timeline/b.md',
          ),
        ],
        journals: [
          JournalEntry(
            recordId: 'j1',
            title: '메모',
            body: '',
            addedAt: DateTime(2026, 6, 19, 9),
            storagePath: '/vault/journal/c.md',
          ),
        ],
        excludePath: '/vault/timeline/a.md',
      );

      expect(refs.length, 1);
      expect(refs.single.kind, RecordKind.freeformJournal);
      expect(refs.single.title, '메모');
    });
  });
}
