# Phase 2 Governance Review — AKASHA 운영 규칙

> **목적:** Phase 2에서 **실제로 도입된** 운영 통제 장치를 한 문서로 정리한다.  
> **질문:** *「AKASHA가 어떤 규칙으로 운영되는가?」*  
> **전제:** [Baseline v1](baseline-v1.md) Validated through Phase 1 · Registry **402작**  
> **기준일:** 2026-06-09

**성격:** 운영·거버넌스 인벤토리 — **신규 실험 · enrich · ADR · 구조 변경 없음**.

**선행 결정:** [phase2-mid-review.md](phase2-mid-review.md) — Coverage 가능성 검증 완료 → **품질·운영 모델** 단계.

---

## Executive Summary

Phase 2는 Registry **구조 고정** 아래 **Coverage enrich + KPI + 회귀 + Quality Gate** 로 운영한다.

| 층 | 한 줄 |
|----|--------|
| **Coverage Governance** | 무엇을·얼마나 채울 것인가 — Dashboard · Sprint · Economics |
| **Quality Governance** | 채운 값이 믿을 만한가 — `validateEnTitle` · 게이트 · spot-check |
| **Release Governance** | 언제 배포/동기화할 것인가 — `quality_gate --release` · panel·회귀 하한 |

**A3:** **Supported (Operational Dependency)** — 위 통제가 **유지될 때** Identity 모델은 성립한다.

---

## 1. Coverage Governance

### 1.1 목적·범위

- **목적:** Canonical Identity **Coverage** — 표면형(`titles` · `aliases` · `externalIds` 등) **존재 비율** 향상.
- **허용 작업:** Work shard **메타 enrich** · `registry_builder` · contribution merge · KPI/회귀 측정.
- **금지:** 신규 ADR · Registry/Franchise/search_index **구조 변경** ([phase2-charter.md](phase2-charter.md) §3).

### 1.2 거버넌스 문서

| 문서 | 역할 |
|------|------|
| [phase2-charter.md](phase2-charter.md) | Phase 2 범위·KPI·성공/종료 조건·워크플로 |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Coverage KPI 정의·PASS/FAIL |
| [phase2-mid-review.md](phase2-mid-review.md) | Sprint 01~03 · Economics 검증 기록 |
| [phase2-late-stage-plan.md](phase2-late-stage-plan.md) | 잔여 검증 질문·Sprint 04 재정의 |

### 1.3 Coverage Sprint (실측 완료)

| Sprint | 도구 | 역할 |
|--------|------|------|
| **01** | `tool/coverage_sprint_01_gap_enrich.dart` | GAP panel 17 Work — 구조 없이 SW1/URV/GAP **100%** |
| **02** | `tool/coverage_sprint_02_economics.dart` | Registry-wide **비용 추정** (~60.1h composite) |
| **03** | `tool/coverage_sprint_03_titles_en.dart` | titles.en Economics **실측** · auto enrich 체인 |

**Economics 교훈:** manual 상한(22.9h) ≠ 도구화 wall clock — **인력-equivalent·축별** 검증 필요 (Mid-Review).

### 1.4 Coverage 운영 워크플로

```
enrich PR / Sprint --apply
    ↓
dart run tool/registry_builder.dart [--sync-assets]
    ↓
dart run tool/coverage_dashboard.dart
    ↓
panel + registry-wide KPI (Coverage 층)
    ↓
dart run tool/sw1_a_validation.dart
dart run tool/urv_a_validation.dart
    ↓
(선택) dart run tool/quality_gate.dart --strict
```

### 1.5 예외 (구조 재개)

Charter §3.2 — 아래 **셋 중 하나** 실측 확인 시에만 ADR/구조 논의 재개:

1. Coverage로 **해결 불가**
2. SW1/URV **구조적 결함** (MISSING_TOKEN 아님)
3. A5/A6이 구조 **직접 반박**

---

## 2. Quality Governance

### 2.1 목적

Coverage **수량**과 **품질** 분리 — Sprint 03: titles.en **91.5%** 달성과 **31건** TMDB 오염 공존.

