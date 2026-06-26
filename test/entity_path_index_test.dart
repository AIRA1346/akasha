import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_path_index_service.dart';
import 'package:akasha/services/entity_vault_loader.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/vault_readme_writer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VaultReadmeWriter', () {
    test('writes VAULT_README.md on vault connect', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_readme_');
      try {
        await AkashaFileService().setVaultPath(tempDir.path);
        final readme = File(p.join(tempDir.path, VaultReadmeWriter.readmeFileName));
        expect(await readme.exists(), isTrue);
        final text = await readme.readAsString();
        expect(text, contains('entity_path_index.json'));
        expect(text, contains('record_kind: entityJournal'));
      } finally {
        await AkashaFileService().setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('EntityPathIndexService', () {
    late Directory tempDir;
    late EntityPathIndexService index;
    late EntityVaultStore store;

    setUp(() async {
      index = EntityPathIndexService();
      store = EntityVaultStore(pathIndex: index);
      tempDir = await Directory.systemTemp.createTemp('akasha_idx_');
      await AkashaFileService().setVaultPath(tempDir.path);
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('upsert and lookup relative path', () async {
      const entityId = 'pe_u_idx0001';
      final path = p.join(tempDir.path, 'entities', 'person', 'Index.md');

      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: path,
      );

      expect(
        await index.lookupRelativePath(tempDir.path, entityId),
        'entities${Platform.pathSeparator}person${Platform.pathSeparator}Index.md',
      );
    });

    test('findByEntityId uses index without full scan', () async {
      const entityId = 'co_u_idx0002';
      await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.concept,
          title: 'Indexed',
        ),
        body: 'body',
      );

      final indexFile = File(
        p.join(tempDir.path, '.akasha', EntityPathIndexService.indexFileName),
      );
      expect(await indexFile.exists(), isTrue);

      final loader = EntityVaultLoader(pathIndex: index);
      final found = await loader.findByEntityId(tempDir.path, entityId);
      expect(found?.body, 'body');
    });

    test('rebuildFromVault scans entities tree', () async {
      await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_rebuild1',
          type: EntityAnchorType.person,
          title: 'Rebuild',
        ),
        body: 'scan',
      );

      final indexFile = File(
        p.join(tempDir.path, '.akasha', EntityPathIndexService.indexFileName),
      );
      if (await indexFile.exists()) {
        await indexFile.delete();
      }

      await index.rebuildFromVault(tempDir.path);
      expect(
        await index.lookupRelativePath(tempDir.path, 'pe_u_rebuild1'),
        isNotNull,
      );
    });
  });

  group('EntityVaultStore title rename', () {
    test('renames file when title changes', () async {
      final store = EntityVaultStore();
      final tempDir = await Directory.systemTemp.createTemp('akasha_rename_');
      try {
        await AkashaFileService().setVaultPath(tempDir.path);
        const entityId = 'pe_u_rename01';

        final saved = await store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: entityId,
            type: EntityAnchorType.person,
            title: 'Old Name',
          ),
          body: 'v1',
        );

        final renamed = await store.updateEntry(
          entry: saved,
          body: 'v2',
          title: 'New Name',
          vaultPath: tempDir.path,
        );

        expect(renamed.storagePath, contains('New Name.md'));
        expect(File(saved.storagePath).existsSync(), isFalse);
        expect(File(renamed.storagePath).existsSync(), isTrue);
        expect(renamed.title, 'New Name');

        final loader = EntityVaultLoader();
        final found = await loader.findByEntityId(tempDir.path, entityId);
        expect(found?.title, 'New Name');
        expect(found?.body, 'v2');
      } finally {
        await AkashaFileService().setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
