import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/services/works_registry.dart';
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

      expect(restored.workId, original.workId);
      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.rating, original.rating);
      expect(restored.isHallOfFame, true);
      expect(restored.myStatusLabel, '전부 봄');
      expect(restored.memorableQuotes, contains('"명대사 테스트"'));
      expect(restored.review, '감상문 본문입니다.');
      expect(restored.tags, containsAll(['테스트', '판타지']));
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

    test('ensureWorkId creates custom id when no registry match', () {
      final item = createItem(
        workId: '',
        title: '존재하지않는작품XYZ',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        releaseYear: 2025,
      );
      final id = MarkdownParser.ensureWorkId(item);
      expect(id, startsWith('sub_manga_custom_'));
    });

    test('isArchivedInVault is true only when vault linked and filePath set', () async {
      final service = AkashaFileService();
      final item = createItem(
        workId: 'sub_manga_archbadge_2020',
        title: '배지 테스트',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      );

      expect(service.isArchivedInVault(item), isFalse);

      final tempDir = await Directory.systemTemp.createTemp('akasha_badge_test_');
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
    });

    test('saveItem writes .md to vault and loadAllItems reads it back', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_vault_test_');
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
    });
  });
}
