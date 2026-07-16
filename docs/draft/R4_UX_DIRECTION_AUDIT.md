# R4 UX Direction Audit

> **일자:** 2026-06-22  
> **범위:** R3-A ~ R3-G 완료 시점 · 코드 수정 없음  
> **근거:** [PROJECT_CONSTITUTION.md](../history/closure-2026-07/PROJECT_CONSTITUTION_STUB.md), [CURRENT_STATE.md](../active/CURRENT_STATE.md), R3E/F/G/H Dogfood 문서, `lib/screens/home/` · `lib/features/workbench/` 코드 추적

---

## Executive Summary

R3 시리즈는 **탐험 이상 경로**(Home → Preview → Stack → Workbench → 저장 복귀)를 실질적으로 닫았다.  
그러나 **첫 30초·첫 10분** 체감은 여전히 「문화 콘텐츠 탐색·아카이브 앱」에 가깝고, 헌법이 말하는 **「개인 지식 우주」** narrative는 **루프 1회 완주 후**에야 형성된다.


| Audit Question             | 한 줄 답                                         |
| -------------------------- | --------------------------------------------- |
| Q1 — 30초 안에 무엇을 해야 하는 앱인지? | **아니오** (cold start)                          |
| Q2 — 가장 자주 보는 화면           | **Browse/Explore 그리드 + Preview 병치** (~50–55%) |
| Q3 — 정보 밀도 최고              | **Work Workbench** (4열 편집기)                   |
| Q4 — 「관리」로 느껴지는 요소         | Workbench·서재·볼트·필터·타임라인                       |
| Q5 — 「개인 지식 우주」 근접도        | **체감 55/100** (cold) → **72/100** (루프 완주 후)   |


---

## 현재 UX 상태

### 아키텍처 (한 화면 안)

```
[Sidebar 260px] | [WorkbenchShell: TabRail? + BrowseContent] | [Preview 320px?]
                     ↑ Home / Explore Grid / Graph / Library / Records
```

- **BrowseContent** = 홈 대시보드 · 글로벌/로컬 그리드 · Graph · 서재 · 컬렉션 · 타임라인
- **Preview** = `!workbench.hasOpenDetail` 일 때만 우측 고정 (`home_shell_body.dart` L444–472)
- **Workbench detail** = Preview **전면 가림** — 기록 모드 진입 시 탐험 패널 소실

### R3 완료 후 핵심 정책 (코드)


| 동작                     | API                                     | Stack          |
| ---------------------- | --------------------------------------- | -------------- |
| 새 탐험 (검색·탐색 그리드)       | `openWorkPreview` / `openEntityPreview` | clear          |
| Preview 이웃             | `previewLinked`*                        | push           |
| Home·Graph (Preview 中) | `navigate*Preview`                      | push (R3-F)    |
| Preview → 기록           | `open*FromPreview` + snapshot           | —              |
| 명시적 저장                 | `_maybeReturnToPreviewAfterSave`        | restore (R3-G) |
| 서재 그리드                 | `openBrowseItem`                        | Preview 우회     |


### Dogfood 루프 완성도 (R3-H 재확인)


| 프로필          | 추정     |
| ------------ | ------ |
| 빈 볼트         | 62–68% |
| 일반 (10–30작품) | 88–91% |
| 연결 밀집        | 90–93% |


---

## Audit Question 1

> 사용자가 AKASHA를 처음 실행했을 때 **「무엇을 해야 하는 앱인지」** 30초 안에 이해할 수 있는가?

### 판정: **아니오**

30초 안에 보이는 것(코드·카피 기준):


| 순서    | 사용자가 보는 것                             | 전달 메시지                                                                 |
| ----- | ------------------------------------- | ---------------------------------------------------------------------- |
| 0s    | 볼트 미연동 시 `HomeVaultBanner`            | 「데모용 샘플」→ **Sanctum Vault 폴더 연동** (`home_vault_banner.dart`)           |
| 0–5s  | 좌측 **Sidebar 260px** (기본 open)        | 대시보드 · 나만의 서재 · 컬렉션 · 기록 · 그래프 — **공간이 여러 개**                          |
| 0–5s  | 하단 **5탭**: 홈 · 탐색 · 검색(중앙) · 서재 · 컬렉션 | 탐색 vs 홈 vs 서재 **역할 중복**                                                |
| 5–15s | 홈 `HomeDashboardTopBar`               | 검색 placeholder + **Ctrl K** 배지 + 볼트 설정 (`home_dashboard_top_bar.dart`) |
| 5–30s | 홈 **4섹션** (스크롤 필요)                    | 계속 탐험 / 오늘의 연결 / 최근 발견 / 최근 기록 — **각각 다른 CTA**                         |


