# ADR-006: Franchise Boundary & Hierarchy

| 항목 | 내용 |
|------|------|
| **상태** | **초안** (URV-A 전 검토 필요) |
| **범위** | Franchise 레이어 — [ADR-001](ADR-001-dual-layer-entity-model.md) Dual-layer 위 |
| **목표** | **IP 1카드** 정책을 장기 유지하면서, 수백만 Work 규모에서 Franchise 구조가 **붕괴하지 않음**을 검증 |
| **연관** | [registry-scaling-review.md](../registry-scaling-review.md) §2.5 · [ADR-005](ADR-005-minimum-recordable-unit.md) |

---

## 1. 문제

현재 `franchise_groups.json` v2:

- **평면 맵** — `members: [wk_…]` 만, 부모·자식 Franchise 없음
- **단순 IP** (귀멸·포케몬)에는 충분
- **복합 IP** (Marvel·Fate·건담)는 **우주 → 시리즈 → 작품** 다단계를 한 장의 카드에 담기 어렵다

**검토 질문**

| # | 질문 |
|---|------|
| Q1 | Franchise 안에 Franchise가 **존재**할 수 있는가? |
| Q2 | Marvel → Avengers → *Endgame* 같은 **다단계**를 허용할 것인가? |
| Q3 | Pokémon(단순)과 Marvel(복합)을 **같은 모델**로 표현 가능한가? |
| Q4 | Franchise **최대 깊이**를 제한할 것인가? |

**제약 (고정)**

- [ADR-001](ADR-001-dual-layer-entity-model.md): 저장 원자는 **Work** — Franchise는 묶음·표시 레이어
- **IP 1카드** (Steam v1+): 그리드에서 동일 IP가 **중복 카드**로 늘어나면 안 됨
- [registry-scaling-review](../registry-scaling-review.md): 1M에서 franchise **전수 수동 큐레이션 불가** — tier·지연 생성 전제

---

## 2. 예시 케이스 (복잡도 스펙트럼)

| IP | 복잡도 | 구조 특성 | 현재 402 Registry |
|----|--------|-----------|-------------------|
| **Pokémon** | 낮음 | 단일 IP · 게임/애니/카드게임 다매체 | (미등록·단순 후보) |
| **Star Wars** | 중 | 우주 + 트리로지/시리즈/스핀오프 | (미등록) |
| **Gundam** | 중~높음 | 우주 + UC/CE/… 타임라인 | (미등록) |
| **Fate** | 높음 | 우주 + FSN/FGO/Hollow 등 | (미등록) |
| **Marvel** | 높음 | 우주 + MCU/팀/히어로 | (미등록) |
| **DC** | 높음 | Marvel과 유사 | (미등록) |
| **귀멸의 칼날** | 낮음 | 만화+애니+극장판 | ✅ `franchise_kimetsu` |

→ 단순·복합 IP를 **하나의 스키마**로 표현하되, **깊이는 IP 복잡도에 따라 선택** 적용.

---

## 3. 후보 모델

### 3.1 F0 — 평면 전용 (현행)

```
Franchise → [wk_, wk_, …]
```

| 장점 | 단점 |
|------|------|
| 구현·linter 단순 | Marvel 전체를 하나로 묶으면 **과대** · Avengers만 묶으면 **MCU 단절** |
| IP 1카드 명확 | 서브 IP를 Work `tags`로만 표현 → 검색·큐레이션 약함 |

### 3.2 F1 — 부모 포인터 (권장 초안)

```
Franchise (universe)  parent: null
  └─ Franchise (sub-ip)  parent: universe_id
       └─ members: [wk_, …]   ← Work만
```

| 규칙 | 내용 |
|------|------|
| `members` | **`wk_`만** — Franchise ID를 members에 **넣지 않음** |
| `parentFranchiseId` | 선택 · **최대 1부모** (트리) |
| 순환 | linter **금지** |
| 그리드 | §4 IP 1카드 규칙 |

**Q1 답 (F1):** Franchise **안에** Franchise를 members로 넣지 **않는다**.  
대신 **부모–자식 Franchise 노드**로 계층을 표현한다.

### 3.3 F2 — members에 Franchise 허용 (중첩)

```
Franchise_marvel.members = [ franchise_mcu, franchise_avengers, wk_… ]
```

| 장점 | 단점 |
|------|------|
| 직관적 «포함» | 해석 **재귀** · 그리드·검색·linter 복잡 |
| | IP 1카드 **이중 카드** 위험 |
| | 1M에서 역인덱스·사이클 검증 비용 ↑ |

**F2는 초안에서 기각 방향** — F1이 동일 표현력·낮은 복잡도.

### 3.4 F3 — Universe 전용 2계층 (고정 깊이)

- Depth **정확히 2**: `universe` → `sub_ip` → Work
- Marvel 3단(우주→팀→작품)에 **답답**할 수 있음

---

## 4. 결정 (초안) — F1 + 깊이 제한 + IP 1카드

### 4.1 통합 모델 (단순·복합 IP 공통)

