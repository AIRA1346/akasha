# Wave 1 Exit Review — Tier 1.5 User Catalog

> **일자:** 2026-06-19  
> **커밋:** `d4f8503` — feat: Wave 1 Tier 1.5 user catalog 및 wk_u_* ID 레이어  
> **범위:** Wave 1 코드 · 테스트 · 빌드 · Wave 0 P0 대응  
> **판정:** 🟡 **조건부 통과** — 코드·테스트·빌드 ✅ · dogfood·policy §10 일부 ⏳  
> **다음:** [wave2-vault-record-spec.md](wave2-vault-record-spec.md) 설계 Gate · [entity-record-storage-masterplan.md](entity-record-storage-masterplan.md)

---

## 1. Executive Summary

Wave 1 목표(사전에 없는 **Work**를 `wk_u_*` Fact로 등록하고 Fusion search에서 hit)는 **코드·회귀 테스트·release 빌드** 기준으로 달성했다.

Wave 0 P0 5건 중 **ID·EntityAnchor·catalog 경로·Fusion·볼트 필수 UX**는 해결됐다.  
**Dogfood·RegistryWorkAutocomplete catalog merge·upsert 순서**는 Wave 2 착수 전 정리 권고.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| `wk_u_*` ID 레이어 | 🟢 | buildUserLocal · isMasterFormat · ensureWorkId 보존 |
| UserCatalogStore | 🟢 | `vault/catalog/user_entities.json` CRUD · vault watch |
| FusionSearchService | 🟢 | 3-tier merge · catalog badge |
| Browse vs Search 경계 | 🟢 | BrowsePipeline 미변경 (spec 준수) |
| Dogfood E2E | 🟡 | 수동 시나리오 미기록 |
| Entity Type 확장 | ⬜ | Wave 1 scope — work only (의도) |

---

## 2. Wave 0 P0 — 대응 현황

| ID | 이슈 | Wave 1 결과 |
|----|------|-------------|
| P0-1 | `wk_u_*` vs WorkIdCodec | ✅ `isGlobalWorkId` / `isUserLocalWorkId` / `isMasterFormat` / `EntityAnchor.isWork` |
| P0-2 | Contribution 경로 문서≠코드 | ✅ policy §4 「현재 app data · Wave 1 이전 안 함」 |
| P0-3 | `user_entities.json` SSOT | ✅ 파일명·스키마 v1 |
| P0-4 | 볼트 필수 Tier 1.5 | ✅ custom add 차단 · in-memory deprecated |
| P0-5 | Fusion dedupe §6.1 | ✅ local > catalog > global (entityId 기준) |

---

## 3. Policy §10 · Spec §11 Exit

| 체크 | 상태 | 비고 |
|------|:----:|------|
| `wk_u_*` 발급 · persist | ✅ | `UserCatalogStore` |
| Fusion user-only hit | ✅ | `fusion_search_service_test` |
| ID namespace 충돌 없음 | ✅ | `wk_u_*` ≠ `wk_\d{9}` |
| catalog-only 표시 | ✅ | FusionSearchDialog 「내 catalog」 |
| Contribution ↔ catalog 분리 | ✅ | 코드·문서 일치 |
| Legacy `custom_*` 신규 제거 | ✅ | `buildUserLocal` 경로 |
| `flutter test` green | ✅ | 344 passed @ commit |
| Release build | ✅ | `build_release.ps1` |
| **Dogfood** | ⏳ | 볼트→직접 추가→검색→(선택) archive 미기록 |

---

## 4. 구현 산출물 (코드)

| 파일 | 역할 |
|------|------|
| `work_id_codec.dart` | `buildUserLocal()` · user local pattern |
| `user_catalog_entity.dart` · `user_catalog_store.dart` | Tier 1.5 Fact |
| `fusion_search_service.dart` · `fusion_search_dialog.dart` | 3-tier search |
| `home_dialogs_coordinator.dart` | vault 필수 · catalog upsert |
| `file_service.dart` | `catalog/` skip · folder create |

---

## 5. 잔여·Wave 2 전 이관

| # | 등급 | 항목 | 권고 Wave |
|---|:----:|------|-----------|
| R1 | Low | catalog upsert → saveItem 순서 (orphan catalog) | W2 또는 W1.1 hotfix |
| R2 | Optional | `RegistryWorkAutocomplete` + user catalog merge | W2 |
| R3 | Process | Dogfood friction log 1회 | Wave 2 Gate 전 |
| R4 | Docs | `wave1-user-catalog-spec.md` §11 체크박스 갱신 | 본 문서로 대체 |

---

## 6. Wave 2 Gate 조건

Wave 2 **코드 착수** 전:

1. ✅ Wave 1 Exit Review (본 문서) 승인
2. ✅ [wave2-pre-implementation-review.md](wave2-pre-implementation-review.md) P0 결정
3. ⏳ [wave1-dogfood-checklist.md](wave1-dogfood-checklist.md) 1회
4. ⏳ Test fixtures (`test/fixtures/vault_v*.md`) — ✅ 작성됨

**Wave 2 착수 금지:** frontmatter v2 스펙 미확정 · `works/` 경로 규칙 미확정 → **✅ wave2 spec + review v1 확정**

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 1 post-implementation exit review |
