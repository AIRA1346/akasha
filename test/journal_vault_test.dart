import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/archive_record.dart';
import 'package:akasha/core/archiving/archive_record_mapper.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/data/adapters/vault_archive_record_adapter.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/journal_entry_parser.dart';
import 'package:akasha/services/journal_vault_loader.dart';
import 'package:akasha/services/journal_vault_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JournalEntryParser', () {
    test('parse and serialize round-trip', () {
      const content = '''---
record_kind: freeformJournal
record_id: "jr_20260619_abc123"
title: "테스트 메모"
added_at: "2026-06-19T10:00:00.000"
---
본문 내용입니다.
''';

      final parsed = JournalEntryParser.parse(content, r'C:\vault\journal\jr.md');
      expect(parsed, isNotNull);
      expect(parsed!.recordId, 'jr_20260619_abc123');
      expect(parsed.title, '테스트 메모');
      expect(parsed.body, '본문 내용입니다.');

      final reserialized = JournalEntryParser.serialize(
        recordId: parsed.recordId,
        title: parsed.title,
        body: parsed.body,
        addedAt: parsed.addedAt,
      );
      final reparsed = JournalEntryParser.parse(reserialized, parsed.storagePath);
      expect(reparsed?.recordId, parsed.recordId);
      expect(reparsed?.title, parsed.title);
      expect(reparsed?.body, parsed.body);
    });

    test('rejects non-freeformJournal record_kind', () {
      const content = '''---
record_kind: timeline
record_id: "tl_1"
title: "x"
---
body
''';
      expect(JournalEntryParser.parse(content, 'a.md'), isNull);
    });
  });

  group('JournalVaultStore', () {
    test('save and load from vault', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_w3_journal_');
      try {
        await service.setVaultPath(tempDir.path);
        const store = JournalVaultStore();
        const loader = JournalVaultLoader();

        final recordId = JournalVaultStore.generateRecordId();
        final saved = await store.save(
          vaultPath: tempDir.path,
          record: ArchiveRecord(
            recordId: recordId,
            kind: RecordKind.freeformJournal,
            title: 'Journal Test',
            timeAnchor: DateTime.utc(2026, 6, 19),
          ),
          body: 'freeform body',
        );

        expect(saved.title, 'Journal Test');
        expect(saved.body, 'freeform body');

        final loaded = await loader.loadFromVault(tempDir.path);
        expect(loaded.length, 1);
        expect(loaded.first.recordId, recordId);

        final mapped = ArchiveRecordMapper.fromJournalEntry(loaded.first);
        expect(mapped.kind, RecordKind.freeformJournal);
        expect(mapped.entity, isNull);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('VaultArchiveRecordAdapter freeformJournal', () {
    test('listRecords includes journal entries', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_w3_adapter_');
      try {
        await service.setVaultPath(tempDir.path);
        final adapter = VaultArchiveRecordAdapter();
        const store = JournalVaultStore();

        final recordId = JournalVaultStore.generateRecordId();
        await store.save(
          vaultPath: tempDir.path,
          record: ArchiveRecord(
            recordId: recordId,
            kind: RecordKind.freeformJournal,
            title: 'Adapter Test',
          ),
          body: 'adapter body',
        );

        final records = await adapter.listRecords(
          kinds: {RecordKind.freeformJournal},
        );
        expect(records.any((r) => r.recordId == recordId), isTrue);

        await adapter.delete(recordId);
        final afterDelete = await adapter.listRecords(
          kinds: {RecordKind.freeformJournal},
        );
        expect(afterDelete.any((r) => r.recordId == recordId), isFalse);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
