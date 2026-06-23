# R4-B Implementation Report — Navigation IA (P1)

> **일자:** 2026-06-22  
> **Sprint:** R4-B (P1)  
> **Planning:** [R4_P1_NAVIGATION_PLAN.md](./R4_P1_NAVIGATION_PLAN.md)  
> **선행:** [R4A_IMPLEMENTATION_REPORT.md](./R4A_IMPLEMENTATION_REPORT.md)

---

## Summary

R4-B는 **Sidebar 보조 역할 축소**, **Library → Preview 정책 통일**, **Cold Start Sidebar 기본 collapsed**, **탐험 경로 Preview 우선**을 구현했다.

Preview Stack · Save Return · Discovery · Link Index · Search Engine · Registry — **미변경**.

---

## 변경 파일

| 파일 | R4-B | 내용 |
|------|:----:|------|
| `lib/widgets/dashboard_sidebar.dart` | B1 | 홈·탐색·라이브러리·컬렉션 **메뉴 타일 제거**; 도구(연결 맵·타임라인)만; **최근 탐색 섹션 제거** |
| `lib/screens/home/coordinators/home_browse_coordinator.dart` | B2 | Library/Catalog **동일** `onPreviewWork ?? openBrowseItem` |
| `lib/screens/home/home_shell_body.dart` | B3 | TodayRecall → `onPreviewWork` (탐험 경로) |
| `lib/screens/home/home_sidebar_preferences.dart` | B4 | `defaultOpen: false` (신규 설치) |
| `lib/screens/home/coordinators/home_navigation_coordinator.dart` | B4 | 초기 `isSidebarOpen = false` |
| `test/coordinators/home_browse_library_preview_test.dart` | — | Library preview open policy 테스트 |

---

## Navigation Before / After

### Bottom Navigation (변경 없음 — Primary)

| 탭 | 역할 |
|----|------|
| 홈 | Hero + 4섹션 탐험 허브 |
| 탐색 | 카탈로그 그리드 → Preview |
| 검색 | modal → Preview |
| 라이브러리 | **그리드 → Preview** (B2) |
| 컬렉션 | Entity browse → Preview (기존) |

### Sidebar

| Before | After |
|--------|-------|
| 홈 · 탐색 · 라이브러리 · 컬렉션 · 그래프 · 타임라인 | **도구:** 지식 연결 맵 · 타임라인 |
| 최근 탐색 4건 (홈 continue와 중복) | **제거** |
| 나의 서재 / 컬렉션 **목록** (전환) | **유지** (Bottom active + Sidebar switcher) |
| default **open** 260px | default **closed** (pref 없을 때) |

### Preview 진입 (탐험 경로)

| 진입 | Before | After |
|------|--------|-------|
| Home 카드 | `navigate*Preview` | 동일 |
| Search | `open*Preview` | 동일 |
| Explore 그리드 | `openWorkPreview` | 동일 |
| Graph | `navigate*Preview` | 동일 |
| **Library 그리드** | `openBrowseItem` (Workbench) | **`openWorkPreview`** |
| Entity gallery (탐색) | `openEntityPreview` | 동일 |
| TodayRecall | `openBrowseItem` | **`openWorkPreview`** |
| Sidebar recent | `openRecentExploreItem` | 섹션 제거 (홈 continue 유일) |

---

## 예외 정책 (Workbench 직행 유지)

| 경로 | 이유 | API |
|------|------|-----|
| **Preview 「기록하기 >」** | 명시적 기록 의도 | `open*FromPreview` + Save Return |
| **Timeline / Records 뷰** | 기록 축 — 편집 맥락 | `onOpenBrowseItem` / `onOpenEntity` |
| **Workbench incoming / same-day** | Record 맥락에서 Work/Entity 열기 | `onRecordOpenWork` / `onRecordOpenEntity` |
| **Graph 「기록 열기」** | 최근 작품 **편집** CTA | `openMostRecentWorkForRecord` → `openBrowseItem` |
| **Search Entity promote** | catalog-only → 아카이브 플로우 | `openEntity` (Workbench) |
| **Wiki link (Sanctum 편집 중)** | 편집 맥락 Preview replace | `open*Preview` (stack clear — R3 정책) |

**원칙:** 탐색·발견 목적 → **Preview first**. 기록·편집·Record 맥락 → **Workbench 직행 허용**.

---

## UX 영향

| 영역 | 영향 |
|------|------|
| **탐험 루프** | Library가 Home/Explore와 동일: Preview → 기록하기 → Workbench → 저장 → Preview |
| **First 30s (R4-A)** | Sidebar noise ↓ — Hero·CTA 시선 유지 |
| **Cold Start** | Sidebar collapsed — 중앙 Hero+Browse focus |
| **Mental model** | Bottom = **어디**; Sidebar = **도구 + 서재/컬렉션 전환** |
| **회귀** | R3-F push / R3-G Save Return — **미변경** |

---

## 테스트 결과

```
flutter test test/views/home_dashboard_view_test.dart                    → PASS
flutter test test/views/entity_dashboard_preview_panel_test.dart         → PASS
flutter test test/work_detail_workspace_smoke_test.dart                  → PASS
flutter test test/coordinators/home_browse_library_preview_test.dart     → 2/2 PASS
```

**합계: 5/5 PASS**

회귀 확인:

| 항목 | 결과 |
|------|------|
| Home Hero + 4섹션 | ✅ |
| Entity Preview CTA | ✅ |
| Workbench smoke | ✅ |
| Library preview policy | ✅ |

---

## Do Not Touch 확인

- [x] Discovery / Pipeline / Link Index / Search Engine
- [x] Registry / Collection semantics / Data schema
- [x] Preview Stack (`previewLinked*`, `navigate*Preview`, `popPreview`)
- [x] Save Return (`_previewReturnSnapshot`, `_maybeReturnToPreviewAfterSave`)

---

## 남은 R4 범위 (P2/P3 — Deferred)

| 항목 | Phase |
|------|-------|
| Preview 연결 섹션 fold 상향 | P2 |
| Graph 하단 탭 / expand friction | P2 |
| Home → Graph 텍스트 링크 (N8) | P2 |
| Autosave vs 저장 복귀 UX 카피 | P2/P3 |
| Workbench TabRail 정리 | P3 |
| Sanctum 패널 UI 라벨 | P3 |
| entityId UI 접기 | P3 |

---

## 수동 검증 권장

1. Bottom만으로 홈 ↔ 탐색 ↔ 라이브러리 전환 (Sidebar 닫힌 상태)  
2. 라이브러리 포스터 탭 → **Preview** (Workbench 아님) → 기록하기 → 저장 → Preview 복귀  
3. Tab → Sidebar → 지식 연결 맵 · 타임라인 · 서재 **목록 전환**  
4. Timeline에서 작품 탭 → Workbench 직행 (예외)  

---

## 관련 문서

- [R4_PLANNING_MASTER_PLAN.md](./R4_PLANNING_MASTER_PLAN.md)
- [R4A_IMPLEMENTATION_REPORT.md](./R4A_IMPLEMENTATION_REPORT.md)
