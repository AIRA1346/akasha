import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/archive_record_contract.dart';
import 'package:akasha/services/timeline_entry_parser.dart';

/// Spec §2.3 — Semantic Local Time Constraint.
///
/// `occurred_at` records when the *human experienced* something and must keep
/// its wall-clock digits on every device, unlike UTC system timestamps.
void main() {
  group('ArchiveRecordContract semantic local timestamp', () {
    test('parses timezone-less string as wall-clock digits', () {
      final parsed = ArchiveRecordContract.parseSemanticLocalTimestamp(
        '2026-07-05T22:30:00.000',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(parsed.year, 2026);
      expect(parsed.month, 7);
      expect(parsed.day, 5);
      expect(parsed.hour, 22);
      expect(parsed.minute, 30);
    });

    test('still accepts legacy Z values on read', () {
      final parsed = ArchiveRecordContract.parseSemanticLocalTimestamp(
        '2026-07-05T13:30:00.000Z',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
    });

    test('returns null for null and invalid input', () {
      expect(ArchiveRecordContract.parseSemanticLocalTimestamp(null), isNull);
      expect(
        ArchiveRecordContract.parseSemanticLocalTimestamp('not a date'),
        isNull,
      );
    });

    test('formats local DateTime without timezone designator', () {
      final formatted = ArchiveRecordContract.formatSemanticLocalTimestamp(
        DateTime(2026, 7, 5, 22, 30),
      );
      expect(formatted, '2026-07-05T22:30:00.000');
      expect(formatted.endsWith('Z'), isFalse);
      expect(formatted.contains('+'), isFalse);
    });

    test('normalizes UTC DateTime to local wall-clock preserving instant', () {
      final utc = DateTime.utc(2026, 7, 5, 13, 30);
      final formatted =
          ArchiveRecordContract.formatSemanticLocalTimestamp(utc);
      expect(formatted.endsWith('Z'), isFalse);

      final roundTrip = DateTime.parse(formatted);
      expect(roundTrip.isUtc, isFalse);
      // Same physical instant, expressed as experienced local time.
      expect(roundTrip.toUtc(), utc);
    });

    test('wall-clock digits survive serialize/parse round trip', () {
      final original = DateTime(2026, 7, 5, 22, 30);
      final formatted =
          ArchiveRecordContract.formatSemanticLocalTimestamp(original);
      final parsed =
          ArchiveRecordContract.parseSemanticLocalTimestamp(formatted);
      expect(parsed, original);
    });
  });

  group('TimelineEntryParser occurred_at semantic local contract', () {
    test('serializes occurred_at without timezone designator', () {
      final serialized = TimelineEntryParser.serialize(
        recordId: 'tl_semantic',
        title: 'wall clock',
        body: 'body',
        occurredAt: DateTime(2026, 7, 5, 22, 30),
      );

      expect(serialized, contains('occurred_at: "2026-07-05T22:30:00.000"'));
      // System timestamps stay UTC Z in the same file.
      expect(serialized, contains(RegExp(r'added_at: "[^"]+Z"')));
      expect(serialized, contains(RegExp(r'created_at: "[^"]+Z"')));
    });

    test('parse keeps wall-clock digits exactly as written', () {
      const content = '''
---
record_kind: timelineEntry
record_id: "tl_wall"
title: "경험 시각"
occurred_at: "2026-07-05T22:30:00.000"
added_at: "2026-07-05T13:35:00.000Z"
---
본문
''';

      final entry = TimelineEntryParser.parse(content, 't.md');
      expect(entry, isNotNull);
      expect(entry!.occurredAt.isUtc, isFalse);
      expect(entry.occurredAt.hour, 22);
      expect(entry.occurredAt.minute, 30);
    });

    test('legacy Z occurred_at is normalized to wall-clock on rewrite', () {
      const legacy = '''
---
record_kind: timelineEntry
record_id: "tl_legacy"
title: "legacy"
occurred_at: "2026-07-05T13:30:00.000Z"
added_at: "2026-07-05T13:35:00.000Z"
---
본문
''';

      final entry = TimelineEntryParser.parse(legacy, 't.md');
      expect(entry, isNotNull);

      final rewritten = TimelineEntryParser.serialize(
        recordId: entry!.recordId,
        title: entry.title,
        body: entry.body,
        occurredAt: entry.occurredAt,
        addedAt: entry.addedAt,
      );

      final match =
          RegExp(r'occurred_at: "([^"]+)"').firstMatch(rewritten)!.group(1)!;
      expect(match.endsWith('Z'), isFalse, reason: 'normalized to wall-clock');
      // Physical instant preserved through normalization.
      expect(
        DateTime.parse(match).toUtc(),
        DateTime.utc(2026, 7, 5, 13, 30),
      );
    });
  });
}