| 문서 | 역할 |
|------|------|
| [coverage-quality-governance.md](coverage-quality-governance.md) | enrich 경로·실패 유형·insert/enrich/release 게이트 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | `_isValidEnTitle` 규칙·CI·Release Block |

### 2.2 구현 (MVP)

| 구성요소 | 경로 |
|----------|------|
| 검증 규칙 | `tool/coverage_quality.dart` — `validateEnTitle()` · `scanTitlesEnQuality()` |
| enrich 가드 | `coverage_sprint_03` — auto 실패 시 **fallback 체인** · `isValidEnTitle` |
| 포스터–ID | `tool/poster_verification.dart` — TMDB poster 정합 |

### 2.3 자동 enrich 경로 (품질 관점)

| method | bucket | 품질 리스크 (확인됨) |
|--------|:------:|----------------------|
| `tmdb_fetch` | auto | HTML 템플릿 오염 (**31건**) — **단독 success 금지** |
| `steam_fetch` | auto | ID·HTML 변경 |
| `legacy_slug` | semi | 공식 표기 불일치 |
| `latin_title` | semi | 비영어 라틴 혼입 (rare) |

### 2.4 품질 게이트 (3단)

| 단계 | 게이트 ID | 핵심 (구현·문서) |
|------|-----------|------------------|
| **insert 전** | I1–I4 | Minimal Core · externalId · poster 검증 · stub 희석 감시 |
| **enrich 후** | E1–E8 | `isValidEnTitle` · TMDB match · fallback · dashboard · SW1/URV · invalid scan |
| **release 전** | R1–R5 | panel PASS · 회귀 하한 · invalid-en 0 · manifest sync |

**수동 검수 (문서화, CI 미연동):** auto tier spot-check · `legacy_slug` 샘플 · linguistic QA ([coverage-quality-governance.md](coverage-quality-governance.md) §6).

---

## 3. Release Governance

### 3.1 Release Block Rule (구현됨)

`tool/quality_gate.dart --release` · `coverage_snapshot.json` → `quality.release_block`

| 규칙 | 조건 | 동작 |
|------|------|------|
| **RB1** | `invalid_en_count > 0` | **Block** |
| **RB2** | `source_breakage_count > 0` | **Block** |
| **Override** | `--override` 또는 `akasha-db/pipeline/quality_gate_override.json` | Block **완화** (로그·만료) |

**원칙:** Coverage `titles.en` PASS여도 **Quality FAIL이면 release 보류**.

### 3.2 Release 체크리스트 (권장 순서)

```bash
dart run tool/coverage_dashboard.dart
dart run tool/quality_gate.dart --release
dart run tool/sw1_a_validation.dart
dart run tool/urv_a_validation.dart
dart run tool/registry_builder.dart --sync-assets   # assets/registry 동기화
```

### 3.3 CI 모드 (Quality Gate)

| 모드 | 용도 |
|------|------|
| default | 리포트 only |
| `--warn` | 경고, exit 0 |
| `--strict` | PR·enrich 배치 gate |
| `--release` | 배포·assets sync 전 |

**현재:** workflow 자동 연동은 **후속** — 로컬·dogfood에서 수동 실행 가능.

### 3.4 Phase 2 종료 vs Release

| 구분 | 기준 |
|------|------|
| **Release (배치)** | Quality RB1·RB2 + 회귀 하한 + `registry_builder --sync-assets` |
| **Phase 2 종료** | [phase2-charter.md](phase2-charter.md) §5·§6 — externalId G2 **50%** 등 **추가** 조건 |

Release 통과만으로 Phase 2 **완료**가 아님.

---

## 4. KPI 체계

### 4.1 두 층 + Panel

