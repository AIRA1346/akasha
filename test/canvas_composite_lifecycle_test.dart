import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:akasha/services/canvas_store.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:akasha/services/vault_trash_transaction_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Canvas Composite Lifecycle, Fault-Injection & Guard Tests', () {
    late Directory tempVault;
    final trashService = const VaultTrashService();
    final canvasStore = CanvasStore.instance;

    setUp(() async {
      tempVault = await Directory.systemTemp.createTemp(
        'canvas_lifecycle_test',
      );
    });

    tearDown(() async {
      if (tempVault.existsSync()) {
        await tempVault.delete(recursive: true);
      }
    });

    test('Single-file moveFileToTrash rejects canvas member files', () async {
      final canvasData = await canvasStore.createCanvas(
        vaultPath: tempVault.path,
        title: 'Guard Test Canvas',
        slug: 'guard-test',
      );
      final canvasId = canvasData.record.canvasId;
      final canvasMdPath = p.join(
        tempVault.path,
        'canvases',
        canvasId,
        'canvas.md',
      );
      final layoutJsonPath = p.join(
        tempVault.path,
        'canvases',
        canvasId,
        'layout.json',
      );

      expect(
        () => trashService.moveFileToTrash(
          vaultPath: tempVault.path,
          absolutePath: canvasMdPath,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Canvas member files cannot be trashed independently'),
          ),
        ),
      );

      expect(
        () => trashService.moveFileToTrash(
          vaultPath: tempVault.path,
          absolutePath: layoutJsonPath,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Canvas member files cannot be trashed independently'),
          ),
        ),
      );

      expect(File(canvasMdPath).existsSync(), isTrue);
      expect(File(layoutJsonPath).existsSync(), isTrue);
    });

    test(
      'Composite moveCanvasToTrash keeps sidecar files with the canvas directory',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Extra File Canvas',
          slug: 'extra-file',
        );
        final canvasId = canvasData.record.canvasId;
        final extraFile = File(
          p.join(tempVault.path, 'canvases', canvasId, 'extra.txt'),
        );
        await extraFile.writeAsString('sidecar content');

        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
        );
        expect(trashResult.succeeded, isTrue);
        expect(extraFile.existsSync(), isFalse);

        final trashExtra = File(
          p.join(
            trashResult.transaction!.trashRootPath!,
            'canvases',
            canvasId,
            'extra.txt',
          ),
        );
        expect(trashExtra.existsSync(), isTrue);
        expect(await trashExtra.readAsString(), equals('sidecar content'));

        final members = trashResult.transaction!.members;
        expect(members.length, greaterThanOrEqualTo(3));
        expect(
          members.map((m) => p.basename(m.relativeOriginalPath)),
          containsAll(['canvas.md', 'layout.json', 'extra.txt']),
        );
        final sidecar = members.firstWhere(
          (m) => p.basename(m.relativeOriginalPath) == 'extra.txt',
        );
        expect(sidecar.required, isFalse);
        expect(sidecar.sha256, isNotEmpty);
      },
    );

    test(
      'Composite moveCanvasToTrash validates layout.json canvas_id matching',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Bad Layout ID Canvas',
          slug: 'bad-layout-id',
        );
        final canvasId = canvasData.record.canvasId;
        final layoutFile = File(
          p.join(tempVault.path, 'canvases', canvasId, 'layout.json'),
        );
        await layoutFile.writeAsString('{"canvas_id": "cv_u_mismatched_id"}');

        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
        );
        expect(trashResult.succeeded, isFalse);
        expect(
          trashResult.error,
          contains('Canvas ID in layout.json does not match'),
        );
      },
    );

    test(
      'Composite moveCanvasToTrash and restoreCanvasTransaction round-trip without overwriting',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Composite Trash Test',
          slug: 'composite-trash',
        );
        final canvasId = canvasData.record.canvasId;
        final canvasDir = Directory(
          p.join(tempVault.path, 'canvases', canvasId),
        );
        final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
        final jsonFile = File(p.join(canvasDir.path, 'layout.json'));

        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
          reason: 'test_composite_delete',
        );

        expect(trashResult.succeeded, isTrue);
        expect(trashResult.transaction, isNotNull);
        expect(canvasDir.existsSync(), isFalse);

        final tx = trashResult.transaction!;
        expect(tx.recordKind, equals('canvas'));
        expect(tx.recordId, equals(canvasId));
        expect(tx.state, equals(VaultTrashTransactionState.committed.wireName));

        final restoreResult = await trashService.restoreCanvasTransaction(tx);
        expect(restoreResult.succeeded, isTrue);
        expect(
          restoreResult.state,
          equals(VaultTrashTransactionState.restored.wireName),
        );

        expect(canvasDir.existsSync(), isTrue);
        expect(mdFile.existsSync(), isTrue);
        expect(jsonFile.existsSync(), isTrue);

        final reloaded = await canvasStore.loadCanvas(tempVault.path, canvasId);
        expect(reloaded, isNotNull);
        expect(reloaded!.record.title, equals('Composite Trash Test'));
      },
    );

    test(
      'restoreCanvasTransaction is strictly non-destructive and returns restoreConflict on collision',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Non Destructive Test',
          slug: 'non-destructive',
        );
        final canvasId = canvasData.record.canvasId;
        final mdFile = File(
          p.join(tempVault.path, 'canvases', canvasId, 'canvas.md'),
        );

        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
        );
        expect(trashResult.succeeded, isTrue);

        // Re-create conflicting canvas.md
        await mdFile.parent.create(recursive: true);
        await mdFile.writeAsString('# Conflict Active Content');

        final restoreResult = await trashService.restoreCanvasTransaction(
          trashResult.transaction!,
        );
        expect(restoreResult.succeeded, isFalse);
        expect(restoreResult.state, equals('restoreConflict'));
        expect(restoreResult.error, contains('strictly forbidden'));

        // Verify active file was NOT deleted or mutated
        expect(
          await mdFile.readAsString(),
          equals('# Conflict Active Content'),
        );
      },
    );

    test(
      'restoreCanvasTransaction rejects path traversal in transaction manifest',
      () async {
        final stamp = '2026-07-24T00-00-00-000000z';
        final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final badTx = VaultTrashTransaction(
          version: 1,
          transactionId: stamp,
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: 'cv_u_hacker01',
          state: VaultTrashTransactionState.committed.wireName,
          createdAt: DateTime.now().toUtc(),
          trashRootPath: trashRoot.path,
          members: [
            VaultTrashMember(
              relativeOriginalPath: '../outside/canvas.md',
              relativeTrashPath: 'canvases/cv_u_hacker01/canvas.md',
              size: 10,
              sha256: 'abc',
            ),
            VaultTrashMember(
              relativeOriginalPath: 'canvases/cv_u_hacker01/layout.json',
              relativeTrashPath: 'canvases/cv_u_hacker01/layout.json',
              size: 10,
              sha256: 'def',
            ),
          ],
        );
        File(
          p.join(trashRoot.path, 'trash_transaction.json'),
        ).writeAsStringSync(jsonEncode(badTx.toJson()));

        final restoreResult = await trashService.restoreCanvasTransaction(
          badTx,
        );
        expect(restoreResult.succeeded, isFalse);
        expect(
          restoreResult.error,
          anyOf(
            contains('Path traversal or absolute path detected'),
            contains('Transaction member original paths must stay under'),
          ),
        );
      },
    );

    test(
      'Fault-Injection: prepared state recovery before directory rename',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Interrupted Prepared',
          slug: 'interrupted-prepared',
        );
        final canvasId = canvasData.record.canvasId;
        final mdBytes = await File(
          p.join(tempVault.path, 'canvases', canvasId, 'canvas.md'),
        ).readAsBytes();
        final jsonBytes = await File(
          p.join(tempVault.path, 'canvases', canvasId, 'layout.json'),
        ).readAsBytes();

        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T10-00-00-000000z'),
        );
        await trashStampDir.create(recursive: true);

        final preparedTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T10-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          state: VaultTrashTransactionState.prepared.wireName,
          createdAt: DateTime.now().toUtc(),
          members: [
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'canvas.md'),
              relativeTrashPath: p.join('canvases', canvasId, 'canvas.md'),
              size: mdBytes.length,
              sha256: crypto.sha256.convert(mdBytes).toString(),
            ),
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'layout.json'),
              relativeTrashPath: p.join('canvases', canvasId, 'layout.json'),
              size: jsonBytes.length,
              sha256: crypto.sha256.convert(jsonBytes).toString(),
            ),
          ],
        );
        final manifestFile = File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        );
        await manifestFile.writeAsString(jsonEncode(preparedTx.toJson()));

        final recovered = await trashService.recoverPendingTrashTransactions(
          vaultPath: tempVault.path,
        );
        expect(recovered, contains('2026-07-24T10-00-00-000000z'));
        expect(trashStampDir.existsSync(), isFalse);
      },
    );

    test(
      'Fault-Injection: moving state recovery after directory rename',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Interrupted Moving',
          slug: 'interrupted-moving',
        );
        final canvasId = canvasData.record.canvasId;
        final canvasDir = Directory(
          p.join(tempVault.path, 'canvases', canvasId),
        );

        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T11-00-00-000000z'),
        );
        final targetTrashCanvasDir = Directory(
          p.join(trashStampDir.path, 'canvases', canvasId),
        );
        await targetTrashCanvasDir.parent.create(recursive: true);
        await canvasDir.rename(targetTrashCanvasDir.path);

        final trashMdFile = File(
          p.join(targetTrashCanvasDir.path, 'canvas.md'),
        );
        final trashJsonFile = File(
          p.join(targetTrashCanvasDir.path, 'layout.json'),
        );

        final mdBytes = await trashMdFile.readAsBytes();
        final jsonBytes = await trashJsonFile.readAsBytes();

        final movingTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T11-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          state: VaultTrashTransactionState.moving.wireName,
          createdAt: DateTime.now().toUtc(),
          members: [
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'canvas.md'),
              relativeTrashPath: p.join('canvases', canvasId, 'canvas.md'),
              size: mdBytes.length,
              sha256: crypto.sha256.convert(mdBytes).toString(),
            ),
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'layout.json'),
              relativeTrashPath: p.join('canvases', canvasId, 'layout.json'),
              size: jsonBytes.length,
              sha256: crypto.sha256.convert(jsonBytes).toString(),
            ),
          ],
        );
        final manifestFile = File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        );
        await manifestFile.writeAsString(jsonEncode(movingTx.toJson()));

        final recovered = await trashService.recoverPendingTrashTransactions(
          vaultPath: tempVault.path,
        );
        expect(recovered, contains('2026-07-24T11-00-00-000000z'));

        final txList = await trashService.listTransactions(
          vaultPath: tempVault.path,
        );
        final recoveredTx = txList.firstWhere(
          (t) => t.transactionId == '2026-07-24T11-00-00-000000z',
        );
        expect(
          recoveredTx.state,
          equals(VaultTrashTransactionState.committed.wireName),
        );
      },
    );

    test(
      'Fault-Injection: restoring state recovery after crash before rename',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Interrupted Restoring',
          slug: 'interrupted-restoring',
        );
        final canvasId = canvasData.record.canvasId;
        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
        );
        final tx = trashResult.transaction!;

        final trashStampDir = Directory(tx.trashRootPath!);
        final restoringTx = VaultTrashTransaction(
          version: tx.version,
          transactionId: tx.transactionId,
          vaultPath: tx.vaultPath,
          recordKind: tx.recordKind,
          recordId: tx.recordId,
          state: VaultTrashTransactionState.restoring.wireName,
          createdAt: tx.createdAt,
          members: tx.members,
          trashRootPath: tx.trashRootPath,
        );
        await File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        ).writeAsString(jsonEncode(restoringTx.toJson()));

        final recovered = await trashService.recoverPendingTrashTransactions(
          vaultPath: tempVault.path,
        );
        expect(recovered, contains(tx.transactionId));

        expect(
          Directory(p.join(tempVault.path, 'canvases', canvasId)).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'Fault-Injection: partial presence marks rollbackRequired state',
      () async {
        final canvasId = 'cv_u_partial1';
        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T12-00-00-000000z'),
        );
        await trashStampDir.create(recursive: true);

        // Leave one file in original, one in trash
        final origMd = File(
          p.join(tempVault.path, 'canvases', canvasId, 'canvas.md'),
        );
        await origMd.parent.create(recursive: true);
        await origMd.writeAsString('md content');

        final trashJson = File(
          p.join(trashStampDir.path, 'canvases', canvasId, 'layout.json'),
        );
        await trashJson.parent.create(recursive: true);
        await trashJson.writeAsString('json content');

        final partialTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T12-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          state: VaultTrashTransactionState.prepared.wireName,
          createdAt: DateTime.now().toUtc(),
          members: [
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'canvas.md'),
              relativeTrashPath: p.join('canvases', canvasId, 'canvas.md'),
              size: 100,
              sha256: 'abc',
            ),
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'layout.json'),
              relativeTrashPath: p.join('canvases', canvasId, 'layout.json'),
              size: 100,
              sha256: 'def',
            ),
          ],
        );
        final manifestFile = File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        );
        await manifestFile.writeAsString(jsonEncode(partialTx.toJson()));

        await trashService.recoverPendingTrashTransactions(
          vaultPath: tempVault.path,
        );

        final updatedManifest = jsonDecode(await manifestFile.readAsString());
        expect(
          updatedManifest['state'],
          equals(VaultTrashTransactionState.rollbackRequired.wireName),
        );
      },
    );

    test(
      'restoreCanvasTransaction rejects SHA-256 mismatch without mutating active vault',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Hash Mismatch Canvas',
          slug: 'hash-mismatch',
        );
        final canvasId = canvasData.record.canvasId;
        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
        );
        expect(trashResult.succeeded, isTrue);
        final tx = trashResult.transaction!;

        final trashMd = File(
          p.join(tx.trashRootPath!, 'canvases', canvasId, 'canvas.md'),
        );
        await trashMd.writeAsString('${await trashMd.readAsString()}\nmutated');

        final restoreResult = await trashService.restoreCanvasTransaction(tx);
        expect(restoreResult.succeeded, isFalse);
        expect(
          restoreResult.error,
          anyOf(contains('SHA-256 hash mismatch'), contains('Size mismatch')),
        );
        expect(
          Directory(p.join(tempVault.path, 'canvases', canvasId)).existsSync(),
          isFalse,
        );
      },
    );

    test('restoreCanvasTransaction rejects absolute member paths', () async {
      final stamp = '2026-07-24T13-00-00-000000z';
      final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp))
        ..createSync(recursive: true);
      final badTx = VaultTrashTransaction(
        version: 1,
        transactionId: stamp,
        vaultPath: tempVault.path,
        recordKind: 'canvas',
        recordId: 'cv_u_abs00001',
        state: VaultTrashTransactionState.committed.wireName,
        createdAt: DateTime.now().toUtc(),
        trashRootPath: trashRoot.path,
        members: [
          VaultTrashMember(
            relativeOriginalPath: p.join(
              tempVault.path,
              'canvases',
              'cv_u_abs00001',
              'canvas.md',
            ),
            relativeTrashPath: p.join('canvases', 'cv_u_abs00001', 'canvas.md'),
            size: 10,
            sha256: 'abc',
          ),
          VaultTrashMember(
            relativeOriginalPath: p.join(
              'canvases',
              'cv_u_abs00001',
              'layout.json',
            ),
            relativeTrashPath: p.join(
              'canvases',
              'cv_u_abs00001',
              'layout.json',
            ),
            size: 10,
            sha256: 'def',
          ),
        ],
      );
      File(
        p.join(trashRoot.path, 'trash_transaction.json'),
      ).writeAsStringSync(jsonEncode(badTx.toJson()));

      final restoreResult = await trashService.restoreCanvasTransaction(badTx);
      expect(restoreResult.succeeded, isFalse);
      expect(
        restoreResult.error,
        anyOf(
          contains('Path traversal or absolute path detected'),
          contains('Transaction member original paths must stay under'),
        ),
      );
    });

    test(
      'recovery hash mismatch for prepared originals marks rollbackRequired',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Hash Rollback',
          slug: 'hash-rollback',
        );
        final canvasId = canvasData.record.canvasId;
        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T14-00-00-000000z'),
        );
        await trashStampDir.create(recursive: true);

        final preparedTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T14-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          state: VaultTrashTransactionState.prepared.wireName,
          createdAt: DateTime.now().toUtc(),
          members: [
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'canvas.md'),
              relativeTrashPath: p.join('canvases', canvasId, 'canvas.md'),
              size: 1,
              sha256: 'deadbeef',
            ),
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'layout.json'),
              relativeTrashPath: p.join('canvases', canvasId, 'layout.json'),
              size: 1,
              sha256: 'cafebabe',
            ),
          ],
        );
        final manifestFile = File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        );
        await manifestFile.writeAsString(jsonEncode(preparedTx.toJson()));

        final details = await trashService
            .recoverPendingTrashTransactionsDetail(vaultPath: tempVault.path);
        expect(
          details.single.resultState,
          equals(VaultTrashTransactionState.rollbackRequired.wireName),
        );
        expect(trashStampDir.existsSync(), isTrue);
        expect(
          Directory(p.join(tempVault.path, 'canvases', canvasId)).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'deleteTransactionPermanently rejects mismatched trashRootPath',
      () async {
        final outside = await Directory.systemTemp.createTemp(
          'canvas_outside_trash',
        );
        addTearDown(() async {
          if (outside.existsSync()) await outside.delete(recursive: true);
        });

        final tx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T15-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: 'cv_u_delpath1',
          state: VaultTrashTransactionState.committed.wireName,
          createdAt: DateTime.now().toUtc(),
          trashRootPath: outside.path,
          members: [
            VaultTrashMember(
              relativeOriginalPath: p.join(
                'canvases',
                'cv_u_delpath1',
                'canvas.md',
              ),
              relativeTrashPath: p.join(
                'canvases',
                'cv_u_delpath1',
                'canvas.md',
              ),
              size: 10,
              sha256: 'abc',
            ),
            VaultTrashMember(
              relativeOriginalPath: p.join(
                'canvases',
                'cv_u_delpath1',
                'layout.json',
              ),
              relativeTrashPath: p.join(
                'canvases',
                'cv_u_delpath1',
                'layout.json',
              ),
              size: 10,
              sha256: 'def',
            ),
          ],
        );

        final deleted = await trashService.deleteTransactionPermanently(tx);
        expect(deleted, isFalse);
        expect(outside.existsSync(), isTrue);
      },
    );

    test('moveCanvasToTrash rejects unsafe canvasId values', () async {
      final outsideRoot = Directory.systemTemp.createTempSync(
        'akasha_outside_sentinel',
      );
      final sentinelDir = Directory(p.join(outsideRoot.path, 'keep_me'))
        ..createSync();
      final sentinelFile = File(p.join(sentinelDir.path, 'sentinel.txt'))
        ..writeAsStringSync('untouched-sentinel');
      addTearDown(() {
        if (outsideRoot.existsSync()) {
          outsideRoot.deleteSync(recursive: true);
        }
      });

      final unsafeIds = <String>[
        '..',
        '../works',
        r'..\works',
        'canvases/nested',
        p.join(tempVault.path, 'canvases', 'cv_u_abcdef12'),
        '.',
        'cv_u_ab/cd',
        r'cv_u_ab\cd',
        'wk_u_abcdef12',
        'cv_u_SHORT',
        'cv_u_toolongid',
        'cv_u_BADCASE1',
      ];

      for (final canvasId in unsafeIds) {
        final result = await trashService.moveCanvasToTrash(
          vaultPath: tempVault.path,
          canvasId: canvasId,
        );
        expect(result.succeeded, isFalse, reason: 'id=$canvasId');
        expect(result.error, isNotNull, reason: 'id=$canvasId');
        expect(sentinelDir.existsSync(), isTrue, reason: 'id=$canvasId');
        expect(
          sentinelFile.readAsStringSync(),
          'untouched-sentinel',
          reason: 'id=$canvasId',
        );
        expect(
          Directory(p.join(tempVault.path, 'works')).existsSync(),
          isFalse,
          reason: 'id=$canvasId must not create vault works/',
        );
      }
    });

    test('public restore rejects non-committed transaction states', () async {
      Future<void> expectInvalidRestore(String diskState) async {
        final stamp =
            '2026-07-24T20-${diskState.hashCode.abs().toRadixString(16)}-000000z';
        final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final diskTx = VaultTrashTransaction(
          version: 1,
          transactionId: stamp,
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: 'cv_u_state001',
          state: diskState,
          createdAt: DateTime.now().toUtc(),
          trashRootPath: trashRoot.path,
          members: [
            VaultTrashMember(
              relativeOriginalPath: 'canvases/cv_u_state001/canvas.md',
              relativeTrashPath: 'canvases/cv_u_state001/canvas.md',
              size: 1,
              sha256: 'a',
            ),
            VaultTrashMember(
              relativeOriginalPath: 'canvases/cv_u_state001/layout.json',
              relativeTrashPath: 'canvases/cv_u_state001/layout.json',
              size: 1,
              sha256: 'b',
            ),
          ],
        );
        File(
          p.join(trashRoot.path, 'trash_transaction.json'),
        ).writeAsStringSync(jsonEncode(diskTx.toJson()));

        final caller = diskTx.copyWith(
          state: VaultTrashTransactionState.committed.wireName,
        );
        final result = await trashService.restoreCanvasTransaction(caller);
        expect(result.succeeded, isFalse, reason: diskState);
        expect(
          result.errorCode,
          CanvasRestoreResult.invalidStateErrorCode,
          reason: diskState,
        );
        expect(result.error, contains('invalidState'), reason: diskState);
      }

      await expectInvalidRestore(VaultTrashTransactionState.prepared.wireName);
      await expectInvalidRestore(VaultTrashTransactionState.moving.wireName);
      await expectInvalidRestore(VaultTrashTransactionState.restoring.wireName);
      await expectInvalidRestore(VaultTrashTransactionState.restored.wireName);
      await expectInvalidRestore(
        VaultTrashTransactionState.restoreConflict.wireName,
      );
      await expectInvalidRestore(
        VaultTrashTransactionState.rollbackRequired.wireName,
      );
      await expectInvalidRestore('totallyUnknown');
    });

    test(
      'deleteTransactionPermanently rejects unsafe states and preserves folder',
      () async {
        Future<void> expectDeleteRejected(String diskState) async {
          final stamp =
              '2026-07-24T21-${diskState.hashCode.abs().toRadixString(16)}-000000z';
          final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp))
            ..createSync(recursive: true);
          File(p.join(trashRoot.path, 'marker.txt')).writeAsStringSync('keep');

          final diskTx = VaultTrashTransaction(
            version: 1,
            transactionId: stamp,
            vaultPath: tempVault.path,
            recordKind: 'canvas',
            recordId: 'cv_u_delst001',
            state: diskState,
            createdAt: DateTime.now().toUtc(),
            trashRootPath: trashRoot.path,
            members: [
              VaultTrashMember(
                relativeOriginalPath: 'canvases/cv_u_delst001/canvas.md',
                relativeTrashPath: 'canvases/cv_u_delst001/canvas.md',
                size: 1,
                sha256: 'a',
              ),
              VaultTrashMember(
                relativeOriginalPath: 'canvases/cv_u_delst001/layout.json',
                relativeTrashPath: 'canvases/cv_u_delst001/layout.json',
                size: 1,
                sha256: 'b',
              ),
            ],
          );
          File(
            p.join(trashRoot.path, 'trash_transaction.json'),
          ).writeAsStringSync(jsonEncode(diskTx.toJson()));

          final caller = diskTx.copyWith(
            state: VaultTrashTransactionState.committed.wireName,
          );
          final deleted = await trashService.deleteTransactionPermanently(
            caller,
          );
          expect(deleted, isFalse, reason: diskState);
          expect(trashRoot.existsSync(), isTrue, reason: diskState);
          expect(
            File(p.join(trashRoot.path, 'marker.txt')).readAsStringSync(),
            'keep',
            reason: diskState,
          );
        }

        await expectDeleteRejected(
          VaultTrashTransactionState.prepared.wireName,
        );
        await expectDeleteRejected(VaultTrashTransactionState.moving.wireName);
        await expectDeleteRejected(
          VaultTrashTransactionState.restoring.wireName,
        );
        await expectDeleteRejected(
          VaultTrashTransactionState.restoreConflict.wireName,
        );
        await expectDeleteRejected(
          VaultTrashTransactionState.rollbackRequired.wireName,
        );
        await expectDeleteRejected(
          VaultTrashTransactionState.restored.wireName,
        );
        await expectDeleteRejected('mysteryState');
      },
    );

    group('authoritative manifest reload before mutation', () {
      VaultTrashTransaction baseTx({
        required String stamp,
        required String recordId,
        required String state,
        String? trashRootPath,
      }) {
        return VaultTrashTransaction(
          version: 1,
          transactionId: stamp,
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: recordId,
          state: state,
          createdAt: DateTime.utc(2026, 7, 24),
          trashRootPath: trashRootPath,
          members: [
            VaultTrashMember(
              relativeOriginalPath: 'canvases/$recordId/canvas.md',
              relativeTrashPath: 'canvases/$recordId/canvas.md',
              size: 1,
              sha256: 'a',
            ),
            VaultTrashMember(
              relativeOriginalPath: 'canvases/$recordId/layout.json',
              relativeTrashPath: 'canvases/$recordId/layout.json',
              size: 1,
              sha256: 'b',
            ),
          ],
        );
      }

      void writeDiskManifest(Directory root, Map<String, dynamic> json) {
        File(
          p.join(root.path, 'trash_transaction.json'),
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
      }

      test(
        'caller committed / disk rollbackRequired rejects restore',
        () async {
          final stamp = '2026-07-24T23-00-00-000001z';
          final root = Directory(p.join(tempVault.path, '.trash', stamp))
            ..createSync(recursive: true);
          final disk = baseTx(
            stamp: stamp,
            recordId: 'cv_u_auth0001',
            state: VaultTrashTransactionState.rollbackRequired.wireName,
            trashRootPath: root.path,
          );
          writeDiskManifest(root, disk.toJson());

          final caller = disk.copyWith(
            state: VaultTrashTransactionState.committed.wireName,
          );
          final result = await trashService.restoreCanvasTransaction(caller);
          expect(result.succeeded, isFalse);
          expect(result.errorCode, CanvasRestoreResult.invalidStateErrorCode);
          expect(result.error, contains('rollbackRequired'));
        },
      );

      test(
        'caller committed / disk rollbackRequired rejects permanent delete',
        () async {
          final stamp = '2026-07-24T23-00-00-000002z';
          final root = Directory(p.join(tempVault.path, '.trash', stamp))
            ..createSync(recursive: true);
          File(p.join(root.path, 'marker.txt')).writeAsStringSync('keep');
          final disk = baseTx(
            stamp: stamp,
            recordId: 'cv_u_auth0002',
            state: VaultTrashTransactionState.rollbackRequired.wireName,
            trashRootPath: root.path,
          );
          writeDiskManifest(root, disk.toJson());

          final caller = disk.copyWith(
            state: VaultTrashTransactionState.committed.wireName,
          );
          expect(
            await trashService.deleteTransactionPermanently(caller),
            isFalse,
          );
          expect(root.existsSync(), isTrue);
          expect(File(p.join(root.path, 'marker.txt')).existsSync(), isTrue);
        },
      );

      test('caller committed / disk unknown rejects mutate', () async {
        final stamp = '2026-07-24T23-00-00-000003z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        File(p.join(root.path, 'marker.txt')).writeAsStringSync('keep');
        final disk = baseTx(
          stamp: stamp,
          recordId: 'cv_u_auth0003',
          state: 'totallyUnknown',
          trashRootPath: root.path,
        );
        writeDiskManifest(root, disk.toJson());
        final caller = disk.copyWith(
          state: VaultTrashTransactionState.committed.wireName,
        );

        final restore = await trashService.restoreCanvasTransaction(caller);
        expect(restore.succeeded, isFalse);
        expect(restore.errorCode, CanvasRestoreResult.invalidStateErrorCode);
        expect(
          await trashService.deleteTransactionPermanently(caller),
          isFalse,
        );
        expect(File(p.join(root.path, 'marker.txt')).existsSync(), isTrue);
      });

      test('caller committed / disk missing state rejects mutate', () async {
        final stamp = '2026-07-24T23-00-00-000004z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        File(p.join(root.path, 'marker.txt')).writeAsStringSync('keep');
        final disk = baseTx(
          stamp: stamp,
          recordId: 'cv_u_auth0004',
          state: VaultTrashTransactionState.committed.wireName,
          trashRootPath: root.path,
        );
        final json = Map<String, dynamic>.from(disk.toJson())..remove('state');
        writeDiskManifest(root, json);

        final parsed = VaultTrashTransaction.fromJson(json);
        expect(parsed.state, isEmpty);
        expect(parsed.parsedState, isNull);

        final restore = await trashService.restoreCanvasTransaction(disk);
        expect(restore.succeeded, isFalse);
        expect(restore.errorCode, CanvasRestoreResult.invalidStateErrorCode);
        expect(await trashService.deleteTransactionPermanently(disk), isFalse);
        expect(File(p.join(root.path, 'marker.txt')).existsSync(), isTrue);
      });

      test('caller/disk identity mismatch rejects mutate', () async {
        final stamp = '2026-07-24T23-00-00-000005z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final disk = baseTx(
          stamp: stamp,
          recordId: 'cv_u_auth0005',
          state: VaultTrashTransactionState.committed.wireName,
          trashRootPath: root.path,
        );
        writeDiskManifest(root, disk.toJson());

        final wrongRecord = VaultTrashTransaction(
          version: disk.version,
          transactionId: disk.transactionId,
          vaultPath: disk.vaultPath,
          recordKind: disk.recordKind,
          recordId: 'cv_u_other005',
          state: disk.state,
          createdAt: disk.createdAt,
          members: disk.members,
          trashRootPath: disk.trashRootPath,
        );
        final restoreWrongRecord = await trashService.restoreCanvasTransaction(
          wrongRecord,
        );
        expect(restoreWrongRecord.succeeded, isFalse);
        expect(
          restoreWrongRecord.errorCode,
          CanvasRestoreResult.invalidStateErrorCode,
        );
        expect(
          await trashService.deleteTransactionPermanently(wrongRecord),
          isFalse,
        );

        final wrongStamp = '2026-07-24T23-00-00-000099z';
        final wrongRoot = Directory(
          p.join(tempVault.path, '.trash', wrongStamp),
        )..createSync(recursive: true);
        writeDiskManifest(wrongRoot, disk.toJson());
        final wrongIdCaller = VaultTrashTransaction(
          version: disk.version,
          transactionId: wrongStamp,
          vaultPath: disk.vaultPath,
          recordKind: disk.recordKind,
          recordId: disk.recordId,
          state: disk.state,
          createdAt: disk.createdAt,
          members: disk.members,
          trashRootPath: wrongRoot.path,
        );
        final restoreWrongId = await trashService.restoreCanvasTransaction(
          wrongIdCaller,
        );
        expect(restoreWrongId.succeeded, isFalse);
        expect(
          restoreWrongId.errorCode,
          CanvasRestoreResult.invalidStateErrorCode,
        );
      });

      test('fromJson never promotes missing/empty/unknown to committed', () {
        expect(
          VaultTrashTransaction.fromJson({
            'transactionId': 't',
            'vaultPath': '/v',
            'recordKind': 'canvas',
            'recordId': 'cv_u_auth0006',
            'createdAt': '2026-07-24T00:00:00.000Z',
            'members': [],
          }).state,
          isEmpty,
        );
        expect(
          VaultTrashTransaction.fromJson({
            'transactionId': 't',
            'vaultPath': '/v',
            'recordKind': 'canvas',
            'recordId': 'cv_u_auth0006',
            'state': '',
            'createdAt': '2026-07-24T00:00:00.000Z',
            'members': [],
          }).parsedState,
          isNull,
        );
        expect(
          VaultTrashTransaction.fromJson({
            'transactionId': 't',
            'vaultPath': '/v',
            'recordKind': 'canvas',
            'recordId': 'cv_u_auth0006',
            'state': 'notARealState',
            'createdAt': '2026-07-24T00:00:00.000Z',
            'members': [],
          }).parsedState,
          isNull,
        );
      });

      test('incomplete state manifests are not treated as complete', () {
        final stamp = '2026-07-24T23-00-00-000007z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final good = baseTx(
          stamp: stamp,
          recordId: 'cv_u_auth0007',
          state: VaultTrashTransactionState.committed.wireName,
        );

        bool promotesFromNext(Map<String, dynamic> payload) {
          final next = File(
            p.join(root.path, VaultTrashTransactionManifestStore.nextName),
          );
          final primary = File(
            p.join(root.path, VaultTrashTransactionManifestStore.primaryName),
          );
          if (primary.existsSync()) primary.deleteSync();
          if (next.existsSync()) next.deleteSync();
          next.writeAsStringSync(jsonEncode(payload));
          final store = VaultTrashTransactionManifestStore()..converge(root);
          return primary.existsSync() && store.read(root)?.parsedState != null;
        }

        final missing = Map<String, dynamic>.from(good.toJson())
          ..remove('state');
        final unknown = Map<String, dynamic>.from(good.toJson())
          ..['state'] = 'nope';
        final empty = Map<String, dynamic>.from(good.toJson())..['state'] = '';

        expect(promotesFromNext(missing), isFalse);
        expect(promotesFromNext(unknown), isFalse);
        expect(promotesFromNext(empty), isFalse);
        expect(promotesFromNext(good.toJson()), isTrue);
      });
    });

    group('recoverable transaction manifest writes', () {
      VaultTrashTransaction sampleTx(String vaultPath, String stamp) {
        return VaultTrashTransaction(
          version: 1,
          transactionId: stamp,
          vaultPath: vaultPath,
          recordKind: 'canvas',
          recordId: 'cv_u_manif001',
          state: VaultTrashTransactionState.committed.wireName,
          createdAt: DateTime.utc(2026, 7, 24),
          members: [
            VaultTrashMember(
              relativeOriginalPath: 'canvases/cv_u_manif001/canvas.md',
              relativeTrashPath: 'canvases/cv_u_manif001/canvas.md',
              size: 1,
              sha256: 'a',
            ),
            VaultTrashMember(
              relativeOriginalPath: 'canvases/cv_u_manif001/layout.json',
              relativeTrashPath: 'canvases/cv_u_manif001/layout.json',
              size: 1,
              sha256: 'b',
            ),
          ],
        );
      }

      bool hasCompletePrimaryOrPrevious(Directory root) {
        final store = VaultTrashTransactionManifestStore();
        store.converge(root);
        final primary = File(
          p.join(root.path, VaultTrashTransactionManifestStore.primaryName),
        );
        final previous = File(
          p.join(root.path, VaultTrashTransactionManifestStore.previousName),
        );
        final next = File(
          p.join(root.path, VaultTrashTransactionManifestStore.nextName),
        );
        bool complete(File f) {
          if (!f.existsSync()) return false;
          try {
            final decoded = jsonDecode(f.readAsStringSync());
            if (decoded is! Map<String, dynamic>) return false;
            final tx = VaultTrashTransaction.fromJson(decoded);
            return tx.transactionId.isNotEmpty &&
                tx.members.isNotEmpty &&
                tx.parsedState != null;
          } catch (_) {
            return false;
          }
        }

        return complete(primary) || complete(previous) || complete(next);
      }

      test('fault before temp write leaves prior complete manifest', () async {
        final stamp = '2026-07-24T22-00-00-000001z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final baseline = sampleTx(tempVault.path, stamp);
        await VaultTrashTransactionManifestStore().write(root, baseline);

        final failing = VaultTrashTransactionManifestStore(
          faultInjector: (checkpoint) async {
            if (checkpoint ==
                TrashTransactionManifestCheckpoint.beforeTempWrite) {
              throw StateError('injected beforeTempWrite');
            }
          },
        );
        await expectLater(
          failing.write(
            root,
            baseline.copyWith(
              state: VaultTrashTransactionState.moving.wireName,
            ),
          ),
          throwsA(isA<StateError>()),
        );
        expect(hasCompletePrimaryOrPrevious(root), isTrue);
        final read = VaultTrashTransactionManifestStore().read(root);
        expect(read?.state, VaultTrashTransactionState.committed.wireName);
      });

      test('fault after temp before promote keeps prior or next', () async {
        final stamp = '2026-07-24T22-00-00-000002z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final baseline = sampleTx(tempVault.path, stamp);
        await VaultTrashTransactionManifestStore().write(root, baseline);

        final failing = VaultTrashTransactionManifestStore(
          faultInjector: (checkpoint) async {
            if (checkpoint ==
                TrashTransactionManifestCheckpoint.afterTempBeforePromote) {
              throw StateError('injected afterTemp');
            }
          },
        );
        await expectLater(
          failing.write(
            root,
            baseline.copyWith(
              state: VaultTrashTransactionState.restoring.wireName,
            ),
          ),
          throwsA(isA<StateError>()),
        );
        expect(hasCompletePrimaryOrPrevious(root), isTrue);
      });

      test(
        'fault after previous before promote keeps previous or next',
        () async {
          final stamp = '2026-07-24T22-00-00-000003z';
          final root = Directory(p.join(tempVault.path, '.trash', stamp))
            ..createSync(recursive: true);
          final baseline = sampleTx(tempVault.path, stamp);
          await VaultTrashTransactionManifestStore().write(root, baseline);

          final failing = VaultTrashTransactionManifestStore(
            faultInjector: (checkpoint) async {
              if (checkpoint ==
                  TrashTransactionManifestCheckpoint
                      .afterPreviousBeforePromote) {
                throw StateError('injected afterPrevious');
              }
            },
          );
          await expectLater(
            failing.write(
              root,
              baseline.copyWith(
                state: VaultTrashTransactionState.prepared.wireName,
              ),
            ),
            throwsA(isA<StateError>()),
          );
          expect(hasCompletePrimaryOrPrevious(root), isTrue);
        },
      );

      test(
        'fault after promote before verify still has complete primary',
        () async {
          final stamp = '2026-07-24T22-00-00-000004z';
          final root = Directory(p.join(tempVault.path, '.trash', stamp))
            ..createSync(recursive: true);
          final baseline = sampleTx(tempVault.path, stamp);
          await VaultTrashTransactionManifestStore().write(root, baseline);

          final failing = VaultTrashTransactionManifestStore(
            faultInjector: (checkpoint) async {
              if (checkpoint ==
                  TrashTransactionManifestCheckpoint.afterPromoteBeforeVerify) {
                throw StateError('injected afterPromote');
              }
            },
          );
          await expectLater(
            failing.write(
              root,
              baseline.copyWith(
                state: VaultTrashTransactionState.moving.wireName,
              ),
            ),
            throwsA(isA<StateError>()),
          );
          expect(hasCompletePrimaryOrPrevious(root), isTrue);
        },
      );

      test('converge discards corrupt .next and keeps primary', () {
        final stamp = '2026-07-24T22-00-00-000005z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final baseline = sampleTx(tempVault.path, stamp);
        File(
          p.join(root.path, VaultTrashTransactionManifestStore.primaryName),
        ).writeAsStringSync(jsonEncode(baseline.toJson()));
        File(
          p.join(root.path, VaultTrashTransactionManifestStore.nextName),
        ).writeAsStringSync('{not-json');

        final store = VaultTrashTransactionManifestStore()..converge(root);
        expect(hasCompletePrimaryOrPrevious(root), isTrue);
        expect(store.read(root)?.transactionId, stamp);
        expect(
          File(
            p.join(root.path, VaultTrashTransactionManifestStore.nextName),
          ).existsSync(),
          isFalse,
        );
      });

      test('converge promotes previous when primary is corrupt', () {
        final stamp = '2026-07-24T22-00-00-000006z';
        final root = Directory(p.join(tempVault.path, '.trash', stamp))
          ..createSync(recursive: true);
        final baseline = sampleTx(tempVault.path, stamp);
        File(
          p.join(root.path, VaultTrashTransactionManifestStore.primaryName),
        ).writeAsStringSync('{broken');
        File(
          p.join(root.path, VaultTrashTransactionManifestStore.previousName),
        ).writeAsStringSync(jsonEncode(baseline.toJson()));

        final store = VaultTrashTransactionManifestStore()..converge(root);
        expect(store.read(root)?.transactionId, stamp);
        expect(hasCompletePrimaryOrPrevious(root), isTrue);
      });
    });
  });
}

extension on VaultTrashTransaction {
  VaultTrashTransaction copyWith({String? state}) {
    return VaultTrashTransaction(
      version: version,
      transactionId: transactionId,
      vaultPath: vaultPath,
      recordKind: recordKind,
      recordId: recordId,
      title: title,
      reason: reason,
      state: state ?? this.state,
      createdAt: createdAt,
      members: members,
      trashRootPath: trashRootPath,
    );
  }
}
