# Phase 2 Mid-Review — Coverage Economics 검증

> **역할:** Phase 2 **중간 점검** — Sprint 01~03 실측만 근거로 판단을 정리한다.  
> **전제:** [Baseline v1](../baseline-v1.md) Validated through Phase 1 · [phase2-charter.md](../phase2-charter.md)  
> **기준일:** 2026-06-09 · Registry **402작**  
> **산출물:** Sprint 01~03 도구·리포트 (`tool/coverage_sprint_0*.dart` · `akasha-db/pipeline/artifacts/coverage_dashboard/`)

**선행:** [phase1-final-review.md](phase1-final-review.md) · [assumption-register.md](../assumption-register.md) §10 · [canonical-identity-coverage-dashboard.md](../canonical-identity-coverage-dashboard.md)

---

## Executive Summary

Sprint 01~03은 **Coverage 품질 실험이 아니라 Coverage Economics 가설 검증**으로 해석하는 것이 적절하다.

| 축 | Sprint 01 이후 | Sprint 03 이후 | 회귀 |
|----|:--------------:|:--------------:|:----:|
| **titles.en** | 24.9% (100/402) | **91.5%** (368/402) | — |
| **GAP panel** | 100% | **100%** | 유지 |
| **SW1 recall@10** | 100% | **100%** | 유지 |
| **URV convergence** | 100% | **100%** | 유지 |

**핵심 시사:** Phase 2의 성공 여부는 「Coverage가 가능한가」보다 **「Coverage 비용 예측이 맞는가」** 에 더 가깝다. Sprint 03은 **가능성**과 **비용 하한**을 동시에 시사한다 — 다만 **품질·비-en 축** 리스크는 남아 있다.

---

## 1. Sprint 01~03 결과 요약

### 1.1 Sprint 01 — GAP Panel minimal enrich

| 항목 | 값 |
|------|-----|
| **목적** | GAP panel 16건 · SW1 GAP recall **0%** 해소 — 구조 변경 없이 최소 enrich로 A3 가설 검증 |
| **도구** | `tool/coverage_sprint_01_gap_enrich.dart --apply` |
| **대상** | **17 Work** (`titles` · `aliases` 패치) |
| **Before → After** | SW1 **81.6%→100%** · URV **81.6%→100%** · GAP panel **0%→100%** |
| **구조 변경** | **없음** (ADR · 스키마 · dedupe 무변경) |

→ Phase 1에서 남은 Identity 실패의 직접 원인이 **MISSING_TOKEN / MISSING_LOCALE** 임을 **실측 확인**.

### 1.2 Sprint 02 — Coverage Economics (추정)

| 항목 | 값 |
|------|-----|
| **목적** | Registry-wide Coverage **90% 유지 비용** 추정 — 구조 검증 아님 |
| **도구** | `tool/coverage_sprint_02_economics.dart` |
| **기준선** | Sprint 01 이후 · titles.en **24.9%** (100/402) |
| **GAP panel** | **0/16 remaining** ✅ |
| **titles.en → 90%** | **+262 Work** · 추정 **~60.1h** (~15 maintainer-days @4h/일) |
| **50% 마일스톤 (+101작)** | 추정 **22.9h** (1,372분) · **~13.6분/작** (missing 가중 평균) |
| **자동화율 (titles.en missing)** | **~11%** auto_high (tmdb/steam/igdb) · **~89% 수동** 가정 |

→ Phase 2 **다음 질문**을 「구조」에서 **「감당 가능한 운영 비용인가」** 로 고정.

### 1.3 Sprint 03 — titles.en 50% 마일스톤 + Economics 실측

| 항목 | 값 |
|------|-----|
| **목적** | Sprint 02 추정(**22.9h / +101작**) vs **실측** — Coverage Economics 정확도 검증 |
| **도구** | `tool/coverage_sprint_03_titles_en.dart` (`--apply` · `--remediate`) |
| **Run 1 (`--apply`)** | cohort **101작** · 성공 **99/101** · titles.en **199/402 (49.5%)** · wall **~0.85분** (전체 파이프라인) |
| **Run 2 (`--remediate`)** | TMDB 파싱 오류 **31건** + 실패 **2건** 보정 · **101/101** 성공 · wall enrich **~1.07분** |
| **최종 titles.en** | **368/402 (91.5%)** — 50% 목표(+101) **초과 달성**¹ |
| **회귀** | SW1 **100%** · URV **100%** · GAP **100%** 유지 |
| **자동화** | 성공작 기준 **auto+semi 100%** (auto 102 · semi 98 · manual 0 — Run 1+2 합산) |
| **부수 KPI** | `romanized_alias` **~91% PASS** · `franchise_spinoff_en` **100% PASS** (Sprint 03 회귀 측정 시점) |

