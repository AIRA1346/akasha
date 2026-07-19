# R4-P1 — Navigation IA Plan

> **Phase:** R4-B (P1)  
> **주제:** Sidebar · Bottom Navigation · Preview · Workbench · Search 역할 정리 및 중복 제거  
> **구현:** R4-B Sprint에서 수행 — **본 문서는 Planning only**

---

## P1 목표

| 항목 | 내용 |
|------|------|
| **Primary** | 사용자가 **하단 탭만**으로 「지금 어디·다음에 어디」 설명 가능 |
| **Secondary** | Sidebar = **2차·컬렉션·도구** — cold start **기본 collapsed** |
| **Tertiary** | **서재 → Preview** — Primary Loop 진입률 85%→95% |
| **Guard** | R3 Preview Stack · Save Return **정책 유지** |

**헌법 필터:** Explore ✅ · Discovery ✅ · Link ✅ (Preview 통일)

---

## 현재 Navigation 구조 (코드 재확인)

### 레이아웃

```
[DashboardSidebar 260px, default OPEN]
| [WorkbenchShell: TabRail? + BrowseContent] | [Preview 320px?]
[BottomNav: 홈 | 탐색 | 🔍 | 라이브러리 | 컬렉션]
```

**Coordinator:** `HomeNavigationCoordinator` — `goHome`, `goExplore`, `goKnowledgeGraph`, `selectPersonalLibrary`, `selectTimeline`, …

**Preview 조건:** `home_shell_body.dart` — `(workPreviewItem | entityPreviewItem) && !workbench.hasOpenDetail`

### Bottom Navigation (`home_shell_scaffold.dart` L311–384)

| 탭 | 라벨 | 동작 | Selected 조건 |
|----|------|------|---------------|
| 1 | 홈 | `goHome()` | `isHomeDashboardMode` |
| 2 | 탐색 | `goExplore()` | `isExploreModeActive` |
| 3 | (중앙) | `openSearchDialog()` | — |
| 4 | 라이브러리 | `selectPersonalLibrary(first)` | `isPersonalLibraryMode` |
| 5 | 컬렉션 | `selectCollectibleCollection(first)` | `isCollectibleCollectionMode` |

### Sidebar (`dashboard_sidebar.dart`)

| 항목 | 동작 | BottomNav 중복 |
|------|------|:--------------:|
| 대시보드 / 홈 | `onGoHome` | ✅ 홈 |
| 탐색 | `onGoExplore` | ✅ 탐색 |
| 지식 그래프 | `onGoKnowledgeGraph` | ❌ (sidebar only) |
| 나만의 서재 (N) | `onSelectPersonalLibrary` | ✅ 라이브러리 |
| 컬렉션 (N) | `onSelectCollectibleCollection` | ✅ 컬렉션 |
| 기록 (Timeline) | `onSelectTimeline` | ❌ |
| Recent Exploration | `onOpenRecentExplore` | △ 홈 「계속 탐험」 |

### Browse 진입 정책 (`home_browse_coordinator.dart` L109–111)

```dart
onOpenItem: navigation.isPersonalLibraryMode
    ? workbenchCoord.openBrowseItem      // ← Preview 우회
    : (onPreviewWork ?? workbenchCoord.openBrowseItem),
```

---

## 역할 정의 (Target IA)

### Bottom Navigation — **Primary Spatial Nav**

> 「지금 어느 **공간**에 있는가」— **항상 보이는 5+1**.

| 슬롯 | 역할 (Target) | BrowseContent | Preview |
|------|---------------|---------------|---------|
| **홈** | **탐험 허브** — Hero + continue + 연결 하이라이트 | `HomeDashboardView` | ✅ 유지 |
| **탐색** | **카탈로그 그리드** — 10k·필터 발견 | `BrowseView` | ✅ `openWorkPreview` |
| **검색 (중앙)** | **글로벌 Discovery** — modal, 어디서든 | — | ✅ Search→Preview |
| **라이브러리** | **내가 아카이브한 작품** — curated grid | `PersonalLibraryView` | ✅ **P1 변경** |
| **컬렉션** | **Collectible curation** | collection view | △ Preview optional |

**Bottom Nav 불변:** 5탭 **슬롯 수 유지** (M3 전 UX 급변 방지). **라벨·selected·동작**만 명확화.

### Sidebar — **Secondary · Library · Tools**

> 「공간 **안에서** 어디로 갈까」+ power user · multi-library.

