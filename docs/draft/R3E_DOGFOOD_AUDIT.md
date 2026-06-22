# R3-E Dogfood Audit — 탐험 중심 UX 검증

> **갱신:** 2026-06-22  
> **방법:** 코드 기반 시나리오 시뮬레이션 (R3-A ~ R3-D 구현 반영)  
> **코드 수정:** 없음  
> **전제:** [R3D_PREVIEW_STACK_IMPLEMENTATION_REPORT.md](./R3D_PREVIEW_STACK_IMPLEMENTATION_REPORT.md), [R3D_ENTITY_WORKBENCH_P2_IMPLEMENTATION_REPORT.md](./R3D_ENTITY_WORKBENCH_P2_IMPLEMENTATION_REPORT.md)

---

## Executive Summary

R3 시리즈 이후 **홈·Preview·연결 CTA·Preview Stack·Entity Workbench**는 탐험 축을 크게 강화했다.  
이상 경로(홈 → Preview → 이웃 체인 → 기록 → 복귀)에서는 **발견→기록→연결→새 발견** 루프가 동작한다.

그러나 **진입 경로마다 정책이 다르고**(Preview vs Workbench, push vs replace), **빈 볼트·라이브러리·키보드 단축키** 등에서 탐험 리듬이 끊긴다.

| 환경 | 탐험 중심 체감 | 루프 완성도 (추정) |
|------|:--------------:|:------------------:|
| 빈 볼트 | ⚠️ 부분 | **60~65%** |
| 소규모 볼트 | ✅ 양호 | **82~85%** |
| 연결 밀집 볼트 | ✅ 우수 | **88~92%** |
| **전체 (가중 평균)** | **양호** | **~85%** |

**판정:** 탐험 중심 경험은 **달성됐으나 보편적이지는 않다.** 이상 경로에서는 90%+ 가능, 모든 진입점 통합 시 85% 전후.

---

## Audit 방법

| 항목 | 내용 |
|------|------|
| 실측 | `lib/screens/home/`, Preview 패널, Workbench, Graph 뷰 코드 추적 |
| 시나리오 | 3개 볼트 프로필 × 표준 탐험 루프 6단계 |
| 제외 | 런타임 스크린샷·실제 볼트 파일 (후속 수동 dogfood 권장) |

### 표준 탐험 루프 (검증 시나리오)

```
① 발견 (홈 / 검색 / 그리드)
② Preview 열기
③ 연결 이웃 탐색 (체인)
④ 기록하기 → Workbench
⑤ [[wiki]] 연결 생성
⑥ Preview 복귀 → 새 발견
```

---

## 환경 1 — 빈 볼트

**프로필:** `vaultItems == []`, `recentExploreItems == []`, 볼트 미연결 또는 연결됐으나 아카이브 0건.

### 사용자가 보는 화면 (코드)

| 섹션 | 동작 |
|------|------|
| 계속 탐험하기 | 「아직 탐색 기록이 없습니다」+ [검색으로 탐험 시작] (`home_dashboard_continue_section.dart`) |
| 오늘의 연결 | 「[[wiki]] 링크로 연결된…」 안내만 (`home_dashboard_todays_links_section.dart`) |
| 최근 발견 | 「검색으로 작품을 찾아 볼트에 추가해 보세요」 |
| 최근 기록 | 「Sanctum에 감상을 기록하면…」 |
| 지식 연결 맵 | 「볼트에 작품이 없습니다」+ [엔티티 연결하기] (`knowledge_graph_view.dart`) |

### 시나리오 수행

| 단계 | 결과 | 판정 |
|------|------|------|
| ① 발견 | 검색(10k 카탈로그) 또는 탐색 탭 그리드 → `openWorkPreview` | ✅ |
| ② Preview | 연결 0건 → `WorkPreviewEmptyConnections` (인물/사건/개념 CTA) | ✅ |
| ③ 이웃 체인 | 연결 없음 → 체인 불가 | ⏸️ |
| ④ 기록 | [기록 열고 직접 작성하기] → Workbench | ✅ |
| ⑤ 연결 | Workbench Sanctum + Entity Link Picker / `[[wiki]]` | ⚠️ 볼트 필요 |
| ⑥ 복귀 | 저장 후 Preview 자동 복귀 **없음** | ❌ |

### 빈 볼트 특이사항

