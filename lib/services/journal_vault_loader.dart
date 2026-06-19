import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/journal_entry.dart';
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
        final parsed = JournalEntryParser.parse(
          await entity.readAsString(),
          entity.path,
        );
        if (parsed != null) entries.add(parsed);
      } catch (_) {
        // skip malformed journal files
      }
    }

    entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return entries;
  }
}
