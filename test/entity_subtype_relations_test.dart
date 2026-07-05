import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:akasha/core/archiving/archive_record_contract.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/record_summary_index_service.dart';

void main() {
  group('Entity Subtype & Relations Unit Tests (UA-107)', () {
    test('1. parse extracts entity_subtype correctly from YAML frontmatter', () {
      const content = '''---
schema_version: 3
record_id: "rec_pe_u_3puh848u"
entity_type: person
entity_id: "pe_u_3puh848u"
record_kind: entityJournal
title: "렘"
entity_subtype: "character"
aliases: ["Rem"]
---
로즈월 저택의 메이드.
''';

      final entry = EntityJournalParser.parse(content, 'entities/person/pe_u_3puh848u.md');
      expect(entry, isNotNull);
      expect(entry!.entityType, equals(EntityAnchorType.person));
      expect(entry.entityId, equals('pe_u_3puh848u'));
      expect(entry.title, equals('렘'));
      expect(entry.entitySubtype, equals('character'));
      expect(entry.aliases, contains('Rem'));
      expect(entry.body, equals('로즈월 저택의 메이드.'));
    });

    test('2. serialize writes entity_subtype correctly into Markdown frontmatter', () {
      final serialized = EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_3puh848u',
        title: '렘',
        body: '로즈월 저택의 메이드.',
        aliases: ['Rem'],
        entitySubtype: 'character',
      );

      expect(serialized, contains('entity_subtype: "character"'));
      expect(serialized, contains('entity_id: "pe_u_3puh848u"'));
      expect(serialized, contains('record_kind: entityJournal'));
    });

    test('3. VaultRecordSummary.fromEntityEntry populates entitySubtype', () async {
      final entry = EntityJournalEntry(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_3puh848u',
        title: '렘',
        body: '로즈월 저택의 메이드.',
        addedAt: DateTime.now(),
        storagePath: 'test/entities/person/pe_u_3puh848u.md',
        entitySubtype: 'character',
      );

      final summary = await VaultRecordSummary.fromEntityEntry(
        vaultPath: '.',
        entry: entry,
      );

      expect(summary.id, equals('pe_u_3puh848u'));
      expect(summary.entitySubtype, equals('character'));

      final json = summary.toJson();
      expect(json['entitySubtype'], equals('character'));

      final fromJson = VaultRecordSummary.fromJson(json);
      expect(fromJson.entitySubtype, equals('character'));
    });

    test('4. parse structured links and query relationship roles', () {
      const content = '''---
schema_version: 3
record_id: "rec_wk_u_rezero"
entity_id: "wk_u_rezero"
record_kind: workJournal
title: "Re:제로부터 시작하는 이세계 생활"
links:
  - relation: "character"
    target_id: "pe_u_3puh848u"
    target_title: "렘"
    label: "메인 히로인"
  - relation: "creator"
    target_id: "pe_u_tappei"
    target_title: "나가츠키 탓페이"
    label: "작가"
---
명작.
''';

      final frontmatter = content.split('---')[1];
      final meta = ArchiveRecordContract.metadataFromYaml(
        loadYaml(frontmatter) as Map,
      );
      expect(meta.links, hasLength(2));

      final characterLink = meta.links.firstWhere((link) => link.relation == 'character');
      expect(characterLink.targetId, equals('pe_u_3puh848u'));
      expect(characterLink.targetTitle, equals('렘'));
      expect(characterLink.label, equals('메인 히로인'));

      final creatorLink = meta.links.firstWhere((link) => link.relation == 'creator');
      expect(creatorLink.targetId, equals('pe_u_tappei'));
      expect(creatorLink.targetTitle, equals('나가츠키 탓페이'));
      expect(creatorLink.label, equals('작가'));
    });

    test('5. serialize structured links correctly formats yaml', () {
      final buffer = StringBuffer();
      final metadata = ArchiveRecordMetadata(
        links: [
          const ArchiveStructuredLink(
            targetId: 'pe_u_3puh848u',
            targetTitle: '렘',
            relation: 'character',
            label: '메인 히로인',
          ),
        ],
      );

      ArchiveRecordContract.writeContractFields(
        buffer,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      final out = buffer.toString();
      expect(out, contains('links:'));
      expect(out, contains('relation: "character"'));
      expect(out, contains('target_id: "pe_u_3puh848u"'));
      expect(out, contains('target_title: "렘"'));
      expect(out, contains('label: "메인 히로인"'));
    });
  });
}