빈 볼트 첫 화면 CTA 분산:

- [검색으로 탐험 시작] (`home_dashboard_continue_section.dart`)
- `[[wiki]]` 안내 (`home_dashboard_todays_links_section.dart`)
- Sanctum 기록 안내 (`home_dashboard_recent_records_section.dart`)
- [폴더 연동] (배너)
- 하단 **탐색** 탭 → 10k 카탈로그 그리드 (로컬 0과 무관)

### 진입 흐름 추적 (Home · Browse · Search · Preview · Workbench)

```
┌─────────────────────────────────────────────────────────────────┐
│ COLD START (볼트 연동, 작품 0)                                    │
├─────────────────────────────────────────────────────────────────┤
│ 앱 기동 → goHome() → HomeDashboardView                           │
│   ├─ TopBar 탭 → openSearchDialog()                              │
│   ├─ 「검색으로 탐험 시작」→ openSearchDialog()                    │
│   ├─ 하단 탐색 → goExplore() → BrowseView (10k 그리드)            │
│   └─ 카드 탭 → openWorkPreview (replace) → Preview 320px           │
│         └─ 「기록하기 >」→ openWorkFromPreview → Workbench (Preview 가림) │
│               └─ md 저장 → Preview 복귀 (R3-G, snapshot 있을 때만) │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ SEARCH (모달)                                                     │
├─────────────────────────────────────────────────────────────────┤
│ openSearchDialog() → HomeDialogsFacade.showSearchDialog          │
│   ├─ 로컬 선택 → onPreviewLocalWork → openWorkPreview            │
│   ├─ 원격(Registry) → onPreviewLocalWork → openWorkPreview       │
│   ├─ Entity → onPreviewEntity → openEntityPreview                │
│   └─ catalog-only promote → Workbench 직행 (openEntity)          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ BROWSE (탐색 탭 / 필터 적용 그리드)                                │
├─────────────────────────────────────────────────────────────────┤
│ goExplore() → isExploreBrowseMode=true → BrowseView              │
│ 포스터 탭 → onPreviewWork (= openWorkPreview)  [탐색 모드]        │
│ 포스터 탭 → openBrowseItem  [나의 서재 모드]  ← Preview 우회        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ PREVIEW (우측 320px, browse와 병치)                               │
├─────────────────────────────────────────────────────────────────┤
│ 이웃 탭 → previewLinked* (push, ← 이전)                          │
│ Home/Graph 카드 (Preview 中) → navigate*Preview (push, R3-F)     │
│ 「기록하기 >」→ snapshot + closeAllPreviews + Workbench          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ WORKBENCH                                                       │
├─────────────────────────────────────────────────────────────────┤
│ 진입: openBrowseItem | open*FromPreview | Search promote | Graph │
│       「기록 열기」| incoming/same-day                           │
│ WorkDetailWorkspace: Info패널 + Sanctum md (4열)                   │
│ 명시적 저장 + snapshot 일치 → Preview+stack 복귀 + showBrowse()   │
│ Autosave (silent) → Workbench 유지                               │
└─────────────────────────────────────────────────────────────────┘
```

### 30초 이해 실패 요인

1. **단일 narrative 부재** — 「기록→연결→발견」 문장이 화면 어디에도 **한 줄로** 없음
2. **관리 어휘 선행** — Vault, Sanctum, md, catalog only, 볼트 설정
3. **Ctrl K** 표시 vs **Tab**만 동작 (`home_shell_scaffold.dart` L36–41)
4. **탐색 탭**이 글로벌 DB를 즉시 노출 — 「내 우주」가 아니라 「카탈로그」 인상
5. **서재** 하단 탭 → Workbench 직행 — 탐험 루프 **교과서와 다른** 진입

