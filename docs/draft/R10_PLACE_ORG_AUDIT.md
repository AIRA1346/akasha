# R10 Place / Organization Discovery Audit

> **일자:** 2026-06-22  
> **유형:** 갭 분석 + 구현 스프린트 (R10)  
> **선행:** [R9_DISCOVERY_ENGINE_AUDIT.md](./R9_DISCOVERY_ENGINE_AUDIT.md)  
> **SSOT:** [PROJECT_CONSTITUTION.md](../history/closure-2026-07/PROJECT_CONSTITUTION_STUB.md), [CURRENT_STATE.md](../active/CURRENT_STATE.md)

**방법:** 코드 인용 기준 · Link Index Schema / Discovery Semantics / Registry 구조 변경 없음.

---

## Executive Summary

Place(`pl_`)·Organization(`or_`)는 **ID codec·카탈로그·Link Index**에는 이미 존재하나, R9 시점까지 **Discovery 파이프라인 UI·이웃·후보 레이어**에서 Person/Event/Concept만 허용했다. R10은 동일 2홉 흐름(Work↔Entity↔Work)에 Place/Org를 편입한다.

| 구분 | R9 판정 | R10 조치 |
|------|---------|----------|
| Link Index | ✅ entity id 타입 무관 인덱싱 | 변경 없음 |
| Discovery Engine (`discover`) | ✅ 타입 무관 | 변경 없음 |
| Neighbors fetch | ❌ switch `default: break` | **P0** place/org 분기 추가 |
| LinkCandidateService | ❌ `_linkableTypes` 3종 | **P0** 5종 + catalog-only 허용 |
| Entity Picker | ❌ archive-first 3종만 | **P1** catalog place/org 허용 |
| Preview CTA | ❌ Person/Event/Concept만 | **P1** 장소·조직 버튼 |
| Home / Graph / Workbench / Entity Preview | ❌ 섹션·하이라이트 없음 | **P2** 공통 섹션 위젯 확장 |

---

## 1. Place (`pl_`) 연결 현황 (R9 → R10)

| Surface | R9 | 누락 유형 | R10 |
|---------|-----|-----------|-----|
| Entity ID codec | ✅ `pl_` prefix | — | — |
| Link Index | ✅ `[[pl_…]]` 인덱싱 가능 | — | — |
| `fetchWorkLinkNeighbors` | ❌ | **Engine(UI adapter)** | ✅ `places` 리스트 |
| `fetchEntityLinkNeighbors` | ❌ | **Engine(UI adapter)** | ✅ `places` 리스트 |
| `LinkCandidateService` | ❌ | **Proposal** | ✅ catalog·tag 매칭 |
| Entity Picker | ❌ `usesArchiveFirstFlow` only | **UI+Filter** | ✅ catalog-only 허용 |
| Preview CTA | ❌ | **UI** | ✅ 장소 연결하기 |
| Home 오늘의 연결 | ❌ | **UI** | ✅ 장소 하이라이트 |
| Graph (`KnowledgeGraphView`) | ❌ (섹션 위젯) | **UI** | ✅ `WorkLinkNeighborsSections` |
| Entity Preview / Workbench | ❌ | **UI** | ✅ `EntityLinkNeighborsSections` |

---

## 2. Organization (`or_`) 연결 현황

Place와 동일 패턴. ID `or_`, Link Index 지원, neighbors/candidate/picker/UI 전부 R9에서 누락 → R10에서 `organizations` 리스트·조직 CTA·하이라이트·섹션 추가.

---

## 3. Link Index 지원 여부

`RecordLinkIndexService`는 vault `.md` 본문의 `[[entityId]]`를 **타입 무관**으로 outgoing/incoming에 기록한다 (`R9` §4). Place/Org 링크가 vault에 있으면:

- `EntityRelatedWorksDiscovery.entityIdsForWork` — ✅ 반환
- `discover(entityId)` — ✅ 연결 작품 집합

**결론:** Index·Discovery SSOT는 이미 지원. 갭은 **이웃 fetch의 타입 필터**와 **UI/Proposal 레이어**.

---

## 4. UI vs Engine 분리

| 레이어 | Place/Org R9 상태 | 설명 |
|--------|-------------------|------|
| **Engine (Index + Discovery)** | 부분 지원 | 링크 집합 조회는 동작; neighbors가 타입 버림 |
| **Proposal (LinkCandidate)** | 미지원 | catalog place/org 제외 |
| **Picker filter** | 미지원 | archive-first 3종만 |
| **UI Sections** | 미지원 | person/event/concept 섹션만 렌더 |

R10은 Engine semantics 변경 없이 **adapter·proposal·UI**만 확장한다.

---

## 5. 구현 계획 (금지 사항 준수)

### 금지 (미변경)

- Search Index
- Link Index Schema
- Discovery Semantics (`entity_related_works_discovery.dart`)
- Registry 구조
- Preview Stack (`PreviewPanelChrome` 등)

### P0 — Engine adapters

- `lib/utils/discovery_linkable_types.dart` — 공통 5종 타입·`isCatalogLinkable`
- `work_link_neighbors.dart` — `places`, `organizations`
- `entity_link_neighbors.dart` — 동일
- `link_candidate_service.dart` — `_linkableTypes` → 5종

### P1 — 연결 진입

- `entity_link_picker_candidates.dart` — place/org catalog 허용
- `work_preview_empty_connections.dart` — 장소·조직 CTA
- `dashboard_preview_panel.dart` — CTA 배선
- `entity_link_picker_dialog.dart` — subtitle·아이콘

### P2 — Surface 노출

- `work_link_neighbors_sections.dart` / `entity_link_neighbors_sections.dart`
- `home_dashboard_todays_links_section.dart` — 장소·조직 하이라이트
- Graph / Workbench / Entity Preview — 공통 섹션 위젯으로 자동 반영

---

## 6. 성공 기준 검증

| 흐름 | 기대 |
|------|------|
| Work → Place → Work | neighbors `places` + connectedWorks 2홉 |
| Organization → Work | entity neighbors `connectedWorks` |
| Picker | catalog place/org 검색·선택 |
| Preview | 빈 연결 CTA · 추천 칩에 place/org |
| Home | 오늘의 연결 카드에 장소·조직 |
| Graph / Workbench | 관련 장소·조직 섹션 |

---

## 7. 의도적 비범위

- Place/Org **seed fallback** — Person 전용 Cold Graph 유지
- **Archive-first** place/org — `EntityArchiveService` 미변경; catalog-only 연결만
- 3홉+ 자동 탐색 — R9 천장(2홉) 유지
