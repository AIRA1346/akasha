# R4 Planning Master Plan

> **일자:** 2026-06-22
> **지위:** R4 Sprint 범위 SSOT (Planning 전용 — 구현 전)
> **근거:** [PROJECT_CONSTITUTION.md](../PROJECT_CONSTITUTION_STUB.md), [CURRENT_STATE.md](../../../active/CURRENT_STATE.md), [R3H_DOGFOOD_VALIDATION.md](./R3H_DOGFOOD_VALIDATION.md), [R4_UX_DIRECTION_AUDIT.md](./R4_UX_DIRECTION_AUDIT.md)

---

## R4 한 줄 목표

> R3가 **닫은 탐험 루프**를 앱의 **첫 30초·기본 진입**으로 승격한다.

R3 = 「이미 탐험하는 사용자」를 위한 Sprint.
R4 = 「처음 여는 사용자」에게 **기록 → 연결 → 발견**이 default narrative가 되게 하는 Sprint.

---

## R4 목표 (헌법 정렬)

| # | 목표 | 헌법 축 |
|---|------|---------|
| G1 | **30초 안에** AKASHA가 「개인 지식 우주를 걸어 다니는 앱」임을 전달 | Discovery, Explore |
| G2 | **Cold Start**(볼트 0·작품 0)에서 Primary Loop 진입 **단일 경로** 제공 | Discovery, Explore |
| G3 | **Navigation IA** — Sidebar·Bottom·Preview·Workbench·Search **역할 분담** | Explore |
| G4 | R3-F/G 탐험 루프 **유지·강화** (Stack, Save Return) | Link, Explore, Archive |
| G5 | 「관리 앱」 첫인상 **완화** (용어·진입 정책) | Discovery, Link |

**R4가 하지 않는 것:** 새 Entity 타입, 타임라인 Phase, 시각 Graph, 검색 알고리즘, akasha-db 스키마.

---

## 성공 기준 (R4 종료 시 재측정)

### 정량 (Dogfood·관찰 테스트)

| 지표 | R3-H / R4 Audit baseline | R4 목표 |
|------|:------------------------:|:-------:|
| Q1 — 30s 「무엇을 하는 앱」 | ❌ | **5/5** 테스터가 「기록·연결·발견」 중 **≥2** 언급 |
| Cold Start 우주 체감 | 38/100 | **≥55/100** |
| Scenario A 루프 완성도 | 62–68% | **≥75%** |
| Primary Loop 진입 (의도적 Workbench 직행 제외) | ~85% | **≥95%** |
| Ctrl+K → 검색 | ❌ | ✅ |

### 정성 (Scenario B 1회)

- Home Hero → Search → Preview → 이웃 1hop **추가 설명 없이** 완주 가능
- 하단 탭만으로 「지금 어디」 설명 가능 (Sidebar 없이도)
- 서재 그리드 탭 시 Preview 경유 (P1 완료 시)

### 회귀 방지

- R3-F: Home/Graph Preview 中 push + `← 이전` — **유지**
- R3-G: Preview→Workbench→**명시적 저장**→Preview+stack — **유지**
- `flutter test` 기존 PASS 유지

---

## Sprint 범위

### In Scope — R4 (2 Phase)

| Phase | Sprint ID | 주제 | 산출 | 상세 |
|:-----:|-----------|------|------|------|
| **1** | **R4-A (P0)** | First 30 Seconds | Hero UI, 단일 CTA, Cold Start 카피, Ctrl+K | [R4_P0_FIRST_30_SECONDS_PLAN.md](./R4_P0_FIRST_30_SECONDS_PLAN.md) |
| **2** | **R4-B (P1)** | Navigation IA | Bottom/Sidebar 역할, 중복 제거, 서재→Preview | [R4_P1_NAVIGATION_PLAN.md](./R4_P1_NAVIGATION_PLAN.md) |

**P0·P1 공통 (경량):** 홈·Preview·빈 상태 카피에서 `[[wiki]]`→「링크」, Sanctum/Vault 사용자어 통일 (문자열 only).

### Deferred — R4 이후 (P2/P3, 본 Sprint **범위 외**)

| 우선순위 | 항목 | ROI 축 | R4에서 제외 사유 |
|:--------:|------|--------|------------------|
| P2 | Preview 연결 섹션 fold 상향 | Link, Explore | P0/P1 후 측정 — layout 변경 단독 ROI 낮음 |
| P2 | Graph 하단 진입·expand friction | Explore | 시각 Graph 아님 — IA 정리 후 재평가 |
| P2 | Autosave vs 저장 복귀 UX 통일 | Archive | R3-G 정책 확정됨 — 카피/토스트 수준은 P0에 일부 포함 가능 |
| P3 | Workbench 탭 레일 정리 | Archive | 편집 power user — cold start 무관 |
| P3 | entityId UI 접기 | — | polish |
| P3 | Entity/Record Preview 카피 계층 | Link | P0 용어 정리로 partial |

---

## 비범위 (Do Not Touch)

| 영역 | 금지 | 이유 |
|------|------|------|
| **akasha-db** | manifest, 샤드, 스키마 | Tier 1 Fact SSOT |
| **search_index / Recall CI** | 랭킹·인덱스·`sw1_a_validation` | 헌법 Ⅱ |
| **Link Index 내부** | neighbor fetch 알고리즘, wiki 파서 | R3 Discovery/Link Index 변경 금지 관행 |
| **Registry Sync** | sync 파이프라인, catalog propose 로직 | CURRENT_STATE CI 게이트 |
| **R3-F/G 핵심 정책** | `navigate*Preview`, `_maybeReturnToPreviewAfterSave` **삭제·역전** | 회귀 — **확장만** |
| **Workbench 4열 편집기** | Sanctum·YAML·autosave **구조** | Archive 완결 — R4는 **진입·카피**만 |
| **Phase 3–5** | Entity 다각화, 타임라ine Phase, Connection Phase | CURRENT_STATE 미착수 |
| **시각 Knowledge Graph** | 노드·엣지 렌더링 | scope creep |
| **IAP / Steam / M3** | 스토어·depot | 보류 |

