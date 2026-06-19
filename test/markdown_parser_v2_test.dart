import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/archive_record_mapper.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/services/user_preferences.dart';
import 'package:akasha/services/vault_work_journal_paths.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MarkdownParser v2', () {
    test('deserializes legacy fixture without entity_* fields', () async {
      final content = await File('test/fixtures/vault_v1_legacy.md')
          .readAsString();
      final item = MarkdownParser.deserialize(content, 'fallback');

      expect(item.workId, 'sub_manga_legacytest_2020');
      expect(item.title, '레거시 테스트 만화');
      expect(item.category, MediaCategory.manga);
    });

    test('deserializes v2 fixture with entity_id mirror', () async {
      final content =
          await File('test/fixtures/vault_v2_work.md').readAsString();
      final item = MarkdownParser.deserialize(content, 'fallback');

      expect(item.workId, 'wk_u_fixt0001');
      expect(item.category, MediaCategory.animation);
    });

    test('serialize adds lazy entity_* fields', () {
      final item = createItem(
        workId: 'wk_u_ser00001',
        title: 'Serialize Test',
        category: MediaCategory.book,
        domain: AppDomain.subculture,
      );

      final md = MarkdownParser.serialize(item);

      expect(md, contains('entity_type: work'));
      expect(md, contains('entity_id: "wk_u_ser00001"'));
      expect(md, contains('subtype: book'));
      expect(md, contains('record_kind: workJournal'));
      expect(md, contains('work_id: "wk_u_ser00001"'));
    });

    test('round-trip preserves workId and category', () {
      final original = createItem(
        workId: 'wk_u_round001',
        title: 'Round Trip',
        category: MediaCategory.game,
        domain: AppDomain.subculture,
        rating: 4.0,
      );

      final restored = MarkdownParser.deserialize(
        MarkdownParser.serialize(original),
        'fallback',
      );

      expect(restored.workId, original.workId);
      expect(restored.category, original.category);
      expect(restored.title, original.title);
      expect(restored.rating, original.rating);
    });
  });

  group('ArchiveRecordMapper.fromWorkMarkdown', () {
    test('maps v2 fixture to workJournal record', () async {
      final content =
          await File('test/fixtures/vault_v2_work.md').readAsString();
      final record = ArchiveRecordMapper.fromWorkMarkdown(
        content,
        r'C:\vault\works\animation\Wave 2 Fixture 작품.md',
      );

      expect(record.kind, RecordKind.workJournal);
      expect(record.entity?.entityId, 'wk_u_fixt0001');
      expect(record.title, 'Wave 2 Fixture 작품');
    });
  });

  group('VaultWorkJournalPaths', () {
    test('default legacy category path', () {
      final item = createItem(
        workId: 'wk_u_path01',
        title: 'Path Test',
        category: MediaCategory.manga,
      );
      final path = VaultWorkJournalPaths.resolveNewPath(
        vaultRoot: r'C:\vault',
        item: item,
        useWorksLayout: false,
      );

      expect(path, r'C:\vault\manga\Path Test.md');
    });

    test('works layout path when enabled', () {
      final item = createItem(
        workId: 'wk_u_path02',
        title: 'Works Path',
        category: MediaCategory.animation,
      );
      final path = VaultWorkJournalPaths.resolveNewPath(
        vaultRoot: r'C:\vault',
        item: item,
        useWorksLayout: true,
      );

      expect(path, r'C:\vault\works\animation\Works Path.md');
    });
  });

  group('AkashaFileService saveItem path', () {
    test('new item uses works/ when pref enabled', () async {
      await UserPreferences.setVaultWorksLayoutEnabled(true);
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_w2_path_');
      try {
        await service.setVaultPath(tempDir.path);
        final item = createItem(
          workId: 'wk_u_newpath1',
          title: 'New Works Layout',
          category: MediaCategory.manga,
        );

        await service.saveItem(item);

        expect(item.filePath, contains('works'));
        expect(item.filePath, contains('manga'));
        expect(File(item.filePath!).existsSync(), isTrue);

        final content = await File(item.filePath!).readAsString();
        expect(content, contains('entity_id: "wk_u_newpath1"'));
      } finally {
        await service.setVaultPath('');
        await UserPreferences.setVaultWorksLayoutEnabled(false);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('existing filePath is not moved on save', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_w2_keep_');
      try {
        await service.setVaultPath(tempDir.path);
        await UserPreferences.setVaultWorksLayoutEnabled(true);

        final legacyPath = '${tempDir.path}/manga/Stay Here.md';
        await Directory('${tempDir.path}/manga').create(recursive: true);
        final item = createItem(
          workId: 'sub_manga_stay_2020',
          title: 'Stay Here',
          category: MediaCategory.manga,
        );
        item.filePath = legacyPath;
        await File(legacyPath).writeAsString(MarkdownParser.serialize(item));

        await service.saveItem(item);

        expect(item.filePath, legacyPath);
        expect(item.filePath, isNot(contains('works')));
      } finally {
        await service.setVaultPath('');
        await UserPreferences.setVaultWorksLayoutEnabled(false);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
