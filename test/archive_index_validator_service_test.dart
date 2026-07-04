import 'dart:io';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/services/archive_index_validator_service.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vaultDir;
  late ArchiveIndexValidatorService validator;

  setUp(() async {
    vaultDir = await Directory.systemTemp.createTemp('akasha_index_validate_');
    validator = ArchiveIndexValidatorService();
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test('validate rebuilds and accepts a mixed path vault', () async {
    final legacyWorkFile = File(p.join(vaultDir.path, 'Legacy Work.md'));
    await legacyWorkFile.writeAsString('''
---
work_id: "wk_u_valid001"
entity_type: work
title: "Valid Work"
aliases: ["VW"]
original_title: "Original Valid Work"
category: movie
rating: 5
tags: ["action"]
---

Related [[pe_u_valid001|Valid Person]]
''');

    final entityFile = File(
      p.join(vaultDir.path, 'entities', 'person', 'pe_u_valid001.md'),
    );
    await entityFile.parent.create(recursive: true);
    await entityFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_valid001',
        title: 'Valid Person',
        aliases: const ['VP'],
        body: 'Related [[wk_u_valid001|Valid Work]]',
      ),
    );

    final result = await validator.validate(vaultPath: vaultDir.path);

    expect(result.succeeded, isTrue);
    expect(result.errors, isEmpty);
    expect(result.stats['sourceRecords'], 2);
    expect(result.stats['recordIndexRecords'], 2);
    expect(result.stats['entityPathIndexEntries'], 1);
    expect(result.stats['titleAliasExpectedNames'], greaterThan(2));
  });

  test(
    'validate reports duplicate source ids hidden by index dedupe',
    () async {
      await File(p.join(vaultDir.path, 'A.md')).writeAsString('''
---
work_id: "wk_u_dup0001"
entity_type: work
title: "Duplicate A"
category: movie
---

A
''');
      await File(p.join(vaultDir.path, 'B.md')).writeAsString('''
---
work_id: "wk_u_dup0001"
entity_type: work
title: "Duplicate B"
category: movie
---

B
''');

      final result = await validator.validate(vaultPath: vaultDir.path);

      expect(result.succeeded, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('source_duplicate_record_id'),
      );
    },
  );

  test('validate without rebuild reports stale derived index paths', () async {
    final workFile = File(p.join(vaultDir.path, 'Stale.md'));
    await workFile.writeAsString('''
---
work_id: "wk_u_stale001"
entity_type: work
title: "Stale Work"
category: movie
rating: 4
tags: ["stale"]
---

Related [[pe_u_miss0001]]
''');

    final first = await validator.validate(vaultPath: vaultDir.path);
    expect(first.succeeded, isTrue);

    await workFile.delete();
    final stale = await validator.validate(
      vaultPath: vaultDir.path,
      rebuildFirst: false,
    );

    expect(stale.succeeded, isFalse);
    expect(
      stale.errors.map((issue) => issue.code),
      contains('record_index_stale_id'),
    );
    expect(
      stale.errors.map((issue) => issue.code),
      contains('title_alias_stale_path'),
    );
    expect(
      stale.errors.map((issue) => issue.code),
      contains('taste_signal_stale_evidence_path'),
    );
  });

  test(
    'validate reports unresolved explicit link targets as warnings',
    () async {
      await File(p.join(vaultDir.path, 'Missing Link.md')).writeAsString('''
---
work_id: "wk_u_linkwarn1"
entity_type: work
title: "Missing Link Work"
category: movie
---

Related [[pe_u_miss0001]]
''');

      final result = await validator.validate(vaultPath: vaultDir.path);

      expect(result.succeeded, isTrue);
      expect(
        result.warnings.map((issue) => issue.code),
        contains('link_target_missing_local'),
      );
    },
  );

  test('validate rejects an empty vault path', () async {
    final result = await validator.validate(vaultPath: '');

    expect(result.succeeded, isFalse);
    expect(result.errors.single.code, 'vault_path_required');
  });
}
