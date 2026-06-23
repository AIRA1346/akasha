# R13 Relationship Discovery Implementation Plan

> **일자:** 2026-06-22  
> **선행:** [R12_RELATIONSHIP_DISCOVERY_AUDIT.md](./R12_RELATIONSHIP_DISCOVERY_AUDIT.md)  
> **유형:** Level 3 첫 구현 (Analysis + Surface)

**금지:** Link Index Schema · Search Index · Discovery Semantics · Registry · Preview Stack 변경 없음.

---

## 1. R12 설계 검증

| R12 제안 | R13 채택 | 비고 |
|----------|----------|------|
| `RelationshipDiscoveryService` read-only | ✅ | `lib/services/relationship_discovery_service.dart` |
| `bridgeEntities(A, B)` | ✅ | 5종 Entity 교집합 + 직접 Work 링크 |
| Bridge 라벨 on `connectedWorks` | ✅ | `WorkLinkNeighbors.connectedWorkBridgeLabels` |
| `themeClusters` Concept ≥3 | ✅ | vault 전수 `entityIdsForWork` 집계 |
| Engine `discover` 시그니처 불변 | ✅ | 기존 API만 **읽기** |
| Home 「반복 주제」| ✅ P1 | Preview 우선 · Home 섹션 추가 |

**검증 결론:** R12 Phase A(Engine-safe) 범위 **#1 bridge 라벨 + #2 Concept cluster** 만 이번 Sprint에 구현. coEntitiesForEntity·sharedEntities 패널은 R14.

---

## 2. 구현 범위

### Step 2 — `RelationshipDiscoveryService`

| API | 역할 |
|-----|------|
| `bridgeBetweenWorks(source, target, …)` | A↔B 최적 브리지 1건 |
| `bridgeLabelsForConnectedWorks(source, connected, …)` | connectedWorks용 label map |
| `conceptThemeClusters(…)` | Concept Entity별 ≥N Work |
| `conceptThemeClustersForWork(workId, …)` | 현재 Work 포함 클러스터만 |

브리지 우선순위: **직접 Work 링크** → Concept → Person → Event → Place → Organization.

라벨 형식 (한국어):

| 타입 | 예시 |
|------|------|
| direct | `직접 링크` |
| person | `{title} 때문에 연결` |
| concept | `{title} 개념 때문에 연결` |
| event | `{title} 사건 때문에 연결` |
| place | `{title} 장소 때문에 연결` |
| organization | `{title} 때문에 연결` |

### Step 3 — Surface (Bridge Label)

- `WorkLinkConnectedWorksList` — `bridgeLabelsByWorkId` prop
- `WorkLinkNeighborsSections` — neighbors에서 label 전달
- `fetchWorkLinkNeighbors` — 반환 시 label·themeClusters 포함 (adapter 확장)

### Step 4 — Theme Cluster Surface

- `WorkPreviewThemeClustersSection` 위젯
- Work Preview · Workbench · Graph neighbors 아래 노출
- `HomeDashboardThemeClustersSection` — 볼트 전역 top 클러스터

---

## 3. 파일 변경 목록

| 파일 | 변경 |
|------|------|
| `lib/services/relationship_discovery_service.dart` | **신규** |
| `lib/utils/work_link_neighbors.dart` | bridgeLabels · themeClusters 필드 + adapter |
| `lib/widgets/work_link_neighbors_sections.dart` | bridge label · theme section |
| `lib/widgets/work_preview_theme_clusters_section.dart` | **신규** |
| `lib/screens/home/views/home_dashboard/home_dashboard_theme_clusters_section.dart` | **신규** |
| `lib/screens/home/views/home_dashboard/home_dashboard_view.dart` | theme 섹션 배선 |
| `test/relationship_discovery_service_test.dart` | **신규** |

**미변경:** `entity_related_works_discovery.dart` · `record_link_index_service.dart` · `preview_panel_chrome.dart`

---

## 4. 성공 기준

- [ ] Work A Preview에서 connected Work B에 **「X 때문에 연결」** 라벨
- [ ] Concept 3작품 이상 시 **Theme Cluster** 칩 표시
- [ ] Engine semantics 테스트 회귀 PASS

---

## 5. 테스트 계획

- shared Person/Concept bridge 라벨
- direct work link 우선
- theme cluster minWorks=3 필터
- `conceptThemeClustersForWork` 멤버십 필터
