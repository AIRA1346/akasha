# externalId Quality Risk Review

> **목적:** externalId **확대 시** 품질·신뢰 리스크를 평가한다.  
> **질문:** *「externalId를 늘릴 수 있는가?」* (Economics) 가 아니라 *「externalId를 늘려도 **신뢰할 수 있는가?」***  
> **전제:** [externalid-economics-plan.md](externalid-economics-plan.md) · [quality-gate-mvp.md](quality-gate-mvp.md) · Sprint 03 이후  
> **기준일:** 2026-06-09 · Registry **402작**

**금지:** enrich · 실험 실행 · 구조 변경 · 신규 ADR.

---

## Executive Summary

| 층 | 판정 |
|----|------|
| **Economics (G2 50%)** | 경로 **존재** — Steam poster **125** + TMDB gap **31** ≥ **+141** |
| **Quality (신뢰)** | **부분 통제** — TMDB는 `poster_verification` · URV exactId **있음** · Steam auto attach는 **교차검증 없음** |
| **Quality Gate MVP** | `titles.en` **만** — **externalId 오류는 RB1/RB2 미포함** |
| **Sprint 04 권고** | enrich 전 **감사 샘플·spot-check 필수** — Release Block은 **externalId 전용 규칙 추가 전 soft gate** |

**한 줄:** externalId를 늘리는 것은 가능하나, **Steam cohort(125)** 는 자동화 이득이 크고 **품질 리스크도 가장 큼**. Sprint 04는 Economics와 **동시에** 최소 감사 없이 release 하지 않는다.

---

## 1. externalId 오류 유형

> 확인 근거: Sprint 01~03 · `poster_verification.dart` · `urv_a_validation.dart` · [externalid-economics-plan.md](externalid-economics-plan.md) · franchise 정책(ADR-006).

### 1.1 잘못된 Steam appId

| 항목 | 내용 |
|------|------|
| **메커니즘** | `posterPath` / legacy `appid{n}` → `externalIds.steam` 복사 |
| **현황** | 보유 60작 중 **Steam 0** — Sprint 04 **E1**에서 **≤125작** 신규 예정 |
| **오류 시나리오** | 잘못된 legacy · 번들/데모 URL · **리마스터 별도 app** · DLC appId |
| **영향** | dedupe **exactId 오염** · 잘못된 store 링크 · franchise 비형제 **중복 키** |
| **현재 완화** | Sprint 03 `steam_fetch`는 **제목**용 — externalId attach는 **별 경로** (미실측) |

### 1.2 잘못된 TMDB id

| 항목 | 내용 |
|------|------|
| **메커니즘** | TMDB poster 보유 · `posterSource:tmdb` → ID resolve |
| **현황** | 보유 **60/60 TMDB** · poster 있으나 ext 없음 **31작** |
| **오류 시나리오** | **tv vs movie** · 시즌/극장판 ID · 동명이작 · 지역별 다른 엔트리 |
| **영향** | `titles.en` Sprint 03 — TMDB HTML **31건** 오염(제목) · ID 오류는 **poster 불일치**로 간접 탐지 가능 |
| **현재 완화** | `isPosterVerified()` — TMDB poster ↔ `externalIds.tmdb` + 캐시 **일치** ([poster_verification.dart](../tool/poster_verification.dart)) |

### 1.3 franchise 혼동

| 항목 | 내용 |
|------|------|
| **메커니즘** | 동일 IP · spinoff · 시즌별 Work — `franchise_groups` 형제 |
| **오류 시나리오** | 형제 Work에 **동일 externalKey** · primary가 아닌 쪽에 ID 부착 |
| **영향** | URV **duplicateExternalKeyPairs** — franchise sibling은 **의도적 제외** ([urv_a_validation.dart](../tool/urv_a_validation.dart)) |
| **현재 완화** | URV duplicate 검사 · franchise peer 예외 — **오류 은폐 가능** (형제 간 ID 공유는 정책상 허용될 수 있음) |

