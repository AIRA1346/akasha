# UX Flow Audit — AKASHA

> **Sprint:** UX Recovery
> **갱신:** 2026-06-22
> **기준:** 실제 코드 (`lib/`) + [PROJECT_CONSTITUTION.md](../PROJECT_CONSTITUTION_STUB.md)
> **주의:** [CURRENT_STATE.md](../../../active/CURRENT_STATE.md), [ROADMAP.md](../../../active/ROADMAP.md)는 일부 항목이 코드보다 뒤처져 있음 (본 문서는 **코드 우선**)

---

## 헌법 기준: 기록 → 연결 → 발견

| 가치 | 코드에 존재하는가 | 사용자가 자연스럽게 경험하는가 |
|------|-------------------|-------------------------------|
| **기록 (Archive)** | ✅ Sanctum, YAML, vault, timeline/journal | ⚠️ 워크벤치 진입 후에야 명확 |
| **연결 (Link)** | ✅ `[[wiki]]`, link index, incoming, neighbors | ❌ 링크 삽입은 숨김; 그래프는 리스트 |
| **발견 (Discovery)** | ✅ Fusion 검색, 10k catalog, browse | ⚠️ 홈 휴리스틱과 실제 추천 불일치 |

**진단 한 줄:** 엔진은 있으나, **진입·전환·카피**가 데이터 관리 앱처럼 동작한다.

---

## 전역 셸 구조

```
HomeShellScaffold
├── AppBar (홈 대시보드 모드에서는 null)
├── DashboardSidebar (좌)
├── HomeShellBody
│   ├── FilterSection (조건부)
│   └── WorkbenchShell
│       ├── CollectibleTabRail (탭 열림 시)
│       ├── WorkDetailWorkspace | EntityDetailWorkspace (상세 열림 시)
│       └── browseContent (대시보드 / 그리드 / 그래프 / Records / 컬렉션)
└── BottomNavigationBar (항상)
```

**모드 전환:** `HomeNavigationCoordinator` — `isHomeDashboardMode`, `isExploreBrowseMode`, `isKnowledgeGraphMode`, 서재/컬렉션/타임라인.

---

## 경로 1: Home Dashboard

### 코드 경로

`goHome()` → `isHomeDashboardMode` → `HomeDashboardView` (`home_shell_body._buildDashboardBrowseContent`)

### 사용자가 보는 것

| 영역 | 내용 |
|------|------|
| TopBar | 검색창(클릭), Ctrl K 배지, 볼트 설정, 아바타 |
| 환영 | 「안녕하세요, 탐험가님!」 |
| 계속 탐험하기 | `RecentExplorationStore` 기반 최근 4건 + 진행률 휴리스틱 |
| 발견의 여정 | 탭: 추천 연결 / 새로운 작품 / 주목할 인물 |
| 지식 우주 현황 | 궤도 위젯 + 최근 추가 작품 |
| 빠른 액션 | 검색, 인물 탐색, 그래프[Beta], 타임라인 |
| 사이드바 | 최근 탐색, 서재·대시보드·컬렉션 목록, 그래프 메뉴 |
| 하단 탭 | 홈·탐색·검색·라이브러리·컬렉션 |

### 사용자가 할 수 있는 것

- **Work 카드 탭** → 우측 `DashboardPreviewPanel` (워크벤치 아님)
- **Entity 카드 탭** → 즉시 Entity 워크벤치
- 탐색 / 그래프 / 타임라인 / 검색 / 서재·컬렉션 전환

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 기록 | △ 최근 탐색·진행률은 「탐험」 메타포이나 기록 깊이 휴리스틱 |
| 연결 | △ 프리뷰에 이웃 인물·작품 (링크 인덱스) — **링크 없으면 빈 화면** |
| 발견 | △ 「발견의 여정」은 추천이 아닌 정렬/태그 휴리스틱 |

### 성격

**표면: 지식 탐험 UI / 실체: 라이브러리 관리 대시보드에 가까움**
(볼트·서재·컬렉션·설정이 동일 가중치로 노출)

### 숨겨진 기능

