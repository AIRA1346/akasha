# R14-A Design System & Workbench Consistency Audit

> **일자:** 2026-06-22  
> **유형:** Design Token · Workbench 패널 · Typography 코드 감사 (구현 전)  
> **선행:** [R14_UI_UX_AUDIT.md](./R14_UI_UX_AUDIT.md), [R4_PLANNING_MASTER_PLAN.md](./R4_PLANNING_MASTER_PLAN.md), [R5_DOGFOOD_ROUND2_REPORT.md](./R5_DOGFOOD_ROUND2_REPORT.md)  
> **SSOT:** [PROJECT_CONSTITUTION.md](../active/PROJECT_CONSTITUTION.md)

**방법:** `lib/` 전역 색·간격·타이포·Workbench 패널 코드를 정량 집계 + 파일별 대조. **코드 수정 없음.**

**금지 (본 Sprint):** Discovery Engine · Relationship Discovery · Registry · Search · Link Index · Preview Stack · Save Return 정책.

**다음 단계:** 본 Audit 승인 후 → `R14A_IMPLEMENTATION_PLAN.md` + 코드 구현.

---

## Executive Summary

AKASHA는 `AkashaColors`(19색) + `AkashaTheme.dark()`(M3)가 **정의**돼 있으나, **Workbench 전역은 토큰 0%** — 별도 hex 팔레트 6종을 사용한다. `Colors.grey[n]`은 **70파일·248회**로 `AkashaColors`(**29파일·101회**)보다 광범위하다.

| 영역 | 판정 | 핵심 |
|------|------|------|
| **P0 Design Token** | 🔴 분산 | hex 60+종, radius 6단계, spacing 15+값 — 토큰 파일 2개만 존재 |
| **P1 Workbench 통일** | 🔴 비대칭 | Work·Entity 패널이 배경·패딩·제목·저장 UI·메타 배치 **5축 불일치** |
| **P2 Typography** | 🟡 분산 | fontSize 13단계, 역할별 매핑 없음 — 10~11px가 전체 55% |

**R14-A 구현 목표:** `lib/theme/`에 **spacing·radius·typography 토큰 추가** + **Workbench 공통 패널 스타일** 추출 → Work/Entity 시각적 동일 시스템. Preview·Home·Graph는 **2차**(토큰 import만, 레이아웃 변경 없음).

---

## 0. 조사 범위·방법

### 0.1 정량 집계 (`lib/**/*.dart`)

| 지표 | 파일 수 | 매칭 라인 수 | 비고 |
|------|:-------:|:------------:|------|
| `AkashaColors` | 29 | 101 | Workbench **0파일** |
| `Colors.grey` | 70 | 248 | shade 400~600 혼용 |
| `Color(0xFF…)` 하드코딩 | 37 | 132 | 토큰과 중복 다수 |
| `fontSize: N` (고유값) | — | 13종 | 8~22px |
| `BorderRadius.circular(N)` | — | 6종 | 4·6·8·10·12·30 (+2·14·999 각 1) |
| `SizedBox(height: N)` (상위) | — | 8·12·6·16·4 | 5값이 74% |

### 0.2 Workbench 전용 집계

| 파일 | hex/grey 매칭 |
|------|:-------------:|
| `work_detail_info_form.dart` | 21 |
| `entity_detail_info_panel.dart` | 16 |
| `work_detail_info_panel.dart` | 8 |
| `workbench_save_status_hint.dart` | 4 |
| `work_detail_workspace.dart` | 1 |
| `entity_detail_workspace.dart` | 1 |

**결론:** Workbench가 **가장 토큰화가 뒤처진 Surface** — R14-A 1차 타깃이 타당하다.

### 0.3 선행 문서 정렬

| 문서 | R14-A 관련 시사점 |
|------|-------------------|
| **R14 UI/UX Audit** | P0 토큰 pass · Work/Entity 통일을 R14-A로 확정 |
| **R4 Master Plan** | R4는 진입·네비; Workbench 구조 변경은 P3 deferred — **스타일 통일은 범위 내** |
| **R5 Dogfood R2** | Workbench 탭 레일 3겹·Incoming Record 용어·Autosave 힌트 — **시각 통일과 별도**이나 Entity 패널 가독성 개선 시 시너지 |

