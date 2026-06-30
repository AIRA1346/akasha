import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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

    final moved = await source.rename(targetPath);
    final entry = VaultTrashEntry(
      vaultPath: normalizedVault,
      originalPath: normalizedSource,
      trashPath: moved.path,
      trashedAt: trashedAt,
    );
    await _writeManifest(trashRoot, entry);
    return entry;
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
      await originalFile.delete();
    }

    await originalFile.parent.create(recursive: true);
    await trashFile.rename(originalFile.path);
    return true;
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
    await manifest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.toJson()),
      flush: true,
    );
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