---

## Audit Question 2

> 현재 UI에서 사용자가 **가장 자주 보는 화면**은 무엇인가? (예상 사용 시간 비율)

### 추정 방법

- 진입점 빈도: `openWorkPreview` vs `openBrowseItem` vs `goHome`/`goExplore` 배선
- Preview 표시 조건: browse와 **병치** — 탐험 세션 중 **시각적 체류** 높음
- Workbench: 기록·편집 **burst** — R3-G 이후 Preview 복귀로 **체류 단축**
- R3-H Scenario B/C = **일반·밀집** 사용자를 기준 프로필로 가정

### 프로필 A — 일반 사용자 (작품 10–30, 탐험 루프 수행)


| 화면                                 | 추정 비율      | 근거                                                         |
| ---------------------------------- | ---------- | ---------------------------------------------------------- |
| **Browse / Explore 그리드**           | **28–32%** | `goExplore`, 필터 그리드, 홈 fallback 카드 — **발견 진입의 주 경로**       |
| **Preview Panel**                  | **22–28%** | 탐색·홈·Graph 연속 사용 시 browse **우측 상시**; Workbench detail 아닐 때 |
| **Home Dashboard**                 | **12–18%** | `goHome` 복귀·4섹션 스크롤; Preview와 **동시** 노출                    |
| **Workbench (detail)**             | **15–22%** | 기록 burst; R3-G로 Preview 복귀 → **비율 하향** (R3-E 대비)           |
| **Search (모달)**                    | **5–8%**   | 하단 중앙·TopBar·CTA — **짧지만 고빈도**                             |
| **Graph**                          | **3–6%**   | 사이드바 전용, 하단 탭 없음                                           |
| **Personal Library / Collections** | **4–8%**   | 서재 탭·사이드바 — Workbench 직행                                   |
| **Records / Timeline**             | **2–5%**   | 탐험 루프 **분리 축**                                             |


**합계 시각:** Browse+Home **중앙 영역 ~45%**, Preview **병치 ~25%**, Workbench **~18%**, 나머지 **~12%**

### 프로필 B — cold start / 관리 편향


| 화면                 | 추정 비율                     |
| ------------------ | ------------------------- |
| Browse/Explore 그리드 | **35–40%**                |
| Workbench          | **20–30%** (첫 기록·볼트 설정)   |
| Preview            | **10–15%** (연결 0 → 체류 짧음) |
| Home               | **10–15%**                |
| Search             | **8–12%**                 |


### 결론

**가장 자주 보는 단일 컴포넌트** = Browse/Explore **그리드**.  
**탐험 세션 중 실질 주력** = **그리드 + Preview 병치** (합산 **~50–55%**).  
Workbench는 **시간은 짧지만 인지 부하·전환 비용**이 커서 「주 화면」처럼 느껴진다.

---

## Audit Question 3

> 정보 밀도가 **가장 높은 화면**은 어디인가?

### 비교: Work Workbench · Entity Workbench · Preview Panel


| 기준                  | Work Workbench                                             | Entity Workbench           | Preview Panel               |
| ------------------- | ---------------------------------------------------------- | -------------------------- | --------------------------- |
| **클릭 수** (탐색 1 hop) | 높음 — 탭·패널·Sanctum·picker·저장                                | 높음 — 동일 + journal          | **낮음** — 이웃 1탭              |
| **스크롤**             | **3영역** — Info `SingleChildScrollView` + Sanctum + preview | **3영역** — Info + journal   | **1열** — 320px 세로           |
| **시선 이동**           | **좌→우 4열** (TabRail + Info + Editor)                       | **좌→우 3–4열**               | **단일 열** 상→하                |
| **중요 정보 위치**        | Sanctum **중앙**; 연결은 Info 패널 (R3-D P2)                      | 연결 Info **상단**; journal 우측 | 연결 **포스터·CTA 아래** (fold 아래) |
| **편집 가능 필드**        | **20+** (rating, status, tags, YAML, md…)                  | **15+**                    | **0** (read-only)           |
| **인지 모드**           | **관리·편집**                                                  | **관리·편집**                  | **발견·탐색**                   |


