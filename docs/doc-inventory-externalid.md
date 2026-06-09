# 문서 인벤토리 — externalId · Quality Gate · Coverage Governance

> **목적:** 설계 재개 전 **기존 문서 중복·공백** 조사  
> **기준일:** 2026-06-09 · Registry **430 works**  
> **범위:** `docs/` · `docs/adr/` 전수 목록 + 주제 7종 매핑

**금지 준수:** 신규 규칙 **없음** · ADR **작성 없음** · **조사만**

---

## Executive Summary

| 주제 | 기존 문서 | 공백·중복 | 수정 후보 |
|------|-----------|-----------|-----------|
| externalId quality gate | **3+** (draft 1 · risk 1 · sprint 측정 2) | `quality-gate-mvp`와 **축 분리** · Rule ID **E1–E5 충돌** | **높음** |
| coverage governance | **4** (정의 1 · 인벤토리 1 · KPI 1 · charter) | 역할 **분명** · 수치 **402 vs 430** 혼재 | 중간 |
| attach validation | **5+** (분산) | **단일 attach gate SSOT 없음** | 높음 |
| identity validation | **5+** (URV · canonical · locale · MVP) | 계층 **분리됨** · 통합 인덱스 없음 | 낮음 |
| duplicate detection | **4+** | URV·canonical·A5·E3/E5 **병렬** | 중간 |
| sprint 04 findings | **11** | `final-review` vs **Phase B** **시점 불일치** | **높음** |
| quality gate mvp | **1** (+ governance 링크) | externalId **명시 제외** | 낮음 |

### 신규 ADR 필요 여부

| 판정 | **당분간 불필요** |
|------|-------------------|
| 근거 | attach gate는 **문서 초안**(`externalid-quality-gate-rules.md`) 단계 · 구현·정책 확정 **전** · 기존 문서가 **「신규 ADR 금지」** 명시 ([coverage-quality-governance.md](coverage-quality-governance.md) · [externalid-quality-risk-review.md](externalid-quality-risk-review.md)) |
| 대안 | 정책 확정 시 **(1)** [coverage-quality-governance.md](coverage-quality-governance.md) §4 확장 · **(2)** `externalid-quality-gate-rules.md` 승격 · **(3)** 그 후에만 ADR-007 검토 |
| 관련 ADR | [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md) — duplicate **예외** · [ADR-001](adr/ADR-001-dual-layer-entity-model.md) — Work identity · **externalId attach 전용 ADR 없음** |

---

## 1. `docs/` 전체 목록 (67건)

`docs/adr/` **제외** · 파일명 가나다순.

