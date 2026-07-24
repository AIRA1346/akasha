import 'dart:convert';
import 'dart:io';

import 'package:akasha/services/canvas_store.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Canvas Composite Lifecycle & Guard Tests', () {
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

      // Attempting to trash canvas.md independently throws ArgumentError
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

      // Attempting to trash layout.json independently throws ArgumentError
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

      // Verify files still exist intact
      expect(File(canvasMdPath).existsSync(), isTrue);
      expect(File(layoutJsonPath).existsSync(), isTrue);
    });

    test(
      'Single-file moveFileToTrash still works for regular work/entity files',
      () async {
        final workFile = File(
          p.join(tempVault.path, 'works', 'book', 'wk_test.md'),
        );
        await workFile.parent.create(recursive: true);
        await workFile.writeAsString('# Test Work File');

        final entry = await trashService.moveFileToTrash(
          vaultPath: tempVault.path,
          absolutePath: workFile.path,
        );

        expect(entry, isNotNull);
        expect(workFile.existsSync(), isFalse);
        expect(File(entry!.trashPath).existsSync(), isTrue);
      },
    );

    test(
      'Composite moveCanvasToTrash and restoreCanvasTransaction round-trip',
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

        // Trash canvas as composite
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
        expect(tx.title, equals('Composite Trash Test'));
        expect(tx.members.length, equals(2));

        // Restore transaction
        final restoreResult = await trashService.restoreCanvasTransaction(tx);
        expect(restoreResult.succeeded, isTrue);

        expect(canvasDir.existsSync(), isTrue);
        expect(mdFile.existsSync(), isTrue);
        expect(jsonFile.existsSync(), isTrue);

        final reloaded = await canvasStore.loadCanvas(tempVault.path, canvasId);
        expect(reloaded, isNotNull);
        expect(reloaded!.record.title, equals('Composite Trash Test'));
      },
    );

    test(
      'restoreCanvasTransaction fails if collision occurs and overwrite is false',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Collision Test',
          slug: 'collision-test',
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

        // Re-create a conflicting canvas.md at original location
        await mdFile.parent.create(recursive: true);
        await mdFile.writeAsString('# Conflict file');

        final restoreResult = await trashService.restoreCanvasTransaction(
          trashResult.transaction!,
          overwrite: false,
        );

        expect(restoreResult.succeeded, isFalse);
        expect(restoreResult.error, contains('Original file already exists'));

        // Restore with overwrite=true succeeds
        final forceRestoreResult = await trashService.restoreCanvasTransaction(
          trashResult.transaction!,
          overwrite: true,
        );
        expect(forceRestoreResult.succeeded, isTrue);
      },
    );

    test('restoreCanvasTransaction rejects tampered SHA-256 files', () async {
      final canvasData = await canvasStore.createCanvas(
        vaultPath: tempVault.path,
        title: 'Tamper Hash Test',
        slug: 'tamper-hash',
      );
      final canvasId = canvasData.record.canvasId;

      final trashResult = await canvasStore.deleteCanvas(
        tempVault.path,
        canvasId,
      );
      expect(trashResult.succeeded, isTrue);

      // Tamper with the trashed canvas.md content
      final tx = trashResult.transaction!;
      final trashedMdFile = File(
        p.join(tx.trashRootPath!, tx.members.first.relativeTrashPath),
      );
      await trashedMdFile.writeAsString('Tampered content');

      final restoreResult = await trashService.restoreCanvasTransaction(tx);
      expect(restoreResult.succeeded, isFalse);
      expect(restoreResult.error, contains('SHA-256 hash mismatch'));
    });

    test(
      'Structured discoverCanvases reports complete and incomplete canvas states',
      () async {
        // 1. Create a complete canvas
        final c1 = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Complete Map',
          slug: 'complete-map',
        );

        // 2. Create missing metadata canvas
        final missingMdDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_no_md'),
        );
        await missingMdDir.create(recursive: true);
        await File(
          p.join(missingMdDir.path, 'layout.json'),
        ).writeAsString('{"canvas_id": "cv_u_no_md"}');

        // 3. Create missing layout canvas
        final missingLayoutDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_no_layout'),
        );
        await missingLayoutDir.create(recursive: true);
        await File(p.join(missingLayoutDir.path, 'canvas.md')).writeAsString(
          '''---
document_kind: "canvas"
canvas_id: "cv_u_no_layout"
slug: "no-layout"
title: "No Layout"
layout_ref: "./layout.json"
---
''',
        );

        // 4. Create ID mismatch canvas
        final mismatchDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_mismatch'),
        );
        await mismatchDir.create(recursive: true);
        await File(p.join(mismatchDir.path, 'canvas.md')).writeAsString('''---
document_kind: "canvas"
canvas_id: "cv_u_wrong_id"
slug: "wrong-id"
title: "Wrong ID"
layout_ref: "./layout.json"
---
''');
        await File(
          p.join(mismatchDir.path, 'layout.json'),
        ).writeAsString('{"canvas_id": "cv_u_mismatch"}');

        final discovery = await canvasStore.discoverCanvases(tempVault.path);

        expect(discovery.complete.length, equals(1));
        expect(discovery.complete.first.canvasId, equals(c1.record.canvasId));

        expect(discovery.incomplete.length, equals(3));

        final noMd = discovery.incomplete.firstWhere(
          (i) => i.inferredCanvasId == 'cv_u_no_md',
        );
        expect(noMd.status, equals(IncompleteCanvasStatus.missingMetadata));
        expect(noMd.missingFiles, contains('canvas.md'));

        final noLayout = discovery.incomplete.firstWhere(
          (i) => i.inferredCanvasId == 'cv_u_no_layout',
        );
        expect(noLayout.status, equals(IncompleteCanvasStatus.missingLayout));
        expect(noLayout.missingFiles, contains('layout.json'));

        final idMismatch = discovery.incomplete.firstWhere(
          (i) => i.inferredCanvasId == 'cv_u_mismatch',
        );
        expect(idMismatch.status, equals(IncompleteCanvasStatus.idMismatch));
      },
    );

    test(
      'Legacy single-file trash entry remains backward compatible',
      () async {
        // Simulate historical legacy single-file canvas.md in trash
        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-20T13-34-08-173940z'),
        );
        final trashCanvasMd = File(
          p.join(trashStampDir.path, 'canvases', 'cv_u_legacy', 'canvas.md'),
        );
        await trashCanvasMd.parent.create(recursive: true);
        await trashCanvasMd.writeAsString('''---
document_kind: "canvas"
canvas_id: "cv_u_legacy"
slug: "legacy"
title: "Legacy Canvas"
layout_ref: "./layout.json"
---
''');

        final entryJsonFile = File(
          p.join(trashStampDir.path, 'trash_entry.json'),
        );
        final entry = VaultTrashEntry(
          vaultPath: tempVault.path,
          originalPath: p.join(
            tempVault.path,
            'canvases',
            'cv_u_legacy',
            'canvas.md',
          ),
          trashPath: trashCanvasMd.path,
          trashedAt: DateTime.now().toUtc(),
        );
        await entryJsonFile.writeAsString(jsonEncode(entry.toJson()));

        // listEntries finds legacy entry
        final entries = await trashService.listEntries(
          vaultPath: tempVault.path,
        );
        expect(entries.length, equals(1));
        expect(entries.first.originalFileName, equals('canvas.md'));

        // restoreFile restores legacy single-file
        final restored = await trashService.restoreFile(entries.first);
        expect(restored, isTrue);
        expect(
          File(
            p.join(tempVault.path, 'canvases', 'cv_u_legacy', 'canvas.md'),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'recoverPendingTrashTransactions cleans up prepared interrupted state',
      () async {
        final canvasData = await canvasStore.createCanvas(
          vaultPath: tempVault.path,
          title: 'Interrupted Prepared',
          slug: 'interrupted-prepared',
        );
        final canvasId = canvasData.record.canvasId;

        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T00-00-00-000000z'),
        );
        await trashStampDir.create(recursive: true);

        final preparedTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T00-00-00-000000z',
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
          ],
        );
        final manifestFile = File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        );
        await manifestFile.writeAsString(jsonEncode(preparedTx.toJson()));

        final recovered = await trashService.recoverPendingTrashTransactions(
          vaultPath: tempVault.path,
        );
        expect(recovered, contains('2026-07-24T00-00-00-000000z'));
        expect(trashStampDir.existsSync(), isFalse);
      },
    );
  });
}
