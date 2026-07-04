import 'dart:io';

import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/archive_operation_validator.dart';
import 'package:akasha/core/archiving/archive_record_contract.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/journal_entry_parser.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/services/timeline_entry_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveRecordContract v3', () {
    test(
      'work fixture parses and preserves additive contract metadata',
      () async {
        final content = await File(
          'test/fixtures/vault_v3_contract_work.md',
        ).readAsString();

        final item = MarkdownParser.deserialize(content, 'fallback.md');

        expect(item.workId, 'wk_u_contract');
        expect(item.category, MediaCategory.movie);
        expect(item.addedAt, DateTime.parse('2026-07-04T00:00:00.000Z'));
        expect(item.recordMetadata.source, 'agent');
        expect(item.recordMetadata.aliases, ['CW', 'Contract Alias']);
        expect(item.recordMetadata.originalTitle, 'Original Contract');
        expect(item.recordMetadata.externalIds['imdb'], 'tt1234567');
        expect(item.recordMetadata.evidence, ['User imported this record.']);
        expect(item.recordMetadata.links.single.targetId, 'co_u_source01');

        final serialized = MarkdownParser.serialize(item);

        expect(serialized, contains('created_at: "2026-07-04T00:00:00.000Z"'));
        expect(serialized, contains('updated_at: "2026-07-04T01:00:00.000Z"'));
        expect(serialized, contains('source: "agent"'));
        expect(serialized, contains('aliases: ["CW", "Contract Alias"]'));
        expect(serialized, contains('original_title: "Original Contract"'));
        expect(serialized, contains('external_ids:'));
        expect(serialized, contains('imdb: "tt1234567"'));
        expect(serialized, contains('evidence:'));
        expect(serialized, contains('target_id: "co_u_source01"'));
      },
    );

    test(
      'legacy work fixture still parses through added_at fallback',
      () async {
        final content = await File(
          'test/fixtures/vault_v1_legacy.md',
        ).readAsString();

        final item = MarkdownParser.deserialize(content, 'fallback.md');

        expect(item.workId, 'sub_manga_legacytest_2020');
        expect(item.recordMetadata.source, ArchiveRecordContract.defaultSource);
        expect(item.recordMetadata.aliases, isEmpty);
        expect(item.addedAt, DateTime.parse('2020-01-01T00:00:00.000Z'));
      },
    );

    test('entity journal emits and parses contract metadata', () {
      final updatedAt = DateTime.parse('2026-07-04T01:00:00.000Z');
      final markdown = EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_contract1',
        title: 'Contract Person',
        body: 'body',
        addedAt: DateTime.parse('2026-07-04T00:00:00.000Z'),
        aliases: const ['CP'],
        metadata: ArchiveRecordMetadata(
          source: 'agent',
          originalTitle: 'Original Person',
          externalIds: const {'wikidata': 'Q123'},
          evidence: const ['Mentioned in source record.'],
          links: const [
            ArchiveStructuredLink(
              relation: 'appears_in',
              targetId: 'wk_u_contract',
              label: 'Contract Work',
            ),
          ],
          updatedAt: updatedAt,
          sourceOperationId: 'op_contract1',
        ),
      );

      expect(markdown, contains('source_operation_id: "op_contract1"'));
      expect(markdown, contains('aliases: ["CP"]'));
      expect(markdown, contains('wikidata: "Q123"'));
      expect(markdown, contains('relation: "appears_in"'));

      final parsed = EntityJournalParser.parse(markdown, 'entity.md');

      expect(parsed?.addedAt, DateTime.parse('2026-07-04T00:00:00.000Z'));
      expect(parsed?.sourceOperationId, 'op_contract1');
      expect(parsed?.recordMetadata.source, 'agent');
      expect(parsed?.recordMetadata.externalIds['wikidata'], 'Q123');
      expect(parsed?.recordMetadata.links.single.targetId, 'wk_u_contract');
    });

    test('journal and timeline serializers write shared contract fields', () {
      final metadata = ArchiveRecordMetadata(
        source: 'script',
        updatedAt: DateTime.parse('2026-07-04T01:00:00.000Z'),
      );

      final journal = JournalEntryParser.serialize(
        recordId: 'jr_20260704_contract',
        title: 'Journal Contract',
        body: 'journal body',
        addedAt: DateTime.parse('2026-07-04T00:00:00.000Z'),
        metadata: metadata,
      );
      final timeline = TimelineEntryParser.serialize(
        recordId: 'tl_20260704_contract',
        title: 'Timeline Contract',
        body: 'timeline body',
        occurredAt: DateTime.parse('2026-07-04T02:00:00.000Z'),
        addedAt: DateTime.parse('2026-07-04T00:00:00.000Z'),
        metadata: metadata,
      );

      expect(journal, contains('record_kind: freeformJournal'));
      expect(journal, contains('created_at: "2026-07-04T00:00:00.000Z"'));
      expect(journal, contains('source: "script"'));
      expect(timeline, contains('record_kind: timelineEntry'));
      expect(timeline, contains('created_at: "2026-07-04T00:00:00.000Z"'));
      expect(timeline, contains('source: "script"'));
      expect(
        JournalEntryParser.parse(journal, 'journal.md')?.recordMetadata.source,
        'script',
      );
      expect(
        TimelineEntryParser.parse(
          timeline,
          'timeline.md',
        )?.recordMetadata.source,
        'script',
      );
    });

    test('operation payload cannot mutate app-owned provenance fields', () {
      final operation = ArchiveOperation(
        operationId: 'op_contract_guard',
        type: ArchiveOperationType.updateFrontmatter,
        recordKind: RecordKind.workJournal,
        source: ArchiveOperationSource.agent,
        createdAt: DateTime.utc(2026, 7, 4),
        targetRecordId: 'rec_wk_u_contract',
        payload: const {
          'created_at': '2026-07-04T00:00:00.000Z',
          'updated_at': '2026-07-04T01:00:00.000Z',
          'source': 'agent',
        },
      );

      final result = ArchiveOperationValidator.validate(operation);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        everyElement('immutable_frontmatter'),
      );
    });
  });
}
