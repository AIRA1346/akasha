import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import '../core/archiving/vault_file_revision.dart';

export '../core/archiving/vault_file_revision.dart';

enum VaultRecoveryWriteCheckpoint {
  staged,
  previousPreserved,
  promoted,
  verified,
}

typedef VaultRecoveryFaultInjector =
    FutureOr<void> Function(VaultRecoveryWriteCheckpoint checkpoint);

class VaultWriteConflictException implements Exception {
  const VaultWriteConflictException({
    required this.targetPath,
    required this.expectedRevision,
    required this.currentRevision,
    required this.proposedPath,
  });

  final String targetPath;
  final VaultFileRevision expectedRevision;
  final VaultFileRevision currentRevision;
  final String proposedPath;

  @override
  String toString() =>
      'Vault write conflict for $targetPath: expected '
      '${expectedRevision.value}, found ${currentRevision.value}. '
      'Proposed content preserved at $proposedPath.';
}

class VaultRecoverableWriteResult {
  const VaultRecoverableWriteResult({
    required this.transactionId,
    required this.targetPath,
    required this.previousRevision,
    required this.newRevision,
  });

  final String transactionId;
  final String targetPath;
  final VaultFileRevision previousRevision;
  final VaultFileRevision newRevision;
}

class VaultTextWriteRequest {
  const VaultTextWriteRequest({
    required this.targetPath,
    required this.content,
    this.expectedRevision,
  });

  final String targetPath;
  final String content;
  final VaultFileRevision? expectedRevision;
}

class VaultRecoverableBatchWriteResult {
  const VaultRecoverableBatchWriteResult({
    required this.transactionId,
    required this.writes,
  });

  final String transactionId;
  final List<VaultRecoverableWriteResult> writes;
}

/// Writes durable Vault files without silently destroying a recoverable copy.
///
/// A platform-independent atomic replacement cannot be assumed for cloud sync
/// folders, removable drives, or Windows rename semantics. This service stages
/// and verifies the new file, moves the previous verified file to durable
/// recovery storage, promotes the staged copy, and records enough evidence to
/// recover after interruption.
class VaultRecoveryWriteService {
  VaultRecoveryWriteService({VaultRecoveryFaultInjector? faultInjector})
    : _faultInjector = faultInjector;

  static const String systemDirName = 'system';
  static const String recoveryDirName = 'recovery';
  static const String backupsDirName = 'backups';
  static const String conflictsDirName = 'conflicts';
  static const String manifestsDirName = 'manifests';
  static const String transactionLogFileName = 'transactions.jsonl';

  static Future<void> _queueTail = Future<void>.value();

  final VaultRecoveryFaultInjector? _faultInjector;

  Future<VaultRecoverableWriteResult> writeText({
    required String vaultPath,
    required String targetPath,
    required String content,
    required String reason,
    VaultFileRevision? expectedRevision,
  }) {
    return _enqueue(() async {
      final result = await _writeTextBatch(
        vaultPath: vaultPath,
        writes: [
          VaultTextWriteRequest(
            targetPath: targetPath,
            content: content,
            expectedRevision: expectedRevision,
          ),
        ],
        reason: reason,
      );
      return result.writes.single;
    });
  }

  /// Replaces a set of interdependent text files as one recoverable unit.
  ///
  /// It is deliberately not presented as cross-filesystem atomicity. On a
  /// restart, the durable transaction manifest lets recovery choose one
  /// complete, verified set: all previous files or all proposed files.
  Future<VaultRecoverableBatchWriteResult> writeTextBatch({
    required String vaultPath,
    required List<VaultTextWriteRequest> writes,
    required String reason,
  }) => _enqueue(
    () => _writeTextBatch(
      vaultPath: vaultPath,
      writes: writes,
      reason: reason,
    ),
  );

  /// Repairs a transaction interrupted after it wrote a recoverable artifact.
  ///
  /// Recovery never replaces a present, unknown target file. In that case it
  /// keeps both artifacts and records a conflict for explicit user resolution.
  Future<void> recoverPending({required String vaultPath}) {
    return _enqueue(() => _recoverPending(vaultPath: vaultPath));
  }

  /// Stores a verified proposed payload when parsing or validation makes an
  /// in-place update unsafe. The source target is never touched.
  Future<String> preserveRejectedText({
    required String vaultPath,
    required String targetPath,
    required String content,
    required String reason,
  }) {
    return _enqueue(
      () => _preserveRejectedText(
        vaultPath: vaultPath,
        targetPath: targetPath,
        content: content,
        reason: reason,
      ),
    );
  }

  /// Checks a previously opened revision without modifying the target file.
  ///
  /// Rename flows use this before writing their new path. A mismatch preserves
  /// the proposed text as conflict evidence and leaves both user files alone.
  Future<void> verifyExpectedRevision({
    required String vaultPath,
    required String targetPath,
    required VaultFileRevision expectedRevision,
    required String proposedContent,
    required String reason,
  }) {
    return _enqueue(
      () => _verifyExpectedRevision(
        vaultPath: vaultPath,
        targetPath: targetPath,
        expectedRevision: expectedRevision,
        proposedContent: proposedContent,
        reason: reason,
      ),
    );
  }