### 순위

1. **Work Workbench** — `WorkDetailWorkspace` 3열 Info + 4열 Sanctum (`work_detail_workspace.dart` 주석 L33); incoming·same-day·neighbors·form **동시 노출**
2. **Entity Workbench** — Info에 neighbors + incoming + metadata + journal (`entity_detail_info_panel.dart` L162+)
3. **Preview Panel** — 정보량은 중간이나 **320px·단일 스크롤**로 상대적으로 가벼움; 밀집 볼트에서 4 neighbor 섹션 **길어짐**

### Preview의 밀도 역설

- **절대 정보량**은 Workbench보다 낮음
- **탐험 핵심(연결)** 이 포스터·메타·「기록하기」 **아래** — 첫 viewport는 **아카이브 CTA**가 지배
- Entity Preview는 `entityId` **노출** (`entity_dashboard_preview_panel.dart` L189) — 개발자 밀도

---

## Audit Question 4

> 「발견」보다 **「관리」**로 느껴지는 요소는?

### 화면별 — 관리(Management) 체감


| 화면                   | 관리로 느껴지는 요소                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------- |
| **Home**             | 볼트 설정 아이콘; 「최근 **기록**」; Sanctum 카피; 데모/볼트 배너                                                |
| **Browse/Explore**   | 도메인·카테고리·상태 **필터**; 카탈로그 페이지네이션; 서재 DnD·테마                                                  |
| **Search**           | catalog propose; custom add; promote → Workbench                                            |
| **Preview**          | 「기록하기 >」 primary CTA; 평점·장르 **정적 메타** (CMS 카드 느낌)                                           |
| **Workbench**        | Tab rail; YAML frontmatter; md 편집; rating/workStatus/myStatus; incoming 경로 **관리**; autosave |
| **Personal Library** | curated reorder; IAP 테마 stub; **Workbench 직행**                                              |
| **Collections**      | collectible curation                                                                        |
| **Graph**            | 연결 **수** 정렬 리스트; ExpansionTile **펼치기** — 인벤토리 목록                                            |
| **Records/Timeline** | 감상 일기·캡처 — **기록 축**                                                                         |
| **Sidebar/AppBar**   | sync registry; vault settings; catalog inbox; clipboard import                              |
| **전역**               | `entityId`/`workId` 노출; 「catalog only」; `[[wiki]]` 문법                                       |


### 화면별 — 탐험(Discovery) 체감


| 화면          | 탐험으로 느껴지는 요소                             |
| ----------- | ---------------------------------------- |
| **Home**    | 「계속 **탐험**하기」; 「오늘의 **연결**」; 「최근 **발견**」 |
| **Browse**  | 포스터 그리드 → Preview (탐색 모드)                |
| **Preview** | 이웃 4섹션; `← 이전`; 「연결 맵에서 보기」              |
| **Graph**   | 연결 밀집 작품부터; neighbor 탭 → Preview push    |
| **Search**  | 10k 발견; Entity/Work **가벼운** 진입 (Preview) |
| **Stack**   | A→B→C 체인 + 저장 복귀 (R3-F/G)                |


### 균형 판정


| 축                   | 체감 우세             |
| ------------------- | ----------------- |
| **첫인상 (30s–10m)**   | **관리 65 : 발견 35** |
| **Scenario B 루프 중** | **발견 60 : 관리 40** |
| **기록·서재·설정 세션**     | **관리 80 : 발견 20** |


---

## Audit Question 5

> PROJECT_CONSTITUTION — **「개인 지식 우주」** 비전에 UX가 얼마나 가까운가? (기능 존재 ≠ 체감)

### 헌법 4축 × 사용자 체감


