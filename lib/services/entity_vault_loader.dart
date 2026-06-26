import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_journal_entry.dart';
import 'entity_journal_parser.dart';
import 'entity_path_index_service.dart';

/// `vault/entities/{type}/` 에서 entity journal 로드 — Wave 4.1.
class EntityVaultLoader {
  const EntityVaultLoader({EntityPathIndexService? pathIndex})
      : _pathIndex = pathIndex;

  final EntityPathIndexService? _pathIndex;

  EntityPathIndexService get _index => _pathIndex ?? EntityPathIndexService();

  Future<List<EntityJournalEntry>> loadFromVault(String? vaultPath) async {
    if (vaultPath == null || vaultPath.isEmpty) return const [];

    final root = Directory(
      p.join(vaultPath, EntityJournalParser.entitiesDirName),
    );
    if (!await root.exists()) return const [];

    final entries = <EntityJournalEntry>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      try {
        final parsed = EntityJournalParser.parse(
          await entity.readAsString(),
          entity.path,
        );
        if (parsed != null) entries.add(parsed);
      } catch (_) {
        // skip malformed entity journal files
      }
    }

    entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return entries;
  }

  Future<EntityJournalEntry?> findByEntityId(
    String? vaultPath,
    String entityId,
  ) async {
    if (entityId.isEmpty || vaultPath == null || vaultPath.isEmpty) {
      return null;
    }

    final indexedPath = await _index.lookupAbsolutePath(vaultPath, entityId);
    if (indexedPath != null) {
      final file = File(indexedPath);
      if (await file.exists()) {
        try {
          final parsed = EntityJournalParser.parse(
            await file.readAsString(),
            indexedPath,
          );
          if (parsed != null && parsed.entityId == entityId) {
            return parsed;
          }
        } catch (_) {
          // fall through to scan + rebuild
        }
      }
    }

    final all = await loadFromVault(vaultPath);
    for (final entry in all) {
      if (entry.entityId == entityId) {
        await _index.upsert(
          vaultPath: vaultPath,
          entityId: entityId,
          absolutePath: entry.storagePath,
        );
        return entry;
      }
    }
    return null;
  }
}
