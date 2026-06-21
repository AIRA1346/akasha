# Wave 4 Exit Review — Person · Event · Concept Entity Types

> **일자:** 2026-06-19  
> **범위:** Wave 4 코드 · 테스트  
> **판정:** 🟡 **MVP Exit** — multi-type catalog · fusion · entity journal · browse filter ✅ · **Archive-First UX debt 🔶** · dogfood ⏳ (R5)  
> **다음:** [archive-first-realignment-plan.md](archive-first-realignment-plan.md) R1 · Wave 6 · dogfood

---

## 1. Executive Summary

Wave 4 MVP(Person · Event · Concept user-local + Person global seed) 목표는 **코드·회귀 테스트** 기준으로 달성했다.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| EntityIdCodec + EntityAnchor | 🟢 | cross-type ID · prefix parse |
| UserCatalog multi-type | 🟢 | pe_u_* · co_u_* · ev_u_* load/search |
| FusionSearch multi-type | 🟢 | catalog + global Person hit |
| Person seed registry | 🟢 | bundled 5명 (Einstein 등) |
| Add catalog entity dialog | 🟡 | 유형 선택 ✅ · **catalog-first · journal opt-in** — UX debt |
| Entity journal vault | 🟢 | entities/{type}/ · parser/store |
| Browse entity filter (W4-9) | 🟢 | FilterSection chips · CatalogEntityBrowseView |
| Person seed 100+ | ⬜ | charter defer |
| Entity journal edit UI | 🟢 | W4.1 — Entity tab · catalog dialog |
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
| `entity_vault_loader.dart` · `entity_journal_view.dart` | W4.1 load · 기록 Entity tab |
| `entity_journal_dialog.dart` | catalog · journal 편집/생성/삭제 |

---

## 4. Known UX debt — Archive-First (R1 대상)

> SSOT: [archive-first-realignment-plan.md](archive-first-realignment-plan.md) §2

| # | 현재 (Wave 4) | 목표 (R1) |
|---|---------------|-----------|
| D1 | Person 추가 → `user_entities.json` **기본** | `entities/person/*.md` **기본** |
| D2 | journal 생성 **opt-in** 체크 | journal **기본 ON** · 「이름만」= 고급 |
| D3 | SnackBar 「catalog 추가」 | 「**아카이브에 추가됨**」 |
| D4 | Fusion 섹션 「내 catalog — Entity」 | 「**내 아카이브** — Person/Concept…」 |
| D5 | catalog-only Person → Browse/서재 **미노출** | archived journal 기준 strip/기록 (R2) |
| D6 | `onCatalogEntityAdded` highlight | `onEntityArchived` · journal path (R1) |

**판정:** Wave 4 **기술 Exit ✅** · 제품 의도 정합은 **R1 Gate**에서 해소.

---

## 5. 잔여 · Wave 5 전

| # | 항목 | Wave |
|---|------|------|
| R-W4-1 | Entity journal list/edit UI | ✅ W4.1 |
| R-W4-2 | Person seed 100+ (non-blocking) | optional |
| R-W4-3 | Place · Organization user-local MVP | W4.2 |
| R-W4-4 | Connection graph (Entity links) | ✅ W5 MVP |

---

## 6. 테스트

| 시점 | 결과 |
|------|------|
| Wave 4 exit | **375 passed** (W4.1 +2) |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1.1 — W4.1 entity journal UI · 375 tests |
| 2026-06-19 | **v1.2 Archive-First** — §4 UX debt · R1 pointer |
