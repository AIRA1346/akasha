# R3-B Knowledge Exploration Audit

> **갱신:** 2026-06-22
> **범위:** P0–P7 UX Recovery Sprint 이후 실측
> **방법:** `lib/` 코드 추적만. 런타임 테스트·추측 없음.
> **SSOT:** [PROJECT_CONSTITUTION.md](../PROJECT_CONSTITUTION_STUB.md) — 문화 지식 그래프 기반 개인 지식 우주

---

## 검증 질문

P0–P7 이후 AKASHA가 **「문화 지식 그래프 기반 개인 지식 우주」**를 얼마나 전달하는가?

---

## 1. 실제 앱 흐름 분석 (코드 추적)

### 1.1 기준 경로: Home → … → Knowledge Graph

```
HomeDashboardView
  └─ HomeDashboardContinueSection.onItemTap
       └─ home_dashboard_view._handleItemTap
            └─ onPreviewWork / onPreviewEntity
                 └─ home_shell_controller.openWorkPreview / openEntityPreview
                      └─ home_shell_body: DashboardPreviewPanel | EntityDashboardPreviewPanel
                           (조건: workPreviewItem|entityPreviewItem != null && !workbench.hasOpenDetail)

Work Preview — 연결 탭
  └─ WorkLinkNeighborsSections.onOpenEntity
       └─ onPreviewEntity → openEntityPreview
            (openEntityPreview 시 workPreviewItem = null — Work 프리뷰 닫힘)

Entity Preview — 기록
  └─ onOpenDetail → openEntityFromPreview
       └─ closeAllPreviews + workbenchCoord.openEntity
            └─ EntityDetailWorkspace (프리뷰 패널 숨김: hasOpenDetail)

Preview / Workbench — 그래프
  └─ onGoKnowledgeGraph → navigation.goKnowledgeGraph
       └─ isKnowledgeGraphMode = true, workbench.showBrowse()
            └─ KnowledgeGraphView (browseContent 교체)
```

### 1.2 경로별 코드 앵커

| 단계 | 진입 | 핸들러 | 결과 |
|------|------|--------|------|
| Home | `HomeDashboardView` | `home_dashboard_view.dart` L73–98 | 4섹션 렌더 |
| Continue | 카드 탭 | `_handleItemTap` → `onPreviewWork` / `onPreviewEntity` | Preview 패널 |
| Work Preview | 우측 320px | `dashboard_preview_panel.dart` | `fetchWorkLinkNeighbors` + `WorkLinkNeighborsSections` |
| Person 탭 | 인물 아바타 | `onOpenEntity` → `onPreviewEntity` | Entity Preview (Work Preview **교체**) |
| Entity Preview | 우측 320px | `entity_dashboard_preview_panel.dart` | `fetchEntityLinkNeighbors` + `EntityLinkNeighborsSections` |
| Workbench | `기록하기 >` | `openWorkFromPreview` / `openEntityFromPreview` | `closeAllPreviews` + Workbench 탭 |
| Graph | `연결 맵에서 보기` | `goKnowledgeGraph` (`home_navigation_coordinator.dart` L172–180) | 메인 영역 → `KnowledgeGraphView` |

### 1.3 「새 연결 발견」이 이어지는가?

**이어지는 경우 (코드상 연결됨)**

| 조건 | 경로 |
|------|------|
| `[[wiki]]` 링크가 이미 존재 | Home 「오늘의 연결」→ Preview → 이웃 탭 → 다른 Preview |
| 탐색 그리드·컬렉션·그래프 | `onPreviewWork` / `onPreviewEntity` → Preview 이웃 |
| Work Preview에 연결 데이터 있음 | `WorkLinkCharacterRow` / `WorkLinkConnectedWorksList` 탭 체인 |

**끊기는 경우 (코드상 확인)**