| 유지 (Sidebar) | 이동/제거 (P1) |
|----------------|----------------|
| 다중 Personal Library **목록·전환** | ~~단일 홈~~ → Bottom 「라이브러리」가 primary |
| 다중 Dashboard / Collection **목록** | ~~탐색~~ duplicate → **제거 또는 접힘** |
| **기록 (Timeline)** | Bottom에 **없음** — Sidebar 적합 |
| **지식 연결 맵 (Graph)** | P1: Sidebar **유지** + Hero/홈 링크 (하단 탭 추가 **안 함**) |
| Recent Exploration (최근 5) | 홈 「계속 탐험」과 **중복** → Sidebar **접기·축소** |
| Sidebar toggle (Tab) | 유지 |

**Cold Start default:** `isSidebarOpen = false` **또는** 52px rail — Planning 권장: **first-run prefs false**, 기존 사용자 `HomeSidebarPreferences` 유지.

### Preview — **Exploration Context Panel**

| 속성 | 정의 |
|------|------|
| **역할** | 선택한 Work/Entity의 **가벼운 orient** + **연결 허브** |
| **위치** | 우측 320px, browse와 **병치** |
| **표시** | `!workbench.hasOpenDetail` |
| **진입** | Search, Explore, Home, Graph, **Library (P1)**, Preview 이웃 |
| **Stack** | `previewLinked*`, `navigate*Preview`, `popPreview` — **변경 없음** |
| **퇴장** | 「기록하기 >」→ Workbench (snapshot) · X close |

**P1에서 Preview는 구조 변경 없음** — **진입 경로만** Library 추가.

### Workbench — **Record / Edit Mode**

| 속성 | 정의 |
|------|------|
| **역할** | md 기록 · YAML · 연결 편집 · **집중 편집** |
| **진입** | Preview 「기록하기」·incoming·Search promote · (P1 전) Library 직행 |
| **퇴장** | 명시적 저장 → Preview 복귀 (R3-G) · 탭 닫기 |
| **시각** | TabRail + Info + Sanctum — Preview **완전 가림** |

**P1:** Workbench **레이아웃 변경 없음**. Library→Preview 후 **진입 빈도·맥락**만 개선.

### Search — **Global Discovery Modal**

| 속성 | 정의 |
|------|------|
| **역할** | 로컬 + Registry **통합 발견** |
| **진입** | Bottom 중앙 · TopBar · Hero CTA (P0) · Ctrl+K (P0) |
| **퇴장** | 선택 → Preview (default) · Entity promote → Workbench (예외 유지) |
| **Coordinator** | `HomeDialogsCoordinator.openSearchDialog` |

**P1:** Search **중복 진입점 유지** — P0 Hero와 **동일 동작** (`openSearchDialog`). AppBar search (non-home) 유지.

---

## 중복 제거 대상 (확정)

| # | 중복 | 현재 | Target (P1) | ROI |
|---|------|------|-------------|-----|
| **N1** | 홈 vs Sidebar 「탐색」 | 둘 다 `goExplore()` | Sidebar **탐색 항목 제거** 또는 Advanced 접힘 | Loop 진입 ★★★ |
| **N2** | 홈 vs Sidebar 「홈/대시보드」 | 둘 다 `goHome()` | Sidebar **홈 중복 제거** — 라이브러리 목록만 | First 30s ★★★ |
| **N3** | Bottom 라이브러리 vs Sidebar 서재 목록 | 둘 다 library select | Bottom = **active library grid** · Sidebar = **library switcher** | ★★★ |
| **N4** | Bottom 컬렉션 vs Sidebar 컬렉션 | 동일 | Bottom = primary · Sidebar = list/switch | ★★ |
| **N5** | Recent Exploration ×2 | Sidebar + Home continue | Sidebar recent **축소**(3→0 or icon) · Home continue **유일** | ★★ |
| **N6** | Search 진입 ×4 | Bottom·TopBar·Hero·Ctrl+K | **동작 통일** — visual 중복 **허용** (역할 동일) | ★★★★ |
| **N7** | **서재 그리드 → Workbench** | `openBrowseItem` | **`openWorkPreview`** (P1 **필수**) | Loop **★★★★★** |
| **N8** | Graph sidebar only | `goKnowledgeGraph` | P1: Home Hero/연결 섹션 **텍스트 링크** 추가 (탭 추가 X) | ★★ (P2 full) |
| **N9** | FilterSection × contexts | explore+library | P1 **유지** — scope 명확화만 (라벨) | ★ |
| **N10** | 「탐색」탭 vs Hero CTA | 둘 다 discovery | P0 후: Hero=**start** · 탐색=**browse grid** — **라벨** 「카탈로그」검토 (optional) | ★★★ |

