import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/models/collectible_collection.dart';
import 'package:akasha/models/collectible_collection_filter.dart';
import 'package:akasha/models/collectible_kind.dart';
import 'package:akasha/models/collectible_ref.dart';
import 'package:akasha/models/entity_browse_card.dart';
import 'package:akasha/models/collectible_browse_item.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/models/entity_related_works.dart';
import 'package:akasha/services/collectible_collection_pipeline.dart';
import 'package:akasha/services/collectible_collection_storage_service.dart';
import 'package:akasha/services/entity_related_works_discovery.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/utils/entity_tag_semantics.dart';
import 'package:akasha/utils/entity_tag_validator.dart';
import 'package:akasha/widgets/entity_curated_reorder_grid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class _FakeEntityRelatedWorksDiscovery implements EntityRelatedWorksDiscovery {
  _FakeEntityRelatedWorksDiscovery(this._workIdsByEntity);

  final Map<String, Set<String>> _workIdsByEntity;

  @override
  Future<EntityRelatedWorks> discover(String entityId) async {
    return EntityRelatedWorks(
      entityId: entityId,
      workIds: _workIdsByEntity[entityId] ?? const {},
    );
  }

  @override
  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  ) async {
    final uniqueIds = entityIds.where((id) => id.isNotEmpty).toSet();
    return {
      for (final id in uniqueIds)
        id: await discover(id),
    };
  }

  @override
  int? cachedIncomingRecordCount(String entityId) => null;

  @override
  EntityJournalEntry? cachedJournal(String entityId) => null;

  @override
  Map<String, EntityJournalEntry>? get cachedJournalsByEntityId => null;

  @override
  Future<Set<String>> entityIdsForWork(String workId) async {
    return {
      for (final entry in _workIdsByEntity.entries)
        if (entry.value.contains(workId)) entry.key,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('EntityTagSemantics', () {
    test('matchesTagsAll requires exact tag strings', () {
      expect(
        EntityTagSemantics.matchesTagsAll(['영웅', '성장'], ['영웅']),
        isTrue,
      );
      expect(
        EntityTagSemantics.matchesTagsAll(['영웅'], ['영웅', '성장']),
        isFalse,
      );
      expect(
        EntityTagSemantics.matchesTagsAll(['영웅형'], ['영웅']),
        isFalse,
      );
    });
  });

  group('UserCatalogEntity.matchesTagsAll', () {
    UserCatalogEntity person({List<String> tags = const []}) {
      return UserCatalogEntity.userLocal(
        entityId: 'pe_u_abc12345',
        type: EntityAnchorType.person,
        title: 'Test',
        tags: tags,
      );
    }

    test('substring search differs from tagsAll', () {
      final entity = person(tags: ['영웅']);
      expect(entity.matchesQuery('영'), isTrue);
      expect(entity.matchesTagsAll(['영']), isFalse);
      expect(entity.matchesTagsAll(['영웅']), isTrue);
    });
  });

  group('EntityTagValidator', () {
    test('flags tags matching work titles', () {
      final index = EntityTagValidator.buildWorkTitleIndex(
        catalogEntities: [
          UserCatalogEntity(
            entityId: 'wk_u_rezero01',
            entityType: UserCatalogEntity.entityTypeWork,
            subtype: MediaCategory.animation,
            title: 'Re:Zero',
            addedAt: DateTime(2024),
          ),
        ],
      );
      final offending = EntityTagValidator.findWorkTitleTags(
        ['영웅', 'Re:Zero'],
        index,
      );
      expect(offending, ['Re:Zero']);
    });
  });

  group('CollectibleCollectionPipeline', () {
    UserCatalogEntity hero(String id, String title) {
      return UserCatalogEntity.userLocal(
        entityId: id,
        type: EntityAnchorType.person,
        title: title,
        tags: const ['영웅'],
      );
    }

    test('filter mode resolves tagsAll with exact match', () async {
      final collection = CollectibleCollection(
        id: 'col_u_test0001',
        title: '영웅',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          tagsAll: ['영웅'],
        ),
      );
      final catalog = [
        hero('pe_u_subaru01', '나츠키 스바루'),
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_emilia01',
          type: EntityAnchorType.person,
          title: '에밀리아',
          tags: const ['마왕'],
        ),
      ];
      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: catalog,
      );
      expect(result.map((e) => e.title), ['나츠키 스바루']);
    });

    test('curated mode preserves member order', () async {
      final collection = CollectibleCollection(
        id: 'col_u_fav00001',
        title: '최애',
        mode: CollectibleCollectionMode.curated,
        memberOrder: const [
          CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_emilia01'),
          CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_subaru01'),
        ],
      );
      final catalog = [
        hero('pe_u_subaru01', '나츠키 스바루'),
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_emilia01',
          type: EntityAnchorType.person,
          title: '에밀리아',
          tags: const ['영웅'],
        ),
      ];
      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: catalog,
      );
      expect(result.map((e) => e.title), ['에밀리아', '나츠키 스바루']);
    });

    const rezeroWorkId = 'wk_u_rezero01';
    const fateWorkId = 'wk_u_fate0001';

    UserCatalogEntity person({
      required String id,
      required String title,
      List<String> tags = const [],
    }) {
      return UserCatalogEntity.userLocal(
        entityId: id,
        type: EntityAnchorType.person,
        title: title,
        tags: tags,
      );
    }

    _FakeEntityRelatedWorksDiscovery discovery(
      Map<String, Set<String>> workIdsByEntity,
    ) {
      return _FakeEntityRelatedWorksDiscovery(workIdsByEntity);
    }

    test('relatedWorkId match includes linked entity', () async {
      const subaruId = 'pe_u_subaru01';
      const saberId = 'pe_u_saber001';
      final catalog = [
        person(id: subaruId, title: '스바루'),
        person(id: saberId, title: 'Saber'),
      ];
      final collection = CollectibleCollection(
        id: 'col_u_rezero01',
        title: 'Re:Zero Cast',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          relatedWorkId: rezeroWorkId,
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: catalog,
        relatedWorksDiscovery: discovery({
          subaruId: {rezeroWorkId},
          saberId: {fateWorkId},
        }),
      );

      expect(result.map((e) => e.entityId), [subaruId]);
    });

    test('relatedWorkId mismatch excludes unrelated entity', () async {
      const saberId = 'pe_u_saber001';
      final collection = CollectibleCollection(
        id: 'col_u_rezero02',
        title: 'Re:Zero Cast',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          relatedWorkId: rezeroWorkId,
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: [person(id: saberId, title: 'Saber')],
        relatedWorksDiscovery: discovery({
          saberId: {fateWorkId},
        }),
      );

      expect(result, isEmpty);
    });

    test('kind and relatedWorkId both required', () async {
      const subaruId = 'pe_u_subaru01';
      const conceptId = 'co_u_world001';
      final catalog = [
        person(id: subaruId, title: '스바루'),
        UserCatalogEntity.userLocal(
          entityId: conceptId,
          type: EntityAnchorType.concept,
          title: 'Re:Zero World',
        ),
      ];
      final collection = CollectibleCollection(
        id: 'col_u_rezero03',
        title: 'Re:Zero Cast',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          relatedWorkId: rezeroWorkId,
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: catalog,
        relatedWorksDiscovery: discovery({
          subaruId: {rezeroWorkId},
          conceptId: {rezeroWorkId},
        }),
      );

      expect(result.map((e) => e.entityId), [subaruId]);
    });

    test('tagsAll and relatedWorkId both required', () async {
      const subaruId = 'pe_u_subaru01';
      const emiliaId = 'pe_u_emilia01';
      final catalog = [
        person(id: subaruId, title: '스바루', tags: const ['영웅']),
        person(id: emiliaId, title: '에밀리아', tags: const ['마왕']),
      ];
      final collection = CollectibleCollection(
        id: 'col_u_rezero04',
        title: 'Re:Zero Heroes',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          tagsAll: ['영웅'],
          relatedWorkId: rezeroWorkId,
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: catalog,
        relatedWorksDiscovery: discovery({
          subaruId: {rezeroWorkId},
          emiliaId: {rezeroWorkId},
        }),
      );

      expect(result.map((e) => e.entityId), [subaruId]);
    });

    test('multiple related works includes when filter matches any', () async {
      const heroId = 'pe_u_hero0001';
      final collection = CollectibleCollection(
        id: 'col_u_multi01',
        title: 'Work B Cast',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          relatedWorkId: 'wk_u_workb001',
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: [person(id: heroId, title: 'Hero')],
        relatedWorksDiscovery: discovery({
          heroId: {'wk_u_worka001', 'wk_u_workb001'},
        }),
      );

      expect(result.map((e) => e.entityId), [heroId]);
    });

    test('empty related works excludes entity', () async {
      const subaruId = 'pe_u_subaru01';
      final collection = CollectibleCollection(
        id: 'col_u_rezero05',
        title: 'Re:Zero Cast',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          relatedWorkId: rezeroWorkId,
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: [person(id: subaruId, title: '스바루')],
        relatedWorksDiscovery: discovery({
          subaruId: const {},
        }),
      );

      expect(result, isEmpty);
    });

    test('relatedWorkId cast works without tagsAll axis', () async {
      const subaruId = 'pe_u_subaru01';
      const emiliaId = 'pe_u_emilia01';
      final catalog = [
        person(id: subaruId, title: '스바루'),
        person(id: emiliaId, title: '에밀리아', tags: const ['Re:Zero']),
      ];
      final collection = CollectibleCollection(
        id: 'col_u_rezero06',
        title: 'Re:Zero Cast',
        mode: CollectibleCollectionMode.filter,
        filter: const CollectibleCollectionFilter(
          kinds: [CollectibleKind.person],
          relatedWorkId: rezeroWorkId,
        ),
      );

      final result = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: catalog,
        relatedWorksDiscovery: discovery({
          subaruId: {rezeroWorkId},
          emiliaId: {rezeroWorkId},
        }),
      );

      expect(result.map((e) => e.entityId), [subaruId, emiliaId]);
    });
  });

  group('CollectibleRef work kind', () {
    test('json round-trip includes work kind', () {
      const ref = CollectibleRef(kind: CollectibleKind.work, id: 'wk_u_rezero01');
      final parsed = CollectibleRef.fromJson(ref.toJson());
      expect(parsed.kind, CollectibleKind.work);
      expect(parsed.id, 'wk_u_rezero01');
    });
  });

  group('CollectibleCollectionPipeline mixed curated', () {
    test('resolveMembers preserves work and entity order', () async {
      const workId = 'wk_u_rezero01';
      const subaruId = 'pe_u_subaru01';
      final collection = CollectibleCollection(
        id: 'col_u_mixed01',
        title: 'Re:Zero Shelf',
        mode: CollectibleCollectionMode.curated,
        memberOrder: const [
          CollectibleRef(kind: CollectibleKind.work, id: workId),
          CollectibleRef(kind: CollectibleKind.person, id: subaruId),
        ],
      );
      final vaultItems = [
        ContentItem(
          workId: workId,
          title: 'Re:Zero',
          category: MediaCategory.book,
          domain: AppDomain.subculture,
        ),
      ];
      final members = await CollectibleCollectionPipeline.resolveMembers(
        collection: collection,
        catalog: [
          UserCatalogEntity.userLocal(
            entityId: subaruId,
            type: EntityAnchorType.person,
            title: '스바루',
          ),
        ],
        vaultItems: vaultItems,
      );

      expect(members.length, 2);
      expect(members[0], isA<WorkCollectibleMember>());
      expect((members[0] as WorkCollectibleMember).item.workId, workId);
      expect(members[1], isA<EntityCollectibleMember>());
      expect((members[1] as EntityCollectibleMember).entity.entityId, subaruId);
    });

    test('resolve skips work member when vault item missing', () async {
      const workId = 'wk_u_missing1';
      const subaruId = 'pe_u_subaru01';
      final collection = CollectibleCollection(
        id: 'col_u_mixed02',
        title: 'Shelf',
        mode: CollectibleCollectionMode.curated,
        memberOrder: const [
          CollectibleRef(kind: CollectibleKind.work, id: workId),
          CollectibleRef(kind: CollectibleKind.person, id: subaruId),
        ],
      );
      final members = await CollectibleCollectionPipeline.resolveMembers(
        collection: collection,
        catalog: [
          UserCatalogEntity.userLocal(
            entityId: subaruId,
            type: EntityAnchorType.person,
            title: '스바루',
          ),
        ],
        vaultItems: const [],
      );

      expect(members.length, 1);
      expect(members.single, isA<EntityCollectibleMember>());
    });

    test('resolve entity-only via resolve() ignores work without vault', () async {
      const workId = 'wk_u_rezero01';
      const subaruId = 'pe_u_subaru01';
      final collection = CollectibleCollection(
        id: 'col_u_mixed03',
        title: 'Shelf',
        mode: CollectibleCollectionMode.curated,
        memberOrder: const [
          CollectibleRef(kind: CollectibleKind.work, id: workId),
          CollectibleRef(kind: CollectibleKind.person, id: subaruId),
        ],
      );
      final resolved = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: [
          UserCatalogEntity.userLocal(
            entityId: subaruId,
            type: EntityAnchorType.person,
            title: '스바루',
          ),
        ],
      );
      expect(resolved.map((e) => e.entityId), [subaruId]);
    });
  });

  group('reorderRefsInMemberOrder', () {
    test('reorders mixed work and entity refs', () {
      const fullOrder = [
        CollectibleRef(kind: CollectibleKind.work, id: 'wk_u_rezero01'),
        CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_emilia01'),
        CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_subaru01'),
      ];
      const visible = [
        CollectibleRef(kind: CollectibleKind.work, id: 'wk_u_rezero01'),
        CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_subaru01'),
      ];
      final reordered = reorderRefsInMemberOrder(
        fullOrder: fullOrder,
        visibleRefs: visible,
        oldIndex: 0,
        newIndex: 1,
      );
      expect(
        reordered.map(collectibleRefKey),
        [
          'person:pe_u_subaru01',
          'person:pe_u_emilia01',
          'work:wk_u_rezero01',
        ],
      );
    });
  });

  group('reorderEntityIdsInMemberOrder', () {
    test('preserves missing members while reordering visible cards', () {
      const fullOrder = [
        'pe_u_emilia01',
        'pe_u_missing01',
        'pe_u_subaru01',
        'pe_u_rem01',
      ];
      const visible = ['pe_u_emilia01', 'pe_u_subaru01'];
      final reordered = reorderEntityIdsInMemberOrder(
        fullOrder: fullOrder,
        visibleEntityIds: visible,
        oldIndex: 0,
        newIndex: 1,
      );
      expect(reordered, [
        'pe_u_subaru01',
        'pe_u_missing01',
        'pe_u_emilia01',
        'pe_u_rem01',
      ]);
    });
  });

  group('applyEntityReorderToCollection', () {
    EntityBrowseCard card(String id, String title) {
      return EntityBrowseCard(
        entity: UserCatalogEntity.userLocal(
          entityId: id,
          type: EntityAnchorType.person,
          title: title,
        ),
        isArchived: false,
      );
    }

    test('reorders memberOrder using visible card indices only', () {
      final collection = CollectibleCollection(
        id: 'col_u_reorder1',
        title: '최애',
        mode: CollectibleCollectionMode.curated,
        memberOrder: const [
          CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_a'),
          CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_missing'),
          CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_b'),
        ],
      );
      applyEntityReorderToCollection(
        collection: collection,
        visibleCards: [card('pe_u_a', 'A'), card('pe_u_b', 'B')],
        oldIndex: 0,
        newIndex: 1,
      );
      expect(
        collection.memberOrder.map((r) => r.id),
        ['pe_u_b', 'pe_u_missing', 'pe_u_a'],
      );
    });
  });

  group('CollectibleCollectionStorageService', () {
    test('curated memberOrder survives save and reload', () async {
      final fileService = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_col_');
      try {
        await fileService.setVaultPath(tempDir.path);
        final storage = CollectibleCollectionStorageService();
        final original = [
          CollectibleCollection(
            id: 'col_u_persist1',
            title: '최애',
            mode: CollectibleCollectionMode.curated,
            memberOrder: const [
              CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_emilia01'),
              CollectibleRef(kind: CollectibleKind.person, id: 'pe_u_subaru01'),
            ],
          ),
        ];
        await storage.save(original);

        applyEntityReorderToCollection(
          collection: original.first,
          visibleCards: [
            EntityBrowseCard(
              entity: UserCatalogEntity.userLocal(
                entityId: 'pe_u_emilia01',
                type: EntityAnchorType.person,
                title: '에밀리아',
              ),
              isArchived: false,
            ),
            EntityBrowseCard(
              entity: UserCatalogEntity.userLocal(
                entityId: 'pe_u_subaru01',
                type: EntityAnchorType.person,
                title: '스바루',
              ),
              isArchived: false,
            ),
          ],
          oldIndex: 0,
          newIndex: 2,
        );
        await storage.save(original);

        final reloaded = await storage.load();
        expect(reloaded, hasLength(1));
        expect(
          reloaded.first.memberOrder.map((r) => r.id),
          ['pe_u_subaru01', 'pe_u_emilia01'],
        );

        final resolved = await CollectibleCollectionPipeline.resolve(
          collection: reloaded.first,
          catalog: [
            UserCatalogEntity.userLocal(
              entityId: 'pe_u_emilia01',
              type: EntityAnchorType.person,
              title: '에밀리아',
            ),
            UserCatalogEntity.userLocal(
              entityId: 'pe_u_subaru01',
              type: EntityAnchorType.person,
              title: '스바루',
            ),
          ],
        );
        expect(resolved.map((e) => e.title), ['스바루', '에밀리아']);
      } finally {
        await fileService.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Re:Zero Cast relatedWorkId-only survives save and reload', () async {
      final fileService = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_col_cast_');
      try {
        await fileService.setVaultPath(tempDir.path);
        final storage = CollectibleCollectionStorageService();
        const rezeroWorkId = 'wk_u_rezero01';
        final original = [
          CollectibleCollection(
            id: 'col_u_rezero_cast',
            title: 'Re:Zero Cast',
            mode: CollectibleCollectionMode.filter,
            filter: const CollectibleCollectionFilter(
              kinds: [CollectibleKind.person],
              relatedWorkId: rezeroWorkId,
            ),
          ),
        ];
        await storage.save(original);

        final reloaded = await storage.load();
        expect(reloaded, hasLength(1));
        expect(reloaded.first.filter?.relatedWorkId, rezeroWorkId);
        expect(reloaded.first.filter?.tagsAll, isNull);
        expect(reloaded.first.filter?.kinds?.map((k) => k.name), ['person']);

        const subaruId = 'pe_u_subaru01';
        const saberId = 'pe_u_saber001';
        final resolved = await CollectibleCollectionPipeline.resolve(
          collection: reloaded.first,
          catalog: [
            UserCatalogEntity.userLocal(
              entityId: subaruId,
              type: EntityAnchorType.person,
              title: '스바루',
            ),
            UserCatalogEntity.userLocal(
              entityId: saberId,
              type: EntityAnchorType.person,
              title: 'Saber',
            ),
          ],
          relatedWorksDiscovery: _FakeEntityRelatedWorksDiscovery({
            subaruId: {rezeroWorkId},
            saberId: {'wk_u_fate0001'},
          }),
        );
        expect(resolved.map((e) => e.entityId), [subaruId]);
      } finally {
        await fileService.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