  /// Appends one self-contained JSONL record. This is the append-only
  /// equivalent of a replacement transaction: a torn final line may be
  /// ignored, while every earlier verified line remains readable.
  Future<void> appendJsonLine({
    required String vaultPath,
    required String targetPath,
    required Map<String, Object?> entry,
  }) {
    return _enqueue(() async {
      final paths = _paths(vaultPath: vaultPath, targetPath: targetPath);
      final file = File(paths.targetPath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite(mode: FileMode.append);
      try {
        sink.writeln(jsonEncode(entry));
      } finally {
        await sink.flush();
        await sink.close();
      }
    });
  }

  /// Safely creates a new binary asset. Callers must select a unique target
  /// path; replacing an existing binary belongs to a future explicit asset
  /// revision flow.
  Future<void> writeNewBytes({
    required String vaultPath,
    required String targetPath,
    required List<int> bytes,
    required String reason,
  }) {
    return _enqueue(() async {
      final paths = _paths(vaultPath: vaultPath, targetPath: targetPath);
      await _recoverPending(vaultPath: paths.vaultRoot);
      final target = File(paths.targetPath);
      if (await target.exists()) {
        throw StateError('Refusing to replace existing binary Vault asset.');
      }

      final transactionId = _transactionId();
      final staged = File(_stagingPath(paths.targetPath, transactionId));
      final backup = File(
        p.join(
          paths.recoveryRoot,
          backupsDirName,
          transactionId,
          paths.relativeTarget,
        ),
      );
      final plannedRevision = VaultFileRevision.fromBytes(bytes);
      final manifest = _manifestFile(paths.recoveryRoot, transactionId);
      await _writeRawManifest(
        manifest: manifest,
        transactionId: transactionId,
        reason: reason,
        targets: [
          <String, Object?>{
            'target_path': paths.relativeTarget,
            'staging_path': _relative(paths.vaultRoot, staged.path),
            'backup_path': _relative(paths.vaultRoot, backup.path),
            'expected_revision': const VaultFileRevision.missing().toJson(),
            'previous_revision': const VaultFileRevision.missing().toJson(),
            'new_revision': plannedRevision.toJson(),
          },
        ],
      );
      await staged.parent.create(recursive: true);
      await staged.writeAsBytes(bytes, flush: true);
      final stagedRevision = await VaultFileRevision.fromFile(staged);
      if (!stagedRevision.sameContentAs(plannedRevision)) {
        throw StateError(
          'Staged binary Vault asset failed SHA-256 verification.',
        );
      }
      await _appendEvidence(
        paths: paths,
        phase: 'staged',
        transactionId: transactionId,
        reason: reason,
        targetPath: paths.relativeTarget,
        stagingPath: _relative(paths.vaultRoot, staged.path),
        backupPath: _relative(paths.vaultRoot, backup.path),
        previousRevision: const VaultFileRevision.missing(),
        newRevision: stagedRevision,
      );
      await _hit(VaultRecoveryWriteCheckpoint.staged);
      if (await target.exists()) {
        throw StateError('Binary Vault asset target changed before promotion.');
      }
      await staged.rename(target.path);
      final promoted = await VaultFileRevision.fromFile(target);
      if (!promoted.sameContentAs(stagedRevision)) {
        throw StateError(
          'Promoted binary Vault asset failed SHA-256 verification.',
        );
      }
      await _appendEvidence(
        paths: paths,
        phase: 'verified',
        transactionId: transactionId,
        reason: reason,
        targetPath: paths.relativeTarget,
        stagingPath: _relative(paths.vaultRoot, staged.path),
        backupPath: _relative(paths.vaultRoot, backup.path),
        previousRevision: const VaultFileRevision.missing(),
        newRevision: promoted,
      );
      if (await manifest.exists()) await manifest.delete();
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final operation = _queueTail.then((_) => action());
    _queueTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<VaultRecoverableBatchWriteResult> _writeTextBatch({
    required String vaultPath,
    required List<VaultTextWriteRequest> writes,
    required String reason,
  }) async {
    if (writes.isEmpty) {
      throw ArgumentError.value(writes, 'writes', 'must not be empty');
    }

    final firstPaths = _paths(
      vaultPath: vaultPath,
      targetPath: writes.first.targetPath,
    );
    await _recoverPending(vaultPath: firstPaths.vaultRoot);

    final targets = <String>{};
    final items = <_BatchWriteItem>[];
    for (final request in writes) {
      final paths = _paths(
        vaultPath: firstPaths.vaultRoot,
        targetPath: request.targetPath,
      );
      if (paths.vaultRoot != firstPaths.vaultRoot ||
          !targets.add(paths.targetPath)) {
        throw ArgumentError.value(
          request.targetPath,
          'writes',
          'targets must be unique and belong to one Vault',
        );
      }
      final bytes = utf8.encode(request.content);
      final previous = await VaultFileRevision.fromFile(File(paths.targetPath));
      items.add(
        _BatchWriteItem(
          paths: paths,
          content: request.content,
          expectedRevision: request.expectedRevision ?? previous,
          previousRevision: previous,
          newRevision: VaultFileRevision(
            exists: true,
            sha256: crypto.sha256.convert(bytes).toString(),
            byteLength: bytes.length,
          ),
        ),
      );
    }

    final transactionId = _transactionId();
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (!item.previousRevision.sameContentAs(item.expectedRevision)) {
        throw await _preserveBatchConflict(
          transactionId: transactionId,
          reason: reason,
          items: items,
          conflictIndex: index,
          currentRevision: item.previousRevision,
        );
      }
    }

    for (final item in items) {
      item.staged = File(_stagingPath(item.paths.targetPath, transactionId));
      item.backup = File(
        p.join(
          item.paths.recoveryRoot,
          backupsDirName,
          transactionId,
          item.paths.relativeTarget,
        ),
      );
    }
    final manifest = _manifestFile(firstPaths.recoveryRoot, transactionId);
    await _writeManifest(
      manifest: manifest,
      transactionId: transactionId,
      reason: reason,
      items: items,
    );

    for (final item in items) {
      final staged = item.staged!;
      await staged.parent.create(recursive: true);
      await staged.writeAsString(item.content, flush: true);
      final stagedRevision = await VaultFileRevision.fromFile(staged);
      if (!stagedRevision.sameContentAs(item.newRevision)) {
        throw StateError('Staged Vault content failed SHA-256 verification.');
      }
      await _appendEvidence(
        paths: item.paths,
        phase: 'staged',
        transactionId: transactionId,
        reason: reason,
        targetPath: item.paths.relativeTarget,
        stagingPath: _relative(firstPaths.vaultRoot, staged.path),
        backupPath: _relative(firstPaths.vaultRoot, item.backup!.path),
        previousRevision: item.previousRevision,
        newRevision: item.newRevision,
        expectedRevision: item.expectedRevision,
      );
      await _hit(VaultRecoveryWriteCheckpoint.staged);
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final current = await VaultFileRevision.fromFile(
        File(item.paths.targetPath),
      );
      if (!current.sameContentAs(item.expectedRevision)) {
        throw await _preserveBatchConflict(
          transactionId: transactionId,
          reason: '${reason}_before_preserve',
          items: items,
          conflictIndex: index,
          currentRevision: current,
        );
      }
    }

    for (final item in items) {
      final target = File(item.paths.targetPath);
      final backup = item.backup!;
      if (item.previousRevision.exists) {
        await backup.parent.create(recursive: true);
        await target.rename(backup.path);
        final preserved = await VaultFileRevision.fromFile(backup);
        if (!preserved.sameContentAs(item.previousRevision)) {
          throw StateError('Previous Vault content could not be preserved.');
        }
      }
      await _appendEvidence(
        paths: item.paths,
        phase: 'previous_preserved',
        transactionId: transactionId,
        reason: reason,
        targetPath: item.paths.relativeTarget,
        stagingPath: _relative(firstPaths.vaultRoot, item.staged!.path),
        backupPath: _relative(firstPaths.vaultRoot, backup.path),
        previousRevision: item.previousRevision,
        newRevision: item.newRevision,
        expectedRevision: item.expectedRevision,
      );
      await _hit(VaultRecoveryWriteCheckpoint.previousPreserved);
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final target = File(item.paths.targetPath);
      final current = await VaultFileRevision.fromFile(target);
      if (current.exists) {
        throw await _preserveBatchConflict(
          transactionId: transactionId,
          reason: '${reason}_before_promote',
          items: items,
          conflictIndex: index,
          currentRevision: current,
        );
      }
      await item.staged!.rename(target.path);
      await _appendEvidence(
        paths: item.paths,
        phase: 'promoted',
        transactionId: transactionId,
        reason: reason,
        targetPath: item.paths.relativeTarget,
        stagingPath: _relative(firstPaths.vaultRoot, item.staged!.path),
        backupPath: _relative(firstPaths.vaultRoot, item.backup!.path),
        previousRevision: item.previousRevision,
        newRevision: item.newRevision,
        expectedRevision: item.expectedRevision,
      );
      await _hit(VaultRecoveryWriteCheckpoint.promoted);
    }

    final results = <VaultRecoverableWriteResult>[];
    for (final item in items) {
      final promoted = await VaultFileRevision.fromFile(
        File(item.paths.targetPath),
      );
      if (!promoted.sameContentAs(item.newRevision)) {
        throw StateError('Promoted Vault content failed SHA-256 verification.');
      }
      await _appendEvidence(
        paths: item.paths,
        phase: 'verified',
        transactionId: transactionId,
        reason: reason,
        targetPath: item.paths.relativeTarget,
        stagingPath: _relative(firstPaths.vaultRoot, item.staged!.path),
        backupPath: _relative(firstPaths.vaultRoot, item.backup!.path),
        previousRevision: item.previousRevision,
        newRevision: promoted,
        expectedRevision: item.expectedRevision,
      );
      results.add(
        VaultRecoverableWriteResult(
          transactionId: transactionId,
          targetPath: item.paths.targetPath,
          previousRevision: item.previousRevision,
          newRevision: promoted,
        ),
      );
      await _hit(VaultRecoveryWriteCheckpoint.verified);
    }

    for (final item in items) {
      final backup = item.backup!;
      if (await backup.exists()) await backup.delete();
    }
    if (await manifest.exists()) await manifest.delete();
    return VaultRecoverableBatchWriteResult(
      transactionId: transactionId,
      writes: results,
    );
  }

  Future<void> _verifyExpectedRevision({
    required String vaultPath,
    required String targetPath,
    required VaultFileRevision expectedRevision,
    required String proposedContent,
    required String reason,
  }) async {
    final paths = _paths(vaultPath: vaultPath, targetPath: targetPath);
    final currentRevision = await VaultFileRevision.fromFile(File(targetPath));
    if (currentRevision.sameContentAs(expectedRevision)) return;
    throw await _preserveConflict(
      paths: paths,
      transactionId: _transactionId(),
      expectedRevision: expectedRevision,
      currentRevision: currentRevision,
      content: proposedContent,
      reason: reason,
    );
  }

  Future<VaultWriteConflictException> _preserveConflict({
    required _VaultWritePaths paths,
    required String transactionId,
    required String reason,
    required VaultFileRevision expectedRevision,
    required VaultFileRevision currentRevision,
    required String content,
  }) async {
    final extension = p.extension(paths.targetPath);
    final proposed = File(
      p.join(
        paths.recoveryRoot,
        conflictsDirName,
        '$transactionId.proposed$extension',
      ),
    );
    await _writeNewVerifiedFile(proposed, content);
    await _appendEvidence(
      paths: paths,
      phase: 'conflict',
      transactionId: transactionId,
      reason: reason,
      targetPath: paths.relativeTarget,
      conflictPath: _relative(paths.vaultRoot, proposed.path),
      previousRevision: currentRevision,
      expectedRevision: expectedRevision,
      newRevision: await VaultFileRevision.fromFile(proposed),
    );
    return VaultWriteConflictException(
      targetPath: paths.targetPath,
      expectedRevision: expectedRevision,
      currentRevision: currentRevision,
      proposedPath: proposed.path,
    );
  }

  Future<String> _preserveRejectedText({
    required String vaultPath,
    required String targetPath,
    required String content,
    required String reason,
  }) async {
    final paths = _paths(vaultPath: vaultPath, targetPath: targetPath);
    final transactionId = _transactionId();
    final extension = p.extension(paths.targetPath);
    final proposed = File(
      p.join(
        paths.recoveryRoot,
        conflictsDirName,
        '$transactionId.rejected$extension',
      ),
    );
    await _writeNewVerifiedFile(proposed, content);
    await _appendEvidence(
      paths: paths,
      phase: 'quarantined',
      transactionId: transactionId,
      reason: reason,
      targetPath: paths.relativeTarget,
      conflictPath: _relative(paths.vaultRoot, proposed.path),
      previousRevision: await VaultFileRevision.fromFile(
        File(paths.targetPath),
      ),
      newRevision: await VaultFileRevision.fromFile(proposed),
    );
    return proposed.path;
  }

  File _manifestFile(String recoveryRoot, String transactionId) => File(
    p.join(recoveryRoot, manifestsDirName, '$transactionId.json'),
  );

  Future<void> _writeManifest({
    required File manifest,
    required String transactionId,
    required String reason,
    required List<_BatchWriteItem> items,
  }) async {
    final vaultRoot = items.first.paths.vaultRoot;
    final targets = items
        .map(
          (item) => <String, Object?>{
            'target_path': item.paths.relativeTarget,
            'staging_path': _relative(vaultRoot, item.staged!.path),
            'backup_path': _relative(vaultRoot, item.backup!.path),
            'expected_revision': item.expectedRevision.toJson(),
            'previous_revision': item.previousRevision.toJson(),
            'new_revision': item.newRevision.toJson(),
          },
        )
        .toList();
    await _writeRawManifest(
      manifest: manifest,
      transactionId: transactionId,
      reason: reason,
      targets: targets,
    );
  }

  Future<void> _writeRawManifest({
    required File manifest,
    required String transactionId,
    required String reason,
    required List<Map<String, Object?>> targets,
  }) async {
    if (await manifest.exists()) {
      throw StateError('Recovery transaction manifest already exists.');
    }
    final document = <String, Object?>{
      'version': 1,
      'kind': 'replace_batch',
      'transaction_id': transactionId,
      'reason': reason,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'targets': targets,
    };
    await _writeNewVerifiedFile(
      manifest,
      const JsonEncoder.withIndent('  ').convert(document),
    );
  }

  Future<VaultWriteConflictException> _preserveBatchConflict({
    required String transactionId,
    required String reason,
    required List<_BatchWriteItem> items,
    required int conflictIndex,
    required VaultFileRevision currentRevision,
  }) async {
    String? firstProposal;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final extension = p.extension(item.paths.targetPath);
      final proposed = File(
        items.length == 1
            ? p.join(
                item.paths.recoveryRoot,
                conflictsDirName,
                '$transactionId.proposed$extension',
              )
            : p.join(
                item.paths.recoveryRoot,
                conflictsDirName,
                transactionId,
                '${item.paths.relativeTarget}.proposed',
              ),
      );
      await _writeNewVerifiedFile(proposed, item.content);
      final current = index == conflictIndex
          ? currentRevision
          : await VaultFileRevision.fromFile(File(item.paths.targetPath));
      await _appendEvidence(
        paths: item.paths,
        phase: 'conflict',
        transactionId: transactionId,
        reason: reason,
        targetPath: item.paths.relativeTarget,
        conflictPath: _relative(item.paths.vaultRoot, proposed.path),
        previousRevision: current,
        newRevision: await VaultFileRevision.fromFile(proposed),
        expectedRevision: item.expectedRevision,
      );
      firstProposal ??= proposed.path;
    }
    final conflicting = items[conflictIndex];
    return VaultWriteConflictException(
      targetPath: conflicting.paths.targetPath,
      expectedRevision: conflicting.expectedRevision,
      currentRevision: currentRevision,
      proposedPath: firstProposal!,
    );
  }

  Future<Set<String>> _recoverPendingManifests({
    required String vaultPath,
  }) async {
    final manifestDir = Directory(
      p.join(vaultPath, systemDirName, recoveryDirName, manifestsDirName),
    );
    if (!await manifestDir.exists()) return <String>{};

    final recoveredTransactions = <String>{};
    await for (final entity in manifestDir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is! Map) continue;
        final manifest = Map<String, dynamic>.from(decoded);
        if (manifest['kind']?.toString() != 'replace_batch') continue;
        final transactionId = manifest['transaction_id']?.toString() ?? '';
        if (transactionId.isEmpty) continue;
        recoveredTransactions.add(transactionId);
        await _recoverManifest(
          vaultPath: vaultPath,
          manifestFile: entity,
          manifest: manifest,
        );
      } catch (_) {
        // The manifest remains in place for explicit resolution. JSONL is only
        // a fallback acceleration path, never the authority for this write.
      }
    }
    return recoveredTransactions;
  }

