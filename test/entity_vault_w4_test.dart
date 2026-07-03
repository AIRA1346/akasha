import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/entity_fact.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/entity_vault_loader.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/fusion_search_service.dart';
import 'package:akasha/services/person_seed_registry.dart';
import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntityJournalParser', () {
    test('serialize and parse entityJournal', () {
      const content = '''---
entity_type: concept
entity_id: "co_u_abcd1234"
record_kind: entityJournal
title: "Tiger"
added_at: "2026-06-19T10:00:00.000"
aliases: ["Tiger King", "Tora"]
---
호랑이에 대한 메모
''';

      final parsed = EntityJournalParser.parse(
        content,
        r'C:\vault\entities\concept\Tiger.md',
      );
      expect(parsed, isNotNull);
      expect(parsed!.entityType, EntityAnchorType.concept);
      expect(parsed.entityId, 'co_u_abcd1234');
      expect(parsed.title, 'Tiger');
      expect(parsed.aliases, ['Tiger King', 'Tora']);
      expect(parsed.body, '호랑이에 대한 메모');

      final reserialized = EntityJournalParser.serialize(
        entityType: parsed.entityType,
        entityId: parsed.entityId,
        title: parsed.title,
        body: parsed.body,
        addedAt: parsed.addedAt,
        aliases: parsed.aliases,
        tags: parsed.tags,
      );
      expect(reserialized, contains('schema_version: 3'));
      expect(reserialized, contains('record_id: "rec_co_u_abcd1234"'));
      expect(reserialized, contains('record_kind: entityJournal'));
      expect(reserialized, contains('aliases: ["Tiger King", "Tora"]'));
    });
  });

  group('EntityVaultStore', () {
    test('saves person journal under entities/person/', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_w4_entity_',
      );
      try {
        await service.setVaultPath(tempDir.path);
        final store = EntityVaultStore();

        final entity = UserCatalogEntity.userLocal(
          entityId: 'pe_u_test1234',
          type: EntityAnchorType.person,
          aliases: const ['Hero Alias'],
          title: '나비',
        );

        final saved = await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: entity,
          body: '우리 고양이',
        );

        expect(saved.storagePath, contains('entities'));
        expect(saved.storagePath, contains('person'));
        expect(saved.storagePath, endsWith('pe_u_test1234.md'));
        expect(File(saved.storagePath).existsSync(), isTrue);

        final content = await File(saved.storagePath).readAsString();
        final parsed = EntityJournalParser.parse(content, saved.storagePath);
        expect(parsed?.entityId, 'pe_u_test1234');
        expect(parsed?.aliases, ['Hero Alias']);
        expect(parsed?.body, '우리 고양이');
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('reuses existing legacy path when entity id already exists', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_w4_entity_',
      );
      try {
        await service.setVaultPath(tempDir.path);
        final store = EntityVaultStore();
        final legacyFile = File(
          '${tempDir.path}/entities/person/Legacy Hero.md',
        );
        await legacyFile.parent.create(recursive: true);
        await legacyFile.writeAsString(
          EntityJournalParser.serialize(
            entityType: EntityAnchorType.person,
            entityId: 'pe_u_legacy01',
            title: 'Legacy Hero',
            body: 'legacy body',
            addedAt: DateTime.utc(2026, 7, 3),
          ),
        );

        final saved = await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: 'pe_u_legacy01',
            type: EntityAnchorType.person,
            title: 'Renamed Hero',
            aliases: const ['Hero Alias'],
          ),
          body: 'updated body',
        );

        expect(p.normalize(saved.storagePath), p.normalize(legacyFile.path));
        expect(await legacyFile.exists(), isTrue);
        expect(
          await File(
            '${tempDir.path}/entities/person/pe_u_legacy01.md',
          ).exists(),
          isFalse,
        );
        final parsed = EntityJournalParser.parse(
          await legacyFile.readAsString(),
          legacyFile.path,
        );
        expect(parsed?.entityId, 'pe_u_legacy01');
        expect(parsed?.title, 'Renamed Hero');
        expect(parsed?.aliases, ['Hero Alias']);
        expect(parsed?.body, 'updated body');
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('update and delete entity journal round-trip', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_w4_entity_',
      );
      try {
        await service.setVaultPath(tempDir.path);
        final store = EntityVaultStore();
        const loader = EntityVaultLoader();

        final entity = UserCatalogEntity.userLocal(
          entityId: 'co_u_round01',
          type: EntityAnchorType.concept,
          title: 'Tiger',
        );

        final saved = await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: entity,
          body: 'v1',
        );

        final updated = await store.updateEntry(
          entry: saved,
          body: 'v2',
          title: entity.title,
        );
        expect(updated.body, 'v2');

        final found = await loader.findByEntityId(tempDir.path, 'co_u_round01');
        expect(found?.body, 'v2');

        await store.deleteEntry(saved.storagePath);
        expect(
          await loader.findByEntityId(tempDir.path, 'co_u_round01'),
          isNull,
        );
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('EntityVaultLoader', () {
    test('loads all entity journals sorted newest first', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_w4_loader_',
      );
      try {
        await service.setVaultPath(tempDir.path);
        final store = EntityVaultStore();
        const loader = EntityVaultLoader();

        await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: 'pe_u_old0001',
            type: EntityAnchorType.person,
            title: 'Old',
            addedAt: DateTime.utc(2026, 1, 1),
          ),
          body: 'old',
        );
        await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: 'pe_u_new0001',
            type: EntityAnchorType.person,
            title: 'New',
            addedAt: DateTime.utc(2026, 6, 19),
          ),
          body: 'new',
        );

        final entries = await loader.loadFromVault(tempDir.path);
        expect(entries.length, 2);
        expect(entries.first.entityId, 'pe_u_new0001');
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('PersonSeedRegistry', () {
    test('loads bundled seed and searches Einstein', () async {
      final registry = PersonSeedRegistry.instance;
      registry.resetForTesting();
      await registry.init();

      final hits = registry.search('Einstein');
      expect(hits.any((e) => e.entityId == 'pe_000000001'), isTrue);

      final koHits = registry.search('아인슈타인');
      expect(koHits.any((e) => e.title.contains('Einstein')), isTrue);
    });
  });

  group('FusionSearchService person global', () {
    test('includes global person fact in registry hits', () async {
      final personRegistry = PersonSeedRegistry.instance;
      personRegistry.resetForTesting();
      personRegistry.seedForTesting(const [
        EntityFact(
          entityId: 'pe_000000099',
          entityType: EntityAnchorType.person,
          title: 'Test Person',
          aliases: ['테스트'],
        ),
      ]);

      final result = await FusionSearchService.search(
        query: 'Test Person',
        localItems: const [],
        userCatalog: FakeUserCatalogPort(),
        registry: FakeRegistryPort(),
        entityRegistry: personRegistry,
      );

      expect(result.registryHits.length, 1);
      expect(result.registryHits.first.entityType, EntityAnchorType.person);
      expect(result.registryHits.first.work.title, 'Test Person');
    });
  });
}
