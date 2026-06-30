import 'package:akasha/core/archiving/archive_record_mapper.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/core/archiving/timeline_entry.dart';
import 'package:akasha/services/timeline_entry_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimelineEntryParser', () {
    test('parse legacy timeline record_kind', () {
      const content = '''
---
record_kind: timeline
record_id: "tl_20260501_abc"
title: "오늘의 생각"
occurred_at: "2026-05-01T10:00:00.000"
added_at: "2026-05-01T12:00:00.000"
entity_id: "wk_test123"
---
첫 번째 타임라인 본문입니다.
''';

      final entry = TimelineEntryParser.parse(content, r'C:\vault\timeline\a.md');

      expect(entry, isNotNull);
      expect(entry!.recordId, 'tl_20260501_abc');
      expect(entry.title, '오늘의 생각');
      expect(entry.entityId, 'wk_test123');
      expect(entry.body, contains('첫 번째 타임라인'));
      expect(entry.occurredAt, DateTime.parse('2026-05-01T10:00:00.000'));
    });

    test('parse canonical timelineEntry record_kind', () {
      const content = '''
---
record_kind: timelineEntry
record_id: "tl_20260502_def"
title: "canonical"
occurred_at: "2026-05-02T10:00:00.000"
added_at: "2026-05-02T12:00:00.000"
---
canonical body
''';

      final entry = TimelineEntryParser.parse(content, r'C:\vault\timeline\b.md');

      expect(entry, isNotNull);
      expect(entry!.recordId, 'tl_20260502_def');
      expect(entry.title, 'canonical');
      expect(entry.body, contains('canonical body'));
    });

    test('returns null for non-timeline record_kind', () {
      const content = '''
---
record_kind: journal
record_id: "x"
---
body
''';

      expect(TimelineEntryParser.parse(content, 'a.md'), isNull);
    });

    test('serialize uses canonical timelineEntry record_kind', () {
      final serialized = TimelineEntryParser.serialize(
        recordId: 'tl_1',
        title: '테스트 "인용"',
        body: '본문',
        occurredAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
        entityId: 'wk_abc',
      );

      expect(serialized, contains('record_kind: timelineEntry'));
      expect(serialized, isNot(contains('record_kind: timeline\n')));

      final parsed = TimelineEntryParser.parse(serialized, 't.md');
      expect(parsed?.recordId, 'tl_1');
      expect(parsed?.title, '테스트 "인용"');
      expect(parsed?.entityId, 'wk_abc');
    });
  });

  group('ArchiveRecordMapper.fromTimelineEntry', () {
    test('maps timeline with work entity anchor', () {
      final entry = TimelineEntry(
        recordId: 'tl_1',
        title: '관람',
        body: '봤다',
        occurredAt: DateTime.parse('2026-06-01T09:00:00.000Z'),
        addedAt: DateTime.parse('2026-06-01T10:00:00.000Z'),
        storagePath: r'C:\vault\timeline\tl_1.md',
        entityId: 'wk_frieren',
      );

      final record = ArchiveRecordMapper.fromTimelineEntry(entry);

      expect(record.kind, RecordKind.timelineEntry);
      expect(record.entity?.entityId, 'wk_frieren');
      expect(record.entity?.type, EntityAnchorType.work);
      expect(record.timeAnchor, entry.occurredAt);
    });
  });
}
