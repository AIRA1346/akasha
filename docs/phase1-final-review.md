# Phase 1 Final Review — Baseline v1 검증 종료

> **역할:** [Baseline v1](baseline-v1.md) 검증 단계(Phase 1) **종료 보고서**.  
> **기준일:** 2026-06-09 · Registry **402작**  
> **다음 단계:** 구조 설계·신규 ADR가 아니라 **Coverage Improvement Program** (운영·enrich).

**검증 산출물**

| 실험 | 도구·문서 | 산출물 |
|------|-----------|--------|
| SIM-A/B/C/D | `tool/scale_5k_sim.dart` | `akasha-db/pipeline/artifacts/scale_5k_sim/` |
| SW1-A | `tool/sw1_a_validation.dart` | `global_search_validation/sw1_a_report.json` |
| URV-A | `tool/urv_a_validation.dart` | `universal_registry_validation/urv_a_report.json` |
| Coverage KPI | `tool/coverage_dashboard.dart` | `coverage_dashboard/coverage_snapshot.json` |

**근거 문서:** [assumption-register.md](assumption-register.md) · [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md)

---

## Executive Summary

Phase 1의 핵심 결론은 다음과 같다.

**AKASHA의 주요 리스크는 더 이상 Registry 구조가 아니다.**

검증 결과, Work/Franchise Dual-layer · `wk_` 불변 ID · 해시 샤딩 · shadow_write dedupe · exactId 병합 · Franchise 지연 생성은 **402 및 5k 합성 조건에서 설계 의도대로 동작**한다.

**현재 최대 과제는 Canonical Identity Coverage** — Registry가 **사람들이 실제로 쓰는 이름(표면형)** 을 얼마나 알고 있는가의 문제이다. 이는 "작품을 저장하는 문제"가 아니라 **메타 enrich·운영** 문제로 분류된다.

| 가정 | Phase 1 판정 |
|------|--------------|
| A1 (5k 공급) | **Supported** |
| A2 (Stub-first) | **Supported** |
| A3 (Canonical Identity) | **구조 Supported · Coverage 운영 과제** |
| A4 (Franchise) | **Supported** |
| A5 | **미검증** |
| A6 | **장기 과제** |

---

## 1. 무엇이 검증되었는가

### 1.1 Registry 구조·아키텍처

| 항목 | 증거 | 결과 |
|------|------|------|
| Dual-layer (Work + Franchise) | ADR-001 승인 · URV-A · SIM-D | IP 1카드·저장 원자 분리 **유지 가능** |
| `wk_` + 해시 샤드 v4 | 402 manifest · registry_builder | 402→5k 합성에서 shard·index 빌드 **무이상** |
| Dedupe 신호 (externalId · fuzzy title) | SIM-B B-2 outcome **100%** · URV exactId ingress **100%** | **title 보존 시** 수렴·탐지 **안정** |
| Franchise 지연 생성 | SIM-D **PASS** | 5k에서 후보·미커버 클러스터 **통제 가능** (지연 정책 전제) |
| Search index (402 규모) | SW1-A · SIM-C | latency·throughput 병목 **아님** — 5k = **공급·품질** 문제 |

### 1.2 공급·파이프라인 (A1)

| 지표 | 값 (SIM-A, seed=42) |
|------|---------------------|
| 배치 500건 net wouldCreate | 486 |
| 주 1회 배치 환산 net/월 | **~2,104** |
| G1 목표 net/월 | 300 |
| Contract 통과율 | 97.2% |

→ **처리량(throughput)은 G1 목표를 충족.** 공급 경로 자체는 실현 가능하다고 판단.

### 1.3 Stub-first (A2)

| 지표 | 값 |
|------|-----|
| SW1-A 402 recall@10 | **81.6%** (71/87) |
| SIM-C 5k gap vs 402 delta | **−1.1pp** (80.5% vs 81.6%) |
| 원제·영어 검색 (SW1) | **100%** |

→ **현 enrich 수준에서 stub-first 확장이 SW1을 즉시 붕괴시키지 않음.** 다만 표면형 변형 유입 시 하락은 별도 리스크(§2).

### 1.4 Canonical Identity — 구조 측면 (A3)

| 지표 | 값 (URV-A / SW1-A) |
|------|---------------------|
| 번역 제목 수렴 | **92.7%** PASS |
| exactId ingress | **100%** (60/60) |
| title 보존 dedupe (B-2) | outcome **100%** |
| 전체 identity 수렴 (URV query) | **81.6%** — SW1 recall과 **동일 건수** |

