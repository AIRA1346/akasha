import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../models/user_catalog_entity.dart';
import '../core/archiving/vault_ledger_event.dart';
import 'entity_journal_parser.dart';
import 'entity_vault_path_conflict.dart';
import 'event_ledger_service.dart';
import 'file_service.dart';

/// `vault/entities/{type}/` 쓰기 — Wave 4.
class EntityVaultStore {
  EntityVaultStore({EventLedgerService? eventLedger})
      : _eventLedger = eventLedger ?? EventLedgerService();

  final EventLedgerService _eventLedger;

  static String _makeSafeFilename(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
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

    final subdir = EntityJournalParser.entitySubdir(entity.anchorType);
    final dir = Directory(p.join(vaultPath, EntityJournalParser.entitiesDirName, subdir));
    await dir.create(recursive: true);

    final safeTitle = _makeSafeFilename(entity.title);
    final targetPath = p.join(dir.path, '$safeTitle.md');

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
    await AkashaFileService().signalVaultChanged();
    await _eventLedger.append(
      VaultLedgerEvent(
        type: VaultLedgerEventType.recordSaved,
        at: DateTime.now().toUtc(),
        path: targetPath,
        meta: {'recordKind': RecordKind.entityJournal.name},
      ),
    );

    return EntityJournalEntry(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      body: body.trim(),
      addedAt: addedAt,
      storagePath: targetPath,
      tags: List<String>.from(entity.tags),
      posterPath: entity.posterPath,
    );
  }

  Future<EntityJournalEntry> updateEntry({
    required EntityJournalEntry entry,
    required String body,
    String? title,
    List<String>? tags,
    String? posterPath,
  }) async {
    if (entry.storagePath.isEmpty) {
      throw StateError('Entity journal storage path missing');
    }

    final resolvedTitle = (title ?? entry.title).trim();
    if (resolvedTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }

    final resolvedTags = tags ?? entry.tags;

    final content = EntityJournalParser.serialize(
      entityType: entry.entityType,
      entityId: entry.entityId,
      title: resolvedTitle,
      body: body,
      addedAt: entry.addedAt,
      tags: resolvedTags,
      posterPath: posterPath ?? entry.posterPath,
    );

    await _writeAtomic(entry.storagePath, content);
    await AkashaFileService().signalVaultChanged();
    await _eventLedger.append(
      VaultLedgerEvent(
        type: VaultLedgerEventType.recordSaved,
        at: DateTime.now().toUtc(),
        path: entry.storagePath,
        meta: {'recordKind': RecordKind.entityJournal.name},
      ),
    );

    return EntityJournalEntry(
      entityType: entry.entityType,
      entityId: entry.entityId,
      title: resolvedTitle,
      body: body.trim(),
      addedAt: entry.addedAt,
      storagePath: entry.storagePath,
      tags: List<String>.from(resolvedTags),
      posterPath: posterPath ?? entry.posterPath,
    );
  }

  /// `.md` 삭제 성공 시 `true`. 경로 없음·파일 없음은 `false`.
  Future<bool> deleteEntry(String storagePath) async {
    if (storagePath.isEmpty) return false;
    final file = File(storagePath);
    if (!await file.exists()) return false;
    await file.delete();
    await AkashaFileService().signalVaultChanged();
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
