# R14-A Design System Phase 1 — Implementation Report

> **일자:** 2026-06-22  
> **선행:** [R14A_DESIGN_SYSTEM_AUDIT.md](./R14A_DESIGN_SYSTEM_AUDIT.md)  
> **범위:** Design Token 도입 · Workbench Work/Entity UI 통일 · 중복 UI 제거

**금지 준수:** Discovery Engine · Relationship Discovery · Registry · Search · Link Index · Preview Stack · Save Return 정책 — **변경 없음**.

---

## Summary

R14-A Phase 1을 완료했다. `lib/theme/`에 spacing·radius·typography 토큰을 추가하고, Workbench Work/Entity info panel을 **동일 배경·패딩·타이포·버튼·섹션 헤더** 기준으로 통일했다. Incoming/SameDay Record UI **~330줄 중복**을 공통 위젯으로 추출했다.

---

## 변경 파일

### 신규

| 파일 | 역할 |
|------|------|
| `lib/theme/akasha_spacing.dart` | xs(4)·sm(8)·md(12)·lg(16)·xl(24)·`workbenchPanel` padding |
| `lib/theme/akasha_radius.dart` | sm(6)·md(8)·lg(10)·xl(12) |
| `lib/theme/akasha_typography.dart` | headline·sectionTitle·sectionLabel·body·caption·micro |
| `lib/features/workbench/presentation/widgets/workbench_record_links_sections.dart` | `WorkbenchIncomingLinksSection` · `WorkbenchSameDayRecordsSection` |
| `lib/features/workbench/presentation/widgets/workbench_panel_styles.dart` | 패널 공통 스타일 · `WorkbenchSaveActions` |

### 수정

| 파일 | 변경 |
|------|------|
| `lib/theme/akasha_colors.dart` | workbench surface·semantic text·status 색 추가 |
| `lib/features/workbench/presentation/work_detail_info_panel.dart` | 토큰 배경·패딩 · 중복 섹션 제거 |
| `lib/features/workbench/presentation/work_detail_info_form.dart` | 토큰 전면 적용 · 저장 UI 메타데이터 밖으로 이동 |
| `lib/features/workbench/presentation/entity_detail_info_panel.dart` | Work와 동일 시스템 · 중복 섹션 제거 |
| `lib/features/workbench/presentation/workbench_save_status_hint.dart` | semantic status 색 · caption 토큰 |
| `lib/features/workbench/presentation/work_detail_workspace.dart` | Sanctum `workbenchEditor` 토큰 |
| `lib/features/workbench/presentation/entity_detail_workspace.dart` | 동일 |
| `lib/widgets/collectible_tab_rail.dart` | `AkashaColors.surface` |
| `lib/widgets/workbench_resizable_panel.dart` | `AkashaColors.border` · `textCaption` |

---

## Before / After

### P0 — Design Tokens

| 항목 | Before | After |
|------|--------|-------|
| Spacing scale | 없음 (8·12·16 산재) | `AkashaSpacing` xs~xl |
| Radius scale | 6종 하드코딩 | `AkashaRadius` sm~xl |
| Typography scale | fontSize 인라인 13종 | `AkashaTypography` 6역할 |
| Workbench colors | `#1A1A28` / `#1A1A26` / `#252535` 등 | `AkashaColors.workbenchPanel` 등 |
| Semantic text | `Colors.grey[n]` | `textPrimary` · `textSecondary` · `textMuted` · `textCaption` |
| Link accent | `Colors.tealAccent` | `AkashaColors.linkAccent` (= personAccent) |

### P1 — Workbench 통일

