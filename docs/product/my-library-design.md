# 나만의 서재 — UI·역할 설계 (v1 재정의)

> **상태:** v1 구현 완료 (2026-06-07) · **2026-06 통합 홈** (`HomeShell` 나만의 서재 모드)  
> **북극성:** [ultimate-archiving-vision.md](ultimate-archiving-vision.md) · **화면 역할:** §12  
> **관련 코드:** `dashboard_sidebar.dart`, `home_shell.dart`, `browse_dashboard_sections.dart`

---

## 0. 구현 현황 (2026-06-12)

| 항목 | 상태 |
|------|------|
| 사이드바 「나만의 서재」 섹션 | ✅ `dashboard_sidebar.dart` |
| 메인 패널 모드 전환 | ✅ `_isPersonalLibraryMode` (`home_screen.dart`) |
| 별도 `MyLibraryScreen` | ❌ **제거** — To-Be §2와 일치 |

---

## 1. 문제 인식 (과거 As-Is · 2026-06-07)

### 사이드바 구조 (잘못된 배치)

```
대시보드 서재  [+]
─────────────────
  나의 서재  →        ← ❌ 대시보드 목록 **위**에 단일 항목으로 배치됨
─────────────────
  master_index
  manga_dashboard
  game_dashboard
```

### 동작 (역할과 UI 불일치)

| 항목 | 현재 |
|------|------|
| 진입 | 사이드바 「나의 서재」 탭 → **별도 전체 화면** (`MyLibraryScreen`, `Navigator.push`) |
| 콘텐츠 | 볼트에 **아카이브된** 작품만 IP 1카드 그리드 |
| 대시보드와 관계 | 메인 영역(필터·섹션·HoF)과 **완전 분리** |
| 데이터 | `MyLibraryPipeline` — 사전 가상 카드 제외, 아카이브만 |

사용자 의도와의 차이:

- **위치:** 나만의 서재는 대시보드 **아래** 별도 섹션으로 나와야 함.
- **형식:** 새 창/화면이 아니라 **대시보드와 같은 메인 패널** 안에서 전환.
- **역할:** 탐색(대시보드) vs **엄선·즐겨찾기(나만의 서재)** 가 명확히 갈려야 함.

---

## 2. 목표 구조 (To-Be)

### 사이드바 계층

```
┌─ 대시보드 서재 ───────────── [+]   ← 섹션 헤더 (teal)
│    master_index                    ← 대시보드 항목 (필터 프리셋)
│    manga_dashboard
│    game_dashboard
│
├─ 나만의 서재 ─────────────── [+]   ← 섹션 헤더 (amber, 대시보드와 대칭)
│    (나만의 서재 A)                 ← 개인 서재 항목 — 대시보드 항목과 동일한 행 스타일
│    (나만의 서재 B)
│    …
└─ Tab 키를 눌러 사이드바 토글
```

**규칙**

1. 「대시보드 서재」와 「나만의 서재」는 **동급 섹션 헤더** (아이콘·`[+]`·구분선 패턴 통일).
2. 각 섹션 아래에 **목록 항목**이 나열됨. 항목 행 UI는 `SidebarItemWidget`과 동일 계열.
3. 항목 선택 시 **오른쪽 메인 영역만** 바뀜 (`Navigator.push` 없음).
4. 한 번에 **하나만 활성**: 대시보드 항목 **또는** 나만의 서재 항목.

### 메인 콘텐츠 영역

| 모드 | 역할 | 작품 범위 |
|------|------|-----------|
| **대시보드** | 수많은 작품을 **찾고·확인**하는 탐색 공간 | 글로벌 사전(카탈로그) + 볼트 아카이브 융합, 필터·HoF·연도별·워치리스트 섹션 |
| **나만의 서재** | 내가 **골라 둔** 작품만 보는 엄선 공간 | 아카이브·체크·즐겨찾기·수동 선정 등 **사용자가 의도적으로 넣은** 작품만 |

**공통:** IP 1카드 그리드, 포스터 카드, 상세 진입, (옵션) 섹션·정렬 UX.

**차이:** 나만의 서재는 **사전 전체 브라우징을 하지 않음** — 포함 기준이 “내 컬렉션”에 한정.

---

## 3. 개념 정의

### 3.1 대시보드 서재

