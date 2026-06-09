# Sprint 04 Charter — externalId G2 50% 검증

> **목적:** Sprint 04 **시작 여부 최종 결정**을 위한 Sprint 정의.  
> **범위:** externalId **14.9% → G2 50%** — Economics·Quality **동시 검증**.  
> **전제:** Sprint 01~03 완료 · [externalid-economics-plan.md](externalid-economics-plan.md) · [externalid-quality-risk-review.md](externalid-quality-risk-review.md)  
> **기준일:** 2026-06-09 · Registry **402작**

**금지 (본 문서 작성 시점):** enrich 실행 · 실험 실행 · 구조 변경 · 신규 provider.

**Charter 연계:** [phase2-charter.md](phase2-charter.md) §5 **#4** — externalId coverage **≥ 50% (G2)** · [phase2-late-stage-plan.md](archive/phase2-late-stage-plan.md) **Q2**.

### Sprint 04 레이어 (R1 / R2)

| 레이어 | 기준 Registry | 내용 | SSOT |
|--------|:-------------:|------|------|
| **04-R1** | **402작** | 1차 externalId apply (+141) · Economics·G2 **@402 달성** | [sprint-04-final-review.md](archive/sprint-04-final-review.md) *(superseded · 아카이브)* |
| **04-R2** | **430작** | Scale 이후 재기준선 · Phase A baseline · Phase B 품질 감사 · 잔여 15건 | [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md) · [sprint-04-baseline-report.md](sprint-04-baseline-report.md) |

**현재 운영·수치:** **04-R2** (@430 · externalId **46.74%**) — 본 Charter의 **402작 수치는 04-R1 착수 정의**이며 R2 SSOT가 **아님**.

---

## Executive Summary

| 항목 | 값 |
|------|-----|
| **Sprint** | **04** — externalId G2 50% |
| **현재** | **60/402 (14.9%)** |
| **목표** | **201/402 (50.0%)** — **+141작** |
| **In scope** | **E1** Steam cohort · **E2** TMDB poster cohort |
| **Out of scope** | titles.en · zh · 신규 provider · 구조 변경 |
| **착수 전 검토** | Economics Plan ✅ · Quality Risk Review ✅ — **충분** |

**Sprint 04 한 줄:** poster·legacy 신호 기반 **+141작 externalId attach**를 실행하고, **G2 달성·회귀·감사**로 Economics·신뢰를 **실측**한다.

---

## 1. 목표

### 1.1 Primary

| # | 목표 | baseline (Sprint 03) | Sprint 04 target |
|---|------|:--------------------:|:----------------:|
| **G2-1** | **externalId coverage** | **60/402 (14.9%)** | **≥201/402 (50.0%)** |
| **G2-2** | **Charter §5 #4** | FAIL | **PASS** |

```
현재:  60/402 (14.9%)
목표: 201/402 (50.0%)
갭:   +141 works with non-empty externalIds
```

### 1.2 Secondary (Sprint 04에서 측정·문서화)

| # | 목표 | 비고 |
|---|------|------|
| **G2-3** | Sprint 02 externalId Economics **추정 vs 실측** | titles.en Sprint 03과 **동형** 검증 |
| **G2-4** | poster-priority cohort **automation 비율** | E1+E2가 +141의 **공급원** |
| **G2-5** | externalId attach **품질 이슈** 정량화 | Quality Risk Review 후속 |

### 1.3 Non-goals

- Phase 2 **90%** externalId milestone (+302작) — **Sprint 04 범위 외**
- **zh** · **titles.en** 추가 enrich
- 신규 external provider (IGDB · openlibrary 등 **신규 도입**)
- Registry · Franchise · search_index **구조 변경**

---

## 2. 범위

### 2.1 In scope — cohort 전략

[externalid-economics-plan.md](externalid-economics-plan.md) §4.2 실행 순서.

