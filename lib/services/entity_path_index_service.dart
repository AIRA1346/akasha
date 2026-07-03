import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'entity_journal_parser.dart';

/// `{vault}/.akasha/entity_path_index.json` — entity_id → vault 상대 경로.
class EntityPathIndexService {
  EntityPathIndexService();

  static const int schemaVersion = 1;
  static const String indexDirName = '.akasha';
  static const String indexFileName = 'entity_path_index.json';

  String _indexPath(String vaultPath) =>
      p.join(vaultPath, indexDirName, indexFileName);

  Future<Map<String, String>> loadPaths(String vaultPath) async {
    final file = File(_indexPath(vaultPath));
    if (!await file.exists()) return {};

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final raw = json['paths'];
      if (raw is! Map) return {};
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<String?> lookupRelativePath(String vaultPath, String entityId) async {
    if (entityId.isEmpty) return null;
    final paths = await loadPaths(vaultPath);
    return paths[entityId];
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

    try {
      final parsed = EntityJournalParser.parse(
        await file.readAsString(),
        file.path,
      );
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
    } catch (_) {
      await removeByAbsolutePath(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return null;
    }
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

  /// 인덱스 파일이 없으면 `entities/` 전체 스캔으로 생성.
  Future<void> ensureIndex(String vaultPath) async {
    final file = File(_indexPath(vaultPath));
    if (await file.exists()) return;
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
    final dir = Directory(p.join(vaultPath, indexDirName));
    await dir.create(recursive: true);

    final payload = <String, dynamic>{
      'version': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'paths': paths,
    };
    await File(_indexPath(vaultPath)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
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