| 지점 | 원인 | 파일 |
|------|------|------|
| Work → Entity Preview 전환 | `openEntityPreview`가 `workPreviewItem = null` 설정 — **동시에 두 노드 컨텍스트 불가** | `home_shell_controller.dart` L429–433 |
| Workbench 진입 | `hasOpenDetail == true` → Preview 패널 **미렌더** | `home_shell_body.dart` L415–437 |
| Workbench 내 연결 탭 | `_openLinkedEntity` → `handleWikiLinkTap` → `workbenchCoord.openEntity` (**Preview 우회**) | `work_detail_workspace.dart` L164–171, `home_shell_controller.dart` L275–285 |
| 링크 0건 | Preview 빈 섹션에 CTA 없음 (Work); Graph·Today's Links에 행동 버튼 없음 | §3, §5 |
| Entity 0건 | Entity Preview·오늘의 연결(인물)·Entity 체인 **진입 불가** | cold start §5 |
| Entity Workbench | `EntityDetailInfoPanel`에 **연결 이웃 섹션 없음** (incoming만) | `entity_detail_info_panel.dart` |

### 1.4 헌법 5대 엔티티 vs UI 노출

| 타입 | 이웃 조회 (`fetchWorkLinkNeighbors` / `fetchEntityLinkNeighbors`) | Preview 섹션 |
|------|---------------------------------------------------------------------|--------------|
| Work | ✅ | 연결된 작품 |
| Person | ✅ | 주요 인물 / 연결된 인물 |
| Event | ✅ | 관련 사건 |
| Concept | ✅ + tags | 관련 개념 |
| **Place** | ❌ switch default | ❌ |
| Organization | ❌ | ❌ |

`EntityAnchorType.place`는 헌법·검색 카피(`home_dashboard_top_bar.dart` L36)에 있으나 이웃 UI에는 미포함.

---

## 2. Knowledge Graph UX Audit

**파일:** `knowledge_graph_view.dart` (주석: v1.1 **리스트형**)

### 2.1 「지식 그래프」처럼 느껴지는가?

| 항목 | 코드 사실 | 평가 |
|------|-----------|------|
| 시각 형태 | `ListView` + `ExpansionTile` per work. 노드·엣지 렌더링 없음 | **그래프 아님**. 카피는 「지식 연결 맵」으로 정직함 (L110–121) |
| 정렬 | `_linkCounts` 내림차순 → 제목 (L92–98) | 연결 밀도 우선 탐색 의도는 있음 |
| 진입 | 사이드바 「그래프」(`dashboard_sidebar.dart` L281–287), Preview/Workbench 「연결 맵에서 보기」 | 다중 진입점 |
| Feature flag | `FeatureFlags.showKnowledgeGraph = true` | 노출됨 |

### 2.2 연결 구조 가시성

- **Work 중심:** 볼트 `vaultItems` 전체를 행으로 나열. Entity는 Work 타일 **펼침 후** `WorkLinkNeighborsSections`로만 등장.
- **전역 구조:** Work↔Work, Person↔Event 등 **한 화면에 보이는 그래프 없음**.
- **연결 수:** subtitle `연결 N개` / `연결 없음 · 기록에서 [[링크]] 추가` (L189–198).

### 2.3 Work ↔ Person ↔ Event ↔ Concept 탐색

| 전환 | Graph 내 동작 |
|------|---------------|
| Work → Person | ExpansionTile 펼침 → `onOpenEntity` → **Preview** |
| Person → Work | Preview `onOpenWork` |
| Event / Concept | `ActionChip` → Preview |
| Person → Event (직접) | **Graph에 없음**. Preview 체인에만 존재 |
| Entity-only 진입 | Graph에 Entity 루트 행 **없음** |

### 2.4 Preview와 역할 중복

| | Preview (`dashboard_preview_panel`) | Graph (`knowledge_graph_view`) |
|--|-------------------------------------|--------------------------------|
| 데이터 | `fetchWorkLinkNeighbors` | 동일 함수 (펼침 시) |
| UI | `WorkLinkNeighborsSections` | 동일 위젯 |
| 차이 | 포스터·메타·기록하기 CTA | Work 목록·연결 수·정렬 |
| 컨텍스트 | 단일 Work 포커스 | 볼트 전체 스캔 |

**판정:** 데이터·위젯 **중복**. Graph는 「전체 목록 + 밀도 정렬」, Preview는 「단일 노드 깊이」—역할 분리는 약하고 컴포넌트는 공유.

### 2.5 Empty State

| 상태 | UI | CTA |
|------|-----|-----|
| 볼트 비음 | `볼트에 작품이 없습니다.` (L134) | 없음 |
| 연결 0 | subtitle 안내 문구 | **버튼 없음** — Preview/Workbench 이동 유도 없음 |
| 펼침 전 | `펼쳐서 연결을 불러오세요.` (L231) | 없음 |
| 펼침 후 링크 0 | `WorkLinkNeighborsSections` 빈 섹션 (`onLinkCta` **미전달**) | CTA 없음 |

