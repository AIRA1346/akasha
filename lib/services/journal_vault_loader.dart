import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/journal_entry.dart';
import '../core/archiving/vault_file_revision.dart';
import 'journal_entry_parser.dart';

/// `vault/journal/` 에서 freeform journal 로드.
class JournalVaultLoader {
  const JournalVaultLoader();

  Future<List<JournalEntry>> loadFromVault(String? vaultPath) async {
    if (vaultPath == null || vaultPath.isEmpty) return const [];

    final dir = Directory(p.join(vaultPath, JournalEntryParser.journalDirName));
    if (!await dir.exists()) return const [];

    final entries = <JournalEntry>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      try {
        final content = await entity.readAsString();
        final parsed = JournalEntryParser.parse(content, entity.path);
        if (parsed != null) {
          entries.add(
            JournalEntry(
              recordId: parsed.recordId,
              title: parsed.title,
              body: parsed.body,
              addedAt: parsed.addedAt,
              storagePath: parsed.storagePath,
              recordMetadata: parsed.recordMetadata,
              openedRevision: VaultFileRevision.fromText(
                content,
                modifiedAtUtc: (await entity.lastModified()).toUtc(),
              ),
            ),
          );
        }
      } catch (_) {
        // skip malformed journal files
      }
    }

    entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return entries;
  }

  /// Loads one freeform journal by stable id without listing the directory.
  Future<JournalEntry?> loadByRecordId(
    String? vaultPath,
    String recordId,
  ) async {
    final id = recordId.trim();
    if (vaultPath == null || vaultPath.isEmpty || id.isEmpty) return null;

    final direct = File(
      p.join(vaultPath, JournalEntryParser.journalDirName, '$id.md'),
    );
    if (await direct.exists()) {
      return _parseFile(direct);
    }
    return null;
  }

  Future<JournalEntry?> loadByAbsolutePath(String absolutePath) async {
    final file = File(absolutePath);
    if (!await file.exists()) return null;
    return _parseFile(file);
  }

  Future<JournalEntry?> _parseFile(File entity) async {
    try {
      final content = await entity.readAsString();
      final parsed = JournalEntryParser.parse(content, entity.path);
      if (parsed == null) return null;
      return JournalEntry(
        recordId: parsed.recordId,
        title: parsed.title,
        body: parsed.body,
        addedAt: parsed.addedAt,
        storagePath: parsed.storagePath,
        recordMetadata: parsed.recordMetadata,
        openedRevision: VaultFileRevision.fromText(
          content,
          modifiedAtUtc: (await entity.lastModified()).toUtc(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