- `TodayRecallCard` (`showRecallCard=false`)
- AppBar 도구(동기화, AI 가져오기, 카탈로그 제안) — 홈에서 AppBar 없음
- Tab 단축키만 전역 바인딩 (`Ctrl+K` 검색 없음)

---

## 경로 2: Search (Fusion)

### 코드 경로

`openSearchDialog()` → `FusionSearchDialog` — TopBar, 하단 FAB, AppBar(비홈), 빠른 액션

### 사용자가 보는 것

- 로컬 아카이브 / 내 등록 / 글로벌 사전 통합 결과
- 미아카이브 글로벌 Work, catalog-only Entity
- CTA: 직접 추가, 글로벌 제안, 서재 담기

### 선택 후 동작

| 결과 | 다음 화면 |
|------|-----------|
| 로컬 Work | **워크벤치 직행** (프리뷰 없음) |
| 글로벌 Work | in-memory 워크벤치 (미저장 가능) |
| Entity | Entity 워크벤치 (또는 promote 후) |

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 발견 | ✅ 강함 — 10k + 볼트 통합 |
| 기록 | △ 아카이브 CTA는 있으나 검색=편집기 진입으로 수렴 |
| 연결 | ✗ 검색 결과에 연결 맥락 없음 |

### 성격

**발견 + 등록 허브** — 탐험이 아니라 「찾아서 열기/담기」

### UX 불일치

- TopBar 「Ctrl K」표시 ≠ 실제 단축키 미연결
- 홈 프리뷰 정책과 검색 정책 불일치 (Work: 홈=프리뷰, 검색=워크벤치)

---

## 경로 3: Preview Panel

### 코드 경로

`HomeDashboardView._handleItemTap` (Work만) → `DashboardPreviewPanel`

### 사용자가 보는 것

포스터, 메타, **상세 정보 >**, 링크 기반 주요 인물·연결 작품, 태그 칩(비클릭)

### 사용자가 할 수 있는 것

- 닫기, 상세 정보 → 워크벤치
- 이웃 인물/작품 탭 → 엔티티 워크벤치 또는 프리뷰 대상 교체

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 발견 | ✅ peek 후 깊이 선택 |
| 연결 | ✅ (링크 있을 때) |
| 기록 | ✗ 없음 — 의도적 |

### 성격

**유일한 「탐험 중간층」** — 그러나 홈 대시보드에만 존재

### 단절

- 탐색 그리드, 검색, 서재, 컬렉션에는 **프리뷰 없음**
- 워크벤치 탭 열리면 browse(프리뷰 포함) 전체 가려짐

---

## 경로 4: Workbench (Work)

### 코드 경로

`openBrowseItem` / 검색 / 그래프 「열기」 → `WorkbenchController.openWork` → `WorkDetailWorkspace`

### 레이아웃

`[탭 레일] | [Info Panel] | [Sanctum: 보기|본문|.md]`

### 사용자가 보는 것

- **Info:** 포스터, 제목, 평점, 상태, 태그, 링크 이웃, incoming, same-day
- **Sanctum:** 마크다운 감상·기록, wiki 링크 편집/탭

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 기록 | ✅✅ 핵심 |
| 연결 | △ incoming·이웃·wiki — **편집기 안에 묻힘** |
| 발견 | △ same-day·incoming이 탐색 역할 가능하나 UI는 목록 |

### 성격

**데이터 관리·아카이브 중심** — 「작품 정보 + 메타데이터 + 편집」

### 숨김

- Entity 연결 삽입: 마크다운 툴바/슬래시 — 온보딩 없음
- 글로벌 Work 미저장 상태에서 나가면 기록 유실 위험

---

## 경로 5: Entity

### 코드 경로

홈(Entity 카드), 검색, 컬렉션, wiki 탭, 그래프, Records Entity 탭, 최근 탐색

### 레이아웃

Work와 대칭: `EntityDetailInfoPanel` + Sanctum(journal)

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 기록 | ✅ journal |
| 연결 | △ wiki, incoming |
| 발견 | △ 갤러리·컬렉션에서 진입 |

### 성격

Work와 동일 — **엔티티 시트 편집기**

### 단절