| Phase | cohort | 모집단 | 예상 규모 | 공급원 | attach 방식 |
|:-----:|--------|--------|:---------:|--------|-------------|
| **E1** | Steam poster · ext 없음 | 미보유 342 중 game-heavy | **≤125** | `externalIds.steam` | `posterPath` / legacy `appid{n}` **deterministic** |
| **E2** | TMDB poster · ext 없음 | animation · manga · drama 등 | **≤31** | `externalIds.tmdb` | poster 캐시 · `posterSource:tmdb` resolve |
| **E3** | G2 잔여 (필요 시) | E1+E2 후 미달분 | **≤141−E1−E2** | E1/E2 혼합 | E1+E2 **≥141**이면 **E3 생략** |

**판단 (계획):** E1 **125** + E2 **31** = **156 ≥ 141** — G2 50%는 **E1+E2만**으로 달성 가능.

### 2.2 실행 산출 (Sprint 착수 후)

| 산출 | 용도 |
|------|------|
| `coverage_snapshot.json` | externalId KPI |
| `sprint_04_externalid.json` (가칭) | wall · human-eq · method mix |
| `externalid_audit_sample.json` (가칭) | spot-check 기록 |
| shard patch · `registry_builder` | E4 게이트 ([coverage-quality-governance.md](coverage-quality-governance.md)) |

### 2.3 도구·게이트 (기존)

| 도구 | 역할 |
|------|------|
| `coverage_dashboard.dart` | KPI · quality 섹션 |
| `quality_gate.dart` | `--strict` · `--release` |
| `sw1_a_validation.dart` | recall@10 회귀 |
| `urv_a_validation.dart` | exactId · duplicate |
| `poster_verification.dart` | TMDB poster ↔ id |

---

## 3. 제외 범위

| # | 제외 | 근거 |
|---|------|------|
| **X1** | **titles.en** enrich | Sprint 03 **91.5%** · Sprint 04는 **externalId 축** |
| **X2** | **zh** enrich | [phase2-late-stage-plan.md](archive/phase2-late-stage-plan.md) **Q1** — 별 Sprint |
| **X3** | **신규 provider** | IGDB · openlibrary 등 **402 내 미사용** — 도입은 구조·공급 검토 필요 |
| **X4** | **구조 변경** | Phase 2 거버넌스 · ADR-006 franchise 정책 **유지** |
| **X5** | **E4 manual 대량** (186작) | G2 달성에 **불필요** (E1+E2 충분) — 50% 초과 시 **후속** |
| **X6** | Quality Gate MVP **코드 확장** | Steam validator · RB 연동 — Sprint 04 **후속** 가능 (착수 **blocking 아님**) |

**원칙:** Sprint 04는 **기존 신호·기존 키** (`steam` · `tmdb`)만 사용한다.

---

## 4. 성공 조건

Sprint 04 **종료 시** 아래 **전부** 충족 시 **성공**.

| # | 조건 | 측정 | baseline |
|---|------|------|----------|
| **S1** | **G2 50% 달성** | `kpis.external_id` **≥201/402** | 60/402 |
| **S2** | **SW1 회귀 없음** | recall@10 **≥ Sprint 03 (100%)** | 100% |
| **S3** | **URV 회귀 없음** | convergence **≥ Sprint 03** · verdict **≥ PARTIAL** | Sprint 03 PASS/PARTIAL |
| **S4** | **URV exactId** | **100%** (ID 보유 작품) | 60/60 |
| **S5** | **Quality Gate 통과** | `quality_gate --strict` **PASS** | invalid_en **0** |
| **S6** | **비형제 duplicate** | URV `duplicateExternalKeyPairs` **= 0** | Sprint 03 기준 |
| **S7** | **감사 완료** | §5 감사 조건 **충족** | — |

**실패 정의:**

