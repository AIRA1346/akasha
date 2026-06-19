import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/entity_fact.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_journal_parser.dart';
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
---
호랑이에 대한 메모
''';

      final parsed = EntityJournalParser.parse(content, r'C:\vault\entities\concept\Tiger.md');
      expect(parsed, isNotNull);
      expect(parsed!.entityType, EntityAnchorType.concept);
      expect(parsed.entityId, 'co_u_abcd1234');
      expect(parsed.title, 'Tiger');
      expect(parsed.body, '호랑이에 대한 메모');

      final reserialized = EntityJournalParser.serialize(
        entityType: parsed.entityType,
        entityId: parsed.entityId,
        title: parsed.title,
        body: parsed.body,
        addedAt: parsed.addedAt,
      );
      expect(reserialized, contains('record_kind: entityJournal'));
    });
  });

  group('EntityVaultStore', () {
    test('saves person journal under entities/person/', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_w4_entity_');
      try {
        await service.setVaultPath(tempDir.path);
        const store = EntityVaultStore();

        final entity = UserCatalogEntity.userLocal(
          entityId: 'pe_u_test1234',
          type: EntityAnchorType.person,
          title: '나비',
        );

        final saved = await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: entity,
          body: '우리 고양이',
        );

        expect(saved.storagePath, contains('entities'));
        expect(saved.storagePath, contains('person'));
        expect(File(saved.storagePath).existsSync(), isTrue);

        final content = await File(saved.storagePath).readAsString();
        final parsed = EntityJournalParser.parse(content, saved.storagePath);
        expect(parsed?.entityId, 'pe_u_test1234');
        expect(parsed?.body, '우리 고양이');
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
