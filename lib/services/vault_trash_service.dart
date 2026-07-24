import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../core/archiving/canvas_record.dart';
import 'vault_recovery_write_service.dart';
import 'vault_trash_transaction_manifest.dart';

/// Wire/state-machine values for composite vault trash transactions.
enum VaultTrashTransactionState {
  prepared,
  moving,
  committed,
  restoring,
  restored,
  restoreConflict,
  rollbackRequired,
}

extension VaultTrashTransactionStateWire on VaultTrashTransactionState {
  String get wireName => name;

  static VaultTrashTransactionState? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in VaultTrashTransactionState.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

class VaultTrashEntry {
  const VaultTrashEntry({
    required this.vaultPath,
    required this.originalPath,
    required this.trashPath,
    required this.trashedAt,
  });

  final String vaultPath;
  final String originalPath;
  final String trashPath;
  final DateTime trashedAt;

  Map<String, Object?> toJson() => {
    'vaultPath': vaultPath,
    'originalPath': originalPath,
    'trashPath': trashPath,
    'trashedAt': trashedAt.toUtc().toIso8601String(),
  };

  factory VaultTrashEntry.fromJson(Map<String, dynamic> json) {
    return VaultTrashEntry(
      vaultPath: json['vaultPath']?.toString() ?? '',
      originalPath: json['originalPath']?.toString() ?? '',
      trashPath: json['trashPath']?.toString() ?? '',
      trashedAt:
          DateTime.tryParse(json['trashedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  String get originalFileName => p.basename(originalPath);

  String originalPathRelativeToVault() {
    if (vaultPath.isEmpty || originalPath.isEmpty) return originalPath;
    return p.relative(originalPath, from: vaultPath);
  }
}

class VaultTrashMember {
  const VaultTrashMember({
    required this.relativeOriginalPath,
    required this.relativeTrashPath,
    required this.size,
    required this.sha256,
    this.required = true,
  });

  final String relativeOriginalPath;
  final String relativeTrashPath;
  final int size;
  final String sha256;
  final bool required;

  Map<String, Object?> toJson() => {
    'relativeOriginalPath': relativeOriginalPath,
    'relativeTrashPath': relativeTrashPath,
    'size': size,
    'sha256': sha256,
    'required': required,
  };

  factory VaultTrashMember.fromJson(Map<String, dynamic> json) {
    return VaultTrashMember(
      relativeOriginalPath: json['relativeOriginalPath']?.toString() ?? '',
      relativeTrashPath: json['relativeTrashPath']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      sha256: json['sha256']?.toString() ?? '',
      required: json['required'] as bool? ?? true,
    );
  }
}

class VaultTrashTransaction {
  const VaultTrashTransaction({
    this.version = 1,
    required this.transactionId,
    required this.vaultPath,
    required this.recordKind,
    required this.recordId,
    this.title,
    this.reason,
    required this.state,
    required this.createdAt,
    required this.members,
    this.trashRootPath,
  });

  final int version;
  final String transactionId;
  final String vaultPath;
  final String recordKind;
  final String recordId;
  final String? title;
  final String? reason;

  /// Serialized [VaultTrashTransactionState.wireName] value.
  final String state;
  final DateTime createdAt;
  final List<VaultTrashMember> members;
  final String? trashRootPath;

  VaultTrashTransactionState? get parsedState =>
      VaultTrashTransactionStateWire.tryParse(state);

  Map<String, Object?> toJson() => {
    'version': version,
    'transactionId': transactionId,
    'vaultPath': vaultPath,
    'recordKind': recordKind,
    'recordId': recordId,
    if (title != null) 'title': title,
    if (reason != null) 'reason': reason,
    'state': state,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory VaultTrashTransaction.fromJson(
    Map<String, dynamic> json, {
    String? trashRootPath,
  }) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    return VaultTrashTransaction(
      version: (json['version'] as num?)?.toInt() ?? 1,
      transactionId: json['transactionId']?.toString() ?? '',
      vaultPath: json['vaultPath']?.toString() ?? '',
      recordKind: json['recordKind']?.toString() ?? '',
      recordId: json['recordId']?.toString() ?? '',
      title: json['title']?.toString(),
      reason: json['reason']?.toString(),
      state: json['state']?.toString() ?? 'committed',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      members: rawMembers
          .map(
            (m) =>
                VaultTrashMember.fromJson(Map<String, dynamic>.from(m as Map)),
          )
          .toList(),
      trashRootPath: trashRootPath,
    );
  }
}

class VaultTrashRecoveryResult {
  const VaultTrashRecoveryResult({
    required this.transactionId,
    required this.previousState,
    required this.resultState,
    required this.action,
    this.error,
  });

  final String transactionId;
  final String previousState;
  final String resultState;

  /// cleaned | committed | restored | markedRollbackRequired | skipped | error
  final String action;
  final String? error;
}

class CanvasTrashResult {
  const CanvasTrashResult({
    required this.succeeded,
    this.transaction,
    this.error,
  });

  final bool succeeded;
  final VaultTrashTransaction? transaction;
  final String? error;
}

class CanvasRestoreResult {
  const CanvasRestoreResult({
    required this.succeeded,
    this.state,
    this.error,
    this.errorCode,
  });

  final bool succeeded;
  final String? state;
  final String? error;

  /// Structured code such as [invalidStateErrorCode].
  final String? errorCode;

  static const invalidStateErrorCode = 'invalidState';
}

class VaultTrashService {
  const VaultTrashService({this.manifestStore});

  /// Optional injectable store (fault-injection / tests). Defaults to durable store.
  final VaultTrashTransactionManifestStore? manifestStore;

  static const trashDirName = '.trash';
  static const manifestFileName = 'trash_entry.json';
  static const transactionManifestFileName =
      VaultTrashTransactionManifestStore.primaryName;

  /// Current user canvas ID contract: `cv_u_` + 8 lowercase alphanumerics.
  static final RegExp canvasIdPattern = RegExp(r'^cv_u_[a-z0-9]{8}$');

  VaultTrashTransactionManifestStore get _manifests =>
      manifestStore ?? VaultTrashTransactionManifestStore();

  Future<VaultTrashEntry?> moveFileToTrash({
    required String vaultPath,
    required String absolutePath,
  }) async {
    final source = File(absolutePath);
    if (!await source.exists()) return null;

    final normalizedVault = _normalizeAbsolute(vaultPath);
    final normalizedSource = _normalizeAbsolute(source.path);
    _assertInsideVault(
      vaultPath: normalizedVault,
      absolutePath: normalizedSource,
    );
    _assertNotAlreadyTrash(
      vaultPath: normalizedVault,
      absolutePath: normalizedSource,
    );
    _assertNotCanvasMember(
      vaultPath: normalizedVault,
      absolutePath: normalizedSource,
    );

    final trashedAt = DateTime.now().toUtc();
    final trashRoot = await _createTrashRoot(
      vaultPath: normalizedVault,
      trashedAt: trashedAt,
    );
    final relativeSource = p.relative(normalizedSource, from: normalizedVault);
    final targetPath = p.join(trashRoot.path, relativeSource);
    await Directory(p.dirname(targetPath)).create(recursive: true);

    final entry = VaultTrashEntry(
      vaultPath: normalizedVault,
      originalPath: normalizedSource,
      trashPath: targetPath,
      trashedAt: trashedAt,
    );
    await _writeManifest(trashRoot, entry);
    final moved = await source.rename(targetPath);
    return VaultTrashEntry(
      vaultPath: entry.vaultPath,
      originalPath: entry.originalPath,
      trashPath: moved.path,
      trashedAt: entry.trashedAt,
    );
  }

  Future<CanvasTrashResult> moveCanvasToTrash({
    required String vaultPath,
    required String canvasId,
    String? reason,
  }) async {
    if (vaultPath.isEmpty) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Invalid vault path.',
      );
    }
    final idError = validateCanvasId(canvasId);
    if (idError != null) {
      return CanvasTrashResult(succeeded: false, error: idError);
    }

    final normalizedVault = _normalizeAbsolute(vaultPath);
    final canvasesRoot = Directory(p.join(normalizedVault, 'canvases'));
    final canvasDir = Directory(p.join(canvasesRoot.path, canvasId));
    final normalizedCanvasDir = _normalizeAbsolute(canvasDir.path);
    final normalizedCanvasesRoot = _normalizeAbsolute(canvasesRoot.path);

    if (p.dirname(normalizedCanvasDir) != normalizedCanvasesRoot) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Canvas directory parent must be <vault>/canvases.',
      );
    }

    _assertInsideVault(
      vaultPath: normalizedVault,
      absolutePath: normalizedCanvasDir,
    );
    _assertNotAlreadyTrash(
      vaultPath: normalizedVault,
      absolutePath: normalizedCanvasDir,
    );

    if (!await canvasDir.exists()) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Canvas directory does not exist.',
      );
    }