---

## P0 — Design Token Audit

### P0.1 현재 토큰 정의 (`akasha_colors.dart`, `akasha_theme.dart`)

#### AkashaColors (색상)

| 토큰 | Hex | 용도 (정의 의도) |
|------|-----|------------------|
| `background` | `#0F111A` | 페이지·scaffold |
| `surface` | `#161824` | 카드·패널 |
| `surfaceElevated` | `#1E1E2E` | CardTheme |
| `sidebar` | `#1E1E2F` | 사이드바 |
| `border` | `#2D2D44` | 구분선 |
| `menuSelected` | `#2A2A3E` | 메뉴 선택 |
| `accent` | `#6C63FF` | Primary CTA |
| `personAccent` … `eventAccent` | 각 4색 | 엔티티 타입 |
| `surfaceCard()` | surface + radius 12 | 카드 데코 헬퍼 |
| `borderSubtle(α)` | white@α | 미세 테두리 |

#### AkashaTheme.dark()

- `main.dart`에서만 `theme:` 적용.
- `FilledButton`·`Chip`·`AppBar`·`ProgressIndicator` 테마 정의.
- **Surface 위젯 대부분이 Theme 위임 없이 인라인 스타일** — chip/button 테마 **유휴**.

#### 기타 스타일 헬퍼

| 파일 | 범위 |
|------|------|
| `home_dashboard_styles.dart` | 홈 섹션 15px·categoryColor |
| `library_theme.dart` | 서재 모드 배경/accent 오버라이드 |

**없는 것:** spacing scale · radius scale · typography scale · semantic text colors · workbench surface tokens.

---

### P0.2 AkashaColors 사용 현황

#### 사용하는 29파일 (요약)

| 클러스터 | 파일 | 사용 패턴 |
|----------|------|-----------|
| **홈** | `home_dashboard_*` (10+) | `background`, `accent`, `surfaceCard`, category accent |
| **Preview** | `dashboard_preview_panel`, `entity_dashboard_preview_panel`, `preview_panel_chrome` | `surface`, `accent` |
| **Graph** | `knowledge_graph_view` | `background`, `surfaceCard`, `accent` — **모범 사례** |
| **Neighbors** | `work_link_neighbors_sections`, `entity_link_neighbors_sections` | `surface`, `accent` (부분) |
| **Shell** | `home_shell_scaffold`, `dashboard_sidebar` | `surface`, `accent`, `accentDark` |
| **Theme** | `akasha_colors`, `akasha_theme` | 정의 |

#### AkashaColors를 **쓰지 않는** 주요 Surface

| 영역 | 대표 파일 | 실제 색 |
|------|-----------|---------|
| **Workbench 전체** | `work_detail_info_*`, `entity_detail_info_*` | `#1A1A28`, `#1A1A26`, `#12121A` … |
| **Tab rail** | `collectible_tab_rail.dart` | `#181824` |
| **Sanctum** | `sanctum_page_panel.dart` | `tealAccent`, `grey[300]` |
| **Browse grids** | `browse_poster_grid` 등 | 대부분 Material default |

---

### P0.3 하드코딩 Hex — 빈도·토큰 매핑

**상위 중복 (AkashaColors와의 관계)**

