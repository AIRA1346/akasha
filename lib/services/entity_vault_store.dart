import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../models/user_catalog_entity.dart';
import '../core/archiving/vault_ledger_event.dart';
import 'entity_journal_parser.dart';
import 'entity_path_index_service.dart';
import 'entity_vault_path_conflict.dart';
import 'event_ledger_service.dart';
import 'entity_vault_loader.dart';
import '../core/app_vault.dart';
import 'archive_index_manager.dart';
import 'vault_record_path_resolver.dart';
import 'vault_trash_service.dart';

/// `vault/entities/{type}/` 쓰기 — Wave 4.
class EntityVaultStore {
  EntityVaultStore({
    EventLedgerService? eventLedger,
    EntityPathIndexService? pathIndex,
  }) : _eventLedger = eventLedger ?? EventLedgerService(),
       _pathIndex = pathIndex ?? EntityPathIndexService();

  final EventLedgerService _eventLedger;
  final EntityPathIndexService _pathIndex;

  static String resolveStoragePath({
    required String vaultPath,
    required EntityAnchorType entityType,
    required String title,
    String entityId = '',
  }) {
    return VaultRecordPathResolver.resolveEntityPath(
      vaultRoot: vaultPath,
      entityType: entityType,
      entityId: entityId,
      title: title,
    );
  }