### 1.4 remake / remaster 혼동

| 항목 | 내용 |
|------|------|
| **메커니즘** | 동일 타이틀 · 다른 연도/app — 별도 `wk_` |
| **오류 시나리오** | `gen_game_appid1145350` (Hades II) vs 구작 · **디플리케이트/리마스터** Steam 엔트리 |
| **영향** | 검색 제목은 맞아도 **store·메타**가 다른 작품 — SW1 **미검출** 가능 |
| **현재 완화** | **없음** (자동) — releaseYear · legacy slug **수동 대조** |

### 1.5 region / version 혼동

| 항목 | 내용 |
|------|------|
| **메커니즘** | TMDB 다국어 엔트리 · Steam 지역화 페이지 |
| **오류 시나리오** | 현지화 제목·부제 다른 엔트리 · **극장판/특별편** 별도 ID |
| **영향** | `titles.en` 품질과 **연동** · externalId만 맞고 표면형 불일치 |
| **현재 완화** | `titlesMatchWork` (TMDB **제목** fetch 시) — **ID attach 전용 검증 없음** |

### 1.6 오류 유형 요약

| 유형 | Sprint 04 노출도 | 심각도 |
|------|:----------------:|:------:|
| 잘못된 Steam appId | **높음** (E1 ≤125) | **높음** |
| 잘못된 TMDB id | 중간 (E2 ≤31) | 중간–높음 |
| franchise 혼동 | 중간 | 중간 |
| remake/remaster | 중간 (game) | 중간 |
| region/version | 낮음–중간 | 중간 |

---

## 2. 현재 Quality Gate가 잡을 수 있는 것

**도구:** `coverage_quality.dart` · `quality_gate.dart` · `coverage_dashboard` `quality` 섹션.

| # | 검증 | externalId 연계 | 한계 |
|---|------|-----------------|------|
| G1 | **`titles.en` syntactic** (`validateEnTitle`) | 간접 — 잘못된 fetch **후** 제목 오염 | ID 자체 **미검증** |
| G2 | **`source_breakage_count`** | auto-tier + invalid `titles.en` | externalId attach **미포함** |
| G3 | **Release Block RB1/RB2** | invalid-en · source_breakage | **externalId 무관** |
| G4 | **SW1 recall@10 ≥ baseline** | 402 쿼리 · **ID 오류 대부분 미반영** | 하한만 |
| G5 | **URV exactId ingress** | stub이 **동일 work**로 merge되는지 | **키가 index에 있으면** 통과 — **타작품 ID**는 별도 검사 없음 |
| G6 | **URV duplicate external key** | 비형제·동 category **중복 키** | franchise sibling **제외** |
| G7 | **`isPosterVerified` (TMDB)** | poster URL ↔ tmdb id **캐시 일치** | **TMDB만** · 60작+31 후보 |
| G8 | **`extensions.posterVerified`** | 메타 플래그 | TMDB는 **캐시 일치 없으면 false** |

**TMDB 보유 60작:** poster 검증 체계 **이미 존재** — Sprint 04 E2는 이 **레일 위**에서 리스크 **상대적으로 낮음**.

**Steam 125작:** `poster_verification` — non-TMDB host는 **무조건 verified=true** (검증 생략). → **자동 externalId attach에 대한 게이트 없음**.

---

## 3. 현재 Quality Gate가 못 잡는 것

| # | blind spot | 예시 | Sprint 04 영향 |
|---|------------|------|----------------|
| B1 | **Steam appId ↔ store 정합** | URL 파싱 오타 · 잘못된 app | **E1 전체** |
| B2 | **Steam appId ↔ 작품 identity** | 리마스터·번들 | game **140** |
| B3 | **TMDB id 의미적 정확도** | tv/movie 혼동 · 동명이작 | E2 **31** |
| B4 | **ID만 맞고 제목/표면형 불일치** | region 엔트리 | SW1 **PASS 가능** |
| B5 | **franchise 내 ID 배치** | spinoff에 시리즈 ID | duplicate 검사 **스킵** |
| B6 | **stale / 폐기 app** | Steam delist | 런타임 fetch **없음** |
| B7 | **source HTML/API 변경** | Steam/TMDB 스크래핑 | titles.en 사고와 **동형** |
| B8 | **externalId syntax** | 빈 문자열·음수 id | **전용 validator 없음** (MVP) |
| B9 | **Coverage 수량만 올린 ID** | KPI 50% 달성 · 신뢰 실패 | `kpis.external_id` **PASS 가능** |

