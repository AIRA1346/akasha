# A5 Scale Operational Decisions — SD1~SD3

> **목적:** Scale 단계 **운영 수치** 확정 — O3·O7·Gate 판정에 사용.  
> **전제:** [a5-scale-plan.md](a5-scale-plan.md) · Pilot **동결** · Scale baseline **410작** (2026-06-09)  
> **기준일:** 2026-06-09

**출처:** [a5-operational-decisions.md](a5-operational-decisions.md) D1~D3 Scale 이관.

---

## Executive Summary

| ID | 결정 영역 | 확정 |
|:--:|-----------|:----:|
| **SD1** | 관측 기간 · O3 윈도 | **예** |
| **SD2** | 배치 규모 | **예** |
| **SD3** | Pause 임계 (O7·Coverage) | **예** |

---

## SD1 — 관측 기간 · O3 insert rate

| # | 항목 | 값 |
|---|------|-----|
| SD1.1 | Scale **시작** (O3 clock) | **2026-06-09** (Scale 1) |
| SD1.2 | O3 **1차 checkpoint** | **2026-07-09** (30일) |
| SD1.3 | O3 **측정 대상** | Maintainer `a5_scale_supply_batch` net insert only |
| SD1.4 | O3 **제외** | Pilot 402→410 · Expansion batch5/6 (현재 ADD 0) |
| SD1.5 | Rate **공식** | `net_insert / elapsed_days × 30` (월 환산) |

### O3 스냅샷 (2026-06-09, day 0)

| 필드 | 값 |
|------|-----|
| Baseline | **410** works |
| Scale net insert | **+6** → **416** |
| elapsed_days | **0** (단일 세션) |
| 월 환산 rate | **미산출** — checkpoint **2026-07-09**에 확정 |
| 문서 가설 (G2) | ~3k–5k/월 — **비교는 checkpoint 이후** |

---

## SD2 — 배치 규모

| # | 항목 | 값 |
|---|------|-----|
| SD2.1 | Supply 배치 상한 | **2 works** / batch |
| SD2.2 | Enrich 배치 상한 | **4 works** / batch (insert-free 허용) |
| SD2.3 | Insert-free enrich | **허용** — O7 backlog 소진용 (batch 4) |
| SD2.4 | 배치 후 검증 | `preflight_check` **필수** |
| SD2.5 | Expansion apply | `--max-add 2` 기본 · gate **선행** |
| SD2.6 | 1차 checkpoint 전 누적 supply 상한 | **20 works** (410→430 가이드) |

---

## SD3 — Pause 임계

| # | 항목 | 임계 | Gate |
|---|------|------|------|
| SD3.1 | titles_en | **< 0.90** (dashboard) | H3 **Pause** |
| SD3.2 | dedupe 신규 fuzzyTitle | **> 0** after insert | H2 **Pause** |
| SD3.3 | quality_gate strict | **FAIL** | H4 **Pause** |
| SD3.4 | SW1 recall@10 | **< 1.0** (87쿼리) | H3 **Pause** |
| SD3.5 | O7 — maintainer stub ja backlog | **≥ 4** AND **2연속** insert-only 세션 | H3 **Pause** · enrich **우선** |
| SD3.6 | H1 Stop | 공급 경로 붕괴 · G2 **기각** | H1 **Stop** |

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | SD1~SD3 초안 확정 — O3 checkpoint 30일 |
