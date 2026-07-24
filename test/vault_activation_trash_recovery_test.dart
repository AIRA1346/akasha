import 'dart:convert';
import 'dart:io';

import 'package:akasha/services/canvas_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempVault;
  final canvasStore = CanvasStore.instance;
  final trash = const VaultTrashService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempVault = await Directory.systemTemp.createTemp(
      'vault_activation_recovery',
    );
    AkashaFileService.debugActivationPhases = null;
    AkashaFileService.debugTrashRecoveryOverride = null;
    await AkashaFileService().setVaultPath('');
  });

  tearDown(() async {
    AkashaFileService.debugActivationPhases = null;
    AkashaFileService.debugTrashRecoveryOverride = null;
    await AkashaFileService().setVaultPath('');
    if (tempVault.existsSync()) {
      await tempVault.delete(recursive: true);
    }
  });

  Future<({String canvasId, List<int> mdBytes, List<int> jsonBytes})>
  createCanvasFixture(String title, String slug) async {
    final data = await canvasStore.createCanvas(
      vaultPath: tempVault.path,
      title: title,
      slug: slug,
    );
    final canvasId = data.record.canvasId;
    final mdBytes = await File(
      p.join(tempVault.path, 'canvases', canvasId, 'canvas.md'),
    ).readAsBytes();
    final jsonBytes = await File(
      p.join(tempVault.path, 'canvases', canvasId, 'layout.json'),
    ).readAsBytes();
    return (canvasId: canvasId, mdBytes: mdBytes, jsonBytes: jsonBytes);
  }

  List<VaultTrashMember> membersFor(
    String canvasId,
    List<int> mdBytes,
    List<int> jsonBytes,
  ) {
    return [
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
    ];
  }

  Future<void> writeTx({
    required String stamp,
    required String canvasId,
    required String state,
    required List<VaultTrashMember> members,
  }) async {
    final root = Directory(p.join(tempVault.path, '.trash', stamp));
    await root.create(recursive: true);
    final tx = VaultTrashTransaction(
      version: 1,
      transactionId: stamp,
      vaultPath: tempVault.path,
      recordKind: 'canvas',
      recordId: canvasId,
      state: state,
      createdAt: DateTime.utc(2026, 7, 24),
      trashRootPath: root.path,
      members: members,
    );
    await File(
      p.join(root.path, 'trash_transaction.json'),
    ).writeAsString(jsonEncode(tx.toJson()));
  }

  test(
    'prepared with healthy originals is cleaned on vault activation',
    () async {
      final created = await createCanvasFixture('Prepared Clean', 'prepared-clean');
      final stamp = '2026-07-24T30-00-00-000001z';
      await writeTx(
        stamp: stamp,
        canvasId: created.canvasId,
        state: VaultTrashTransactionState.prepared.wireName,
        members: membersFor(created.canvasId, created.mdBytes, created.jsonBytes),
      );

      await AkashaFileService().setVaultPath(tempVault.path);

      expect(
        Directory(p.join(tempVault.path, '.trash', stamp)).existsSync(),
        isFalse,
      );
      expect(
        File(
          p.join(tempVault.path, 'canvases', created.canvasId, 'canvas.md'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(tempVault.path, 'canvases', created.canvasId, 'layout.json'),
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'moving with healthy trash converges to committed on activation',
    () async {
      final created = await createCanvasFixture('Moving Commit', 'moving-commit');
      final stamp = '2026-07-24T30-00-00-000002z';
      final members = membersFor(
        created.canvasId,
        created.mdBytes,
        created.jsonBytes,
      );
      final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp));
      final trashCanvas = Directory(
        p.join(trashRoot.path, 'canvases', created.canvasId),
      );
      await trashCanvas.create(recursive: true);
      await File(
        p.join(tempVault.path, 'canvases', created.canvasId, 'canvas.md'),
      ).rename(p.join(trashCanvas.path, 'canvas.md'));
      await File(
        p.join(tempVault.path, 'canvases', created.canvasId, 'layout.json'),
      ).rename(p.join(trashCanvas.path, 'layout.json'));
      await Directory(
        p.join(tempVault.path, 'canvases', created.canvasId),
      ).delete(recursive: true);

      await writeTx(
        stamp: stamp,
        canvasId: created.canvasId,
        state: VaultTrashTransactionState.moving.wireName,
        members: members,
      );

      await AkashaFileService().setVaultPath(tempVault.path);

      final listed = await trash.listTransactions(vaultPath: tempVault.path);
      expect(listed, isNotEmpty);
      final tx = listed.singleWhere((item) => item.transactionId == stamp);
      expect(tx.state, VaultTrashTransactionState.committed.wireName);
      expect(
        Directory(
          p.join(tempVault.path, 'canvases', created.canvasId),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('restoring with healthy trash resumes restore on activation', () async {
    final created = await createCanvasFixture('Restoring Resume', 'restoring-resume');
    final stamp = '2026-07-24T30-00-00-000003z';
    final members = membersFor(
      created.canvasId,
      created.mdBytes,
      created.jsonBytes,
    );
    final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp));
    final trashCanvas = Directory(
      p.join(trashRoot.path, 'canvases', created.canvasId),
    );
    await trashCanvas.create(recursive: true);
    await File(
      p.join(tempVault.path, 'canvases', created.canvasId, 'canvas.md'),
    ).rename(p.join(trashCanvas.path, 'canvas.md'));
    await File(
      p.join(tempVault.path, 'canvases', created.canvasId, 'layout.json'),
    ).rename(p.join(trashCanvas.path, 'layout.json'));
    await Directory(
      p.join(tempVault.path, 'canvases', created.canvasId),
    ).delete(recursive: true);

    await writeTx(
      stamp: stamp,
      canvasId: created.canvasId,
      state: VaultTrashTransactionState.restoring.wireName,
      members: members,
    );

    await AkashaFileService().setVaultPath(tempVault.path);

    expect(
      File(
        p.join(tempVault.path, 'canvases', created.canvasId, 'canvas.md'),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        p.join(tempVault.path, 'canvases', created.canvasId, 'layout.json'),
      ).existsSync(),
      isTrue,
    );
    final listed = await trash.listTransactions(vaultPath: tempVault.path);
    expect(
      listed.any((tx) => tx.transactionId == stamp),
      isFalse,
      reason: 'restored transactions are filtered from listing',
    );
    final manifest = File(
      p.join(tempVault.path, '.trash', stamp, 'trash_transaction.json'),
    );
    if (manifest.existsSync()) {
      final decoded =
          jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['state'], VaultTrashTransactionState.restored.wireName);
    }
  });

  test(
    'hash mismatch marks rollbackRequired without deleting evidence',
    () async {
      final created = await createCanvasFixture('Hash Rollback', 'hash-rollback');
      final stamp = '2026-07-24T30-00-00-000004z';
      final members = [
        VaultTrashMember(
          relativeOriginalPath: p.join(
            'canvases',
            created.canvasId,
            'canvas.md',
          ),
          relativeTrashPath: p.join('canvases', created.canvasId, 'canvas.md'),
          size: 1,
          sha256: 'deadbeef',
        ),
        VaultTrashMember(
          relativeOriginalPath: p.join(
            'canvases',
            created.canvasId,
            'layout.json',
          ),
          relativeTrashPath: p.join(
            'canvases',
            created.canvasId,
            'layout.json',
          ),
          size: 1,
          sha256: 'cafebabe',
        ),
      ];
      await writeTx(
        stamp: stamp,
        canvasId: created.canvasId,
        state: VaultTrashTransactionState.prepared.wireName,
        members: members,
      );

      await AkashaFileService().setVaultPath(tempVault.path);

      final manifest =
          jsonDecode(
                File(
                  p.join(
                    tempVault.path,
                    '.trash',
                    stamp,
                    'trash_transaction.json',
                  ),
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        manifest['state'],
        VaultTrashTransactionState.rollbackRequired.wireName,
      );
      expect(
        File(
          p.join(tempVault.path, 'canvases', created.canvasId, 'canvas.md'),
        ).existsSync(),
        isTrue,
      );
      expect(AkashaFileService().vaultPath, tempVault.path);
    },
  );

  test('repeated activation is idempotent for committed trash', () async {
    final created = await createCanvasFixture('Idempotent', 'idempotent');
    final stamp = '2026-07-24T30-00-00-000005z';
    final members = membersFor(
      created.canvasId,
      created.mdBytes,
      created.jsonBytes,
    );
    final trashRoot = Directory(p.join(tempVault.path, '.trash', stamp));
    final trashCanvas = Directory(
      p.join(trashRoot.path, 'canvases', created.canvasId),
    );
    await trashCanvas.create(recursive: true);
    await File(
      p.join(tempVault.path, 'canvases', created.canvasId, 'canvas.md'),
    ).rename(p.join(trashCanvas.path, 'canvas.md'));
    await File(
      p.join(tempVault.path, 'canvases', created.canvasId, 'layout.json'),
    ).rename(p.join(trashCanvas.path, 'layout.json'));
    await Directory(
      p.join(tempVault.path, 'canvases', created.canvasId),
    ).delete(recursive: true);
    await writeTx(
      stamp: stamp,
      canvasId: created.canvasId,
      state: VaultTrashTransactionState.moving.wireName,
      members: members,
    );

    await AkashaFileService().setVaultPath(tempVault.path);
    final first = await trash.listTransactions(vaultPath: tempVault.path);
    final firstHash = File(
      p.join(trashCanvas.path, 'canvas.md'),
    ).readAsBytesSync();

    await AkashaFileService().setVaultPath(tempVault.path);
    final second = await trash.listTransactions(vaultPath: tempVault.path);
    expect(second.single.transactionId, first.single.transactionId);
    expect(second.single.state, VaultTrashTransactionState.committed.wireName);
    expect(
      File(p.join(trashCanvas.path, 'canvas.md')).readAsBytesSync(),
      firstHash,
    );
  });

  test('trash recovery finishes before watcher and vault notify', () async {
    final phases = <String>[];
    AkashaFileService.debugActivationPhases = phases;
    var recoveryStarted = false;
    var sawWatchOrNotifyDuringRecovery = false;

    AkashaFileService.debugTrashRecoveryOverride = (vaultPath) async {
      recoveryStarted = true;
      expect(phases, contains('trash_recovery_start'));
      expect(phases, isNot(contains('start_watching')));
      expect(phases, isNot(contains('notify_vault_updated')));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (phases.contains('start_watching') ||
          phases.contains('notify_vault_updated')) {
        sawWatchOrNotifyDuringRecovery = true;
      }
      return const <VaultTrashRecoveryResult>[];
    };

    await AkashaFileService().setVaultPath(tempVault.path);

    expect(recoveryStarted, isTrue);
    expect(sawWatchOrNotifyDuringRecovery, isFalse);
    expect(
      phases.indexOf('trash_recovery_done'),
      lessThan(phases.indexOf('start_watching')),
    );
    expect(
      phases.indexOf('trash_recovery_done'),
      lessThan(phases.indexOf('notify_vault_updated')),
    );
  });
}