| Hex | 출현 | AkashaColors 대응 | 실제 사용처 |
|-----|:----:|-------------------|-------------|
| `#252535` | 11 | ❌ 없음 | Workbench Record list tile |
| `#2D2D44` | 9 | ✅ `border` | Divider·리사이저 (하드코딩) |
| `#6C63FF` | 7 | ✅ `accent` | Workbench section title (하드코딩) |
| `#2A2A3E` | 7 | ✅ `menuSelected` | — |
| `#161824` | 6 | ✅ `surface` | empty CTA·quick memo (하드코딩) |
| `#1E1E2E` | 6 | ✅ `surfaceElevated` | — |
| `#00E5FF` | 4 | ✅ `personAccent` | 장르 배지 (하드코딩) |
| `#12121A` | 3 | ❌ 없음 | Sanctum 배경 |
| `#1A1A28` | 1 | ❌ 없음 | **Work info panel** |
| `#1A1A26` | 1 | ❌ 없음 | **Entity info panel** |
| `#181824` | 2 | ≈ `surface` | Tab rail |
| `#2E2E3E` | 1 | ❌ 없음 | Work 저장 버튼 |
| `#141A28` | 2 | ❌ 없음 | Registry bridge·preview banner |

**진단:** 값이 토큰과 **동일해도 식별자를 쓰지 않음**(accent·border·surface). Workbench 전용 4색(`#1A1A28`, `#1A1A26`, `#12121A`, `#252535`)은 **팔레트에 없음**.

#### 권장 신규 토큰 (구현안 — Audit만)

| 제안 토큰 | Hex | 근거 |
|-----------|-----|------|
| `workbenchPanel` | `#1A1A28` | Work·Entity **통일** 배경 (Entity `#1A1A26` 폐기) |
| `workbenchEditor` | `#12121A` | Sanctum |
| `workbenchListTile` | `#252535` | Incoming/SameDay 카드 |
| `workbenchMutedButton` | `#2E2E3E` | secondary save (또는 `surfaceElevated`) |

→ 기존 `surface`/`surfaceElevated`로 흡수 가능한지 **구현 시 육안 대비** 후 결정.

---

### P0.4 Colors.grey 사용

| Shade | 추정 용도 | 문제 |
|-------|-----------|------|
| `grey[600]` | caption·placeholder | semantic 이름 없음 |
| `grey[500]` | section label·icon | Work/Entity 동일 역할, 다른 파일에 산재 |
| `grey[400]` | secondary text·badge | Preview chrome type badge |
| `grey[300]` | Sanctum header | 단독 |
| `Colors.grey` (무 shade) | 비활성 아이콘 | Entity journal 상태 |

**권장 semantic 토큰 (구현안):**

```
textPrimary   → Colors.white
textSecondary → grey[400] 상당
textMuted     → grey[500~600] 상당
textCaption   → 9~10px + textMuted
```

---

### P0.5 Radius Audit

| 값 | 출현 | 제안 역할 |
|----|:----:|-----------|
| **8** | 46 | `radiusMd` — 카드·입력 (default) |
| **6** | 26 | `radiusSm` — 버튼·칩 |
| **4** | 24 | `radiusXs` — 배지 |
| **10** | 19 | `radiusLg` — graph card |
| **12** | 7 | `radiusXl` — surfaceCard (이미 helper에 12) |
| **30** | 2 | bottom nav pill |

**문제:** 동일 「카드」인데 6·8·10·12 혼용. Workbench empty CTA=8, graph card=10, home card=12.

---

### P0.6 Spacing Audit

#### Vertical (`SizedBox(height:)` 상위)

| px | 출현 | 제안 토큰 |
|----|:----:|-----------|
| 4 | 31 | `spaceXs` |
| 6 | 44 | (버튼 gap — `spaceXs`와 통합 검토) |
| 8 | 65 | `spaceSm` |
| 12 | 52 | `spaceMd` |
| 14 | 12 | **Workbench section gap** — `spaceMd`로 흡수 |
| 16 | 35 | `spaceLg` |
| 24 | 2 | `spaceXl` |
| 32 | 5 | `space2xl` (홈 섹션) |

#### Workbench 패딩 불일치 (P1 선행)

| 패널 | 패딩 |
|------|------|
| Work `work_detail_info_panel` | `8, 6, 8, 2` / scroll `8, 2, 8, 8` |
| Entity `entity_detail_info_panel` | **`16, 16, 16, 24`** |

**권장 패널 패딩 (통일안):** `EdgeInsets.fromLTRB(12, 12, 12, 16)` — 8과 16의 중간, 양쪽 스크롤 구조에 맞춤.

