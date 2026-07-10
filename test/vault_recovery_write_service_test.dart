import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/services/vault_recovery_write_service.dart';

void main() {
  late Directory vault;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('akasha_recovery_write_');
  });

  tearDown(() async {
    if (await vault.exists()) {
      await vault.delete(recursive: true);
    }
  });

  test('writes a verified replacement and records durable evidence', () async {
    final target = File(
      '${vault.path}${Platform.pathSeparator}journal${Platform.pathSeparator}entry.md',
    );
    await target.parent.create(recursive: true);
    await target.writeAsString('before', flush: true);
    final before = await VaultFileRevision.fromFile(target);

    final result = await VaultRecoveryWriteService().writeText(
      vaultPath: vault.path,
      targetPath: target.path,
      content: 'after',
      reason: 'test_replace',
      expectedRevision: before,
    );

    expect(await target.readAsString(), 'after');
    expect(result.previousRevision.sameContentAs(before), isTrue);
    expect(result.newRevision.sha256, isNot(before.sha256));
    final evidence = File(
      '${vault.path}${Platform.pathSeparator}system${Platform.pathSeparator}recovery${Platform.pathSeparator}transactions.jsonl',
    );
    expect(await evidence.exists(), isTrue);
    expect(await evidence.readAsString(), contains('"phase":"verified"'));
  });

  for (final checkpoint in VaultRecoveryWriteCheckpoint.values) {
    test(
      'recovers a verified normal copy after interruption at $checkpoint',
      () async {
        final target = File(
          '${vault.path}${Platform.pathSeparator}journal${Platform.pathSeparator}entry.md',
        );
        await target.parent.create(recursive: true);
        await target.writeAsString('before', flush: true);
        final before = await VaultFileRevision.fromFile(target);
        final writer = VaultRecoveryWriteService(
          faultInjector: (actual) {
            if (actual == checkpoint) {
              throw StateError('simulated interruption at $checkpoint');
            }
          },
        );

        await expectLater(
          writer.writeText(
            vaultPath: vault.path,
            targetPath: target.path,
            content: 'after',
            reason: 'fault_injection',
            expectedRevision: before,
          ),
          throwsStateError,
        );

        await VaultRecoveryWriteService().recoverPending(vaultPath: vault.path);
        final recovered = await VaultFileRevision.fromFile(target);
        expect(recovered.exists, isTrue);
        expect(recovered.sha256, isIn([before.sha256, await _shaFor('after')]));
      },
    );
  }

  test('preserves source and proposed content on revision conflict', () async {
    final target = File(
      '${vault.path}${Platform.pathSeparator}timeline${Platform.pathSeparator}entry.md',
    );
    await target.parent.create(recursive: true);
    await target.writeAsString('original', flush: true);
    final observed = await VaultFileRevision.fromFile(target);
    await target.writeAsString('external edit', flush: true);

    await expectLater(
      VaultRecoveryWriteService().writeText(
        vaultPath: vault.path,
        targetPath: target.path,
        content: 'akasha proposed edit',
        reason: 'conflict_test',
        expectedRevision: observed,
      ),
      throwsA(isA<VaultWriteConflictException>()),
    );

    expect(await target.readAsString(), 'external edit');
    final conflictRoot = Directory(
      '${vault.path}${Platform.pathSeparator}system${Platform.pathSeparator}recovery${Platform.pathSeparator}conflicts',
    );
    final proposals = await conflictRoot
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    expect(proposals, hasLength(1));
    expect(await proposals.single.readAsString(), 'akasha proposed edit');
  });

  test('does not treat a timestamp-only change as a content conflict', () async {
    final target = File(
      '${vault.path}${Platform.pathSeparator}journal${Platform.pathSeparator}same.md',
    );
    await target.parent.create(recursive: true);
    await target.writeAsString('unchanged', flush: true);
    final observed = await VaultFileRevision.fromFile(target);
    await target.setLastModified(DateTime.now().toUtc().add(const Duration(minutes: 1)));

    final result = await VaultRecoveryWriteService().writeText(
      vaultPath: vault.path,
      targetPath: target.path,
      content: 'unchanged',
      reason: 'timestamp_only_change',
      expectedRevision: observed,
    );

    expect(result.previousRevision.sameContentAs(observed), isTrue);
    expect(await target.readAsString(), 'unchanged');
  });

  for (final checkpoint in VaultRecoveryWriteCheckpoint.values) {
    test(
      'recovers an interdependent two-file set at $checkpoint',
      () async {
        final canvasDir = Directory(
          '${vault.path}${Platform.pathSeparator}canvases${Platform.pathSeparator}cv_test',
        );
        await canvasDir.create(recursive: true);
        final record = File('${canvasDir.path}${Platform.pathSeparator}canvas.md');
        final layout = File('${canvasDir.path}${Platform.pathSeparator}layout.json');
        await record.writeAsString('record before', flush: true);
        await layout.writeAsString('layout before', flush: true);
        final recordBefore = await VaultFileRevision.fromFile(record);
        final layoutBefore = await VaultFileRevision.fromFile(layout);
        final writer = VaultRecoveryWriteService(
          faultInjector: (actual) {
            if (actual == checkpoint) {
              throw StateError('batch interruption at $checkpoint');
            }
          },
        );

        await expectLater(
          writer.writeTextBatch(
            vaultPath: vault.path,
            reason: 'canvas_test_batch',
            writes: [
              VaultTextWriteRequest(
                targetPath: record.path,
                content: 'record after',
                expectedRevision: recordBefore,
              ),
              VaultTextWriteRequest(
                targetPath: layout.path,
                content: 'layout after',
                expectedRevision: layoutBefore,
              ),
            ],
          ),
          throwsStateError,
        );

        await VaultRecoveryWriteService().recoverPending(vaultPath: vault.path);
        final values = [await record.readAsString(), await layout.readAsString()];
        expect(
          values,
          anyOf(
            equals(['record before', 'layout before']),
            equals(['record after', 'layout after']),
          ),
        );
      },
    );
  }

  test('recovers a two-file set when transactions.jsonl is unavailable',
      () async {
    final canvasDir = Directory(
      '${vault.path}${Platform.pathSeparator}canvases${Platform.pathSeparator}cv_manifest',
    );
    await canvasDir.create(recursive: true);
    final record = File('${canvasDir.path}${Platform.pathSeparator}canvas.md');
    final layout = File('${canvasDir.path}${Platform.pathSeparator}layout.json');
    await record.writeAsString('record before', flush: true);
    await layout.writeAsString('layout before', flush: true);
    final writer = VaultRecoveryWriteService(
      faultInjector: (checkpoint) {
        if (checkpoint == VaultRecoveryWriteCheckpoint.promoted) {
          throw StateError('interrupted after first promotion');
        }
      },
    );

    await expectLater(
      writer.writeTextBatch(
        vaultPath: vault.path,
        reason: 'manifest_only_recovery',
        writes: [
          VaultTextWriteRequest(
            targetPath: record.path,
            content: 'record after',
            expectedRevision: await VaultFileRevision.fromFile(record),
          ),
          VaultTextWriteRequest(
            targetPath: layout.path,
            content: 'layout after',
            expectedRevision: await VaultFileRevision.fromFile(layout),
          ),
        ],
      ),
      throwsStateError,
    );
    final log = File(
      '${vault.path}${Platform.pathSeparator}system${Platform.pathSeparator}recovery${Platform.pathSeparator}transactions.jsonl',
    );
    if (await log.exists()) await log.delete();

    await VaultRecoveryWriteService().recoverPending(vaultPath: vault.path);
    expect(await record.readAsString(), 'record after');
    expect(await layout.readAsString(), 'layout after');
  });

  test('recovers from a manifest when transactions.jsonl is malformed',
      () async {
    final target = File(
      '${vault.path}${Platform.pathSeparator}journal${Platform.pathSeparator}manifest.md',
    );
    await target.parent.create(recursive: true);
    await target.writeAsString('before', flush: true);
    final writer = VaultRecoveryWriteService(
      faultInjector: (checkpoint) {
        if (checkpoint == VaultRecoveryWriteCheckpoint.previousPreserved) {
          throw StateError('interrupted after preserving previous copy');
        }
      },
    );

    await expectLater(
      writer.writeText(
        vaultPath: vault.path,
        targetPath: target.path,
        content: 'after',
        reason: 'malformed_log_manifest_recovery',
        expectedRevision: await VaultFileRevision.fromFile(target),
      ),
      throwsStateError,
    );
    final log = File(
      '${vault.path}${Platform.pathSeparator}system${Platform.pathSeparator}recovery${Platform.pathSeparator}transactions.jsonl',
    );
    await log.writeAsString('{truncated JSONL record');

    await VaultRecoveryWriteService().recoverPending(vaultPath: vault.path);
    expect(await target.readAsString(), 'after');
  });

  test('recovers a new binary asset without transactions.jsonl', () async {
    final target = File(
      '${vault.path}${Platform.pathSeparator}posters${Platform.pathSeparator}asset.bin',
    );
    final writer = VaultRecoveryWriteService(
      faultInjector: (checkpoint) {
        if (checkpoint == VaultRecoveryWriteCheckpoint.staged) {
          throw StateError('interrupted binary asset');
        }
      },
    );
    await expectLater(
      writer.writeNewBytes(
        vaultPath: vault.path,
        targetPath: target.path,
        bytes: [1, 2, 3, 4],
        reason: 'binary_manifest_recovery',
      ),
      throwsStateError,
    );
    final log = File(
      '${vault.path}${Platform.pathSeparator}system${Platform.pathSeparator}recovery${Platform.pathSeparator}transactions.jsonl',
    );
    if (await log.exists()) await log.delete();

    await VaultRecoveryWriteService().recoverPending(vaultPath: vault.path);
    expect(await target.readAsBytes(), [1, 2, 3, 4]);
  });
}

Future<String> _shaFor(String content) async {
  final directory = await Directory.systemTemp.createTemp('akasha_sha_');
  try {
    final file = File('${directory.path}${Platform.pathSeparator}value.txt');
    await file.writeAsString(content, flush: true);
    return (await VaultFileRevision.fromFile(file)).sha256!;
  } finally {
    await directory.delete(recursive: true);
  }
}
