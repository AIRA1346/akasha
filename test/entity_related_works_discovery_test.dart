import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/entity_vault_loader.dart';
import 'package:akasha/services/entity_related_works_discovery.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/user_catalog_store.dart';

/// R2-E Phase 4 Step 1 — EntityRelatedWorksDiscovery (incoming ∪ outgoing).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecordLinkEntityRelatedWorksDiscovery', () {
    late AkashaFileService fileService;
    late RecordLinkIndexService linkIndex;
    late UserCatalogStore catalog;
    late Directory tempDir;

    setUp(() async {
      fileService = AkashaFileService();
      linkIndex = RecordLinkIndexService(fileService: fileService);
      catalog = UserCatalogStore.instance..resetForTesting();
      tempDir = await Directory.systemTemp.createTemp('akasha_r2e_disc_');
      await fileService.setVaultPath(tempDir.path);
    });

    tearDown(() async {
      catalog.resetForTesting();
      await fileService.setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<RecordLinkEntityRelatedWorksDiscovery> discovery({
      required List<AkashaItem> vaultItems,
    }) async {
      return RecordLinkEntityRelatedWorksDiscovery(
        linkIndex: linkIndex,
        vaultItems: vaultItems,
        vaultPath: tempDir.path,
      );
    }

    Future<String> writeWork({
      required String workId,
      required String title,
      required String fileName,
      required String body,
    }) async {
      final worksDir = Directory(p.join(tempDir.path, 'works', 'book'));
      await worksDir.create(recursive: true);
      final workPath = p.join(worksDir.path, fileName);
      await File(workPath).writeAsString('''---
title: "$title"
work_id: "$workId"
---
$body
''');
      return p.normalize(workPath);
    }

    ContentItem workItem({
      required String workId,
      required String title,
      required String workPath,
    }) {
      return ContentItem(
        workId: workId,
        title: title,
        category: MediaCategory.book,
        domain: AppDomain.subculture,
      )..filePath = workPath;
    }

    Future<void> writeEntityJournal({
      required String entityId,
      required String title,
      required String body,
      EntityAnchorType type = EntityAnchorType.person,
    }) async {
      final entityDir = Directory(
        p.join(
          tempDir.path,
          EntityJournalParser.entitiesDirName,
          type.name,
        ),
      );
      await entityDir.create(recursive: true);
      await File(p.join(entityDir.path, '$title.md')).writeAsString('''---
entity_type: ${type.name}
entity_id: "$entityId"
record_kind: entityJournal
title: "$title"
added_at: "2026-06-19T10:00:00.000"
---
$body
''');
    }

    test('incoming only: entity → record → work (Subaru / Re:Zero)', () async {
      const entityId = 'pe_u_subaru01';
      const workId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );

      final workPath = await writeWork(
        workId: workId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '주인공 [[pe_u_subaru01|스바루]]',
      );
      final items = [
        workItem(workId: workId, title: 'Re:Zero', workPath: workPath),
      ];

      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final result = await (await discovery(vaultItems: items)).discover(entityId);

      expect(result.entityId, entityId);
      expect(result.workIds, {workId});
      expect(result.isRelatedTo(workId), isTrue);
    });

    test('outgoing only: entity journal → wk_* link', () async {
      const entityId = 'pe_u_emilia01';
      const workId = 'wk_u_rezero01';

      await writeEntityJournal(
        entityId: entityId,
        title: 'Emilia',
        body: '[[wk_u_rezero01|Re:Zero]]',
      );

      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: const []);

      final result = await (await discovery(vaultItems: const [])).discover(entityId);

      expect(result.workIds, {workId});
    });

    test('merge dedupes when incoming and outgoing resolve same work', () async {
      const entityId = 'pe_u_subaru01';
      const workId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );

      final workPath = await writeWork(
        workId: workId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_subaru01|스바루]]',
      );
      await writeEntityJournal(
        entityId: entityId,
        title: 'Subaru',
        body: '[[wk_u_rezero01|Re:Zero]]',
      );

      final items = [
        workItem(workId: workId, title: 'Re:Zero', workPath: workPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final result = await (await discovery(vaultItems: items)).discover(entityId);

      expect(result.workIds, {workId});
      expect(result.workIds.length, 1);
    });

    test('multiple works: entity linked from two records', () async {
      const entityId = 'pe_u_hero0001';
      const workA = 'wk_u_worka001';
      const workB = 'wk_u_workb001';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.person,
          title: 'Hero',
        ),
      );

      final pathA = await writeWork(
        workId: workA,
        title: 'Work A',
        fileName: 'Work_A.md',
        body: '[[pe_u_hero0001|Hero]]',
      );
      final pathB = await writeWork(
        workId: workB,
        title: 'Work B',
        fileName: 'Work_B.md',
        body: '[[pe_u_hero0001|Hero]]',
      );

      final items = [
        workItem(workId: workA, title: 'Work A', workPath: pathA),
        workItem(workId: workB, title: 'Work B', workPath: pathB),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final result = await (await discovery(vaultItems: items)).discover(entityId);

      expect(result.workIds, {workA, workB});
    });

    test('empty when no linked work exists', () async {
      const entityId = 'pe_u_orphan01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.person,
          title: 'Orphan',
        ),
      );
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: const []);

      final result =
          await (await discovery(vaultItems: const [])).discover(entityId);

      expect(result.workIds, isEmpty);
    });

    test('Saber resolves Fate work via incoming canonical path', () async {
      const entityId = 'pe_u_saber001';
      const workId = 'wk_u_fate0001';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.person,
          title: 'Saber',
        ),
      );

      final workPath = await writeWork(
        workId: workId,
        title: 'Fate/stay night',
        fileName: 'Fate_stay_night.md',
        body: '서번트 [[pe_u_saber001|Saber]]',
      );
      final items = [
        workItem(
          workId: workId,
          title: 'Fate/stay night',
          workPath: workPath,
        ),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final result = await (await discovery(vaultItems: items)).discover(entityId);

      expect(result.workIds, {workId});
    });

    test('discoverAll returns map keyed by entityId', () async {
      const subaruId = 'pe_u_subaru01';
      const saberId = 'pe_u_saber001';
      const rezeroId = 'wk_u_rezero01';
      const fateId = 'wk_u_fate0001';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: subaruId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );
      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: saberId,
          type: EntityAnchorType.person,
          title: 'Saber',
        ),
      );

      final rezeroPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_subaru01|스바루]]',
      );
      final fatePath = await writeWork(
        workId: fateId,
        title: 'Fate/stay night',
        fileName: 'Fate_stay_night.md',
        body: '[[pe_u_saber001|Saber]]',
      );

      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: rezeroPath),
        workItem(
          workId: fateId,
          title: 'Fate/stay night',
          workPath: fatePath,
        ),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final all = await (await discovery(vaultItems: items)).discoverAll([
        subaruId,
        saberId,
        subaruId,
      ]);

      expect(all.length, 2);
      expect(all[subaruId]!.workIds, {rezeroId});
      expect(all[saberId]!.workIds, {fateId});
    });

    test('discoverAll loads vault journals once for batch resolve', () async {
      const subaruId = 'pe_u_subaru01';
      const emiliaId = 'pe_u_emilia01';
      const saberId = 'pe_u_saber001';
      const rezeroId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: subaruId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );
      await writeEntityJournal(
        entityId: emiliaId,
        title: 'Emilia',
        body: '[[wk_u_rezero01|Re:Zero]]',
      );

      final rezeroPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_subaru01|스바루]]',
      );
      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: rezeroPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final countingLoader = _CountingEntityVaultLoader();
      final service = RecordLinkEntityRelatedWorksDiscovery(
        linkIndex: linkIndex,
        vaultItems: items,
        vaultLoader: countingLoader,
        vaultPath: tempDir.path,
      );

      final batch = await service.discoverAll([
        subaruId,
        emiliaId,
        saberId,
        subaruId,
      ]);

      expect(countingLoader.loadFromVaultCallCount, 1);
      expect(countingLoader.findByEntityIdCallCount, 0);
      expect(batch[subaruId]!.workIds, {rezeroId});
      expect(batch[emiliaId]!.workIds, {rezeroId});
      expect(batch[saberId]!.workIds, isEmpty);

      await service.discover(subaruId);
      expect(countingLoader.loadFromVaultCallCount, 2);
      expect(countingLoader.findByEntityIdCallCount, 1);
    });

    test('discoverAll caches incoming record counts for gallery reuse', () async {
      const subaruId = 'pe_u_subaru01';
      const rezeroId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: subaruId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );

      final rezeroPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_subaru01|스바루]]',
      );
      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: rezeroPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final service = await discovery(vaultItems: items);
      await service.discoverAll([subaruId]);

      expect(service.cachedIncomingRecordCount(subaruId), 1);
      expect(service.cachedJournalsByEntityId, isNotNull);
    });

    test('entityIdsForWork returns incoming and outgoing linked entities',
        () async {
      const subaruId = 'pe_u_subaru01';
      const emiliaId = 'pe_u_emilia01';
      const rezeroId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: subaruId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );
      await writeEntityJournal(
        entityId: emiliaId,
        title: 'Emilia',
        body: '[[wk_u_rezero01|Re:Zero]]',
      );

      final rezeroPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_subaru01|스바루]]',
      );
      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: rezeroPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final service = await discovery(vaultItems: items);
      final linked = await service.entityIdsForWork(rezeroId);

      expect(linked, {subaruId, emiliaId});
    });
  });
}

class _CountingEntityVaultLoader extends EntityVaultLoader {
  int loadFromVaultCallCount = 0;
  int findByEntityIdCallCount = 0;

  @override
  Future<List<EntityJournalEntry>> loadFromVault(String? vaultPath) async {
    loadFromVaultCallCount++;
    return super.loadFromVault(vaultPath);
  }

  @override
  Future<EntityJournalEntry?> findByEntityId(
    String? vaultPath,
    String entityId,
  ) async {
    findByEntityIdCallCount++;
    return super.findByEntityId(vaultPath, entityId);
  }
}
