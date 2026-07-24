import 'dart:convert';
import 'dart:io';

import 'package:akasha/services/canvas_store.dart';
import 'package:akasha/services/vault_trash_service.dart';
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
      'Composite moveCanvasToTrash rejects extra unexpected files in canvas folder',
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
        await extraFile.writeAsString('unexpected extra content');

        final trashResult = await canvasStore.deleteCanvas(
          tempVault.path,
          canvasId,
        );
        expect(trashResult.succeeded, isFalse);
        expect(trashResult.error, contains('unexpected extra files'));
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
        expect(tx.state, equals('committed'));

        final restoreResult = await trashService.restoreCanvasTransaction(tx);
        expect(restoreResult.succeeded, isTrue);
        expect(restoreResult.state, equals('restored'));

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
        final badTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T00-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: 'cv_u_hacker',
          state: 'committed',
          createdAt: DateTime.now().toUtc(),
          members: [
            VaultTrashMember(
              relativeOriginalPath: '../outside/canvas.md',
              relativeTrashPath: 'canvases/cv_u_hacker/canvas.md',
              size: 10,
              sha256: 'abc',
            ),
            VaultTrashMember(
              relativeOriginalPath: 'canvases/cv_u_hacker/layout.json',
              relativeTrashPath: 'canvases/cv_u_hacker/layout.json',
              size: 10,
              sha256: 'def',
            ),
          ],
        );

        final restoreResult = await trashService.restoreCanvasTransaction(
          badTx,
        );
        expect(restoreResult.succeeded, isFalse);
        expect(
          restoreResult.error,
          anyOf(
            contains('Path traversal or absolute path detected'),
            contains('Transaction member original paths must match canonical'),
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
          state: 'prepared',
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

        final movingTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T11-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          state: 'moving',
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
        expect(recoveredTx.state, equals('committed'));
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
          state: 'restoring',
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
        final canvasId = 'cv_u_partial';
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
          state: 'prepared',
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
        expect(updatedManifest['state'], equals('rollbackRequired'));
      },
    );
  });
}
