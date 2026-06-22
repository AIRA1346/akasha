# R3-C Dead End Removal — Audit

> **갱신:** 2026-06-22  
> **기준:** [R3B_EXPLORATION_AUDIT.md](./R3B_EXPLORATION_AUDIT.md)  
> **범위:** UX 계층만 · Discovery/Graph 엔진/Schema 변경 없음

---

## Sprint 목표

작품 → 연결 → 엔티티 → 다른 연결 → 기록 흐름에서 **Dead End 제거**.

---

## Dead End 경로별 Audit

### D1 — Wiki / Sanctum 링크 → Workbench 직행 (P1)

| 항목 | 내용 |
|------|------|
| **경로** | Sanctum `[[wiki]]` 탭 · Workbench 연결 이웃 탭 |
| **현재** | `handleWikiLinkTap` → `workbenchCoord.openEntity` / `openBrowseItem` |
| **After** | `workbench.showBrowse()` → `openEntityPreview` / `openWorkPreview` |
| **예외** | Records/Timeline · incoming/same-day 기록 열기 → Workbench 유지 |
| **위험** | Workbench 편집 중 링크 탭 시 detail 닫힘 (`showBrowse`). 의도된 탐험 전환 |
| **파일** | `home_shell_controller.dart`, `work_detail_workspace.dart`, `entity_detail_workspace.dart` |

### D2 — Work Preview 링크 0건 (P2)

| 항목 | 내용 |
|------|------|
| **경로** | `DashboardPreviewPanel` → `WorkLinkNeighborsSections` 전부 빈 |
| **현재** | 섹션별 메시지만, `onLinkCta` 미배선 |
| **After** | 통합 블록: 인물/사건/개념 연결 CTA → Workbench + Entity Link Picker (타입 필터) |
| **Picker 재사용** | ✅ `showEntityLinkPickerDialog` + `EntityLinkPickerCandidates` (Person/Event/Concept 필터 추가) |
| **위험** | 볼트 미연결 시 picker/저장 실패 — 기존 Sanctum과 동일 제약 |
| **파일** | `dashboard_preview_panel.dart`, `work_preview_empty_connections.dart`, `entity_link_picker_*.dart` |

### D3 — Knowledge Graph 연결 0건 (P3)

| 항목 | 내용 |
|------|------|
| **경로** | `KnowledgeGraphView` — 전 작품 `entityIdsForWork` = 0 |
| **현재** | 행별 subtitle만, 상단 CTA 없음 |
| **After** | 상단 배너: 「첫 연결을 만들어 보세요」+ [기록 열기] [엔티티 연결하기] |
| **기록 열기** | 최근 추가 작품 → Workbench (`openBrowseItem`) |
| **엔티티 연결** | `openAddEntityDialog` (기존 다이얼로그) |
| **위험** | Graph 엔진/데이터 변경 없음. 콜백만 추가 |
| **파일** | `knowledge_graph_view.dart`, `home_shell_body.dart` |

### D4 — Continue Exploring cold start (P4)

| 항목 | 내용 |
|------|------|
| **경로** | `RecentExplorationStore` 빈 + 볼트 작품 있음 |
| **현재** | 빈 안내 + 검색 CTA만 |
| **After** | `vaultItems` 최근 추가 4건 fallback 카드 |
| **위험** | 최근 발견 섹션과 카드 중복 가능 — 카피로 구분 (탐색 이력 vs 최근 추가) |
| **파일** | `home_dashboard_continue_section.dart`, `home_dashboard_view.dart` |

### D5 — Entity Workbench 연결 없음 (P5 — Audit only)

| 항목 | 내용 |
|------|------|
| **현재** | `EntityDetailInfoPanel`: incoming·same-day·그래프 버튼만 |
| **Preview** | `EntityLinkNeighborsSections` full |
| **중복 여부** | 데이터 소스 동일 (`fetchEntityLinkNeighbors`). UI 중복 |
| **최소 요약 가치** | 편집 중 이웃 탐색 시 Preview 닫힘 없이 유지 — **다음 Sprint 후보** |
| **이번 Sprint** | **구현 보류** (R3-C 범위 외 명시) |

---

## 예외 정책 (탐험 vs 편집)

| 맥락 | Work | Entity |
|------|------|--------|
| Sanctum wiki 탭 | Preview | Preview |
| Preview 이웃 탭 | Preview | Preview |
| Workbench 연결 이웃 | Preview (P1) | Preview (P1) |
| Records / Timeline | Workbench | Workbench |
| incoming / same-day 기록 | Workbench | Workbench |
| promote 직후 Entity | Workbench | Workbench (기존) |
| Personal Library 그리드 | Workbench | — |

---

## 수정 전후 흐름 요약

```
Before:  [[인물]] → Workbench (탐험 단절)
After:   [[인물]] → Entity Preview → 기록하기 → Workbench

Before:  Preview 연결 0 → 메시지만
After:   Preview 연결 0 → 인물/사건/개념 CTA → Picker → Sanctum

Before:  Graph 전체 연결 0 → 리스트만
After:   Graph → 배너 CTA → 기록 / 엔티티 추가

Before:  Continue 빈 (볼트 10작품)
After:   Continue → vault fallback 카드
```

---

## 구현 위험 매트릭스

| ID | 위험 | 완화 |
|----|------|------|
| R1 | Wiki 탭 시 편집 중 detail 닫힘 | 탐험 정책과 일치; 저장은 autosave |
| R2 | Picker에 엔티티 없음 | 기존 「아카이브에 추가」 플로우 동일 |
| R3 | Continue/최근 발견 중복 | 섹션 역할 카피 유지 |
| R4 | Graph CTA가 Workbench 직행 | 「기록 열기」= 링크 작성 목적 |

---

## P5 결정 (이번 Sprint)

**Entity Workbench 연결 섹션: 구현하지 않음.**

이유:
1. Preview와 `EntityLinkNeighborsSections` 완전 중복
2. Workbench 좌측 패널 이미 incoming·same-day로 기록 맥락 제공
3. R3-C는 Dead End 제거에 집중; 대칭화는 별도 Sprint

다음 Sprint 후보: Workbench에 **접힌 연결 요약** (1줄 + Preview로 이동) 정도의 경량안.
