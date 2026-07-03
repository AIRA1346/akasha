import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_catalog_sync.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/utils/entity_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityTags', () {
    test('parseYaml handles list and comma string', () {
      expect(EntityTags.parseYaml(['영웅', '성장']), ['영웅', '성장']);
      expect(EntityTags.parseYaml('영웅, 성장'), ['영웅', '성장']);
      expect(EntityTags.parseYaml(null), isEmpty);
    });

    test('serializeYamlLine matches Work markdown convention', () {
      expect(EntityTags.serializeYamlLine([]), 'tags: []');
      expect(EntityTags.serializeYamlLine(['영웅', '구원']), 'tags: ["영웅", "구원"]');
    });
  });

  group('EntityJournalParser tags', () {
    test('round-trips semantic tags in frontmatter', () {
      const content = '''---
entity_type: person
entity_id: "pe_u_tagtest1"
record_kind: entityJournal
title: "나츠키 스바루"
added_at: "2026-06-20T12:00:00.000Z"
tags: ["영웅", "성장", "구원"]
---
메모
''';

      final parsed = EntityJournalParser.parse(
        content,
        '/vault/entities/person/natsuki.md',
      );
      expect(parsed, isNotNull);
      expect(parsed!.tags, ['영웅', '성장', '구원']);

      final reserialized = EntityJournalParser.serialize(
        entityType: parsed.entityType,
        entityId: parsed.entityId,
        title: parsed.title,
        body: parsed.body,
        addedAt: parsed.addedAt,
        tags: parsed.tags,
      );
      expect(reserialized, contains('tags: ["영웅", "성장", "구원"]'));

      final reparsed = EntityJournalParser.parse(
        reserialized,
        parsed.storagePath,
      );
      expect(reparsed?.tags, parsed.tags);
    });

    test('missing tags defaults to empty', () {
      const content = '''---
entity_type: person
entity_id: "pe_u_notags01"
record_kind: entityJournal
title: "No Tags"
added_at: "2026-06-20T12:00:00.000Z"
---
body
''';
      final parsed = EntityJournalParser.parse(content, '/x.md');
      expect(parsed?.tags, isEmpty);
    });
  });

  group('EntityCatalogSync tags mirror', () {
    test('journal tags overwrite draft on mirror', () {
      final draft = UserCatalogEntity.userLocal(
        entityId: 'pe_u_sync_tag',
        type: EntityAnchorType.person,
        title: 'Draft',
        tags: ['구원'],
      );
      final mirrored = EntityCatalogSync.mirrorFromJournal(
        draft: draft,
        entry: EntityJournalEntry(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_sync_tag',
          title: 'Journal',
          body: '',
          addedAt: DateTime.utc(2026, 6, 20),
          storagePath: '/vault/entities/person/Journal.md',
          aliases: const ['Journal Alias'],
          tags: const ['영웅', '성장'],
        ),
      );
      expect(mirrored.tags, ['영웅', '성장']);
    });
  });

  group('EntityCatalogSync aliases mirror', () {
    test('journal aliases overwrite draft on mirror', () {
      final draft = UserCatalogEntity.userLocal(
        entityId: 'pe_u_sync_alias',
        type: EntityAnchorType.person,
        title: 'Draft',
        aliases: const ['Draft Alias'],
      );
      final mirrored = EntityCatalogSync.mirrorFromJournal(
        draft: draft,
        entry: EntityJournalEntry(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_sync_alias',
          title: 'Journal',
          body: '',
          addedAt: DateTime.utc(2026, 6, 20),
          storagePath: '/vault/entities/person/Journal.md',
          aliases: const ['Journal Alias'],
        ),
      );
      expect(mirrored.aliases, ['Journal Alias']);
    });
  });

  group('UserCatalogEntity tags search', () {
    test('matchesQuery finds semantic tag', () {
      final entity = UserCatalogEntity.userLocal(
        entityId: 'pe_u_q',
        type: EntityAnchorType.person,
        title: '나츠키 스바루',
        tags: const ['영웅', '구원'],
      );
      expect(entity.matchesQuery('영웅'), isTrue);
      expect(entity.matchesQuery('re:zero'), isFalse);
    });
  });
}
