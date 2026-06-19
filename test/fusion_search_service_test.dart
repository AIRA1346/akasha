import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/fusion_search_service.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/helpers.dart';

import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';

void main() {
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
