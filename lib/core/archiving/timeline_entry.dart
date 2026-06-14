/// Timeline Archive 항목 — Phase 4.1 ([ADR-008]).
class TimelineEntry {
  TimelineEntry({
    required this.recordId,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.addedAt,
    required this.storagePath,
    this.entityId,
  });

  final String recordId;
  final String title;
  final String body;
  final DateTime occurredAt;
  final DateTime addedAt;
  final String storagePath;
  final String? entityId;
}