- 글로벌 카탈로그 탐색은 가능하나 **로컬 연결·오늘의 연결·Graph**는 모두 빈 상태.
- 커스텀 추가·아카이브는 `vaultPath == null` 시 「볼트를 먼저 연결」 (`home_dialogs_coordinator.dart`).
- **첫 행동이 무엇인지** 메시지는 있으나, 볼트 연결 vs 검색 vs 아카이브 우선순위가 분산됨.

---

## 환경 2 — 소규모 볼트

**프로필:** 작품 2~8건, 엔티티 소수, wiki 링크 0~5개, 탐색 이력 일부.

### 사용자가 보는 화면

| 섹션 | 동작 |
|------|------|
| 계속 탐험하기 | `recentExploreItems` 없으면 **vault fallback** — 「최근 추가한 작품부터」 (R3-C) |
| 오늘의 연결 | 링크 있으면 최대 3카드, 탭 → Preview (replace) |
| 탐색 그리드 | 포스터 탭 → `openWorkPreview` (`home_browse_coordinator.dart` L109–111) |
| Entity 갤러리 | `onPreviewEntity` (`catalog_entity_browse_view.dart`) |

### 시나리오 수행

| 단계 | 결과 | 판정 |
|------|------|------|
| ① 발견 | 홈 카드 / 검색 / 탐색 탭 | ✅ |
| ② Preview | Work·Entity 패널 + 연결 섹션 | ✅ |
| ③ A→B 체인 | Preview 이웃 탭 → `previewLinked*` → stack push | ✅ R3-D |
| ④ `← 이전` | `canPopPreview` → `popPreview` | ✅ |
| ⑤ 기록하기 | Preview → Workbench, 연결 섹션 유지 (R3-D P2) | ✅ |
| ⑥ 연결 후 탐험 | 저장 → neighbors 리프레시, Preview 수동 재오픈 | ⚠️ |

### 소규모 볼트 특이사항

- 연결 1~2건이면 **오늘의 연결**·이웃 섹션이 실질적 발견 동기가 됨.
- 빈 연결 작품은 `WorkPreviewEmptyConnections`로 **다음 행동이 명확**.
- 홈·Graph에서 Preview 진입은 **stack replace** — 패널 밖에서 연 타면 `← 이전` 사라짐.

---

## 환경 3 — 연결 밀집 볼트

**프로필:** 작품 20건+, 엔티티 다수, wiki 링크 풍부, Entity journal 다수.

### 사용자가 보는 화면

| 섹션 | 동작 |
|------|------|
| 오늘의 연결 | 실제 Work↔Entity 하이라이트 3건 |
| 지식 연결 맵 | 연결 수 정렬, ExpansionTile → neighbors |
| Preview | 4섹션 이웃 + incoming 요약 |
| Entity Workbench | Preview ≥ 연결 정보 + incoming 상세 (P2) |
| Preview Stack | 3단계 이상 체인 + `← 이전` |

### 시나리오 수행

```
Work A (홈)
  → Preview 이웃: Entity B (push)
  → Preview 이웃: Work C (push)
  → ← 이전 → Entity B → ← 이전 → Work A     ✅

Entity B Preview
  → 기록하기 → Workbench
  → 연결 4섹션 + incoming 경로 + Sanctum     ✅

Graph → 작품 펼침 → 인물 탭
  → onPreviewEntity (replace, stack clear)   ⚠️
```

### 밀집 볼트 특이사항

- **탐험 밀도가 높을수록** R3 투자(Preview, Stack, Workbench 허브) ROI 최대.
- Graph는 리스트형이지만 연결 수·expand neighbors로 **탐험 허브 역할** 가능.
- incoming 경로 탭 → `onRecordOpenEntity` → Workbench 직행 (기록 맥락, R3-C 의도).

---

## 검증 질문 답변

### 1. 사용자가 무엇을 해야 하는지 이해되는가?

| 환경 | 판정 | 근거 |
|------|:----:|------|
| 빈 볼트 | ⚠️ | 「검색」「볼트 연결」「기록」이 동시 노출, 단일 다음 행동 부족 |
| 소규모 | ✅ | 홈 fallback + 빈 연결 CTA로 흐름 유도 |
| 밀집 | ✅ | 오늘의 연결·이웃 섹션이 자기 설명적 |

**리스크:** 카피 전반에 `[[wiki]]`·「link index」 개념이 노출 — 비개발자에게는 진입 장벽.