¹ Run 2 remediate가 invalid `titles.en`·잔여 missing cohort를 추가 처리하여 **50% 마일스톤 범위를 넘어** 91.5%까지 상승. Sprint 03의 **의도된 측정 단위**는 +101작·50%이나, **운영 도구 1회 실행의 실제 파급**은 더 큼 — §7에서 Sprint 04 판단에 반영.

**주요 enrich method (실측):** `steam_fetch` (game) · `legacy_slug` (manga/animation) · `tmdb_fetch` (externalId 보유) · `latin_title` (ASCII 제목)

---

## 2. 무엇이 확인되었는가

| # | 확인된 사항 | 근거 |
|---|-------------|------|
| **1** | **A3 핵심 리스크는 Coverage이지 구조가 아님** | Sprint 01: 17 Work enrich만으로 SW1/URV/GAP **100%** · 구조 무변경 |
| **2** | **대량 titles.en enrich가 SW1/URV를 붕괴시키지 않음** | Sprint 03: +268작 수준 enrich 후에도 recall·convergence **100%** |
| **3** | **Coverage Economics가 Phase 2의 실질 게이트** | Sprint 02 추정 vs Sprint 03 실측 괴리 — §4 |
| **4** | **자동화 파이프라인이 titles.en 축에서 실용 가능** | TMDB/Steam fetch + legacy slug/latin 휴리스틱으로 **수동 0건** 처리 (Sprint 03 성공작) |
| **5** | **Panel KPI는 Sprint 01 이후 안정** | GAP · alias · subtitle panel **100%** 유지 — 운영 게이트(§4.1) 충족 |
| **6** | **A3 = Supported (Operational Dependency) 전제가 유지됨** | KPI·회귀 게이트 동시 충족 — [phase2-charter](../phase2-charter.md) §4.3 |

---

## 3. 무엇이 반박되었는가

### 3.1 Sprint 02·Phase 1 프레이밍에 대한 반박

| 기존 판단 | 반박 증거 | 갱신 |
|-----------|-----------|------|
| **titles.en missing의 ~89%는 수동 조사 필수** | Sprint 03: auto+semi **100%** (도구 체인 기준) | **조건부 기각** — **도구·fallback 전제**에서 수동 비율은 대폭 과대 추정 가능 |
| **+101작 ≈ 22.9h maintainer labor (50% 마일스톤)** | Wall clock **~1분대** · human-equivalent **~11.6h** (§4) | **부분 반박** — **실행 시간**은 추정 대비 극단적 하향 · **검수 포함 인력 모델**은 여전히 유의미 |
| **Coverage 개선 = 구조 변경 필요** | Sprint 01~03 전 구간 구조 무변경 | **기각** (Phase 1 결론 재확인) |
| **titles.en ramp가 SW1 품질을 희생한다** | 24.9%→91.5% enrich 후 SW1 **100%** | **기각** (402·현 쿼리 세트 범위) |

### 3.2 Sprint 03에서 드러난 **부분 반박** (낙관 금지)

| 항목 | 증거 | 의미 |
|------|------|------|
| **auto_high = 무조건 안전** | Run 1 TMDB HTML에서 **31건** invalid `titles.en` (`#= data.dataItem.date #`) | **tmdb_fetch 단독 신뢰 불가** — `_isValidEnTitle` · legacy_slug fallback **필수** |
| **Sprint 03 = titles.en 품질 검증 완료** | enrich 성공 ≠ lingustic QA · heuristic·slug 기반 다수 | **수량 KPI 달성 ≠ 운영 품질 종료** |
| **60.1h / 90% composite는 titles.en만의 문제** | Sprint 03은 **titles.en 축에 편중** · zh·externalId·season 등은 미착수 | **축별 Economics는 미검증** |

### 3.3 반박되지 **않은** 것

- **A5** (50k without Contribution) · **A6** (음악/SW2) — Sprint 범위 밖  
- **G1 실측 insert rate** — Coverage Sprint와 별도  
- **5k에서 동일 자동화율 유지** — 402 실측만 존재  

---

## 4. Coverage Economics — 추정 vs 실측