```
┌─────────────────────────────────────────────────────────┐
│  Panel KPI (운영 게이트) — GAP · alias · subtitle        │
├─────────────────────────────────────────────────────────┤
│  Coverage KPI (registry-wide) — titles.en · zh · …      │
├─────────────────────────────────────────────────────────┤
│  Quality KPI — invalid_en · source_breakage · release_block │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Coverage KPI (측정)

**도구:** `dart run tool/coverage_dashboard.dart`  
**산출:** `akasha-db/pipeline/artifacts/coverage_dashboard/coverage_snapshot.json` → `kpis`

| 층 | KPI (Sprint 03 후) | target | status |
|----|-------------------|--------|--------|
| **Panel** | GAP · alias · subtitle | ≥90% | **PASS** (100%) |
| **Registry** | titles.en | 90% | **PASS** (91.5%) |
| **Registry** | romanized_alias | 90% | **PASS** (~91%) |
| **Registry** | zh | 90% | **FAIL** (~1%) |
| **Registry** | externalId | 50% (G2) / 90% | **FAIL** (~15%) |
| **Registry** | season · alias_field 등 | 각 target | 대부분 **FAIL** |

### 4.3 Quality KPI (측정)

**동일 snapshot** → `quality` 섹션 · `tool/quality_gate.dart`

| KPI | 필드 | Sprint 03+ MVP baseline |
|-----|------|-------------------------|
| invalid_en_count | `quality.invalid_en_count` | **0** (remediate 후) |
| invalid_en_rate | `quality.invalid_en_rate` | **0** |
| source_breakage_count | `quality.source_breakage_count` | **0** |
| status | `quality.status` | **PASS** |
| release_block | `quality.release_block` | **false** |

### 4.4 의사결정 매트릭스

| Coverage | Quality | Release | 조치 |
|:--------:|:-------:|:-------:|------|
| PASS | PASS | ✅ | `registry_builder --sync-assets` |
| PASS | FAIL | ❌ | remediate · **override는 예외 기록** |
| FAIL | PASS | △ | enrich 계속 · release는 회귀 병행 |
| FAIL | FAIL | ❌ | 배치 중단 |

---

## 5. Regression Gates

**정의:** 동일 Identity 실패의 **다른 측정** — enrich 후 **하락 금지**.

| 게이트 | 도구 | Phase 2 하한 (Sprint 03 baseline) |
|--------|------|-----------------------------------|
| **SW1-A** | `tool/sw1_a_validation.dart` | recall@10 **≥ 100%** (87/87) |
| **URV-A** | `tool/urv_a_validation.dart` | query convergence **≥ 100%** (87/87) |
| **GAP diagnostic** | SW1-A 내 GAP proxy | **100%** (15/15) |
| **Panel** | `coverage_dashboard` | GAP · alias · subtitle **≥ 90%** |

**Charter §4.3:** Sprint 01 이후 SW1/URV **하락 금지**.

**한계 (문서화):** SW1/URV 100%는 **402·87 쿼리** 범위 — 쿼리 세트 확대 시 재기준 필요 ([coverage-quality-governance.md](coverage-quality-governance.md) M7).

### 회귀 워크플로 (enrich 배치 필수)

```
registry_builder
    → coverage_dashboard (panel)
    → sw1_a_validation
    → urv_a_validation
    → quality_gate (--strict 권장)
