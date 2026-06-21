# Wave 3 Exit Review — Timeline · Journal 「기록」축

> **일자:** 2026-06-19  
> **범위:** Wave 3 코드 · 테스트  
> **판정:** 🟡 **MVP Exit** — 기록 UI · journal E2E · timeline edit ✅ · workbench edit ⏳  
> **다음:** [wave4-entity-types-spec.md](wave4-entity-types-spec.md)

---

## 1. Executive Summary

Wave 3 MVP(Journal First · 「기록」축) 목표는 **코드·회귀 테스트** 기준으로 달성했다.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| 「기록」 sidebar + 탭 | 🟢 | RecordsView — 타임라인 \| 메모 |
| Timeline list | 🟢 | 기존 TimelineView · RecordsView 통합 |
| Timeline edit/save | 🟢 | 상세 다이얼로그 편집 · ArchiveRecordPort |
| freeformJournal save/list | 🟢 | journal/ · parser · adapter |
| Journal edit/delete | 🟢 | JournalView 다이얼로그 |
| Workbench timeline tab | ⬜ | W3-T2 full workbench — MVP는 다이얼로그 |
| Entity link picker 개선 | ⬜ | quick capture dropdown 유지 (W3-T3) |

---

## 2. Spec §9 Exit Checklist

| 체크 | 상태 | 비고 |
|------|:----:|------|
| Timeline list + open | ✅ | RecordsView 탭 |
| Timeline edit E2E | ✅ | 다이얼로그 편집 · adapter save |
| freeformJournal save E2E | ✅ | journal_vault_test |
| journal/ loadAllItems 제외 | ✅ | Wave 2 `_skipDirNames` |
| Wave 2 tests green | ✅ | 361 passed |
| Entity link picker (archived works) | 🔶 | capture dropdown · 전용 picker ⏳ |

---

## 3. 구현 산출물

| 파일 | 역할 |
|------|------|
| `records_view.dart` | 「기록」 TabBar shell |
| `journal_view.dart` | 메모 list · edit · delete |
| `journal_entry.dart` · `journal_entry_parser.dart` | freeformJournal model |
| `journal_vault_loader.dart` · `journal_vault_store.dart` | vault/journal/ IO |
| `journal_quick_capture_dialog.dart` | 메모 quick capture |
| `vault_archive_record_adapter.dart` | journal list/save/delete |
| `timeline_view.dart` | 편집·저장 추가 |
| `dashboard_sidebar.dart` | 「기록」 label |
| `journal_vault_test.dart` | parser · store · adapter |

---

## 4. 잔여 · Wave 4 전

| # | 항목 | Wave |
|---|------|------|
| R-W3-1 | WorkbenchRecordContext + timeline workbench tab | W3.1 |
| R-W3-2 | Entity link dedicated picker | W3-T3 |
| R-W3-3 | Fusion timeline title search | optional |

---

## 5. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 3 MVP exit · 361 tests |
