# R5 Dogfood Round 2 — UX 검증 보고서

> **일자:** 2026-06-22
> **범위:** R4-A ~ R4-C 반영 후 · 코드·UI 흐름 추적 + widget test
> **SSOT:** [PROJECT_CONSTITUTION.md](../PROJECT_CONSTITUTION_STUB.md), [CURRENT_STATE.md](../../../active/CURRENT_STATE.md)
> **선행 Dogfood:** [R3H_DOGFOOD_VALIDATION.md](./R3H_DOGFOOD_VALIDATION.md)
> **선행 구현:** [R4A](./R4A_IMPLEMENTATION_REPORT.md) · [R4B](./R4B_IMPLEMENTATION_REPORT.md) · [R4C](./R4C_IMPLEMENTATION_REPORT.md)

---

## 검증 방법 (한계 포함)

| 수단 | 내용 |
|------|------|
| SSOT 대조 | 헌법 4축(발견·기록·연결·탐색) vs R4 이후 UI·네비게이션 |
| 시나리오 재현 | Scenario A/B/C별 클릭 경로·멈춤 지점을 `home_shell_*`, Preview, Workbench, Graph 호출 체인으로 단계 추적 |
| R3H 대비 | R4-A(First 30s) · R4-B(Navigation IA) · R4-C(Friction) 변화 반영 여부 |
| 자동 테스트 | `home_dashboard_view_test`, `entity_dashboard_preview_panel_test`, `home_browse_library_preview_test` — **4/4 PASS** |
| GUI 조작 | 에이전트 환경에서 **전 시나리오 실클릭·타이밍 측정 불가** — R3H와 동일 한계; 본 보고서는 **구현된 UX가 설계 의도대로 배선됐는지** 검증 |

**금지 준수:** UI 개선안 · Redesign · Planning · 기능 제안 · 코드 수정 — **없음**.

---

## 헌법 대비 현재 UX (R4 이후)

| 헌법 축 | R4 이후 전달 방식 | Dogfood 체감 |
|---------|-------------------|--------------|
| **발견 (Discovery)** | Hero CTA · 검색(Ctrl+K) · 탐색 10k · 홈 4섹션 | ✅ 진입은 **한 곳(Hero)**으로 수렴 (R4-A) |
| **기록 (Archive)** | Preview 「기록하기」→ Workbench · autosave 힌트 | ✅ 역할 분리 **명확** (R4-C); cold 첫 기록은 Preview 복귀 대상 없음 (정책) |
| **연결 (Link)** | Preview 빈 연결 CTA · 본문 `[[링크]]` · 연결 목록 | ⚠️ **작동하나** 마크다운 링크 학습 또는 Workbench 진입 필요 |
| **탐색 (Explore)** | Preview Stack · `이전` · Library→Preview (R4-B) | ✅ Scenario B 루프 **닫힘** |

---

## Scenario A — 새 볼트 · 작품 10 · 엔티티 0

**프로필:** 볼트 연동됨. vault에 작품 md 10건. UserCatalog 엔티티 0. outgoing 링크 0.

### 실제 사용 흐름

1. **앱 실행** → Sidebar **collapsed** (R4-B) → Hero 「기록하고, 연결하고, 발견하세요」+ **[탐험 시작하기]**
2. **계속 탐험하기** — 탐색 기록 없으면 vault fallback: 「최근 추가한 작품부터…」+ **작품 카드 4장** (R4-A2)
3. **오늘의 연결** — 「기록에서 연결한 작품·인물이 여기에 표시됩니다.」 (**클릭 대상 없음**)
4. **최근 기록** — md/review 있는 작품 **최대 4건** 리스트 (있으면 Preview 진입)
5. 카드 탭 → **Work Preview** (Chrome: 「지금 보는 항목」·「기록하기」)
6. 연결 0 → **빈 연결 블록**: 인물/사건/개념 연결하기 · 기록 열고 직접 작성하기
7. **연결 목록**(Sidebar 도구) → 10작품 **전부 연결 0** · 펼쳐도 이웃 없음 · empty banner

