# Sprint 04 Readiness Review — 착수 승인 판정

> **목적:** Sprint 04 **착수 승인 여부** 최종 판정.  
> **범위:** externalId G2 50% — [sprint-04-charter.md](../sprint-04-charter.md) 실행 대기 상태 검증.  
> **기준일:** 2026-06-09 · Registry **402작**

**금지:** 새 분석 · 새 실험 · 새 구조 논의 · enrich 실행.

**근거 문서만 사용:** [sprint-04-charter.md](../sprint-04-charter.md) · [externalid-economics-plan.md](externalid-economics-plan.md) · [externalid-quality-risk-review.md](../externalid-quality-risk-review.md) · [phase2-governance-review.md](../phase2-governance-review.md) · [quality-gate-mvp.md](../quality-gate-mvp.md) · [phase2-late-stage-plan.md](phase2-late-stage-plan.md) · [phase2-charter.md](../phase2-charter.md) · [coverage-quality-governance.md](../coverage-quality-governance.md) · [phase2-mid-review.md](phase2-mid-review.md).

---

## Executive Summary

| 층 | 판정 |
|----|------|
| **계획** | ✅ 완료 — Charter · Economics · Quality Risk |
| **거버넌스** | ✅ P0 G1–G5 충족 |
| **실행 준비** | △ — attach **도구 미구현** (문서화됨 · Sprint **1단계** 작업) |
| **착수 승인** | **GO** — §7 최종 판정 |

Sprint 04는 **계획 단계를 종료**하고 **실행 대기**로 전환한다. 미완료 항목은 **착수 blocking이 아닌** 실행·후속 과제로 분류한다.

---

## 1. 준비 완료 항목

기존 문서·도구에서 **이미 충족**된 항목.

### 1.1 Sprint 정의·목표

| # | 항목 | 근거 | 상태 |
|---|------|------|:----:|
| R1 | Sprint 04 **목표** — externalId **14.9% → 50%** (+141) | [sprint-04-charter.md](../sprint-04-charter.md) §1 | ✅ |
| R2 | **범위** — E1 Steam · E2 TMDB poster cohort | Charter §2 · [externalid-economics-plan.md](externalid-economics-plan.md) §4.2 | ✅ |
| R3 | **제외** — titles.en · zh · 신규 provider · 구조 변경 | Charter §3 | ✅ |
| R4 | **성공·실패 조건** — G2 · 회귀 · Quality · 감사 | Charter §4–§5 | ✅ |
| R5 | **종료 평가** — Economics 실측 · automation · quality 이슈 | Charter §6 | ✅ |

### 1.2 Economics 검토

| # | 항목 | 근거 | 상태 |
|---|------|------|:----:|
| E1 | G2 50% **경로 존재** — E1 125 + E2 31 ≥ 141 | Economics Plan §4 · Executive Summary | ✅ |
| E2 | Sprint 02 baseline **18.8h** · poster-priority **4.7–12h** 가설 | Economics Plan §5 | ✅ |
| E3 | cohort **실행 순서** (E1 → E2 → E3) | Economics Plan §4.2 | ✅ |
| E4 | SW1 exactId·variant 축과 **직교** — 하한 100% 유지 전제 | Economics Plan §1.3 | ✅ |

### 1.3 Quality Risk 검토

| # | 항목 | 근거 | 상태 |
|---|------|------|:----:|
| Q1 | 오류 유형 **5종** 식별 | [externalid-quality-risk-review.md](../externalid-quality-risk-review.md) §1 | ✅ |
| Q2 | Gate **잡는/못 잡는** 항목 분리 | Quality Risk §2–§3 | ✅ |
| Q3 | **감사 규모** — TMDB 31 전수 · Steam 최소 15 / 권장 100% | Quality Risk §5 | ✅ |
| Q4 | Release **soft block** 정책 | Quality Risk §6.4 | ✅ |
| Q5 | Steam **최대 blind spot** 명시 | Quality Risk §1.1 · B1–B2 | ✅ |

### 1.4 Governance 준비

| # | 항목 | 근거 | 상태 |
|---|------|------|:----:|
| G1 | `coverage_quality.dart` · `quality_gate.dart` | [phase2-governance-review.md](../phase2-governance-review.md) §7.1 G1 | ✅ |
| G2 | `coverage_dashboard` **quality** 섹션 | Governance §7.1 G2 | ✅ |
| G3 | Release Block **RB1·RB2** (CLI) | Governance §3.1 · [quality-gate-mvp.md](../quality-gate-mvp.md) §5 | ✅ |
| G4 | enrich **E1–E3** 가드·fallback (Sprint 03) | Governance §7.1 G4 | ✅ |
| G5 | `quality_gate --strict` **현 registry PASS** | Governance §7.1 G5 · Charter P4 | ✅ |
| G6 | 회귀 baseline — SW1/URV/GAP **100%** | Governance §5 · Charter S2–S3 | ✅ |
| G7 | enrich 후 워크플로 — builder → dashboard → SW1/URV → gate | Governance §1.4 · §5 | ✅ |
| G8 | `poster_verification` (TMDB) | Governance §2.2 · Quality Risk G7 | ✅ |