- **목적:** 카탈로그 탐색 · 상태별 필터 · 신작/미등록 작품 발견.
- **데이터 소스:** `BrowsePipeline` (user items + `WorksRegistry` fuse).
- **설정:** `DashboardConfig` — domain, categories, myStatuses, workStatuses.
- **UI:** 상단 `FilterSection` + `BrowseDashboardSections` (HoF, 카탈로그, 연도별, 워치리스트).
- **기본값:** `master_index`, `manga_dashboard`, `game_dashboard`.

### 3.2 나만의 서재

- **목적:** “내가 고른 것만” — 회고·재감상·자랑·정리용 **개인 큐레이션**.
- **데이터 소스:** 볼트 기반 + (TBD) 즐겨찾기·체크·HoF·수동 컬렉션 규칙.
- **설정:** `PersonalLibraryConfig` (신규, `DashboardConfig`와 대칭) — **포함 규칙** 중심.
- **UI:** 대시보드와 **동일 셸** (필터·메인 스크롤). 섹션 구성은 TBD (단순 그리드 vs HoF 등).
- **금지:** 사전 가상 카드만으로 채우기 (`MyLibraryPipeline` 정책 유지).

### 3.3 용어 정리

| 용어 | 권장 | 비고 |
|------|------|------|
| UI 섹션 헤더 | **나만의 서재** | 사용자 지정 명칭 |
| 개별 목록 항목 | **(이름 있는 서재)** 예: `인생 명작`, `즐겨찾기` | 사용자가 `[+]`로 추가 |
| 구현 클래스 (가칭) | `PersonalLibraryConfig` / `PersonalLibraryPipeline` | `MyLibraryScreen` 단계적 폐기 |
| 레거시 명칭 | 「나의 서재」 | 문서·코드에서 **나만의 서재**로 통일 예정 |

---

## 4. 기술 방향 (초안)

### 4.1 네비게이션 통합

```text
HomeScreen
├── activeView: dashboard | personalLibrary
├── activeDashboardId (기존)
└── activePersonalLibraryId (신규)

사이드바 onSelectDashboard  → activeView=dashboard, 메인=BrowseDashboardSections
사이드바 onSelectPersonalLib → activeView=personalLibrary, 메인=PersonalLibraryView (신규)
```

- `MyLibraryScreen` + `Navigator.push` **제거**.
- `DashboardSidebar` → `LibrarySidebar` 또는 기존 위젯 확장: 두 섹션 + 두 ListView.

### 4.2 설정 영속화

| 키 (가칭) | 내용 |
|-----------|------|
| `akasha_dashboards` | 기존 유지 |
| `akasha_active_dashboard_id` | 대시보드 선택 시 |
| `akasha_personal_libraries` | JSON 배열 (`PersonalLibraryConfig`) |
| `akasha_active_personal_library_id` | 나만의 서재 선택 시 |
| `akasha_active_sidebar_mode` | `dashboard` \| `personal` (마지막 포커스) |

### 4.3 포함 규칙 후보 (결정 대기)

| 규칙 ID | 설명 | 현재 데이터 |
|---------|------|-------------|
| `archived` | 볼트에 아카이브된 작품 | `ArchivedWorksQuery` ✅ |
| `hall_of_fame` | `isHallOfFame == true` | `AkashaItem.isHallOfFame` ✅ |
| `favorite` | 즐겨찾기 표시 작품 | ❌ 필드 없음 — 신규 필요 |
| `manual` | 사용자가 서재에 직접 추가한 workId 목록 | ❌ 신규 필요 |
| `my_status:*` | 나의 상태 필터 (예: 전부 봄만) | 상태 라벨 ✅ |
| `rating_min` | 최소 평점 | `rating` ✅ |

**원칙:** 나만의 서재 하나 = **하나 이상의 포함 규칙** (AND/OR — TBD).

### 4.4 대시보드 메인과의 UI 차이 (예상)

| 요소 | 대시보드 | 나만의 서재 |
|------|----------|-------------|
| 상단 필터 칩 | ✅ 전체 (domain·category·status) | TBD — 축소 또는 숨김 |
| 사전 카탈로그 섹션 | ✅ 「작품 카탈로그 (사전+아카이브)」 | ❌ 미등록 사전-only 카드 없음 |
| HoF 섹션 | 대시보드 필터 결과 중 HoF | TBD — 서재별 HoF만 or 단일 그리드 |
| 연도별 / 워치리스트 | ✅ | TBD |
| 테마·꾸미기 (IAP) | — | 기존 `LibraryTheme` — 서재별 or 전역 TBD |
| FAB 「+ 새 작품」 | ✅ | TBD — 탐색 vs 큐레이션 |

