import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_record.dart';
import '../core/archiving/archive_record_contract.dart';
import '../core/archiving/timeline_entry.dart';
import 'archive_index_manager.dart';
import 'timeline_entry_parser.dart';
import 'timeline_vault_loader.dart';
import 'vault_trash_service.dart';

/// `vault/timeline/` 쓰기·삭제 — Phase 4.2.
class TimelineVaultStore {
  const TimelineVaultStore({TimelineVaultLoader? loader})
    : _loader = loader ?? const TimelineVaultLoader();

  final TimelineVaultLoader _loader;

  /// `tl_{yyyyMMdd}_{hex6}` — vault 내 안정 ID.
  static String generateRecordId([DateTime? at]) {
    final now = at ?? DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final suffix = (now.microsecondsSinceEpoch & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return 'tl_${date}_$suffix';
  }

  static String fileNameFor(String recordId) {
    final safe = recordId.replaceAll(RegExp(r'[^\w\-]'), '_');
    return '$safe.md';
  }

  Future<TimelineEntry> save({
    required String vaultPath,
    required ArchiveRecord record,
    required String body,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (!record.isTimelineEntry) {
      throw ArgumentError.value(
        record.kind,
        'record.kind',
        'timelineEntry only',
      );
    }

    final recordId = record.recordId.trim();
    if (recordId.isEmpty) {
      throw ArgumentError.value(
        record.recordId,
        'recordId',
        'must not be empty',
      );
    }

    final timelineDir = Directory(
      p.join(vaultPath, TimelineEntryParser.timelineDirName),
    );
    await timelineDir.create(recursive: true);

    final occurredAt = record.timeAnchor ?? DateTime.now();
    final title = (record.title?.trim().isNotEmpty ?? false)
        ? record.title!.trim()
        : recordId;
    final entityId = record.entity?.entityId;

    var addedAt = DateTime.now().toUtc();
    var existingMetadata = ArchiveRecordMetadata.empty;
    var targetPath = record.storagePath?.trim();

    if (targetPath != null &&
        targetPath.isNotEmpty &&
        File(targetPath).existsSync()) {
      final existing = TimelineEntryParser.parse(
        await File(targetPath).readAsString(),
        targetPath,
      );
      if (existing != null) {
        addedAt = existing.addedAt;
        existingMetadata = existing.recordMetadata;
      }
    } else {
      final existing = await _findByRecordId(vaultPath, recordId);
      if (existing != null) {
        targetPath = existing.storagePath;
        addedAt = existing.addedAt;
        existingMetadata = existing.recordMetadata;
      } else {
        targetPath = p.join(timelineDir.path, fileNameFor(recordId));
      }
    }
    final recordMetadata = existingMetadata.copyWith(
      source: ArchiveRecordContract.defaultSource,
      updatedAt: DateTime.now().toUtc(),
    );

    final content = TimelineEntryParser.serialize(
      recordId: recordId,
      title: title,
      body: body,
      occurredAt: occurredAt,
      addedAt: addedAt,
      entityId: entityId,
      metadata: recordMetadata,
    );

    await _writeAtomic(targetPath, content);

    final entry = TimelineEntry(
      recordId: recordId,
      title: title,
      body: body.trim(),
      occurredAt: occurredAt,
      addedAt: addedAt,
      storagePath: targetPath,
      entityId: entityId?.trim().isNotEmpty == true ? entityId!.trim() : null,
      recordMetadata: recordMetadata,
    );
    await ArchiveIndexManager().updateChangedRecord(
      vaultPath: vaultPath,
      absolutePath: targetPath,
    );
    return entry;
  }

  Future<void> delete({
    required String vaultPath,
    required String recordId,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (recordId.trim().isEmpty) return;

    final entries = await _loader.loadFromVault(vaultPath);
    for (final entry in entries) {
      if (entry.recordId != recordId) continue;
      final file = File(entry.storagePath);
      if (await file.exists()) {
        await const VaultTrashService().moveFileToTrash(
          vaultPath: vaultPath,
          absolutePath: entry.storagePath,
        );
        await ArchiveIndexManager().removeRecord(
          vaultPath: vaultPath,
          absolutePath: entry.storagePath,
          sourceRecordId: entry.recordId,
        );
      }
      return;
    }
  }

  Future<TimelineEntry?> _findByRecordId(
    String vaultPath,
    String recordId,
  ) async {
    final entries = await _loader.loadFromVault(vaultPath);
    for (final entry in entries) {
      if (entry.recordId == recordId) return entry;
    }
    return null;
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
