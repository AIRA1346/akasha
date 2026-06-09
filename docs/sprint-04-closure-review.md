# Sprint 04 Closure Review

> **목적:** Sprint 04 **최종 결과** 기록 — 회고 전용  
> **기준일:** 2026-06-09 · Registry **430 works** · externalId **201 (46.74%)**  
> **SSOT:** [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md)

**금지 준수:** 신규 설계 · 신규 정책 · ADR · 구현 **없음** — **기존 산출물 정리만**

---

## Executive Summary

| 항목 | 결과 |
|------|------|
| **최종 판정** | **PARTIAL SUCCESS** |
| **04-R1** (@402) | G2 **50% 달성** · +141 auto attach · 회귀 **PASS** |
| **04-R2** (@430) | G2 **미달** (46.74% · **-14**) · 잔여 E1 **15건** · 품질 감사 **완료** · apply **보류** |
| **핵심 교훈** | **수량 KPI**와 **운영 SSOT** 분리 · **identity 품질**이 무인 attach보다 **병목** |

---

## 1. 목표

### 1.1 원래 Sprint 04 목표

[sprint-04-charter.md](sprint-04-charter.md) · [externalid-economics-plan.md](externalid-economics-plan.md) 기준.

| # | 목표 |
|---|------|
| G2-1 | externalId coverage **14.9% → 50%** (Charter: **60/402 → 201/402**) |
| G2-2 | **E1** Steam · **E2** TMDB poster cohort로 **+141** attach |
| G2-3 | Economics·Quality **동시 검증** — 자동화 실효 · 회귀·감사 |
| 범위 외 | titles.en · zh · 신규 provider · 구조 변경 |

### 1.2 실제 달성 수준

| 레이어 | 시점 | Registry | externalId | G2 50% | 비고 |
|--------|------|:--------:|:----------:|:------:|------|
| **04-R1** | 1차 실행 | **402** | **201 (50.0%)** | **달성** | [sprint-04-final-review.md](sprint-04-final-review.md) *(archive)* |
| **04-R2** | 종료 시점 | **430** | **201 (46.74%)** | **미달 (-14)** | Scale **+28** · id count **유지** |

| 목표 축 | 달성 |
|---------|------|
| **Economics (poster-priority)** | **달성** — Sprint 02 대비 **~14h 절감** 추정 · 141건 **100% auto** (R1) |
| **G2 @현재 분모** | **미달** — 215/430 필요 · E2 TMDB 잔여 **0** · E1 잔여 **15** |
| **Quality (잔여 cohort)** | **측정·문서화 완료** — apply **미실행** |
| **회귀 (R1 apply 후)** | **달성** — SW1·URV **1.0** · invalid_en **0** |

**한 줄:** Charter의 **G2 Economics 검증**은 R1에서 **성공**했으나, Scale 이후 **R2 운영 기준**에서는 G2 **미달**이며, 잔여 15건은 **품질 게이트 통과 전 apply 보류** 상태로 Sprint를 **닫는다**.

---

## 2. 주요 발견

| # | 발견 | 근거 |
|---|------|------|
| 1 | **Coverage rate 하락의 주원인은 분모 증가** | externalId **201 유지** · Registry **402→430** → 50.0%→**46.74%** |
| 2 | **기계적 cohort 상한은 여전히 G2 초과** | E1 15건 적용 시 **216/430 (50.23%)** — [sprint-04-baseline-report.md](sprint-04-baseline-report.md) |
| 3 | **Runner syntactic audit ≠ semantic 안전** | dry-run **blocking 0** (R1) vs Phase B **HIGH 4** · [sprint-04-e1-audit.md](sprint-04-e1-audit.md) |
| 4 | **무인 attach보다 identity·integrity가 병목** | HIGH: duplicate·Site Error·교차 게임명 · MEDIUM: Steam 프로모 `titles.en` |
| 5 | **E2 TMDB poster 경로는 @430 소진** | baseline E2 후보 **0** — 잔여 G2는 **E1(Steam)만** |
| 6 | **문서 SSOT 이중화 비용** | R1 종료 GO vs R2 재감사 — [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md) |
| 7 | **Rule ID `E1`~`E5` 다의어** | cohort · enrich gate · attach gate **충돌** — [rule-id-collision-analysis.md](rule-id-collision-analysis.md) |

---

## 3. 실패한 가설

| 가설 | 실측 | 문서 |
|------|------|------|
| **E4 token overlap `< 0.15` → REVIEW** | cohort **15/15** 발화 · LOW 7건 **FALSE_REVIEW 100%** | [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) |
| **「audit blocking 0」= attach 안전** | semantic HIGH **4** · post-gate **BLOCK 8** | [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) |
| **G2 달성 = Sprint 04 완전 종료** (@402) | @430 **-14** · 15건 **미처리** | reconciliation |
| **(초안) overlap으로 ko/en 불일치 검출** | 한·영 로컬라이즈에서 overlap **구조적 0.0** | B-5 |
| **E4 단독으로 AUTO_APPROVE 경로 확보** | (구 E4 기준) AUTO **0/15** | B-4 |

