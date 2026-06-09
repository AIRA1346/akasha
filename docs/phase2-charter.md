# Phase 2 Charter — Coverage Improvement Program

> **성격:** 운영 계획 문서 — **설계·아키텍처 문서가 아님**.  
> **전제:** [Baseline v1](baseline-v1.md) **Validated through Phase 1** · [phase1-final-review.md](archive/phase1-final-review.md)  
> **Mid-Review:** [phase2-mid-review.md](archive/phase2-mid-review.md) — Sprint 01~03 의사결정 기록  
> **기준일:** 2026-06-09 · Registry **402작** (G1→G2 병행)

---

## 1. 목적

**Canonical Identity Coverage 개선** — Registry가 **사람들이 실제로 쓰는 이름(표면형)** 을 충분히 알고 있도록 메타를 enrich한다.

Phase 1 결론 — **검증 완료:**

| 영역 | 상태 |
|------|------|
| Registry 구조 | ✅ |
| Franchise 구조 | ✅ |
| Stub-first | ✅ |
| 5k 확장성 | ✅ |
| Search / Identity **구조** | ✅ |

**남은 핵심 과제:** Canonical Identity Coverage — *「무엇을 만들 것인가?」* 가 아니라 **「어떻게 채울 것인가?」**.

- Registry **구조**는 Supported (Dual-layer · `wk_` · dedupe · Franchise).
- 실패의 직접 원인은 **표면형 미부착** (MISSING_LOCALE / MISSING_TOKEN).
- Phase 2 우선순위: **구조 설계 < Coverage KPI 운영**.

**Mid-Review 이후 재정의 (Sprint 01~03):** Phase 2의 미해결 질문은 *「Coverage가 가능한가?」* 가 아니라 **「Coverage를 어떤 품질 관리 체계로 유지할 것인가?」** 에 가깝다. ([phase2-mid-review.md](archive/phase2-mid-review.md) §Executive Summary)

---

## 1.1 현재 상태 (Sprint 01~03 · Mid-Review)

> 근거: [phase2-mid-review.md](archive/phase2-mid-review.md) · `tool/coverage_sprint_0*.dart`

### 검증 완료 (Mid-Review 합의)

| 항목 | 판정 |
|------|------|
| Coverage 리스크 **존재** | ✅ 확인 (Phase 1·panel FAIL) |
| **enrich로 해결 가능** | ✅ Sprint 01: 17 Work → SW1/URV/GAP 100% |
| **구조 변경 불필요** | ✅ Sprint 01~03 전 구간 무변경 |
| Sprint 02 **Economics 과대추정** | ✅ Sprint 03: 22.9h 추정 vs human-eq **~11.6h** |
| **자동화 실효성** | ✅ titles.en 축 auto+semi **100%** (도구 체인 전제) |

### Sprint 요약

| Sprint | 목적 | 핵심 결과 |
|--------|------|-----------|
| **01** | GAP panel minimal enrich | 17 Work · SW1/URV **81.6%→100%** · GAP **0%→100%** |
| **02** | Coverage Economics **추정** | titles.en 90% **~60.1h** · 50% **22.9h** · auto **~11%** 가정 |
| **03** | Economics **실측** (50% 마일스톤) | titles.en **24.9%→91.5%** · SW1/URV/GAP **100%** 유지 · wall **~1분대** |

### KPI 스냅샷 (Sprint 03 이후)

| 층 | KPI | Sprint 01 후 | **현재 (Sprint 03)** | Phase 2 target |
|----|-----|:------------:|:--------------------:|:--------------:|
| **Panel** | GAP | 100% | **100%** | ≥ 90% |
| **Panel** | alias | 100% | **100%** | ≥ 90% |
| **Panel** | subtitle | 100% | **100%** | ≥ 90% |
| **Registry** | titles.en | 24.9% | **91.5%** | 90% (G2) ✅ |
| **Registry** | romanized alias | 22.7% | **~91%** | G2 50% ✅ |
| **Registry** | zh | ~1% | **~1%** | G3 전 30% |
| **Registry** | externalId | 14.9% | **~15%** | G2 **50%** |
| **회귀** | SW1 recall@10 | 100% | **100%** | ≥ 100% |
| **회귀** | URV convergence | 100% | **100%** | ≥ 100% |

**A3:** **Supported (Operational Dependency)** 유지 — 최신 근거 [assumption-register.md](assumption-register.md) §10 · [phase2-mid-review.md](archive/phase2-mid-review.md) §5.

**다음 초점:** titles.en 연장이 아닌 **zh · externalId · composite Economics** + **auto enrich 품질 가드** (Sprint 04 재정의).

---

## 2. 범위

다음 필드·축의 **커버리지 향상**만 다룬다. ([locale-catalog-policy.md](locale-catalog-policy.md) · [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) 계약 준수)