---

## 5. 마이그레이션

1. **기본 나만의 서재 1개** 자동 생성 (이름·규칙 TBD).
2. 기존 `MyLibraryScreen` 동작(아카이브 전체)을 **첫 번째 서재**로 매핑.
3. `browse_dashboard_sections` 안내 문구: 「나만의 서재」 사이드바 안내로 수정.
4. ROADMAP·README 용어 통일.

---

## 6. 미결정 사항 (질문 목록)

아래는 구현 전 사용자 확인이 필요한 항목이다. 답변 후 §7에 반영한다.

### A. 서재 개수·생성

- A1. 기본 제공 서재는 **고정 프리셋**인가, **빈 상태에서 사용자만 추가**인가?
- A2. `[+]`로 서재를 **여러 개** 만들 수 있는가? (대시보드와 동일?)
- A3. 서재 이름·아이콘·색 **커스터마이즈** 범위는?

### B. 작품 포함 기준

- B1. 「체크한 작품」의 정확한 의미 — **아카이브**인가, **새 체크박스**인가, **HoF**인가?
- B2. 「즐겨찾기」는 **별도 토글(★)** 신규 도입인가?
- B3. 한 작품이 **여러 서재**에 동시 소속 가능한가?
- B4. 사전에만 있고 볼트에 없는 작품 — 나만의 서재에 **넣을 수 있는가** (수동 추가)?

### C. 메인 패널 UX

- C1. 나만의 서재도 **HoF / 연도별 / 워치리스트 섹션**을 쓸까, **단일 그리드**만?
- C2. 나만의 서재 선택 시 **상단 FilterSection** 표시 여부?
- C3. 대시보드와 **동시에 필터 상태 공유**할까, 서재마다 독립 저장?

### D. 테마·IAP

- D1. `LibraryTheme`은 **서재별**인가 **앱 전역**인가?
- D2. 테마 피커 위치 — 사이드바 항목 설정, 메인 툴바, AppBar?

### E. v1 범위

- E1. 이번 수정에서 **사이드바 재배치 + 메인 통합**만 할지, **즐겨찾기·수동 컬렉션**까지 포함할지?
- E2. `master_index` 대시보드 안내 문구·카탈로그 섹션은 그대로 둘지, 역할 설명을 강화할지?

---

## 7. 결정 로그

| ID | 질문 | 결정 | 일자 |
|----|------|------|------|
| A | 서재 목록 구성 | **기본 프리셋 + `[+]` 사용자 추가** (대시보드와 동일 패턴) | 2026-06-07 |
| B | 작품 포함 기준 | **v1: 아카이브(`archived`)만**. v1.1+에 HoF·즐겨찾기·수동·상태필터 순차 추가 | 2026-06-07 |
| C | 메인 레이아웃 | **대시보드와 동일 섹션** (HoF / 그리드 / 연도별 / 워치리스트 — 내 작품만) | 2026-06-07 |
| D | 상단 필터 칩 | 나만의 서재 선택 시 **숨김** (서재·규칙이 필터 역할) | 2026-06-07 |
| E | v1 구현 범위 | **1단계:** 사이드바 재배치 + 메인 통합 셸. 아카이브 규칙, 매체별 프리셋 | 2026-06-07 |
| F | 기본 프리셋 | **매체별 전부** + 「내 전체 아카이브」 (7개) | 2026-06-07 |
| G | 빈 프리셋 | **항상 표시** (0건이어도 사이드바 유지) | 2026-06-07 |
| H | 기본 서재 이름 | **`내 {매체} 아카이브`** 패턴 | 2026-06-07 |
| I | v1 `[+]` | 이름 입력 → 빈 서재 (`archived`, 카테고리 없음) | 2026-06-07 |
| J | 테마 피커 | v1.1로 미룸 | 2026-06-07 |
| K | 섹션 제목 | 나만의 서재 모드: **「내 아카이브」** | 2026-06-07 |
| L | 프리셋 편집 | **master_index와 동일** — 삭제·이름 변경 불가 | 2026-06-07 |
| M | 활성 강조색 | 대시보드 **teal** · 나만의 서재 **amber** | 2026-06-07 |
| N | 책 매체 | **`book` 카테고리** — 「내 책·라노벨 아카이브」 | 2026-06-07 |

