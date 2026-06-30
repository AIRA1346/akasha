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
import '../core/app_vault.dart';
import 'record_summary_index_service.dart';
import 'vault_safe_filename.dart';
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
  }) {
    final subdir = EntityJournalParser.entitySubdir(entityType);
    final safeTitle = VaultSafeFilename.fromTitle(title);
    return p.join(
      vaultPath,
      EntityJournalParser.entitiesDirName,
      subdir,
      '$safeTitle.md',
    );
  }

  Future<EntityJournalEntry> saveCatalogEntity({
    required String vaultPath,
    required UserCatalogEntity entity,
    required String body,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (entity.isWorkEntity) {
      throw ArgumentError('work entities use VaultPort.saveItem');
    }

    final targetPath = resolveStoragePath(
      vaultPath: vaultPath,
      entityType: entity.anchorType,
      title: entity.title,
    );

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
      tags: entity.tags,
      posterPath: entity.posterPath,
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
      tags: List<String>.from(entity.tags),
      posterPath: entity.posterPath,
    );
    await RecordSummaryIndexService().upsertEntity(
      vaultPath: vaultPath,
      entry: entry,
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
    final vaultRoot = vaultPath ?? _vaultRootFromStoragePath(entry.storagePath);

    var targetPath = entry.storagePath;
    if (resolvedTitle != entry.title) {
      final nextPath = resolveStoragePath(
        vaultPath: vaultRoot,
        entityType: entry.entityType,
        title: resolvedTitle,
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
      tags: resolvedTags,
      posterPath: posterPath ?? entry.posterPath,
    );

    await _writeAtomic(targetPath, content);

    if (targetPath != entry.storagePath) {
      final oldFile = File(entry.storagePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
        await RecordSummaryIndexService().removeByAbsolutePath(
          vaultPath: vaultRoot,
          absolutePath: entry.storagePath,
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
      tags: List<String>.from(resolvedTags),
      posterPath: posterPath ?? entry.posterPath,
    );
    await RecordSummaryIndexService().upsertEntity(
      vaultPath: vaultRoot,
      entry: updated,
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
    await RecordSummaryIndexService().removeByAbsolutePath(
      vaultPath: vaultRoot,
      absolutePath: storagePath,
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
