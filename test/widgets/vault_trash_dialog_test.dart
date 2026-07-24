import 'dart:convert';
import 'dart:io';

import 'package:akasha/screens/home/dialogs/vault_trash_dialog.dart';
import 'package:akasha/services/canvas_store.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('VaultTrashDialog Widget Tests', () {
    late Directory tempVault;

    setUp(() async {
      tempVault = await Directory.systemTemp.createTemp(
        'vault_trash_dialog_test',
      );
    });

    tearDown(() async {
      if (tempVault.existsSync()) {
        await tempVault.delete(recursive: true);
      }
    });

    testWidgets('renders legacy entry and composite transaction items', (
      tester,
    ) async {
      // 1. Create a legacy trash entry
      final legacyFile = File(
        p.join(tempVault.path, '.trash', 'stamp1', 'works', 'wk_legacy.md'),
      );
      await legacyFile.parent.create(recursive: true);
      await legacyFile.writeAsString('# Legacy Work');

      final legacyEntry = VaultTrashEntry(
        vaultPath: tempVault.path,
        originalPath: p.join(tempVault.path, 'works', 'wk_legacy.md'),
        trashPath: legacyFile.path,
        trashedAt: DateTime.now().toUtc(),
      );
      final legacyManifest = File(
        p.join(tempVault.path, '.trash', 'stamp1', 'trash_entry.json'),
      );
      await legacyManifest.writeAsString(jsonEncode(legacyEntry.toJson()));

      // 2. Create a composite canvas transaction
      final canvasData = await CanvasStore.instance.createCanvas(
        vaultPath: tempVault.path,
        title: 'Composite Trash Canvas',
        slug: 'composite-trash',
      );
      final canvasId = canvasData.record.canvasId;
      final trashRes = await CanvasStore.instance.deleteCanvas(
        tempVault.path,
        canvasId,
      );
      expect(trashRes.succeeded, isTrue);

      // Render dialog
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify dialog renders both items
      expect(find.text('Vault 휴지통'), findsOneWidget);
      expect(find.text('wk_legacy.md'), findsOneWidget);
      expect(find.text('Composite Trash Canvas'), findsOneWidget);

      // Tap restore on composite canvas
      final restoreButtons = find.text('복구');
      expect(restoreButtons, findsNWidgets(2));

      await tester.tap(restoreButtons.at(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Canvas should be restored to active canvases dir
      final activeCanvasMd = File(
        p.join(tempVault.path, 'canvases', canvasId, 'canvas.md'),
      );
      expect(activeCanvasMd.existsSync(), isTrue);
    });
  });
}
