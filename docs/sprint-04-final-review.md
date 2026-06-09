# Sprint 04 Final Review — externalId G2 50%

> **⛔ Superseded (운영 SSOT 아님)** — 본 문서는 **Sprint 04-R1** (Registry **402작** 기준) **1차 실행** 결과를 기록한다.  
> **현재 운영 기준:** **Sprint 04-R2** — [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md) · [sprint-04-baseline-report.md](sprint-04-baseline-report.md) (@430).

> **목적:** Sprint 04 실행 결과를 정리하고 Phase 2 후속 GO/NO-GO를 판정한다.  
> **범위:** externalId G2 50% — [sprint-04-charter.md](sprint-04-charter.md) · [sprint-04-readiness-review.md](sprint-04-readiness-review.md) 기준.  
> **실행일:** 2026-06-09 · Registry **402작**

---

## Executive Summary

| 항목 | 결과 |
|------|------|
| **externalId Coverage** | **60/402 (14.9%) → 201/402 (50.0%)** |
| **G2 50%** | **달성** |
| **batch** | E2 TMDB **31작** · E1 Steam **110작** |
| **Automation** | **141/141 (100%)** auto attach |
| **Quality Gate** | **PASS** (`invalid_en_count=0`, `source_breakage_count=0`) |
| **SW1** | **1.0000 (87/87)** — 회귀 없음 |
| **URV** | **1.0000 (87/87)** — 회귀 없음 |
| **URV exactId** | **201/201 (100%)** |
| **비형제 duplicate external key** | **0** |
| **중단 조건** | 발생 없음 |

**판정:** Sprint 04는 목표한 externalId **G2 50% 검증을 성공적으로 완료**했다.

---

## 1. 실행 범위

### 1.1 Batch 구성

| Batch | Charter cohort | 적용 수 | 누적 externalId | 감사 결과 | Gate |
|------:|----------------|--------:|----------------:|-----------|------|
| 0 | dry-run | 0 | 60/402 | 후보 **156** (TMDB 31 · Steam 125), blocking **0** | 실행 전 |
| 1 | **E2 TMDB poster** | **31** | **91/402 (22.6%)** | blocking **0** | PASS |
| 2 | **E1 Steam** | **110** | **201/402 (50.0%)** | blocking **0** | PASS |

**비고:** E1 Steam 후보는 125작이었으나, E2 31작 이후 G2까지 필요한 수는 **110작**이었다. 따라서 15작은 Sprint 04 범위에서 적용하지 않았다.

### 1.2 생성·갱신 산출물

| 산출물 | 역할 |
|--------|------|
| `tool/coverage_sprint_04_external_id.dart` | Sprint 04 dry-run / apply runner |
| `akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_externalid_report.json` | 마지막 batch 실행 보고 |
| `akasha-db/pipeline/artifacts/coverage_dashboard/externalid_audit_sample.json` | 마지막 batch 감사 기록 |
| `akasha-db/pipeline/artifacts/coverage_dashboard/coverage_snapshot.json` | 최종 Coverage / Quality snapshot |
| `akasha-db/pipeline/artifacts/global_search_validation/sw1_a_report.json` | 최종 SW1 |
| `akasha-db/pipeline/artifacts/universal_registry_validation/urv_a_report.json` | 최종 URV |

---

## 2. externalId Coverage 변화

| 지표 | Sprint 03 baseline | Sprint 04 final | 변화 |
|------|-------------------:|----------------:|-----:|
| externalId 보유 | **60/402** | **201/402** | **+141** |
| externalId rate | **14.9%** | **50.0%** | **+35.1pp** |
| G2 phase target | 50.0% | **50.0%** | **달성** |
| dashboard status | FAIL | **PARTIAL** | phaseTarget 달성 |

`coverage_dashboard` 최종 값:

| KPI | 값 |
|-----|----|
| `kpis.external_id.numerator` | **201** |
| `kpis.external_id.denominator` | **402** |
| `kpis.external_id.rate` | **0.5** |
| `kpis.external_id.phaseTarget` | **0.5** |

---

## 3. Economics 실측

### 3.1 Sprint 02 추정 대비

| 항목 | Sprint 02 baseline | Sprint 04 actual |
|------|-------------------:|-----------------:|
| target additional works | **+141** | **+141** |
| method model | missing tier **100% manual** | poster-priority **100% auto** |
| human-equivalent | **18.8h** | **~4.7h model-equivalent** |
| delta | — | **약 -14.1h** |

**해석:** Sprint 02 externalId 모델은 Sprint 04 G2 cohort에 대해 **보수적 과대추정**이었다. titles.en Sprint 03과 동일하게, 기존 신호(poster/legacy)가 있는 cohort에서는 자동화 효과가 크다.

### 3.2 Wall clock

| 단계 | 관측 |
|------|------|
| dry-run | 약 **5.6초** |
| E2 apply + builder + gates | 약 **11.5초** |
| E1 apply + builder + gates | 약 **11.5초** |
| final release quality gate | 약 **4.5초** |

**주의:** 위 wall clock은 runner·gate 명령 실행 시간이다. 도구 작성·검토 시간은 제외한다.