→ **동일 표면형이 이미 Registry에 있으면** 하나의 `wk_`로 수렴·검색 모두 성공. **모델·알고리즘은 틀리지 않았다.**

### 1.5 Franchise (A4)

| 지표 | 값 (SIM-D) |
|------|------------|
| 402 미커버 클러스터 | 3 (4 members) |
| 5k deferred 정책 시 미커버 | 63 clusters (운영 큐로 흡수 가능한 규모) |

→ ADR-006 F1(지연 생성·depth≤3) 전제에서 **5k 운영 비용 통제 가능.**

---

## 2. 무엇이 반박되었는가

### 2.1 가설·프레이밍 반박

| 기존 가설 | 반박 증거 | 갱신 |
|-----------|-----------|------|
| **5k 병목 = 성능/인프라** | search_index·shard 5k 합성 무이상 | **기각** — 5k = **공급·커버리지** |
| **A3 = dedupe 알고리즘 문제** | B-2 outcome 100% · exactId 100% | **기각** — 알고리즘은 표면형 보존 시 충분 |
| **사후 dedupe만으로 충분** | B-3 **25%** · B-4 **22%** · 사후 잔존 276/287 | **조건부 반박** — **표면형 변형** 시 사전·사후 **동시 실패** |
| **Registry 구조가 최대 리스크** | URV-A 구조 축 PASS · SIM-D PASS | **기각** — 구조는 Supported |
| **externalId 공백이 dedupe를 무너뜨림** | B-2 title 보존 100% (ID 0건 기여) | **부분 기각** — 공백 자체가 아니라 **공백 + 변형 결합**이 붕괴 원인 |

### 2.2 측정·운영 정의 반박

| 항목 | 증거 |
|------|------|
| SIM-B KPI recall 68.5% vs outcome 100% | KPI join이 `externalIds.sim`만 집계 — **탐지 실패가 아닌 측정 결함** (B-1 교정 후순위) |
| Maintainer burden (SIM-A) | 월 **~2,849분** 추정 vs 예산 1,200분 — **throughput만으로는 G1 불충분** 가능 (운영 모델 과제) |

### 2.3 Coverage 부족 (A3 운영 축) — Phase 1에서 확인된 실패

| KPI (402) | 현재 | SW1/URV 연계 |
|-----------|:----:|--------------|
| GAP panel | **0%** (0/16) | SW1 GAP recall **0%** (15건) |
| titles.en | **21.1%** | 로마자·공식 영문 미부착 |
| romanized | **22.7%** | URV 로마자 축 **0%** |
| externalId | **14.9%** | variant-only stub fuzzy **0%** |
| alias panel | 81.8% | Re:ゼロ · FMA 미부착 |
| subtitle panel | 66.7% | LOTR · Dandadan 미부착 |

→ 검색·수렴 실패의 직접 원인은 **MISSING_LOCALE / MISSING_TOKEN** (표면형 미부착). Rank 문제가 아님.

---

## 3. 무엇이 아직 미검증인가

| ID | 항목 | 이유 |
|----|------|------|
| **A5** | Contribution 없이 50k 도달 | 5k SIM 범위 밖 · Pipeline MVP 미실측 |
| **A6** | 곡=Work(B안) 장기 규모 | 402 음악 0건 · SW2(30M index) 미착수 |
| **ADR-002** | 음악 A/B **최종 확정** | B안 가중 잠정 · 5k 범위 밖 · **비긴급** |
| **G1-1 실측** | 월 ≥300 net **실제 insert** | SIM-A는 shadow dry-run · maintainer 실측 없음 |
| **Enrich SLA** | stub 유입 후 N일 내 panel KPI | 정책 수치만 존재 · CI 게이트 미구현 |
| **URV-B** | enrich before/after 회귀 | URV-A baseline만 완료 |
| **SW2** | 10M~30M search_index | A6·대규모 인프라 게이트 |
| **B-1** | SIM-B KPI join 교정 | 측정 정합 — 구조 검증과 무관 |

---

## 4. 현재 AKASHA의 최대 리스크 Top 5

실험 결과만 기반. (구조 리스크는 Top 5에서 제외됨.)

