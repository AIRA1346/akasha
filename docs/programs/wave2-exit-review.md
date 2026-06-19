# Wave 2 Exit Review — Vault Frontmatter v2

> **일자:** 2026-06-19  
> **범위:** Wave 2 코드 · 테스트 · Wave 1 R1 fix  
> **판정:** 🟢 **코드 Exit** — regression 357 passed · legacy 100% 호환  
> **다음:** [wave3-timeline-journal-spec.md](wave3-timeline-journal-spec.md) · [wave3-pre-implementation-review.md](wave3-pre-implementation-review.md)

---

## 1. Executive Summary

Wave 2 목표(Work Record frontmatter v2 + ArchiveRecord round-trip, legacy `{category}/` 유지)는 **코드·회귀 테스트** 기준으로 달성했다.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| EntityFrontmatter infer/lazy | 🟢 | `entity_frontmatter.dart` + unit tests |
| MarkdownParser v2 read/write | 🟢 | entity_id > work_id · lazy serialize |
| Legacy 호환 | 🟢 | v1 fixture · sub_* ID · 기존 경로 유지 |
| works/ path opt-in | 🟢 | pref default OFF · existing filePath immobile |
| ArchiveRecordMapper | 🟢 | `fromWorkMarkdown` workJournal |
| R1 upsert 순서 | 🟢 | saveItem → catalog upsert |
| Vault settings UI (works/) | 🟡 | pref API만 · UI toggle Wave 2.1 optional |

---

## 2. Spec §10 Exit Checklist

| 체크 | 상태 | 비고 |
|------|:----:|------|
| Parser read v2 + legacy infer | ✅ | `EntityFrontmatter.inferFromYaml` |
| Serializer lazy v2 on save | ✅ | `toLazyWriteFields` · work_id mirror |
| works/ path opt-in | ✅ | `UserPreferences.isVaultWorksLayoutEnabled` |
| ArchiveRecord round-trip 1 Work path | ✅ | `fromWorkMarkdown` + fixtures |
| Wave 1 + legacy fixtures green | ✅ | `vault_v1_legacy.md` · `vault_v2_work.md` |
| `flutter test` green | ✅ | **357 passed** @ 2026-06-19 |
| vault-layout-v2 §4 frontmatter | ✅ | entity_type · entity_id · subtype · record_kind |

---

## 3. 구현 산출물 (코드)

| 파일 | 역할 |
|------|------|
| `entity_frontmatter.dart` | YAML infer · lazy write · EntityAnchor bridge |
| `markdown_parser.dart` | deserialize v2 · serialize entity_* |
| `vault_work_journal_paths.dart` | legacy vs `works/{subtype}/` resolver |
| `file_service.dart` | folder stub · path resolver on new save |
| `user_preferences.dart` | `vaultWorksLayoutKey` |
| `archive_record_mapper.dart` | `fromWorkMarkdown` |
| `home_dialogs_coordinator.dart` | R1: upsert after saveItem |
| `entity_frontmatter_test.dart` | infer · lazy fields |
| `markdown_parser_v2_test.dart` | T1~T6 · path integration |

---

## 4. Wave 0 P0 · W2 결정 대응

| ID | 결정 | 결과 |
|----|------|------|
| P0-W2-1 | entity_id > work_id | ✅ deserialize |
| P0-W2-2 | wk_u_* catalog join | ✅ Wave 1 유지 |
| P0-W2-3 | works/ default OFF | ✅ |
| P0-W2-5 | AkashaItem.entity_type ❌ | ✅ infer only |
| P0-W2-7 | upsert after save | ✅ |
| D-W2-1 | workJournal saveItem 유지 | ✅ ArchiveRecordPort 미통합 |

---

## 5. 잔여 · Wave 3 전 이관

| # | 등급 | 항목 | 권고 |
|---|:----:|------|------|
| R-W2-1 | Low | Vault settings UI — works/ layout toggle | W2.1 또는 W3 |
| R-W2-2 | Info | `journal/` folder create only — freeform save W3 | W3-J* |
| R-W2-3 | Process | Wave 1 dogfood ⏳ | Gate에서 분리 (코드 Exit 독립) |

---

## 6. Wave 3 Gate 조건

| # | 조건 | 상태 |
|---|------|:----:|
| G1 | Wave 2 Exit checklist green | ✅ |
| G2 | Wave 2 regression green | ✅ 357 |
| G3 | [wave3-pre-implementation-review.md](wave3-pre-implementation-review.md) P0 결정 | 🔄 |
| G4 | Timeline frontmatter unchanged (W2 T8) | ✅ |

**Gate 🟢 시:** W3-T1 (timeline list) 또는 W3-J1 (journal folder scan)부터 순차 구현.

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 2 code exit · 357 tests · Wave 3 Gate |
