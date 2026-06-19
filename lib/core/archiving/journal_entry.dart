/// Freeform journal Archive 항목 — Wave 3 ([ADR-008]).
class JournalEntry {
  JournalEntry({
    required this.recordId,
    required this.title,
    required this.body,
    required this.addedAt,
    required this.storagePath,
  });

  final String recordId;
  final String title;
  final String body;
  final DateTime addedAt;
  final String storagePath;
}
