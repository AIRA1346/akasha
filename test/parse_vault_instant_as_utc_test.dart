import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:akasha/services/record_summary_index_service.dart';

void main() {
  group('parseVaultInstantAsUtc Tests', () {
    test('1. Timezone-less date-time becomes UTC wall-clock representation', () {
      final result = RecordSummaryIndexService.parseVaultInstantAsUtc('2026-07-05 12:00:00');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });

    test('2. Date-only becomes UTC midnight representation', () {
      final result = RecordSummaryIndexService.parseVaultInstantAsUtc('2026-07-05');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 0, 0, 0)));
    });

    test('3. Explicit UTC string is preserved untouched as UTC', () {
      final result = RecordSummaryIndexService.parseVaultInstantAsUtc('2026-07-05T12:00:00Z');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
    });

    test('4. Positive offset string parses and converts to absolute UTC', () {
      final result = RecordSummaryIndexService.parseVaultInstantAsUtc('2026-07-05T12:00:00+09:00');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 3, 0, 0)));
    });

    test('5. Negative offset string parses and converts to absolute UTC', () {
      final result = RecordSummaryIndexService.parseVaultInstantAsUtc('2026-07-05T12:00:00-05:00');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 7, 5, 17, 0, 0)));
    });

    test('6. Raw DateTime object preserves its instant and converts to UTC', () {
      final localDateTime = DateTime(2026, 7, 5, 12, 0, 0);
      final result = RecordSummaryIndexService.parseVaultInstantAsUtc(localDateTime);
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result, equals(localDateTime.toUtc()));
    });

    test('7. Markdown frontmatter source with created_at is parsed via UTC instant parser', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_created_at_test');
      try {
        final file = File(p.join(tempDir.path, 'test_rec.md'));
        await file.writeAsString('''---
schema_version: 3
record_id: "rec_created_at_test"
record_kind: workJournal
created_at: 2026-07-05 12:00:00
title: "Created At Test"
---
''', flush: true);

        final indexService = RecordSummaryIndexService();
        final summary = await indexService.upsertMarkdownFile(
          vaultPath: tempDir.path,
          absolutePath: file.path,
        );

        expect(summary, isNotNull);
        expect(summary!.addedAt, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('8. Markdown frontmatter source with camelCase createdAt is parsed via UTC instant parser', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_created_at_camel_test');
      try {
        final file = File(p.join(tempDir.path, 'test_rec_camel.md'));
        await file.writeAsString('''---
schema_version: 3
record_id: "rec_created_at_camel_test"
record_kind: workJournal
createdAt: 2026-07-05 12:00:00
title: "Created At Camel Test"
---
''', flush: true);

        final indexService = RecordSummaryIndexService();
        final summary = await indexService.upsertMarkdownFile(
          vaultPath: tempDir.path,
          absolutePath: file.path,
        );

        expect(summary, isNotNull);
        expect(summary!.addedAt, equals(DateTime.utc(2026, 7, 5, 12, 0, 0)));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('9. When both created_at and added_at exist, created_at has priority', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_created_at_priority_test');
      try {
        final file = File(p.join(tempDir.path, 'test_rec_priority.md'));
        await file.writeAsString('''---
schema_version: 3
record_id: "rec_created_at_priority_test"
record_kind: workJournal
created_at: 2026-07-05 12:00:00
added_at: 2026-07-05 09:00:00
title: "Priority Test"
---
''', flush: true);

        final indexService = RecordSummaryIndexService();
        final summary = await indexService.upsertMarkdownFile(
          vaultPath: tempDir.path,
          absolutePath: file.path,
        );

        expect(summary, isNotNull);
        expect(summary!.addedAt, equals(DateTime.utc(2026, 7, 5, 12, 0, 0))); // Must be created_at (12:00) not added_at (09:00)
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
