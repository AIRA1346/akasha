# R4-A Implementation Report — First 30 Seconds (P0)

> **일자:** 2026-06-22  
> **Sprint:** R4-A (P0)  
> **Planning:** [R4_P0_FIRST_30_SECONDS_PLAN.md](./R4_P0_FIRST_30_SECONDS_PLAN.md)

---

## Summary

R4-A는 홈 **Hero narrative + 단일 Primary CTA**, Cold Start **중복 CTA 제거**, **Vault 배너 축소**, **용어 정리**, **Ctrl+K 검색 연결**을 구현했다.

Discovery / Link Index / Search Engine / Registry / Schema — **변경 없음**.

---

## 변경 파일

| 파일 | R4-A | 내용 |
|------|:----:|------|
| `lib/screens/home/views/home_dashboard/home_dashboard_hero.dart` | A1 | **신규** — Hero 제목·설명·「탐험 시작하기」 |
| `lib/screens/home/views/home_dashboard/home_dashboard_view.dart` | A1/A2 | Hero 최상단 배치, `isColdStart` 전달 |
| `lib/screens/home/views/home_dashboard/home_dashboard_continue_section.dart` | A2 | Cold CTA 제거, `_AddExploreCard` 삭제 |
| `lib/screens/home/home_vault_banner.dart` | A3 | 1줄 compact, Sanctum 제거 |
| `lib/screens/home/home_shell_scaffold.dart` | A5 | Ctrl+K → `openSearchDialog` |
| `lib/screens/home/views/home_dashboard/home_dashboard_todays_links_section.dart` | A4 | `[[wiki]]` 제거 |
| `lib/screens/home/views/home_dashboard/home_dashboard_recent_discovery_section.dart` | A4 | 검색 CTA성 카피 완화 |
| `lib/screens/home/views/home_dashboard/home_dashboard_recent_records_section.dart` | A4 | Sanctum 제거 |
| `lib/widgets/work_preview_empty_connections.dart` | A4 | `[[링크]]` → 링크 |
| `lib/widgets/work_link_neighbors_sections.dart` | A4 | `[[링크]]` → 링크 |
| `lib/screens/home/views/knowledge_graph_view.dart` | A4 | 위키 링크 카피만 (엔진 무변) |
| `test/views/home_dashboard_view_test.dart` | — | Hero·CTA·cold start 검증 |

---

## Before / After

### R4-A1 — Home Hero

| Before | After |
|--------|-------|
| TopBar(검색 placeholder) → 4섹션 | **Hero**(제목+설명+CTA) → TopBar → 4섹션 |
| 「무엇을 하는 앱」 설명 없음 | 「기록하고, 연결하고, 발견하세요」 + 1줄 설명 |
| Primary CTA 없음 | **[탐험 시작하기]** → `openSearchDialog()` |

### R4-A2 — Cold Start

| Before | After |
|--------|-------|
| continue 빈 상태: [검색으로 탐험 시작] TextButton | 안내 문장만 — **버튼 없음** |
| horizontal list: `_AddExploreCard`(검색으로 더 보기) | cold/empty 시 list 숨김; vault fallback 시 카드만 |
| CTA 4곳+ (배너·섹션·탭·TopBar) | **Hero FilledButton 1개** only (viewport) |

### R4-A3 — Vault 배너

| Before | After |
|--------|-------|
| padding 10+ · amber 15% · 긴 Sanctum Vault 문구 · [폴더 연동] 버튼 | padding 6 · amber 6% · **1줄 10px** · tap→연동 (버튼 제거) |

### R4-A4 — 용어

| 위치 | Before | After |
|------|--------|-------|
| 오늘의 연결 (empty) | `[[wiki]] 링크로…` | 기록에서 연결한… |
| 최근 기록 (empty) | Sanctum에 감상… | 감상을 기록하면… |
| 최근 발견 (empty) | 검색으로 작품을 찾아… | 탐험을 시작하면… |
| Preview empty | `[[링크]]` | 링크 |
| Graph subtitle/banner | `[[위키 링크]]` | 링크 |

### R4-A5 — Ctrl+K

| Before | After |
|--------|-------|
| Tab → sidebar only; Ctrl+K 표시만 | **Ctrl+K** → `openSearchDialog()` |

---

## UX 영향

| 영역 | 영향 |
|------|------|
| **First 30 Seconds** | Hero가 스크롤 전 viewport에 narrative + CTA — Q1 개선 기대 |
| **Cold Start** | 탐험 이력 없을 때 Hero CTA 단일 강조 — Scenario A friction ↓ |
| **탐험 루프 진입** | Hero/TopBar/하단검색/Ctrl+K → Search → Preview (기존 R3) |
| **Vault 미연동** | 배너 visual weight ↓ — Hero 우선 |
| **회귀** | R3-F/G Preview Stack·Save Return — **미변경** |

---

## 테스트 결과

```
flutter test test/views/home_dashboard_view_test.dart          → 1/1 PASS
flutter test test/views/entity_dashboard_preview_panel_test.dart → 1/1 PASS
flutter test test/work_detail_workspace_smoke_test.dart        → 1/1 PASS
```

**`home_dashboard_view_test` 검증:**

- Hero 제목·설명·「탐험 시작하기」 표시
- 「검색으로 탐험 시작」「검색으로 더 보기」**미표시**
- CTA 탭 → `onSearch` 호출
- 4 exploration 섹션 유지

---

## 남은 R4-B 범위 (P1 — Navigation IA)

| 항목 | 상태 |
|------|------|
| Bottom Nav vs Sidebar 역할 분담 | 미착수 |
| Sidebar 홈/탐색 중복 제거 | 미착수 |
| Cold start Sidebar default closed | 미착수 |
| **라이브러리 그리드 → Preview** (`HomeBrowseCoordinator`) | 미착수 |
| Graph 하단 진입 | Deferred (P2) |
| Preview fold 재배치 | Deferred (P2) |
| Workbench Sanctum 패널 UI 라벨 | 미착수 (P3) |

---

## Do Not Touch 확인

- [x] Discovery / Pipeline / Link Index / Search Engine — **미변경**
- [x] Registry / Collection semantics / Data schema — **미변경**
- [x] Graph **엔진** — **미변경** (카피 문자열만)
- [x] R3-F `navigate*Preview` / R3-G `_maybeReturnToPreviewAfterSave` — **미변경**

---

## 수동 검증 권장

1. 앱 cold start → Hero + CTA 1개 확인  
2. 「탐험 시작하기」→ Search → Preview  
3. Ctrl+K → Search dialog  
4. 볼트 미연동 → compact 배너, Hero가 더 눈에 띔  

---

## 관련 문서

- [R4_PLANNING_MASTER_PLAN.md](./R4_PLANNING_MASTER_PLAN.md)
- [R4_P1_NAVIGATION_PLAN.md](./R4_P1_NAVIGATION_PLAN.md)