---

## ROI 우선순위 (확정)

> **ROI = (First 30s + Cold Start + Loop 진입률 + 우주 체감) / 구현 비용**
> Audit Top 10 기준 — **새 문제 탐색 없음**.

| Rank | 항목 | Phase | First 30s | Cold Start | Loop 진입 | 우주 체감 | 비용 | **ROI** |
|:----:|------|:-----:|:---------:|:----------:|:---------:|:---------:|:----:|:-------:|
| **1** | Home Hero + 단일 CTA + narrative 1줄 | P0 | ★★★★★ | ★★★★★ | ★★★★ | ★★★★ | M | **최고** |
| **2** | Cold Start 카피·상태 분기 (볼트 0/미연동) | P0 | ★★★★ | ★★★★★ | ★★★★ | ★★★ | S | **최고** |
| **3** | Ctrl+K → `openSearchDialog` | P0 | ★★★★ | ★★★ | ★★★ | ★★ | **XS** | **최고** |
| **4** | 용어 비개발자화 (Hero·빈 섹션) | P0 | ★★★★ | ★★★★ | ★★ | ★★★ | S | **높음** |
| **5** | Bottom Nav 역할 명확화 | P1 | ★★★ | ★★★ | ★★★★ | ★★★ | M | **높음** |
| **6** | Sidebar 축소·2차 배치 | P1 | ★★★ | ★★★ | ★★★ | ★★★ | M | **높음** |
| **7** | 서재 → Preview (`HomeBrowseCoordinator`) | P1 | ★★ | ★★ | ★★★★★ | ★★★★ | S | **높음** |
| **8** | Home vs Explore 중복 제거 | P1 | ★★★ | ★★★ | ★★★ | ★★ | M | **중** |
| **9** | Graph 진입 IA (sidebar→hero/link) | P2 | ★★ | ★★ | ★★★ | ★★★ | M | **중** (R4-B 후보) |
| **10** | Preview fold 재배치 | P2 | ★ | ★★ | ★★★ | ★★★ | M | **중** |

**R4 확정 범위 = Rank 1–7.** Rank 8은 P1 일부로 포함, 9–10은 Deferred.

---

## 코드 구조 (Planning 기준 재확인)

```
HomeShellScaffold
  └─ HomeShellBody (Row)
       ├─ DashboardSidebar [260px, default open]
       └─ Expanded
            ├─ HomeVaultBanner? (vaultPath == null)
            ├─ FilterSection? (explore/library/filter)
            └─ WorkbenchShell
                 ├─ TabRail? (hasTabs)
                 └─ browseContent ← _buildDashboardBrowseContent()
                      ├─ isKnowledgeGraphMode → KnowledgeGraphView
                      ├─ isHomeDashboardMode → HomeDashboardView
                      ├─ isExploreBrowseMode → BrowseView
                      ├─ isPersonalLibraryMode → PersonalLibraryView
                      └─ …
       └─ DashboardPreviewPanel | EntityDashboardPreviewPanel
            (workPreviewItem | entityPreviewItem) && !workbench.hasOpenDetail
```

### 진입 API (변경 후보 표시)

| 경로 | 현재 API | R4 변경 |
|------|----------|---------|
| Home 카드 | `navigate*Preview` | 유지 |
| Explore 그리드 | `openWorkPreview` | 유지 |
| Search | `openSearchDialog` → Preview | 유지 + **Ctrl+K** |
| Hero CTA (신규) | — | → `openSearchDialog` |
| 서재 그리드 | `openBrowseItem` | **P1 → Preview** |
| Preview 기록 | `open*FromPreview` | 유지 |
| 저장 복귀 | `_maybeReturnToPreviewAfterSave` | 유지 |

---

## Phase 일정 (제안)

| Week | Sprint | Deliverable |
|------|--------|-------------|
| 1 | R4-A P0 | Hero, CTA, Cold Start copy, Ctrl+K, widget test |
| 2 | R4-B P1 | Nav IA, sidebar default, library→Preview, regression test |
| 2末 | R4-H | 5명 30s 테스트 + Scenario A/B 재측정 → R4H_VALIDATION.md |

---

## 의사결정 로그 (Planning 확정)

| ID | 결정 | 근거 |
|----|------|------|
| D1 | R4 = P0 + P1 only | ROI Rank 1–7, M3 hold 상태에서 cold start가 blocker |
| D2 | Hero는 **HomeDashboardView 상단** 신규 위젯 | 4섹션 IA 유지, cold만 Hero 우선 |
| D3 | Primary CTA = **검색** (`openSearchDialog`) | R3-H: 검색이 유일하게 명확한 첫 행동 |
| D4 | Graph·Preview layout은 R4 **제외** | P0/P1 ROI 대비 낮음 |
| D5 | Discovery/Link Index/Schema **손대지 않음** | R3 Do Not Touch 계승 |

---

## 관련 문서

- [R4_P0_FIRST_30_SECONDS_PLAN.md](./R4_P0_FIRST_30_SECONDS_PLAN.md)
- [R4_P1_NAVIGATION_PLAN.md](./R4_P1_NAVIGATION_PLAN.md)
- [R4_UX_DIRECTION_AUDIT.md](./R4_UX_DIRECTION_AUDIT.md)