  Future<void> _recoverManifest({
    required String vaultPath,
    required File manifestFile,
    required Map<String, dynamic> manifest,
  }) async {
    final transactionId = manifest['transaction_id']?.toString() ?? '';
    final reason = manifest['reason']?.toString() ?? 'recovery';
    final rawTargets = manifest['targets'];
    if (transactionId.isEmpty || rawTargets is! List || rawTargets.isEmpty) {
      throw const FormatException('Invalid recovery transaction manifest.');
    }

    final items = <_ManifestWriteItem>[];
    for (final raw in rawTargets) {
      if (raw is! Map) throw const FormatException('Invalid manifest target.');
      final item = _manifestItemFromJson(
        vaultPath: vaultPath,
        transactionId: transactionId,
        json: Map<String, dynamic>.from(raw),
      );
      items.add(item);
    }

    final targetRevisions = <VaultFileRevision>[];
    var hasExternalTarget = false;
    for (final item in items) {
      final revision = await VaultFileRevision.fromFile(item.target);
      targetRevisions.add(revision);
      if (revision.exists &&
          !revision.sameContentAs(item.previousRevision) &&
          !revision.sameContentAs(item.newRevision)) {
        hasExternalTarget = true;
      }
    }
    if (hasExternalTarget) {
      await _recordManifestOutcome(
        items: items,
        transactionId: transactionId,
        reason: reason,
        phase: 'recovery_needs_resolution',
      );
      return;
    }

    final canCompleteNew = await _canCompleteNew(items, targetRevisions);
    if (canCompleteNew) {
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        var targetRevision = targetRevisions[index];
        if (targetRevision.sameContentAs(item.newRevision)) continue;
        if (targetRevision.exists) {
          if (!targetRevision.sameContentAs(item.previousRevision)) {
            await _recordManifestOutcome(
              items: items,
              transactionId: transactionId,
              reason: reason,
              phase: 'recovery_needs_resolution',
            );
            return;
          }
          if (item.previousRevision.exists && !await item.backup.exists()) {
            await item.backup.parent.create(recursive: true);
            await item.target.rename(item.backup.path);
          } else {
            await _preserveRecoveryArtifact(
              source: item.target,
              item: item,
              transactionId: transactionId,
              label: 'unexpected_target',
            );
          }
          targetRevision = const VaultFileRevision.missing();
        }
        if (!targetRevision.exists && await item.staged.exists()) {
          await item.target.parent.create(recursive: true);
          await item.staged.rename(item.target.path);
        }
      }
      final complete = await _allTargetsMatch(items, useNew: true);
      if (complete) {
        await _recordManifestOutcome(
          items: items,
          transactionId: transactionId,
          reason: reason,
          phase: 'recovered_new_set',
        );
        await _cleanupRecoveredManifest(items, manifestFile);
        return;
      }
    }

