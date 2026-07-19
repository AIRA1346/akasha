# R4-P0 — First 30 Seconds Plan

> **Phase:** R4-A (P0)  
> **주제:** 사용자가 **30초 안에** AKASHA가 무엇을 하는 앱인지 이해하게 만드는 방법  
> **구현:** R4-A Sprint에서 수행 — **본 문서는 Planning only**

---

## P0 목표

| 항목 | 내용 |
|------|------|
| **Primary** | 30초 내 「**기록 → 연결 → 발견**」 narrative 전달 |
| **Secondary** | 다음 행동 **1개**로 수렴 (분산 CTA 제거) |
| **Tertiary** | Ctrl+K 신뢰 복구 |

**헌법 필터:** Discovery ✅ · Explore ✅ · Link ✅ (카피) · Archive △ (볼트 안내는 2차)

---

## 현재 문제 (Audit 확정 — 재탐색 없음)

### 30초 타임라인 (코드 기준)

| 시각 | 사용자 경험 | 문제 |
|------|-------------|------|
| 0s | `HomeVaultBanner` — 「데모용 샘플」「Sanctum Vault」 | **관리·인프라** 언어 선행 |
| 0–5s | Sidebar 260px open — 대시보드·서재·컬렉션·기록·그래프 | **공간 과다** |
| 0–5s | 하단 5탭 — 홈·탐색·검색·라이브러리·컬렉션 | Home≈Explore **역할 불명** |
| 5–15s | `HomeDashboardTopBar` — 검색 placeholder, Ctrl K, 볼트 설정 | **앱이 뭔지** 설명 없음 |
| 15–30s | 4섹션 스크롤 — 각각 다른 CTA | **단일 narrative 부재** |

### Cold Start 3상태 (R3-H Scenario A)

| 상태 | 조건 | 현재 첫 행동 후보 |
|------|------|-------------------|
| **S0** | `vaultPath == null` | 배너 [폴더 연동] · 검색 · 탐색 · Sidebar Graph |
| **S1** | 볼트 연동, 작품 0 | [검색으로 탐험 시작] · `[[wiki]]` 안내 · 탐색 탭 10k 그리드 |
| **S2** | 작품 있음, 연결 0~ | 4섹션 카드 · fallback vault |

**공통 실패:** 「AKASHA = 지식 우주 탐험」 문장이 **viewport 어디에도 없음**.

### 코드 앵커 (변경 대상)

| 파일 | 현재 역할 |
|------|-----------|
| `home_dashboard_view.dart` | TopBar → 4섹션 Column — **Hero 없음** |
| `home_dashboard_top_bar.dart` | 검색·설정만 |
| `home_dashboard_continue_section.dart` | 빈 시 [검색으로 탐험 시작] — **Hero와 경쟁** |
| `home_vault_banner.dart` | S0 전용 — narrative 없음 |
| `home_shell_scaffold.dart` | Ctrl+K 미연결 (Tab=sidebar) |

---

## 변경 후 흐름 (Target UX)

### 30초 이상 경로 (모든 Cold Start 상태)

```
앱 실행
  → goHome() → HomeDashboardView
  → [Hero] 1줄 narrative + 1 Primary CTA  ← NEW (viewport 최상단, 스크롤 전)
  → (선택) 사용자가 CTA 탭
  → openSearchDialog()
  → 작품/인물 선택
  → openWorkPreview / openEntityPreview
  → Preview: 연결·「기록하기 >」  ← R3 루프 진입 (기존)
```

**30초 내 이해:** Hero만 읽어도 「발견하고 → 연결하고 → 기록하는 우주」 파악.  
**30–90초:** CTA 1회 → Search → Preview까지 **guided discovery**.

### 상태별 Hero 분기