### 2.6 Link Density 낮을 때

- 10작품·연결 0: 전 타일 동일 subtitle, 정렬은 제목순.
- **밀도 시각화 없음** (히트맵·클러스터·하이라이트 없음).
- 연결 많은 Work를 찾는 유일한 힌트: subtitle 숫자 + 정렬.

---

## 3. Preview Layer Audit

### 3.1 Work Preview (`dashboard_preview_panel.dart`)

| 항목 | 코드 사실 |
|------|-----------|
| 레이아웃 | 320px, 포스터 180×260, 제목·작자·연도 |
| CTA 순서 | ① `기록하기 >` (Filled, L154–170) ② 연결 섹션 ③ `연결 맵에서 보기` (Outlined) |
| 정보 밀도 | 메타 3행(장르·원작·평점) + 연결 4섹션. 포스터가 세로 공간 **~40%** |
| 연결 따라가기 | 인물: 1탭 → Entity Preview. 작품: 1탭 → Work Preview 교체 |
| 빈 연결 CTA | `WorkLinkNeighborsSections`에 `onLinkCta` **미전달** → 빈 메시지만, 버튼 없음 (L200–205) |
| Workbench 타이밍 | `기록하기 >`만 Workbench 진입. 연결 탐색은 Preview 내 완결 |

### 3.2 Entity Preview (`entity_dashboard_preview_panel.dart`)

| 항목 | 코드 사실 |
|------|-----------|
| 레이아웃 | 320px, 아바타 120×120, 제목·별칭·**entityId 노출** (L160–163) |
| CTA 순서 | ① `기록하기 >` ② incoming 수 (있을 때) ③ 연결 4섹션 ④ 연결 맵 |
| 빈 연결 CTA | `onRecordCta: widget.onOpenDetail` → **Workbench 직행** (L203) |
| incoming 0 | incoming 행 **숨김** (`entity_link_neighbors_sections.dart` L56) |
| Work Preview 대비 | Entity는 빈 CTA가 있으나 Workbench로 보냄 — 탐색 계층 이탈 |

### 3.3 「편집 전 탐험 공간」 역할 수행 여부

| 기준 | Work Preview | Entity Preview |
|------|--------------|----------------|
| 편집 UI 없음 | ✅ | ✅ |
| 연결 구조 선행 | ✅ (링크 있을 때) | ✅ (journal·discovery 있을 때) |
| 링크 없을 때 다음 행동 | ⚠️ 메시지만 | ⚠️ 기록하기 → Workbench |
| Workbench 대칭 | Workbench에도 연결 섹션 상단 (`work_detail_info_form.dart` L121–128) | Workbench에 연결 섹션 **없음** |
| 탐험 체인 | Preview 간 체인 가능 | Work Preview와 **상호 배타** |

**판정:** P4로 Entity도 Preview 계층에 편입되었으나, **Work와 대칭이 완전하지 않고**, Workbench 진입 시 탐험 UI가 Work만 유지된다.

### 3.4 연결 따라가기 비용

| 동작 | 탭/클릭 수 |
|------|------------|
| Home Work → Person Preview | 2 (카드 + 인물) |
| Person → 다시 Work 맥락 | Work Preview **소실** — 사이드바 최근 탐색 또는 재검색 필요 |
| Graph Work → Person Preview | 3 (사이드바 그래프 + 펼침 + 인물) |
| Workbench 연결 → Entity | 1탭이나 **Workbench 직행** (Preview 우회) |

---

## 4. Home Audit (4섹션)

**파일:** `home_dashboard_view.dart` — 환영·빠른액션 **미포함** (P5 완료)

### 4.1 섹션별 역할

| 섹션 | 데이터 소스 | 탭 동작 | 빈 상태 |
|------|-------------|---------|---------|
| **계속 탐험하기** | `RecentExplorationStore` → `resolveRecentExplorationItems` | Preview | 문구 + `검색으로 탐험 시작` 버튼 (`home_dashboard_continue_section.dart` L44–52) |
| **오늘의 연결** | `fetchWorkLinkNeighbors` on recent vault works, max 3 | Preview | 문구만, **버튼 없음** (L107–114) |
| **최근 발견** | `vaultItems` by `addedAt`, max 4 | Preview | 문구만 (L32–36) |
| **최근 기록** | `review` or `filePath` 있는 작품 | Preview (Work만) | 문구만 (L32–36) |