- 홈 Work는 프리뷰, Entity는 **즉시 편집기** — 정책 비대칭
- Person/Event/Concept는 UI에 있으나 ROADMAP은 「Phase 3 미착수」

---

## 경로 6: Collection

### 코드 경로

`selectCollectibleCollection` → `CatalogEntityBrowseView` + `CollectibleCollection`

### 모드

- **curated:** 수동 멤버 + reorder
- **filter:** `tagsAll`, `kinds`, `relatedWorkId` (Cast)

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 발견 | △ 갤러리 브라우즈 |
| 연결 | ✅ filter+`relatedWorkId`는 링크 그래프 활용 |
| 기록 | ✗ 큐레이션 메타 |

### 성격

**큐레이션 도구** — 탐험보다 「내가 만든 집합」

---

## 경로 7: Knowledge Graph

### 코드 경로

`goKnowledgeGraph()` → `KnowledgeGraphView` (볼트 작품 리스트 + 연결 수 + ExpansionTile)

### 비전 정합성

| 항목 | 평가 |
|------|------|
| 연결 | ✅ 링크 인덱스 기반 |
| 발견 | △ 리스트 탐색 |
| 기록 | ✗ |

### 성격

**카피는 그래프, 구현은 연결 목록** — 기대치 붕괴 위험

### 단절

- 하단 네비에 없음
- wiki 링크 없는 작품은 「연결 없음」만 표시 — 다음 행동 유도 없음

---

## 부가 경로: Timeline / Records

`selectTimeline()` → `RecordsView` (타임라인 | 메모 | Entity)

- ROADMAP Phase 4 「미착수」와 불일치 — **구현됨**
- 사이드바·빠른 액션에서만 진입; 하단 탭 선택 표시 없음

---

## 경로별 요약 매트릭스

| 경로 | 보임 | 할 수 있음 | 기록 | 연결 | 발견 | 성격 |
|------|------|------------|------|------|------|------|
| Home | 5섹션 대시보드 | peek/전환 | △ | △ | △ | 관리+탐험 혼합 |
| Search | Fusion 다이얼로그 | 열기/담기/추가 | △ | ✗ | ✅ | 발견 허브 |
| Preview | 320px 패널 | peek→상세 | ✗ | △ | ✅ | 탐험 층 (홈만) |
| Work WB | 3+4열 편집기 | 저장·링크 | ✅ | △ | △ | **관리** |
| Entity WB | 3+4열 편집기 | journal·링크 | ✅ | △ | △ | **관리** |
| Collection | 갤러리 | 큐레이션 | ✗ | △ | △ | 큐레이션 |
| Graph | 연결 리스트 | 펼쳐보기 | ✗ | △ | △ | 연결 목록 |

---

## 문서 vs 코드 갭 (SSOT 정합)

| 문서 주장 | 코드 실태 |
|-----------|-----------|
| Phase 3 Entity 미착수 | Person/Event/Place/Concept/Org **동작** |
| Phase 5 Connection 미착수 | `[[wiki]]`, link index, neighbors **동작** |
| Phase 4 Timeline 미착수 | `RecordsView` **동작** |
| 홈 = 카탈로그 탐색 | 프리미엄 5섹션 + 프리뷰 + 이중 네비 |
| 지식 그래프 v1.1 | flag on, **리스트 UI** |

→ **문서 갱신 필요** (본 Sprint는 UX만; 구현 변경 없음)

---

## 핵심 UX 불일치 (Flow 관점)

1. **이중 네비게이션** — 사이드바 vs 하단 탭 (그래프·타임라인은 사이드바만)
2. **클릭 정책 비대칭** — Home Work=프리뷰, Entity/Search=워크벤치
3. **연결 기능의 매몰** — wiki 링크·incoming·그래프가 편집기/사이드 메뉴에 묻힘
4. **카피 vs 구현** — 발견의 여정, 그래프 Beta, Ctrl K
5. **AppBar 도구 단절** — 홈에서 기록·동기화·발견 도구 접근 불가

---

*다음: [HOME_DASHBOARD_REDESIGN.md](./HOME_DASHBOARD_REDESIGN.md)*