**점수: 7/10**

---

### 2. Preview 사용 빈도는 충분한가?

| 진입점 | Preview | Workbench 직행 |
|--------|:-------:|:--------------:|
| 홈 대시보드 | ✅ | — |
| 탐색 그리드 (일반) | ✅ | — |
| 검색 (로컬·원격) | ✅ | — |
| Entity 갤러리 | ✅ | — |
| Knowledge Graph | ✅ | — |
| **나의 서재 그리드** | — | ✅ `openBrowseItem` |
| incoming / same-day | — | ✅ `onRecordOpenEntity` |

**판정:** 탐색 축의 ~85%가 Preview를 거친다. 서재·기록 맥락 예외는 합리적이나 **서재도 Preview 통일 시 일관성↑**.

**점수: 8/10**

---

### 3. Workbench 진입 타이밍은 자연스러운가?

| 트리거 | 타이밍 | 판정 |
|--------|--------|------|
| Preview 「기록하기 >」 | 연결 확인 후 기록 | ✅ 자연 |
| 빈 연결 CTA → picker | 연결 의도 후 Sanctum | ✅ |
| `openWorkFromPreviewToConnect` | 연결 생성 직전 Workbench | ✅ |
| Graph 「기록 열기」 | `openMostRecentWorkForRecord` | ⚠️ 최근 작품 고정 |
| 검색 → catalog-only Entity promote | 아카이브 플로우 | ⚠️ 편집 무게 |

**R3-D P2 이후:** Entity Workbench 진입 시 연결 UI 유지 — Preview→Workbench 단절 **해소**.

**점수: 8/10**

---

### 4. Preview Stack은 실제로 유용한가?

| 조건 | 유용성 |
|------|--------|
| Preview 패널 내 이웃 체인 (A→B→C) | ✅ **높음** — `previewLinked*` + `← 이전` |
| 홈·Graph에서 연속 탭 | ⚠️ **낮음** — replace, stack 미축적 |
| Workbench Sanctum wiki 탭 | ⚠️ replace (편집 맥락) |
| 루트 Preview | `← 이전` 숨김 (`canPopPreview`) — ✅ |

**판정:** Stack은 **Preview 패널 내부 탐험**에서만 가치 있음. 전체 앱 탐험의 ~40% 경로에 적용.

**개선 여지:** Graph·홈 「오늘의 연결」 이웃 탭도 `previewLinked*` 사용 시 체감↑.

**점수: 7/10** (니치하지만 핵심 체인에서 결정적)

---

### 5. 연결 생성 CTA는 충분히 발견 가능한가?

| 위치 | CTA | 발견성 |
|------|-----|:------:|
| Work Preview (연결 0) | `WorkPreviewEmptyConnections` | ⭐⭐⭐ |
| Work/Entity Preview (섹션별 빈) | 「기록에서 [[링크]] 추가」 | ⭐⭐ |
| Knowledge Graph (전체 0) | 배너 [기록 열기][엔티티 연결하기] | ⭐⭐⭐ |
| Entity Workbench (P2) | 빈 섹션 → Sanctum focus | ⭐⭐ |
| Graph 행 subtitle | 「연결 없음 · 기록에서 [[링크]] 추가」 | ⭐ |

**판정:** R3-C 이후 CTA **표면적 증가**. 다만 **[[wiki]] 문법**을 모르면 picker CTA만이 실질 가이드.

**점수: 7.5/10**

---

### 6. 아직 Dead End가 존재하는가?

**예.** 심각도순:

| # | Dead End | 환경 | 심각도 |
|---|----------|------|:------:|
| D1 | **Ctrl K 표시·미연결** — 홈 TopBar에 표기, Shell shortcut은 Tab만 | 전체 | 중 |
| D2 | **나의 서재 → Workbench 직행** — Preview 우회 | 서재 | 중 |
| D3 | **저장 후 Preview 미복귀** — 연결 생성 후 탐험 루프 수동 재개 | 소규모+ | 중 |
| D4 | **Graph/홈 이웃 탭 = stack replace** — 체인 탐험 중 홈 카드 탭 시 맥락 소실 | 밀집 | 중 |
| D5 | **볼트 미연결 시 로컬 루프 불가** — 카탈로그 Preview만 가능 | 빈 | 중 |
| D6 | **이중 네비** — 사이드바 vs 하단탭 (홈/탐색/라이브러리/컬렉션) | 전체 | 중 |
| D7 | Graph expand 전 「펼쳐서 연결을 불러오세요」 — 1클릭 추가 | 밀집 | 하 |
| D8 | **Timeline/Records 축** — 탐험 루프와 분리 | 전체 | 하 |
| D9 | catalog-only Entity — journal 없으면 outgoing neighbors 제한 | 소규모 | 하 |

