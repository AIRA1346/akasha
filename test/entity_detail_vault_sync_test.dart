import 'dart:io';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/features/workbench/presentation/entity_detail_vault_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadJournalFromDisk parses entity journal markdown', () async {
    final dir = await Directory.systemTemp.createTemp('entity_vault_sync');
    addTearDown(() => dir.delete(recursive: true));

    final path = '${dir.path}/person.md';
    await File(path).writeAsString('''
---
entity_type: person
entity_id: "ent_person_test"
record_kind: entityJournal
title: "테스트"
added_at: "2024-01-01T00:00:00.000Z"
tags: [태그]
---

본문 내용
''');

    final entry = await EntityDetailVaultSync.loadJournalFromDisk(path);

    expect(entry, isNotNull);
    expect(entry!.entityId, 'ent_person_test');
    expect(entry.entityType, EntityAnchorType.person);
    expect(entry.body, '본문 내용');
    expect(entry.tags, ['태그']);
  });

  test('loadJournalFromDisk returns null for missing file', () async {
    expect(
      await EntityDetailVaultSync.loadJournalFromDisk('/no/such/file.md'),
      isNull,
    );
  });
}
