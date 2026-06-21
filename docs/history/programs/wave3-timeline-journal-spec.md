# Wave 3 — Timeline · Journal First 구현 스펙

> **상태:** 설계 v1 · pre-review ✅ · 코드 **Gate 대기** ([wave3-pre-implementation-review.md](wave3-pre-implementation-review.md))  
> **갱신:** 2026-06-19  
> **상위:** [entity-type-philosophy.md](../policy/entity-type-philosophy.md) · [vault-layout-v2.md](../product/vault-layout-v2.md)  
> **철학:** Note/일기 = **Record** · Entity optional

---

## 1. 목표

**Journal First** — Entity 없이도 기록·재탐색. Work-only Home에서 **「기록」축** 표면화.

| 하지 않음 (Wave 3) | Wave |
|--------------------|------|
| Person/Event Entity | W4 |
| Connection index | W5 |
| `journal/` full UX polish | W3 MVP만 |

---

## 2. RecordKind (Wave 3 scope)

| Kind | 경로 | Entity | 현재 코드 |
|------|------|--------|-----------|
| `timelineEntry` | `timeline/` | optional | ✅ save · read partial |
| `freeformJournal` | `journal/` | none | ❌ enum only |

---

## 3. 아키텍처 (현재 → 목표)

```
[현재]
Timeline quick capture → VaultArchiveRecordAdapter → timeline/*.md ✅
Home Timeline mode → read timeline entries 🔶
freeformJournal → 미구현

[Wave 3]
+ journal/ quick capture OR promote timeline UX
+ Home sidebar 「기록」 — timeline list + open
+ Phase 4.4b — link entity_id from archived works
+ Workbench adapter: timeline vs work journal edit
```

---

## 4. Timeline (`timelineEntry`) — 갭

### 4.1 구현됨

| 항목 | 파일 |
|------|------|
| Parse | `timeline_entry_parser.dart` |
| Save | `timeline_vault_store.dart` · `VaultArchiveRecordAdapter` |
| Quick capture UI | `timeline_quick_capture_dialog.dart` |
| Entity link (optional) | `entity_id` in frontmatter |

### 4.2 Wave 3 갭

| ID | 작업 | Exit |
|----|------|------|
| W3-T1 | Timeline list UI — Home sidebar / dedicated view | scroll · open entry |
| W3-T2 | Timeline entry **edit** in workbench | save round-trip |
| W3-T3 | Entity link picker — **archived works only** (Phase 4.4b) | wk_* · wk_u_* |
| W3-T4 | Fusion search — timeline title match (optional) | low priority |
| W3-T5 | `occurred_at` vs `added_at` display sort | timeAnchor SSOT |

### 4.3 Frontmatter (unchanged Wave 2)

```yaml
record_kind: timelineEntry
title: "…"
occurred_at: "…"
entity_type: work      # optional
entity_id: "wk_…"      # optional
```

**Wave 2 영향:** timeline frontmatter **변경 없음** (wave2 spec T8).

---

## 5. Freeform Journal (`freeformJournal`)

### 5.1 목적 ([entity-type-philosophy](../policy/entity-type-philosophy.md))

- 아이디어·메모 · **Entity 없음**
- 나중에 Concept/Person **Connection** (Wave 5)

### 5.2 저장

```
{vault}/journal/{slug}.md
```

```yaml
---
record_kind: freeformJournal
title: "스타트업 아이디어"
added_at: "…"
---
```

### 5.3 Wave 3 작업

| ID | 작업 |
|----|------|
| W3-J1 | `journal/` folder create · skip scan for AkashaItem (like timeline) |
| W3-J2 | Journal quick capture dialog (timeline과 유사·단순) |
| W3-J3 | `VaultArchiveRecordAdapter` — freeformJournal save/list |
| W3-J4 | Journal list in 「기록」 sidebar |

---

## 6. Home UX — 「기록」축

| 표면 | Wave 3 |
|------|--------|
| Sidebar | 「타임라인」→ **「기록」** (timeline + journal tabs) |
| Work grid | **변경 없음** |
| Fusion | **변경 없음** |

### 6.1 Navigation coordinator

- `isTimelineMode` → `isRecordsMode` rename **검토** (breaking internal — optional alias)

---

## 7. Workbench adapter

| Record kind | Editor | Save path |
|-------------|--------|-----------|
| workJournal | 기존 Sanctum | VaultPort.saveItem |
| timelineEntry | markdown body | ArchiveRecordPort |
| freeformJournal | markdown body | ArchiveRecordPort |

**W3-W1:** `WorkbenchRecordContext { kind, recordId, storagePath }` — tab metadata.

---

## 8. 테스트

| ID | 케이스 |
|----|--------|
| T1 | timeline round-trip after Wave 2 regression |
| T2 | freeformJournal save/list |
| T3 | timeline with entity_id link to wk_u_* |
| T4 | journal/ excluded from loadAllItems |
| T5 | 「기록」 sidebar smoke |

---

## 9. Wave 3 Exit

- [x] Timeline list + edit E2E (dialog MVP)
- [x] freeformJournal save E2E
- [ ] Entity link picker (archived works) — capture dropdown only
- [ ] Phase 4 Exit (workbench tab)
- [x] Wave 2 tests green (361)

**상세:** [wave3-exit-review.md](wave3-exit-review.md)

---

## 10. 의존성

```
Wave 2 Exit → Wave 3 code
Wave 1 catalog → timeline entity link wk_u_*
Wave 4 → Concept link from journal (W5)
```

---

## 11. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 3 timeline · journal spec |
