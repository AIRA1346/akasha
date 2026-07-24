import 'package:akasha/screens/home/dialogs/vault_trash_dialog.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (tester.any(finder)) return;
  }
  fail('Finder not found after $maxPumps pumps: $finder');
}

class _RecordingTrashService extends VaultTrashService {
  _RecordingTrashService({
    List<VaultTrashEntry>? legacy,
    List<VaultTrashTransaction>? transactions,
  }) : legacy = List<VaultTrashEntry>.from(legacy ?? const []),
       transactions = List<VaultTrashTransaction>.from(
         transactions ?? const [],
       );

  final List<VaultTrashEntry> legacy;
  final List<VaultTrashTransaction> transactions;

  int restoreCalls = 0;
  int deleteCalls = 0;
  VaultTrashTransaction? lastRestored;
  VaultTrashTransaction? lastDeleted;
  CanvasRestoreResult restoreResult = const CanvasRestoreResult(
    succeeded: true,
  );
  bool deleteResult = true;

  @override
  Future<List<VaultTrashEntry>> listEntries({required String vaultPath}) async {
    return List<VaultTrashEntry>.from(legacy);
  }

  @override
  Future<List<VaultTrashTransaction>> listTransactions({
    required String vaultPath,
  }) async {
    return List<VaultTrashTransaction>.from(transactions);
  }

  @override
  Future<CanvasRestoreResult> restoreCanvasTransaction(
    VaultTrashTransaction transaction,
  ) async {
    restoreCalls++;
    lastRestored = transaction;
    if (restoreResult.succeeded) {
      transactions.removeWhere(
        (tx) => tx.transactionId == transaction.transactionId,
      );
    }
    return restoreResult;
  }

  @override
  Future<bool> deleteTransactionPermanently(
    VaultTrashTransaction transaction,
  ) async {
    deleteCalls++;
    lastDeleted = transaction;
    if (deleteResult) {
      transactions.removeWhere(
        (tx) => tx.transactionId == transaction.transactionId,
      );
    }
    return deleteResult;
  }
}

VaultTrashTransaction _sampleTx({
  required String vaultPath,
  required String canvasId,
  required String title,
  required String stamp,
  String state = 'committed',
}) {
  return VaultTrashTransaction(
    version: 1,
    transactionId: stamp,
    vaultPath: vaultPath,
    recordKind: 'canvas',
    recordId: canvasId,
    title: title,
    state: state,
    createdAt: DateTime.utc(2026, 7, 24, 10),
    trashRootPath: p.join(vaultPath, '.trash', stamp),
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
}

void main() {
  group('VaultTrashDialog Widget Tests', () {
    testWidgets(
      'restore button tap invokes service callback, snackbar, and refresh',
      (tester) async {
        const canvasId = 'cv_u_widget01';
        var onRestoredCalls = 0;
        final service = _RecordingTrashService(
          legacy: [
            VaultTrashEntry(
              vaultPath: r'C:\tmp\vault',
              originalPath: r'C:\tmp\vault\works\wk_legacy.md',
              trashPath: r'C:\tmp\vault\.trash\stamp1\works\wk_legacy.md',
              trashedAt: DateTime.utc(2026, 7, 24, 9),
            ),
          ],
          transactions: [
            _sampleTx(
              vaultPath: r'C:\tmp\vault',
              canvasId: canvasId,
              title: 'Composite Trash Canvas',
              stamp: '2026-07-24T10-00-00-000000z',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showVaultTrashDialog(
                    context,
                    vaultPath: r'C:\tmp\vault',
                    trashService: service,
                    onRestored: () async {
                      onRestoredCalls++;
                    },
                  ),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('Composite Trash Canvas'));
        expect(find.text('wk_legacy.md'), findsOneWidget);

        await tester.tap(
          find.byKey(ValueKey<String>('trash-restore-canvas-$canvasId')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(service.restoreCalls, 1);
        expect(service.lastRestored?.recordId, canvasId);
        expect(onRestoredCalls, 1);
        await pumpUntilFound(
          tester,
          find.textContaining('지식 지도 「Composite Trash Canvas」'),
        );
        await pumpUntilFound(tester, find.text('wk_legacy.md'));
        expect(find.text('Composite Trash Canvas'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'permanent delete tap shows confirm dialog then deletes via service',
      (tester) async {
        const canvasId = 'cv_u_delete01';
        final service = _RecordingTrashService(
          transactions: [
            _sampleTx(
              vaultPath: r'C:\tmp\vault',
              canvasId: canvasId,
              title: 'Canvas To Delete',
              stamp: '2026-07-24T11-00-00-000000z',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showVaultTrashDialog(
                    context,
                    vaultPath: r'C:\tmp\vault',
                    trashService: service,
                  ),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('Canvas To Delete'));

        await tester.tap(
          find.byKey(ValueKey<String>('trash-delete-canvas-$canvasId')),
        );
        await pumpUntilFound(tester, find.textContaining('휴지통에서도 영구 삭제할까요'));

        // Confirm in the nested dialog (second 영구 삭제 button).
        await tester.tap(find.text('영구 삭제').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(service.deleteCalls, 1);
        expect(service.lastDeleted?.recordId, canvasId);
        await pumpUntilFound(tester, find.text('휴지통에서 영구 삭제했습니다.'));
        await pumpUntilFound(tester, find.text('휴지통이 비어 있습니다.'));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'restoreConflict path surfaces snackbar from service error',
      (tester) async {
        const canvasId = 'cv_u_conflc01';
        final service =
            _RecordingTrashService(
                transactions: [
                  _sampleTx(
                    vaultPath: r'C:\tmp\vault',
                    canvasId: canvasId,
                    title: 'Conflict Canvas',
                    stamp: '2026-07-24T12-00-00-000000z',
                  ),
                ],
              )
              ..restoreResult = const CanvasRestoreResult(
                succeeded: false,
                state: 'restoreConflict',
                error: 'restoreConflict: original already exists',
              );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showVaultTrashDialog(
                    context,
                    vaultPath: r'C:\tmp\vault',
                    trashService: service,
                  ),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('Conflict Canvas'));
        await tester.tap(
          find.byKey(ValueKey<String>('trash-restore-canvas-$canvasId')),
        );
        await tester.pump();
        await pumpUntilFound(
          tester,
          find.text('restoreConflict: original already exists'),
        );
        expect(service.restoreCalls, 1);
        expect(find.text('Conflict Canvas'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'hides restore and delete buttons for rollbackRequired unsafe transaction',
      (tester) async {
        const canvasId = 'cv_u_unsafe01';
        final service = _RecordingTrashService(
          transactions: [
            _sampleTx(
              vaultPath: r'C:\tmp\vault',
              canvasId: canvasId,
              title: 'Unsafe Canvas',
              stamp: '2026-07-24T13-00-00-000000z',
              state: VaultTrashTransactionState.rollbackRequired.wireName,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showVaultTrashDialog(
                    context,
                    vaultPath: r'C:\tmp\vault',
                    trashService: service,
                  ),
                  child: const Text('Open Trash'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Trash'));
        await pumpUntilFound(tester, find.text('Unsafe Canvas'));

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
