import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../core/archiving/canvas_record.dart';
import 'vault_recovery_write_service.dart';

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
  final String state;
  final DateTime createdAt;
  final List<VaultTrashMember> members;
  final String? trashRootPath;

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
      members:
          rawMembers
              .map(
                (m) => VaultTrashMember.fromJson(
                  Map<String, dynamic>.from(m as Map),
                ),
              )
              .toList(),
      trashRootPath: trashRootPath,
    );
  }
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
  const CanvasRestoreResult({required this.succeeded, this.error});

  final bool succeeded;
  final String? error;
}

class VaultTrashService {
  const VaultTrashService();

  static const trashDirName = '.trash';
  static const manifestFileName = 'trash_entry.json';
  static const transactionManifestFileName = 'trash_transaction.json';

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
    if (vaultPath.isEmpty || canvasId.isEmpty) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Invalid vault path or canvas ID.',
      );
    }
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final canvasDir = Directory(p.join(normalizedVault, 'canvases', canvasId));
    final normalizedCanvasDir = _normalizeAbsolute(canvasDir.path);

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

    final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
    final layoutFile = File(p.join(canvasDir.path, 'layout.json'));

    if (!await mdFile.exists() || !await layoutFile.exists()) {
      return const CanvasTrashResult(
        succeeded: false,
        error: 'Canvas composite members (canvas.md, layout.json) missing.',
      );
    }

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
      title = record.title;
    } catch (e) {
      return CanvasTrashResult(
        succeeded: false,
        error: 'Failed to parse canvas.md: $e',
      );
    }

    final trashedAt = DateTime.now().toUtc();
    final trashRoot = await _createTrashRoot(
      vaultPath: normalizedVault,
      trashedAt: trashedAt,
    );
    final transactionId = p.basename(trashRoot.path);

    final mdBytes = await mdFile.readAsBytes();
    final mdHash = crypto.sha256.convert(mdBytes).toString();
    final layoutBytes = await layoutFile.readAsBytes();
    final layoutHash = crypto.sha256.convert(layoutBytes).toString();

    final relCanvasDir = p.relative(normalizedCanvasDir, from: normalizedVault);
    final targetCanvasDir = p.join(trashRoot.path, relCanvasDir);

    final members = [
      VaultTrashMember(
        relativeOriginalPath: p.join(relCanvasDir, 'canvas.md'),
        relativeTrashPath: p.relative(
          p.join(targetCanvasDir, 'canvas.md'),
          from: trashRoot.path,
        ),
        size: mdBytes.length,
        sha256: mdHash,
      ),
      VaultTrashMember(
        relativeOriginalPath: p.join(relCanvasDir, 'layout.json'),
        relativeTrashPath: p.relative(
          p.join(targetCanvasDir, 'layout.json'),
          from: trashRoot.path,
        ),
        size: layoutBytes.length,
        sha256: layoutHash,
      ),
    ];

    final transaction = VaultTrashTransaction(
      version: 1,
      transactionId: transactionId,
      vaultPath: normalizedVault,
      recordKind: 'canvas',
      recordId: canvasId,
      title: title,
      reason: reason ?? 'user_delete',
      state: 'prepared',
      createdAt: trashedAt,
      members: members,
      trashRootPath: trashRoot.path,
    );

    await _writeTransactionManifest(trashRoot, transaction);

    await Directory(p.dirname(targetCanvasDir)).create(recursive: true);
    await canvasDir.rename(targetCanvasDir);

    final committedTx = VaultTrashTransaction(
      version: transaction.version,
      transactionId: transaction.transactionId,
      vaultPath: transaction.vaultPath,
      recordKind: transaction.recordKind,
      recordId: transaction.recordId,
      title: transaction.title,
      reason: transaction.reason,
      state: 'committed',
      createdAt: transaction.createdAt,
      members: transaction.members,
      trashRootPath: trashRoot.path,
    );
    await _writeTransactionManifest(trashRoot, committedTx);

    return CanvasTrashResult(succeeded: true, transaction: committedTx);
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
    VaultTrashTransaction transaction, {
    bool overwrite = false,
  }) async {
    final normalizedVault = _normalizeAbsolute(transaction.vaultPath);
    final trashRoot =
        transaction.trashRootPath != null
            ? Directory(transaction.trashRootPath!)
            : Directory(
              p.join(
                normalizedVault,
                trashDirName,
                transaction.transactionId,
              ),
            );

    if (!await trashRoot.exists()) {
      return const CanvasRestoreResult(
        succeeded: false,
        error: 'Trash transaction directory does not exist.',
      );
    }

    for (final member in transaction.members) {
      final origPath = p.join(normalizedVault, member.relativeOriginalPath);
      if (await File(origPath).exists() && !overwrite) {
        return CanvasRestoreResult(
          succeeded: false,
          error:
              'Original file already exists: ${member.relativeOriginalPath}',
        );
      }
    }

    for (final member in transaction.members) {
      final trashMemberPath = p.join(trashRoot.path, member.relativeTrashPath);
      final file = File(trashMemberPath);
      if (!await file.exists()) {
        return CanvasRestoreResult(
          succeeded: false,
          error: 'Trash member file missing: ${member.relativeTrashPath}',
        );
      }
      final bytes = await file.readAsBytes();
      final hash = crypto.sha256.convert(bytes).toString();
      if (hash != member.sha256) {
        return CanvasRestoreResult(
          succeeded: false,
          error:
              'SHA-256 hash mismatch for trash member: ${member.relativeTrashPath}',
        );
      }
    }

    final canvasDirRel = p.dirname(
      transaction.members.first.relativeOriginalPath,
    );
    final targetCanvasDir = Directory(p.join(normalizedVault, canvasDirRel));
    final trashCanvasDir = Directory(
      p.dirname(
        p.join(trashRoot.path, transaction.members.first.relativeTrashPath),
      ),
    );

    if (await targetCanvasDir.exists() && overwrite) {
      await targetCanvasDir.delete(recursive: true);
    }

    await targetCanvasDir.parent.create(recursive: true);
    await trashCanvasDir.rename(targetCanvasDir.path);

    if (await trashRoot.exists()) {
      await trashRoot.delete(recursive: true);
    }

    return const CanvasRestoreResult(succeeded: true);
  }

  Future<List<VaultTrashEntry>> listEntries({required String vaultPath}) async {
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final trashRoot = Directory(p.join(normalizedVault, trashDirName));
    if (!await trashRoot.exists()) return const [];

    final entries = <VaultTrashEntry>[];
    await for (final entity in trashRoot.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      if (p.basename(entity.path) != manifestFileName) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        final entry = VaultTrashEntry.fromJson(decoded);
        if (entry.vaultPath.isEmpty ||
            entry.originalPath.isEmpty ||
            entry.trashPath.isEmpty) {
          continue;
        }
        if (!await File(entry.trashPath).exists()) continue;
        entries.add(entry);
      } catch (_) {}
    }

    entries.sort((a, b) => b.trashedAt.compareTo(a.trashedAt));
    return entries;
  }

  Future<List<VaultTrashTransaction>> listTransactions({
    required String vaultPath,
  }) async {
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final trashRoot = Directory(p.join(normalizedVault, trashDirName));
    if (!await trashRoot.exists()) return const [];

    final transactions = <VaultTrashTransaction>[];
    await for (final entity in trashRoot.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      if (p.basename(entity.path) != transactionManifestFileName) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        final tx = VaultTrashTransaction.fromJson(
          decoded,
          trashRootPath: entity.parent.path,
        );
        if (tx.transactionId.isEmpty || tx.vaultPath.isEmpty) continue;
        transactions.add(tx);
      } catch (_) {}
    }

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  Future<List<String>> recoverPendingTrashTransactions({
    required String vaultPath,
  }) async {
    final normalizedVault = _normalizeAbsolute(vaultPath);
    final trashRoot = Directory(p.join(normalizedVault, trashDirName));
    if (!await trashRoot.exists()) return const [];

    final recoveredIds = <String>[];
    await for (final entity in trashRoot.list(recursive: false)) {
      if (entity is! Directory) continue;
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

        if (tx.state == 'prepared') {
          bool allOriginalExist = true;
          for (final member in tx.members) {
            final origFile = File(
              p.join(normalizedVault, member.relativeOriginalPath),
            );
            if (!await origFile.exists()) {
              allOriginalExist = false;
              break;
            }
          }

          if (allOriginalExist) {
            await entity.delete(recursive: true);
            recoveredIds.add(tx.transactionId);
          }
        } else if (tx.state == 'restoring') {
          final restoreRes = await restoreCanvasTransaction(
            tx,
            overwrite: true,
          );
          if (restoreRes.succeeded) {
            recoveredIds.add(tx.transactionId);
          }
        }
      } catch (_) {}
    }

    return recoveredIds;
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
    final trashRoot =
        transaction.trashRootPath != null
            ? Directory(transaction.trashRootPath!)
            : Directory(
              p.join(
                _normalizeAbsolute(transaction.vaultPath),
                trashDirName,
                transaction.transactionId,
              ),
            );

    if (await trashRoot.exists()) {
      await trashRoot.delete(recursive: true);
      return true;
    }
    return false;
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
    final manifest = File(p.join(trashRoot.path, transactionManifestFileName));
    await VaultRecoveryWriteService().writeText(
      vaultPath: transaction.vaultPath,
      targetPath: manifest.path,
      content: const JsonEncoder.withIndent('  ').convert(transaction.toJson()),
      reason: 'write_trash_transaction_manifest',
    );
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
    final parts = p.split(relative);
    if (parts.isNotEmpty && parts.first == 'canvases') {
      throw ArgumentError(
        'Canvas member files cannot be trashed independently. Use the Canvas composite trash operation.',
      );
    }
  }
}