| 상태 | Hero headline (안) | Primary CTA | Secondary (텍스트 링크) |
|------|-------------------|-------------|-------------------------|
| **S0** 미연동 | 「작품에서 시작해, 당신만의 지식 우주를 만드세요」 | **작품 찾아 탐험 시작** → Search | 「로컬 폴더 연결」→ vault (배너 **통합·축소**) |
| **S1** 빈 볼트 | 동일 headline | **작품 찾아 탐험 시작** → Search | 「볼트에 첫 작품 추가」→ Search (동일) |
| **S2** 데이터 있음 | 「이어서 탐험하세요 — 연결에서 새 발견이」 | **탐험 이어하기** → Search **또는** 첫 continue 카드 scroll-into-view | 없음 또는 Graph 링크 (P1) |

> **원칙:** Primary CTA는 **항상 1개**. S2만 CTA 라벨만 변경 — **동작은 Search 또는 continue 첫 카드** (구현 시 continue 비어 있으면 Search).

### R3 루프와의 접점 (변경 없음)

```
Hero CTA → Search → Preview (replace)
  → previewLinked* (push)
  → open*FromPreview → Workbench
  → 명시적 저장 → _maybeReturnToPreviewAfterSave
```

P0는 **Hero→Search→Preview** 구간만 추가. R3-F/G **손대지 않음**.

---

## Home Hero 영역 (설계)

### 배치

```
HomeDashboardView
  ├─ HomeDashboardHero          ← NEW (P0)
  ├─ HomeDashboardTopBar        (유지 — 검색 shortcut)
  ├─ HomeDashboardContinueSection  (S2: Hero 아래 유지 / S0·S1: 시각적 위계 하향)
  ├─ TodaysLinks
  ├─ RecentDiscovery
  └─ RecentRecords
```

- **위치:** `HomeDashboardTopBar` **위** 또는 **아래** — Planning 권장: **TopBar 위** (검색창 = Hero CTA의 visual echo)
- **높이:** ~120–160px — **스크롤 없이** narrative + CTA 노출 (1080p 기준)
- **AppBar:** `isHomeDashboardMode` 시 null 유지 — Hero가 사실상 app header

### Hero 콘텐츠 구조

```
┌─────────────────────────────────────────────────────────┐
│  AKASHA                                    (로고/워드마크) │
│  기록하고 · 연결하고 · 새로 발견하는                        │
│  당신만의 문화 지식 우주                                   │
│                                                         │
│  [  작품 찾아 탐험 시작  ]    ← FilledButton, full-width max 320 │
│                                                         │
│  S0 only: 로컬 기록은 폴더 연결 후 저장됩니다 · [연결]       │
└─────────────────────────────────────────────────────────┘
```

### 카피 원칙

| 금지 (현재) | 대체 (P0) |
|-------------|-----------|
| `[[wiki]]` | 「링크」 |
| Sanctum Vault | 「로컬 폴더」또는 「내 기록」 |
| 데모용 샘플 (Hero 근처) | 「카탈로그로 먼저 탐험해 보세요」 |
| md 저장 | 「기록 저장」 |

### `HomeVaultBanner` 처리 (P0)

- **S0:** 배너 **축소** — Hero secondary 링크로 흡수, 노란 full-width bar **제거 또는 1줄**
- **S1+:** 배너 **숨김**

---

## 단일 CTA 전략

### Primary CTA (유일한 FilledButton)

| 속성 | 값 |
|------|-----|
| **라벨** | 「작품 찾아 탐험 시작」(S0/S1) / 「탐험 이어하기」(S2) |
| **동작** | `onPrimaryCta` → `openSearchDialog()` |
| **위치** | Hero only — **4섹션·TopBar·하단탭에 duplicate FilledButton 금지** |

### Secondary actions (TextButton / Link only)

| 항목 | 허용 | 금지 |
|------|:----:|:----:|
| S0 폴더 연결 | ✅ Hero 하단 1줄 | ❌ 배너 + Hero + Sidebar 동시 강조 |
| TopBar 검색 tap | ✅ (power user) | ❌ Hero와 **동등** visual weight |
| continue section [검색으로 탐험 시작] | S0/S1 | ❌ — **Hero로 대체·제거** |
| 하단 검색 FAB | ✅ 유지 | 변경 없음 (P1에서 역할 정리) |

