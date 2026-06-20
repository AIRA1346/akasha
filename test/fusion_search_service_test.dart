import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/fusion_search_service.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/helpers.dart';

import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FusionSearchService', () {
    test('returns catalog-only hit when no local md or global match', () async {
      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity(
            entityId: 'wk_u_onlycat1',
            subtype: MediaCategory.manga,
            title: '유니크 카탈로그 만화',
            creator: '나',
            addedAt: DateTime.utc(2024, 5, 1),
          ),
        ]);
      final registry = FakeRegistryPort()
        ..addWork(
          RegistryWork(
            workId: 'wk_000000001',
            title: '글로벌 다른 작품',
            category: MediaCategory.manga,
            domain: AppDomain.subculture,
          ),
        );

      final result = await FusionSearchService.search(
        query: '유니크 카탈로그',
        localItems: const [],
        userCatalog: catalog,
        registry: registry,
      );

      expect(result.localItems, isEmpty);
      expect(result.registryHits, hasLength(1));
      expect(result.registryHits.first.source, FusionRegistrySource.userCatalog);
      expect(result.registryHits.first.work.workId, 'wk_u_onlycat1');
    });

    test('prefers local md row over catalog entry with same workId', () async {
      final localItem = createItem(
        workId: 'wk_u_shared01',
        title: '공유 ID 작품',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      )..filePath = '/vault/manga/공유 ID 작품.md';

      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity(
            entityId: 'wk_u_shared01',
            subtype: MediaCategory.manga,
            title: '공유 ID 작품',
            addedAt: DateTime.utc(2024, 5, 1),
          ),
        ]);

      final result = await FusionSearchService.search(
        query: '공유',
        localItems: [localItem],
        userCatalog: catalog,
        registry: FakeRegistryPort(),
      );

      expect(result.localItems, hasLength(1));
      expect(result.registryHits, isEmpty);
    });

    test('excludes global registry row when workId already in user catalog', () async {
      const sharedId = 'wk_u_blockglob';
      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity(
            entityId: sharedId,
            subtype: MediaCategory.manga,
            title: '카탈로그 전용',
            addedAt: DateTime.utc(2024, 5, 1),
          ),
        ]);
      final registry = FakeRegistryPort()
        ..addWork(
          RegistryWork(
            workId: sharedId,
            title: '카탈로그 전용',
            category: MediaCategory.manga,
            domain: AppDomain.subculture,
          ),
        );

      final result = await FusionSearchService.search(
        query: '카탈로그',
        localItems: const [],
        userCatalog: catalog,
        registry: registry,
      );

      expect(result.registryHits, hasLength(1));
      expect(result.registryHits.first.source, FusionRegistrySource.userCatalog);
      expect(result.registryHits.first.work.workId, sharedId);
    });

    test('finds archived entity journal by semantic tag', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_fusion_tags_');
      try {
        await service.setVaultPath(tempDir.path);
        final entityDir = Directory(p.join(tempDir.path, 'entities', 'person'));
        await entityDir.create(recursive: true);
        await File(p.join(entityDir.path, 'natsuki.md')).writeAsString('''
---
entity_type: person
entity_id: "pe_u_fusiontag1"
record_kind: entityJournal
title: "나츠키 스바루"
added_at: "2026-06-20T12:00:00.000Z"
tags: ["영웅", "성장", "구원"]
---
메모
''');

        final result = await FusionSearchService.search(
          query: '영웅',
          localItems: const [],
          userCatalog: FakeUserCatalogPort(),
          registry: FakeRegistryPort(),
        );

        expect(result.localEntityJournals, hasLength(1));
        expect(result.localEntityJournals.first.entityId, 'pe_u_fusiontag1');
        expect(result.localEntityJournals.first.tags, contains('영웅'));
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('catalog tag match via matchesQuery', () async {
      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity.userLocal(
            entityId: 'pe_u_cattag01',
            type: EntityAnchorType.person,
            title: '에밀리아',
            tags: const ['영웅', '왕후보'],
          ),
        ]);

      final result = await FusionSearchService.search(
        query: '왕후보',
        localItems: const [],
        userCatalog: catalog,
        registry: FakeRegistryPort(),
      );

      expect(result.registryHits, hasLength(1));
      expect(result.registryHits.first.entityType, EntityAnchorType.person);
      expect(result.registryHits.first.work.tags, contains('왕후보'));
    });
  });

  group('EntityAnchor.isWork — user local', () {
    test('wk_u_* is work anchor', () {
      const anchor = EntityAnchor(
        entityId: 'wk_u_abcd1234',
        type: EntityAnchorType.work,
      );
      expect(anchor.isUserLocalWork, isTrue);
      expect(anchor.isGlobalWork, isFalse);
      expect(anchor.isWork, isTrue);
    });
  });
}
