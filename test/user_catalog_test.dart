import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/models/work_id_codec.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/user_catalog_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserCatalogStore.instance.resetForTesting();
  });

  group('UserCatalogStore', () {
    test('round-trips user_entities.json in vault catalog folder', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_catalog_');
      try {
        await service.setVaultPath(tempDir.path);

        final entity = UserCatalogEntity(
          entityId: WorkIdCodec.buildUserLocal(suffix: 'test0001'),
          subtype: MediaCategory.manga,
          title: '내 catalog 테스트',
          creator: '작가',
          releaseYear: 2024,
          domain: AppDomain.subculture,
          tags: const ['판타지', '이세계'],
          addedAt: DateTime.utc(2024, 1, 2),
        );

        await UserCatalogStore.instance.upsert(entity);
        UserCatalogStore.instance.resetForTesting();
        await UserCatalogStore.instance.load();

        expect(UserCatalogStore.instance.all, hasLength(1));
        final loaded = UserCatalogStore.instance.all.first;
        expect(loaded.entityId, entity.entityId);
        expect(loaded.title, entity.title);
        expect(loaded.creator, entity.creator);
        expect(loaded.releaseYear, 2024);
        expect(loaded.tags, ['판타지', '이세계']);

        final file = File('${tempDir.path}/catalog/user_entities.json');
        expect(await file.exists(), isTrue);
        final decoded = json.decode(await file.readAsString()) as Map;
        expect(decoded['version'], UserCatalogStore.schemaVersion);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('search matches title and creator', () async {
      UserCatalogStore.instance.setEntitiesForTesting([
        UserCatalogEntity(
          entityId: 'wk_u_catalog01',
          subtype: MediaCategory.animation,
          title: '프라이빗 애니',
          creator: '스튜디오 A',
          addedAt: DateTime.utc(2024, 3, 1),
        ),
      ]);

      expect(UserCatalogStore.instance.search('프라이빗'), hasLength(1));
      expect(UserCatalogStore.instance.search('스튜디오'), hasLength(1));
      expect(UserCatalogStore.instance.search('없음'), isEmpty);
    });
  });
}
