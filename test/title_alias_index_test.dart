import 'dart:io';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/title_alias_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vaultDir;
  late TitleAliasIndexService index;

  setUp(() async {
    vaultDir = await Directory.systemTemp.createTemp('akasha_title_alias_');
    index = TitleAliasIndexService();
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test('rebuildFromVault indexes work and entity title variants', () async {
    final workFile = File(
      p.join(vaultDir.path, 'works', 'movie', 'wk_u_alias001.md'),
    );
    await workFile.parent.create(recursive: true);
    await workFile.writeAsString('''
---
schema_version: 3
record_id: "rec_wk_u_alias001"
work_id: "wk_u_alias001"
entity_type: work
record_kind: workJournal
title: "Cyber Action"
aliases: ["CA", "Cyber-Action"]
original_title: "Saiba Akushon"
titles:
  ko: "사이버 액션"
  en: "Cyber Action"
---

memo
''');

    final entityFile = File(
      p.join(vaultDir.path, 'entities', 'person', 'pe_u_alias001.md'),
    );
    await entityFile.parent.create(recursive: true);
    await entityFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_alias001',
        title: 'Rem',
        aliases: const ['렘', 'Rem (Re:Zero)'],
        body: 'body',
      ),
    );

    final stats = await index.rebuildFromVault(vaultDir.path);

    expect(stats.targets, 2);
    expect(stats.names, greaterThanOrEqualTo(6));
    expect(
      await File(
        p.join(vaultDir.path, '.akasha', 'title_alias_index', 'manifest.json'),
      ).exists(),
      isTrue,
    );

    expect(
      (await index.lookup(
        vaultDir.path,
        'cyber action',
      )).map((entry) => entry.targetId),
      contains('wk_u_alias001'),
    );
    expect(
      (await index.lookup(
        vaultDir.path,
        'Cyber-Action',
      )).map((entry) => entry.targetId),
      contains('wk_u_alias001'),
    );
    expect(
      (await index.lookup(
        vaultDir.path,
        '사이버액션',
      )).map((entry) => entry.targetId),
      contains('wk_u_alias001'),
    );
    expect(
      (await index.lookup(
        vaultDir.path,
        'Rem (Re:Zero)',
      )).map((entry) => entry.targetId),
      contains('pe_u_alias001'),
    );
    expect(
      (await index.lookup(
        vaultDir.path,
        '렘',
        recordKind: RecordKind.entityJournal,
      )).map((entry) => entry.entityType),
      contains(EntityAnchorType.person.name),
    );
  });

  test('upsertMarkdownFile replaces old names for the changed path', () async {
    final survivorFile = File(
      p.join(vaultDir.path, 'entities', 'person', 'pe_u_survivor1.md'),
    );
    await survivorFile.parent.create(recursive: true);
    await survivorFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_survivor1',
        title: 'Stable Name',
        aliases: const ['Still Here'],
        body: 'body',
      ),
    );
    await index.upsertMarkdownFile(
      vaultPath: vaultDir.path,
      absolutePath: survivorFile.path,
    );

    final changedFile = File(
      p.join(vaultDir.path, 'entities', 'person', 'pe_u_changed01.md'),
    );
    await changedFile.parent.create(recursive: true);
    await changedFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_changed01',
        title: 'Old Name',
        aliases: const ['Old Alias'],
        body: 'body',
      ),
    );
    await index.upsertMarkdownFile(
      vaultPath: vaultDir.path,
      absolutePath: changedFile.path,
    );

    await changedFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_changed01',
        title: 'New Name',
        aliases: const ['New Alias'],
        body: 'body',
      ),
    );
    final entries = await index.upsertMarkdownFile(
      vaultPath: vaultDir.path,
      absolutePath: changedFile.path,
    );

    expect(entries.map((entry) => entry.targetId), contains('pe_u_changed01'));
    expect(await index.lookup(vaultDir.path, 'Old Alias'), isEmpty);
    expect(
      (await index.lookup(
        vaultDir.path,
        'New Alias',
      )).map((entry) => entry.targetId),
      contains('pe_u_changed01'),
    );
    expect(
      (await index.lookup(
        vaultDir.path,
        'Still Here',
      )).map((entry) => entry.targetId),
      contains('pe_u_survivor1'),
    );
  });

  test('removeByAbsolutePath removes title and alias entries', () async {
    final entityFile = File(
      p.join(vaultDir.path, 'entities', 'concept', 'co_u_remove01.md'),
    );
    await entityFile.parent.create(recursive: true);
    await entityFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.concept,
        entityId: 'co_u_remove01',
        title: 'Remove Name',
        aliases: const ['Remove Alias'],
        body: 'body',
      ),
    );
    await index.upsertMarkdownFile(
      vaultPath: vaultDir.path,
      absolutePath: entityFile.path,
    );

    final removed = await index.removeByAbsolutePath(
      vaultPath: vaultDir.path,
      absolutePath: entityFile.path,
    );

    expect(removed, greaterThan(0));
    expect(await index.lookup(vaultDir.path, 'Remove Name'), isEmpty);
    expect(await index.lookup(vaultDir.path, 'Remove Alias'), isEmpty);
  });
}