| 축 | 대상 필드·신호 | 운영 게이트 |
|----|----------------|-------------|
| **titles.en** | `titles.en` | Registry-wide + GAP panel |
| **romanized aliases** | `titles.romaji` · `titles.en` · latin `aliases[]` | GAP panel · romanized KPI |
| **zh titles** | `titles.zh` | GAP panel (CJK 4건) |
| **subtitle aliases** | `titles.en` · `aliases[]` — 부제·시리즈 영문 | subtitle panel |
| **season aliases** | `extensions.seasons[]` · 시즌 표기 alias | season KPI (animation/drama) |
| **externalIds** | `externalIds` 맵 | Registry-wide · G2 phase target |

**작업 유형 (허용):**

- 기존 Work shard **메타 enrich** (PR · contribution merge)
- `registry_builder` 재실행 · search_index 갱신
- `dart run tool/coverage_dashboard.dart` 스냅샷
- `dart run tool/sw1_a_validation.dart` · `dart run tool/urv_a_validation.dart` 회귀

---

## 3. 거버넌스 — Phase 2 동안 원칙적 금지

Phase 2는 **순수 운영·데이터 품질 개선** 단계이다. 아래는 **원칙적 금지** — 예외는 §3.2만 따른다.

| 금지 | 내용 |
|------|------|
| **신규 ADR 작성** | Baseline v1 ADR 세트 유지 · ADR-002는 기존 초안만 도입 시 재개 |
| **Registry 구조 변경** | `wk_` · 샤드 · 스키마 · dedupe 알고리즘 · search_index 아키텍처 |
| **Franchise 구조 변경** | ADR-006 F1 · `franchise_groups` 모델 · 계층 규칙 |

**기타 범위 밖 (금지와 동일 취급):** SW2(30M index) · 음악 카테고리 도입 · A5/A6 본검증 전 구조 선제 수정.

### 3.1 허용 작업 (기본)

- Work shard **메타 enrich** (`titles` · `aliases` · `externalIds` · `extensions.seasons`)
- Contribution merge · 수동 PR · `registry_builder` · Coverage/SW1/URV 회귀
- G1/G2 **insert** ([registry-growth-strategy](registry-growth-strategy.md)) — stub-first 전제 유지

### 3.2 예외 — 아래 **셋 중 하나**가 **실측·회귀로 확인**될 때만

구조·ADR 변경 논의를 **재개**할 수 있다. Coverage enrich로 우선 해결 시도 후 판단한다.

| # | 예외 조건 |
|---|-----------|
| **1** | **Coverage 개선으로 해결 불가능**한 문제가 발견됨 (enrich·panel KPI·externalId로도 동일 실패 재현) |
| **2** | **SW1 / URV 회귀**에서 **구조적 결함**이 재현됨 (MISSING_TOKEN이 아닌 모델·알고리즘 한계) |
| **3** | **A5 또는 A6 검증**이 기존 구조를 **직접 반박**함 |

예외 발동 시: `assumption-register` 증거 등급 갱신 → 사용자 승인 후 ADR **개정**(신규 ADR 최소화) — Phase 1과 동일한 거버넌스.

**그 외:** Phase 2는 enrich·KPI·회귀만 진행한다.

---

## 4. 핵심 KPI

**단일 기준:** [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md)

**측정:** `dart run tool/coverage_dashboard.dart`  
**산출물:** `akasha-db/pipeline/artifacts/coverage_dashboard/coverage_snapshot.json`

### 4.1 운영 게이트 (Panel — 우선)

| KPI | Sprint 01 후 | Phase 2 target |
|-----|:------------:|:--------------:|
| **GAP panel** | **100%** (16/16) ✅ | **≥ 90%** 유지 |
| **alias panel** | **100%** (11/11) ✅ | **≥ 90%** 유지 |
| **subtitle panel** | **100%** (9/9) ✅ | **≥ 90%** 유지 |

### 4.2 Registry-wide (보조·백로그)

| KPI | Sprint 01 후 | **Sprint 03 후** | Phase 2 milestone |
|-----|:------------:|:----------------:|:-----------------:|
| **titles.en** | 24.9% | **91.5%** ✅ | ~~90%~~ 달성 · **유지·회귀** |
| **romanized alias** | 22.7% (375작) | **~91%** ✅ | G2 **50%** |
| **zh** | ~1% | **~1%** | G3 전 **30%** (Phase 2 후반) |
| **season** | 43.3% (anim+drama) | — | **60%** |
| **externalId** | 14.9% | **~15%** | **G2 목표 50%** |

**Economics:** Sprint 02 추정 [`coverage_sprint_02_economics.dart`](../tool/coverage_sprint_02_economics.dart) · Sprint 03 실측 [`coverage_sprint_03_titles_en.dart`](../tool/coverage_sprint_03_titles_en.dart) — [phase2-mid-review.md](archive/phase2-mid-review.md) §4.

### 4.3 회귀 지표 (품질 하락 방지)

| 지표 | Sprint 01 후 | Phase 2 하한 |
|------|:------------:|:------------:|
| SW1-A recall@10 | **100%** | **≥ 100%** (Sprint 01 이후 하락 금지) |
| URV-A query convergence | **100%** | **≥ 100%** (동일) |