### 4.2 「다음 탐험」 유도 평가

| 신호 | 판정 |
|------|------|
| 계속 탐험 + 검색 CTA | ✅ 명시적 |
| 최근 발견 (볼트 작품) | ✅ cold vault에 작품만 있어도 진입 가능 |
| 오늘의 연결 | ⚠️ 링크 필요 — 0이면 정적 안내만 |
| 최근 기록 | ⚠️ 기록 필요 — 신규 사용자에겐 빈 섹션 |
| TopBar 검색 | ✅ (`onSearch` 탭) |
| 하단 FAB 검색 | ✅ (`home_shell_scaffold.dart` L310–337) |

### 4.3 통계·관리·중복 위젯

| 요소 | 파일 | 홈 노출 | 성격 |
|------|------|---------|------|
| `explorationProgress` 진행률 바 | `home_dashboard_continue_section.dart` L107–238 | ✅ | **기록·태그 휴리스틱** — 그래프 탐험 깊이 아님 (`exploration_progress.dart`) |
| 볼트 설정 | `home_dashboard_top_bar.dart` L62–68 | ✅ | 관리 |
| 프로필 이미지 (네트워크) | `home_dashboard_top_bar.dart` L70–89 | ✅ | 장식 |
| `Ctrl K` 배지 | `home_dashboard_top_bar.dart` L47–54 | ✅ | **홈 Shell에 Ctrl+K 단축키 바인딩 없음** (`home_shell_scaffold.dart` L35–41은 Tab만). 검색은 **탭**으로만 열림 |
| 사이드바 홈/탐색/라이브러리/컬렉션/그래프/타임라인 | `dashboard_sidebar.dart` | ✅ | 홈 4섹션과 **IA 중복** |
| 하단 탭 5개 | `home_shell_scaffold.dart` L295+ | ✅ | 사이드바와 **이중 네비** |
| `TodayRecallCard` | `home_shell_body.dart` L335–338 | ❌ (`showRecallCard=false`) | — |
| 환영·빠른액션 | `home_dashboard_welcome_header.dart` 등 | ❌ (미사용) | P5 제거됨 |

### 4.4 섹션 간 중복

- **계속 탐험 vs 최근 발견:** 전자는 탐색 **이력**(SharedPreferences), 후자는 볼트 **추가 시각**. 데이터 소스 다름. 사용자 입장에서는 둘 다 「최근 본 것」으로 읽힐 수 있음.
- **최근 발견 vs 최근 기록:** 발견=전체 추가, 기록=review/filePath 필터. 작품 겹칠 수 있음.

---

## 5. Cold Start Audit

**가정:** 작품 10개 · 엔티티 0개 · `[[wiki]]` 링크 0개 · 탐색 이력 없음

### 5.1 화면별 경험

| 화면 | 경험 | Dead End? |
|------|------|-----------|
| **Home — 계속 탐험** | 빈 + 검색 CTA | ❌ |
| **Home — 오늘의 연결** | `[[wiki]] 링크로…` 문구만 | ⚠️ CTA 없음 |
| **Home — 최근 발견** | 4작품 카드 → Preview | ❌ |
| **Home — 최근 기록** | 빈 안내 | ⚠️ |
| **Work Preview** | 4빈 연결 섹션, `기록하기 >`만 | ⚠️ 링크 만드는 법 Preview에서 안내 안 됨 |
| **Entity Preview** | **도달 불가** | — |
| **Knowledge Graph** | 10행, 모두 연결 0 subtitle | ⚠️ 행동 버튼 없음 |
| **Entity Browse** | `아카이브된 Entity가 없습니다` + `아카이브에 추가` (`catalog_entity_browse_view.dart` L381–407) | ❌ (엔티티 생성 유도) |
| **Entity discovery strip (compact)** | `_entriesEmpty` → `SizedBox.shrink()` (L382) | **완전 숨김** — 존재 자체를 모름 |
| **Explore 그리드** | Work 탭 → Preview | ❌ |
| **Personal Library** | Work 탭 → **Workbench 직행** (`home_browse_coordinator.dart` L109–111) | 관리 맥락 (의도적) |

