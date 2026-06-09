# Phase 2 Summary — Coverage Improvement Program

> **목적:** Phase 2 전체를 **5분 안에** 이해할 수 있는 아카이브 요약.  
> **상태:** **PHASE 2 COMPLETE** (2026-06-09)  
> **상세 판정:** [phase2-final-review.md](archive/phase2-final-review.md)

**전제:** Phase 1에서 Registry·Franchise·검색 **구조**는 검증 완료. Phase 2는 **Coverage를 어떻게 채우고 유지할 것인가**를 검증했다. Registry **402작** · 구조 변경 없음.

---

## 1. 시작 시점의 질문

Phase 2가 답하려 한 것은 설계 문제가 아니라 **운영 문제**였다.

| 질문 | 의미 |
|------|------|
| Identity 실패의 원인이 **구조**인가, **표면형 부족**인가? | enrich로 해결 가능한지 |
| Coverage를 늘려도 **검색·Identity가 깨지지 않는가?** | SW1 · URV 회귀 |
| Coverage 비용은 **감당 가능한가?** | Economics (추정 vs 실측) |
| 품질 없이 수량만 올리면 **신뢰할 수 있는가?** | Quality Gate · 감사 |
| Charter G2(**externalId 50%**)를 **구조 변경 없이** 달성할 수 있는가? | Sprint 04 |

**Phase 2가 답하지 않은 것:** 50k 운영(A5) · zh 30% · externalId 90% · 음악/SW2 · Registry 구조 변경.

---

## 2. 무엇이 검증되었는가

| 영역 | 증명된 것 | 근거 (Sprint) |
|------|-----------|---------------|
| **Coverage Hypothesis** | 실패 원인은 표면형 미부착 · enrich로 회복 가능 | Sprint **01** |
| **구조 불필요** | ADR·스키마 변경 없이 panel·G2 달성 | Sprint **01~04** |
| **Coverage Economics** | titles.en ramp 비용은 추정보다 낮을 수 있음 (자동화 전제) | Sprint **02~03** |
| **externalId Economics** | G2 50%는 poster-priority cohort로 달성 가능 | Sprint **04** |
| **회귀 안정성** | 대량 enrich·externalId ramp 후에도 SW1/URV **100%** | Sprint **01~04** |
| **품질 통제** | syntactic `titles.en` 오염은 자동 게이트로 차단 가능 | Sprint **03** + Quality Gate MVP |
| **Governance** | Coverage KPI · Quality KPI · 회귀를 **분리 측정** 가능 | dashboard · `quality_gate` |

### Assumption (최종)

| ID | 판정 |
|----|------|
| A1 5k 공급 가능 | **Supported** |
| A2 Stub-first 품질 | **Supported** |
| A3 Canonical Identity Coverage | **Supported**¹ |
| A4 Franchise 지연 생성 | **Supported** |
| A5 50k without Contribution | **Deferred** |

¹ A3는 KPI·회귀·품질 게이트 **유지가 운영 전제** (Operational Dependency).

---

## 3. 최종 KPI

**기준일:** 2026-06-09 · `coverage_snapshot.json` · SW1/URV 리포트

### Charter (종료 기준)

| KPI | 결과 | 목표 |
|-----|------|------|
| GAP panel | **100%** (16/16) | ≥90% |
| alias panel | **100%** (11/11) | ≥90% |
| subtitle panel | **100%** (9/9) | ≥90% |
| externalId (G2) | **50.0%** (201/402) | ≥50% |
| SW1 recall@10 | **100%** (87/87) | ≥ baseline |
| URV convergence | **100%** (87/87) | ≥ baseline |

### 주요 Registry·Quality (부수)

| KPI | 결과 |
|-----|------|
| titles.en | **91.5%** (368/402) |
| romanized_alias | **91.2%** (342/375) |
| invalid_en_count | **0** |
| source_breakage_count | **0** |
| URV exactId | **201/201 (100%)** |
| duplicate external key (비형제) | **0** |

**Charter §5·§6:** 전부 충족 → [phase2-final-review.md](archive/phase2-final-review.md) **PHASE 2 COMPLETE**.

---

## 4. 남은 질문

Phase 2 **실패가 아님** — Charter 범위 밖 또는 후속 Open Question.

| 구분 | 항목 | 상태 |
|------|------|------|
| **범위 밖** | **A5** 50k-scale operations | **Deferred** — Phase 2 미검증 |
| **범위 밖** | A6 음악 · SW2 | 장기 과제 |
| **범위 밖** | zh 30% · externalId 90% · season/alias 백로그 | Charter §5 미포함 |
| **Open Question** | zh · composite Economics | 미실측 축 잔여 |
| **Open Question** | Semantic QA (의미적 enrich 오류) | syntactic gate만 구현 |
| **Open Question** | CI `quality_gate --strict` 자동 연동 | 로컬 PASS · workflow 없음 |

---

## 5. 핵심 교훈

1. **구조는 이미 충분했다.** Phase 2의 병목은 설계가 아니라 **Coverage 운영**이었다.
2. **표면형을 채우면 Identity가 회복된다.** 17 Work minimal enrich로 SW1/URV/GAP가 100%로 올라갔다 (Sprint 01).
3. **Coverage 수량과 품질은 분리해야 한다.** titles.en 91.5% 달성과 TMDB 31건 오염이 동시에 발생했다 (Sprint 03).
4. **Economics 추정은 manual 상한에 가깝다.** poster·legacy 신호가 있는 cohort에서는 자동화 이득이 크다 (Sprint 03·04).
5. **회귀 게이트는 필수 운영 비용이다.** enrich마다 SW1 · URV · Quality Gate를 돌려야 A3가 유지된다.
6. **externalId는 늘릴 수 있고, 신뢰는 감사에 달려 있다.** G2 50% 달성 시 audit blocking 0 · duplicate 0 — Steam 등은 hard gate 없이 soft block으로 통제했다 (Sprint 04).

---

## 문서 맵

| 문서 | 용도 |
|------|------|
| [phase2-summary.md](phase2-summary.md) | **본 문서** — 외부인용 요약 |
| [phase2-final-review.md](archive/phase2-final-review.md) | 종료 판정서 |
| [phase2-charter.md](phase2-charter.md) | Phase 2 목표·성공 조건 |
| [phase2-mid-review.md](archive/phase2-mid-review.md) | Sprint 01~03 |
| [sprint-04-final-review.md](archive/sprint-04-final-review.md) | Sprint 04 |

**판정:** **PHASE 2 COMPLETE**