| 실패 | 의미 |
|------|------|
| S1 미달 | Charter §5 #4 **미달** — Phase 2 **종료 불가** (Charter 기준) |
| S2–S4 회귀 | externalId ramp가 **identity 구조** 훼손 — **롤백** |
| S5 실패 | titles.en **연쇄 오염** — 배치 중단 |
| S7 미달 | Coverage만 달성 · **신뢰 미확보** — release **보류** |

---

## 5. 감사 조건

[externalid-quality-risk-review.md](externalid-quality-risk-review.md) §4–§5.

### 5.1 필수 (Sprint 04 blocking)

| # | cohort | 규모 | 요구 |
|---|--------|:----:|------|
| **A1** | **E2 TMDB** | **31작** | **100% spot-check** · `isPosterVerified` **true** (poster 있음) |
| **A2** | **E1 Steam** | attach **전건** | **감사 계획 실행** (아래 §5.2) |
| **A3** | **URV duplicate** | 신규 attach 후 | 비형제 중복 **0건** 확인 |
| **A4** | **자동 회귀** | 전 registry | SW1 · URV · `quality_gate --strict` **매 배치** |

### 5.2 E1 Steam cohort 감사 계획

Steam은 **자동 교차검증 없음** ([externalid-quality-risk-review.md](externalid-quality-risk-review.md) B1–B2) — Sprint 04 **최대 리스크**.

| 수준 | Steam spot-check | 적용 |
|------|------------------|------|
| **최소선** | attach 건 중 **≥15작 (10%)** | [quality-gate-mvp.md](quality-gate-mvp.md) auto tier SLA |
| **권장선 (Charter 채택)** | **E1 attach 전건 100%** | 첫 Steam 대량 배치 · blind spot 완화 |

**1작당 체크리스트 (수동):**

| # | 항목 |
|---|------|
| C1 | Steam store 제목 ≈ `title` / `titles.en` |
| C2 | 연도·시리즈·remake/remaster **일치** |
| C3 | franchise 형제와 ID 공유 **의도 확인** |
| C4 | URV duplicate 리포트 **신규 비형제 없음** |

**감사 실패 시:** 해당 작품 **ID 제거 또는 수정** · cohort **재감사** · S7 미충족 시 Sprint **미완료**.

### 5.3 Release 연계 (soft block)

감사 미완 · Steam 권장선(100%) 미달 시 **`--release` 보류** — [externalid-quality-risk-review.md](externalid-quality-risk-review.md) §6.4.

```
BLOCK (hard)   quality_gate --strict FAIL
BLOCK (hard)   SW1/URV < baseline
BLOCK (soft)   externalId audit incomplete
BLOCK (soft)   URV duplicateExternalKeyPairs > 0 (비형제)
ALLOW          위 clear + kpis.external_id ≥ 50%
```

**override:** 감사 미완은 **override 불가** (문서 정책).

---

## 6. 종료 후 평가 항목

Sprint 04 **종료 보고** (Mid-Review Sprint 03 형식)에 포함.

### 6.1 Economics 실측

| 지표 | Sprint 02 추정 (G2) | Sprint 04 실측 목표 |
|------|:-------------------:|---------------------|
| additionalWorks | **+141** | 실제 attach 수 |
| estimatedHours | **18.8h** (manual 0%) | human-equivalent |
| wall clock | 미측정 | 스크립트·배치 타이밍 |
| Δ (추정 vs 실측) | — | **문서화 필수** |

**가설 (검증 대상):** poster-priority **4.7–12h** human-eq ([externalid-economics-plan.md](externalid-economics-plan.md) §5.2).

### 6.2 Automation 비율

| 측정 | 정의 |
|------|------|
| **auto** | E1 URL/legacy · E2 poster resolve **무수동** |
| **semi** | resolve 실패 → 수동 보정 **1회** |
| **manual** | ID 소스 없음 · E3 fallback |

**보고:** method mix **%** · E1 vs E2 분리 · Sprint 02 tier **0%** 가정과 비교.