### 1.5 Phase 2 선행 Sprint

| # | 항목 | 근거 | 상태 |
|---|------|------|:----:|
| P1 | Sprint 01~03 **완료** · titles.en **91.5%** | [phase2-mid-review.md](phase2-mid-review.md) · Charter P1 | ✅ |
| P2 | Late-Stage **Q2** = Sprint 04 핵심 | [phase2-late-stage-plan.md](phase2-late-stage-plan.md) P1 | ✅ |
| P3 | 구조 변경 **금지** 합의 | [phase2-charter.md](../phase2-charter.md) §3 · Charter P5 | ✅ |

---

## 2. 미완료 항목

기존 문서에 **명시된 미완료** — Sprint 04 **착수 전** 해결 필수 여부 포함.

| # | 항목 | 문서 근거 | 착수 blocking | 비고 |
|---|------|-----------|:-------------:|------|
| U1 | **`coverage_sprint_04_external_id.dart`** (가칭) **미구현** | Economics Plan §8.3 | **아니오** | Sprint **실행 1단계** — `--dry-run` / `--apply` |
| U2 | **CI `quality_gate --strict` workflow 연동** | Governance §7.1 **G6** ⏳ · quality-gate-mvp §3.4 | **아니오** | 로컬·dogfood **수동** 가능 |
| U3 | **externalId 전용 Release Block** (RB: poster fail · duplicate) | Quality Risk §6.2 | **아니오** | Sprint 04 **후속** · **soft block**으로 대체 |
| U4 | **Steam appId 자동 교차검증** | Quality Risk B1–B2 | **아니오** | **수동 감사**로 Sprint 04 통제 |
| U5 | **`externalid_audit_sample.json`** (가칭) | Quality Risk §5.3 | **아니오** | enrich **시** 생성 |
| U6 | **zh Economics (Q1)** | Late-Stage Plan Q1 · Charter **범위 외** | **아니오** | Sprint 04 **제외** (Charter §3) |
| U7 | **composite Economics (Q3)** | Late-Stage Plan Q3 | **아니오** | Sprint 04 **종료 후** 합산 |
| U8 | **G1 insert·stub 희석 (A2)** 실측 | Governance §6 #4 | **아니오** | Phase 2 **병행** 백로그 |
| U9 | **A5 (50k 운영)** | Governance §6 #7 | **아니오** | Phase 2 **blocking 아님** |

**요약:** 착수 **blocking** 미완료 **0건**. U1은 **첫 실행 작업**이지 계획 결함이 아님 (Economics Plan §8.3).

---

## 3. 남은 리스크

새 분석 없이 **기존 문서에 기록된** 리스크만 인벤토리.

| # | 리스크 | 출처 | Sprint 04 통제 |
|---|--------|------|----------------|
| L1 | **Steam appId 오류** — 자동 검증 없음 | Quality Risk §1.1 · B1–B2 | E1 **100% spot-check** (Charter §5.2 권장) |
| L2 | **TMDB id 의미 오류** — tv/movie · 동명이작 | Quality Risk §1.2 · B3 | E2 **31작 전수** · `isPosterVerified` |
| L3 | **franchise·remake 혼동** | Quality Risk §1.3–§1.4 · B5 | 감사 C2–C3 · URV duplicate |
| L4 | **Coverage↑ · 신뢰↓** — KPI만 PASS | Quality Risk B9 | 감사 **soft block** · override 불가 |
| L5 | **SW1/URV 미검출** — ID 오류 | Quality Risk G4 · B4 | 회귀 **필수** · 감사 **보완** |
| L6 | **TMDB/Steam source 변경** | Governance §6 #5 | externalId attach는 **fetch 최소** — legacy·poster 우선 |
| L7 | **Sprint 02 Economics 과대/과소** | Economics Plan §5 · Mid-Review | Sprint 04 **실측**으로 종료 |
| L8 | **의미적 enrich 오류** (titles.en valid · wrong) | Governance §6 #1 | externalId Sprint와 **직교** · `--strict` 유지 |

**잔여 리스크 수용 전제:** L1–L5는 **감사·회귀**로 완화 — 자동 제거 불가 (문서 합의).

---

## 4. GO / NO-GO 판정

### 4.1 판정 기준 (문서 합의)

| 결정 | 조건 (출처) |
|------|-------------|
| **GO** | Charter §7.1 **P1–P5** ✅ · Governance **G1–G5** ✅ · Economics·Quality Risk **완료** · §2 **blocking 미완료 0** |
| **NO-GO** | Charter §7.2 — P4 FAIL · Quality Risk·감사 **미합의** · Quality Gate 없이 대량 enrich |
| **DEFER** | Charter §7.2 — zh/composite **선행** (Late-Stage P1=externalId **권고**) |

