# R4-C Implementation Report — UX Friction Removal

> **일자:** 2026-06-22  
> **Sprint:** R4-C (P0–P3)  
> **Planning:** [R4_PLANNING_MASTER_PLAN.md](./R4_PLANNING_MASTER_PLAN.md)  
> **선행:** [R4A_IMPLEMENTATION_REPORT.md](./R4A_IMPLEMENTATION_REPORT.md), [R4B_IMPLEMENTATION_REPORT.md](./R4B_IMPLEMENTATION_REPORT.md)  
> **Dogfood:** [R3H_DOGFOOD_VALIDATION.md](./R3H_DOGFOOD_VALIDATION.md)

---

## Summary

R4-C는 실사용 중 남아 있던 **Preview · Graph 카피 · Autosave · Workbench** 마찰을 제거했다. Preview Stack 구조·Save Return 정책·Graph Engine·Discovery/Link Index/Search/Registry/Schema — **미변경**.

---

## 변경 파일

| 파일 | 우선순위 | 내용 |
|------|:--------:|------|
| `lib/screens/home/views/preview_panel_chrome.dart` | P0 | **신규** — 고정 헤더: 「지금 보는 항목」+ 제목 + `이전` + `기록하기` |
| `lib/screens/home/views/dashboard_preview_panel.dart` | P0 | `PreviewPanelChrome` 통합; 본문 중복 CTA·헤더 제거 |
| `lib/screens/home/views/entity_dashboard_preview_panel.dart` | P0 | Work Preview와 동일 Chrome; `entityId` 노출 제거 |
| `lib/screens/home/views/knowledge_graph_view.dart` | P1 | 제목 「연결 목록」; 부제에 리스트형 명시 |
| `lib/widgets/dashboard_sidebar.dart` | P1 | 「지식 연결 맵」→「연결 목록」 |
| `lib/features/workbench/presentation/workbench_save_status_hint.dart` | P2 | **신규** — Autosave vs 명시 저장 안내 위젯 |
| `lib/widgets/sanctum_page_panel.dart` | P2 | 「Sanctum 페이지」→「기록 본문」; 저장 상태 힌트 |
| `lib/features/workbench/presentation/work_detail_info_form.dart` | P2·P3 | 저장 힌트; 연결 섹션 라벨·안내; Graph/본문 카피 |
| `lib/features/workbench/presentation/work_detail_info_panel.dart` | P2 | `isDirty` / `lastSavedAt` 전달 |
| `lib/features/workbench/presentation/work_detail_workspace.dart` | P2 | Info 패널에 dirty·savedAt 배선 |
| `lib/features/workbench/presentation/entity_detail_info_panel.dart` | P2·P3 | `catalog only`→사용자어; `entityId` 숨김; 연결·저장 힌트 |
| `lib/features/workbench/presentation/entity_detail_workspace.dart` | P2 | Entity Info 패널 dirty·savedAt 배선 |
| `test/views/entity_dashboard_preview_panel_test.dart` | — | Chrome CTA 기대값 갱신 |

---

## 제거된 UX 마찰

### P0 — Preview Panel UX

| 마찰 | 조치 |
|------|------|
| Preview Stack 탐색 중 **현재 위치 불명확** | 헤더 「지금 보는 항목」+ 타입 배지 + 제목 |
| Work / Entity Preview **헤더·CTA 불일치** | 공통 `PreviewPanelChrome` |
| `기록하기 >` vs `기록하기` 혼재 | 단일 FilledButton 「기록하기」 |
| Entity Preview **entityId 노출** | 제거 (타입 배지만) |
| `← 이전` / `기록하기` 발견성 | 헤더 하단 고정 행 (back 가능 시 `이전` + `기록하기`) |

### P1 — Graph 진입 기대치

| 마찰 | 조치 |
|------|------|
| 「지식 연결 맵」「그래프」→ 노드 UI 기대 | 「**연결 목록**」 + 부제 「노드 그래프가 아닙니다」 |
| Preview/Workbench 「연결 맵에서 보기」 | 「**연결 목록에서 보기**」 + `list_alt` 아이콘 |
| Sidebar 라벨 불일치 | Sidebar · Graph 뷰 · CTA **용어 통일** |

### P2 — Autosave UX (정책 유지)