### 6.3 Quality 이슈 수

| 카테고리 | 기록 |
|----------|------|
| 잘못된 Steam appId | 감사 C1–C2 **FAIL** 건수 |
| 잘못된 TMDB id | `isPosterVerified` false · A1–A2 FAIL |
| franchise 혼동 | C3 / A3 이슈 |
| remake/remaster | C2 이슈 |
| URV duplicate (비형제) | **0** 목표 · 초과 시 **blocking** |
| remediate 건수 | ID 제거·교체 |

**목표:** Quality 이슈 **정량화** — Sprint 05 (zh · 90% externalId) **리스크 입력**.

---

## 7. Sprint 04 시작 여부 — 최종 결정

### 7.1 착수 전제 (검토 완료)

| # | 전제 | 상태 |
|---|------|:----:|
| P1 | Sprint 01~03 · titles.en Economics **검증** | ✅ |
| P2 | [externalid-economics-plan.md](externalid-economics-plan.md) — G2 경로 **존재** | ✅ |
| P3 | [externalid-quality-risk-review.md](externalid-quality-risk-review.md) — blind spot·감사 **정의** | ✅ |
| P4 | Quality Gate MVP · `quality_gate --strict` **PASS** (현 registry) | ✅ |
| P5 | Phase 2 **구조 변경 금지** 합의 | ✅ |

### 7.2 Go / No-Go

| 결정 | 조건 |
|------|------|
| **GO** | P1–P5 충족 · 본 Charter **승인** · §5 감사(Steam **권장선 100%**) **합의** |
| **NO-GO** | P4 FAIL · Quality Risk 미합의 · Steam 감사 **최소선만** 합의 불가 시 **보류** |
| **DEFER** | zh·composite Q3를 **선행** — Charter 우선순위 **P1=externalId** 유지 권고 |

### 7.3 권고 판정 (2026-06-09)

| 질문 | 답 |
|------|-----|
| **Sprint 04 착수 전 검토 충분한가?** | **예** — Economics·Quality Risk **완료** |
| **지금 enrich 실행?** | **아니오** — Charter **승인 후** 착수 |
| **Sprint 04 시작 권고?** | **GO (조건부)** — E1 Steam **100% 감사** · E2 **31작 전수** · 배치마다 S2–S5 |

**조건부 GO 요약:** Economics 경로는 있으나 **신뢰는 감사에 의존**. Sprint 04는 *늘릴 수 있는가*가 아니라 *늘려도 신뢰할 수 있는가*를 **실측으로 닫는** Sprint다.

---

## 8. 일정·역할 (계획)

| 단계 | 내용 |
|------|------|
| **0. Charter 승인** | 본 문서 · §5.2 Steam **100%** 합의 |
| **1. E2 TMDB** | ≤31작 · poster resolve · **전수 감사** |
| **2. E1 Steam** | ≤125작 중 +141까지 · **전수 감사 (권장)** |
| **3. E3 (선택)** | G2 미달 시만 |
| **4. E4–E7** | builder · dashboard · 회귀 · invalid scan |
| **5. 종료 보고** | §6 평가 · assumption-register 갱신 |

**예상 human-equivalent (가설):** **4.7–18.8h** — 실측으로 확정.

---

## 9. 문서 맵

| 문서 | 역할 |
|------|------|
| [sprint-04-charter.md](sprint-04-charter.md) | **본 문서** — Sprint 정의·GO/NO-GO |
| [externalid-economics-plan.md](externalid-economics-plan.md) | cohort · 비용 가설 |
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | 리스크 · 감사 규모 |
| [coverage-quality-governance.md](coverage-quality-governance.md) | E/I/R 게이트 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | `--strict` · release |
| [phase2-charter.md](phase2-charter.md) | Phase 2 G2 목표 |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — enrich 미실행 · 착수 전 검토 완료 반영 |