    final canRestorePrevious = await _canRestorePrevious(
      items,
      targetRevisions,
    );
    if (!canRestorePrevious) {
      await _recordManifestOutcome(
        items: items,
        transactionId: transactionId,
        reason: reason,
        phase: 'recovery_needs_resolution',
      );
      return;
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final current = await VaultFileRevision.fromFile(item.target);
      if (current.sameContentAs(item.newRevision)) {
        await _preserveRecoveryArtifact(
          source: item.target,
          item: item,
          transactionId: transactionId,
          label: 'interrupted_new',
        );
      }
      final afterPreserve = await VaultFileRevision.fromFile(item.target);
      if (!afterPreserve.exists &&
          item.previousRevision.exists &&
          await item.backup.exists()) {
        final backupRevision = await VaultFileRevision.fromFile(item.backup);
        if (backupRevision.sameContentAs(item.previousRevision)) {
          await item.target.parent.create(recursive: true);
          await item.backup.rename(item.target.path);
        }
      }
      if (await item.staged.exists()) {
        await _preserveRecoveryArtifact(
          source: item.staged,
          item: item,
          transactionId: transactionId,
          label: 'interrupted_stage',
        );
      }
    }

    if (await _allTargetsMatch(items, useNew: false)) {
      await _recordManifestOutcome(
        items: items,
        transactionId: transactionId,
        reason: reason,
        phase: 'recovered_previous_set',
      );
      await _cleanupRecoveredManifest(items, manifestFile);
    } else {
      await _recordManifestOutcome(
        items: items,
        transactionId: transactionId,
        reason: reason,
        phase: 'recovery_needs_resolution',
      );
    }
  }

  _ManifestWriteItem _manifestItemFromJson({
    required String vaultPath,
    required String transactionId,
    required Map<String, dynamic> json,
  }) {
    final targetRelative = json['target_path']?.toString() ?? '';
    final stagingRelative = json['staging_path']?.toString() ?? '';
    final backupRelative = json['backup_path']?.toString() ?? '';
    final previous = _revisionFromEvidence(json['previous_revision']);
    final next = _revisionFromEvidence(json['new_revision']);
    if (targetRelative.isEmpty ||
        stagingRelative.isEmpty ||
        backupRelative.isEmpty ||
        previous == null ||
        next == null) {
      throw const FormatException('Incomplete recovery transaction manifest.');
    }
    final paths = _paths(
      vaultPath: vaultPath,
      targetPath: p.join(vaultPath, targetRelative),
    );
    final staging = _artifactFile(vaultPath, stagingRelative);
    final backup = _artifactFile(vaultPath, backupRelative);
    return _ManifestWriteItem(
      paths: paths,
      target: File(paths.targetPath),
      staged: staging,
      backup: backup,
      previousRevision: previous,
      newRevision: next,
      transactionId: transactionId,
    );
  }

  File _artifactFile(String vaultPath, String relativePath) {
    final absolute = p.normalize(p.absolute(p.join(vaultPath, relativePath)));
    final root = p.normalize(p.absolute(vaultPath));
    if (!p.isWithin(root, absolute)) {
      throw const FormatException('Recovery artifact is outside the Vault.');
    }
    return File(absolute);
  }

  Future<bool> _canCompleteNew(
    List<_ManifestWriteItem> items,
    List<VaultFileRevision> targetRevisions,
  ) async {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (targetRevisions[index].sameContentAs(item.newRevision)) continue;
      final staged = await VaultFileRevision.fromFile(item.staged);
      if (!staged.sameContentAs(item.newRevision)) return false;
    }
    return true;
  }

  Future<bool> _canRestorePrevious(
    List<_ManifestWriteItem> items,
    List<VaultFileRevision> targetRevisions,
  ) async {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final target = targetRevisions[index];
      if (target.sameContentAs(item.previousRevision)) continue;
      if (!item.previousRevision.exists &&
          target.sameContentAs(item.newRevision)) {
        continue;
      }
      final backup = await VaultFileRevision.fromFile(item.backup);
      if (!backup.sameContentAs(item.previousRevision)) return false;
    }
    return true;
  }

  Future<bool> _allTargetsMatch(
    List<_ManifestWriteItem> items, {
    required bool useNew,
  }) async {
    for (final item in items) {
      final expected = useNew ? item.newRevision : item.previousRevision;
      if (!(await VaultFileRevision.fromFile(item.target)).sameContentAs(expected)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _preserveRecoveryArtifact({
    required File source,
    required _ManifestWriteItem item,
    required String transactionId,
    required String label,
  }) async {
    if (!await source.exists()) return;
    final destination = File(
      p.join(
        item.paths.recoveryRoot,
        conflictsDirName,
        transactionId,
        '$label.${item.paths.relativeTarget}',
      ),
    );
    if (await destination.exists()) return;
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
  }

  Future<void> _recordManifestOutcome({
    required List<_ManifestWriteItem> items,
    required String transactionId,
    required String reason,
    required String phase,
  }) async {
    for (final item in items) {
      await _appendEvidence(
        paths: item.paths,
        phase: phase,
        transactionId: transactionId,
        reason: reason,
        targetPath: item.paths.relativeTarget,
        stagingPath: _relative(item.paths.vaultRoot, item.staged.path),
        backupPath: _relative(item.paths.vaultRoot, item.backup.path),
        previousRevision: item.previousRevision,
        newRevision: item.newRevision,
      );
    }
  }

  Future<void> _cleanupRecoveredManifest(
    List<_ManifestWriteItem> items,
    File manifestFile,
  ) async {
    for (final item in items) {
      if (await item.backup.exists()) await item.backup.delete();
      if (await item.staged.exists()) await item.staged.delete();
    }
    if (await manifestFile.exists()) await manifestFile.delete();
  }

  Future<void> _recoverPending({required String vaultPath}) async {
    final normalizedVault = p.normalize(p.absolute(vaultPath));
    final manifestTransactions = await _recoverPendingManifests(
      vaultPath: normalizedVault,
    );
    final log = File(
      p.join(
        normalizedVault,
        systemDirName,
        recoveryDirName,
        transactionLogFileName,
      ),
    );
    if (!await log.exists()) return;

    final latestByTransaction = <String, Map<String, dynamic>>{};
    for (final line in await log.readAsLines()) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is! Map) continue;
        final entry = Map<String, dynamic>.from(decoded);
        final transactionId = entry['transaction_id']?.toString() ?? '';
        if (transactionId.isNotEmpty) {
          latestByTransaction[transactionId] = entry;
        }
      } catch (_) {
        // A partial final append cannot invalidate previous evidence.
      }
    }

    for (final entry in latestByTransaction.values) {
      final loggedTransactionId = entry['transaction_id']?.toString() ?? '';
      if (manifestTransactions.contains(loggedTransactionId)) continue;
      final phase = entry['phase']?.toString() ?? '';
      if (phase == 'verified' ||
          phase == 'conflict' ||
          phase.startsWith('recovered_')) {
        continue;
      }
      final targetRelative = entry['target_path']?.toString() ?? '';
      if (targetRelative.isEmpty) {
        continue;
      }
      final paths = _paths(
        vaultPath: normalizedVault,
        targetPath: p.join(normalizedVault, targetRelative),
      );
      final transactionId = entry['transaction_id']?.toString() ?? '';
      final stagedRelative = entry['staging_path']?.toString() ?? '';
      final backupRelative = entry['backup_path']?.toString() ?? '';
      final staged = stagedRelative.isEmpty
          ? null
          : File(p.join(normalizedVault, stagedRelative));
      final backup = backupRelative.isEmpty
          ? null
          : File(p.join(normalizedVault, backupRelative));
      final target = File(paths.targetPath);
      final expectedNewDigest = _digestFromEvidence(entry['new_revision']);

      final targetRevision = await VaultFileRevision.fromFile(target);
      if (targetRevision.exists && targetRevision.sha256 == expectedNewDigest) {
        await _appendRecoveryOutcome(
          paths: paths,
          transactionId: transactionId,
          phase: 'recovered_verified_target',
          source: entry,
        );
        continue;
      }

      if (!targetRevision.exists && staged != null && await staged.exists()) {
        final stagedRevision = await VaultFileRevision.fromFile(staged);
        if (stagedRevision.sha256 == expectedNewDigest) {
          await staged.rename(target.path);
          final promoted = await VaultFileRevision.fromFile(target);
          if (promoted.sha256 == expectedNewDigest) {
            await _appendRecoveryOutcome(
              paths: paths,
              transactionId: transactionId,
              phase: 'recovered_new_copy',
              source: entry,
            );
            continue;
          }
        }
      }

      if (!targetRevision.exists && backup != null && await backup.exists()) {
        await target.parent.create(recursive: true);
        await backup.copy(target.path);
        await _appendRecoveryOutcome(
          paths: paths,
          transactionId: transactionId,
          phase: 'recovered_previous_copy',
          source: entry,
        );
        continue;
      }

      // A present target with a different revision may have been changed by an
      // editor or sync tool while AKASHA was interrupted. Preserve every file.
      await _appendRecoveryOutcome(
        paths: paths,
        transactionId: transactionId,
        phase: 'recovery_needs_resolution',
        source: entry,
      );
    }
  }

  Future<void> _appendRecoveryOutcome({
    required _VaultWritePaths paths,
    required String transactionId,
    required String phase,
    required Map<String, dynamic> source,
  }) {
    return _appendEvidence(
      paths: paths,
      phase: phase,
      transactionId: transactionId,
      reason: source['reason']?.toString() ?? 'recovery',
      targetPath: source['target_path']?.toString() ?? paths.relativeTarget,
      stagingPath: source['staging_path']?.toString(),
      backupPath: source['backup_path']?.toString(),
      conflictPath: source['conflict_path']?.toString(),
      previousRevision: _revisionFromEvidence(source['previous_revision']),
      newRevision: _revisionFromEvidence(source['new_revision']),
      expectedRevision: _revisionFromEvidence(source['expected_revision']),
    );
  }

  Future<void> _appendEvidence({
    required _VaultWritePaths paths,
    required String phase,
    required String transactionId,
    required String reason,
    required String targetPath,
    String? stagingPath,
    String? backupPath,
    String? conflictPath,
    VaultFileRevision? previousRevision,
    VaultFileRevision? newRevision,
    VaultFileRevision? expectedRevision,
  }) async {
    final log = File(p.join(paths.recoveryRoot, transactionLogFileName));
    await log.parent.create(recursive: true);
    final entry = <String, Object?>{
      'version': 1,
      'transaction_id': transactionId,
      'phase': phase,
      'reason': reason,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'target_path': targetPath,
      if (stagingPath != null && stagingPath.isNotEmpty)
        'staging_path': stagingPath,
      if (backupPath != null && backupPath.isNotEmpty)
        'backup_path': backupPath,
      if (conflictPath != null && conflictPath.isNotEmpty)
        'conflict_path': conflictPath,
      if (expectedRevision != null)
        'expected_revision': expectedRevision.toJson(),
      if (previousRevision != null)
        'previous_revision': previousRevision.toJson(),
      if (newRevision != null) 'new_revision': newRevision.toJson(),
    };
    final sink = log.openWrite(mode: FileMode.append);
    try {
      sink.writeln(jsonEncode(entry));
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<void> _writeNewVerifiedFile(File destination, String content) async {
    await destination.parent.create(recursive: true);
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsString(content, flush: true);
    final expectedDigest = crypto.sha256
        .convert(utf8.encode(content))
        .toString();
    final revision = await VaultFileRevision.fromFile(temporary);
    if (revision.sha256 != expectedDigest) {
      throw StateError('Recovery artifact failed SHA-256 verification.');
    }
    await temporary.rename(destination.path);
  }

  Future<void> _hit(VaultRecoveryWriteCheckpoint checkpoint) async {
    final injector = _faultInjector;
    if (injector != null) await injector(checkpoint);
  }

  _VaultWritePaths _paths({
    required String vaultPath,
    required String targetPath,
  }) {
    final vaultRoot = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(targetPath));
    if (!p.isWithin(vaultRoot, target)) {
      throw ArgumentError.value(
        targetPath,
        'targetPath',
        'must be inside vault',
      );
    }
    final relativeTarget = _relative(vaultRoot, target);
    final recoveryRoot = p.join(vaultRoot, systemDirName, recoveryDirName);
    if (target == recoveryRoot || p.isWithin(recoveryRoot, target)) {
      throw ArgumentError.value(
        targetPath,
        'targetPath',
        'must not write through the recovery evidence path',
      );
    }
    return _VaultWritePaths(
      vaultRoot: vaultRoot,
      targetPath: target,
      relativeTarget: relativeTarget,
      recoveryRoot: recoveryRoot,
    );
  }

  static String _relative(String vaultPath, String targetPath) =>
      p.relative(targetPath, from: vaultPath).replaceAll('\\', '/');

  static String _stagingPath(String targetPath, String transactionId) {
    final parent = p.dirname(targetPath);
    final base = p.basename(targetPath);
    return p.join(parent, '.akasha_recovery_$transactionId.$base.tmp');
  }

  static String _transactionId() {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(36);
    return '${DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36)}_$random';
  }

  static String? _digestFromEvidence(Object? raw) {
    if (raw is! Map) return null;
    return raw['sha256']?.toString();
  }

  static VaultFileRevision? _revisionFromEvidence(Object? raw) {
    if (raw is! Map) return null;
    final exists = raw['exists'] == true;
    if (!exists) return const VaultFileRevision.missing();
    final length = raw['byte_length'];
    final modified = raw['modified_at'];
    return VaultFileRevision(
      exists: true,
      sha256: raw['sha256']?.toString(),
      byteLength: length is num ? length.toInt() : int.tryParse('$length'),
      modifiedAtUtc: DateTime.tryParse(modified?.toString() ?? '')?.toUtc(),
    );
  }

}

class _VaultWritePaths {
  const _VaultWritePaths({
    required this.vaultRoot,
    required this.targetPath,
    required this.relativeTarget,
    required this.recoveryRoot,
  });

  final String vaultRoot;
  final String targetPath;
  final String relativeTarget;
  final String recoveryRoot;
}

class _BatchWriteItem {
  _BatchWriteItem({
    required this.paths,
    required this.content,
    required this.expectedRevision,
    required this.previousRevision,
    required this.newRevision,
  });

  final _VaultWritePaths paths;
  final String content;
  final VaultFileRevision expectedRevision;
  final VaultFileRevision previousRevision;
  final VaultFileRevision newRevision;
  File? staged;
  File? backup;
}

class _ManifestWriteItem {
  const _ManifestWriteItem({
    required this.paths,
    required this.target,
    required this.staged,
    required this.backup,
    required this.previousRevision,
    required this.newRevision,
    required this.transactionId,
  });

  final _VaultWritePaths paths;
  final File target;
  final File staged;
  final File backup;
  final VaultFileRevision previousRevision;
  final VaultFileRevision newRevision;
  final String transactionId;
}
