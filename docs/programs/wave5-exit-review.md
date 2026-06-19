# Wave 5 Exit Review — Connection (RecordLink · Wiki Navigate)

> **일자:** 2026-06-19  
> **범위:** Wave 5 코드 · 테스트  
> **판정:** 🟡 **MVP Exit** — parser · index · incoming UI · preview tap ✅ · dogfood ⏳  
> **다음:** [wave5-dogfood-checklist.md](wave5-dogfood-checklist.md) · ADR-013 · Wave 6 검토

---

## 1. Executive Summary

Wave 5 MVP(`[[entity_id|label]]` 파싱 → vault link index → 양방향 탐색 UI) 목표는 **코드·회귀 테스트** 기준으로 달성했다.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| RecordLinkParser | 🟢 | explicitId · titleOnly · code block skip |
| Link index service | 🟢 | `.akasha/link_index.json` · incoming/outgoing |
| Vault auto-rebuild | 🟢 | loadItems + vault watch debounce |
| Entity incoming links | 🟢 | entity journal dialog 섹션 |
| Workbench preview tap | 🟢 | `akasha-wiki:` → navigate |
| Title-only resolve | 🟢 | catalog alias · vault work title |
| ADR-013 | 🟢 | [ADR-013](../adr/ADR-013-connection-link-index.md) |
| W5-5 sameDay | 🟢 | Entity Sheet «같은 날 기록» |
| E2E dogfood | ⏳ | manual gate |

---

## 2. Spec §8 Exit Checklist

| 체크 | 상태 | 비고 |
|------|:----:|------|
| W5-1 RecordLinkParser | ✅ | record_link_parser_test |
| W5-2 Link index rebuild | ✅ | record_link_index_test |
| W5-3 incoming links UI | ✅ | entity_journal_dialog |
| W5-4 outbound tap navigate | ✅ | vault_markdown_body · navigator |
| Work → Person/Concept dogfood | ⏳ | wave5-dogfood-checklist |

---

## 3. 구현 산출물

| 파일 | 역할 |
|------|------|
| `record_link.dart` | ParsedRecordLink · RecordLink model |
| `record_link_parser.dart` | `[[…]]` parse · frontmatter body |
| `record_link_index_service.dart` | vault scan · JSON index |
| `record_link_port.dart` | port interface |
| `record_link_markdown.dart` | preview preprocess · href decode |
| `record_link_navigator.dart` | tap · incoming record open |
| `home_vault_coordinator.dart` | linkIndex · auto rebuild |
| `entity_journal_dialog.dart` | «링크한 Record» 섹션 |
| `vault_markdown_body.dart` | onTapLink wiki navigate |

---

## 4. E2E 흐름 (MVP)

```
Work .md 본문 [[pe_u_xxx|작가]]
    → Sanctum 보기 탭 링크 tap
    → entity journal dialog (Person)
    → «링크한 Record»에 work path 표시
    → tap → workbench reopen
```

---

## 5. 잔여

| # | 항목 | 우선 |
|---|------|------|
| R-W5-1 | Dogfood 1회 | Gate |
| R-W5-2 | ADR-013 Link Index | 문서 |
| R-W5-3 | Incremental index (single-file) | optional |
| R-W5-4 | sameDay sidebar | W5.1 optional |
| R-W5-5 | titleOnly → fusion search fallback | enhancement |

---

## 6. 테스트

| 시점 | 결과 |
|------|------|
| Wave 5 exit | **389 passed** |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 5 MVP exit · 389 tests |
