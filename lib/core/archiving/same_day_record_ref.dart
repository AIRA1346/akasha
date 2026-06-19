import '../../core/archiving/record_kind.dart';

/// W5-5 — Entity Sheet «같은 날 기록» 항목.
class SameDayRecordRef {
  const SameDayRecordRef({
    required this.kind,
    required this.title,
    required this.storagePath,
    required this.when,
  });

  final RecordKind kind;
  final String title;
  final String storagePath;
  final DateTime when;

  String get kindLabel => switch (kind) {
        RecordKind.timelineEntry => 'Timeline',
        RecordKind.freeformJournal => 'Journal',
        RecordKind.workJournal => 'Work',
        RecordKind.entityJournal => 'Entity',
        _ => kind.name,
      };
}