### 4섹션 Cold Start 역할 재정의

| 섹션 | S0/S1 | S2 |
|------|-------|-----|
| 계속 탐험하기 | 빈 상태 — **CTA 제거**, 설명 1줄만 | 카드 유지 |
| 오늘의 연결 | 「링크를 만들면 여기 표시」 — wiki 문법 제거 | 유지 |
| 최근 발견 | 「탐험 후 표시」 | 유지 |
| 최근 기록 | 「기록하기에서 저장」 — Sanctum 제거 | 유지 |

**목표:** S0/S1에서 Hero **외** 클릭 유도 **최소화** — 정보性 섹션은 **미래 preview**.

---

## Cold Start 흐름 (상세)

### S0 — 볼트 미연동

```
[Before]
Banner(데모) + Sidebar + 5탭 + 4섹션 CTA 분산

[After]
Hero(narrative + 「작품 찾아 탐험 시작」)
  → Search → Registry work → Preview (데모/로컬 없이 가능)
  → 「기록하기 >」→ Workbench → 저장 시 「볼트 연결」 (기존 — P0 변경 없음)
Secondary: 「로컬 폴더 연결」
```

**ROI:** Search→Preview는 **볼트 없이** 가능 — Hero CTA가 S0에서도 Dead End 없음.

### S1 — 빈 볼트

```
Hero → Search → Preview → (연결 0) WorkPreviewEmptyConnections
  → 「기록 열고 직접 작성」→ Workbench → 저장 → Preview 복귀 (R3-G)
```

**ROI:** Scenario A 62–68% → **75%** 목표의 핵심 경로.

### S2 — 데이터 있음

```
Hero 「탐험 이어하기」→ Search
  OR continue 첫 카드가 viewport에 보이도록 Hero compact
Home 카드 → navigate*Preview (R3-F 유지)
```

---

## P0 부가 항목 (ROI 최고·저비용)

### Ctrl+K (`home_shell_scaffold.dart`)

```dart
// Planning intent — R4-A 구현 시
SingleActivator(LogicalKeyboardKey.keyK, control: true): openSearchDialog
```

- TopBar `Ctrl K` 배지와 **일치**
- 비용 **XS**, First 30s ★★★★

---

## 구현 체크리스트 (R4-A용 — 아직 미착수)

| # | 작업 | 파일 |
|---|------|------|
| 1 | `HomeDashboardHero` 위젯 | `views/home_dashboard/home_dashboard_hero.dart` (신규) |
| 2 | Hero 상태 분기 (S0/S1/S2) | `home_dashboard_view.dart`, `vaultPath`, `vaultItems` |
| 3 | continue section cold CTA 제거 | `home_dashboard_continue_section.dart` |
| 4 | todays/recent wiki·Sanctum 카피 | `home_dashboard_*_section.dart` |
| 5 | Vault banner 축소/흡수 | `home_vault_banner.dart`, `home_shell_body.dart` |
| 6 | Ctrl+K shortcut | `home_shell_scaffold.dart` |
| 7 | widget test — Hero visible, CTA → search callback | `test/home_dashboard_view_test.dart` |

---

## 성공 기준 (P0 단독)

| # | 기준 |
|---|------|
| 1 | Hero + CTA **스크롤 없이** 노출 (`isHomeDashboardMode`) |
| 2 | S0/S1 viewport에 **FilledButton 1개** only |
| 3 | 5명 테스트 — 30s 내 「기록·연결·발견」 **≥2** 언급 |
| 4 | Ctrl+K → Search dialog |
| 5 | R3-F/G widget test **회귀 없음** |

---

## 비범위 (P0)

- Navigation IA (P1)
- Preview layout reorder
- Graph
- Search 알고리즘
- Workbench 구조

---

## 관련 문서

- [R4_PLANNING_MASTER_PLAN.md](./R4_PLANNING_MASTER_PLAN.md)
- [R4_P1_NAVIGATION_PLAN.md](./R4_P1_NAVIGATION_PLAN.md)