### 5.2 Dead End TOP (cold start 코드 기준)

1. **오늘의 연결** — 링크 0이면 안내만, 다음 행동 없음
2. **Work Preview 빈 연결** — `onLinkCta` 미배선, `기록하기`만 노출
3. **Graph 전체 연결 0** — subtitle 외 상호작용 없음
4. **Entity 체인 불가** — 엔티티 0이면 Person/Event/Concept 탐험 경로 전무
5. **계속 탐험 빈 상태** — 볼트에 10작품 있어도 이력 없으면 빈 (최근 발견과 분리)

### 5.3 첫 「연결 발견」까지 최소 경로 (코드상)

```
최근 발견 카드 탭 → Work Preview → 기록하기 > → Workbench Sanctum
  → [[wiki]] 수동 입력 (마크다운 툴바/슬래시, workbench 내)
  → 저장 후 link_index 반영 → 홈 「오늘의 연결」·Preview 이웃·Graph에 데이터 표시
```

**판정:** 엔진은 있으나, cold start에서 「연결 발견」은 **기록 작성·위키 문법**에 의존. Preview/Graph/Home은 그 결과를 **소비**할 뿐, 링크 **생성**을 탐험 흐름에 넣지 않음 (Workbench Sanctum 예외).

---

## A. 현재 UX 평가 (P0–P7 이후)

| 축 | 점수 | 근거 |
|----|------|------|
| **탐험 계층 (Preview)** | **B** | Work·Entity 검색/홈/그리드/그래프 → Preview 통일 (P4). Workbench·Wiki는 예외 |
| **연결 가시성** | **C+** | 이웃 섹션·오늘의 연결·Graph 리스트 존재. 링크 0·Place·전역 구조 약함 |
| **지식 그래프 메타포** | **D+** | Graph는 리스트; 카피는 「연결 맵」. 체감은 카탈로그+이웃 목록 |
| **홈 IA** | **B−** | 4섹션 단순화 (P5). 이중 네비·진행률 휴리스틱·섹션 간 중복 잔존 |
| **Cold start** | **C−** | 최근 발견·검색 CTA는 있음. 링크 0 구간 Dead End 다수 |
| **헌법 정합 (Explore)** | **C** | Work→Person 체인은 Preview에서 가능. Place·Entity 루트·그래프 구조는 미달 |

**총평:** P0–P7은 「관리 앱 → 탐험 앱」 **방향 전환**에 성공. Preview 계층·홈 IA·빈 CTA 일부가 개선됨. 그러나 **「개인 지식 우주」 체감**은 여전히 「작품 카드 + 이웃 목록 + 기록기」에 가깝고, 그래프·밀도·cold path·Entity Workbench 비대칭이 비전과 거리를 둠.

---

## B. 비전과의 거리

**헌법 비전:** 작품에서 인물·사건·장소·개념으로 **확장·연결**되는 문화 지식 그래프.

| 비전 요소 | 현재 UI | 거리 |
|-----------|---------|------|
| 그래프 **구조** 보기 | Work 리스트 + 펼침 | 큼 |
| 노드 간 **걸어가기** | Preview 1단계 체인 (Work↔Entity 교체식) | 중간 |
| **발견** (링크 없을 때) | Dead End / Workbench 위임 | 큼 |
| 5대 Entity | Place·Organization UI 누락 | 중간 |
| 기록 vs Entity 분리 | Preview=탐험, Workbench=편집 원칙은 있음 | 작음 (방향 맞음) |
| 개인 **우주** (전체 조망) | Graph·Home 모두 로컬 볼트 스코프, 전역 맵 없음 | 큼 |

---

## C. 가장 큰 UX 병목 TOP 5

