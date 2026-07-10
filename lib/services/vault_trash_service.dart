import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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

class VaultTrashService {
  const VaultTrashService();

  static const trashDirName = '.trash';
  static const manifestFileName = 'trash_entry.json';

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
}