**A3:** **Supported (Operational Dependency)** — [assumption-register.md](assumption-register.md) §10 · [phase2-mid-review.md](archive/phase2-mid-review.md) · KPI·품질 가드 유지 전제.

---

## 5. 성공 조건

Phase 2 **중간·최종 성공**은 아래를 **모두** 충족할 때 선언한다.

| # | 조건 | 측정 |
|---|------|------|
| 1 | **GAP panel ≥ 90%** | `coverage_dashboard` |
| 2 | **alias panel ≥ 90%** | `coverage_dashboard` |
| 3 | **subtitle panel ≥ 90%** | `coverage_dashboard` |
| 4 | **externalId coverage — G2 목표 달성** | **≥ 50%** (402→G2 구간) |
| 5 | SW1-A recall@10 **≥ 402 baseline** | `sw1_a_validation` |
| 6 | URV-A convergence **≥ 402 baseline** | `urv_a_validation` |

---

## 6. 종료 조건

Phase 2 **종료**는 성공 조건(§5) 달성 **후**, 아래가 추가로 충족될 때이다.

| # | 종료 조건 |
|---|-----------|
| 1 | **SW1-A** 회귀에서 Identity Coverage 관련 **FAIL 제거** — GAP 태그 쿼리 recall@10 **≥ 90%** |
| 2 | **URV-A** 회귀에서 Identity Coverage 관련 **FAIL 제거** — 로마자 축 **FAIL → PASS/PARTIAL(≥90%)** |
| 3 | `coverage_dashboard` GAP · alias · subtitle panel **안정 PASS** (연속 2회 스냅샷) |

종료 시 산출: Phase 2 completion note (assumption-register · baseline 링크 갱신) — **신규 ADR 없음**.

---

## 7. 운영 워크플로

```
enrich PR / contribution merge
    ↓
dart run tool/registry_builder.dart [--sync-assets]
    ↓
dart run tool/coverage_dashboard.dart
    ↓
panel KPI 추적 (§4.1)
    ↓
dart run tool/urv_a_validation.dart
dart run tool/sw1_a_validation.dart
    ↓
§5 성공 조건 · §6 종료 조건 점검
```

**우선 enrich 백로그** (Sprint 01~03 ✅ — [phase2-mid-review.md](archive/phase2-mid-review.md)):

1. ~~GAP panel 16건~~ ✅
2. ~~Registry-wide titles.en → 90%~~ ✅ (Sprint 03: **91.5%** · 유지·회귀)
3. ~~romanized alias G2 50%~~ ✅ (Sprint 03 부수: **~91%**)
4. **externalId** 밀도 (G2 **50%** — Sprint 04 후보)
5. **zh** (+358작 — Sprint 04 후보)
6. **auto enrich 품질 가드** (TMDB fallback · CI)
7. alias field · season (백로그)

**Sprint 04 (재정의):** titles.en 연장 ❌ → **zh · externalId · composite Economics 검증** ([phase2-mid-review.md](archive/phase2-mid-review.md) §7).

---

## 8. 일정 (3개월 가이드)

| 기간 | 목표 |
|------|------|
| **M1** | ~~GAP panel · titles.en~~ ✅ Sprint 01~03 선행 완료 |
| **M2** | externalId **≥ 30%** · zh ramp 시작 · auto enrich CI |
| **M3** | §5 성공 조건 충족 시도 (externalId G2 50%) · Economics Sprint 04 |

일정은 **KPI 스냅샷**에 따라 조정. 구조 변경으로 일정을 맞추지 않는다.

---

## 9. 역할·문서 맵

| 문서 | Phase 2 역할 |
|------|--------------|
| [phase1-final-review.md](archive/phase1-final-review.md) | Phase 1 종료 근거 |
| **[phase2-mid-review.md](archive/phase2-mid-review.md)** | **Sprint 01~03 의사결정 · Economics · Sprint 04 재정의** |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | KPI 정의·baseline |
| [assumption-register.md](assumption-register.md) | A1–A6 판정 · §10 A3 최신 근거 |
| [baseline-v1.md](baseline-v1.md) | 설계 불변 참조 |
| [registry-growth-strategy.md](registry-growth-strategy.md) | G1/G2 insert 병행 (범위 밖 구조 변경 없음) |

---

## 10. 원칙

1. **구조는 고정** — enrich만으로 KPI를 올린다 (§3 예외 3종만 구조 재개).
2. **Panel KPI 우선** — GAP · alias · subtitle이 운영 게이트다.
3. SW1 · URV · Coverage Dashboard는 **동일 실패의 다른 측정** — 통합 게이트.
4. Phase 2 문서는 **운영 계획** — 아키텍처 제안·신규 ADR을 포함하지 않는다.
5. **채우기 우선** — 설계 논의보다 Coverage Improvement Program 실행.
6. **품질 관리 체계** — Coverage 가능성은 Sprint 01~03으로 확인됨; 이후는 KPI 유지·Economics·auto enrich QA가 운영 핵심 ([phase2-mid-review.md](archive/phase2-mid-review.md)).