---

## 4. Automation %

| cohort | 적용 수 | method | automation |
|--------|--------:|--------|-----------:|
| **E2 TMDB poster** | **31** | poster cache resolve | **100%** |
| **E1 Steam** | **110** | poster / legacy appId deterministic attach | **100%** |
| **합계** | **141** | E1+E2 | **100%** |

| 구분 | 수 | 비율 |
|------|---:|-----:|
| auto | **141** | **100%** |
| semi | 0 | 0% |
| manual | 0 | 0% |

**비고:** `externalid-economics-plan.md`의 E1+E2가 G2 +141을 충족한다는 가설은 실행으로 확인됐다.

---

## 5. Quality 이슈

### 5.1 Quality Gate

| 항목 | 결과 |
|------|-----:|
| `titles_en_populated` | 368 |
| `invalid_en_count` | **0** |
| `invalid_en_rate` | **0.0000** |
| `source_breakage_count` | **0** |
| `release_block` | **false** |
| `quality_gate --strict` | **PASS** |
| `quality_gate --release` | **PASS** |

### 5.2 Audit

| Audit | 대상 | 결과 |
|-------|-----:|------|
| dry-run 후보 감사 | 156 | blocking **0** |
| E2 TMDB | 31 | blocking **0** |
| E1 Steam 적용분 | 110 | blocking **0** |

감사 기준:

- TMDB: poster cache 기반 `isPosterVerified` 정합
- Steam: poster / legacy `appid` 추출 가능, poster-legacy mismatch 없음, category game 확인
- 공통: title 존재, provider id non-empty

### 5.3 URV externalId 품질 신호

| 항목 | 결과 |
|------|-----:|
| worksWithExternalId | **201** |
| externalIdCoverageRate | **0.5** |
| exactIdIngressHits | **201/201** |
| exactIdIngressRate | **1.0** |
| variantWithoutIdRate | **1.0** |
| duplicateExternalKeyPairs | **0** |
| external_id verdict | **PASS** |

**중대한 externalId 오류:** 발견 없음.

---

## 6. Regression

### 6.1 SW1

| 항목 | 결과 |
|------|-----:|
| overall recall@10 | **1.0000** |
| hits | **87/87** |
| GAP diagnostic | **15/15** |

Bucket별 결과:

| bucket | 결과 |
|--------|------|
| original | 6/6 |
| english | 9/9 |
| translation | 47/47 |
| series/subtitle | 14/14 |
| alias | 11/11 |

### 6.2 URV

| 항목 | 결과 |
|------|-----:|
| overall convergence | **1.0000** |
| queryConverged | **87/87** |
| alias | PASS |
| translation | PASS |
| romaji | PASS |
| series_subtitle | PASS |
| external_id | PASS |

**회귀:** 없음.

---

## 7. 중단 조건 평가

| 중단 조건 | 발생 여부 | 근거 |
|-----------|:--------:|------|
| SW1 회귀 | **아니오** | 87/87 · 1.0000 |
| URV 회귀 | **아니오** | 87/87 · 1.0000 |
| Quality Gate 실패 | **아니오** | strict/release PASS |
| 감사 중대 externalId 오류 | **아니오** | audit blocking 0 |

---

## 8. 후속 GO / NO-GO 권고

### 8.1 G2 externalId 목표

| 질문 | 권고 |
|------|------|
| Sprint 04 externalId G2를 Phase 2 충족으로 인정할 것인가? | **GO** |
| G2 달성분을 유지할 것인가? | **GO** |
| Sprint 04를 종료할 것인가? | **GO** |

### 8.2 추가 externalId 확대

| 질문 | 권고 |
|------|------|
| 같은 Sprint에서 50% 초과 확대를 계속할 것인가? | **NO-GO** |
| externalId 90%를 바로 진행할 것인가? | **NO-GO** |
| 남은 Steam 15작을 즉시 적용할 것인가? | **NO-GO** — 별도 후속 batch/charter에서 결정 |

**이유:** Sprint 04의 목적은 **G2 50% 검증**이며 이미 달성했다. 50% 초과 확대는 Quality Risk Review의 manual/remaining cohort 논의와 별도로 다뤄야 한다.

### 8.3 Phase 2 후속

| 항목 | 권고 |
|------|------|
| Sprint 04 결과를 `phase2-mid/final` 계열 문서에 반영 | **GO** |
| externalId Quality Gate hard block 확장 | **GO (후속)** |
| zh Economics(Q1) 착수 | **GO (별 Sprint)** |
| composite Economics 재산정(Q3) | **GO (Sprint 04 결과 반영 후)** |

---

## 9. 결론

Sprint 04는 externalId G2 50%를 **구조 변경 없이** 달성했다.

- Coverage: **201/402 (50.0%)**
- Automation: **100%**
- Quality: **PASS**
- SW1/URV: **회귀 없음**
- 중대한 externalId 오류: **0**

**Sprint 04 종료 판정:** **GO**

**후속 권고:** G2 달성은 승인하고, 50% 초과 확대는 별도 Sprint로 분리한다.

