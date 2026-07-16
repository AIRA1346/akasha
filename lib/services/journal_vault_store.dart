import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_record.dart';
import '../core/archiving/archive_record_contract.dart';
import '../core/archiving/journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../core/archiving/vault_file_revision.dart';
import 'archive_index_manager.dart';
import 'journal_entry_parser.dart';
import 'journal_vault_loader.dart';
import 'vault_lossless_record_writer.dart';
import 'vault_trash_service.dart';

/// `vault/journal/` 쓰기·삭제 — Wave 3.
class JournalVaultStore {
  const JournalVaultStore({
    JournalVaultLoader? loader,
    ArchiveIndexManager? archiveIndex,
  }) : _loader = loader ?? const JournalVaultLoader(),
       _archiveIndex = archiveIndex;

  final JournalVaultLoader _loader;
  final ArchiveIndexManager? _archiveIndex;

  ArchiveIndexManager get _indexes => _archiveIndex ?? ArchiveIndexManager();

  static String generateRecordId([DateTime? at]) {
    final now = at ?? DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final suffix = (now.microsecondsSinceEpoch & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return 'jr_${date}_$suffix';
  }

  static String fileNameFor(String recordId) {
    final safe = recordId.replaceAll(RegExp(r'[^\w\-]'), '_');
    return '$safe.md';
  }

  Future<JournalEntry> save({
    required String vaultPath,
    required ArchiveRecord record,
    required String body,
  }) async {
    final result = await saveWithIndexResult(
      vaultPath: vaultPath,
      record: record,
      body: body,
    );
    return result.entry;
  }

  Future<({JournalEntry entry, ArchiveIndexRebuildResult indexResult})>
  saveWithIndexResult({
    required String vaultPath,
    required ArchiveRecord record,
    required String body,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (record.kind != RecordKind.freeformJournal) {
      throw ArgumentError.value(
        record.kind,
        'record.kind',
        'freeformJournal only',
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

    final journalDir = Directory(
      p.join(vaultPath, JournalEntryParser.journalDirName),
    );
    await journalDir.create(recursive: true);

    final title = (record.title?.trim().isNotEmpty ?? false)
        ? record.title!.trim()
        : recordId;

    var addedAt = DateTime.now().toUtc();
    var existingMetadata = ArchiveRecordMetadata.empty;
    var targetPath = record.storagePath?.trim();
    String? existingContent;

    if (targetPath != null &&
        targetPath.isNotEmpty &&
        File(targetPath).existsSync()) {
      existingContent = await File(targetPath).readAsString();
      final existing = JournalEntryParser.parse(existingContent, targetPath);
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
        existingContent = await File(targetPath).readAsString();
      } else {
        targetPath = p.join(journalDir.path, fileNameFor(recordId));
      }
    }
    final recordMetadata = existingMetadata.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );

    final content = JournalEntryParser.serialize(
      recordId: recordId,
      title: title,
      body: body,
      addedAt: addedAt,
      metadata: recordMetadata,
    );

    final expectedRevision =
        record.openedRevision ??
        (existingContent == null
            ? const VaultFileRevision.missing()
            : VaultFileRevision.fromText(existingContent));
    final writeResult = await VaultLosslessRecordWriter().write(
      vaultPath: vaultPath,
      targetPath: targetPath,
      proposedContent: content,
      reason: 'journal_record_save',
      ownedFrontmatterKeys: VaultFrontmatterOwnership.journal,
      existingContent: existingContent,
      expectedRevision: expectedRevision,
    );

    final entry = JournalEntry(
      recordId: recordId,
      title: title,
      body: body.trim(),
      addedAt: addedAt,
      storagePath: targetPath,
      recordMetadata: recordMetadata,
      openedRevision: writeResult.newRevision,
    );
    final indexResult = await _indexes.updateChangedRecord(
      vaultPath: vaultPath,
      absolutePath: targetPath,
    );
    return (entry: entry, indexResult: indexResult);
  }

  Future<void> delete({
    required String vaultPath,
    required String recordId,
  }) async {
    await deleteWithIndexResult(vaultPath: vaultPath, recordId: recordId);
  }

  Future<ArchiveIndexRebuildResult?> deleteWithIndexResult({
    required String vaultPath,
    required String recordId,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (recordId.trim().isEmpty) return null;

    final entries = await _loader.loadFromVault(vaultPath);
    for (final entry in entries) {
      if (entry.recordId != recordId) continue;
      final file = File(entry.storagePath);
      if (await file.exists()) {
        await const VaultTrashService().moveFileToTrash(
          vaultPath: vaultPath,
          absolutePath: entry.storagePath,
        );
        return _indexes.removeRecord(
          vaultPath: vaultPath,
          absolutePath: entry.storagePath,
          sourceRecordId: entry.recordId,
        );
      }
      return null;
    }
    return null;
  }

  Future<JournalEntry?> _findByRecordId(
    String vaultPath,
    String recordId,
  ) async {
    final entries = await _loader.loadFromVault(vaultPath);
    for (final entry in entries) {
      if (entry.recordId == recordId) return entry;
    }
    return null;
  }
}
