import 'package:path/path.dart' as p;

import '../core/archiving/journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../core/archiving/same_day_record_ref.dart';
import '../core/archiving/timeline_entry.dart';
import 'journal_vault_loader.dart';
import 'timeline_vault_loader.dart';

/// W5-5 — Timeline · journal 같은 로컬 날짜 Record 탐색.
abstract final class SameDayRecordService {
  static bool sameLocalDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static List<SameDayRecordRef> collectFromEntries({
    required DateTime anchor,
    required List<TimelineEntry> timeline,
    required List<JournalEntry> journals,
    String? excludePath,
  }) {
    final normalizedExclude =
        excludePath != null && excludePath.isNotEmpty
            ? p.normalize(excludePath)
            : null;
    final refs = <SameDayRecordRef>[];

    for (final entry in timeline) {
      if (!sameLocalDay(entry.occurredAt, anchor)) continue;
      if (_isExcluded(entry.storagePath, normalizedExclude)) continue;
      refs.add(
        SameDayRecordRef(
          kind: RecordKind.timelineEntry,
          title: entry.title,
          storagePath: entry.storagePath,
          when: entry.occurredAt,
        ),
      );
    }

    for (final entry in journals) {
      if (!sameLocalDay(entry.addedAt, anchor)) continue;
      if (_isExcluded(entry.storagePath, normalizedExclude)) continue;
      refs.add(
        SameDayRecordRef(
          kind: RecordKind.freeformJournal,
          title: entry.title,
          storagePath: entry.storagePath,
          when: entry.addedAt,
        ),
      );
    }

    refs.sort((a, b) => b.when.compareTo(a.when));
    return refs;
  }

  static Future<List<SameDayRecordRef>> findForAnchor({
    required String? vaultPath,
    required DateTime anchor,
    String? excludePath,
  }) async {
    if (vaultPath == null || vaultPath.isEmpty) return const [];

    final timeline = await const TimelineVaultLoader().loadFromVault(vaultPath);
    final journals = await const JournalVaultLoader().loadFromVault(vaultPath);

    return collectFromEntries(
      anchor: anchor,
      timeline: timeline,
      journals: journals,
      excludePath: excludePath,
    );
  }

  static bool _isExcluded(String path, String? normalizedExclude) {
    if (normalizedExclude == null) return false;
    return p.normalize(path) == normalizedExclude;
  }
}