| 축                  | 기능 (코드)                            | 사용자 체감 | Gap                        |
| ------------------ | ---------------------------------- | ------ | -------------------------- |
| **발견 (Discovery)** | 10k 검색, Explore 그리드, Home fallback | ⭐⭐⭐⭐   | 카탈로그 DB 느낌 > 「내 우주」        |
| **기록 (Archive)**   | Workbench, Sanctum, Vault          | ⭐⭐⭐⭐⭐  | **과잉** — 탐험 narrative 가림   |
| **연결 (Link)**      | Preview/Workbench neighbors, Graph | ⭐⭐⭐    | `[[wiki]]`·방향 개념·리스트 Graph |
| **탐색 (Explore)**   | Preview Stack, Save Return         | ⭐⭐⭐⭐   | **이상 경로 한정**; 진입점 분산       |


### 「개인 지식 우주」 체감 점수


| 단계               | 점수 (/100) | 설명                                      |
| ---------------- | --------- | --------------------------------------- |
| 앱 첫 실행 (30s)     | **38**    | 탐색·볼트·데모·다중 nav — **우주**보다 **앱 조립**     |
| 빈 볼트 10분         | **45**    | 검색하면 Preview까지 가능; **연결·로컬 0 Dead End** |
| Scenario B 1회 완주 | **72**    | Stack·저장 복귀 — **한 바퀴 우주** 체험            |
| 밀집 볼트 장세션        | **78**    | Graph+Stack — **가장 헌법에 가까운** 프로필        |


### 헌법 Entity ≠ Record

- **코드:** Fact vs Record 분리 잘 됨
- **체감:** Preview에서 Work **하나의 카드**로 보임 — Entity/Record **계층 학습 전**에는 구분 불명

---

## 사용 흐름 분석

### 이상 경로 (R3가 설계한 Primary Loop)

```
발견(Home/Search/Explore)
  → Preview (가벼운 orient)
  → 연결 이웃 (Stack push)
  → 기록하기 → Workbench (burst)
  → md 저장 → Preview 복귀 (R3-G)
  → 새 이웃 → …
```

**완성도 ~91%** (R3-H) — 단, 사용자가 **스스로 이 경로를 찾아야** 함.

### 실제로 많이 타는 경로 (Dogfood 추정)


| #   | 경로                                 | 빈도  | 탐험 정합 |
| --- | ---------------------------------- | --- | ----- |
| 1   | 탐색 탭 → 그리드 → Preview               | 높음  | ✅     |
| 2   | 검색 → Preview                       | 높음  | ✅     |
| 3   | 홈 카드 → Preview → 이웃                | 중   | ✅     |
| 4   | **서재 → Workbench**                 | 중   | ❌     |
| 5   | Workbench 직접 (incoming/wiki)       | 중   | ⚠️    |
| 6   | Graph (sidebar) → expand → Preview | 중~저 | ✅     |
| 7   | 볼트 설정·sync·필터 조작                   | 저~중 | ❌     |


### 정책 불일치 (학습 필요)


| 진입                     | Preview   | Stack       |
| ---------------------- | --------- | ----------- |
| Explore/Search         | ✅ replace | clear       |
| Preview 이웃             | ✅         | push        |
| Home/Graph (Preview 中) | ✅         | push (R3-F) |
| **서재**                 | ❌         | —           |
| Wiki (Sanctum)         | replace   | clear       |
| Search promote Entity  | Workbench | —           |


---

## 관리 중심 요소 (요약)

1. Workbench 4열 편집기 + Tab rail
2. Sanctum / Vault / md / YAML 어휘
3. Personal Library · Collections curation
4. Filter sidebar + catalog sync AppBar
5. Records/Timeline 축
6. Graph = 정렬 **리스트** (맵 아님)
7. 볼트·데모 배너
8. entityId/workId UI 노출
9. Ctrl+K 미연결 (조작 **실패** = 관리 도구 느낌)
10. Autosave vs 명시적 저장 **이중 규칙**

---

## 탐험 중심 요소 (요약)

1. Home 4섹션 IA (계속 탐험 / 오늘의 연결 / 발견 / 기록)
2. Preview 320px + neighbor sections
3. Preview Stack + `← 이전`
4. Save → Preview Return (R3-G)
5. Home/Graph navigate push (R3-F)
6. WorkPreviewEmptyConnections CTA
7. Search → Preview (가벼운 진입)
8. Explore 그리드 → Preview
9. 「연결 맵에서 보기」 Graph 진입
10. Recent exploration (sidebar + 홈 fallback)