| 마찰 | 조치 |
|------|------|
| Autosave 후 Workbench 유지 vs 명시 저장 후 Preview 복귀 **혼란** | `WorkbenchSaveStatusHint` — dirty / saving / saved / idle 4상태 |
| 「Sanctum」 내부 용어 | 「**기록 본문**」 |
| 저장 버튼만으로는 autosave 차이 파악 어려움 | Info 패널·Sanctum 헤더 **양쪽** 힌트 |

**정책 변경 없음:** 명시 `md 저장` / `journal 생성` → Preview 복귀; Autosave → Workbench 유지 (R3-G).

### P3 — Workbench 정보 밀도

| 마찰 | 조치 |
|------|------|
| 연결 영역 **발견성** | 「연결」 라벨 + 「기록 본문의 [[링크]]로 연결됩니다」 |
| Entity `catalog only` | 「기록 없음 (카탈로그만)」 / 「기록 있음」 |
| Entity `entityId` 1차 노출 | 타입 배지로 대체 |

**레이아웃:** 4열 구조 **유지** (재설계 없음).

---

## Before / After

### Preview 헤더

| Before | After |
|--------|-------|
| Work: 본문에 제목·포스터·CTA 혼재 | 고정 Chrome: 배지 · 「지금 보는 항목」 · 제목 · `이전` · `기록하기` |
| Entity: `entityId` + `기록하기 >` | EntityId 제거; Work와 동일 Chrome |
| Stack depth 인지 불가 | `canGoBack` 시 **이전** 버튼 항상 헤더 동일 위치 |

### Graph / 연결 탐색

| Before | After |
|--------|-------|
| Sidebar 「지식 연결 맵」 | 「연결 목록」 |
| Graph 제목 「지식 연결 맵」 | 「연결 목록」 + 리스트형 부제 |
| CTA 「연결 맵에서 보기」 | 「연결 목록에서 보기」 |

### Workbench 저장

| Before | After |
|--------|-------|
| Sanctum 「Sanctum 페이지」 | 「기록 본문」 |
| 저장 상태 묵시적 | 「변경됨 · 자동 저장은 편집 화면 유지 · 탐험 복귀는 md 저장」 등 |
| Entity 「catalog only」 | 「기록 없음 (카탈로그만)」 |

---

## Do Not Touch 준수

| 영역 | 상태 |
|------|------|
| Preview Stack 구조 (`previewLinked*`, `popPreview`) | ✅ 미변경 |
| Save Return (`_previewReturnSnapshot`, `_maybeReturnToPreviewAfterSave`) | ✅ 미변경 |
| Discovery · Link Index · Pipeline · Search · Registry | ✅ 미변경 |
| Graph Engine (`KnowledgeGraphView` 로직·정렬) | ✅ 미변경 (카피만) |
| Data Schema | ✅ 미변경 |

---

## 테스트 결과

| 테스트 | 결과 |
|--------|:----:|
| `test/views/entity_dashboard_preview_panel_test.dart` | PASS |
| `test/views/home_dashboard_view_test.dart` | PASS |
| `test/work_detail_workspace_smoke_test.dart` | PASS |
| `test/coordinators/home_browse_library_preview_test.dart` | PASS |

**합계: 5/5 PASS** (`flutter test` 2026-06-22)

---

## 남은 UX Debt

| 항목 | 비고 |
|------|------|
| Preview Stack **depth 표시** (예: 2/3) | Chrome에 breadcrumb 미구현 — `이전`만으로 depth 암시 |
| Graph **시각화 기대** | 리스트형 유지; 노드 그래프는 R4 scope 밖 |
| Workbench **4열 첫 방문 가이드** | 연결 라벨·힌트 추가했으나 onboarding tour 없음 |
| Autosave 힌트 **중복** (Info + Sanctum) | 의도적 — 어느 열에서든 정책 인지 |
| Entity Incoming Links **Record 용어** | P3 범위 밖 (Link Index/Record schema touch 금지) |
| Preview **닫기 vs 이전** 차이 | tooltip만; first-run 설명 없음 |

---

## Dogfood 재검증 체크리스트 (수동)

1. Home → 작품 Preview → 이웃 클릭 → **이전**으로 복귀 · 헤더 「지금 보는 항목」 확인  
2. Entity Preview — **entityId 미노출** · `기록하기` → Workbench · 명시 저장 → Preview 복귀  
3. Sidebar → **연결 목록** — 리스트 UI · 부제 확인  
4. Workbench 본문 편집 → Autosave 후 **Workbench 유지** + 힌트 문구  
5. Workbench **md 저장** → Preview 복귀 + 힌트 idle 문구  
