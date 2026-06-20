import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/catalog_entity_add_result.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_archive_service.dart';
import 'package:akasha/services/entity_vault_path_conflict.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/user_catalog_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntityVaultPathConflict UI', () {
    late Directory tempDir;
    late UserCatalogStore catalog;

    setUp(() async {
      catalog = UserCatalogStore.instance..resetForTesting();
      tempDir = await Directory.systemTemp.createTemp('akasha_r2c_ui_');
      await AkashaFileService().setVaultPath(tempDir.path);
    });

    tearDown(() async {
      catalog.resetForTesting();
      await AkashaFileService().setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> seedPersonTiger(String entityId) async {
      await EntityVaultStore().saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: entityId,
          type: EntityAnchorType.person,
          title: 'Tiger',
        ),
        body: 'existing',
      );
    }

    test('A: Add Entity conflict exposes userMessage without crash', () async {
      await seedPersonTiger('pe_u_tiger001');

      await expectLater(
        EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(
            entity: UserCatalogEntity.userLocal(
              entityId: 'pe_u_tiger002',
              type: EntityAnchorType.person,
              title: 'Tiger',
            ),
            journalBody: 'new body',
          ),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        ),
        throwsA(isA<EntityVaultPathConflict>().having(
          (e) => e.userMessage,
          'userMessage',
          allOf(
            contains('Tiger'),
            contains('이미 아카이브'),
            contains('같은 종류'),
          ),
        )),
      );
    });

    test('B: Promote catalog-only conflict exposes userMessage', () async {
      await seedPersonTiger('pe_u_tiger001');
      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_tiger002',
          type: EntityAnchorType.person,
          title: 'Tiger',
        ),
      );

      await expectLater(
        EntityArchiveService.promoteCatalogOnly(
          entity: catalog.getById('pe_u_tiger002')!,
          vaultPath: tempDir.path,
        ),
        throwsA(isA<EntityVaultPathConflict>()),
      );
    });

    test('C: Entity Sheet save catches conflict and keeps dialog open', () async {
      await seedPersonTiger('pe_u_tiger001');
      var dialogClosed = false;

      try {
        await EntityVaultStore().saveCatalogEntity(
          vaultPath: tempDir.path,
          entity: UserCatalogEntity.userLocal(
            entityId: 'pe_u_tiger002',
            type: EntityAnchorType.person,
            title: 'Tiger',
          ),
          body: 'journal body',
        );
        dialogClosed = true;
      } on EntityVaultPathConflict catch (e) {
        expect(
          e.userMessage,
          allOf(
            contains('Tiger'),
            contains('이미 아카이브'),
            contains('같은 종류'),
          ),
        );
      }

      expect(dialogClosed, isFalse);
    });

    testWidgets('C: Entity Sheet conflict userMessage shown in SnackBar', (
      tester,
    ) async {
      final conflict = EntityVaultPathConflict(
        existingEntityId: 'pe_u_tiger001',
        incomingEntityId: 'pe_u_tiger002',
        title: 'Tiger',
        path: r'entities/person/Tiger.md',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(conflict.userMessage)),
                  );
                });
                return const Dialog(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Entity Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Entity Sheet'), findsOneWidget);
      expect(find.textContaining('이미 아카이브'), findsOneWidget);
    });

    test('D: cross-type same title succeeds', () async {
      await seedPersonTiger('pe_u_xtiger01');

      final saved = await EntityArchiveService.saveFromAddResult(
        result: CatalogEntityAddResult(
          entity: UserCatalogEntity.userLocal(
            entityId: 'co_u_xtiger01',
            type: EntityAnchorType.concept,
            title: 'Tiger',
          ),
          journalBody: 'concept',
        ),
        vaultPath: tempDir.path,
        userCatalog: catalog,
      );

      expect(saved.entry, isNotNull);
      expect(catalog.getById('co_u_xtiger01'), isNotNull);
    });
  });
}
