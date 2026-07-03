import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/models/work_id_codec.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/data/adapters/markdown_vault_adapter.dart';
import 'package:akasha/services/user_preferences.dart';
import 'package:akasha/services/vault_work_journal_paths.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Vault archive stability', () {
    test('dedupeItems prefers newest addedAt for same workId', () {
      final older = createItem(
        workId: 'sub_manga_test_2020',
        title: '테스트 만화',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      )..addedAt = DateTime(2020, 1, 1);

      final newer = createItem(
        workId: 'sub_manga_test_2020',
        title: '테스트 만화 (갱신)',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      )..addedAt = DateTime(2024, 6, 1);

      final result = AkashaFileService.dedupeItems([older, newer]);
      expect(result, hasLength(1));
      expect(result.first.title, '테스트 만화 (갱신)');
    });

    test('Markdown round-trip preserves user archive fields', () {
      final original = createItem(
        workId: 'sub_manga_roundtrip_2021',
        title: '라운드트립 테스트',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        workStatus: '완결',
        myStatus: '전부 봄',
        rating: 4.5,
        memorableQuotes: ['"명대사 테스트"'],
        review: '감상문 본문입니다.',
        isHallOfFame: true,
        tags: ['테스트', '판타지'],
      );

      final restored = MarkdownParser.deserialize(
        MarkdownParser.serialize(original),
        'fallback',
      );
      final serialized = MarkdownParser.serialize(original);

      expect(restored.workId, original.workId);
      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.rating, original.rating);
      expect(restored.isHallOfFame, true);
      expect(restored.myStatusLabel, 'Finished');
      expect(restored.memorableQuotes, contains('"명대사 테스트"'));
      expect(restored.review, '감상문 본문입니다.');
      expect(restored.tags, containsAll(['테스트', '판타지']));
      expect(serialized, contains('poster: ""'));
      expect(serialized, contains('# 📝 메모'));
      expect(
        serialized.indexOf('poster:'),
        lessThan(serialized.indexOf('rating:')),
      );
    });

    test('ensureWorkId assigns master id from registry title match', () {
      final item = createItem(
        workId: '',
        title: '나루토',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      );
      final id = MarkdownParser.ensureWorkId(item);
      expect(id, WorksRegistry.getWorkById('sub_manga_naruto_1999')!.workId);
    });

    test('ensureWorkId creates user local id when no registry match', () {
      final item = createItem(
        workId: '',
        title: '존재하지않는작품XYZ',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        releaseYear: 2025,
      );
      final id = MarkdownParser.ensureWorkId(item);
      expect(WorkIdCodec.isUserLocalWorkId(id), isTrue);
      expect(WorkIdCodec.isMasterFormat(id), isTrue);
    });

    test('ensureWorkId preserves existing user local id', () {
      const userLocalId = 'wk_u_abcd1234';
      final item = createItem(
        workId: userLocalId,
        title: '내 catalog 작품',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      );
      expect(MarkdownParser.ensureWorkId(item), userLocalId);
    });

    test(
      'isArchivedInVault is true only when vault linked and filePath set',
      () async {
        final service = AkashaFileService();
        final item = createItem(
          workId: 'sub_manga_archbadge_2020',
          title: '배지 테스트',
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
        );

        expect(service.isArchivedInVault(item), isFalse);

        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_badge_test_',
        );
        try {
          await service.setVaultPath(tempDir.path);
          expect(service.isArchivedInVault(item), isFalse);

          item.filePath = '${tempDir.path}/manga/배지 테스트.md';
          expect(service.isArchivedInVault(item), isTrue);
        } finally {
          await service.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'saveItem writes .md to vault and loadAllItems reads it back',
      () async {
        final service = AkashaFileService();
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_vault_test_',
        );
        try {
          await service.setVaultPath(tempDir.path);

          final item = createItem(
            workId: 'sub_game_vaulttest_2022',
            title: '볼트 저장 테스트',
            category: MediaCategory.game,
            domain: AppDomain.subculture,
            workStatus: '출시됨',
            myStatus: '볼 예정',
            memorableQuotes: ['인용 테스트'],
            review: '저장 검증',
            tags: ['테스트'],
          );

          await service.saveItem(item);
          expect(item.filePath, isNotNull);
          expect(File(item.filePath!).existsSync(), isTrue);

          final loaded = await service.loadAllItems();
          expect(loaded, hasLength(1));
          expect(loaded.first.workId, item.workId);
          expect(loaded.first.title, item.title);
          expect(loaded.first.review, '저장 검증');
          expect(loaded.first.memorableQuotes, isNotEmpty);
        } finally {
          await service.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'title rename fallback keeps a single v3 ID file when filePath is missing',
      () async {
        SharedPreferences.setMockInitialValues({
          UserPreferences.vaultWorksLayoutKey: true,
        });

        final service = AkashaFileService();
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_works_delete_',
        );
        try {
          await service.setVaultPath(tempDir.path);

          final item = createItem(
            workId: 'sub_manga_worksdelete_2024',
            title: 'works 삭제 테스트',
            category: MediaCategory.manga,
            domain: AppDomain.subculture,
          );

          await service.saveItem(item);
          final worksPath = p.join(
            tempDir.path,
            'works',
            MediaCategory.manga.name,
            'sub_manga_worksdelete_2024.md',
          );
          expect(File(worksPath).existsSync(), isTrue);

          item.title = 'works 삭제 테스트 (갱신)';
          item.filePath = null;
          await service.saveItem(item, oldTitle: 'works 삭제 테스트');

          expect(File(worksPath).existsSync(), isTrue);
          expect(await service.countMarkdownFiles(), 1);
          final content = await File(worksPath).readAsString();
          expect(content, contains('title: "works 삭제 테스트 (갱신)"'));
        } finally {
          await service.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test('deleteAkashaItem removes works layout file via filePath', () async {
      SharedPreferences.setMockInitialValues({
        UserPreferences.vaultWorksLayoutKey: true,
      });

      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_works_akasha_delete_',
      );
      try {
        await service.setVaultPath(tempDir.path);

        final item = createItem(
          workId: 'sub_game_worksdelete_2024',
          title: '어댑터 삭제 테스트',
          category: MediaCategory.game,
          domain: AppDomain.subculture,
        );

        await service.saveItem(item);
        expect(item.filePath, isNotNull);
        expect(File(item.filePath!).existsSync(), isTrue);

        final deleted = await service.deleteAkashaItem(item);
        expect(deleted, isTrue);
        expect(File(item.filePath!).existsSync(), isFalse);
        expect(await service.countMarkdownFiles(), 0);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test(
      'MarkdownVaultAdapter.deleteItem uses filePath for works layout',
      () async {
        SharedPreferences.setMockInitialValues({
          UserPreferences.vaultWorksLayoutKey: true,
        });

        final adapter = MarkdownVaultAdapter();
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_adapter_delete_',
        );
        try {
          await adapter.setVaultPath(tempDir.path);

          final item = createItem(
            workId: 'sub_movie_adapterdelete_2024',
            title: '어댑터 경로 삭제',
            category: MediaCategory.movie,
            domain: AppDomain.subculture,
          );

          await adapter.saveItem(item);
          expect(item.filePath, isNotNull);
          expect(File(item.filePath!).existsSync(), isTrue);

          await adapter.deleteItem(item);
          expect(File(item.filePath!).existsSync(), isFalse);
          expect(await adapter.countMarkdownFiles(), 0);
        } finally {
          await adapter.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test('resolveDeleteCandidates includes legacy and works paths', () {
      final candidates = VaultWorkJournalPaths.resolveDeleteCandidates(
        vaultRoot: '/vault',
        title: '테스트/작품',
        category: MediaCategory.manga,
      );

      expect(candidates, [
        p.join('/vault', 'manga', '테스트_작품.md'),
        p.join('/vault', 'works', 'manga', '테스트_작품.md'),
      ]);
    });

    test('title rename moves legacy file to v3 ID path when enabled', () async {
      SharedPreferences.setMockInitialValues({
        UserPreferences.vaultWorksLayoutKey: true,
      });

      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_legacy_rename_',
      );
      try {
        await service.setVaultPath(tempDir.path);

        final legacyPath = p.join(
          tempDir.path,
          MediaCategory.manga.name,
          '레거시 제목.md',
        );
        await Directory(p.dirname(legacyPath)).create(recursive: true);
        final item = createItem(
          workId: 'sub_manga_legacyrename_2024',
          title: '레거시 제목',
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
        );
        item.filePath = legacyPath;
        await File(legacyPath).writeAsString(MarkdownParser.serialize(item));

        item.title = 'works로 이동';
        await service.saveItem(item, oldTitle: '레거시 제목');

        expect(File(legacyPath).existsSync(), isFalse);
        final worksPath = p.join(
          tempDir.path,
          'works',
          MediaCategory.manga.name,
          'sub_manga_legacyrename_2024.md',
        );
        expect(File(worksPath).existsSync(), isTrue);
        expect(item.filePath, worksPath);

        final loaded = await service.loadAllItems();
        expect(loaded, hasLength(1));
        expect(loaded.first.title, 'works로 이동');
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test(
      'title rename keeps v3 ID path stable when already on works path',
      () async {
        SharedPreferences.setMockInitialValues({
          UserPreferences.vaultWorksLayoutKey: true,
        });

        final service = AkashaFileService();
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_works_rename_',
        );
        try {
          await service.setVaultPath(tempDir.path);

          final item = createItem(
            workId: 'sub_manga_worksrename_2024',
            title: 'works 제목',
            category: MediaCategory.manga,
            domain: AppDomain.subculture,
          );
          await service.saveItem(item);

          final oldWorksPath = p.join(
            tempDir.path,
            'works',
            MediaCategory.manga.name,
            'sub_manga_worksrename_2024.md',
          );
          expect(File(oldWorksPath).existsSync(), isTrue);

          item.title = 'works 제목 (갱신)';
          await service.saveItem(item, oldTitle: 'works 제목');

          expect(File(oldWorksPath).existsSync(), isTrue);
          expect(item.filePath, oldWorksPath);
          final content = await File(oldWorksPath).readAsString();
          expect(content, contains('title: "works 제목 (갱신)"'));
        } finally {
          await service.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );
  });
}