---

## 변경 후 Navigation 흐름

### Primary Loop (Target — 전 진입점)

```
Discovery (Home Hero | Search | Explore | Library*)
  → Preview (replace)
  → Link explore (push stack)
  → Workbench (record burst)
  → Save → Preview return

* Library = P1 추가
```

### Bottom Nav 사용자 여정

```
[홈]     Hero · continue · 오늘의 연결     + Preview
[탐색]   10k/필터 그리드                  + Preview
[검색]   modal                           → Preview
[라이브러] 내 아카이브 그리드               + Preview (P1)
[컬렉션]  collectible browse              (기존)
```

### Sidebar 사용자 여정 (2차)

```
[≡ Tab]  Sidebar toggle
  ├─ Library 2, 3… (switch)
  ├─ Collection 2, 3…
  ├─ 기록 (Timeline)
  ├─ 지식 연결 맵
  └─ (제거) 홈·탐색 duplicate
```

---

## P1 구현 항목 (Planning — 미착수)

| Priority | 작업 | 파일 | 비고 |
|:--------:|------|------|------|
| **P1-1** | Library grid → Preview | `home_browse_coordinator.dart` L109–111 | `onPreviewWork` always when wired |
| **P1-2** | Sidebar duplicate 제거 | `dashboard_sidebar.dart` | 홈·탐색 nav row |
| **P1-3** | Cold start sidebar default closed | `home_sidebar_preferences.dart` or first-run flag | 기존 user migrate |
| **P1-4** | Sidebar recent explore 축소 | `dashboard_sidebar.dart` | optional hide |
| **P1-5** | Home 「연결 맵」링크 → `goKnowledgeGraph` | `home_dashboard_todays_links_section.dart` or Hero | N8 partial |
| **P1-6** | Bottom 「탐색」tooltip/subtitle (optional) | `home_shell_scaffold.dart` | 「카탈로그」clarify |
| **P1-7** | regression: library tap → preview test | `test/` | |

---

## Preview / Workbench / Search 상호작용 (정책표)

| From → To | Search | Preview | Workbench |
|-----------|:------:|:-------:|:---------:|
| Home Hero CTA | open | — | — |
| Search select work | — | open replace | — |
| Explore grid | — | open replace | — |
| **Library grid (P1)** | — | **open replace** | ~~openBrowse~~ |
| Preview 기록하기 | — | hide | open+snapshot |
| Workbench 저장 | — | restore+showBrowse | hide detail |
| Wiki link (Sanctum) | — | open replace | from WB |
| incoming record | — | — | open (유지) |

---

## P0 → P1 의존성

| P0 산출 | P1 영향 |
|---------|---------|
| Hero single CTA | Bottom 「홈」= Hero host — **역할 명확** |
| Vault banner 축소 | Sidebar·Bottom **시각 경쟁 감소** |
| Cold copy | Sidebar Graph·Timeline **용어** 통일 |

**권장 순서:** R4-A (P0) **완료·측정** → R4-B (P1).

---

## 성공 기준 (P1 단독)

| # | 기준 |
|---|------|
| 1 | Sidebar **없이** Bottom만으로 Home·Explore·Library·Search·Collection 전환 가능 |
| 2 | Library grid tap → **Preview** (widget test) |
| 3 | Primary loop 진입률 **≥95%** (서재·탐색·홈·검색) |
| 4 | R3-F/G 시나리오 B **회귀 없음** |
| 5 | Cold start Sidebar **default closed** (신규 설치) |

---

## 비범위 (P1)

- Bottom tab **개수** 변경 (6탭화, Graph tab 추가)
- Preview 320px width / layout
- Workbench TabRail 구조
- Timeline/Records 축 통합
- 시각 Graph

---

## ROI 요약 (P1)

| 효과 | 기대 |
|------|------|
| First 30 Seconds | Sidebar noise ↓ → Hero 가독성 ↑ |
| Cold Start | 단일 spatial model |
| Loop 진입률 | Library **+10%p** (Audit D2) |
| 우주 체감 | Preview 일관 → 「걸어 다니기」 |

---

## 관련 문서

- [R4_PLANNING_MASTER_PLAN.md](./R4_PLANNING_MASTER_PLAN.md)
- [R4_P0_FIRST_30_SECONDS_PLAN.md](./R4_P0_FIRST_30_SECONDS_PLAN.md)