| # | 리스크 | 근거 | 성격 |
|---|--------|------|------|
| **1** | **Canonical Identity Coverage 부족** | GAP panel 0% · titles.en 21% · URV 로마자 0% | **운영·enrich** |
| **2** | **표면형 변형 stub 유입 시 identity 붕괴** | B-3 25% · B-4 22% · enrich 없는 합성 | **프로세스** |
| **3** | **externalId 밀도 14.9%** | variant-only fallback 없음 · B-3/B-4 | **메타 공급** |
| **4** | **Maintainer / enrich 운영 부담** | SIM-A burden fail · 402 `aliases[]` 0% | **운영** |
| **5** | **50k 공급 경로 미검증 (A5)** | Pipeline MVP·human queue 한도 미측정 | **중기 가정** |

**한 줄:** Top 1~4는 모두 **「사람들이 쓰는 이름을 Registry가 알고 있는가」** 와 연결된다.

---

## 5. 향후 3개월 우선순위

> Phase 2 = **Coverage Improvement Program** — [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) 운영.

| 순위 | 작업 | 목표 (3개월) | 근거 |
|:----:|------|--------------|------|
| **1** | **GAP panel enrich** | 0% → **≥50%** (중간) → 90% (장기) | SW1·URV 동시 실패 16건 — 최대 leverage |
| **2** | **titles.en · romanized ramp** | 21% → **≥40%** | 로마자 GAP 7건 · identity 1순위 레버 |
| **3** | **externalId 밀도** | 15% → **≥30%** (G2 phase 50% 향) | variant-only fallback |
| **4** | **Coverage CI 게이트** | `coverage_dashboard` + panel threshold | 구조 변경 없이 품질 회귀 방지 |
| **5** | **G1 실측 파일럿** | 월 net insert·maintainer 분 **실측** | SIM-A throughput은 통과 · burden 미통과 |
| **6** | **URV-B / SW1-A 회귀** | enrich 배치마다 before/after | Baseline 81.6% 하락 금지 |

**하지 않는 것 (Phase 2):** 새 ADR · 스키마 변경 · search_index 아키텍처 refactor (SW2는 A6 게이트 후).

---

## 6. 지금 시점에서 새 ADR 작성이 필요한가?

### **No**

**근거 (실험 결과만):**

1. Baseline v1 ADR-001·003·004·005(음악 제외)·006은 Phase 1 검증에서 **반박되지 않음**.
2. Phase 1 실패는 **구조**가 아니라 **메타 커버리지** — ADR가 아니라 **enrich·KPI·운영**으로 해결 가능.
3. ADR-002(음악)는 **기존 초안**에 B안 가중 잠정 — 402·5k 범위 밖 · 음악 도입 **전** 재개하면 됨. **신규 ADR 불필요**.
4. URV-A·SW1-A가 요구하는 것은 `titles.en`·alias·externalId **부착**이지 엔티티 모델 변경이 아님.

**예외 (신규 ADR이 아닌 기존 항목 재개):**

| 항목 | 시점 |
|------|------|
| ADR-002 최종 확정 | 음악 카테고리 도입 시 |
| ADR-006 구현 세부 (O1~O6) | Franchise 도구화 시 — **정책은 이미 승인** |

---

## 7. Phase 1 종료 선언

| Phase | 상태 |
|-------|------|
| Baseline v1 문서 고정 | ✅ |
| SIM-A/B/C/D | ✅ |
| SW1-A (402 recall) | ✅ |
| URV-A (identity baseline) | ✅ |
| Coverage Dashboard 정의 | ✅ |
| **Phase 1 검증** | **✅ 종료** |
| **Phase 2** | **Coverage Improvement Program** 시작 |

**종료 조건 충족:** 구조 가정(A1·A2·A4) Supported · A3는 구조 Supported·Coverage 운영 과제로 분리 · 미검증(A5·A6)은 범위 밖으로 명시 · 최대 리스크가 enrich로 수렴.

---

## 8. 참조 맵

```
Baseline v1 (고정)
    ↓ Phase 1 검증
SIM-A/B/C/D · SW1-A · URV-A · Coverage Dashboard
    ↓ 본 문서 (종료)
Phase 2: Coverage Improvement Program
    ↓
URV-B · SW1 회귀 · G1 실측 (병행)
```

---

## 9. 원칙 (Phase 2 carry-over)

1. **구조는 건드리지 않고** 표면형을 채운다.
2. **Panel KPI**(GAP·alias·subtitle)가 Registry-wide보다 우선.
3. SW1 recall · URV 수렴 · Coverage KPI는 **동일 실패의 다른 측정** — 통합 게이트 유지.
4. Baseline v1 본문은 **Phase 1 반박이 없는 한 불변** — 변경은 검증 산출물 → ADR **개정**으로만 (신규 ADR 없음).