### 4.2 항목별 판정

| 검사 | 결과 |
|------|:----:|
| 목표·범위·제외 **정의 완료** | ✅ |
| Economics **G2 경로** 문서화 | ✅ |
| Quality Risk **blind spot·감사** 문서화 | ✅ |
| Governance **P0 G1–G5** | ✅ |
| 현 registry `quality_gate --strict` | ✅ (Charter P4) |
| §2 **착수 blocking** 미완료 | **0건** |
| Steam 감사 **권장선 100%** | ✅ Charter §5.2 · §7.3 **합의 전제** |

### 4.3 NO-GO 해당 여부

| NO-GO 조건 | 해당 |
|------------|:----:|
| P4 FAIL | **아니오** |
| Quality Risk 미완 | **아니오** |
| 구조 변경으로 착수 시도 | **아니오** |
| Quality Gate 없이 대량 enrich 계획 | **아니오** |

**DEFER 해당 여부:** zh·composite 선행 — Charter·Late-Stage **P1=externalId** 우선 → **해당 없음**.

### 4.4 판정 문구

Sprint 04 **착수 승인** — 계획·Economics·Quality Risk·Governance **준비 완료**. 실행은 Charter §8 순서·§5 감사·회귀 게이트 **준수** 하에 진행.

**조건 (Charter §7.3):**

- E2 TMDB **31작 전수** 감사
- E1 Steam attach **100% spot-check** (권장선 채택)
- 배치마다 SW1 · URV · `quality_gate --strict`
- 감사 미완 시 **release 보류** (soft block)

---

## 5. 착수 체크리스트

Sprint 04 **Day 0** — enrich **전** 확인.

### 5.1 승인·전제 (완료 확인)

- [x] [sprint-04-charter.md](../sprint-04-charter.md) 검토·승인
- [x] [externalid-economics-plan.md](externalid-economics-plan.md) 검토 완료
- [x] [externalid-quality-risk-review.md](../externalid-quality-risk-review.md) 검토 완료
- [x] Governance P0 **G1–G5** ([phase2-governance-review.md](../phase2-governance-review.md) §7.1)
- [x] `quality_gate --strict` **PASS** (현 registry baseline)

### 5.2 실행 착수 (Day 1 — 문서 순서)

- [ ] `coverage_sprint_04_external_id.dart` (가칭) **`--dry-run`** — E1+E2 cohort 선정 ([Economics Plan §8.3](externalid-economics-plan.md))
- [ ] **E2 TMDB** — ≤31작 attach 계획 확정 · **전수 감사** 체크리스트 준비 (Quality Risk A1–A5)
- [ ] **E1 Steam** — +141까지 attach 계획 · **100% spot-check** 일정 (Charter §5.2)
- [ ] 배치 워크플로 확인 — builder → dashboard → SW1 → URV → `quality_gate --strict` (Governance §5)

### 5.3 배치마다 (enrich `--apply` 후)

- [ ] `registry_builder.dart`
- [ ] `coverage_dashboard.dart` — `kpis.external_id` · `quality`
- [ ] `sw1_a_validation.dart` — recall@10 **≥ 100%**
- [ ] `urv_a_validation.dart` — exactId **100%** · `duplicateExternalKeyPairs` **= 0**
- [ ] `quality_gate.dart --strict` — **PASS**
- [ ] TMDB: `isPosterVerified` (해당 작품)
- [ ] 감사 기록 — `externalid_audit_sample.json` (가칭)

### 5.4 Sprint 종료 (Charter §4·§6)

- [ ] **G2 50%** — ≥201/402
- [ ] SW1 · URV **회귀 없음**
- [ ] 감사 **완료** (S7)
- [ ] Economics 실측 vs **18.8h** 문서화
- [ ] automation % · quality 이슈 수 보고
- [ ] release: soft block clear 후 `quality_gate --release` (Governance §3.2)

### 5.5 착수하지 않을 것 (Charter §3)

- [ ] titles.en · zh enrich — **금지**
- [ ] IGDB · openlibrary **신규 provider** — **금지**
- [ ] Registry · Franchise · search_index **구조 변경** — **금지**

---

## 6. 문서 맵

| 문서 | Readiness 역할 |
|------|----------------|
| [sprint-04-readiness-review.md](sprint-04-readiness-review.md) | **본 문서** — 착수 승인 |
| [sprint-04-charter.md](../sprint-04-charter.md) | Sprint 정의·실행 순서 |
| [externalid-economics-plan.md](externalid-economics-plan.md) | cohort · 비용 |
| [externalid-quality-risk-review.md](../externalid-quality-risk-review.md) | 리스크 · 감사 |
| [phase2-governance-review.md](../phase2-governance-review.md) | P0 · 워크플로 |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 기존 Phase 2·Sprint 04 문서만 근거 |

---

## 최종 판정

**GO**