---

## P1 — Workbench Work / Entity Info Panel 비교

### P1.1 구조·파일

| | Work | Entity |
|---|------|--------|
| **셸** | `work_detail_info_panel.dart` | `entity_detail_info_panel.dart` |
| **폼** | `work_detail_info_form.dart` | (패널에 인라인) |
| **스크롤** | Column + Expanded + SingleChildScrollView | SingleChildScrollView 전체 |
| **포스터** | maxHeight **30%** of panel | maxHeight **180px** 고정 |

### P1.2 항목별 대조표

| 항목 | Work | Entity | 통일 목표 |
|------|------|--------|-----------|
| **Background** | `#1A1A28` | `#1A1A26` | 단일 `workbenchPanel` |
| **Padding** | 8px 계열 | 16~24px | 12px 통일 |
| **Headline** | 16px **TextField** w900 | 17px **Text** w700 | 16px w700 — 편집 여부는 기능 차이 유지 가능 |
| **Meta line** | creator·year 11px grey[500] | badge 11px + aliases 12px | caption 스타일 통일 |
| **Section label 「연결」** | 10px bold grey[500] ls 0.5 | 동일 | ✅ 이미 일치 |
| **Neighbors subtitle** | 10px grey[600] | 동일 | ✅ |
| **Neighbors `sectionTitleStyle`** | 11px bold `#6C63FF` | 동일 | ✅ — 토큰화만 |
| **Graph CTA button** | height 30, radius 6, 10px | 동일 | ✅ |
| **Notes / Record** | 「노트」섹션 + quick memo | Incoming 바로 after 연결 | IA 차이 — **시각만** 통일 |
| **Incoming header** | 12px w600 `tealAccent` | 동일 (복제) | `personAccent` 또는 semantic `linkAccent` |
| **List tile card** | `#252535` radius 6 | 동일 (복제) | 공통 위젯 추출 |
| **Divider** | `#2D2D44` height 1 | `Divider height 24` | 동일 divider 토큰 |
| **Tags** | 메타데이터 안 읽기 전용 | `EditableTagChips` 노출 | 배치만 — 기능 유지 |
| **Save hint** | 메타데이터 **접힘 안** | **항상 노출** | **항상 노출** (Entity 따름) |
| **Save button** | 10px compact Row, bg `#2E2E3E` | 18px `FilledButton.icon` accent default | 단일 `WorkbenchPrimarySaveButton` |
| **서재 버튼** | icon 14, 10px text | icon 16, 11px text | compact 통일 |
| **삭제** | 메타데이터 안 | 하단 Outlined 18px icon | 스타일 통일 |
| **볼트 미연동** | amber banner (Work만) | 없음 | Work 유지 |

### P1.3 중복 코드 (통합 후보)

| 위젯 | Work 위치 | Entity 위치 | 라인 수 |
|------|-----------|-------------|---------|
| `_IncomingLinksSection` | `work_detail_info_panel.dart` | `entity_detail_info_panel.dart` | ~95 each |
| `_SameDaySection` | 동일 | 동일 | ~70 each |

→ `lib/features/workbench/presentation/widgets/workbench_record_links_sections.dart` (신규) 추출 권장.

### P1.4 Sanctum·Shell (참고 — P1 범위 경계)

| 영역 | 색 | 비고 |
|------|-----|------|
| Sanctum bg | `#12121A` | Work·Entity 공통 |
| Tab rail | `#181824` | `collectible_tab_rail.dart` |
| 리사이저 | `#2D2D44` | `workbench_resizable_panel.dart` — `border` 토큰화 |

Sanctum 헤더 `tealAccent` / 14px — Info 패널과 **타이포 불일치**. R14-A에서 `sectionTitle` 토큰 적용 가능.

### P1.5 Save Status (`workbench_save_status_hint.dart`)

| 상태 | 색 | 크기 |
|------|-----|------|
| saving | grey[400] | 10px |
| dirty | amber[200] | 10px |
| saved | greenAccent[200] | 10px |
| idle | grey[500] | 10px |