**핵심:** MVP Quality Gate는 **`titles.en` 축** — externalId 신뢰는 **URV partial + poster(TMDB) + 수동**에 의존.

---

## 4. spot-check 필요 영역

[coverage-quality-governance.md](coverage-quality-governance.md) M1–M7 · [externalid-economics-plan.md](externalid-economics-plan.md) cohort 기준.

| 우선순위 | 영역 | 대상 규모 | spot-check 초점 |
|:--------:|------|:---------:|-----------------|
| **P0** | **Steam auto attach (E1)** | **≤125** | appId ↔ store 제목 ↔ `work.title`/`titles.en` |
| **P1** | **TMDB gap (E2)** | **≤31** | ID ↔ poster 캐시 · tv/movie · 시즌 |
| **P2** | **franchise spinoff** | franchise_non_primary **64** (Sprint 03 KPI) | 형제 간 **동일 키** 의도 여부 |
| **P3** | **remake/remaster game** | legacy `appid` 다수 | 연도·부제·시리즈 구분 |
| **P4** | **animation/movie TMDB** | E2 + 기존 60 | 극장판 vs 시리즈 |
| **P5** | **book/manual cohort** | **186** (50% 이후) | openlibrary 등 — Sprint 04 **범위 외** |

**권장 SLA (문서·[quality-gate-mvp.md](quality-gate-mvp.md) 정합):**

| tier | Sprint 04 attach | spot-check |
|------|------------------|------------|
| Steam URL/legacy **auto** | E1 | **≥10%** 최소 · **첫 배치 100%** 권장 (titles.en TMDB 31건 교훈) |
| TMDB poster **auto** | E2 | **100%** (≤31작 — 규모 작음) |
| manual | E4+ | **100%** |

---

## 5. Sprint 04 최소 감사 샘플 규모

**전제:** [externalid-economics-plan.md](externalid-economics-plan.md) — G2 50% **+141작** · E1+E2 poster 우선.

### 5.1 최소선 (통계·거버넌스)

| 감사 축 | 모집단 | 최소 샘플 | 근거 |
|---------|--------|:---------:|------|
| **Steam E1** | ≤125 (실제 +141 중 대부분) | **15작** (10%) | [quality-gate-mvp](quality-gate-mvp.md) auto tier |
| **TMDB E2** | ≤31 | **31작 (100%)** | 규모 작음 · tv/movie 리스크 |
| **합계 최소** | +141 | **≥15 Steam + 31 TMDB = 46** | TMDB 전수 + Steam 10% |

### 5.2 권장선 (첫 externalId 대량 배치)

| 감사 축 | 권장 샘플 | 근거 |
|---------|:---------:|------|
| **Steam E1** | **141작 중 Steam attach 전건 100%** | Steam **검증기 없음** · B1–B2 |
| **TMDB E2** | **31작 100%** | 동일 |
| **franchise overlap** | duplicate 후보 **전건** (URV 리포트) | B5 |
| **회귀** | SW1 · URV · `quality_gate --strict` | **전수 실행** (자동) |

### 5.3 감사 체크리스트 (수동 · 1작당)

| # | 항목 |
|---|------|
| A1 | store/TMDB 페이지 제목 ≈ registry `title` / `titles.en` |
| A2 | 연도·시리즈·부제 **일치** (remake/remaster) |
| A3 | franchise 형제와 **ID 공유 의도** 확인 |
| A4 | TMDB: `isPosterVerified` **true** (해당 시) |
| A5 | URV duplicate 리포트에 **신규 비형제 중복 없음** |

