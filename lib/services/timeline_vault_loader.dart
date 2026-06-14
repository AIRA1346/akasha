import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/timeline_entry.dart';
import 'timeline_entry_parser.dart';

/// `vault/timeline/` 에서 Timeline entry 로드.
class TimelineVaultLoader {
  const TimelineVaultLoader();

  Future<List<TimelineEntry>> loadFromVault(String? vaultPath) async {
    if (vaultPath == null || vaultPath.isEmpty) return const [];

    final dir = Directory(p.join(vaultPath, TimelineEntryParser.timelineDirName));
    if (!await dir.exists()) return const [];

    final entries = <TimelineEntry>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      try {
        final parsed = TimelineEntryParser.parse(
          await entity.readAsString(),
          entity.path,
        );
        if (parsed != null) entries.add(parsed);
      } catch (_) {
        // skip malformed timeline files
      }
    }

    entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return entries;
  }
}
