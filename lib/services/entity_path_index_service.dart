import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_journal_entry.dart';
import 'derived_index_atomic_write.dart';
import 'entity_journal_parser.dart';

/// `{vault}/.akasha/entity_path_index.json` — entity_id → vault 상대 경로.
class EntityPathIndexService {
  EntityPathIndexService({
    DerivedIndexAtomicWrite? atomicWrite,
  }) : atomicWrite = atomicWrite ?? const DerivedIndexAtomicWrite();

  final DerivedIndexAtomicWrite atomicWrite;

  static const int schemaVersion = 1;
  static const String indexDirName = '.akasha';
  static const String indexFileName = 'entity_path_index.json';

  String _indexPath(String vaultPath) =>
      p.join(vaultPath, indexDirName, indexFileName);

  Future<bool> isAvailable(String vaultPath) async {
    final result = await loadPathsResult(vaultPath);
    return result.isReady;
  }

  /// Parses the index without treating corrupt JSON as an empty map.
  Future<EntityPathIndexLoadResult> loadPathsResult(String vaultPath) async {
    final file = File(_indexPath(vaultPath));
    final opened = await atomicWrite.openForRead(
      target: file,
      validateContent: _isValidIndexContent,
    );
    if (opened.isMissing) {
      return const EntityPathIndexLoadResult.missing();
    }
    if (opened.isCorrupt) {
      return EntityPathIndexLoadResult.corrupt(file.path);
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return EntityPathIndexLoadResult.corrupt(file.path);
      }
      final json = Map<String, dynamic>.from(decoded);
      if ((json['version'] as num?)?.toInt() != schemaVersion) {
        return EntityPathIndexLoadResult.corrupt(file.path);
      }
      final raw = json['paths'];
      if (raw is! Map) {
        return EntityPathIndexLoadResult.corrupt(file.path);
      }
      return EntityPathIndexLoadResult.ready(
        raw.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
    } on Object {
      return EntityPathIndexLoadResult.corrupt(file.path);
    }
  }

  Future<Map<String, String>> loadPaths(String vaultPath) async {
    final result = await loadPathsResult(vaultPath);
    if (result.isCorrupt) {
      throw DerivedIndexCorruptException(result.path ?? _indexPath(vaultPath));
    }
    return Map<String, String>.from(result.paths);
  }

  Future<String?> lookupRelativePath(String vaultPath, String entityId) async {
    if (entityId.isEmpty) return null;
    final result = await loadPathsResult(vaultPath);
    if (!result.isReady) return null;
    return result.paths[entityId];
  }

  Future<String?> lookupAbsolutePath(String vaultPath, String entityId) async {
    final relative = await lookupRelativePath(vaultPath, entityId);
    if (relative == null || relative.isEmpty) return null;
    return p.join(vaultPath, relative);
  }

  Future<void> upsert({
    required String vaultPath,
    required String entityId,
    required String absolutePath,
  }) async {
    if (entityId.isEmpty || absolutePath.isEmpty) return;
    if (!_isWithinVault(vaultPath, absolutePath)) return;

    final paths = await loadPaths(vaultPath);
    paths[entityId] = p.relative(absolutePath, from: vaultPath);
    await _write(vaultPath, paths);
  }

  Future<String?> upsertMarkdownFile({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return null;
    if (!_isWithinVault(vaultPath, absolutePath)) return null;

    final file = File(absolutePath);
    if (!await file.exists()) {
      await removeByAbsolutePath(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return null;
    }

    EntityJournalEntry? parsed;
    try {
      parsed = EntityJournalParser.parse(
        await file.readAsString(),
        file.path,
      );
    } catch (_) {
      parsed = null;
    }
    if (parsed == null) {
      await removeByAbsolutePath(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return null;
    }

    await upsert(
      vaultPath: vaultPath,
      entityId: parsed.entityId,
      absolutePath: file.path,
    );
    return parsed.entityId;
  }

  Future<void> remove({
    required String vaultPath,
    required String entityId,
  }) async {
    if (entityId.isEmpty) return;

    final paths = await loadPaths(vaultPath);
    if (paths.remove(entityId) == null) return;
    await _write(vaultPath, paths);
  }

  Future<String?> removeByAbsolutePath({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return null;
    if (!_isWithinVault(vaultPath, absolutePath)) return null;

    final relative = p.relative(absolutePath, from: vaultPath);
    final paths = await loadPaths(vaultPath);
    String? removedEntityId;
    paths.removeWhere((entityId, indexedPath) {
      final matches = p.normalize(indexedPath) == p.normalize(relative);
      if (matches) removedEntityId = entityId;
      return matches;
    });
    if (removedEntityId == null) return null;
    await _write(vaultPath, paths);
    return removedEntityId;
  }

  /// Rebuilds when missing or corrupt; leaves a healthy index alone.
  Future<void> ensureIndex(String vaultPath) async {
    if (await isAvailable(vaultPath)) return;
    await rebuildFromVault(vaultPath);
  }

  Future<void> rebuildFromVault(String vaultPath) async {
    final paths = <String, String>{};
    final root = Directory(
      p.join(vaultPath, EntityJournalParser.entitiesDirName),
    );
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !entity.path.endsWith('.md')) continue;
        try {
          final parsed = EntityJournalParser.parse(
            await entity.readAsString(),
            entity.path,
          );
          if (parsed == null) continue;
          paths[parsed.entityId] = p.relative(entity.path, from: vaultPath);
        } catch (_) {
          // skip malformed
        }
      }
    }
    await _write(vaultPath, paths);
  }

  Future<void> _write(String vaultPath, Map<String, String> paths) async {
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'paths': paths,
    };
    await atomicWrite.writeText(
      target: File(_indexPath(vaultPath)),
      content: const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  static bool _isValidIndexContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return false;
      if ((decoded['version'] as num?)?.toInt() != schemaVersion) return false;
      return decoded['paths'] is Map;
    } on Object {
      return false;
    }
  }

  static bool _isWithinVault(String vaultPath, String absolutePath) {
    final vaultRoot = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    final relative = p.relative(target, from: vaultRoot);
    if (relative == '.') return true;
    if (p.isAbsolute(relative)) return false;
    return relative != '..' && !relative.startsWith('..${p.separator}');
  }
}

class EntityPathIndexLoadResult {
  const EntityPathIndexLoadResult._({
    required this.paths,
    required this.isMissing,
    required this.isCorrupt,
    this.path,
  });

  const EntityPathIndexLoadResult.missing()
    : this._(paths: const {}, isMissing: true, isCorrupt: false);

  const EntityPathIndexLoadResult.corrupt(String path)
    : this._(paths: const {}, isMissing: false, isCorrupt: true, path: path);

  const EntityPathIndexLoadResult.ready(Map<String, String> paths)
    : this._(paths: paths, isMissing: false, isCorrupt: false);

  final Map<String, String> paths;
  final bool isMissing;
  final bool isCorrupt;
  final String? path;

  bool get isReady => !isMissing && !isCorrupt;
}
