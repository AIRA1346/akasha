# R8 P1 Implementation Audit — Link Candidate 데이터 추적

> **일자:** 2026-06-22  
> **Sprint:** R8-P1 Link Candidate  
> **설계:** [R8_P1_LINK_CANDIDATE_DESIGN.md](./R8_P1_LINK_CANDIDATE_DESIGN.md)  
> **선행:** [R8_DISCOVERY_IMPLEMENTATION_PLAN.md](./R8_DISCOVERY_IMPLEMENTATION_PLAN.md)

---

## Executive Summary

Work 맥락 연결 후보에 쓸 수 있는 데이터는 **이미 존재**하나, R8 P1 이전에는 **조합 계층이 없었다**. 본 Audit은 각 소스의 코드 위치·현재 소비처·P1에서의 후보 기여도를 정리한다.

| 소스 | 후보 신호 | P1 사용 |
|------|-----------|---------|
| `work.creator` | 강함 (미사용) | ✅ creator score 10/7 |
| `work.tags` | 중간 (heuristic만) | ✅ tag score 5/4/3 |
| `PersonSeedRegistry` | P0 Picker fallback | ✅ seed score 2 + creator 매칭 |
| `UserCatalogEntity` | Picker 검색 | ✅ tag/creator + catalog 1.0 |
| `EntityLinkPickerCandidates` | catalog/seed 목록 | ✅ 유지 · 추천과 병행 |
| `WorkLinkNeighbors` | 링크 후 이웃 | ❌ 변경 없음 |
| `EntityRelatedWorksDiscovery` | 그래프 파생 | ⚠️ excludeLinked 옵션만 |

---

## 1. work.creator

### 데이터 경로

| 단계 | 파일 | 동작 |
|------|------|------|
| Registry Fact | `RegistryWork.creator` | akasha-db 10k 작품 메타 |
| Archive | `HomeAutoArchive` / `itemFromRegistryWork` | vault md frontmatter에 복사 |
| 런타임 | `AkashaItem.creator` | Preview · Workbench · Fusion |

### 현재 소비처 (P1 이전)

| 소비처 | 파일 | 용도 |
|--------|------|------|
| Fusion 로컬 검색 | `fusion_search_service.dart` L78 | `item.creator.contains(q)` |
| Preview 메타 | `dashboard_preview_panel.dart` | creator · 연도 표시 |
| Work info 패널 | `work_detail_info_panel.dart` | 편집 가능 메타 |

### Link Candidate 기여

- **creator exact** (10.0): `work.creator` ↔ seed/catalog title·alias 일치
- **creator token** (7.0): 쉼표·공백 분리 토큰 부분 일치
- Registry에서 아카이브된 Work는 **creator가 채워진 경우가 많음** → Cold Graph에서도 1순위 신호

---

## 2. work.tags

### 데이터 경로

| 단계 | 파일 |
|------|------|
| Registry | `RegistryWork.tags` / extensions |
| Vault md | YAML `tags:` → `AkashaItem.tags` |
| Preview | `WorkLinkNeighborsSections.conceptTags` |

### 현재 소비처 (P1 이전)

| 소비처 | 파일 | 용도 |
|--------|------|------|
| Fusion 검색 | `fusion_search_service.dart` | 로컬 토큰 매칭 |
| **relatedCharactersForWork** | `work_related_characters.dart` | Person tag·alias ↔ work.tags 점수 |
| neighbors 보충 | `work_link_neighbors.dart` L69–78 | 링크 0일 때 characters heuristic |
| Preview 조건 | `dashboard_preview_panel.dart` | tags 비어 있으면 empty CTA |

### Link Candidate 기여

| 규칙 | score | 조건 |
|------|:-----:|------|
| tag exact | 5.0 | work.tags ∩ entity.tags |
| title in tag | 4.0 | entity tag가 work.title 포함 |
| tag in alias | 3.0 | work tag ∈ entity.aliases |

`relatedCharactersForWork` 로직을 **formalize** — neighbors 파이프라인은 **미변경** (금지 준수).

---

## 3. PersonSeedRegistry

### 데이터