| 필드 (제안) | 설명 |
|-------------|------|
| `id` | `franchise_*` (장기 `fr_` 검토) |
| `franchiseKind` | `ip` · `universe` · `subseries` · `collection` · `musical_act` |
| `parentFranchiseId` | null = 루트 |
| `members` | **`wk_`만** |
| `primaryWorkId` | 그리드·대표 매체 |
| `displayNames` | 로케일별 IP명 |

**단순 IP (Pokémon·귀멸):** `franchiseKind: ip` · `parent: null` · depth **1**  
**복합 IP (Marvel):** 루트 `universe` + 자식 `subseries` · depth **2~3**

### 4.2 Q2 — Marvel → Avengers → Endgame

| 계층 | 엔티티 | 예 |
|------|--------|-----|
| 우주 | Franchise `franchise_marvel` · kind=`universe` | Marvel |
| 서브 IP | Franchise `franchise_mcu` · parent=`marvel` | MCU |
| 팀/페이즈 (선택) | Franchise `franchise_avengers` · parent=`mcu` | Avengers |
| 작품 | Work `wk_…` · *Endgame* · member of `avengers` (또는 `mcu`) | 영화 1편 |

- *Endgame*은 **Work** ([ADR-005](ADR-005-minimum-recordable-unit.md) — 영화 1편)
- 중간 «Avengers»는 **필수 아님** — MCU만으로도 가능 (큐레이션 tier)
- **팀 Franchise**는 멤버 Work가 N개 이상일 때만 생성 (지연 생성)

### 4.3 Q3 — 단순 vs 복합 동일 모델?

**예.** 동일 스키마 · **깊이만 가변**:

| IP | franchiseKind | parent | depth |
|----|---------------|--------|-------|
| 귀멸 | `ip` | null | 1 |
| Pokémon | `ip` | null | 1 |
| Star Wars | `universe` | null | 1 |
| (선택) The Mandalorian | `subseries` | star_wars | 2 |
| Gundam | `universe` | null | 1 |
| (선택) Gundam UC | `subseries` | gundam | 2 |
| Fate | `universe` | null | 1 |
| FGO | `subseries` | fate | 2 |
| Marvel | `universe` | null | 1 |
| MCU | `subseries` | marvel | 2 |

단순 IP는 **항상 depth 1**로 끝 — 복합 IP만 2~3 확장.

### 4.4 Q4 — 최대 깊이

| 항목 | 초안 값 | 근거 |
|------|---------|------|
| **하드 맥스 depth** | **3** | universe → subseries → (optional) collection |
| **그리드 IP 1카드 해석 depth** | **2** (기본) | 사용자에게 보이는 카드는 **가장 구체적 subseries** 또는 설정한 루트 |
| **depth 4+** | **금지** | linter 거부 |

**collection** (depth 3): 「MCU Phase 3」처럼 **큐레이션 묶음** — Work 나열용, 필수 아님.

### 4.5 IP 1카드 정책 (장기)

그리드에 **동시에 올라가는 Franchise 카드**는 사용자·필터 컨텍스트당 **1장**.

| 규칙 | 내용 |
|------|------|
| **G1** | 동일 `wk_`가 여러 Franchise에 속할 수 있으나, **그리드에는 1카드만** |
| **G2** | 기본: **가장 깊은 (가장 구체적인) Franchise** 1개를 display anchor |
| **G3** | 사용자 설정 (장기): 「MCU만 보기」vs 「Marvel 전체」→ anchor를 **조상**으로 승격 |
| **G4** | 조상 Franchise 카드가 뜨면 **자손 소속 Work는 형제 카드로 중복 금지** (현 `isSiblingCovered` 확장) |
| **G5** | 루트만 있고 자식 없는 IP — 현행과 동일 (귀멸·포케몬) |

**검색**은 Work 단위 유지 ([SW1](../global-search-validation-plan.md)) — Franchise 계층은 **표시·browse** 우선.

---

## 5. 규모 · 운영 (수백만 Work)

[registry-scaling-review](../registry-scaling-review.md) 교훈 반영:

| 정책 | 내용 |
|------|------|
| **전수 Franchise** | 1M Work마다 Franchise **강제 생성 금지** |
| **Tier 0** | 다매체·검색 충돌·linter 후보 — Franchise 생성 |
| **Tier 1** | 복합 IP **universe** 루트만 — subseries는 수요 시 |
| **Tier 2** | Marvel급 subseries·collection — **human queue** |
| **파일** | `franchise_groups` **분할** (hash/alphabet) — 단일 25MB 파일 회피 |
| **members 상한** | Franchise당 Work 수 soft cap (예: 500) — 초과 시 collection 분할 |

**붕괴 정의 (검증):**

- 그리드 duplicate rate > 0
- 사이클·orphan parent
- 루트 Franchise 수 >> 큐레이션 용량
- franchise parse/메모리가 search_index 다음 병목

---

## 6. 예시 케이스 매핑 (초안)

### 6.1 Pokémon (단순 · depth 1)

```
franchise_pokemon (ip, parent=null)
  members: [ game_red, game_sv, anime_series, … ]
```