---

## 가장 큰 UX 문제 Top 10


| #      | 문제                                                       | 영향               | Q 연결       |
| ------ | -------------------------------------------------------- | ---------------- | ---------- |
| **1**  | **30초 value prop 부재** — 「무엇을 하는 앱」한 줄 설명 없음              | cold churn       | Q1, Q5     |
| **2**  | **이중 네비게이션** — Sidebar 260px + 하단 5탭                     | mental model 분산  | Q1, Q2     |
| **3**  | **용어 장벽** — `[[wiki]]`, Sanctum, Vault, catalog only, md | 비개발자 이탈          | Q1, Q4, Q5 |
| **4**  | **서재 → Workbench 직행** — Preview·Stack 우회                 | 루프 단절            | Q2, Q4     |
| **5**  | **Workbench 시각·인지 지배** — 기록 시 Preview 소멸                 | 「관리 앱」 인상        | Q3, Q4     |
| **6**  | **빈 볼트 Dead End** — 로컬 연결 0, CTA 분산                      | 첫 10분 이탈         | Q1, Q5     |
| **7**  | **Ctrl+K 표시·미동작**                                        | 신뢰 하락            | Q1         |
| **8**  | **Graph 접근성** — sidebar only, expand 클릭, 리스트≠맵           | 탐험 fatigue       | Q2, Q4     |
| **9**  | **Autosave ≠ 저장 복귀** — R3-G partial                      | 행동 규칙 혼란         | Q3         |
| **10** | **데모 배너 vs 빈 볼트** — 동시 mental model                      | onboarding noise | Q1         |


---

## R4 우선순위 후보

> **범위 결정용 후보** — 구현 상세는 R4 Planning Sprint에서 확정.  
> 헌법 필터: Discovery / Archive / Link / Explore 중 **≥1** 강화.


| 우선순위   | 후보                                              | 헌법 축               | 근거               |
| ------ | ----------------------------------------------- | ------------------ | ---------------- |
| **P0** | **First 30s narrative** — 홈 단일 hero + 다음 행동 1개  | Discovery, Explore | Q1 실패 직접 대응      |
| **P0** | **Ctrl+K → openSearchDialog**                   | Discovery          | D1 잔존, 저비용       |
| **P1** | **Navigation IA 정리** — 하단 vs sidebar 역할 분담      | Explore            | Q2 mental load   |
| **P1** | **서재 → Preview 정책 통일**                          | Explore, Link      | D2, 루프 일관성       |
| **P1** | **용어 비개발자화** (`[[wiki]]`→「링크」 등)                | Link, Explore      | Q4, R3-H         |
| **P2** | **빈 볼트 온�ording** — 볼트→검색→Preview 1줄 가이드        | Discovery, Archive | Scenario A       |
| **P2** | **Preview fold 재배치** — 연결 섹션 viewport 상향        | Link, Explore      | Q3               |
| **P2** | **Graph 진입·형태** — 하단/홈 CTA, expand friction     | Explore, Link      | Q2, Q8           |
| **P3** | **Workbench↔Preview 전환 체감** — 탭 레일 정리, 저장 UX 통일 | Archive, Explore   | Q3, autosave     |
| **P3** | **Entity/Record 체감 계층** — Preview 카피            | Link               | Q5 Entity≠Record |


---

## 구현 없이 해결 가능한 문제


| 문제         | 방법 (코드 변경 없음)                                 |
| ---------- | --------------------------------------------- |
| Audit 신뢰도  | Scenario B **수동 Dogfood** 1회 + 스크린샷 (R3-H 권장) |
| 팀 내 루프 공유  | 「Primary Loop」 **내부 사용 가이드** 1페이지             |
| 용어 혼란 (부분) | 테스트 시 **동의어 시트** (Sanctum=기록, Vault=볼트)       |
| 30초 실패 재현  | **5명 관찰 테스트** — 「이 앱은 무엇?」 질문만                |
| R4 범위 논쟁   | 본 Audit Top 10 **우선순위 투표**                    |
| Graph 기대치  | 「리스트 v1」 **릴리즈 노트** 명시 — 맵 기대 관리              |


