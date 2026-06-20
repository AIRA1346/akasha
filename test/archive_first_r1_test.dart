import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/models/catalog_entity_add_result.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_archive_service.dart';
import 'package:akasha/services/entity_catalog_sync.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/entity_vault_loader.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/fusion_search_service.dart';
import 'package:akasha/services/user_catalog_store.dart';
import 'fakes/fake_registry_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntityArchiveService R1', () {
    test('Person add creates journal before catalog mirror', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r1_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      try {
        await service.setVaultPath(tempDir.path);

        final draft = UserCatalogEntity.userLocal(
          entityId: 'pe_u_r1test01',
          type: EntityAnchorType.person,
          title: '나츠키 스바루',
          aliases: ['스바루'],
          tags: const ['영웅', '구원'],
        );
        final result = CatalogEntityAddResult(
          entity: draft,
          journalBody: '메모',
        );

        expect(result.createsJournal, isTrue);

        final saved = await EntityArchiveService.saveFromAddResult(
          result: result,
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        expect(saved.entry, isNotNull);
        expect(
          File(saved.entry!.storagePath).existsSync(),
          isTrue,
        );
        expect(
          p.normalize(saved.entry!.storagePath),
          contains(p.join('entities', 'person')),
        );

        await catalog.load();
        final stored = catalog.getById('pe_u_r1test01');
        expect(stored, isNotNull);
        expect(stored!.title, '나츠키 스바루');
        expect(stored.tags, ['영웅', '구원']);

        final md = await File(saved.entry!.storagePath).readAsString();
        expect(md, contains('tags: ["영웅", "구원"]'));
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('nameOnly skips journal', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r1_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      try {
        await service.setVaultPath(tempDir.path);

        final draft = UserCatalogEntity.userLocal(
          entityId: 'co_u_nameonly',
          type: EntityAnchorType.concept,
          title: 'Tiger',
        );
        final saved = await EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(entity: draft, nameOnly: true),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        expect(saved.entry, isNull);
        const loader = EntityVaultLoader();
        expect(await loader.findByEntityId(tempDir.path, 'co_u_nameonly'), isNull);
        expect(catalog.getById('co_u_nameonly')?.title, 'Tiger');
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('EntityCatalogSync', () {
    test('mirror uses journal title as SSOT', () {
      final draft = UserCatalogEntity.userLocal(
        entityId: 'pe_u_sync01',
        type: EntityAnchorType.person,
        title: 'Draft Title',
      );
      final mirrored = EntityCatalogSync.mirrorFromJournal(
        draft: draft,
        entry: EntityJournalEntry(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_sync01',
          title: 'Journal Title',
          body: '',
          addedAt: DateTime.utc(2026, 6, 19),
          storagePath: '/vault/entities/person/Journal Title.md',
        ),
      );
      expect(mirrored.title, 'Journal Title');
      expect(mirrored.tags, isEmpty);
    });

    test('mirror copies journal semantic tags', () {
      final draft = UserCatalogEntity.userLocal(
        entityId: 'pe_u_sync02',
        type: EntityAnchorType.person,
        title: 'Draft',
        tags: const ['구원'],
      );
      final mirrored = EntityCatalogSync.mirrorFromJournal(
        draft: draft,
        entry: EntityJournalEntry(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_sync02',
          title: 'Journal Title',
          body: '',
          addedAt: DateTime.utc(2026, 6, 19),
          storagePath: '/vault/entities/person/Journal Title.md',
          tags: const ['영웅', '성장'],
        ),
      );
      expect(mirrored.tags, ['영웅', '성장']);
    });
  });

  group('EntityArchiveService R1.1 — sheet save catalog sync', () {
    test('Person create then title update keeps .md and catalog aligned', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r11_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      final store = EntityVaultStore();
      try {
        await service.setVaultPath(tempDir.path);

        const entityId = 'pe_u_r11title';
        final saved = await EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(
            entity: UserCatalogEntity.userLocal(
              entityId: entityId,
              type: EntityAnchorType.person,
              title: '나츠키 스바루',
            ),
            journalBody: 'v1',
          ),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        expect(catalog.getById(entityId)?.title, '나츠키 스바루');

        final updated = await store.updateEntry(
          entry: saved.entry!,
          body: 'v2',
          title: '나츠키 스바루 (改)',
        );
        await EntityArchiveService.syncCatalogFromJournal(
          draft: saved.entity,
          entry: updated,
          userCatalog: catalog,
        );

        const newTitle = '나츠키 스바루 (改)';
        final mdContent =
            await File(updated.storagePath).readAsString();
        final parsed = EntityJournalParser.parse(
          mdContent,
          updated.storagePath,
        );

        expect(parsed?.title, newTitle);
        expect(catalog.getById(entityId)?.title, newTitle);
        expect(parsed?.title, catalog.getById(entityId)?.title);
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('EntityArchiveService R1.1 — delete catalog sync', () {
    test('Person delete removes .md then catalog entry', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r11_del_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      const loader = EntityVaultLoader();
      try {
        await service.setVaultPath(tempDir.path);

        const entityId = 'pe_u_r11delete';
        final saved = await EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(
            entity: UserCatalogEntity.userLocal(
              entityId: entityId,
              type: EntityAnchorType.person,
              title: '나츠키 스바루',
            ),
            journalBody: '메모',
          ),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        final storagePath = saved.entry!.storagePath;
        expect(File(storagePath).existsSync(), isTrue);
        expect(catalog.getById(entityId), isNotNull);

        final deleted = await EntityArchiveService.deleteArchivedEntity(
          entry: saved.entry!,
          userCatalog: catalog,
        );

        expect(deleted, isTrue);
        expect(File(storagePath).existsSync(), isFalse);
        expect(await loader.findByEntityId(tempDir.path, entityId), isNull);
        expect(catalog.getById(entityId), isNull);
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('catalog remove skipped when .md delete fails', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r11_delfail_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      try {
        await service.setVaultPath(tempDir.path);

        const entityId = 'pe_u_r11delfail';
        final saved = await EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(
            entity: UserCatalogEntity.userLocal(
              entityId: entityId,
              type: EntityAnchorType.person,
              title: 'Ghost Test',
            ),
            journalBody: '메모',
          ),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        await File(saved.entry!.storagePath).delete();

        final deleted = await EntityArchiveService.deleteArchivedEntity(
          entry: saved.entry!,
          userCatalog: catalog,
        );

        expect(deleted, isFalse);
        expect(catalog.getById(entityId), isNotNull);
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('FusionSearchService local entity tier', () {
    test('archived person in localEntityJournals not catalogEntityOnly', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r1_fusion_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      try {
        await service.setVaultPath(tempDir.path);

        await EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(
            entity: UserCatalogEntity.userLocal(
              entityId: 'pe_u_fusion01',
              type: EntityAnchorType.person,
              title: '나츠키 스바루',
            ),
          ),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        final result = await FusionSearchService.search(
          query: '나츠키',
          localItems: const [],
          userCatalog: catalog,
          registry: FakeRegistryPort(),
        );

        expect(result.localEntityJournals.length, 1);
        expect(result.localEntityJournals.first.title, '나츠키 스바루');
        expect(
          result.registryHits.where((h) => h.catalogOnly).length,
          0,
        );
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('catalog-only person flagged catalogOnly', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r1_fusion_');
      final catalog = UserCatalogStore.instance..resetForTesting();
      try {
        await service.setVaultPath(tempDir.path);
        await catalog.upsert(
          UserCatalogEntity.userLocal(
            entityId: 'pe_u_orphan01',
            type: EntityAnchorType.person,
            title: 'Orphan Person',
          ),
        );

        final result = await FusionSearchService.search(
          query: 'Orphan',
          localItems: const [],
          userCatalog: catalog,
          registry: FakeRegistryPort(),
        );

        expect(result.localEntityJournals, isEmpty);
        expect(result.registryHits.length, 1);
        expect(result.registryHits.first.catalogOnly, isTrue);
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
