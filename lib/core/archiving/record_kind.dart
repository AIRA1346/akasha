/// 사용자 축적 Record의 종류 ([ADR-008](docs/adr/ADR-008-record-entity-time-model.md)).
enum RecordKind {
  /// Tier 1 `wk_` 에 묶인 작품 Journal — Phase 0 기본.
  workJournal,

  /// Entity 없이 vault에만 있는 Journal.
  freeformJournal,

  /// Phase 4 — Timeline 축 (일기·생각·아이디어).
  timelineEntry,
}
