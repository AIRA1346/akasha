import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_journal_entry.dart';
import 'entity_journal_parser.dart';

/// `vault/entities/{type}/` 에서 entity journal 로드 — Wave 4.1.
class EntityVaultLoader {
  const EntityVaultLoader();

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
    if (entityId.isEmpty) return null;
    final all = await loadFromVault(vaultPath);
    for (final entry in all) {
      if (entry.entityId == entityId) return entry;
    }
    return null;
  }
}
