import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_vault_path_conflict.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntityVaultStore path guard (R2-C)', () {
    late EntityVaultStore store;
    late Directory tempDir;

    setUp(() async {
      store = EntityVaultStore();
      tempDir = await Directory.systemTemp.createTemp('akasha_r2c_guard_');
      await AkashaFileService().setVaultPath(tempDir.path);
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('A: same type+title different entityId throws EntityVaultPathConflict', () async {
      const title = 'Tiger';
      const idA = 'pe_u_tiger001';
      const idB = 'pe_u_tiger002';

      await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: idA,
          type: EntityAnchorType.person,
          title: title,
        ),
        body: 'first',
      );

      expect(
        store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: idB,
            type: EntityAnchorType.person,
            title: title,
          ),
          body: 'second',
        ),
        throwsA(isA<EntityVaultPathConflict>().having(
          (e) => e.existingEntityId,
          'existingEntityId',
          idA,
        ).having(
          (e) => e.incomingEntityId,
          'incomingEntityId',
          idB,
        )),
      );

      final content = await File(
        p.join(tempDir.path, 'entities', 'person', 'Tiger.md'),
      ).readAsString();
      expect(content, contains(idA));
      expect(content, isNot(contains(idB)));
    });

    test('B: safeTitle collision from different titles throws', () async {
      const idA = 'pe_u_slash001';
      const idB = 'pe_u_slash002';

      await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: idA,
          type: EntityAnchorType.person,
          title: 'A/B',
        ),
        body: 'slash',
      );

      expect(
        store.saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: idB,
            type: EntityAnchorType.person,
            title: 'A_B',
          ),
          body: 'underscore',
        ),
        throwsA(isA<EntityVaultPathConflict>()),
      );
    });

    test('C: same entityId re-save preserves addedAt and succeeds', () async {
      const id = 'pe_u_resave01';
      final addedAt = DateTime.utc(2026, 1, 15, 10);

      final first = await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: id,
          type: EntityAnchorType.person,
          title: 'Resave',
          addedAt: addedAt,
        ),
        body: 'v1',
      );

      final second = await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: id,
          type: EntityAnchorType.person,
          title: 'Resave',
          addedAt: DateTime.utc(2026, 6, 20),
        ),
        body: 'v2',
      );

      expect(second.addedAt, first.addedAt);
      expect(second.addedAt, addedAt);
      expect(second.body, 'v2');
    });

    test('D: cross-type same title both succeed', () async {
      const title = 'Tiger';

      final person = await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_xtiger01',
          type: EntityAnchorType.person,
          title: title,
        ),
        body: 'person',
      );

      final concept = await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'co_u_xtiger01',
          type: EntityAnchorType.concept,
          title: title,
        ),
        body: 'concept',
      );

      expect(person.storagePath, contains('entities${Platform.pathSeparator}person'));
      expect(concept.storagePath, contains('entities${Platform.pathSeparator}concept'));
      expect(File(person.storagePath).existsSync(), isTrue);
      expect(File(concept.storagePath).existsSync(), isTrue);
    });
  });
}