**한계:** Ctrl+K, nav 구조, Preview 정책, Save/autosave 규칙 등 **코드·카피 변경 없이는** 체감 개선 불가.

---

## 구현이 필요한 문제


| 문제              | 최소 구현 방향 (R4 후보)                                             |
| --------------- | ------------------------------------------------------------ |
| Q1 30초 이해       | 홈 hero / cold start CTA **단일화**                              |
| D1 Ctrl+K       | `CallbackShortcuts`에 `LogicalKeyboardKey.keyK` + meta        |
| D2 서재 Preview   | `HomeBrowseCoordinator` personal mode `onOpenItem` → Preview |
| D6 이중 nav       | sidebar 항목 **이동·통합** 또는 bottom tab **역할 명확화**                |
| Q3 Preview fold | neighbor sections **layout reorder**                         |
| Autosave 혼란     | silent save UI feedback 또는 복귀 정책 **명시**                      |
| Graph friction  | lazy neighbors / 1-click expand                              |
| entityId 노출     | debug-only 또는 접기                                             |
| 빈 볼트 Dead End   | 로컬 0일 때 **글로벌 discovery** narrative 강화                       |


---

## 최종 평가

### R3 대비 R4 준비 상태


| 항목            | 상태                  |
| ------------- | ------------------- |
| 탐험 **이상 경로**  | ✅ 닫힘 (R3-F/G)       |
| **보편적** 탐험 UX | ❌ cold start·서재·nav |
| Dogfood 근거    | ✅ R3-H + 본 Audit    |
| R4 범위 결정 준비   | ✅                   |


### R4 방향 (한 줄)

> **「탐험가 루프」는 이미 있다 — R4는 그 루프를 앱의 첫 30초와 기본 진입으로 승격하는 Sprint여야 한다.**

### 성공 기준 (R4 Planning 입력)

R4 완료 후 재측정 시 목표:


| 지표                      | 현재       | R4 목표 (제안)                |
| ----------------------- | -------- | ------------------------- |
| Q1 — 30s 이해             | ❌        | ✅ (5/5 테스터 「기록·연결·발견」 언급) |
| cold start 우주 체감        | 38/100   | **≥55/100**               |
| Scenario A 루프           | 62–68%   | **≥75%**                  |
| Primary loop 진입 (서재 제외) | ~85% 진입점 | **≥95%**                  |


### Audit 결론

AKASHA는 **기능적으로는** 문화 지식 그래프·개인 볼트·연결 탐색을 갖췄으나, **UX narrative는** 여전히 **관리·아카이브 앱**이 먼저다.  
R3는 **「이미 알고 탐험하는 사용자」**를 위한 Sprint였고, **R4는 「처음 여는 사용자」에게 같은 루프를 default로 보여주는 Sprint**가 되어야 한다.

---

## 참고 — 코드 앵커


| 주제                          | 파일                                                                    |
| --------------------------- | --------------------------------------------------------------------- |
| Preview 표시 조건               | `home_shell_body.dart` L444–472                                       |
| 진입 API                      | `home_shell_controller.dart` L427–525                                 |
| Search 배선                   | `home_dialogs_coordinator.dart` L88–109                               |
| Browse Preview vs Workbench | `home_browse_coordinator.dart` L109–111                               |
| Bottom nav                  | `home_shell_scaffold.dart` L281–390                                   |
| Cold start 배너               | `home_vault_banner.dart`                                              |
| Workbench layout            | `work_detail_workspace.dart`, `workbench_shell.dart`                  |
| Preview layout              | `dashboard_preview_panel.dart`, `entity_dashboard_preview_panel.dart` |


---

## 관련 문서

- [R3E_DOGFOOD_AUDIT.md](./R3E_DOGFOOD_AUDIT.md)
- [R3F_PREVIEW_STACK_EXTENSION_AUDIT.md](./R3F_PREVIEW_STACK_EXTENSION_AUDIT.md)
- [R3G_SAVE_RETURN_AUDIT.md](./R3G_SAVE_RETURN_AUDIT.md)
- [R3H_DOGFOOD_VALIDATION.md](./R3H_DOGFOOD_VALIDATION.md)

