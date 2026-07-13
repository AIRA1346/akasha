import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/vault_file_revision.dart';
import 'entity_journal_parser.dart';
import 'entity_path_index_service.dart';
import 'entity_vault_load_result.dart';

export 'entity_vault_load_result.dart';

/// `vault/entities/{type}/` 에서 entity journal 로드 — Wave 4.1.
///
/// Load APIs do not auto-log issues; diagnostic callers must consume
/// [EntityVaultLoadResult.issues] explicitly.
class EntityVaultLoader {
  const EntityVaultLoader({EntityPathIndexService? pathIndex})
    : _pathIndex = pathIndex;

  final EntityPathIndexService? _pathIndex;

  EntityPathIndexService get _index => _pathIndex ?? EntityPathIndexService();

  /// Compatibility wrapper — returns only successful entries.
  Future<List<EntityJournalEntry>> loadFromVault(String? vaultPath) async {
    final result = await loadFromVaultWithIssues(vaultPath);
    return result.entries;
  }

  /// Loads entity journals and classifies per-file failures without aborting.
  /// Does not auto-log; returns issues on the result only.
  Future<EntityVaultLoadResult> loadFromVaultWithIssues(
    String? vaultPath,
  ) async {
    if (vaultPath == null || vaultPath.isEmpty) {
      return const EntityVaultLoadResult.empty();
    }

    final root = Directory(
      p.join(vaultPath, EntityJournalParser.entitiesDirName),
    );
    if (!await root.exists()) {
      return const EntityVaultLoadResult.empty();
    }

    final entries = <EntityJournalEntry>[];
    final issues = <EntityVaultLoadIssue>[];

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      final relativePath = p
          .relative(entity.path, from: vaultPath)
          .replaceAll('\\', '/');

      String content;
      try {
        content = await entity.readAsString();
      } on Object {
        issues.add(
          EntityVaultLoadIssue(
            relativePath: relativePath,
            errorCode: 'io_read_failed',
            severity: EntityVaultIssueSeverity.error,
          ),
        );
        continue;
      }

      final parsed = EntityJournalParser.parseDetailed(content, entity.path);
      if (parsed.issue != null) {
        issues.add(
          EntityVaultLoadIssue(
            relativePath: relativePath,
            errorCode: parsed.issue!.errorCode,
            severity: parsed.issue!.severity,
            diagnostic: parsed.issue!.diagnostic,
          ),
        );
        continue;
      }

      final entry = parsed.entry;
      if (entry == null) continue;

      DateTime? modifiedAtUtc;
      try {
        modifiedAtUtc = (await entity.lastModified()).toUtc();
      } on Object {
        issues.add(
          EntityVaultLoadIssue(
            relativePath: relativePath,
            errorCode: 'io_read_failed',
            severity: EntityVaultIssueSeverity.error,
            diagnostic: 'stat_failed',
          ),
        );
        continue;
      }

      entries.add(
        EntityJournalEntry(
          entityType: entry.entityType,
          entityId: entry.entityId,
          title: entry.title,
          body: entry.body,
          addedAt: entry.addedAt,
          storagePath: entry.storagePath,
          aliases: entry.aliases,
          tags: entry.tags,
          posterPath: entry.posterPath,
          sourceOperationId: entry.sourceOperationId,
          recordMetadata: entry.recordMetadata,
          entitySubtype: entry.entitySubtype,
          openedRevision: VaultFileRevision.fromText(
            content,
            modifiedAtUtc: modifiedAtUtc,
          ),
        ),
      );
    }

    entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    issues.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    return EntityVaultLoadResult(entries: entries, issues: issues);
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
          final content = await file.readAsString();
          final parsed = EntityJournalParser.parseDetailed(
            content,
            indexedPath,
          );
          final entry = parsed.entry;
          if (entry != null && entry.entityId == entityId) {
            return EntityJournalEntry(
              entityType: entry.entityType,
              entityId: entry.entityId,
              title: entry.title,
              body: entry.body,
              addedAt: entry.addedAt,
              storagePath: entry.storagePath,
              aliases: entry.aliases,
              tags: entry.tags,
              posterPath: entry.posterPath,
              sourceOperationId: entry.sourceOperationId,
              recordMetadata: entry.recordMetadata,
              entitySubtype: entry.entitySubtype,
              openedRevision: VaultFileRevision.fromText(
                content,
                modifiedAtUtc: (await file.lastModified()).toUtc(),
              ),
            );
          }
        } on Object {
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
