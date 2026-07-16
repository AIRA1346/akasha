import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/derived_index_atomic_write.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/entity_path_index_service.dart';
import 'package:akasha/services/entity_vault_loader.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/vault_readme_writer.dart';
import 'package:akasha/services/vault_spec_writer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {});

  group('VaultReadmeWriter & VaultSpecWriter', () {
    test('writes VAULT_README.md on vault connect', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_readme_');
      try {
        await AkashaFileService().setVaultPath(tempDir.path);
        final readme = File(
          p.join(tempDir.path, VaultReadmeWriter.readmeFileName),
        );
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

    test('writes spec_v3.md on vault connect', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_spec_');
      try {
        await AkashaFileService().setVaultPath(tempDir.path);
        final specFile = File(
          p.join(tempDir.path, '.akasha', 'spec', VaultSpecWriter.specFileName),
        );
        expect(await specFile.exists(), isTrue);
        final text = await specFile.readAsString();
        expect(text, contains('# AKASHA Vault Format Specification (v3)'));
        expect(text, contains('schema_version'));
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

    File indexFile() => File(
      p.join(tempDir.path, '.akasha', EntityPathIndexService.indexFileName),
    );

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

    test(
      'upsertMarkdownFile and removeByAbsolutePath are incremental',
      () async {
        final entityPath = p.join(
          tempDir.path,
          'entities',
          'concept',
          'co_u_pathincrement.md',
        );
        final entityFile = File(entityPath);
        await entityFile.parent.create(recursive: true);
        await entityFile.writeAsString(
          EntityJournalParser.serialize(
            entityType: EntityAnchorType.concept,
            entityId: 'co_u_pathincrement',
            title: 'Path Increment',
            body: 'body',
          ),
        );

        final upserted = await index.upsertMarkdownFile(
          vaultPath: tempDir.path,
          absolutePath: entityPath,
        );

        expect(upserted, 'co_u_pathincrement');
        expect(
          await index.lookupRelativePath(tempDir.path, 'co_u_pathincrement'),
          isNotNull,
        );

        final removed = await index.removeByAbsolutePath(
          vaultPath: tempDir.path,
          absolutePath: entityPath,
        );

        expect(removed, 'co_u_pathincrement');
        expect(
          await index.lookupRelativePath(tempDir.path, 'co_u_pathincrement'),
          isNull,
        );
      },
    );

    test('failed replace leaves the previous good index intact', () async {
      const entityId = 'pe_u_keepidx01';
      final path = p.join(tempDir.path, 'entities', 'person', 'Keep.md');
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: path,
      );
      final before = await indexFile().readAsString();

      final failing = EntityPathIndexService(
        atomicWrite: DerivedIndexAtomicWrite(
          beforeReplace: (_) async {
            throw StateError('injected replace failure');
          },
        ),
      );

      await expectLater(
        () => failing.upsert(
          vaultPath: tempDir.path,
          entityId: 'pe_u_otheridx01',
          absolutePath: p.join(tempDir.path, 'entities', 'person', 'Other.md'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await indexFile().readAsString(), before);
      expect(await index.isAvailable(tempDir.path), isTrue);
      expect(await index.lookupRelativePath(tempDir.path, entityId), isNotNull);
    });

    test('missing target + valid bak restores without rebuild', () async {
      const entityId = 'pe_u_bakrest01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'A.md'),
      );
      final file = indexFile();
      final good = await file.readAsString();
      await file.rename('${file.path}.bak');

      expect(await index.lookupRelativePath(tempDir.path, entityId), isNotNull);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), good);
      expect(await File('${file.path}.bak').exists(), isFalse);
    });

    test('corrupt target + valid bak restores from bak', () async {
      const entityId = 'pe_u_bakcorr01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'B.md'),
      );
      final file = indexFile();
      final good = await file.readAsString();
      await File('${file.path}.bak').writeAsString(good);
      await file.writeAsString('{truncated');

      expect(await index.lookupRelativePath(tempDir.path, entityId), isNotNull);
      expect(await file.readAsString(), good);
    });

    test('corrupt target + corrupt bak is unavailable', () async {
      const entityId = 'pe_u_bothbad01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'C.md'),
      );
      final file = indexFile();
      await File('${file.path}.bak').writeAsString('{bad-bak');
      await file.writeAsString('{bad-target');

      expect(await index.isAvailable(tempDir.path), isFalse);
      final loaded = await index.loadPathsResult(tempDir.path);
      expect(loaded.isCorrupt, isTrue);
    });

    test('missing target + stale tmp is not promoted', () async {
      const entityId = 'pe_u_staletmp01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'D.md'),
      );
      final file = indexFile();
      final good = await file.readAsString();
      await file.delete();
      await File('${file.path}.tmp').writeAsString(good);

      expect(await index.isAvailable(tempDir.path), isFalse);
      expect(await index.lookupRelativePath(tempDir.path, entityId), isNull);
      expect(await File('${file.path}.tmp').exists(), isFalse);

      await index.ensureIndex(tempDir.path);
      // No entities tree → empty rebuild → available empty index.
      expect(await index.isAvailable(tempDir.path), isTrue);
    });

    test('valid target + stale tmp/bak cleans sidecars', () async {
      const entityId = 'pe_u_cleansc01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'E.md'),
      );
      final file = indexFile();
      final good = await file.readAsString();
      await File('${file.path}.tmp').writeAsString('{tmp');
      await File('${file.path}.bak').writeAsString('{bak');

      expect(await index.lookupRelativePath(tempDir.path, entityId), isNotNull);
      expect(await file.readAsString(), good);
      expect(await File('${file.path}.tmp').exists(), isFalse);
      expect(await File('${file.path}.bak').exists(), isFalse);
    });

    test('failed bak restore keeps bak', () async {
      const entityId = 'pe_u_restfail01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'F.md'),
      );
      final file = indexFile();
      final good = await file.readAsString();
      await file.rename('${file.path}.bak');

      final failing = EntityPathIndexService(
        atomicWrite: DerivedIndexAtomicWrite(
          beforeBakRestore: (_, _) async {
            throw StateError('injected restore failure');
          },
        ),
      );

      expect(await failing.isAvailable(tempDir.path), isFalse);
      expect(await File('${file.path}.bak').exists(), isTrue);
      expect(await File('${file.path}.bak').readAsString(), good);
      expect(await file.exists(), isFalse);
    });

    test('corrupt index without bak is unavailable, not empty hit', () async {
      const entityId = 'pe_u_corrupt01';
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: entityId,
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'G.md'),
      );
      await indexFile().writeAsString('{truncated');

      expect(await index.isAvailable(tempDir.path), isFalse);
      final loaded = await index.loadPathsResult(tempDir.path);
      expect(loaded.isCorrupt, isTrue);
      expect(await index.lookupRelativePath(tempDir.path, entityId), isNull);
    });

    test('rebuildFromVault recovers corrupt index from Markdown', () async {
      await store.saveCatalogEntity(
        vaultPath: tempDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_recover01',
          type: EntityAnchorType.person,
          title: 'Recover',
        ),
        body: 'body',
      );
      await indexFile().writeAsString('{truncated');
      expect(await index.isAvailable(tempDir.path), isFalse);

      await index.rebuildFromVault(tempDir.path);

      expect(await index.isAvailable(tempDir.path), isTrue);
      expect(
        await index.lookupRelativePath(tempDir.path, 'pe_u_recover01'),
        isNotNull,
      );
    });

    test(
      'concurrent upserts preserve both ids across service instances',
      () async {
        final firstReachedReplace = Completer<void>();
        final releaseFirst = Completer<void>();
        var blocked = false;
        final first = EntityPathIndexService(
          atomicWrite: DerivedIndexAtomicWrite(
            beforeReplace: (_) async {
              if (blocked) return;
              blocked = true;
              firstReachedReplace.complete();
              await releaseFirst.future;
            },
          ),
        );
        final second = EntityPathIndexService();

        final firstMutation = first.upsert(
          vaultPath: tempDir.path,
          entityId: 'pe_u_concurrent01',
          absolutePath: p.join(
            tempDir.path,
            'entities',
            'person',
            'Concurrent One.md',
          ),
        );
        await firstReachedReplace.future;
        final secondMutation = second.upsert(
          vaultPath: tempDir.path,
          entityId: 'pe_u_concurrent02',
          absolutePath: p.join(
            tempDir.path,
            'entities',
            'person',
            'Concurrent Two.md',
          ),
        );

        releaseFirst.complete();
        await Future.wait([firstMutation, secondMutation]);

        final paths = await index.loadPaths(tempDir.path);
        expect(
          paths.keys,
          containsAll(['pe_u_concurrent01', 'pe_u_concurrent02']),
        );
        expect(jsonDecode(await indexFile().readAsString()), isA<Map>());
      },
    );

    test('repeated concurrent upserts preserve every different id', () async {
      const count = 24;
      await Future.wait([
        for (var i = 0; i < count; i++)
          EntityPathIndexService().upsert(
            vaultPath: tempDir.path,
            entityId: 'pe_u_parallel${i.toString().padLeft(2, '0')}',
            absolutePath: p.join(
              tempDir.path,
              'entities',
              'person',
              'Parallel $i.md',
            ),
          ),
      ]);

      final paths = await index.loadPaths(tempDir.path);
      for (var i = 0; i < count; i++) {
        expect(paths, contains('pe_u_parallel${i.toString().padLeft(2, '0')}'));
      }
      expect(jsonDecode(await indexFile().readAsString()), isA<Map>());
    });

    test(
      'same id concurrent upserts deterministically keep queued last path',
      () async {
        final firstReachedReplace = Completer<void>();
        final releaseFirst = Completer<void>();
        final first = EntityPathIndexService(
          atomicWrite: DerivedIndexAtomicWrite(
            beforeReplace: (_) async {
              firstReachedReplace.complete();
              await releaseFirst.future;
            },
          ),
        );
        final second = EntityPathIndexService();
        final firstPath = p.join(
          tempDir.path,
          'entities',
          'person',
          'Same First.md',
        );
        final secondPath = p.join(
          tempDir.path,
          'entities',
          'person',
          'Same Second.md',
        );

        final firstMutation = first.upsert(
          vaultPath: tempDir.path,
          entityId: 'pe_u_samequeue01',
          absolutePath: firstPath,
        );
        await firstReachedReplace.future;
        final secondMutation = second.upsert(
          vaultPath: tempDir.path,
          entityId: 'pe_u_samequeue01',
          absolutePath: secondPath,
        );

        releaseFirst.complete();
        await Future.wait([firstMutation, secondMutation]);

        expect(
          await index.lookupAbsolutePath(tempDir.path, 'pe_u_samequeue01'),
          p.normalize(secondPath),
        );
        expect(jsonDecode(await indexFile().readAsString()), isA<Map>());
      },
    );

    test(
      'queued upsert then delete leaves valid JSON without the entry',
      () async {
        final firstReachedReplace = Completer<void>();
        final releaseFirst = Completer<void>();
        final first = EntityPathIndexService(
          atomicWrite: DerivedIndexAtomicWrite(
            beforeReplace: (_) async {
              firstReachedReplace.complete();
              await releaseFirst.future;
            },
          ),
        );
        final second = EntityPathIndexService();
        final path = p.join(
          tempDir.path,
          'entities',
          'person',
          'Upsert Delete.md',
        );

        final upsert = first.upsert(
          vaultPath: tempDir.path,
          entityId: 'pe_u_upsertdelete',
          absolutePath: path,
        );
        await firstReachedReplace.future;
        final remove = second.removeByAbsolutePath(
          vaultPath: tempDir.path,
          absolutePath: path,
        );

        releaseFirst.complete();
        await upsert;
        expect(await remove, 'pe_u_upsertdelete');

        expect(
          await index.lookupRelativePath(tempDir.path, 'pe_u_upsertdelete'),
          isNull,
        );
        expect(jsonDecode(await indexFile().readAsString()), isA<Map>());
      },
    );

    test('failed mutation releases the queue for the next mutation', () async {
      final firstReachedReplace = Completer<void>();
      final releaseFailure = Completer<void>();
      final failing = EntityPathIndexService(
        atomicWrite: DerivedIndexAtomicWrite(
          beforeReplace: (_) async {
            firstReachedReplace.complete();
            await releaseFailure.future;
            throw StateError('injected queued failure');
          },
        ),
      );
      final succeeding = EntityPathIndexService();

      final failedMutation = failing.upsert(
        vaultPath: tempDir.path,
        entityId: 'pe_u_queuefail01',
        absolutePath: p.join(
          tempDir.path,
          'entities',
          'person',
          'Queue Fail.md',
        ),
      );
      final failedExpectation = expectLater(
        failedMutation,
        throwsA(isA<StateError>()),
      );
      await firstReachedReplace.future;
      final nextMutation = succeeding.upsert(
        vaultPath: tempDir.path,
        entityId: 'pe_u_queueok01',
        absolutePath: p.join(tempDir.path, 'entities', 'person', 'Queue OK.md'),
      );

      releaseFailure.complete();
      await failedExpectation;
      await nextMutation;

      expect(
        await index.lookupRelativePath(tempDir.path, 'pe_u_queueok01'),
        isNotNull,
      );
      expect(jsonDecode(await indexFile().readAsString()), isA<Map>());
    });

    test('incremental malformed Entity exposes a partial result', () async {
      final path = p.join(tempDir.path, 'entities', 'person', 'Malformed.md');
      final file = File(path);
      await file.parent.create(recursive: true);
      await index.upsert(
        vaultPath: tempDir.path,
        entityId: 'pe_u_malformed01',
        absolutePath: path,
      );
      await file.writeAsString('---\nrecord_kind: entityJournal\nbroken: [\n');

      final result = await index.upsertMarkdownFileDetailed(
        vaultPath: tempDir.path,
        absolutePath: path,
      );

      expect(result.succeeded, isFalse);
      expect(result.partialSuccess, isTrue);
      expect(result.operation, EntityPathIndexMutationOperation.skipped);
      expect(result.entityId, 'pe_u_malformed01');
      expect(result.skippedPath, 'entities/person/Malformed.md');
      expect(
        result.issues.map((issue) => issue.errorCode),
        contains('frontmatter_invalid'),
      );
      expect(
        await file.exists(),
        isTrue,
        reason: 'source Markdown is retained',
      );
      expect(
        await index.lookupRelativePath(tempDir.path, 'pe_u_malformed01'),
        isNull,
      );
    });

    test(
      'rebuild preserves valid entries and reports malformed files',
      () async {
        final good = File(
          p.join(tempDir.path, 'entities', 'person', 'Good.md'),
        );
        final bad = File(p.join(tempDir.path, 'entities', 'person', 'Bad.md'));
        await good.parent.create(recursive: true);
        await good.writeAsString(
          EntityJournalParser.serialize(
            entityType: EntityAnchorType.person,
            entityId: 'pe_u_rebuildgood',
            title: 'Good',
            body: 'body',
          ),
        );
        await bad.writeAsString('---\nrecord_kind: entityJournal\nbroken: [\n');

        final result = await index.rebuildFromVaultDetailed(tempDir.path);

        expect(result.succeeded, isFalse);
        expect(result.partialSuccess, isTrue);
        expect(result.indexedEntries, 1);
        expect(result.malformedPaths, contains('entities/person/Bad.md'));
        expect(
          await index.lookupRelativePath(tempDir.path, 'pe_u_rebuildgood'),
          isNotNull,
        );
        expect(await bad.exists(), isTrue);
      },
    );

    test(
      'detailed mutation exposes a write issue without exception text',
      () async {
        final path = p.join(
          tempDir.path,
          'entities',
          'person',
          'Write Failure.md',
        );
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsString(
          EntityJournalParser.serialize(
            entityType: EntityAnchorType.person,
            entityId: 'pe_u_writefail01',
            title: 'Write Failure',
            body: 'body',
          ),
        );
        final failing = EntityPathIndexService(
          atomicWrite: DerivedIndexAtomicWrite(
            beforeReplace: (_) async {
              throw StateError('sensitive injected detail');
            },
          ),
        );

        final result = await failing.upsertMarkdownFileDetailed(
          vaultPath: tempDir.path,
          absolutePath: path,
        );

        expect(result.succeeded, isFalse);
        expect(result.partialSuccess, isFalse);
        expect(result.writeApplied, isFalse);
        expect(result.writeFailure, isA<StateError>());
        expect(result.issues.single.errorCode, 'index_write_failed');
        expect(result.issues.single.diagnostic, 'StateError');
        expect(result.toJson().toString(), isNot(contains('sensitive')));
      },
    );
  });

  group('EntityVaultStore title rename', () {
    test('keeps ID path stable when title changes', () async {
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

        expect(renamed.storagePath, saved.storagePath);
        expect(renamed.storagePath, contains('pe_u_rename01.md'));
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
