# R3-C Dead End Removal — Implementation Report

> **완료:** 2026-06-22  
> **Audit:** [R3C_DEAD_END_REMOVAL_AUDIT.md](./R3C_DEAD_END_REMOVAL_AUDIT.md)  
> **기준:** [R3B_EXPLORATION_AUDIT.md](./R3B_EXPLORATION_AUDIT.md)

---

## 요약

R3-B에서 식별된 탐험 Dead End 5건 중 **P1–P4 구현 완료**, **P5는 Audit 결정에 따라 보류**.

| 항목 | 상태 |
|------|------|
| P1 Wiki → Preview | ✅ |
| P2 Work Preview 빈 연결 CTA | ✅ |
| P3 Graph 빈 연결 CTA | ✅ |
| P4 Continue cold fallback | ✅ |
| P5 Entity Workbench 연결 | ⏸️ 다음 Sprint |

**금지 사항 준수:** Discovery / Graph 엔진 / Pipeline / Link Index / Schema 변경 없음.

---

## P1 — Wiki Link Navigation Policy

### Before
```
Sanctum [[wiki]] / Workbench 연결 이웃
  → handleWikiLinkTap
  → workbenchCoord.openEntity / openBrowseItem
```

### After
```
탐험 맥락 (Sanctum · 연결 이웃)
  → workbench.showBrowse()
  → openEntityPreview / openWorkPreview

기록 맥락 (incoming · same-day)
  → onRecordOpenWork / onRecordOpenEntity
  → Workbench 직행 (예외 유지)
```

### 변경 파일
- `home_shell_controller.dart` — `handleWikiLinkTap` Preview 정책
- `work_detail_workspace.dart` — `onRecordOpenWork` / `onRecordOpenEntity`
- `entity_detail_workspace.dart` — 동일
- `workbench_shell.dart` — 콜백 배선

---

## P2 — Work Preview Empty State

### Before
- 연결 0건: 4개 빈 섹션 메시지만 (`onLinkCta` 없음)

### After
- `!neighbors.hasAnyLink && tags.isEmpty` → `WorkPreviewEmptyConnections`
  - 인물 / 사건 / 개념 연결하기 → Entity Link Picker (타입 필터) → Sanctum 본문에 `[[wiki]]` 삽입
  - 기록 열고 직접 작성하기 → Workbench

### 신규·수정
- `lib/widgets/work_preview_empty_connections.dart` (신규)
- `dashboard_preview_panel.dart`
- `entity_link_picker_dialog.dart` / `entity_link_picker_candidates.dart` — `anchorTypeFilter`
- `openWorkFromPreviewToConnect()` + pending link state

---

## P3 — Knowledge Graph Empty State

### Before
- 전 작품 연결 0: subtitle만, 상단 CTA 없음

### After
- `allLinksEmpty` 시 상단 배너:
  - 「아직 연결된 지식이 없습니다」
  - [기록 열기] → `openMostRecentWorkForRecord()` (Workbench)
  - [엔티티 연결하기] → `openAddEntityDialog`
- 볼트 비음: 엔티티 추가 CTA

### 변경 파일
- `knowledge_graph_view.dart`
- `home_shell_controller.dart` — `openMostRecentWorkForRecord`
- `home_shell_body.dart` — 콜백 배선

---

## P4 — Continue Exploring Cold Start

### Before
- `RecentExplorationStore` 빈 → 섹션 빈 (볼트 작품 있어도)

### After
- 탐색 이력 없을 때 `vaultItems` 최근 추가 4건 fallback
- 카피: 「최근 추가한 작품부터 탐험해 보세요.」

### 변경 파일
- `home_dashboard_continue_section.dart`
- `home_dashboard_view.dart`

---

## P5 — Entity Workbench (보류)

**결정:** 이번 Sprint 미구현.

- Preview와 `EntityLinkNeighborsSections` 중복
- Dead End 제거 목표는 P1–P4로 충족
- 다음 Sprint: 접힌 연결 요약 + Preview 이동 링크 검토

---

## Before / After — 사용자 여정

### Cold start (작품 10 · 링크 0)

| 단계 | Before | After |
|------|--------|-------|
| 홈 계속 탐험 | 빈 | **볼트 최근 4작품 카드** |
| Work Preview | 빈 섹션만 | **인물/사건/개념 CTA** |
| Graph | 리스트만 | **배너 + 기록/엔티티 CTA** |
| Wiki 탭 | Workbench | **Entity Preview** |

### 탐험 체인 (링크 있을 때)

```
Home / Search / Grid
  → Preview
  → 이웃 탭 → 다른 Preview
  → [[wiki]] (Sanctum) → Preview  ← P1
  → 기록하기 → Workbench
```

---

## 테스트

```
✓ home_dashboard_view_test
✓ entity_dashboard_preview_panel_test
✓ work_link_neighbors_sections_test
✓ work_detail_workspace_smoke_test
```

---

## 알려진 제한

1. Work → Entity Preview 전환 시 Work Preview **상호 배타** (R3-B 잔여 — 이번 Sprint 범위 외)
2. Graph CTA 「기록 열기」는 Workbench 직행 (링크 작성 목적 — Audit 예외 정책)
3. Picker에 엔티티 없으면 사용자가 「아카이브에 추가」 필요 (기존 제약)

---

## 성공 기준 검증

| 기준 | 충족 |
|------|------|
| Preview 연결 0 → 종료 아님 | ✅ P2 CTA |
| Graph 연결 0 → 종료 아님 | ✅ P3 배너 |
| Home cold → 빈 화면 아님 | ✅ P4 fallback |
| Wiki 탐험 = Preview | ✅ P1 |
| 주요 화면 최소 1 CTA | ✅ Home·Preview·Graph |