| # | 병목 | 코드 근거 | 비전 영향 |
|---|------|-----------|-----------|
| **1** | **Graph가 그래프가 아님** — Work 리스트, Entity 루트 없음 | `knowledge_graph_view.dart` | 「지식 우주」 메타포 붕괴 |
| **2** | **링크 0 = 탐험 종료** — Preview·Graph·오늘의 연결에 생성 CTA 부재/약함 | §3.1, §2.5, `home_dashboard_todays_links_section.dart` | 발견 축 단절 |
| **3** | **Preview ↔ Workbench 정책 불일치** — Preview는 탐험, Workbench 연결·Wiki는 Workbench 직행 | `handleWikiLinkTap`, `_openLinkedEntity` | 탐험 리듬 파괴 |
| **4** | **Entity Workbench에 연결 UI 없음** — Preview에서만 이웃 | `entity_detail_info_panel.dart` vs `entity_dashboard_preview_panel.dart` | Entity 축 약화 |
| **5** | **Cold start: 계속 탐험 ≠ 볼트 내용** — 10작품 있어도 이력 없으면 빈 | `RecentExplorationStore` vs `vaultItems` | 첫 세션 이탈 |

---

## D. 구현 난이도 대비 효과 (ROI)

> UX 계층·카피·배선만 가정. Discovery/Pipeline/Schema 변경 없음.

| 순위 | 개선 | 난이도 | 효과 | 근거 |
|------|------|--------|------|------|
| **1** | Work Preview 빈 연결에 `onLinkCta` → `openWorkFromPreview` + Sanctum 포커스 (Workbench 패턴 재사용) | **낮음** | **높음** | `dashboard_preview_panel.dart` 1줄 배선; `work_detail_info_form`已有 패턴 |
| **2** | 오늘의 연결·Graph·최근 발견/기록 빈 상태에 **검색/기록하기** 통일 CTA | **낮음** | **높음** | `home_dashboard_continue_section` 패턴 복제 |
| **3** | Workbench Wiki·연결 탭 → `openEntityPreview` / `openWorkPreview` (탐험 정책 통일) | **중간** | **높음** | `handleWikiLinkTap` 분기; Records는 유지 |
| **4** | Entity Workbench Info에 `EntityLinkNeighborsSections` 승격 | **중간** | **중간** | Workbench 대칭; Preview와 중복이나 편집 중 탐험 유지 |
| **5** | Graph 카피·빈 상태를 「연결 맵」에 맞게 정비 + 현재 Work 하이라이트 (Preview에서 진입 시) | **중간** | **중간** | 기대치 조정 + 맥락 유지 |
| **6** | 계속 탐험 cold fallback → `vaultItems` 최근 N (이력 없을 때) | **낮음** | **중간** | `home_dashboard_continue_section` |
| **7** | 실제 그래프 시각화 | **높음** | **높음** (장기) | v1.1 리스트 주석 — 스코프 외 가능성 |

---

## E. 다음 Sprint 우선순위 (제안)

**전제:** Constitution Explore·Link·Discovery 축. 데이터 구조 변경 없음.

| 우선순위 | 테마 | 항목 |
|----------|------|------|
| **S1** | Cold path · Empty state | Work Preview `onLinkCta` · 오늘의 연결/Graph 빈 CTA · 계속 탐험 vault fallback |
| **S2** | Navigation consistency (잔여) | Workbench·Wiki → Preview · Entity Workbench 연결 섹션 |
| **S3** | Graph honesty | 「연결 맵」IA 정리, Preview→Graph 컨텍스트(현재 Work 스크롤), Place 이웃 섹션 검토 |
| **S4** | Home polish | 진행률 바 의미 정리 또는 제거 · Ctrl+K 배선 또는 배지 제거 · 섹션 카피 차별화 |
| **S5** | 비전 (장기) | Entity 루트 Graph 행 · 2-hop 이상 탐험 · 시각 그래프 (별 스프린트) |

---

## 부록: P0–P7 완료 항목 vs 잔여 갭

| Sprint | 완료 (코드 확인) | 잔여 갭 |
|--------|------------------|---------|
| P0 | Workbench 연결 상단 (`work_detail_info_form.dart`) | Entity Workbench 미적용 |
| P1/P5 | 홈 4섹션 (`home_dashboard_view.dart`) | 이중 네비, 진행률 휴리스틱 |
| P2/P4 | Preview 우선 탐색 (Work·Entity) | Workbench/Wiki 직행 |
| P3 | Graph 진입 버튼 다수 | Graph 자체는 리스트 |
| P7 | Entity Preview 빈 CTA, Graph subtitle | Work Preview 빈 CTA, Today's Links |

---

*본 문서는 코드 정적 분석 산출물이며, 런타임 스크린샷·사용자 테스트는 포함하지 않습니다.*
