# Wave 4 Exit Review — Person · Event · Concept Entity Types

> **일자:** 2026-06-19  
> **범위:** Wave 4 코드 · 테스트  
> **판정:** 🟡 **MVP Exit** — multi-type catalog · fusion · entity journal · browse filter ✅ · dogfood ⏳  
> **다음:** entity journal 편집 UI · Person seed 확장 · Wave 5 Connection

---

## 1. Executive Summary

Wave 4 MVP(Person · Event · Concept user-local + Person global seed) 목표는 **코드·회귀 테스트** 기준으로 달성했다.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| EntityIdCodec + EntityAnchor | 🟢 | cross-type ID · prefix parse |
| UserCatalog multi-type | 🟢 | pe_u_* · co_u_* · ev_u_* load/search |
| FusionSearch multi-type | 🟢 | catalog + global Person hit |
| Person seed registry | 🟢 | bundled 5명 (Einstein 등) |
| Add catalog entity dialog | 🟢 | 유형 선택 · opt-in journal |
| Entity journal vault | 🟢 | entities/{type}/ · parser/store |
| Browse entity filter (W4-9) | 🟢 | FilterSection chips · CatalogEntityBrowseView |
| Person seed 100+ | ⬜ | charter defer |
| Entity journal edit UI | ⬜ | Wave 4.1 — JournalView 패턴 재사용 |
| E2E dogfood | ⬜ | 필요 시점 gate |

---

## 2. Spec §10 Exit Checklist

| 체크 | 상태 | 비고 |
|------|:----:|------|
| W4-0 EntityIdCodec + EntityAnchor | ✅ | entity_id_codec_test |
| W4-2 UserCatalog multi-type | ✅ | user_catalog_multitype_test |
| W4-3 FusionSearch multi-type | ✅ | concept/person catalog hit |
| W4-4 Person seed + EntityRegistryPort | ✅ | 5 seed · global search |
| W4-5 Add dialog type picker | ✅ | add_catalog_entity_dialog |
| W4-6 entities journal save | ✅ | entity_vault_w4_test |
| W4-7 Concept MVP (co_u_*) | ✅ | user local only |
| W4-8 Event MVP (ev_u_*) | ✅ | user local only |
| W4-9 Browse entity type filter | ✅ | browse_entity_scope · filter chips |
| Person · Event · Concept dogfood | ⏳ | manual gate |

---

## 3. 구현 산출물

| 파일 | 역할 |
|------|------|
| `entity_id_codec.dart` | global/user-local ID · typeFromId |
| `entity_fact.dart` · `entity_registry_port.dart` | global Fact model/port |
| `person_seed_registry.dart` · `person_seed.json` | bundled Person seed |
| `user_catalog_store.dart` · `UserCatalogEntity` | multi-type catalog v2 |
| `fusion_search_service.dart` | entityType on hits · multi-type merge |
| `add_catalog_entity_dialog.dart` | type picker · catalog add |
| `entity_journal_parser.dart` · `entity_vault_store.dart` | entities/ vault IO |
| `browse_entity_scope.dart` · `catalog_entity_browse_view.dart` | W4-9 browse filter UI |
| `filter_section.dart` · `home_shell_body.dart` | scope chips · grid/catalog split |

---

## 4. 잔여 · Wave 5 전

| # | 항목 | Wave |
|---|------|------|
| R-W4-1 | Entity journal list/edit UI (JournalView 패턴) | W4.1 |
| R-W4-2 | Person seed 100+ (non-blocking) | optional |
| R-W4-3 | Place · Organization user-local MVP | W4.2 |
| R-W4-4 | Connection graph (Entity links) | W5 |

---

## 5. 테스트

| 시점 | 결과 |
|------|------|
| Wave 4 exit | **373 passed** |

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 4 MVP exit · 373 tests |
