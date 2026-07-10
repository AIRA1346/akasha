import 'dart:io';

import 'package:akasha/core/archiving/archive_record.dart';
import 'package:akasha/core/archiving/archive_record_contract.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/data/adapters/vault_archive_record_adapter.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/timeline_entry_parser.dart';
import 'package:akasha/services/timeline_vault_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TimelineVaultStore', () {
    late Directory vaultDir;
    late TimelineVaultStore store;

    setUp(() async {
      vaultDir = await Directory.systemTemp.createTemp('akasha_timeline_');
      store = const TimelineVaultStore();
    });

    tearDown(() async {
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('generateRecordId matches tl_yyyyMMdd_hex pattern', () {
      final id = TimelineVaultStore.generateRecordId(
        DateTime.parse('2026-06-14T12:00:00.000'),
      );
      expect(id, matches(RegExp(r'^tl_20260614_[0-9a-f]{6}$')));
    });

    test('save creates vault/timeline file', () async {
      const recordId = 'tl_20260614_abc123';
      final record = ArchiveRecord(
        recordId: recordId,
        kind: RecordKind.timelineEntry,
        title: '오늘의 생각',
        timeAnchor: DateTime.parse('2026-06-14T09:00:00.000'),
      );

      final saved = await store.save(
        vaultPath: vaultDir.path,
        record: record,
        body: '힘든 하루였다.',
      );

      expect(saved.storagePath, isNotEmpty);
      expect(await File(saved.storagePath).exists(), isTrue);
      final onDisk = await File(saved.storagePath).readAsString();
      expect(onDisk, contains('record_kind: timelineEntry'));
      expect(saved.body, '힘든 하루였다.');
      expect(saved.recordId, recordId);
    });

    test('save preserves addedAt on update', () async {
      const recordId = 'tl_20260614_update1';
      final first = ArchiveRecord(
        recordId: recordId,
        kind: RecordKind.timelineEntry,
        title: 'v1',
        timeAnchor: DateTime.parse('2026-06-14T09:00:00.000'),
      );
      final created = await store.save(
        vaultPath: vaultDir.path,
        record: first,
        body: 'first',
      );

      final updated = await store.save(
        vaultPath: vaultDir.path,
        record: ArchiveRecord(
          recordId: recordId,
          kind: RecordKind.timelineEntry,
          title: 'v2',
          timeAnchor: DateTime.parse('2026-06-15T09:00:00.000'),
          storagePath: created.storagePath,
        ),
        body: 'second',
      );

      expect(updated.addedAt, created.addedAt);
      expect(updated.title, 'v2');
      expect(updated.body, 'second');
      expect(updated.occurredAt, DateTime.parse('2026-06-15T09:00:00.000'));
    });

    test('update preserves the original creation source', () async {
      const recordId = 'tl_source_preserve';
      final file = File('${vaultDir.path}/timeline/$recordId.md');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        TimelineEntryParser.serialize(
          recordId: recordId,
          title: 'Agent timeline',
          body: 'original body',
          occurredAt: DateTime(2026, 7, 10, 9),
          addedAt: DateTime.utc(2026, 7, 10),
          metadata: const ArchiveRecordMetadata(source: 'agent'),
        ),
      );

      final updated = await store.save(
        vaultPath: vaultDir.path,
        record: ArchiveRecord(
          recordId: recordId,
          kind: RecordKind.timelineEntry,
          title: 'Edited timeline',
          timeAnchor: DateTime(2026, 7, 10, 10),
          storagePath: file.path,
        ),
        body: 'edited body',
      );

      expect(updated.recordMetadata.source, 'agent');
      expect(await file.readAsString(), contains('source: "agent"'));
    });

    test('delete removes timeline file', () async {
      const recordId = 'tl_20260614_del001';
      await store.save(
        vaultPath: vaultDir.path,
        record: ArchiveRecord(
          recordId: recordId,
          kind: RecordKind.timelineEntry,
          title: '삭제 대상',
        ),
        body: 'gone',
      );

      await store.delete(vaultPath: vaultDir.path, recordId: recordId);

      final timelineDir = Directory('${vaultDir.path}/timeline');
      final mdFiles = timelineDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.md'),
      );
      expect(mdFiles, isEmpty);
    });
  });

  group('VaultArchiveRecordAdapter timeline persist', () {
    late Directory vaultDir;
    late AkashaFileService fileService;
    late VaultArchiveRecordAdapter adapter;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      vaultDir = await Directory.systemTemp.createTemp('akasha_adapter_');
      fileService = AkashaFileService();
      await fileService.setVaultPath(vaultDir.path);
      adapter = VaultArchiveRecordAdapter();
    });

    tearDown(() async {
      await fileService.setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('save list get delete round-trip', () async {
      final recordId = TimelineVaultStore.generateRecordId();
      final record = ArchiveRecord(
        recordId: recordId,
        kind: RecordKind.timelineEntry,
        title: 'Dogfood entry',
        timeAnchor: DateTime.parse('2026-06-14T18:00:00.000'),
      );

      await adapter.save(record, bodyMarkdown: 'round-trip body');

      final listed = await adapter.listRecords(
        kinds: {RecordKind.timelineEntry},
      );
      expect(listed.any((r) => r.recordId == recordId), isTrue);

      final fetched = await adapter.getById(recordId);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Dogfood entry');
      expect(fetched.kind, RecordKind.timelineEntry);

      await adapter.delete(recordId);
      expect(await adapter.getById(recordId), isNull);
    });

    test('save rejects workJournal', () async {
      final record = ArchiveRecord(
        recordId: 'wk_test',
        kind: RecordKind.workJournal,
        title: 'Work',
      );

      expect(
        () => adapter.save(record, bodyMarkdown: 'x'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