### 측정 — 기록 · 연결 · 발견

| 단계 | 대표 경로 | 클릭 수 (추정) | 멈춤 / 헷갈림 |
|------|-----------|:--------------:|---------------|
| **발견** (기존 10작품) | 홈 카드 → Preview | **1** | Hero narrative와 vault 카드 **일치** — 「발견」보다 「이어 보기」 |
| **발견** (신규) | Hero/검색 → 카탈로그 → Preview | **2~3** | 탐색 탭 vs Hero **둘 다 유효** — 혼란은 R3H보다 ↓ |
| **기록** | Preview → 기록하기 → Workbench → md 저장 | **3~4** + 입력 | 첫 기록: Preview 스냅샷 없음 → **저장 후 Preview 복귀 없음** (정책) |
| **연결** (첫 1건) | Preview → 인물 연결하기 → picker → Workbench | **4~6** | **링크 문법 몰라도** CTA 경로 존재 — Workbench 진입은 필수 |
| **연결** (홈 반영) | 링크 생성 후 | — | 「오늘의 연결」·Graph **갱신됨** — 첫 연결 전까지 홈 **2/4 섹션 공허** |

### 불편한 점

- Hero는 「연결하고」를 말하지만 **연결 0 상태**에서는 홈 중앙이 **기록·탐색 중심**, 연결 축은 **비어 있음**
- Graph에 10행 **모두 0건** — R4-C 부제로 기대치는 맞추나 **동기 저하** 가능
- 작품 10개인데 엔티티 0 → Preview 이웃 탐험 **불가** (Work↔Work 링크도 없으면 체인 단절)

### 반복 행동

- **홈 vault 카드** 또는 **라이브러리 탭**에서 같은 10작품 재진입
- 연결 전까지 Preview에서 **「기록하기」** 반복 — 감상만 쌓고 연결은 미루는 패턴

### 막히는 지점

| 지점 | 내용 |
|------|------|
| 연결 0 plateau | 홈·Graph·Preview가 **「연결 대기」** 상태로 길게 머무름 |
| 첫 Entity | catalog-only Entity는 Preview 가능하나 **이웃 없음** — Work 쪽 링크가 선행 |
| Place/Org | 커스텀 추가 picker에 **없음** (Browse scope만) — Scenario A 범위 밖이나 Entity 0 확장 시 장벽 |

### 가치가 느껴지는 순간

- Hero **한 문장**으로 앱 정체성 인지 (R4-A)
- vault fallback 카드로 **「내 10작품」** 즉시 Preview — cold 탐색 기록 없어도 **이어하기** 가능
- Preview Chrome 「지금 보는 항목」 — **어디를 보는지** 명확 (R4-C)

---

## Scenario B — 작품 50+ · 엔티티 20+ · 링크 존재

**프로필:** 링크 인덱스 populated. 홈 continue·오늘의 연결·Graph 정상 데이터.

### 실제 사용 흐름 (목표 루프)

| # | 행동 | 관찰 (R4 반영) |
|---|------|----------------|
| 1 | 홈 continue 카드 | Work Preview (**replace**) |
| 2 | Preview 연결된 인물 탭 | Entity Preview (**push**) · Chrome **「이전」** |
| 3 | 「기록하기」 | Workbench · Save Return 스냅샷 |
| 4 | **md 저장** | Preview+stack **복귀** (R3-G, 유지) |
| 5 | `이전` | Work Preview |
| 6 | 이웃 Work 탭 | stack **push** |
| 7 | Sidebar **연결 목록** | Preview **유지** · 리스트형 부제 (R4-C) |
| 8 | Graph 행 펼침 → 이웃 탭 | Preview **push** (R3-F) |
| 9 | 하단 **라이브러리** 그리드 | **Preview** (R4-B — Workbench 우회 **해소**) |
| 10 | TodayRecall 카드 | **Preview** (R4-B) |