### 6.2 Star Wars (중간 · depth 1~2)

```
franchise_star_wars (universe)
  ├─ (optional) franchise_mandalorian (subseries) → tv Work
  └─ members: [ original_trilogy films, … ]  // 또는 film별 Work만 루트에
```

### 6.3 Gundam (복합 타임라인)

```
franchise_gundam (universe)
  ├─ franchise_gundam_uc (subseries) → UC 작품 Works
  ├─ franchise_gundam_ce (subseries) → SEED 등
  └─ …
```

### 6.4 Fate (다작품 우주)

```
franchise_fate (universe)
  ├─ franchise_fsn (subseries)
  ├─ franchise_fgo (subseries) → game Work
  └─ …
```

### 6.5 Marvel / DC (최대 복잡도)

```
franchise_marvel (universe)
  └─ franchise_mcu (subseries)
       ├─ franchise_avengers (subseries, optional)
       │    └─ members: [ wk_endgame, wk_infinity_war, … ]
       └─ members: [ other mcu films … ]
```

```
franchise_dc (universe)
  └─ franchise_dcau / franchise_dceu (subseries) — **동시 존재** 가능 (형제)
```

**DC vs Marvel:** 동일 F1 모델 · **큐레이션 독립**.

---

## 7. URV 검증 시나리오 (ADR-006)

### 7.1 구조 · 경계

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-FH01 | 귀멸 — depth 1 | parent=null · 그리드 1카드 |
| URV-FH02 | Pokémon — 게임+애니 | 단일 `ip` Franchise · members≥2 |
| URV-FH03 | Marvel → MCU → Endgame | depth≤3 · Endgame=**Work** |
| URV-FH04 | members에 `franchise_mcu` 넣기 | linter **거부** (F1) |
| URV-FH05 | parent 순환 A→B→A | linter **거부** |
| URV-FH06 | depth 4 생성 | linter **거부** |
| URV-FH07 | Endgame을 marvel+mcu+avengers에 중복 소속 | 허용 · **그리드 G2**로 1카드 |
| URV-FH08 | Fate FGO만 아카이브 | anchor=`franchise_fgo` · `fate` 루트 카드 **중복 없음** |

### 7.2 IP 1카드 (G1~G5)

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-FH10 | MCU 영화 3편 사용자 보유 | 그리드 **1카드** (not 3) |
| URV-FH11 | Marvel 루트 표시 설정 | 1카드 anchor=marvel · 칩으로 MCU |
| URV-FH12 | 형제 subseries (UC vs CE) | 각각 별도 카드 · Work 중복 없음 |

### 7.3 규모

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-FH20 | synthetic 1M Work · 50k Franchise | 파일 분할 · parse < budget |
| URV-FH21 | Franchise members 600 | soft cap 경고 · collection 분할 제안 |
| URV-FH22 | Tier0만 자동 · Marvel subseries | human queue 길이 측정 |
| URV-FH23 | franchise_groups 25MB 단일 | **FAIL** → 분할 설계 |

### 7.4 SW1 · ADR 교차

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-FH30 | 「Marvel」검색 | Franchise displayNames + 멤버 Work hit |
| URV-FH31 | 「Avengers Endgame」검색 | **Work** hit · Franchise명만으로는 부족 시 titles 보강 |

---

## 8. F1 vs 대안 요약

| 질문 | F1 (초안) |
|------|-----------|
| Franchise 안에 Franchise? | members **불가** · `parentFranchiseId`로 계층 |
| 다단계 Marvel? | **허용** depth ≤3 |
| Pokémon = Marvel 모델? | **동일 스키마** · Pokémon은 depth 1 |
| 최대 깊이? | **3** hard · 그리드 anchor 기본 **leaf subseries** |

---

## 9. 미결정

| # | 항목 |
|---|------|
| O1 | `fr_` 정식 ID vs `franchise_*` |
| O2 | Work가 여러 subseries에 속할 때 primary 규칙 |
| O3 | `collection` depth-3를 CI에서 필수로 할지 |
| O4 | 사용자 anchor 선택 UX 시점 |
| O5 | franchise_groups 분할 키 (hash vs locale) |
| O6 | members soft cap 숫자 (500 vs 1000) |

---

## 10. URV-A 선행 체크리스트 (갱신)

- [x] ADR-001 Dual-layer
- [x] ADR-003 에피소드 Registry 밖
- [x] ADR-004 2차 창작 분리
- [ ] ADR-005 매체 표 (음악 ADR-002)
- [ ] **ADR-006 F1 승인** (본 문서)
- [ ] ADR-002 A vs B (B안 **가중** — 리뷰어 선호 기록)

---

## 11. 대안 기각 · 보류

| 안 | 처리 |
|----|------|
| F0 평면만 (영구) | **복합 IP 불가** — 장기 기각 |
| F2 members 중첩 Franchise | **재귀·이중 카드** — 기각 방향 |
| depth 무제한 | **기각** |
| IP 1카드 폐기 | **기각** (제품 핵심) |
