# Wave 3 Pre-Implementation Review

> **일자:** 2026-06-19  
> **범위:** [wave3-timeline-journal-spec.md](wave3-timeline-journal-spec.md)  
> **선행:** Wave 2 ✅ [wave2-exit-review.md](wave2-exit-review.md)  
> **판정:** 🟢 **MVP Exit** — [wave3-exit-review.md](wave3-exit-review.md) · 361 tests  
> **구현 SSOT:** [wave3-timeline-journal-spec.md](wave3-timeline-journal-spec.md)

---

## 1. Executive Summary

Wave 3는 **Journal First** — Entity 없이도 기록·재탐색. Home **「기록」축** + timeline edit + freeformJournal MVP.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| Timeline save/read | 🟢 | quick capture · VaultArchiveRecordAdapter ✅ |
| Timeline list/edit UX | 🟡 | mode exists · full list/workbench edit ❌ |
| freeformJournal | 🔴 | enum only · journal/ skip scan ✅ · save ❌ |
| Home 「기록」축 | 🟡 | `isTimelineMode` · rename 검토 |
| Wave 2 의존 | 🟢 | frontmatter v2 · wk_u_* link ready |

---

## 2. 코드 Gap Inventory

### 2.1 Timeline (`timelineEntry`)

| 기능 | 현재 | Wave 3 |
|------|------|--------|
| Quick capture | ✅ `timeline_quick_capture_dialog` | unchanged |
| Save/list adapter | ✅ `VaultArchiveRecordAdapter` | unchanged |
| Home sidebar list | 🔶 partial | W3-T1 scroll · open |
| Workbench edit | ❌ | W3-T2 save round-trip |
| Entity link picker | 🔶 optional field | W3-T3 archived works only |
| Fusion search hit | ❌ | W3-T4 optional |

**파일:** `timeline_entry_parser.dart` · `timeline_vault_store.dart` · `home_filter_coordinator.dart` (timeline mode)

### 2.2 Freeform Journal (`freeformJournal`)

| 기능 | 현재 | Wave 3 |
|------|------|--------|
| `journal/` folder | ✅ `_ensureFolderStructure` (W2) | unchanged |
| loadAllItems skip | ✅ `_skipDirNames` | unchanged |
| Parser/serializer | ❌ | W3-J2 dedicated or reuse timeline pattern |
| Quick capture UI | ❌ | W3-J2 |
| Adapter save/list | ❌ | W3-J3 |
| Sidebar tab | ❌ | W3-J4 |

### 2.3 Home UX

| 기능 | 현재 | Wave 3 |
|------|------|--------|
| Sidebar label | 「타임라인」 | → 「기록」 (timeline + journal tabs) |
| `isTimelineMode` | ✅ | alias `isRecordsMode` 검토 (internal) |
| Work grid | unchanged | spec 준수 |
| Fusion | unchanged | spec 준수 |

### 2.4 Workbench

| Record kind | Editor | Save |
|-------------|--------|------|
| workJournal | Sanctum ✅ | VaultPort.saveItem |
| timelineEntry | ❌ markdown | ArchiveRecordPort |
| freeformJournal | ❌ | ArchiveRecordPort |

**W3-W1:** `WorkbenchRecordContext { kind, recordId, storagePath }` — tab metadata (신규 검토)

---

## 3. P0 — 결정표

| ID | 이슈 | 결정 | 상태 |
|----|------|------|:----:|
| P0-W3-1 | Sidebar rename scope | **「기록」** label · timeline tab default | ✅ |
| P0-W3-2 | `isTimelineMode` rename | **alias 유지** Wave 3 · breaking rename optional W3.1 | ✅ |
| P0-W3-3 | Journal parser | **timeline 패턴 재사용** · dedicated `journal_entry_parser` | 📝 |
| P0-W3-4 | Entity link scope | **archived works only** wk_* · wk_u_* | ✅ |
| P0-W3-5 | Fusion timeline search | **Wave 3 optional** · default OFF | ✅ |
| P0-W3-6 | Workbench timeline edit | **markdown body** · ArchiveRecordPort save | ✅ |

---

## 4. 구현 순서 (권고)

```
W3-0  Records mode coordinator alias + sidebar 「기록」 shell
W3-T1 Timeline list UI (read-only open → workbench stub)
W3-T2 Timeline workbench edit + save round-trip
W3-J1 JournalEntry model + parser (mirror timeline)
W3-J2 Journal quick capture dialog
W3-J3 VaultArchiveRecordAdapter freeformJournal list/save
W3-J4 「기록」 journal tab
W3-T3 Entity link picker (archived works)
W3-6  regression + optional Fusion T4
```

---

## 5. 테스트 계획 (Wave 3)

| ID | 케이스 | 선행 |
|----|--------|------|
| T1 | timeline round-trip after W2 regression | ✅ |
| T2 | freeformJournal save/list | W3-J3 |
| T3 | timeline entity_id → wk_u_* | W3-T3 |
| T4 | journal/ excluded from loadAllItems | ✅ (W2) |
| T5 | 「기록」 sidebar smoke | W3-0 |

---

## 6. Gate → 코드

| # | 조건 | 상태 |
|---|------|:----:|
| G1 | Wave 2 Exit green | ✅ |
| G2 | 본 review P0-W3-1~6 | 🟡 P0-W3-3 parser detail |
| G3 | wave3 spec §8 tests defined | ✅ |
| G4 | Wave 2 regression | ✅ 361 |

**코드 Gate 🟢** — W3-0~J4 MVP 구현 완료 · [wave3-exit-review.md](wave3-exit-review.md)

---

## 7. Wave 3에서 하지 않음

- Person/Event Entity UI (W4)
- Connection index (W5)
- journal/ full polish · rich editor
- `AkashaItem`에 RecordKind 필드 추가

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 3 pre-implementation review · gap · P0 · Gate |