```

---

## 6. 현재 남은 리스크

> Sprint 01~03 · Quality Gate MVP · Mid-Review 기준. **구조 붕괴 리스크 제외.**

| # | 리스크 | 성격 | 통제 상태 |
|---|--------|------|-----------|
| **1** | **의미적 enrich 오류** (valid en · wrong title) | 품질 | Quality MVP **미검출** — 수동 spot-check |
| **2** | **비-en 축 Coverage 격차** (zh · externalId) | Coverage | Dashboard **FAIL** — Sprint 04 대상 |
| **3** | **composite Economics 미검증** | 운영 | Sprint 02 추정만 — zh/externalId 실측 필요 |
| **4** | **G1 stub 유입 → Coverage 희석** (A2) | 성장×운영 | insert 게이트 I4 **문서만** |
| **5** | **TMDB/Steam source 변경** | 공급 | auto tier **일괄 실패** 가능 — fallback 의존 |
| **6** | **CI 미연동** | 프로세스 | `quality_gate --strict` **로컬** — workflow 후속 |
| **7** | **A5 (50k 운영)** | 중기 가정 | Phase 2 **범위 밖** · G1 실측 미착수 |

**Phase 2 핵심 미해결 질문:** *「Coverage를 어떤 품질 관리 체계로 유지할 것인가?」* — MVP는 **syntactic** 층만 구현 · semantic·축별 Economics는 잔여.

---

## 7. Sprint 04 착수 조건

Sprint 04는 **titles.en 연장이 아님** — [phase2-late-stage-plan.md](phase2-late-stage-plan.md) · [phase2-mid-review.md](phase2-mid-review.md) §7.

**재정의 목적:** **zh · externalId · composite Economics** 검증.

### 7.1 착수 전제 (P0 — Quality Governance)

| # | 조건 | 상태 |
|---|------|:----:|
| G1 | `tool/coverage_quality.dart` · `tool/quality_gate.dart` **구현** | ✅ |
| G2 | `coverage_dashboard` **quality** 섹션 | ✅ |
| G3 | Release Block Rule (RB1·RB2) **문서+CLI** | ✅ |
| G4 | enrich 파이프라인 **E1–E3** (가드·fallback) Sprint 03 반영 | ✅ |
| G5 | `quality_gate --strict` **현 registry PASS** | ✅ |
| G6 | CI/dogfood **--strict 연동** | ⏳ 후속 (착수 **권장**, hard block 아님) |

### 7.2 Sprint 04 착수 조건 (권장)

| # | 조건 | 설명 |
|---|------|------|
| S1 | **P0 G1–G5** 충족 | Quality 운영 게이트 최소선 |
| S2 | **회귀 baseline 고정** | SW1/URV/GAP **100%** — Sprint 04 배치마다 동일 게이트 |
| S3 | **Economics Sprint 04 범위 확정** | zh cohort + externalId G2 50% cohort — **실험 설계만**, 본 문서 범위 밖 |
| S4 | **Release Block 운영 합의** | invalid_en > 0 → merge/sync **보류** (override 예외 절차) |

### 7.3 Sprint 04 착수하지 않는 조건

- titles.en **90% 미달** — **해당 없음** (91.5%)
- 구조 변경·신규 ADR로 Coverage 해결 시도 — **Charter 금지**
- Quality Gate 없이 대량 enrich — **Release Governance 위반**

### 7.4 Sprint 04 성공 시 기대 산출 (계획 수준)

- zh · externalId **Economics 실측** 리포트
- composite **갱신 비용 구간**
- Charter §5 **#4 externalId ≥50%** 진척 여부
- 회귀·Quality **유지** (`quality_gate --strict` PASS)

---

## 8. 문서·도구 맵

### 8.1 거버넌스 문서

| 문서 | 층 |
|------|-----|
| [phase2-governance-review.md](phase2-governance-review.md) | **본 문서** — 통합 운영 규칙 |
| [phase2-charter.md](phase2-charter.md) | Coverage 프로그램·종료 조건 |
| [coverage-quality-governance.md](coverage-quality-governance.md) | Quality 거버넌스 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | Quality Gate 구현 |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Coverage KPI |
| [assumption-register.md](assumption-register.md) §10 | A3 증거 |

### 8.2 운영 도구

| 도구 | Governance |
|------|------------|
| `coverage_dashboard.dart` | Coverage + Quality KPI |
| `quality_gate.dart` | Quality · Release block |
| `coverage_quality.dart` | `titles.en` 규칙 |
| `sw1_a_validation.dart` | Regression |
| `urv_a_validation.dart` | Regression |
| `registry_builder.dart` | 빌드·assets sync |
| `coverage_sprint_01/02/03` | Coverage Sprint (01~03 완료) |
| `poster_verification.dart` | insert/enrich 품질 보조 |

---

## 9. 한 줄 요약

**AKASHA Phase 2 운영 규칙:** 구조는 고정하고, enrich로 Coverage를 올리되, **Dashboard로 수량**을, **Quality Gate로 문법적 품질**을, **SW1/URV/Panel로 회귀**를, **`--release`로 배포**를 통제한다. Sprint 04는 이 통제 **위에서** zh·externalId Economics를 검증한다.

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Phase 2 도입 운영 통제만 정리 |