---

## 8. v1 (1단계) 상세 스펙

### 8.1 사이드바

1. 「대시보드 서재」 헤더 → 대시보드 목록 (`master_index` …)
2. 구분선
3. 「나만의 서재」 헤더 + `[+]` (v1: 추가 UI 스텁 또는 동일 다이얼로그 — **TBD §9**)
4. 기본 서재 **프리셋 N개** 자동 생성: `내 {매체} 아카이브` (§9.1)

### 8.2 메인 패널 (나만의 서재 활성 시)

- `FilterSection` **미표시**
- `BrowseDashboardSections` **재사용** — 입력 카드는 `MyLibraryPipeline` (아카이브만)
- HoF / 연도별 / 워치리스트는 **아카이브 작품 subset**으로 동일 로직 적용
- `Navigator.push` → `MyLibraryScreen` **제거**

### 8.3 데이터

```dart
// v1 PersonalLibraryConfig (최소)
{
  "id": "archive_manga",
  "name": "내 만화 아카이브",
  "inclusionRules": ["archived"],
  "categories": ["manga"]   // 프리셋별 매체 필터 (v1)
}
```

### 9.1 기본 프리셋 목록 (v1 확정)

첫 실행 시 **7개** 자동 생성. 아카이브 0건이어도 **항상 사이드바에 표시**.

| ID | 표시 이름 | categories |
|----|-----------|------------|
| `archive_manga` | 내 만화 아카이브 | manga |
| `archive_anime` | 내 애니 아카이브 | animation |
| `archive_game` | 내 게임 아카이브 | game |
| `archive_book` | 내 책·라노벨 아카이브 | book |
| `archive_movie` | 내 영화 아카이브 | movie |
| `archive_drama` | 내 드라마 아카이브 | drama |
| `archive_all` | 내 전체 아카이브 | ∅ (전 매체) |

`[+]`로 추가하는 사용자 서재: 이름 자유, 규칙 `archived` 고정, 카테고리 없음(전 매체).

### 8.4 v1에서 하지 않음 (v1.1+)

- 즐겨찾기(★) 필드·토글
- HoF / 수동 선정 / 나의 상태 규칙
- 서재별 `LibraryTheme` (기존 전역 테마는 `MyLibraryScreen` 폐기 시 **TBD §9**)
- `[+]`로 규칙 다른 새 서재 저장 (UI만 열어 두거나 스텁)

---

## 9. v1 잔여 질문

**모두 응답 완료** (§7·§9.1). 구현 착수 가능.

---

## 10. 구현 체크리스트

### v1 (1단계)

- [x] `PersonalLibraryConfig` 모델 + SharedPreferences (archived 규칙만)
- [x] `dashboard_sidebar.dart` — 두 섹션, 나만의 서재를 대시보드 **아래**로 이동
- [x] `HomeScreen` — `SidebarSelectionMode` 분기, 메인에 `BrowseDashboardSections` 재사용
- [x] `MyLibraryScreen` + `Navigator.push` 제거 (화면 파일은 v1.1 테마용 보류)
- [x] 나만의 서재 활성 시 `FilterSection` 숨김
- [x] `BrowseDashboardSections` — personal 모드 시 섹션 제목 「내 아카이브」
- [x] 기본 프리셋 7개 시드 (`내 {매체} 아카이브`)
- [x] 프리셋 immutable · teal/amber 강조색 분리

### v1.1+

- [ ] `LibraryTheme` / AppBar 팔레트 복원 (서재 뷰)

- [ ] 포함 규칙: `hall_of_fame`, `favorite`, `manual`, `my_status:*`
- [ ] `[+]` 서재 CRUD + 규칙 편집 다이얼로그
- [ ] 즐겨찾기(★) 카드·상세 UI
- [ ] 서재별 테마 (IAP)

---

## 11. v1.1+ 프리셋·규칙 로드맵 (참고)

| 단계 | 규칙 | 예시 서재 이름 |
|------|------|----------------|
| v1 | `archived` + category | 내 만화 아카이브 |
| v1.1 | `hall_of_fame` | 인생 명작 |
| v1.1 | `favorite` | 즐겨찾기 |
| v1.1 | `my_status:watching` | 보는 중 |
| v1.2 | `manual` | 직접 만든 컬렉션 |