**R3-C~D에서 해소된 Dead End (참고):**

- Wiki → Preview ✅
- Work Preview 빈 연결 CTA ✅
- Graph 전체 빈 CTA ✅
- Continue cold fallback ✅
- Entity Preview→Workbench 연결 소실 ✅
- Preview 체인 맥락 (패널 내) ✅

---

## 진입 경로 — Preview 정책 맵

```
                    replace (stack clear)          push (stack)
                    ─────────────────────        ──────────────
홈/검색/Graph/탐색   openWorkPreview              —
Preview 이웃 탭      —                            previewLinked*
Wiki (Sanctum)       open*Preview                  —
서재 그리드          openBrowseItem (Workbench)    —
```

---

## R3 시리즈 효과 (Dogfood 관점)

| Sprint | Dogfood 기여 |
|--------|--------------|
| R3-A | 연결 UI 노출 — 이웃 섹션 표준화 |
| R3-B | Preview 중심 탐색 — 홈·검색·그리드 정책 |
| R3-C | Dead End 4건 제거 — cold start·빈 연결·Graph |
| R3-D P2 | Workbench≥Preview — 기록 후에도 탐험 |
| R3-D P3 | Preview Stack — 패널 내 체인 복귀 |

---

## 종합 판정

### 탐험 중심 경험을 제공하는가?

**조건부 예.**

- **소규모·밀집 볼트 + 홈/Preview 경로:** 「지식 우주를 걸어 다니는」 체감 **가능**.
- **빈 볼트·서재·키보드·루프 복귀:** 여전히 「앱을 조작하는」 체감.

### 루프 완성도 (Dogfood 재추정)

| 구간 | R3-D 설계 추정 | Dogfood 검증 |
|------|:--------------:|:------------:|
| 이상 경로 | 90~92% | **90%** ✅ |
| 전 진입점 평균 | — | **~85%** |
| 빈 볼트 | — | **~62%** |

---

## Audit 후 권장 (코드 수정 — 우선순위만)

| 우선순위 | 항목 | 기대 효과 |
|:--------:|------|-----------|
| **P0** | Shell `Ctrl+K` → `openSearchDialog` | D1, 첫 발견 장벽 |
| **P1** | 홈·Graph 이웃 탭 → `previewLinked*` | D4, Stack 실용성↑ |
| **P1** | 저장 후 Preview 자동 복귀 (선택 토스트) | D3, 루프 닫기 |
| **P2** | 빈 볼트 온보딩 단일 CTA (볼트 연결 → 검색) | 빈 볼트 65%→75% |
| **P2** | 서재 그리드 Preview 옵션 | D2, 정책 일관성 |
| **P3** | `[[wiki]]` 카피 비개발자화 | CTA 발견성 |

**이번 Sprint:** 코드 수정 없음. 위 항목은 R3-F 후보.

---

## 수동 Dogfood 체크리스트 (후속)

실제 3개 볼트로 아래를 재현·스크린샷 권장:

- [ ] 빈 볼트: 첫 10분 내 「다음 행동」 인지
- [ ] 소규모: Work→Entity→Work + `← 이전` 2회
- [ ] 밀집: 오늘의 연결 → 3단계 체인 → 기록 → 복귀
- [ ] 서재 그리드 탭 시 Preview 미노출 확인
- [ ] Ctrl+K 입력 시 검색 미열림 확인

---

## 관련 문서

- [UX_RECOVERY_MASTER_PLAN.md](./UX_RECOVERY_MASTER_PLAN.md)
- [R3B_EXPLORATION_AUDIT.md](./R3B_EXPLORATION_AUDIT.md)
- [R3C_IMPLEMENTATION_REPORT.md](./R3C_IMPLEMENTATION_REPORT.md)
- [R3D_PREVIEW_STACK_IMPLEMENTATION_REPORT.md](./R3D_PREVIEW_STACK_IMPLEMENTATION_REPORT.md)
