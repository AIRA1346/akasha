# Entity Preview Layer — P4 설계

> **갱신:** 2026-06-22  
> **SSOT:** [UX_RECOVERY_MASTER_PLAN.md](./UX_RECOVERY_MASTER_PLAN.md)

---

## 문제

| 축 | Work | Entity |
|----|------|--------|
| 검색 | Preview → Workbench | **Workbench 직행** |
| 홈 탭 | Preview | **Workbench 직행** |
| 탐색 그리드 | Preview | **Workbench 직행** |

사용자는 Entity를 「편집기」로만 경험하고 「탐험 노드」로 경험하지 못함.

---

## 목표 흐름

```
Search / Home / Grid / Graph / Collection
        ↓
 EntityDashboardPreviewPanel (320px)
   · 기본 정보 (타입, 제목, 별칭, 태그)
   · 연결된 작품
   · 연결된 인물 / 사건 / 개념 (journal outgoing [[wiki]])
   · incoming 링크 수
   · [기록하기 >] → Entity Workbench
        ↓
 EntityDetailWorkspace (Sanctum journal)
```

---

## 데이터 (구조 변경 없음)

| 표시 | 소스 |
|------|------|
| 연결된 작품 | `EntityRelatedWorksDiscovery.discover()` |
| 연결 엔티티 | journal `outgoingLinks` + `userCatalog` |
| incoming 수 | `discovery.cachedIncomingRecordCount()` |
| 관련 개념 | entity.tags + concept 타입 링크 |

신규 유틸: `fetchEntityLinkNeighbors()` — `work_link_neighbors.dart`와 대칭, link_index·discovery만 사용.

---

## 구현 범위

| 파일 | 역할 |
|------|------|
| `lib/utils/entity_link_neighbors.dart` | 이웃 조회 |
| `lib/widgets/entity_link_neighbors_sections.dart` | UI 섹션 + 빈 CTA |
| `lib/screens/home/views/entity_dashboard_preview_panel.dart` | 프리뷰 패널 |
| `home_shell_controller.dart` | `entityPreviewItem`, `openEntityPreview`, `openEntityFromPreview` |
| `home_shell_body.dart` | Work/Entity 프리뷰 분기 |
| 탐험 진입점 | `onOpenEntity` → `openEntityPreview` (Records·promote 제외) |

---

## Workbench 유지

- Sanctum journal 편집
- md 저장/삭제
- Entity link picker
- Records·타임라인에서 열기 (기록 맥락)

---

## 성공 기준

Entity를 검색·홈·그리드에서 열었을 때 **Workbench 없이** 연결 구조를 먼저 본다.

**상태:** ✅ 구현 완료 (2026-06-22)