### 측정 — 기록 · 연결 · 발견

| 단계 | 클릭 (추정) | 멈춤 / 헷갈림 |
|------|:-----------:|---------------|
| **발견** (이웃 체인) | 1/탭 · `이전` 1/복귀 | Stack depth **숫자 없음** — `이전`만 (R4-C debt) |
| **연결** 탐색 | Graph: **펼치기 1 + 탭 1**/작품 | 50+ 작품 시 **클릭 누적** · 첫 로딩 `_loadCounts` **수 초** (R3H 동일) |
| **기록** | Preview→Workbench→저장→Preview | **4~5** · autosave 힌트 읽으면 정책 **이해 가능** (R4-C) |
| **발견** (Library) | 그리드 1 → Preview | **1** — R4-B **가장 큰 IA 개선 체감** |

### 불편한 점

- Graph **아코디언** — 연결 많은 볼트에서 탐색 fatigue **잔존** (카피만 정직화, 구조 동일)
- Workbench **탭 레일** — Save Return 후 browse+Preview+탭 **3겹** (R3H 동일)
- Sanctum 편집 중 wiki 탭 → Preview **replace** (stack 초기화) — 탐험 vs 편집 **맥락 충돌**

### 반복 행동

- Preview 이웃 **연속 탭** → `이전` 연타 — **핵심 가치 루프**
- Graph에서 **연결 수 상위** 작품부터 펼치기 — 정렬은 맞으나 **패턴 고정**

### 막히는 지점

| 지점 | 내용 |
|------|------|
| Autosave (2초) | Workbench **유지** — 힌트 있으나 **읽지 않으면** R3-G와 혼동 가능 |
| Incoming Record 용어 | Entity 패널 「연결된 Record N개」 — 일반 사용자 **학습 필요** |
| Graph scale | 50+ **첫 paint 지연** — freeze는 아니나 **기다림** |

### 가치가 느껴지는 순간

- **Work → Entity → Work** Preview 체인 + Save Return — **「탐험 세션」 하나로 느껴짐**
- Library·홈·Graph **모두 Preview first** — mental model **수렴** (R4-B)
- 「지금 보는 항목」+ `이전` — stack 탐험 **자신감** (R4-C)

---

## Scenario C — 실제 개인 지식 (문화 콘텐츠 아님)

**프로필:** 사람·프로젝트·개념·장소·이벤트를 AKASHA에 기록·연결.

### 실제 사용 흐름 (유형별)