| # | 파일 | 한 줄 목적 (추정) |
|---|------|-------------------|
| 1 | [a5-discovery-charter.md](a5-discovery-charter.md) | A5 Discovery 프로그램 정의 |
| 2 | [a5-duplicate-resolution-review.md](a5-duplicate-resolution-review.md) | Pilot fuzzyTitle 중복 3건 운영 결정 |
| 3 | [a5-gate-review.md](a5-gate-review.md) | A5 Gate 검토 |
| 4 | [a5-hypothesis-map.md](a5-hypothesis-map.md) | A5 가설 맵 |
| 5 | [a5-operational-decisions.md](a5-operational-decisions.md) | A5 운영 결정 |
| 6 | [a5-pilot-charter.md](a5-pilot-charter.md) | A5 Pilot Charter |
| 7 | [a5-pilot-final-review.md](a5-pilot-final-review.md) | A5 Pilot 종료 리뷰 |
| 8 | [a5-pilot-gate-decision-record.md](a5-pilot-gate-decision-record.md) | Pilot Gate 결정 기록 |
| 9 | [a5-pilot-launch-review.md](a5-pilot-launch-review.md) | Pilot 착수 리뷰 |
| 10 | [a5-pilot-observation-log.md](a5-pilot-observation-log.md) | Pilot 관측 로그 |
| 11 | [a5-pilot-readiness-review.md](a5-pilot-readiness-review.md) | Pilot 준비도 리뷰 |
| 12 | [a5-question-register.md](a5-question-register.md) | A5 질문 레지스터 |
| 13 | [a5-scale-expansion-cohort-plan.md](a5-scale-expansion-cohort-plan.md) | Scale expansion cohort |
| 14 | [a5-scale-observation-log.md](a5-scale-observation-log.md) | Scale 관측 로그 |
| 15 | [a5-scale-operational-decisions.md](a5-scale-operational-decisions.md) | Scale SD1–SD4 운영 결정 |
| 16 | [a5-scale-plan.md](a5-scale-plan.md) | A5 Scale 계획 |
| 17 | [a5-verification-charter.md](a5-verification-charter.md) | A5 검증 Charter |
| 18 | [akasha-db-implementation-plan.md](akasha-db-implementation-plan.md) | akasha-db 구현 계획 |
| 19 | [akasha-db-policy.md](akasha-db-policy.md) | akasha-db 데이터 정책 |
| 20 | [assumption-register.md](assumption-register.md) | 가정 레지스터 (A3·URV 등) |
| 21 | [baseline-v1.md](baseline-v1.md) | Baseline v1 |
| 22 | [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Coverage KPI·패널 정의 |
| 23 | [canonicalization-policy.md](canonicalization-policy.md) | Identity·dedupe 정책 초안 |
| 24 | [catalog-contribution-roadmap.md](catalog-contribution-roadmap.md) | Contribution 로드맵 |
| 25 | [catalog-expansion-plan.md](catalog-expansion-plan.md) | 카탈로그 확장 계획 |
| 26 | [catalog-ownership.md](catalog-ownership.md) | Tier 0/1 소유권 |
| 27 | [commerce-boundary.md](commerce-boundary.md) | 커머스 경계 |
| 28 | [contribution-model-strategy.md](contribution-model-strategy.md) | Contribution 모델 |
| 29 | [coverage-quality-governance.md](coverage-quality-governance.md) | Coverage·Quality **거버넌스 정의** |
| 30 | [data-architecture-redesign.md](data-architecture-redesign.md) | 데이터 아키텍처 |
| 31 | [data-policy.md](data-policy.md) | 데이터 정책 (필드 분류) |
| 32 | [discovery-policy.md](discovery-policy.md) | Discovery 정책 |
| 33 | [expansion-tool-grading.md](expansion-tool-grading.md) | insert 도구 등급 |
| 34 | [externalid-economics-plan.md](externalid-economics-plan.md) | externalId G2 Economics |
| 35 | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | externalId attach Rule E1–E5 **초안** |
| 36 | [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | externalId 품질 리스크 |
| 37 | [global-search-query-set.md](global-search-query-set.md) | SW1 쿼리 세트 |
| 38 | [global-search-validation-plan.md](global-search-validation-plan.md) | SW1 검증 계획 |
| 39 | [locale-catalog-policy.md](locale-catalog-policy.md) | titles·aliases 로케일 |
| 40 | [my-library-design.md](my-library-design.md) | My Library 설계 |
| 41 | [phase1-final-review.md](phase1-final-review.md) | Phase 1 종료 |
| 42 | [phase2-charter.md](phase2-charter.md) | Phase 2 Charter |
| 43 | [phase2-final-review.md](phase2-final-review.md) | Phase 2 종료 |
| 44 | [phase2-governance-review.md](phase2-governance-review.md) | Phase 2 **운영 규칙 인벤토리** |
| 45 | [phase2-late-stage-plan.md](phase2-late-stage-plan.md) | Phase 2 후반 질문 |
| 46 | [phase2-mid-review.md](phase2-mid-review.md) | Phase 2 중간 리뷰 |
| 47 | [phase2-summary.md](phase2-summary.md) | Phase 2 요약 |
| 48 | [project-status-snapshot.md](project-status-snapshot.md) | 프로젝트 스냅샷 @430 |
| 49 | [quality-gate-mvp.md](quality-gate-mvp.md) | `titles.en` Quality Gate MVP |
| 50 | [README.md](README.md) | Docs 인덱스 |
| 51 | [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) | Registry 병목 검증 |
| 52 | [registry-growth-strategy.md](registry-growth-strategy.md) | Registry 성장 전략 |
| 53 | [registry-scaling-review.md](registry-scaling-review.md) | Registry 스케일링 |
| 54 | [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) | 5k/50k 리스크 |
| 55 | [search-index-architecture-options.md](search-index-architecture-options.md) | 검색 인덱스 옵션 |
| 56 | [search-index-validation-plan.md](search-index-validation-plan.md) | 검색 인덱스 검증 |
| 57 | [search-workload-profile.md](search-workload-profile.md) | 검색 워크로드 |
| 58 | [sprint-04-baseline-report.md](sprint-04-baseline-report.md) | Sprint 04 Phase A baseline |
| 59 | [sprint-04-charter.md](sprint-04-charter.md) | Sprint 04 Charter |
| 60 | [sprint-04-e1-audit.md](sprint-04-e1-audit.md) | E1 cohort 감사 (Phase B) |
| 61 | [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) | E1–E5 post-gate (Phase B-4) |
| 62 | [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) | E4 실효성 (Phase B-5) |
| 63 | [sprint-04-final-review.md](sprint-04-final-review.md) | Sprint 04 **실행 완료** 리뷰 @402 |
| 64 | [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md) | HIGH 4건 disposition |
| 65 | [sprint-04-readiness-review.md](sprint-04-readiness-review.md) | Sprint 04 착수 승인 |
| 66 | [universal-registry-validation.md](universal-registry-validation.md) | URV — identity·dedupe 검증 |
| 67 | [v4-migration-plan.md](v4-migration-plan.md) | v4 마이그레이션 |

---

## 2. `docs/adr/` 전체 목록 (7건)

| # | 파일 | 목적 | 상태 (README 기준) |
|---|------|------|-------------------|
| — | [adr/README.md](adr/README.md) | ADR 인덱스 | active |
| 1 | [adr/ADR-001-dual-layer-entity-model.md](adr/ADR-001-dual-layer-entity-model.md) | Work + Franchise 이중 모델 | **승인** |
| 2 | [adr/ADR-002-music-registry-model.md](adr/ADR-002-music-registry-model.md) | 음악 Registry A/B | 초안 |
| 3 | [adr/ADR-003-series-minimum-unit.md](adr/ADR-003-series-minimum-unit.md) | 시리즈 최소 단위 | 초안·원칙 승인 |
| 4 | [adr/ADR-004-work-collection-policy.md](adr/ADR-004-work-collection-policy.md) | 작품 수집 정책 | 초안·원칙 승인 |
| 5 | [adr/ADR-005-minimum-recordable-unit.md](adr/ADR-005-minimum-recordable-unit.md) | 매체별 최소 기록 단위 | 초안 |
| 6 | [adr/ADR-006-franchise-boundary-hierarchy.md](adr/ADR-006-franchise-boundary-hierarchy.md) | Franchise 경계·계층 | 초안 |

**externalId attach / quality gate 전용 ADR: 없음.**

---

## 3. 주제별 기존 문서 존재 여부

### 3.1 externalId quality gate

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | attach **전** Rule E1–E5 (Site Error · Save · dup · similarity) | **draft** | **예** — E4 overlap [B-5](sprint-04-e4-effectiveness-review.md) 재정의 반영 |
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | externalId 확대 **리스크** · MVP 한계 | **active** | 예 — gate 초안 링크 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | `titles.en` syntactic gate · **externalId 미포함** 명시 | **active** (구현됨) | 낮음 — cross-link만 |
| [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) | E1–E5 적용 시뮬레이션 결과 | **draft** (측정) | 예 — @430 기준 유지 |
| [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) | E4 과보수성 검증 | **draft** (분석) | 예 — rules 문서와 **동기화** |

**중복·충돌**

| 유형 | 설명 |
|------|------|
| **Rule ID 충돌** | [coverage-quality-governance.md](coverage-quality-governance.md) §4.2 **E1–E8** = enrich 경로 게이트 · [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) **E1–E5** = externalId attach 게이트 — **동일 접두사·다른 의미** |
| **축 분리** | `quality-gate-mvp` = titles.en · externalId rules = **별 문서** — 의도적 분리이나 **통합 인덱스 없음** |
| **SSOT 부재** | attach gate **정책 SSOT** = `externalid-quality-gate-rules.md` (초안) · **코드 미구현** |

---

### 3.2 coverage governance

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [coverage-quality-governance.md](coverage-quality-governance.md) | Coverage vs Quality · insert/enrich/release **게이트 정의** | **active** | 중간 — §4 Rule ID rename 검토 |
| [phase2-governance-review.md](phase2-governance-review.md) | Phase 2 **도입된** 운영 통제 **요약 인벤토리** | **active** | 중간 — Sprint 04 Phase B **미반영** |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Coverage **KPI** · 패널 | **active** | 낮음 |
| [phase2-charter.md](phase2-charter.md) | G2 목표 · Sprint 범위 | **active** (Phase 2 동결) | 낮음 |
| [phase2-late-stage-plan.md](phase2-late-stage-plan.md) | Q2 externalId 등 **미검증 질문** | **active** | 중간 — Sprint 04 B-phase로 **부분 갱신됨** |
| [project-status-snapshot.md](project-status-snapshot.md) | @430 gate·coverage **스냅샷** | **active** | 낮음 |

**중복:** `coverage-quality-governance` = **정의서** · `phase2-governance-review` = **요약본** — 내용 **겹침** 있으나 역할 상이.

---

### 3.3 attach validation

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | externalId attach **PRE-check** (문서) | **draft** | **예** |
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | Steam/TMDB attach **오류 유형** | **active** | 낮음 |
| [coverage-quality-governance.md](coverage-quality-governance.md) §4.1 | **I2** externalId 선검증 · **I3** poster–ID | **active** | 중간 |
| [sprint-04-e1-audit.md](sprint-04-e1-audit.md) | E1 cohort **수동 감사** | **draft** (측정) | 낮음 |
| [externalid-economics-plan.md](externalid-economics-plan.md) | attach **대상·규모** (Economics) | **active** | 낮음 |

**도구 (문서화):** `tool/poster_verification.dart` · `tool/coverage_sprint_04_external_id.dart` — **attach runner** · gate **미통합**

**공백:** attach validation **단일 SSOT 문서+코드** 없음 — governance I2/I3 · externalId rules · sprint 감사 **분산**.

---

### 3.4 identity validation

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [universal-registry-validation.md](universal-registry-validation.md) | URV — identity consistency · relation · dedupe | **active** (검증 계획) | 낮음 |
| [canonicalization-policy.md](canonicalization-policy.md) | identity·dedupe·franchise **정책** | **draft** (설계 초안) | 중간 |
| [locale-catalog-policy.md](locale-catalog-policy.md) | `titles` · `aliases` 계약 | **active** | 낮음 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | `titles.en` **syntactic** identity 표면 | **active** | 낮음 |
| [coverage-quality-governance.md](coverage-quality-governance.md) | enrich 경로별 identity **실패 유형** | **active** | 낮음 |
| [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) | ko/en **semantic** identity (E4) | **draft** | 예 |

**중복:** 계층별 분리 (URV > policy > MVP > sprint) — **통합 문서는 없으나** 상호 참조 가능.

---

### 3.5 duplicate detection

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [universal-registry-validation.md](universal-registry-validation.md) | dedupe precision · exactId 축 | **active** | 낮음 |
| [canonicalization-policy.md](canonicalization-policy.md) | 중복 vs franchise vs edition | **draft** | 중간 |
| [a5-duplicate-resolution-review.md](a5-duplicate-resolution-review.md) | fuzzyTitle **3건** 운영 결정 | **active** (판단만) | 낮음 |
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | **E3·E5** attach-time duplicate | **draft** | 예 |
| [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md) | steam id **중복** HIGH 2건 | **draft** | 낮음 |
| [phase2-governance-review.md](phase2-governance-review.md) | `dedupe_linter` 운영 | **active** | 낮음 |

**도구:** `dedupe_linter` · `urv_a_validation` (duplicate external key)

**중복:** insert-time dedupe (A5) vs attach-time dup (E3/E5) vs URV — **시점별 분리** · 문서 간 **교차 링크 부족**.

---

### 3.6 sprint 04 findings

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [sprint-04-charter.md](sprint-04-charter.md) | Sprint 정의 @402 | **active** (charter) | **예** — @430 재기준선 |
| [sprint-04-readiness-review.md](sprint-04-readiness-review.md) | 착수 승인 | **active** (historical) | 낮음 |
| [externalid-economics-plan.md](externalid-economics-plan.md) | Economics @402 | **active** | **예** — 수치 |
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | Quality 리스크 @402 | **active** | 중간 |
| [sprint-04-final-review.md](sprint-04-final-review.md) | **141건 apply 완료** @402 · G2 달성 | **deprecated†** | **예** — Phase B와 **모순** |
| [sprint-04-baseline-report.md](sprint-04-baseline-report.md) | Phase A @430 | **draft** (측정) | 낮음 |
| [sprint-04-e1-audit.md](sprint-04-e1-audit.md) | Phase B E1 감사 | **draft** | 낮음 |
| [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md) | Phase B-2 | **draft** | 낮음 |
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | Phase B-3 | **draft** | 예 |
| [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) | Phase B-4 | **draft** | 낮음 |
| [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) | Phase B-5 | **draft** | 낮음 |

† **deprecated 판정 근거:** `final-review`는 201/402 apply·자동 attach 100% 기록 · 현재 Registry **430** · externalId **46.74%** · Phase B는 **apply 보류·재감사** — **동일 Sprint의 상충 서사**.

**권고:** Sprint 04 **서사 SSOT** = Phase A–B 시리즈 + `project-status-snapshot` · `final-review`는 **「1차 실행」** 아카이브로 격하 표기.

---

### 3.7 quality gate mvp

| 파일 | 목적 | 상태 | 수정 후보 |
|------|------|:----:|:---------:|
| [quality-gate-mvp.md](quality-gate-mvp.md) | R0–R6 · RB1–RB2 · `quality_gate.dart` | **active** (구현 완료) | 낮음 |
| [coverage-quality-governance.md](coverage-quality-governance.md) | E7·R3 → MVP **연결** 명시 | **active** | 낮음 |
| [phase2-governance-review.md](phase2-governance-review.md) | Quality Governance **요약** | **active** | 낮음 |
| [tool/coverage_quality.dart](../tool/coverage_quality.dart) | 구현 (문서 아님) | active | — |

**공백:** MVP는 **externalId RB 없음** — [externalid-quality-risk-review.md](externalid-quality-risk-review.md) §Executive와 **일치**.

---

## 4. 중복·갭 매트릭스

| 갭 / 중복 | 관련 문서 | 심각도 | 권고 조치 (문서만) |
|-----------|-----------|:------:|-------------------|
| **E1–E5 vs E1–E8 이름 충돌** | governance · externalid-rules | **높음** | attach 쪽 **Ex1–Ex5** 또는 **RB-E*** rename — **한 문서에서 매핑표** |
| **Sprint 04 이중 서사** | final-review vs Phase B* | **높음** | final-review **deprecated** 배너 · README 인덱스 정리 |
| **402 vs 430 기준선** | charter · economics · snapshot | 중간 | charter/economics ** superseded note** 또는 snapshot **단일 기준** |
| **attach SSOT 분산** | governance I2 · rules · sprint | 중간 | `externalid-quality-gate-rules` 승격 시 governance §4 **참조** |
| **E4 정책 불일치** | rules · e4-effectiveness | 중간 | rules **§E4 개정** (overlap 폐기 권고) |
| **docs/README 미등록** | Phase B 5건 · inventory | 낮음 | README Sprint 04 섹션 **분리** |

---

## 5. 수정 후보 우선순위 (설계 재개 전)

| 순위 | 문서 | 사유 |
|:----:|------|------|
| P0 | [sprint-04-final-review.md](sprint-04-final-review.md) | Phase B와 **상충** — 상태 명시 |
| P0 | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | B-4·B-5 **실측** 미반영 · E4 |
| P1 | [coverage-quality-governance.md](coverage-quality-governance.md) | Rule ID **충돌** 해소 · attach gate **참조** |
| P1 | [docs/README.md](README.md) | Sprint 04 Phase B·본 inventory **링크** |
| P2 | [phase2-governance-review.md](phase2-governance-review.md) | @430 · externalId gate **한 줄** |
| P2 | [sprint-04-charter.md](sprint-04-charter.md) · [externalid-economics-plan.md](externalid-economics-plan.md) | G2 **215/430** 재기준선 |

**구현·apply·ADR:** 본 인벤토리 **범위 외**.

---

## 6. ADR 필요성 판단 (상세)

| 질문 | 답 |
|------|-----|
| externalId attach를 **아키텍처 결정**으로 고정해야 하는가? | **아직 아님** — B-3~B-5는 **측정·초안** · E4 **폐기/축소** 미확정 |
| 기존 ADR로 **커버**되는가? | **부분** — ADR-001(Work identity) · ADR-006(franchise·dup 예외) · **attach gate 정책은 미포함** |
| canonicalization-policy와 **중복 ADR**? | canonicalization = **draft 정책 문서** — ADR **대체 아님** |
| 언제 ADR 검토? | (1) E1–E5 **승인** · (2) `quality_gate --release` **RB-E** 구현 결정 · (3) franchise dup **allowlist** 확정 |

**결론:** **신규 ADR 작성 불필요** — 정책 확정 후 **기존 governance 확장** 우선 · ADR-007은 **구현 착수 Gate**로 연기.

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | externalId·gate 주제 인벤토리 — docs 67 + adr 7 |