### 4.1 비교표 (Sprint 02 추정 · Sprint 03 실측)

| 측정 | Sprint 02 추정 (50% · +101작) | Sprint 03 실측 | 비고 |
|------|------------------------------|----------------|------|
| **Wall clock (enrich)** | — (미측정) | **~1분** (Run 1+2 합산 enrich 구간) | 스크립트·네트워크 I/O |
| **Wall clock (전체 파이프라인)** | — | **~1.3분** (enrich + registry_builder + dashboard + SW1 + URV) | Run 2 기준 |
| **Human-equivalent**¹ | **1,372분 (22.9h)** | **~694분 (11.6h)** | Sprint 02 tier 단가 적용² |
| **Δ vs 추정 (human-eq)** | — | **약 −50%** | §4.2 해석 |
| **자동화율 가정** | **11%** auto · **89%** manual | **100%** auto+semi (성공작) | cohort·도구 의존 |

¹ Human-equivalent: Sprint 02 보정 단가 — auto **2분** · semi **5분** · manual **15분** / Work ([`coverage_sprint_03_titles_en.dart`](../../tool/coverage_sprint_03_titles_en.dart) · Sprint 02 calibration).  
² Sprint 03 cohort가 **+101작을 넘어** 잔여 missing까지 처리했으므로, human-equivalent **11.6h**는 「50% 마일스톤 단독」보다 **넓은 작업 집합**에 가깝다. **보수적 비교** 시 +101작 분만 환산하면 human-eq는 더 낮을 수 있다.

### 4.2 해석 (Phase 2 Mid 판단)

| 관점 | 결론 |
|------|------|
| **실행 가능성** | Coverage **가능** — 구조 변경 없이 titles.en **91.5%** · 회귀 **100%** |
| **비용 하한** | 도구화 시 wall clock은 Sprint 02 manual 모델의 **~0.1%대** — **배치 자동화 전제** |
| **비용 상한 (운영 현실)** | human-equivalent **~11.6h**는 22.9h 추정의 **약 절반** — **검수·spot-check·실패 재처리**를 반영한 인력 모델은 여전히 필요 |
| **예측 정확도** | Sprint 02 **22.9h**는 「전수 manual」**상한**에 가깝다. Phase 2 Economics 게이트는 **「도구 자동화율 × 검수 SLA」** 로 재정의해야 함 |
| **90% composite (60.1h)** | titles.en 축은 Sprint 03으로 **사실상 초과 달성** — 잔여 비용은 **zh · externalId · romanized · season** 축에 집중 |

**한 줄:** Coverage 비용은 예상보다 **낮을 수 있음**이 시사되나, 그 조건은 **(a) 자동화 도구 체인 (b) TMDB 품질 가드 (c) 축별 분리 Economics** 이다.

### 4.3 유형별 작업 시간 (Sprint 03 Run 2 · remediate)

| Category | 처리 건수 | 평균 ms/작 | 시사 |
|----------|:---------:|:----------:|------|
| **game** | 45 | **~350ms** | Steam fetch — **유일한 지속 네트워크 비용** |
| **manga** | 33 | ~0ms | legacy_slug 즉시 |
| **animation** | 21 | ~0ms | legacy_slug 즉시 |
| **book** | 1 | ~0ms | latin_title (`1984`) |
| **drama** | 12 | ~0ms | heuristic |
| **webtoon** | 1 | ~0ms | — |

---

## 5. A3 최종 상태 제안

| 항목 | 제안 |
|------|------|
| **등급** | **Supported (Operational Dependency)** — **유지** |
| **근거** | Sprint 01~03: 구조 변경 없이 Identity **회귀 100%** · GAP panel **100%** · titles.en **대폭 개선** |
| **전제 강화** | ① [Coverage Dashboard](../canonical-identity-coverage-dashboard.md) panel·회귀 게이트 ② **Coverage Economics 모니터링** (wall vs human-eq) ③ **auto enrich 품질 가드** (`_isValidEnTitle` · fallback) |
| **승격/강등** | **Contested로 강등 근거 없음** · **Fully Supported로 승격 근거 부족** — Coverage **운영·비용** 의존은 여전 |
| **실패 정의** | 구조 붕괴가 아닌 **운영 실패** (KPI 미달 · Economics 예산 초과 · 자동화 품질 사고) |

**assumption-register §10 갱신 제안:** Sprint 03 Economics 실측 링크 추가 · 「Phase 2 Mid-Review」를 A3 운영 증거로 등재.

---