    final stat = await canvasDir.stat();
    if (stat.type == FileSystemEntityType.link) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Canvas directory is a link or junction.',
      );
    }

    final entities = await canvasDir.list(recursive: false).toList();
    final regularFiles = <File>[];
    for (final entity in entities) {
      final entityStat = await entity.stat();
      if (entityStat.type == FileSystemEntityType.link) {
        return const CanvasTrashResult(
          succeeded: false,
          error: 'Canvas directory contains a symlink or junction.',
        );
      }
      if (entity is Directory) {
        return const CanvasTrashResult(
          succeeded: false,
          error: 'Canvas directory contains nested directories.',
        );
      }
      if (entity is File) {
        regularFiles.add(entity);
      }
    }

    final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
    final layoutFile = File(p.join(canvasDir.path, 'layout.json'));

    if (!await mdFile.exists() || !await layoutFile.exists()) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Canvas composite members (canvas.md, layout.json) missing.',
      );
    }

    // Validate canvas.md frontmatter & layoutRef
    String? title;
    try {
      final mdContent = await mdFile.readAsString();
      final record = CanvasRecord.fromMarkdown(mdContent);
      if (record == null || record.canvasId != canvasId) {
        return const CanvasTrashResult(
          succeeded: false,
          error: 'Canvas ID in canvas.md does not match target canvas ID.',
        );
      }
      if (record.layoutRef != './layout.json') {
        return const CanvasTrashResult(
          succeeded: false,
          error: 'layout_ref in canvas.md is not ./layout.json',
        );
      }
      title = record.title;
    } catch (e) {
      return CanvasTrashResult(
        succeeded: false,
        error: 'Failed to parse canvas.md: $e',
      );
    }

    // Validate layout.json parsing & canvas_id
    try {
      final layoutContent = await layoutFile.readAsString();
      final json = jsonDecode(layoutContent) as Map<String, dynamic>;
      final jsonCanvasId = json['canvas_id']?.toString() ?? '';
      if (jsonCanvasId != canvasId) {
        return const CanvasTrashResult(
          succeeded: false,
          error: 'Canvas ID in layout.json does not match target canvas ID.',
        );
      }
    } catch (e) {
      return CanvasTrashResult(
        succeeded: false,
        error: 'Failed to parse layout.json: $e',
      );
    }

    final trashedAt = DateTime.now().toUtc();
    final trashRoot = await _createTrashRoot(
      vaultPath: normalizedVault,
      trashedAt: trashedAt,
    );
    final transactionId = p.basename(trashRoot.path);

    final relCanvasDir = p.relative(normalizedCanvasDir, from: normalizedVault);
    final targetCanvasDir = p.join(trashRoot.path, relCanvasDir);

    final members = <VaultTrashMember>[];
    for (final file in regularFiles) {
      final bytes = await file.readAsBytes();
      final name = p.basename(file.path);
      final required = name == 'canvas.md' || name == 'layout.json';
      members.add(
        VaultTrashMember(
          relativeOriginalPath: p.join(relCanvasDir, name),
          relativeTrashPath: p.relative(
            p.join(targetCanvasDir, name),
            from: trashRoot.path,
          ),
          size: bytes.length,
          sha256: crypto.sha256.convert(bytes).toString(),
          required: required,
        ),
      );
    }

    // State 1: prepared
    final preparedTx = VaultTrashTransaction(
      version: 1,
      transactionId: transactionId,
      vaultPath: normalizedVault,
      recordKind: 'canvas',
      recordId: canvasId,
      title: title,
      reason: reason ?? 'user_delete',
      state: VaultTrashTransactionState.prepared.wireName,
      createdAt: trashedAt,
      members: members,
      trashRootPath: trashRoot.path,
    );
    await _writeTransactionManifest(trashRoot, preparedTx);

    // State 2: moving
    final movingTx = VaultTrashTransaction(
      version: 1,
      transactionId: transactionId,
      vaultPath: normalizedVault,
      recordKind: 'canvas',
      recordId: canvasId,
      title: title,
      reason: reason ?? 'user_delete',
      state: VaultTrashTransactionState.moving.wireName,
      createdAt: trashedAt,
      members: members,
      trashRootPath: trashRoot.path,
    );
    await _writeTransactionManifest(trashRoot, movingTx);

    // Perform rename of the whole canvas directory (required + sidecar files).
    await Directory(p.dirname(targetCanvasDir)).create(recursive: true);
    await canvasDir.rename(targetCanvasDir);

    final postMoveError = await _verifyMembersAt(
      rootPath: trashRoot.path,
      members: members,
      relativePathOf: (m) => m.relativeTrashPath,
    );
    if (postMoveError != null) {
      final rollbackTx = VaultTrashTransaction(
        version: 1,
        transactionId: transactionId,
        vaultPath: normalizedVault,
        recordKind: 'canvas',
        recordId: canvasId,
        title: title,
        reason: reason ?? 'user_delete',
        state: VaultTrashTransactionState.rollbackRequired.wireName,
        createdAt: trashedAt,
        members: members,
        trashRootPath: trashRoot.path,
      );
      await _writeTransactionManifest(trashRoot, rollbackTx);
      return CanvasTrashResult(
        succeeded: false,
        transaction: rollbackTx,
        error: postMoveError,
      );
    }

    // State 3: committed
    final committedTx = VaultTrashTransaction(
      version: 1,
      transactionId: transactionId,
      vaultPath: normalizedVault,
      recordKind: 'canvas',
      recordId: canvasId,
      title: title,
      reason: reason ?? 'user_delete',
      state: VaultTrashTransactionState.committed.wireName,
      createdAt: trashedAt,
      members: members,
      trashRootPath: trashRoot.path,
    );
    await _writeTransactionManifest(trashRoot, committedTx);

    return CanvasTrashResult(succeeded: true, transaction: committedTx);
  }

  /// Returns null when [canvasId] is a safe single-segment canvas identity.
  static String? validateCanvasId(String canvasId) {
    if (canvasId.isEmpty) return 'Canvas ID is empty.';
    if (p.isAbsolute(canvasId)) {
      return 'Canvas ID must not be an absolute path.';
    }
    if (canvasId.contains('/') || canvasId.contains(r'\')) {
      return 'Canvas ID must not contain path separators.';
    }
    final parts = p.split(canvasId);
    if (parts.length != 1) return 'Canvas ID must be a single path segment.';
    final segment = parts.single;
    if (segment == '.' || segment == '..') {
      return 'Canvas ID must not be "." or "..".';
    }
    if (p.normalize(canvasId) != canvasId) {
      return 'Canvas ID must already be normalized.';
    }
    if (!canvasIdPattern.hasMatch(canvasId)) {
      return 'Canvas ID must match ${canvasIdPattern.pattern}.';
    }
    return null;
  }

  Future<bool> restoreFile(
    VaultTrashEntry entry, {
    bool overwrite = false,
  }) async {
    final trashFile = File(entry.trashPath);
    if (!await trashFile.exists()) return false;

    final normalizedVault = _normalizeAbsolute(entry.vaultPath);
    final normalizedOriginal = _normalizeAbsolute(entry.originalPath);
    _assertInsideVault(
      vaultPath: normalizedVault,
      absolutePath: normalizedOriginal,
    );
    _assertNotAlreadyTrash(
      vaultPath: normalizedVault,
      absolutePath: normalizedOriginal,
    );

    final originalFile = File(normalizedOriginal);
    if (await originalFile.exists()) {
      if (!overwrite) return false;
      await moveFileToTrash(
        vaultPath: normalizedVault,
        absolutePath: originalFile.path,
      );
    }

    await originalFile.parent.create(recursive: true);
    await trashFile.rename(originalFile.path);
    await _deleteTrashRootForEntry(entry);
    return true;
  }

  Future<CanvasRestoreResult> restoreCanvasTransaction(
    VaultTrashTransaction transaction,
  ) async {
    final parsed = transaction.parsedState;
    if (parsed != VaultTrashTransactionState.committed) {
      return CanvasRestoreResult(
        succeeded: false,
        state: transaction.state,
        errorCode: CanvasRestoreResult.invalidStateErrorCode,
        error:
            'invalidState: public restore requires committed, got ${transaction.state}',
      );
    }
    return _restoreCanvasTransactionBody(transaction);
  }

  /// Recovery-only resume for interrupted restores (`restoring` state).
  Future<CanvasRestoreResult> resumeInterruptedCanvasRestore(
    VaultTrashTransaction transaction,
  ) async {
    final parsed = transaction.parsedState;
    if (parsed != VaultTrashTransactionState.restoring) {
      return CanvasRestoreResult(
        succeeded: false,
        state: transaction.state,
        errorCode: CanvasRestoreResult.invalidStateErrorCode,
        error:
            'invalidState: interrupted restore resume requires restoring, got ${transaction.state}',
      );
    }
    return _restoreCanvasTransactionBody(transaction);
  }

  Future<CanvasRestoreResult> _restoreCanvasTransactionBody(
    VaultTrashTransaction transaction,
  ) async {
    final manifestValidationError = _validateManifestPaths(transaction);
    if (manifestValidationError != null) {
      return CanvasRestoreResult(
        succeeded: false,
        error: manifestValidationError,
      );
    }

    final normalizedVault = _normalizeAbsolute(transaction.vaultPath);
    final trashRoot = transaction.trashRootPath != null
        ? Directory(transaction.trashRootPath!)
        : Directory(
            p.join(normalizedVault, trashDirName, transaction.transactionId),
          );

    if (!await trashRoot.exists()) {
      return const CanvasRestoreResult(
        succeeded: false,
        error: 'Trash transaction directory does not exist.',
      );
    }

    // NON-DESTRUCTIVE: Never overwrite existing files/directories!
    for (final member in transaction.members) {
      final origPath = p.join(normalizedVault, member.relativeOriginalPath);
      if (await File(origPath).exists() || await Directory(origPath).exists()) {
        return CanvasRestoreResult(
          succeeded: false,
          state: VaultTrashTransactionState.restoreConflict.wireName,
          error:
              'Original target already exists ($origPath). Automatic overwrite is strictly forbidden.',
        );
      }
    }

    final canvasDirRel = p.dirname(
      transaction.members.first.relativeOriginalPath,
    );
    final targetCanvasDir = Directory(p.join(normalizedVault, canvasDirRel));
    if (await targetCanvasDir.exists()) {
      return CanvasRestoreResult(
        succeeded: false,
        state: VaultTrashTransactionState.restoreConflict.wireName,
        error:
            'Target canvas directory already exists (${targetCanvasDir.path}). Automatic overwrite is strictly forbidden.',
      );
    }

    // Verify size + SHA-256 of trash members before mutating anything.
    final trashVerifyError = await _verifyMembersAt(
      rootPath: trashRoot.path,
      members: transaction.members,
      relativePathOf: (m) => m.relativeTrashPath,
    );
    if (trashVerifyError != null) {
      return CanvasRestoreResult(succeeded: false, error: trashVerifyError);
    }

    // State 1: restoring
    final restoringTx = VaultTrashTransaction(
      version: transaction.version,
      transactionId: transaction.transactionId,
      vaultPath: transaction.vaultPath,
      recordKind: transaction.recordKind,
      recordId: transaction.recordId,
      title: transaction.title,
      reason: transaction.reason,
      state: VaultTrashTransactionState.restoring.wireName,
      createdAt: transaction.createdAt,
      members: transaction.members,
      trashRootPath: trashRoot.path,
    );
    await _writeTransactionManifest(trashRoot, restoringTx);

    // Perform rename
    final trashCanvasDir = Directory(
      p.dirname(
        p.join(trashRoot.path, transaction.members.first.relativeTrashPath),
      ),
    );

    await targetCanvasDir.parent.create(recursive: true);
    await trashCanvasDir.rename(targetCanvasDir.path);

    final postRestoreError = await _verifyMembersAt(
      rootPath: normalizedVault,
      members: transaction.members,
      relativePathOf: (m) => m.relativeOriginalPath,
    );
    if (postRestoreError != null) {
      final rollbackTx = VaultTrashTransaction(
        version: transaction.version,
        transactionId: transaction.transactionId,
        vaultPath: transaction.vaultPath,
        recordKind: transaction.recordKind,
        recordId: transaction.recordId,
        title: transaction.title,
        reason: transaction.reason,
        state: VaultTrashTransactionState.rollbackRequired.wireName,
        createdAt: transaction.createdAt,
        members: transaction.members,
        trashRootPath: trashRoot.path,
      );
      await _writeTransactionManifest(trashRoot, rollbackTx);
      return CanvasRestoreResult(
        succeeded: false,
        state: VaultTrashTransactionState.rollbackRequired.wireName,
        error: postRestoreError,
      );
    }

    // State 2: restored (Keep transaction record with restored state)
    final restoredTx = VaultTrashTransaction(
      version: transaction.version,
      transactionId: transaction.transactionId,
      vaultPath: transaction.vaultPath,
      recordKind: transaction.recordKind,
      recordId: transaction.recordId,
      title: transaction.title,
      reason: transaction.reason,
      state: VaultTrashTransactionState.restored.wireName,
      createdAt: transaction.createdAt,
      members: transaction.members,
      trashRootPath: trashRoot.path,
    );
    await _writeTransactionManifest(trashRoot, restoredTx);

    return CanvasRestoreResult(
      succeeded: true,
      state: VaultTrashTransactionState.restored.wireName,
    );
  }

  Future<List<VaultTrashEntry>> listEntries({required String vaultPath}) async {
    return listEntriesSync(vaultPath: vaultPath);
  }

  List<VaultTrashEntry> listEntriesSync({required String vaultPath}) {
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final trashRoot = Directory(p.join(normalizedVault, trashDirName));
    if (!trashRoot.existsSync()) return const [];

    final entries = <VaultTrashEntry>[];
    for (final entity in trashRoot.listSync(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! Directory) continue;
      final manifestFile = File(p.join(entity.path, manifestFileName));
      if (!manifestFile.existsSync()) continue;
      try {
        final decoded = jsonDecode(manifestFile.readAsStringSync());
        if (decoded is! Map<String, dynamic>) continue;
        final entry = VaultTrashEntry.fromJson(decoded);
        if (entry.vaultPath.isEmpty ||
            entry.originalPath.isEmpty ||
            entry.trashPath.isEmpty) {
          continue;
        }
        if (!File(entry.trashPath).existsSync()) continue;
        entries.add(entry);
      } catch (error) {
        assert(() {
          // ignore: avoid_print
          print('VaultTrashService.listEntries skip: $error');
          return true;
        }());
      }
    }

    entries.sort((a, b) => b.trashedAt.compareTo(a.trashedAt));
    return entries;
  }

  Future<List<VaultTrashTransaction>> listTransactions({
    required String vaultPath,
  }) async {
    return listTransactionsSync(vaultPath: vaultPath);
  }

  List<VaultTrashTransaction> listTransactionsSync({
    required String vaultPath,
  }) {
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final trashRoot = Directory(p.join(normalizedVault, trashDirName));
    if (!trashRoot.existsSync()) return const [];

    final transactions = <VaultTrashTransaction>[];
    for (final entity in trashRoot.listSync(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! Directory) continue;
      _manifests.converge(entity);
      final manifestFile = File(
        p.join(entity.path, transactionManifestFileName),
      );
      if (!manifestFile.existsSync()) continue;
      try {
        final decoded = jsonDecode(manifestFile.readAsStringSync());
        if (decoded is! Map<String, dynamic>) continue;
        final tx = VaultTrashTransaction.fromJson(
          decoded,
          trashRootPath: entity.path,
        );
        if (tx.transactionId.isEmpty || tx.vaultPath.isEmpty) continue;
        if (tx.state == VaultTrashTransactionState.restored.wireName) continue;
        transactions.add(tx);
      } catch (error) {
        // Skip unreadable/corrupt manifests; listing must not abort.
        assert(() {
          // ignore: avoid_print
          print('VaultTrashService.listTransactions skip: $error');
          return true;
        }());
      }
    }

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  Future<List<String>> recoverPendingTrashTransactions({
    required String vaultPath,
  }) async {
    final details = await recoverPendingTrashTransactionsDetail(
      vaultPath: vaultPath,
    );
    return details.map((d) => d.transactionId).toList();
  }

  Future<List<VaultTrashRecoveryResult>> recoverPendingTrashTransactionsDetail({
    required String vaultPath,
  }) async {
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final trashRoot = Directory(p.join(normalizedVault, trashDirName));
    if (!await trashRoot.exists()) return const [];

    final results = <VaultTrashRecoveryResult>[];
    await for (final entity in trashRoot.list(recursive: false)) {
      if (entity is! Directory) continue;
      _manifests.converge(entity);
      final manifestFile = File(
        p.join(entity.path, transactionManifestFileName),
      );
      if (!await manifestFile.exists()) continue;

      try {
        final decoded = jsonDecode(await manifestFile.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        final tx = VaultTrashTransaction.fromJson(
          decoded,
          trashRootPath: entity.path,
        );

        final validationErr = _validateManifestPaths(
          tx,
          expectedVaultPath: normalizedVault,
        );
        if (validationErr != null) {
          results.add(
            VaultTrashRecoveryResult(
              transactionId: p.basename(entity.path),
              previousState: tx.state,
              resultState: 'error',
              action: 'error',
              error: validationErr,
            ),
          );
          continue;
        }

        if (tx.state == VaultTrashTransactionState.prepared.wireName ||
            tx.state == VaultTrashTransactionState.moving.wireName) {
          final presence = await _inspectMemberPresence(
            vaultPath: normalizedVault,
            trashRootPath: entity.path,
            members: tx.members,
          );

          if (presence.origFound == tx.members.length &&
              presence.trashFound == 0 &&
              presence.originalHashesValid) {
            await entity.delete(recursive: true);
            results.add(
              VaultTrashRecoveryResult(
                transactionId: tx.transactionId,
                previousState: tx.state,
                resultState: 'cleaned',
                action: 'cleaned',
              ),
            );
          } else if (presence.origFound == 0 &&
              presence.trashFound == tx.members.length &&
              presence.trashHashesValid) {
            final committedTx = VaultTrashTransaction(
              version: tx.version,
              transactionId: tx.transactionId,
              vaultPath: tx.vaultPath,
              recordKind: tx.recordKind,
              recordId: tx.recordId,
              title: tx.title,
              reason: tx.reason,
              state: VaultTrashTransactionState.committed.wireName,
              createdAt: tx.createdAt,
              members: tx.members,
              trashRootPath: entity.path,
            );
            await _writeTransactionManifest(
              Directory(entity.path),
              committedTx,
            );
            results.add(
              VaultTrashRecoveryResult(
                transactionId: tx.transactionId,
                previousState: tx.state,
                resultState: VaultTrashTransactionState.committed.wireName,
                action: 'committed',
              ),
            );
          } else {
            final rollbackTx = VaultTrashTransaction(
              version: tx.version,
              transactionId: tx.transactionId,
              vaultPath: tx.vaultPath,
              recordKind: tx.recordKind,
              recordId: tx.recordId,
              title: tx.title,
              reason: tx.reason,
              state: VaultTrashTransactionState.rollbackRequired.wireName,
              createdAt: tx.createdAt,
              members: tx.members,
              trashRootPath: entity.path,
            );
            await _writeTransactionManifest(Directory(entity.path), rollbackTx);
            results.add(
              VaultTrashRecoveryResult(
                transactionId: tx.transactionId,
                previousState: tx.state,
                resultState:
                    VaultTrashTransactionState.rollbackRequired.wireName,
                action: 'markedRollbackRequired',
                error: 'Partial presence or hash mismatch during recovery',
              ),
            );
          }
        } else if (tx.state == VaultTrashTransactionState.restoring.wireName) {
          final presence = await _inspectMemberPresence(
            vaultPath: normalizedVault,
            trashRootPath: entity.path,
            members: tx.members,
          );

          if (presence.origFound == 0 &&
              presence.trashFound == tx.members.length &&
              presence.trashHashesValid) {
            final restoreRes = await resumeInterruptedCanvasRestore(tx);
            if (restoreRes.succeeded) {
              results.add(
                VaultTrashRecoveryResult(
                  transactionId: tx.transactionId,
                  previousState: tx.state,
                  resultState: VaultTrashTransactionState.restored.wireName,
                  action: 'restored',
                ),
              );
            } else {
              results.add(
                VaultTrashRecoveryResult(
                  transactionId: tx.transactionId,
                  previousState: tx.state,
                  resultState:
                      restoreRes.state ??
                      VaultTrashTransactionState.restoreConflict.wireName,
                  action: 'error',
                  error: restoreRes.error,
                ),
              );
            }
          } else if (presence.origFound == tx.members.length &&
              presence.trashFound == 0 &&
              presence.originalHashesValid) {
            final restoredTx = VaultTrashTransaction(
              version: tx.version,
              transactionId: tx.transactionId,
              vaultPath: tx.vaultPath,
              recordKind: tx.recordKind,
              recordId: tx.recordId,
              title: tx.title,
              reason: tx.reason,
              state: VaultTrashTransactionState.restored.wireName,
              createdAt: tx.createdAt,
              members: tx.members,
              trashRootPath: entity.path,
            );
            await _writeTransactionManifest(Directory(entity.path), restoredTx);
            results.add(
              VaultTrashRecoveryResult(
                transactionId: tx.transactionId,
                previousState: tx.state,
                resultState: VaultTrashTransactionState.restored.wireName,
                action: 'restored',
              ),
            );
          } else {
            final rollbackTx = VaultTrashTransaction(
              version: tx.version,
              transactionId: tx.transactionId,
              vaultPath: tx.vaultPath,
              recordKind: tx.recordKind,
              recordId: tx.recordId,
              title: tx.title,
              reason: tx.reason,
              state: VaultTrashTransactionState.rollbackRequired.wireName,
              createdAt: tx.createdAt,
              members: tx.members,
              trashRootPath: entity.path,
            );
            await _writeTransactionManifest(Directory(entity.path), rollbackTx);
            results.add(
              VaultTrashRecoveryResult(
                transactionId: tx.transactionId,
                previousState: tx.state,
                resultState:
                    VaultTrashTransactionState.rollbackRequired.wireName,
                action: 'markedRollbackRequired',
                error:
                    'Partial presence or hash mismatch during restore recovery',
              ),
            );
          }
        }
      } catch (e) {
        results.add(
          VaultTrashRecoveryResult(
            transactionId: p.basename(entity.path),
            previousState: 'unknown',
            resultState: 'error',
            action: 'error',
            error: e.toString(),
          ),
        );
      }
    }

    return results;
  }

  Future<bool> deleteEntryPermanently(VaultTrashEntry entry) async {
    final trashFile = File(entry.trashPath);
    final trashRoot = _trashRootForEntry(entry);
    if (await trashRoot.exists()) {
      await trashRoot.delete(recursive: true);
      return true;
    }
    if (await trashFile.exists()) {
      await trashFile.delete();
      return true;
    }
    return false;
  }

  Future<bool> deleteTransactionPermanently(
    VaultTrashTransaction transaction,
  ) async {
    final parsed = transaction.parsedState;
    if (parsed != VaultTrashTransactionState.committed) {
      return false;
    }

    final validationError = _validateManifestPaths(transaction);
    if (validationError != null) return false;

    final normalizedVault = _normalizeAbsolute(transaction.vaultPath);
    final trashDir = Directory(p.join(normalizedVault, trashDirName));
    final trashRoot = transaction.trashRootPath != null
        ? Directory(_normalizeAbsolute(transaction.trashRootPath!))
        : Directory(
            p.join(normalizedVault, trashDirName, transaction.transactionId),
          );

    // Validate trashRoot is strictly inside <vault>/.trash/ and matches transactionId
    if (!p.isWithin(trashDir.path, trashRoot.path) ||
        p.basename(trashRoot.path) != transaction.transactionId) {
      return false;
    }

    if (await trashRoot.exists()) {
      await trashRoot.delete(recursive: true);
      return true;
    }
    return false;
  }

  static String? _validateManifestPaths(
    VaultTrashTransaction transaction, {
    String? expectedVaultPath,
  }) {
    if (transaction.recordKind != 'canvas') {
      return 'Unsupported recordKind: ${transaction.recordKind}';
    }
    if (transaction.recordId.trim().isEmpty) {
      return 'Empty recordId';
    }
    final recordIdError = validateCanvasId(transaction.recordId);
    if (recordIdError != null) {
      return 'Invalid recordId: $recordIdError';
    }
    if (transaction.transactionId.trim().isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_\-\.:]+$').hasMatch(transaction.transactionId)) {
      return 'Invalid transactionId format';
    }
    if (transaction.members.length < 2) {
      return 'Canvas transaction must contain at least canvas.md and layout.json';
    }

    final normalizedVault = _normalizeAbsolute(transaction.vaultPath);
    if (expectedVaultPath != null &&
        normalizedVault != _normalizeAbsolute(expectedVaultPath)) {
      return 'Transaction vaultPath does not match expected vaultPath';
    }

    final expectedMdRel = p.normalize(
      p.join('canvases', transaction.recordId, 'canvas.md'),
    );
    final expectedJsonRel = p.normalize(
      p.join('canvases', transaction.recordId, 'layout.json'),
    );

    final expectedTrashRoot = _normalizeAbsolute(
      p.join(normalizedVault, trashDirName, transaction.transactionId),
    );
    if (transaction.trashRootPath != null) {
      final normTrashRootPath = _normalizeAbsolute(transaction.trashRootPath!);
      if (normTrashRootPath != expectedTrashRoot) {
        return 'trashRootPath must match <vault>/.trash/<transactionId>';
      }
    }

    final trashRootForMembers = transaction.trashRootPath != null
        ? _normalizeAbsolute(transaction.trashRootPath!)
        : expectedTrashRoot;

    final memberOriginals = <String>[];
    final memberTrashPaths = <String>[];
    var mdCount = 0;
    var jsonCount = 0;
    for (final member in transaction.members) {
      final origParts = p.split(member.relativeOriginalPath);
      final trashParts = p.split(member.relativeTrashPath);

      if (p.isAbsolute(member.relativeOriginalPath) ||
          p.isAbsolute(member.relativeTrashPath) ||
          origParts.contains('..') ||
          trashParts.contains('..')) {
        return 'Path traversal or absolute path detected in transaction member';
      }

      final absOrig = _normalizeAbsolute(
        p.join(normalizedVault, member.relativeOriginalPath),
      );
      if (!p.isWithin(normalizedVault, absOrig)) {
        return 'Member original path outside vault: $absOrig';
      }

      final absTrash = _normalizeAbsolute(
        p.join(trashRootForMembers, member.relativeTrashPath),
      );
      if (!p.isWithin(trashRootForMembers, absTrash)) {
        return 'Member trash path outside transaction root: $absTrash';
      }

      final expectedMemberRel = p.normalize(
        p.join(
          'canvases',
          transaction.recordId,
          p.basename(member.relativeOriginalPath),
        ),
      );
      if (p.normalize(member.relativeOriginalPath) != expectedMemberRel) {
        return 'Transaction member original paths must stay under canvases/<recordId>/';
      }
      if (p.normalize(member.relativeTrashPath) != expectedMemberRel) {
        return 'Transaction member trash paths must match canvases/<recordId>/ layout';
      }

      final origNorm = p.normalize(member.relativeOriginalPath);
      final trashNorm = p.normalize(member.relativeTrashPath);
      memberOriginals.add(origNorm);
      memberTrashPaths.add(trashNorm);
      if (origNorm == expectedMdRel) mdCount++;
      if (origNorm == expectedJsonRel) jsonCount++;
    }
    if (memberOriginals.toSet().length != memberOriginals.length ||
        memberTrashPaths.toSet().length != memberTrashPaths.length) {
      return 'Duplicate transaction members are not allowed';
    }
    if (mdCount != 1 || jsonCount != 1) {
      return 'Canvas transaction must contain exactly one canvas.md and one layout.json';
    }

    return null;
  }

  static Future<String?> _verifyMembersAt({
    required String rootPath,
    required List<VaultTrashMember> members,
    required String Function(VaultTrashMember member) relativePathOf,
  }) async {
    for (final member in members) {
      final file = File(p.join(rootPath, relativePathOf(member)));
      if (!file.existsSync()) {
        return 'Member file missing: ${relativePathOf(member)}';
      }
      final bytes = file.readAsBytesSync();
      if (bytes.length != member.size) {
        return 'Size mismatch for member: ${relativePathOf(member)}';
      }
      final hash = crypto.sha256.convert(bytes).toString();
      if (hash != member.sha256) {
        return 'SHA-256 hash mismatch for member: ${relativePathOf(member)}';
      }
    }
    return null;
  }

  static Future<_MemberPresence> _inspectMemberPresence({
    required String vaultPath,
    required String trashRootPath,
    required List<VaultTrashMember> members,
  }) async {
    var origFound = 0;
    var trashFound = 0;
    var originalHashesValid = true;
    var trashHashesValid = true;

    for (final member in members) {
      final origFile = File(p.join(vaultPath, member.relativeOriginalPath));
      final trashFile = File(p.join(trashRootPath, member.relativeTrashPath));

      if (await origFile.exists()) {
        origFound++;
        final bytes = await origFile.readAsBytes();
        if (bytes.length != member.size ||
            crypto.sha256.convert(bytes).toString() != member.sha256) {
          originalHashesValid = false;
        }
      }
      if (await trashFile.exists()) {
        trashFound++;
        final bytes = await trashFile.readAsBytes();
        if (bytes.length != member.size ||
            crypto.sha256.convert(bytes).toString() != member.sha256) {
          trashHashesValid = false;
        }
      }
    }

    return _MemberPresence(
      origFound: origFound,
      trashFound: trashFound,
      originalHashesValid: originalHashesValid,
      trashHashesValid: trashHashesValid,
    );
  }

  Future<Directory> _createTrashRoot({
    required String vaultPath,
    required DateTime trashedAt,
  }) async {
    final stamp = trashedAt
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .replaceAll('Z', 'z');
    var candidate = Directory(p.join(vaultPath, trashDirName, stamp));
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = Directory(
        p.join(vaultPath, trashDirName, '${stamp}_$suffix'),
      );
      suffix += 1;
    }
    await candidate.create(recursive: true);
    return candidate;
  }

  Future<void> _writeManifest(
    Directory trashRoot,
    VaultTrashEntry entry,
  ) async {
    final manifest = File(p.join(trashRoot.path, manifestFileName));
    await VaultRecoveryWriteService().writeText(
      vaultPath: entry.vaultPath,
      targetPath: manifest.path,
      content: const JsonEncoder.withIndent('  ').convert(entry.toJson()),
      reason: 'write_trash_manifest',
    );
  }

  Future<void> _writeTransactionManifest(
    Directory trashRoot,
    VaultTrashTransaction transaction,
  ) async {
    await _manifests.write(trashRoot, transaction);
  }

  Future<void> _deleteTrashRootForEntry(VaultTrashEntry entry) async {
    final trashRoot = _trashRootForEntry(entry);
    if (await trashRoot.exists()) {
      await trashRoot.delete(recursive: true);
    }
  }

  Directory _trashRootForEntry(VaultTrashEntry entry) {
    var current = Directory(p.dirname(entry.trashPath));
    while (p.basename(current.path) != trashDirName) {
      final manifest = File(p.join(current.path, manifestFileName));
      if (manifest.existsSync()) return current;
      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }
    return Directory(p.dirname(entry.trashPath));
  }

  static String _normalizeAbsolute(String path) =>
      p.normalize(p.absolute(path));

  static void _assertInsideVault({
    required String vaultPath,
    required String absolutePath,
  }) {
    if (!p.isWithin(vaultPath, absolutePath)) {
      throw ArgumentError.value(
        absolutePath,
        'absolutePath',
        'must be inside vaultPath',
      );
    }
  }

  static void _assertNotAlreadyTrash({
    required String vaultPath,
    required String absolutePath,
  }) {
    final relative = p.relative(absolutePath, from: vaultPath);
    final parts = p.split(relative);
    if (parts.isNotEmpty && parts.first == trashDirName) {
      throw ArgumentError.value(
        absolutePath,
        'absolutePath',
        'must not already be inside $trashDirName',
      );
    }
  }

  static void _assertNotCanvasMember({
    required String vaultPath,
    required String absolutePath,
  }) {
    final relative = p.relative(absolutePath, from: vaultPath);
    final parts = p.split(p.normalize(relative));
    // Only the known composite members cannot be trashed independently.
    // Future sidecar files under canvases/<id>/ may use single-file trash.
    if (parts.length >= 3 &&
        parts.first == 'canvases' &&
        (parts.last == 'canvas.md' || parts.last == 'layout.json') &&
        !parts.contains('..')) {
      throw ArgumentError(
        'Canvas member files cannot be trashed independently. Use the Canvas composite trash operation.',
      );
    }
  }
}

class _MemberPresence {
  const _MemberPresence({
    required this.origFound,
    required this.trashFound,
    required this.originalHashesValid,
    required this.trashHashesValid,
  });

  final int origFound;
  final int trashFound;
  final bool originalHashesValid;
  final bool trashHashesValid;
}