- 에셋: `assets/entities/person_seed.json` (5명 MVP)
- 구현: `person_seed_registry.dart`
- Port: `EntityRegistryPort`

### 현재 소비처

| 소비처 | 파일 | 용도 |
|--------|------|------|
| Fusion Search | `fusion_search_service.dart` | `entityGlobalHits` |
| Search Dialog | `home_dialogs_facade.dart` | 기본 `entityRegistry` |
| **P0 Picker fallback** | `entity_link_picker_candidates.dart` | catalog 0일 때만 |

### P1 API 사용

- `listFacts(type:)` — Work 맥락 전체 seed 순회
- `search` — creator 토큰 보조 (빈 쿼리는 `[]` 유지 — Fusion 회귀 방지)
- catalog에 없는 seed: creator 매칭 또는 **browse filler** (2.0)

---

## 4. UserCatalogEntity

### 데이터

- Tier 1.5 로컬 catalog · `UserCatalogPort`
- 필드: `entityId`, `title`, `aliases`, `tags`, `entityType`, `addedAt`

### 현재 소비처

| 소비처 | 용도 |
|--------|------|
| `EntityLinkPickerCandidates` | Picker catalog 검색 |
| `fetchWorkLinkNeighbors` | 링크된 entity 해석 |
| `relatedCharactersForWork` | tag heuristic |
| `CollectibleCollectionPipeline` | 컬렉션 필터 |
| Fusion | `catalogHits` |

### Link Candidate 기여

- creator·tag 매칭 시 catalog person/event/concept 후보
- 신호 없을 때 **catalog fallback** (1.0) — seed도 없을 때만 의미 있음
- P0 `EntitySeedCatalogPromotion` — seed 선택 시 동일 id로 upsert

---

## 5. EntityLinkPickerCandidates

### 구조 (P0 + P1)

```
build(query)
  → catalog 검색/전체
  → catalog ≥ 1 → 반환
  → catalog = 0 → PersonSeed fallback (P0)

P1 추가 (Dialog 레이어):
  workContext 있음
    → LinkCandidateService.candidatesForWork (상단 추천)
    → build() 결과 (하단 검색 · 중복 id 제외)
```

**분리 원칙:** Candidate **계산**은 `LinkCandidateService` · **목록 빌드**는 기존 `EntityLinkPickerCandidates` 유지.

---

## 6. WorkLinkNeighbors / EntityRelatedWorksDiscovery

### WorkLinkNeighbors (`work_link_neighbors.dart`)

- `discovery.entityIdsForWork(workId)` — **실제 링크**만
- `relatedCharactersForWork` — 링크 부족 시 보충 (Discovery semantics)
- **P1 변경 없음**

### EntityRelatedWorksDiscovery

- `discover(entityId)` · `entityIdsForWork(workId)`
- Link Index 파생 · Schema 무변경
- P1: `LinkCandidateService.excludeEntityIds` — 이미 연결된 id 제외 (선택)

---

## 7. UI 진입점 (P1 구현)

| 지점 | 파일 | P1 조치 |
|------|------|---------|
| Picker 추천 | `entity_link_picker_dialog.dart` | `workContext` · 「이 작품과 관련」 |
| Preview 추천 | `work_preview_empty_connections.dart` | 「추천 연결」 chips 상위 3 |
| Preview 로드 | `dashboard_preview_panel.dart` | `candidatesForWork(limit: 3)` |
| 연결 실행 | `work_detail_workspace.dart` | preselected candidate → `insertWikiLink` |
| Shell | `home_shell_controller.dart` | `openWorkFromPreviewToConnectSuggested` |

---

## 8. 금지 준수 체크

| 금지 | P1 |
|------|-----|
| Discovery Semantics | ✅ neighbors/discovery 미변경 |
| Link Index Schema | ✅ 미변경 |
| Search Index | ✅ 미변경 |
| Collection Pipeline | ✅ 미변경 |
| Preview Stack / Save Return | ✅ Preview chrome 동일 · save return 동일 |
| UI 구조 변경 | ✅ CTA 영역·Picker 섹션만 추가 |

---

## 관련 산출물

- [R8_P1_IMPLEMENTATION_REPORT.md](./R8_P1_IMPLEMENTATION_REPORT.md)