  Future<EntityJournalEntry> saveCatalogEntity({
    required String vaultPath,
    required UserCatalogEntity entity,
    required String body,
    String? sourceOperationId,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (entity.isWorkEntity) {
      throw ArgumentError('work entities use VaultPort.saveItem');
    }

    var targetPath = resolveStoragePath(
      vaultPath: vaultPath,
      entityType: entity.anchorType,
      title: entity.title,
      entityId: entity.entityId,
    );

    if (!await File(targetPath).exists()) {
      final existing = await EntityVaultLoader(
        pathIndex: _pathIndex,
      ).findByEntityId(vaultPath, entity.entityId);
      if (existing != null) {
        if (existing.entityType != entity.anchorType) {
          throw EntityVaultPathConflict(
            existingEntityId: existing.entityId,
            incomingEntityId: entity.entityId,
            title: entity.title,
            path: existing.storagePath,
          );
        }
        targetPath = existing.storagePath;
      }
    }

    await Directory(p.dirname(targetPath)).create(recursive: true);

    var addedAt = entity.addedAt;
    if (File(targetPath).existsSync()) {
      final existing = EntityJournalParser.parse(
        await File(targetPath).readAsString(),
        targetPath,
      );
      if (existing != null) {
        if (existing.entityId != entity.entityId) {
          throw EntityVaultPathConflict(
            existingEntityId: existing.entityId,
            incomingEntityId: entity.entityId,
            title: entity.title,
            path: targetPath,
          );
        }
        addedAt = existing.addedAt;
      }
    }

    final content = EntityJournalParser.serialize(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      body: body,
      addedAt: addedAt,
      aliases: entity.aliases,
      tags: entity.tags,
      posterPath: entity.posterPath,
      sourceOperationId: sourceOperationId,
    );

    await _writeAtomic(targetPath, content);
    await _pathIndex.upsert(
      vaultPath: vaultPath,
      entityId: entity.entityId,
      absolutePath: targetPath,
    );
    final entry = EntityJournalEntry(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      body: body.trim(),
      addedAt: addedAt,
      storagePath: targetPath,
      aliases: List<String>.from(entity.aliases),
      tags: List<String>.from(entity.tags),
      posterPath: entity.posterPath,
      sourceOperationId: sourceOperationId,
    );
    await ArchiveIndexManager().updateChangedRecord(
      vaultPath: vaultPath,
      absolutePath: targetPath,
    );
    await AppVault.port.signalVaultChanged();
    await _eventLedger.append(
      VaultLedgerEvent(
        type: VaultLedgerEventType.recordSaved,
        at: DateTime.now().toUtc(),
        path: targetPath,
        meta: {'recordKind': RecordKind.entityJournal.name},
      ),
    );

    return entry;
  }

  Future<EntityJournalEntry> updateEntry({
    required EntityJournalEntry entry,
    required String body,
    String? title,
    List<String>? aliases,
    List<String>? tags,
    String? posterPath,
    String? vaultPath,
  }) async {
    if (entry.storagePath.isEmpty) {
      throw StateError('Entity journal storage path missing');
    }

    final resolvedTitle = (title ?? entry.title).trim();
    if (resolvedTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }

    final resolvedTags = tags ?? entry.tags;
    final resolvedAliases = aliases ?? entry.aliases;
    final vaultRoot = vaultPath ?? _vaultRootFromStoragePath(entry.storagePath);

    var targetPath = entry.storagePath;
    if (resolvedTitle != entry.title) {
      final nextPath = resolveStoragePath(
        vaultPath: vaultRoot,
        entityType: entry.entityType,
        title: resolvedTitle,
        entityId: entry.entityId,
      );
      if (nextPath != entry.storagePath) {
        await _assertPathAvailable(
          targetPath: nextPath,
          entityId: entry.entityId,
          title: resolvedTitle,
        );
        targetPath = nextPath;
        await Directory(p.dirname(targetPath)).create(recursive: true);
      }
    }

    final content = EntityJournalParser.serialize(
      entityType: entry.entityType,
      entityId: entry.entityId,
      title: resolvedTitle,
      body: body,
      addedAt: entry.addedAt,
      aliases: resolvedAliases,
      tags: resolvedTags,
      posterPath: posterPath ?? entry.posterPath,
      sourceOperationId: entry.sourceOperationId,
    );

    await _writeAtomic(targetPath, content);

    if (targetPath != entry.storagePath) {
      final oldFile = File(entry.storagePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
        await ArchiveIndexManager().removeRecord(
          vaultPath: vaultRoot,
          absolutePath: entry.storagePath,
          sourceRecordId: _entitySourceRecordId(entry.entityId),
        );
      }
    }

    await _pathIndex.upsert(
      vaultPath: vaultRoot,
      entityId: entry.entityId,
      absolutePath: targetPath,
    );
    final updated = EntityJournalEntry(
      entityType: entry.entityType,
      entityId: entry.entityId,
      title: resolvedTitle,
      body: body.trim(),
      addedAt: entry.addedAt,
      storagePath: targetPath,
      aliases: List<String>.from(resolvedAliases),
      tags: List<String>.from(resolvedTags),
      posterPath: posterPath ?? entry.posterPath,
      sourceOperationId: entry.sourceOperationId,
    );
    await ArchiveIndexManager().updateChangedRecord(
      vaultPath: vaultRoot,
      absolutePath: targetPath,
    );
    await AppVault.port.signalVaultChanged();
    await _eventLedger.append(
      VaultLedgerEvent(
        type: VaultLedgerEventType.recordSaved,
        at: DateTime.now().toUtc(),
        path: targetPath,
        meta: {'recordKind': RecordKind.entityJournal.name},
      ),
    );

    return updated;
  }

  /// `.md` 삭제 성공 시 `true`. 경로 없음·파일 없음은 `false`.
  Future<bool> deleteEntry(String storagePath) async {
    if (storagePath.isEmpty) return false;
    final file = File(storagePath);
    if (!await file.exists()) return false;

    String? entityId;
    try {
      final parsed = EntityJournalParser.parse(
        await file.readAsString(),
        storagePath,
      );
      entityId = parsed?.entityId;
    } catch (_) {}

    final vaultRoot = _vaultRootFromStoragePath(storagePath);
    await const VaultTrashService().moveFileToTrash(
      vaultPath: vaultRoot,
      absolutePath: storagePath,
    );
    if (entityId != null && entityId.isNotEmpty) {
      await _pathIndex.remove(vaultPath: vaultRoot, entityId: entityId);
    }
    await ArchiveIndexManager().removeRecord(
      vaultPath: vaultRoot,
      absolutePath: storagePath,
      sourceRecordId: _entitySourceRecordId(entityId),
    );

    await AppVault.port.signalVaultChanged();
    await _eventLedger.append(
      VaultLedgerEvent(
        type: VaultLedgerEventType.recordDeleted,
        at: DateTime.now().toUtc(),
        path: storagePath,
        meta: {'recordKind': RecordKind.entityJournal.name},
      ),
    );
    return true;
  }

  static String _vaultRootFromStoragePath(String storagePath) {
    // …/entities/{type}/{file}.md → vault root
    final entitiesDir = EntityJournalParser.entitiesDirName;
    final normalized = p.normalize(storagePath);
    final segments = p.split(normalized);
    final idx = segments.lastIndexOf(entitiesDir);
    if (idx <= 0) {
      return p.dirname(p.dirname(p.dirname(normalized)));
    }
    return p.joinAll(segments.sublist(0, idx));
  }

  static String? _entitySourceRecordId(String? entityId) {
    final trimmed = entityId?.trim();
    return trimmed == null || trimmed.isEmpty ? null : 'rec_$trimmed';
  }

  Future<void> _assertPathAvailable({
    required String targetPath,
    required String entityId,
    required String title,
  }) async {
    final file = File(targetPath);
    if (!await file.exists()) return;

    final existing = EntityJournalParser.parse(
      await file.readAsString(),
      targetPath,
    );
    if (existing != null && existing.entityId != entityId) {
      throw EntityVaultPathConflict(
        existingEntityId: existing.entityId,
        incomingEntityId: entityId,
        title: title,
        path: targetPath,
      );
    }
  }

  Future<void> _writeAtomic(String targetPath, String content) async {
    final file = File(targetPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final tempPath = p.join(
      parent.path,
      '.akasha_${DateTime.now().microsecondsSinceEpoch}_${p.basename(targetPath)}.tmp',
    );
    final temp = File(tempPath);
    try {
      await temp.writeAsString(content, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(targetPath);
    } catch (e) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