**정책:** Save Return 문구 **변경 금지** — 색만 semantic token으로 교체.

**배치 이슈:** Work는 접힌 메타데이터 안 → **발견성 낮음** (R14·R5 공통 지적). R14-A에서 Entity처럼 **접힘 밖으로 이동** (동작·문구 동일).

### P1.6 Metadata Section (Work만)

- `ExpansionTile` 기본 접힘 — 평점·상태 **읽기 전용** 테이블.
- R14-A 범위: **스타일 통일**만. 편집 UI 복원은 별도 Sprint.

---

## P2 — Typography Audit

### P2.1 fontSize 분포 (전체 `lib/`)

| px | 출현 | 비율(대략) | 현재 역할 (관찰) |
|----|:----:|:----------:|------------------|
| **11** | 117 | 28% | meta·subtitle·섹션 보조 |
| **10** | 89 | 21% | section label·caption·버튼 |
| **12** | 73 | 17% | body·list title |
| **13** | 30 | 7% | neighbors default section |
| **9** | 23 | 6% | preview chrome·badge |
| **14** | 16 | 4% | Sanctum header·panel title |
| **15** | 4 | 1% | home section |
| **16** | 3 | 1% | work title |
| **17** | 2 | <1% | entity title |
| **20** | 4 | 1% | graph header |
| **22** | 2 | <1% | home hero |
| **8** | 4 | 1% | micro badge |

**문제:** 역할 이름 없이 px만 존재. 9·10·11이 **caption 계층 3단**으로 난립.

### P2.2 제안 Typography Scale (R14-A 구현 SSOT)

| 토큰 | size | weight | color | 용도 |
|------|:----:|:------:|-------|------|
| `headline` | 16 | w700 | textPrimary | 패널 제목 (Work·Entity) |
| `headlineEditable` | 16 | w700 | textPrimary | Work TextField (동일 메트릭) |
| `sectionTitle` | 11 | bold | accent | neighbors 서브섹션 (보라) |
| `sectionLabel` | 10 | bold, ls 0.5 | textMuted | 「연결」「노트」「태그」 |
| `body` | 12 | w400~600 | textPrimary | list title·본문 |
| `bodySecondary` | 11 | w400 | textSecondary | meta line·creator |
| `caption` | 10 | w400 | textMuted | 힌트·empty CTA |
| `micro` | 9 | bold | textSecondary | preview badge |

**홈·Graph·Preview는 R14-A 2차** — Workbench + neighbors 기본값만 먼저 적용.

### P2.3 fontWeight 이슈

| 위치 | 값 | 권장 |
|------|-----|------|
| Work title | **w900** | w700 (`headline`과 통일) |
| Entity title | w700 | 유지 |
| Section titles | bold | 유지 |

### P2.4 TextTheme 미사용

`AkashaTheme`에 `textTheme` 오버라이드 **없음**. 구현 시:

```dart
// 제안 (구현 단계) — akasha_typography.dart 또는 Theme extension
static const headline = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, ...);
```

위젯은 `AkashaTypography.headline` 또는 `Theme.of(context).extension<AkashaStyles>()!` — **기존 인라인 일괄 치환**.

---

## P3 — 통합 진단

### P3.1 「한 제품」감을 깎는 Top 5

1. **Workbench 0% AkashaColors** — 별도 팔레트 섬
2. **Work `#1A1A28` vs Entity `#1A1A26`** — 2px도 안 되는 차이로 「다른 패널」인상
3. **저장 UI 크기** — Work 10px compact vs Entity 18px icon
4. **13px white vs 11px accent** — neighbors 동일 위젯, surface마다 다른 기본값
5. **tealAccent vs personAccent** — 링크 색이 토큰 체계 밖

### P3.2 R5 Dogfood 연계 (변경 없이 개선 가능한 것)