*위 항목은 **폐기·수정 완료**(E4) 또는 **R1 시점 한정**으로 기록 — 신규 정책 **아님**.

---

## 4. 성공한 가설

| 가설 | 실측 | 문서 |
|------|------|------|
| **poster-priority Economics** | +141 **100% auto** · manual 대비 **대폭 단축** | [sprint-04-final-review.md](sprint-04-final-review.md) |
| **E1 Steam + E2 TMDB ≥ G2 gap** | 125+31 ≥ 141 **확인** (R1) | economics-plan · final-review |
| **E1 Site Error → BLOCK** | wk_270 **차단** | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) |
| **E2 Save prefix → BLOCK** | 프로모 `titles.en` **5건** (266+4 MEDIUM) | post-gate · rules |
| **E3/E5 duplicate attach → BLOCK** | 144·277 **차단** | disposition · rules |
| **Steam attach 위험 분석 (수동)** | LOW/MED/HIGH **15건 분류** | [sprint-04-e1-audit.md](sprint-04-e1-audit.md) |
| **HIGH disposition** | DUPLICATE·SOURCE·MATCHING **조치 코드** | [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md) |
| **R1 apply 후 회귀** | SW1·URV **100%** · duplicate key **0** | final-review |

---

## 5. 후속 작업 (Sprint 05 이전 backlog)

기존 [repository-ia-priority-review.md](repository-ia-priority-review.md) · Wave 1~2 **완료·진행** 반영.

### 5.1 완료 (Sprint 04 문서)

| 항목 | 산출 |
|------|------|
| Wave 1 SSOT | README 04-R1/R2 · superseded 배너 · charter 레이어 |
| Wave 2 E4 정합 | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) B-5 반영 |

### 5.2 미완 — Sprint 05 이전 권고

| 우선 | 항목 | 성격 |
|:----:|------|------|
| P1 | **EG namespace** (E1~E5 → EG1~EG5) | 문서·도구 · [rule-id-collision-analysis.md](rule-id-collision-analysis.md) |
| P1 | **SC cohort** 각주/정리 (선택 SC1~SC4) | charter · economics · sprint 도구 주석 |
| P1 | **잔여 15건 disposition 실행** | HIGH 4 **MANUAL/DO_NOT_APPLY** · LOW 7 **인적 REVIEW 후** partial apply **결정** |
| P2 | **Coverage Governance 통합** | attach gate ↔ governance §4 링크 · EN 각주 |
| P2 | **charter/economics @430 수치** | superseded 각주 또는 R2 부록 |
| — | **Gate 구현** (`post_gate` → runner) | Sprint 05+ 범위 — 본 Closure **범위 외** |

### 5.3 운영 수치 (종료 시점)

| 지표 | 값 |
|------|-----|
| externalId | **201/430 (46.74%)** |
| G2 gap | **+14** |
| E1 잔여 cohort | **15** |
| E2 잔여 | **0** |

---

## 6. 최종 판정

### **PARTIAL SUCCESS**

| 근거 축 | 판정 |
|---------|------|
| **Charter G2 Economics (R1)** | **SUCCESS** — 201/402 · automation · 회귀 |
| **Charter G2 @430 (R2)** | **NOT MET** — 46.74% · **-14** |
| **Quality 프로그램 (Phase B)** | **SUCCESS** — 감사·gate 시뮬·E4 실효성·rules 정합 |
| **잔여 apply** | **NOT DONE** — 15건 **의도적 보류** |
| **문서·SSOT** | **SUCCESS** — reconciliation · Wave 1~2 |

**FAIL이 아닌 이유:** R1에서 **주요 Sprint 목적**(poster-priority G2 경로·Economics 실측) **달성** · Phase B로 **품질 리스크 가시화** · 무인량산 attach **회피**.

**FULL SUCCESS가 아닌 이유:** 현재 Registry 기준 **G2 미달** · 잔여 cohort **미적용** · attach gate **미구현**.

### Sprint 04 상태 요약

```
04-R1  Economics + G2 @402     ████████████  COMPLETE (archive)
04-R2  Baseline + Phase B       ██████████░░  MEASURED · apply OPEN
04-Doc IA Wave 1–2              ████████████  COMPLETE
04-Impl gate in runner          ░░░░░░░░░░░░  NOT STARTED (backlog)
```

---

## 7. 읽기 순서 (종료 아카이브)

| 순서 | 문서 |
|:----:|------|
| 1 | [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md) |
| 2 | [sprint-04-baseline-report.md](sprint-04-baseline-report.md) |
| 3 | Phase B: e1-audit → disposition → post-gate → e4-effectiveness |
| 4 | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) |
| 5 | (archive) [sprint-04-final-review.md](sprint-04-final-review.md) |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 Closure Review — PARTIAL SUCCESS |