| 대상 | 진입 | 흐름 | 클릭·장벽 |
|------|------|------|-----------|
| **사람** | 컬렉션 탭 → Person scope → 추가 | `showAddCatalogEntityDialog` → journal | **3~4** + 폼 · 다이얼로그 라벨 **영문(Person)** |
| **개념** (예: 방법론) | 동일 · Concept | entities/concept/*.md | **3~4** · subtitle **파일 경로 노출** |
| **이벤트** | 동일 · Event | — | **3~4** |
| **장소** | 컬렉션 → Place scope → 추가 | Browse에만 scope · **커스텀 picker엔 없음** | 탐색 탭 전환 **+** 추가 |
| **조직** | Organization scope | — | Place와 동일 |
| **프로젝트** | **전용 타입 없음** | Concept 또는 Organization 또는 **user-local Work**로 우회 | **타입 선택 혼란** — 헌법 5대 Entity에 Project **없음** |
| **비문화 Work** | 검색 커스텀 추가 · Work picker | user-local work md | 10k 카탈로그와 **섞여 보임** |

### Work에 연결하기

1. Work Preview → 인물/개념 연결 CTA **또는** Workbench 기록 본문 `[[링크]]`
2. Entity picker — catalog 검색
3. md 저장 → Preview 복귀 → **이웃 표시**

### 측정 — 기록 · 연결 · 발견

| 단계 | 클릭 (추정) | 멈춤 / 헷갈림 |
|------|:-----------:|---------------|
| **기록** (Entity 신규) | 컬렉션 탭 → scope → 추가 → 폼 → 저장 | **5~7** · Work보다 **진입 깊음** |
| **연결** | Work Preview CTA 경로 | **4~6** · **마크다운** 대안은 power-user |
| **발견** | Entity Preview 이웃 · Graph | Work 중심 정렬 — **개인 Entity hub** 약함 |

### 불편한 점

- 앱 **첫인상·카탈로그·Hero**는 **문화 작품** 전제 — 개인 프로젝트/업무 지식은 **게스트**
- Entity 추가 UI **영문 타입명** · `entities/person/*.md` — 비개발자 **거부감**
- **프로젝트** 없음 — Concept에 넣을지 Work로 넣을지 **사용자 결정** 필요
- Place/Org는 **Browse scope**로만 추가 — R4가 손대지 않은 **진입 불균형**

### 반복 행동

- Concept/Work **타입 우회** 고정 — 개인 지식마다 **같은 혼란 반복**
- Workbench **기록 본문**에 링크 수동 삽입 — Scenario B보다 **빈도 ↑**

### 막히는 지점

| 지점 | 내용 |
|------|------|
| 타입 모델 | 헌법 5 Entity ≠ 사용자 mental model (프로젝트·업무) |
| Discovery | 10k **문화 Fact** 검색이 **개인 Entity** 발견과 **무관** |
| CURRENT_STATE | Phase 3 Entity 다각화 **미착수** — 코드와 SSOT **일치** |

### 가치가 느껴지는 순간

- **한 Work(프로젝트 노트) + Person + Concept** 링크 후 Preview 체인 — **지식 우주** 감각 **가능**
- Entity Preview Chrome — Work와 **동일 UX** (R4-C)
- Wiki 링크 익숙한 사용자 — **연결·탐색** 속도 **빠름**

---

## 공통 — R3H 대비 R4 이후 변화

| R3H 지적 | R5 재검증 |
|----------|-----------|
| 첫 30초 CTA 분산 | ✅ Hero 단일 CTA (R4-A) |
| Ctrl+K 무동작 | ✅ 검색 연결 (R4-A) |
| Library Workbench 직행 | ✅ Preview (R4-B) |
| Graph 「맵」 기대 | ✅ 「연결 목록」+ 부제 (R4-C) |
| Preview 위치 불명 | ✅ 「지금 보는 항목」 (R4-C) |
| Autosave vs md 저장 | ⚠️ **힌트 추가** — 읽으면 해소, 안 읽으면 잔존 |
| Sanctum / catalog only | ✅ 「기록 본문」「기록 없음」 (R4-C) |
| Wiki `[[wiki]]` 홈 카피 | ✅ 제거 (R4-A) |
| Graph accordion fatigue | ❌ **잔존** (엔진/구조 touch 금지) |
| Stack depth 표시 | ❌ **잔존** |
| 개인 지식 / Project 타입 | ❌ **잔존** (Phase 3 미착수) |

### 루프 완성도 (Dogfood 추정)

| 프로필 | R3H | R5 (R4 후) |
|--------|-----|------------|
| A — 10작품·0엔티티 | 62~68% | **72~78%** |
| B — 50+/20+/링크 | 88~91% | **92~95%** |
| C — 개인 지식 | (미정량) | **65~72%** |
| **Scenario B 이상 경로** | ~91% | **~94%** |

---

## 반복 행동 (전 시나리오)

| 행동 | 빈도 | 의미 |
|------|------|------|
| Preview 이웃 탭 → `이전` | B/C 높음 | **핵심 탐험 루프** — UX 목표 달성 |
| Hero/검색 → Preview | A·C | **발견** 진입 |
| Workbench 기록 본문 편집 | A→B 전환 | **연결 생성**의 실질 작업 |
| Graph 행 펼치기 | B | **비용 있는** 연결 탐색 |
| 컬렉션 scope 전환 | C | Entity 타입별 **관리** |

---

## 가치가 느껴지는 순간 (요약)

1. **Scenario B:** Preview stack으로 Work↔Entity **연속 탐험** + 저장 후 **탐험 복귀**
2. **R4-B:** Library·홈·Graph **같은 Preview 문법** — 「탐험 앱」으로 읽힘
3. **R4-A Hero:** 첫 10초에 **기록→연결→발견** narrative
4. **R4-C Chrome:** stack 중 **길 잃지 않음**
5. **Scenario C (숙련 후):** wiki 링크로 **개인 지식 그래프** 구축 가능 — **입문 전에는 Work-centric**

---

## 최종 판단

### 선택: **A — 현재 UX 충분 → Discovery 강화로 이동**

### 근거

1. **R4 Sprint 목표 달성:** R3H·R4 Planning에서 식별한 **Navigation · First 30s · Preview · Graph 카피 · Autosave 표시** 마찰은 구현·검증 완료. **추가 UX 재설계** 없이 Scenario B **목표 루프(~94%)**가 닫힘.

2. **B(UX 불충분) 해당 안 함:** 잔여 불편(Graph accordion, stack depth, 3겹 탭)은 **IA 재설계**보다 **사용 빈도 낮은 polish** 또는 **Graph Engine/Phase scope**. R4에서 **구조 touch 금지**로 남긴 항목 — **새 UX Sprint ROI 낮음**.

3. **C(기능 우선) 부분 해당하나 UX Sprint 대상 아님:** Scenario C·Phase 3( Entity 다각화)·Project 타입·Place/Org picker — **기능·데이터 모델** 영역. UX 카피/배치만으로 **해결 불가**. CURRENT_STATE **미착수 Phase**와 일치.

4. **헌법 필터:** Scenario B 사용자에게 **Discovery** 강화가 다음 가치. UI narrative는 R4-A Hero로 **충분한 출발점** — **카탈로그에서 관계 발견**이 병목.

### Scenario A caveat (A 선택 조건)

- **연결 0 plateau**는 UX redesign보다 **첫 링크 onboarding(기능/교육)** 또는 Discovery-side **「연결할 후보」** 제시가 맞음 — **Discovery 강화**와 정합.

### Scenario C caveat

- 개인 지식·프로젝트는 **Phase 3+ 기능 로드맵** — **UX Sprint 연장으로 해결하지 않음**.

---

## 수동 교차 검증 권장 (사람 1회)

R3H와 동일 — 아래를 **실기기 클릭·스크린샷·타이밍**으로 교차 검증:

1. Scenario A: vault 10 · entity 0 → **첫 인물 연결**까지 클릭 수
2. Scenario B: Library 그리드 → Preview (**Workbench 우회 없음** 확인)
3. Scenario C: Person + Concept(프로젝트) + Work 링크 → Preview 체인
4. Autosave 2초 후 힌트 **가독성**
5. 연결 목록 50작품 **첫 로딩** 체감

---

## 부록 — 검증 코드 앵커

| 기능 | 앵커 |
|------|------|
| Hero / cold start | `home_dashboard_hero.dart`, `home_dashboard_continue_section.dart` |
| Preview Chrome | `preview_panel_chrome.dart` |
| Library → Preview | `home_browse_coordinator.dart` |
| Save Return | `_previewReturnSnapshot`, `_maybeReturnToPreviewAfterSave` |
| Autosave hint | `workbench_save_status_hint.dart` |
| 연결 목록 | `knowledge_graph_view.dart`, `dashboard_sidebar.dart` |
| Entity 추가 | `catalog_entity_browse_view.dart`, `add_catalog_entity_dialog.dart` |
| 빈 연결 CTA | `work_preview_empty_connections.dart` |