| R5 지적 | R14-A 대응 |
|---------|------------|
| Incoming Record 용어 | **카피 변경 없음** (금지 아님이나 범위 외) — 시각 통일만 |
| Autosave 힌트 읽기 어려움 | Save hint **노출 위치** 상향 (문구 동일) |
| Entity·Work 패널 이질감 | P1 통일 |

---

## 구현 계획 (Audit 후 — 코드 착수용)

> 아래는 **다음 PR/Sprint** 체크리스트. 본 문서에서는 **구현하지 않음**.

### Phase 1 — Token 파일 (`lib/theme/`)

| # | 작업 | 파일 |
|---|------|------|
| 1 | `akasha_spacing.dart` — spaceXs~2xl | 신규 |
| 2 | `akasha_radius.dart` — radiusXs~Xl | 신규 |
| 3 | `akasha_typography.dart` — P2.2 scale | 신규 |
| 4 | `akasha_colors.dart` — workbenchPanel 등 추가·semantic text | 확장 |
| 5 | `akasha_theme.dart` — TextTheme·extension hookup | 확장 |

### Phase 2 — Workbench 통일

| # | 작업 | 파일 |
|---|------|------|
| 6 | `WorkbenchRecordLinksSections` 추출 | 신규 widget |
| 7 | `WorkbenchPanelChrome` 또는 shared padding/decoration | 신규 |
| 8 | `work_detail_info_panel` — bg·padding·save 위치 | 수정 |
| 9 | `entity_detail_info_panel` — bg·padding·save 스타일 | 수정 |
| 10 | `work_detail_info_form` — title w700·토큰 치환 | 수정 |
| 11 | `workbench_save_status_hint` — semantic colors | 수정 |
| 12 | `collectible_tab_rail` — surface 토큰 | 수정 |

### Phase 3 — Neighbors 기본값 (Preview Stack 무변경)

| # | 작업 | 파일 |
|---|------|------|
| 13 | `WorkLinkNeighborsSections` `_defaultSectionTitle` → `AkashaTypography.sectionTitle` | 수정 |
| 14 | `EntityLinkNeighborsSections` 동일 | 수정 |

### Phase 4 — 검증

| # | 작업 |
|---|------|
| 15 | `flutter test` 회귀 |
| 16 | Work·Entity 패널 스크린샷 육안 대조 (side-by-side) |
| 17 | `R14A_IMPLEMENTATION_REPORT.md` |

### 범위 외 (R14-B 이후)

- Preview 320px 밀도·fold
- Home IA·카피
- Responsive Shell
- 메타데이터 편집 UI 복원
- Incoming Record **용어** 변경

---

## 금지 사항 준수

| 금지 | 본 Audit·계획 |
|------|---------------|
| Discovery Engine | ✅ 미접촉 |
| Relationship Discovery | ✅ 미접촉 |
| Registry | ✅ 미접촉 |
| Search | ✅ 미접촉 |
| Link Index | ✅ 미접촉 |
| Preview Stack | ✅ push/replace 로직 무변경 |
| Save Return | ✅ 힌트 **문구·정책** 유지, 위치·색만 |

---

## 성공 기준 (R14-A 구현 완료 시)

1. Work·Entity info panel **동일 background·padding·section label·save row** 육안 확인
2. Workbench 파일 **AkashaColors/AkashaTypography import > 0**
3. `_IncomingLinksSection` **단일 구현**
4. 하드코딩 `#6C63FF`·`#2D2D44`·`#161824` in workbench → **0건** (토큰 참조)
5. `flutter test` PASS

---

## 결론

R14-A는 **새 기능이 아닌 표현 계층 정리**다. 가장 큰 기술 부채는 **Workbench의 토큰 미사용**과 **Work/Entity 패널 5축 비대칭**이다. P0 토큰 파일 3종 + P1 패널 통일만으로도 R14 UI/UX Audit의 「한 제품감 6→8」 체감이 가능하다.

**다음 액션:** 본 Audit 검토 → `R14A_IMPLEMENTATION_PLAN.md` 확정 → Phase 1부터 코드 착수.

---

*문서 끝.*
