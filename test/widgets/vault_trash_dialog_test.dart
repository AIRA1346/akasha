import 'dart:convert';
import 'dart:io';

import 'package:akasha/screens/home/dialogs/vault_trash_dialog.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (tester.any(finder)) return;
  }
  fail('Finder not found after $maxPumps pumps: $finder');
}

void main() {
  group('VaultTrashDialog Widget Tests', () {
    late Directory tempVault;
    final trash = const VaultTrashService();

    setUp(() {
      tempVault = Directory.systemTemp.createTempSync(
        'vault_trash_dialog_test',
      );
    });

    tearDown(() {
      if (tempVault.existsSync()) {
        tempVault.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'renders legacy entry and composite transaction items, restores canvas via Key',
      (tester) async {
        final legacyFile = File(
          p.join(tempVault.path, '.trash', 'stamp1', 'works', 'wk_legacy.md'),
        );
        legacyFile.parent.createSync(recursive: true);
        legacyFile.writeAsStringSync('# Legacy Work');

        final legacyEntry = VaultTrashEntry(
          vaultPath: tempVault.path,
          originalPath: p.join(tempVault.path, 'works', 'wk_legacy.md'),
          trashPath: legacyFile.path,
          trashedAt: DateTime.now().toUtc(),
        );
        File(
          p.join(tempVault.path, '.trash', 'stamp1', 'trash_entry.json'),
        ).writeAsStringSync(jsonEncode(legacyEntry.toJson()));

        final canvasId = 'cv_u_widget_test';
        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T10-00-00-000000z'),
        );
        final trashCanvasDir = Directory(
          p.join(trashStampDir.path, 'canvases', canvasId),
        );
        trashCanvasDir.createSync(recursive: true);

        final mdFile = File(p.join(trashCanvasDir.path, 'canvas.md'));
        final jsonFile = File(p.join(trashCanvasDir.path, 'layout.json'));
        mdFile.writeAsStringSync(
          '---\ndocument_kind: canvas\ncanvas_id: $canvasId\n---\n',
        );
        jsonFile.writeAsStringSync('{"canvas_id": "$canvasId", "nodes": []}');

        final mdBytes = mdFile.readAsBytesSync();
        final jsonBytes = jsonFile.readAsBytesSync();

        final compositeTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T10-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          title: 'Composite Trash Canvas',
          state: VaultTrashTransactionState.committed.wireName,
          createdAt: DateTime.now().toUtc(),
          trashRootPath: trashStampDir.path,
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
        File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        ).writeAsStringSync(jsonEncode(compositeTx.toJson()));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      showVaultTrashDialog(context, vaultPath: tempVault.path),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('wk_legacy.md'));
        expect(find.text('Vault 휴지통'), findsOneWidget);

        expect(find.text('wk_legacy.md'), findsOneWidget);
        expect(find.text('Composite Trash Canvas'), findsOneWidget);
        expect(find.textContaining(canvasId), findsOneWidget);

        final restoreCanvasKey = find.byKey(
          ValueKey<String>('trash-restore-canvas-$canvasId'),
        );
        expect(restoreCanvasKey, findsOneWidget);
        expect(
          tester.widget<TextButton>(restoreCanvasKey).onPressed,
          isNotNull,
        );

        // Restore outside FakeAsync (sync FS path); then refresh dialog list.
        final restoreResult = trash.restoreCanvasTransaction(compositeTx);
        await tester.pump();
        expect((await restoreResult).succeeded, isTrue);

        await tester.tap(find.text('새로고침'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          File(
            p.join(tempVault.path, 'canvases', canvasId, 'canvas.md'),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            p.join(tempVault.path, 'canvases', canvasId, 'layout.json'),
          ).existsSync(),
          isTrue,
        );
        expect(find.text('Composite Trash Canvas'), findsNothing);
        expect(find.text('wk_legacy.md'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'permanently deletes composite transaction via Key',
      (tester) async {
        final canvasId = 'cv_u_del_test';
        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T11-00-00-000000z'),
        );
        final trashCanvasDir = Directory(
          p.join(trashStampDir.path, 'canvases', canvasId),
        );
        trashCanvasDir.createSync(recursive: true);

        final mdFile = File(p.join(trashCanvasDir.path, 'canvas.md'));
        final jsonFile = File(p.join(trashCanvasDir.path, 'layout.json'));
        mdFile.writeAsStringSync(
          '---\ndocument_kind: canvas\ncanvas_id: $canvasId\n---\n',
        );
        jsonFile.writeAsStringSync('{"canvas_id": "$canvasId", "nodes": []}');

        final mdBytes = mdFile.readAsBytesSync();
        final jsonBytes = jsonFile.readAsBytesSync();

        final compositeTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T11-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          title: 'Canvas To Delete',
          state: VaultTrashTransactionState.committed.wireName,
          createdAt: DateTime.now().toUtc(),
          trashRootPath: trashStampDir.path,
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
        File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        ).writeAsStringSync(jsonEncode(compositeTx.toJson()));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      showVaultTrashDialog(context, vaultPath: tempVault.path),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('Canvas To Delete'));

        final deleteKey = find.byKey(
          ValueKey<String>('trash-delete-canvas-$canvasId'),
        );
        expect(deleteKey, findsOneWidget);
        expect(tester.widget<TextButton>(deleteKey).onPressed, isNotNull);

        final deleteFuture = trash.deleteTransactionPermanently(compositeTx);
        await tester.pump();
        expect(await deleteFuture, isTrue);

        await tester.tap(find.text('새로고침'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('Canvas To Delete'), findsNothing);
        expect(find.text('휴지통이 비어 있습니다.'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'hides restore and delete buttons for rollbackRequired unsafe transaction',
      (tester) async {
        final canvasId = 'cv_u_unsafe';
        final trashStampDir = Directory(
          p.join(tempVault.path, '.trash', '2026-07-24T12-00-00-000000z'),
        );
        trashStampDir.createSync(recursive: true);

        final rollbackTx = VaultTrashTransaction(
          version: 1,
          transactionId: '2026-07-24T12-00-00-000000z',
          vaultPath: tempVault.path,
          recordKind: 'canvas',
          recordId: canvasId,
          title: 'Unsafe Canvas',
          state: VaultTrashTransactionState.rollbackRequired.wireName,
          createdAt: DateTime.now().toUtc(),
          members: [
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'canvas.md'),
              relativeTrashPath: p.join('canvases', canvasId, 'canvas.md'),
              size: 10,
              sha256: 'abc',
            ),
            VaultTrashMember(
              relativeOriginalPath: p.join('canvases', canvasId, 'layout.json'),
              relativeTrashPath: p.join('canvases', canvasId, 'layout.json'),
              size: 10,
              sha256: 'def',
            ),
          ],
        );
        File(
          p.join(trashStampDir.path, 'trash_transaction.json'),
        ).writeAsStringSync(jsonEncode(rollbackTx.toJson()));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      showVaultTrashDialog(context, vaultPath: tempVault.path),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('Unsafe Canvas'));

        expect(find.text('Unsafe Canvas'), findsOneWidget);
        expect(find.textContaining('rollbackRequired'), findsWidgets);
        expect(
          find.textContaining('안전한 자동 복구/영구삭제가 제한된 항목입니다'),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey<String>('trash-restore-canvas-$canvasId')),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey<String>('trash-delete-canvas-$canvasId')),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