**산출 (Sprint 04 계획):** `externalid_audit_sample.json` (가칭) — **실험 시** 기록, 본 문서는 규모만 정의.

---

## 6. Release Block 필요 여부

### 6.1 현재 상태

| 규칙 | externalId 적용 |
|------|-------------------|
| `quality_gate --release` RB1 | invalid `titles.en` — **간접만** |
| RB2 | `source_breakage_count` — **titles.en** auto 오염 |
| `kpis.external_id` PASS | **수량만** — **신뢰 미보장** |
| `isPosterVerified` | TMDB — **release CLI 미연동** |

**결론:** **externalId 전용 Release Block은 MVP에 없음.**

### 6.2 Sprint 04 권고

| 수준 | 규칙 | 필요 여부 |
|------|------|:---------:|
| **Hard block (자동)** | `invalid_external_id_count > 0` | ⏳ **후속** — syntax validator·Steam probe 없음 |
| **Hard block (자동)** | TMDB `isPosterVerified == false` (poster 있음) | ⏳ **후속** — `quality_gate` 확장 |
| **Hard block (자동)** | URV `duplicateExternalKeyPairs > 0` (비형제) | ✅ **권장** — 기존 URV **이미 계산** · `--release` **연동 후속** |
| **Soft block (운영)** | Sprint 04 **감사 샘플 미완** → `--release` 보류 | ✅ **필수 권장** |
| **Soft block (운영)** | Steam spot-check **< 100%** (첫 배치) → merge 보류 | ✅ **권장** |

### 6.3 판정 요약

| 질문 | 답 |
|------|-----|
| **지금 당장 externalId용 RB를 코드에 넣어야 하는가?** | **TMDB poster 실패·URV duplicate** 연동은 **가치 있음** — 구현은 Sprint 04 **후속** 가능 |
| **Sprint 04 without Release Block?** | **불가 권고** — 최소 **soft block** (감사 46+작 + 회귀 100% + `quality_gate --strict`) |
| **Economics만 달성하고 release?** | **거부** — [phase2-governance-review.md](phase2-governance-review.md) Coverage≠Quality |

### 6.4 Release 의사결정 (Sprint 04 계획)

```
BLOCK (hard)   if quality_gate --strict FAIL
BLOCK (hard)   if SW1/URV < baseline
BLOCK (soft)   if externalId audit sample incomplete
BLOCK (soft)   if URV duplicateExternalKeyPairs > 0 (비형제)
ALLOW          if above clear + kpis.external_id ≥ 50%
```

**override:** [quality-gate-mvp.md](quality-gate-mvp.md) — `quality_gate_override.json` · **감사 미완은 override 불가** (문서 정책 권장).

---

## 7. Sprint 04 진행 조건 (Quality 관점)

Economics Plan **In scope**에 더해, Quality **게이트 없이 착수 금지**:

| # | 조건 |
|---|------|
| Q1 | 본 문서 **감사 규모** (§5.2 권장선) 합의 |
| Q2 | E1 Steam **100% spot-check** 또는 최소 15작 + 실패 시 전수 |
| Q3 | E2 TMDB **31작 100%** + `isPosterVerified` |
| Q4 | URV **exactId 100%** · duplicate **0** (비형제) 유지 |
| Q5 | `quality_gate --strict` **PASS** (titles.en) |

---

## 8. 문서 맵

| 문서 | 역할 |
|------|------|
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | **본 문서** — 신뢰 리스크 |
| [externalid-economics-plan.md](externalid-economics-plan.md) | Economics · cohort |
| [quality-gate-mvp.md](quality-gate-mvp.md) | 현재 자동 게이트 |
| [coverage-quality-governance.md](coverage-quality-governance.md) | spot-check SLA |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 현재 도구·402 데이터만 (enrich·실험 없음) |
