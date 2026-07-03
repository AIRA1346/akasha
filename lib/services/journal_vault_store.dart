import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_record.dart';
import '../core/archiving/journal_entry.dart';
import '../core/archiving/record_kind.dart';
import 'archive_index_manager.dart';
import 'journal_entry_parser.dart';
import 'journal_vault_loader.dart';
import 'vault_trash_service.dart';

/// `vault/journal/` 쓰기·삭제 — Wave 3.
class JournalVaultStore {
  const JournalVaultStore({JournalVaultLoader? loader})
    : _loader = loader ?? const JournalVaultLoader();

  final JournalVaultLoader _loader;

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

    var addedAt = DateTime.now();
    var targetPath = record.storagePath?.trim();

    if (targetPath != null &&
        targetPath.isNotEmpty &&
        File(targetPath).existsSync()) {
      final existing = JournalEntryParser.parse(
        await File(targetPath).readAsString(),
        targetPath,
      );
      if (existing != null) addedAt = existing.addedAt;
    } else {
      final existing = await _findByRecordId(vaultPath, recordId);
      if (existing != null) {
        targetPath = existing.storagePath;
        addedAt = existing.addedAt;
      } else {
        targetPath = p.join(journalDir.path, fileNameFor(recordId));
      }
    }

    final content = JournalEntryParser.serialize(
      recordId: recordId,
      title: title,
      body: body,
      addedAt: addedAt,
    );

    await _writeAtomic(targetPath, content);

    final entry = JournalEntry(
      recordId: recordId,
      title: title,
      body: body.trim(),
      addedAt: addedAt,
      storagePath: targetPath,
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
