import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import 'vault_trash_service.dart' show VaultTrashTransaction;

/// Checkpoints for fault-injection around recoverable trash transaction manifests.
enum TrashTransactionManifestCheckpoint {
  beforeTempWrite,
  afterTempBeforePromote,
  afterPreviousBeforePromote,
  afterPromoteBeforeVerify,
}

typedef TrashTransactionManifestFaultInjector =
    Future<void> Function(TrashTransactionManifestCheckpoint checkpoint);

/// Durable replace of `trash_transaction.json` using `.next` / `.previous`.
///
/// Guarantees that after any interruption at least one complete primary or
/// previous manifest remains, or a complete `.next` can be promoted on converge.
class VaultTrashTransactionManifestStore {
  VaultTrashTransactionManifestStore({this.faultInjector});

  final TrashTransactionManifestFaultInjector? faultInjector;

  static const primaryName = 'trash_transaction.json';
  static const nextName = '$primaryName.next';
  static const previousName = '$primaryName.previous';

  Future<void> write(
    Directory trashRoot,
    VaultTrashTransaction transaction,
  ) async {
    converge(trashRoot);

    final content = const JsonEncoder.withIndent(
      '  ',
    ).convert(transaction.toJson());
    final expectedHash = crypto.sha256.convert(utf8.encode(content)).toString();

    final primary = File(p.join(trashRoot.path, primaryName));
    final next = File(p.join(trashRoot.path, nextName));
    final previous = File(p.join(trashRoot.path, previousName));

    await faultInjector?.call(
      TrashTransactionManifestCheckpoint.beforeTempWrite,
    );

    next.writeAsStringSync(content, flush: true);
    _assertFileMatches(next, expectedHash);

    await faultInjector?.call(
      TrashTransactionManifestCheckpoint.afterTempBeforePromote,
    );

    if (primary.existsSync()) {
      if (previous.existsSync()) {
        previous.deleteSync();
      }
      primary.renameSync(previous.path);
    }

    await faultInjector?.call(
      TrashTransactionManifestCheckpoint.afterPreviousBeforePromote,
    );

    next.renameSync(primary.path);

    await faultInjector?.call(
      TrashTransactionManifestCheckpoint.afterPromoteBeforeVerify,
    );

    _assertFileMatches(primary, expectedHash);

    if (previous.existsSync()) {
      previous.deleteSync();
    }
  }

  /// Converge leftover `.next` / `.previous` into a complete primary when possible.
  void converge(Directory trashRoot) {
    final primary = File(p.join(trashRoot.path, primaryName));
    final next = File(p.join(trashRoot.path, nextName));
    final previous = File(p.join(trashRoot.path, previousName));

    if (next.existsSync()) {
      if (_isCompleteManifest(next)) {
        if (primary.existsSync() && !_isCompleteManifest(primary)) {
          primary.deleteSync();
        }
        if (!primary.existsSync()) {
          next.renameSync(primary.path);
        } else {
          next.deleteSync();
        }
      } else {
        next.deleteSync();
      }
    }

    if (!primary.existsSync() && previous.existsSync()) {
      if (_isCompleteManifest(previous)) {
        previous.renameSync(primary.path);
      }
    }

    if (primary.existsSync() &&
        !_isCompleteManifest(primary) &&
        previous.existsSync() &&
        _isCompleteManifest(previous)) {
      primary.deleteSync();
      previous.renameSync(primary.path);
    }

    if (previous.existsSync() &&
        primary.existsSync() &&
        _isCompleteManifest(primary)) {
      previous.deleteSync();
    }
  }

  VaultTrashTransaction? read(Directory trashRoot, {String? trashRootPath}) {
    final primary = File(p.join(trashRoot.path, primaryName));
    if (!primary.existsSync()) return null;
    try {
      final decoded = jsonDecode(primary.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return null;
      return VaultTrashTransaction.fromJson(
        decoded,
        trashRootPath: trashRootPath ?? trashRoot.path,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isCompleteManifest(File file) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return false;
      final tx = VaultTrashTransaction.fromJson(decoded);
      return tx.transactionId.isNotEmpty &&
          tx.vaultPath.isNotEmpty &&
          tx.recordKind.isNotEmpty &&
          tx.members.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _assertFileMatches(File file, String expectedHash) {
    final bytes = file.readAsBytesSync();
    final hash = crypto.sha256.convert(bytes).toString();
    if (hash != expectedHash) {
      throw StateError(
        'Trash transaction manifest hash mismatch at ${file.path}',
      );
    }
    jsonDecode(utf8.decode(bytes));
  }
}