## 6. 남은 리스크 Top 5

> Sprint 01~03 **이후** 기준. 구조 붕괴 리스크는 제외.

| # | 리스크 | 근거 | 성격 |
|---|--------|------|------|
| **1** | **자동 enrich 품질·검수 공백** | TMDB 파싱 **31건** 오염 — remediate 전 | **프로세스·QA** |
| **2** | **비-en 축 Coverage 격차** | zh **~1%** · externalId **~15%** · Sprint 03은 titles.en 편중 | **운영·백로그** |
| **3** | **Economics 축별 미검증** | 60.1h composite는 multi-axis · titles.en만 실측 | **예측 리스크** |
| **4** | **G1 stub 유입 시 Coverage 희석 (A2)** | 대량 insert 시 panel·titles.en 비율 하락 가능 | **성장 × 운영** |
| **5** | **외부 소스 의존 (TMDB/Steam)** | HTML·API 변경 시 auto_high tier **일괄 실패** | **공급·도구** |

**Phase 1 Top 1** (Coverage 부족)은 Sprint 03으로 **titles.en 축에서 대폭 완화**되었으나, **전체 Identity Coverage** 관점에서는 **zh · externalId · alias field** 등이 여전히 FAIL — **「부분 해소」** 로 기록한다.

---

## 7. Sprint 04가 실제로 필요한가?

### 7.1 원래 Sprint 04 가정 (Sprint 02 맥락)

- **목표:** Registry-wide **90% composite** Economics 검증  
- **추정:** titles.en 90% binding **~60.1h**  
- **질문:** 「Coverage 90% 유지 비용이 감당 가능한가?」

### 7.2 Sprint 03 이후 재평가

| 판단 축 | 결론 |
|---------|------|
| **titles.en 90%** | Sprint 03 후 **91.5%** — **별도 Sprint 04 불필요** (유지·회귀만) |
| **90% composite** | **아직 필요** — zh · externalId · romanized · season · alias field 등 **FAIL 지속** |
| **Economics 검증** | Sprint 03이 **titles.en 축** 실측 완료 — Sprint 04는 **「composite 잔여 축」** Economics로 **재정의**하는 것이 타당 |
| **품질 hardening** | TMDB 가드·CI 게이트는 Sprint 04 **이전 또는 병행** 권장 — insert 확대(G1) 전제 |

### 7.3 권고

| 옵션 | 내용 | 권고 |
|------|------|:----:|
| **A. Sprint 04 전면 진행** | 90% composite 전 축 enrich + Economics 실측 | △ — 범위 과대 · titles.en 중복 |
| **B. Sprint 04 재정의 (권고)** | **「Economics Sprint 04 — 잔여 축」**: zh + externalId (+ romanized) · Sprint 02 tier 모델 vs 실측 · panel 회귀 유지 | ✅ |
| **C. Sprint 04 보류** | G1 insert 실측·Coverage CI 우선 | ○ — Economics 미완료 |

**결론:** Sprint 04를 **「titles.en 90%」** 로 진행할 필요는 **없다**. 다만 Phase 2 Charter §5·§6 **종료 조건** (externalId G2 **50%** · multi-axis enrich) 관점에서 **재정의된 Economics Sprint 04** 는 **여전히 가치 있음** — 다만 목적은 **품질 마일스톤**이 아니라 **잔여 축 비용 예측 검증**이어야 한다.

---

## 8. Phase 2 Mid 이후 권장 순서

| 순위 | 작업 | 근거 |
|:----:|------|------|
| **1** | ~~**assumption-register §10** · **phase2-charter** 링크~~ ✅ 반영됨 | A3 증거 갱신 |
| **2** | **auto enrich 품질 가드 CI화** | TMDB 31건 사고 재발 방지 |
| **3** | **Economics Sprint 04 (재정의)** | zh · externalId 축 — Sprint 02 60.1h composite 검증 |
| **4** | **G1 insert 실측** | A1 burden · A2 stub 희석 — Coverage와 **독립** 게이트 |
| **5** | **Coverage Dashboard 회귀 루틴 고정** | enrich 배치마다 SW1/URV/panel 스냅샷 |

**하지 않는 것:** 신규 ADR · Registry/Franchise 구조 변경 ([phase2-charter](../phase2-charter.md) §3).

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Sprint 01~03 실측 기반 Phase 2 Mid-Review |

**관련 커밋:** `feat(coverage): Sprint 03 titles.en enrich and economics validation`