| 항목 | Work Before | Entity Before | After (공통) |
|------|-------------|---------------|--------------|
| Background | `#1A1A28` | `#1A1A26` | `AkashaColors.workbenchPanel` |
| Padding | 8px 계열 | 16~24px | `AkashaSpacing.workbenchPanel` (12·12·12·16) |
| Headline | 16px w900 TextField | 17px w700 Text | 16px w700 (`headline` / `headlineEditable`) |
| Section 「연결」 | 10px grey 인라인 | 동일 | `WorkbenchPanelStyles.connectionsHeader()` |
| Neighbors title | `#6C63FF` 11px 하드코딩 | 동일 | `AkashaTypography.sectionTitle` |
| Graph CTA | 인라인 OutlinedButton | 동일 | `WorkbenchPanelStyles.graphListButton()` |
| Incoming/SameDay | tealAccent · `#252535` | 복제 | `WorkbenchIncomingLinksSection` · `WorkbenchSameDayRecordsSection` |
| Save hint 위치 | 메타데이터 **접힘 안** | 항상 노출 | **항상 노출** (문구 동일) |
| Save button | 10px `#2E2E3E` compact | 18px FilledButton.icon | `WorkbenchSaveActions` — 14px icon · `AkashaColors.accent` |
| Divider | `#2D2D44` height 1 vs 24 | 불일치 | `WorkbenchPanelStyles.panelDivider()` |

### P2 — Token 적용 범위

| 영역 | Before (workbench) | After |
|------|-------------------|-------|
| `AkashaColors` import | **0파일** | **10+파일** |
| `Color(0x` in workbench | ~52 매칭 | **1파일** (`work_detail_info_poster.dart`) |
| `Colors.grey` in workbench | ~40 매칭 | **0** (poster 제외 시 거의 0) |

---

## 제거된 중복

| 제거 대상 | 위치 | 대체 |
|-----------|------|------|
| `_IncomingLinksSection` | `work_detail_info_panel.dart` (~95줄) | `WorkbenchIncomingLinksSection` |
| `_SameDaySection` | `work_detail_info_panel.dart` (~70줄) | `WorkbenchSameDayRecordsSection` |
| `_IncomingLinksSection` | `entity_detail_info_panel.dart` (~95줄) | 동일 |
| `_SameDaySection` | `entity_detail_info_panel.dart` (~70줄) | 동일 |
| `_buildOriginalActionsPanel` | `work_detail_info_form.dart` | `WorkbenchSaveActions` |
| Entity 인라인 저장·서재·삭제 블록 | `entity_detail_info_panel.dart` | `WorkbenchSaveActions` |

**추정 제거:** ~330줄 중복 UI 코드.

---

## 남은 UI Debt

| 항목 | 위치 | 비고 |
|------|------|------|
| `work_detail_info_poster.dart` hex 1건 | Workbench | 포스터 레이아웃 전용 — R14-B |
| Sanctum `sanctum_page_panel.dart` | `tealAccent` · 14px header | Info 패널 typography 미적용 |
| Preview/Graph neighbors 기본 `sectionTitle` | `work_link_neighbors_sections.dart` | 13px white — Workbench만 explicit 전달 |
| Home/Preview 전역 grey·hex | 70+ 파일 | R14-B 이후 token pass |
| Work 포스터 30% vs Entity 180px | 패널 구조 | IA 차이 유지 (기능) |
| 메타데이터 읽기 전용 | Work ExpansionTile | 편집 UI 복원은 별도 Sprint |
| `widget_test.dart` · `work_info_poster_layout_test.dart` | test/ | **기존 실패** (본 Sprint 무관) |

---

## Save Return 정책 확인

- `WorkbenchSaveStatusHint` **문구 100% 유지** (dirty/saved/idle/saving 메시지 동일).
- 변경: **색상** semantic token · Work 패널에서 **노출 위치** 메타데이터 밖으로 이동 (복귀 동작 불변).

---

## 테스트 결과

| Suite | 결과 |
|-------|------|
| `test/workbench_controller_test.dart` | 3/3 PASS |
| `test/entity_journal_incoming_refresh_test.dart` | 1/1 PASS (`work_incoming_refresh` · `entity_incoming_refresh` key 유지) |
| `test/relationship_discovery_service_test.dart` | 6/6 PASS |
| `test/utils/work_link_neighbors_sections_test.dart` | 1/1 PASS |
| **Targeted 합계** | **11/11 PASS** |
| `flutter test` (전체) | 539 PASS · 2 FAIL — `widget_test.dart` · `work_info_poster_layout_test.dart` (**기존 부채**, 본 변경 무관) |

---

## 다음 단계 (R14-B 후보)

1. Preview·Home·Graph `AkashaTypography` / `AkashaSpacing` pass
2. `work_link_neighbors_sections` 기본 `sectionTitleStyle` → 토큰
3. Sanctum header typography 통일
4. `work_detail_info_poster` 토큰화

---

*문서 끝.*
