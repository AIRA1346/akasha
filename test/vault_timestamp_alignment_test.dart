import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/archive_record_contract.dart';

void main() {
  group('UA-115: Vault Timestamp Contract Alignment - Parser Tests', () {
    test('parseSystemTimestamp parses timezone-less string as UTC wall-clock representation', () {
      // NOTE: This behavior represents best-effort compatibility for legacy timezone-less timestamps.
      // It clones the wall-clock digits directly into UTC, and does NOT recover the original local instant
      // offset that may have been intended when the file was originally authored.
      final result1 = ArchiveRecordContract.parseSystemTimestamp('2026-07-05T12:00:00.000');
      expect(result1, isNotNull);
      expect(result1!.isUtc, isTrue);
      expect(result1, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));

      final result2 = ArchiveRecordContract.parseSystemTimestamp('2026-07-05 12:00:00');
      expect(result2, isNotNull);
      expect(result2!.isUtc, isTrue);
      expect(result2, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });

    test('parseSystemTimestamp preserves explicit UTC string as UTC', () {
      final result = ArchiveRecordContract.parseSystemTimestamp('2026-07-05T12:00:00.000Z');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });

    test('parseSystemTimestamp parses offset string and converts to absolute UTC', () {
      final result = ArchiveRecordContract.parseSystemTimestamp('2026-07-05T12:00:00.000+09:00');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 3, 0, 0)));
    });

    test('parseSystemTimestamp parses raw DateTime and converts to UTC', () {
      final local = DateTime(2026, 7, 5, 12, 0, 0);
      final result = ArchiveRecordContract.parseSystemTimestamp(local);
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(local.toUtc()));
    });

    test('parseSystemTimestamp returns null for invalid or null inputs', () {
      expect(ArchiveRecordContract.parseSystemTimestamp(null), isNull);
      expect(ArchiveRecordContract.parseSystemTimestamp(''), isNull);
      expect(ArchiveRecordContract.parseSystemTimestamp('not-a-date'), isNull);
    });
  });

  group('UA-115: Vault Timestamp Contract Alignment - Writer Tests', () {
    test('formatSystemTimestamp converts UTC DateTime to ISO string ending with Z', () {
      final utc = DateTime.utc(2026, 7, 5, 12, 0, 0);
      final formatted = ArchiveRecordContract.formatSystemTimestamp(utc);
      expect(formatted, equals('2026-07-05T12:00:00.000Z'));
      expect(formatted.endsWith('Z'), isTrue);
    });

    test('formatSystemTimestamp converts local DateTime to UTC ISO string ending with Z', () {
      final local = DateTime(2026, 7, 5, 12, 0, 0);
      final formatted = ArchiveRecordContract.formatSystemTimestamp(local);
      expect(formatted.endsWith('Z'), isTrue);
      final parsed = DateTime.parse(formatted);
      expect(parsed.isUtc, isTrue);
      expect(parsed, equals(local.toUtc()));
    });
  });

  group('UA-115: Vault Timestamp Contract Alignment - YAML Contract Tests', () {
    test('createdAtFromYaml parses created_at, createdAt, added_at, addedAt with parseSystemTimestamp', () {
      final yaml1 = {'created_at': '2026-07-05T12:00:00.000'};
      expect(ArchiveRecordContract.createdAtFromYaml(yaml1), equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));

      final yaml2 = {'createdAt': '2026-07-05T12:00:00.000Z'};
      expect(ArchiveRecordContract.createdAtFromYaml(yaml2), equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));

      final yaml3 = {'added_at': '2026-07-05T12:00:00.000+09:00'};
      expect(ArchiveRecordContract.createdAtFromYaml(yaml3), equals(DateTime.utc(2026, 7, 5, 3, 0, 0)));

      final yaml4 = {'addedAt': '2026-07-05 12:00:00'};
      expect(ArchiveRecordContract.createdAtFromYaml(yaml4), equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });

    test('createdAtFromYaml priority: created_at has priority over added_at', () {
      final yaml = {
        'created_at': '2026-07-05T12:00:00.000',
        'added_at': '2026-07-05T09:00:00.000'
      };
      expect(ArchiveRecordContract.createdAtFromYaml(yaml), equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });

    test('metadataFromYaml parses updatedAt with parseSystemTimestamp', () {
      final yaml1 = {'updated_at': '2026-07-05T12:00:00.000'};
      final meta1 = ArchiveRecordContract.metadataFromYaml(yaml1);
      expect(meta1.updatedAt, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));

      final yaml2 = {'updatedAt': '2026-07-05T12:00:00.000Z'};
      final meta2 = ArchiveRecordContract.metadataFromYaml(yaml2);
      expect(meta2.updatedAt, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });
  });

  group('UA-115: Vault Timestamp Contract Alignment - Non-goal Checks', () {
    test('occurredAt/timeAnchor read and write paths are not modified to use parseSystemTimestamp', () {
      // occurred_at / occurredAt and timeAnchor should not be affected by UA-115 system timestamp parser integration.
      // 1. Raw parser for occurredAt in timeline_entry_parser uses _parseDateTime (which uses DateTime.tryParse raw).
      // 2. formatDateTime (which does NOT convert to UTC) is still used for occurred_at in timeline_entry_parser serialize.
      // This test ensures formatDateTime is still available and does not automatically shift local DateTime to UTC.
      final local = DateTime(2026, 7, 5, 12, 0, 0);
      final formatted = ArchiveRecordContract.formatDateTime(local);
      expect(formatted, isNot(endsWith('Z')));
      expect(formatted, equals(local.toIso8601String()));
    });
  });
}
