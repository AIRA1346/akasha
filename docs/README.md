# AKASHA Docs Index

> **갱신:** 2026-06-10 · Registry **430 works** · externalId **G2 50% 달성**  
> 북극성: **2026 Q3 Steam v1 출시** — [../ROADMAP.md](../ROADMAP.md)

## 처음 읽는 순서

| 순서 | 문서 | 내용 |
|:----:|------|------|
| 0 | [product-vision.md](product-vision.md) | **제품 북극성** — Fact index + Sanctum vault |
| 1 | [../ROADMAP.md](../ROADMAP.md) | 출시 경로·마일스톤·병행 트랙 |
| 2 | [project-status-snapshot.md](project-status-snapshot.md) | Gate·Registry·프로그램 **운영 SSOT** |
| 3 | [sprint-05-charter.md](sprint-05-charter.md) | **현재 Sprint** — M2 Steam Launch |

---

## 1. 활성 프로세스

| 문서 | 상태 |
|------|------|
| [project-status-snapshot.md](project-status-snapshot.md) | 운영 기준선 @430 |
| [a5-scale-plan.md](a5-scale-plan.md) | A5 Scale — SD2.6 **hold** |
| [a5-scale-observation-log.md](a5-scale-observation-log.md) | 관측 일지 — O3 checkpoint **2026-07-09** |
| [a5-scale-operational-decisions.md](a5-scale-operational-decisions.md) | SD1~SD4 운영 수치 |
| [a5-scale-expansion-cohort-plan.md](a5-scale-expansion-cohort-plan.md) | Expansion cohort 전략 |
| [sprint-05-charter.md](sprint-05-charter.md) | **Sprint 05** — M2 Steam Launch + v1 Polish |
| [m2-steam-store-page.md](m2-steam-store-page.md) | Steam 스토어 copy·스크린샷·IAP 가이드 |
| [sprint-05-candidate-backlog.md](sprint-05-candidate-backlog.md) | Sprint 05 후보 백로그 (참고) |

### 운영 도구 (로컬)

| 도구 | 용도 |
|------|------|
| `dart run tool/preflight_check.dart` | 4종 핵심 gate 일괄 |
| `dart run tool/ci_registry_check.dart` | 통합 registry 점검 |
| `dart run tool/a5_scale_hold_observation.dart --apply` | SD2.6 hold 번들 (O8·O9·O12·O7) |
| `dart run tool/a5_scale_o3_checkpoint.dart --apply` | O3 rate 산출 (`--as-of` 지원) |

---

## 2. 정책·규격 (현행)

| 문서 | 범위 |
|------|------|
| [data-policy.md](data-policy.md) | 데이터 필드·provenance **최상위 정책** |
| [product-vision.md](product-vision.md) | 제품·Tier 1/2 **북극성** |
| [akasha-db-policy.md](akasha-db-policy.md) | 사전 구축·포스터·ID 운영 마스터 정책 |
| [discovery-policy.md](discovery-policy.md) | Discovery ≠ Mirroring · 수집 경계 |
| [catalog-ownership.md](catalog-ownership.md) | Tier 0~2 소유·추가 경로 |
| [canonicalization-policy.md](canonicalization-policy.md) | identity·dedupe·canonical 규칙 |
| [locale-catalog-policy.md](locale-catalog-policy.md) | titles·aliases·검색 로케일 계약 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | `titles.en` 품질 게이트 |
| [coverage-quality-governance.md](coverage-quality-governance.md) | Coverage vs Quality KPI·게이트 지도 |
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | externalId attach E1~E5 규칙 |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Coverage KPI 정의 |
| [expansion-tool-grading.md](expansion-tool-grading.md) | insert 도구 A/B/D 등급 |

---

## 3. 제품·출시 (Steam v1)

| 문서 | 내용 |
|------|------|
| [my-library-design.md](my-library-design.md) | 나의 서재 UI 설계 (v1 구현 완료·잔여 UX) |
| [commerce-boundary.md](commerce-boundary.md) | Steam IAP vs 제휴 커머스 경계 |
| [archive/catalog-expansion-plan.md](archive/catalog-expansion-plan.md) | v1 엄선 확장 (**완료·역사**) |
| [v4-migration-plan.md](v4-migration-plan.md) | v4 마이그레이션 Phase A~E (**완료**) |
| [akasha-db-implementation-plan.md](akasha-db-implementation-plan.md) | 사전 CI·앱 구현 체크리스트 |
| [data-architecture-redesign.md](data-architecture-redesign.md) | 데이터 아키텍처 장기 비전 |

---

## 4. 전략·성장 (Steam 후)

| 문서 | 내용 |
|------|------|
| [registry-growth-strategy.md](registry-growth-strategy.md) | 430 → 5M+ 성장 단계 **상위 전략** |
| [contribution-model-strategy.md](contribution-model-strategy.md) | 기여 모델 진화 |
| [catalog-contribution-roadmap.md](catalog-contribution-roadmap.md) | Contribution vs Expansion 파이프라인 |
| [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) | 5k 확장 리스크 Top 3 |
| [registry-scaling-review.md](registry-scaling-review.md) | 1M 구조 병목 분석 |

---

## 5. 검증 (Validation)

| 문서 | 내용 | 상태 |
|------|------|:----:|
| [baseline-v1.md](baseline-v1.md) | Phase 1 검증 고정 세트 (ADR·SW1·URV) | **고정** |
| [assumption-register.md](assumption-register.md) | A1~A6 가정 인벤토리 | 참조 |
| [universal-registry-validation.md](universal-registry-validation.md) | URV 정체성·dedupe 검증 축 | URV-A ✅ |
| [global-search-validation-plan.md](global-search-validation-plan.md) | SW1 recall 검증 계획 | SW1-A ✅ |
| [global-search-query-set.md](global-search-query-set.md) | SW1 쿼리 스위트 95건 | 참조 |
| [search-index-validation-plan.md](search-index-validation-plan.md) | synthetic 10k~1M 실측 | ✅ |
| [search-index-architecture-options.md](search-index-architecture-options.md) | 인덱스 교체 후보 비교 | 참조 |
| [search-workload-profile.md](search-workload-profile.md) | 검색 workload 가정 v0 | 참조 |
| [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) | search_index 첫 병목 실측 | ✅ |

---

## 6. 프로그램 기록 (완결 — 결과·정의만 잔류)

### Phase 2 — Coverage (COMPLETE)

| 문서 | 내용 |
|------|------|
| [phase2-summary.md](phase2-summary.md) | 5분 요약 (진입점) |
| [phase2-charter.md](phase2-charter.md) | Charter·KPI 정의 |
| [phase2-governance-review.md](phase2-governance-review.md) | 거버넌스 장치 지도 |

### Sprint 04 — externalId G2 (**달성** · 2026-06-10)

| 문서 | 내용 |
|------|------|
| [sprint-04-e1-resolution.md](sprint-04-e1-resolution.md) | **최종 결과** — E1 15건 resolution · G2 **50.00%** |
| [sprint-04-charter.md](sprint-04-charter.md) | 정의 (R1/R2 레이어) |
| [sprint-04-baseline-report.md](sprint-04-baseline-report.md) | @430 Phase A baseline |
| [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md) | 문서 SSOT 계층 정리 |
| [externalid-economics-plan.md](archive/externalid-economics-plan.md) | Economics 계획 (**역사** — @402 시점) |
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | 품질 리스크 검토 |
| [rule-id-collision-analysis.md](rule-id-collision-analysis.md) | Rule ID namespace 분석 (Sprint 05 EG 후보 입력) |

### A5 — 검증 프레임 (Pilot 동결 · Scale 활성)

| 문서 | 내용 |
|------|------|
| [a5-verification-charter.md](a5-verification-charter.md) | 관측·판정 방법론 |
| [a5-pilot-charter.md](a5-pilot-charter.md) | Pilot 범위 정의 |
| [a5-gate-review.md](a5-gate-review.md) | H1~H5 Gate 정의 |
| [a5-hypothesis-map.md](a5-hypothesis-map.md) | O1~O14 → H1~H5 가설 구조 |
| [a5-question-register.md](a5-question-register.md) | Open Question 등록부 |

---

## 7. ADR

[adr/README.md](adr/README.md) — ADR-001 (Dual-layer ✅) · 002 (음악, 미결) · 003~006 (단위·수집·프랜차이즈)

---

## 8. Archive

완료 프로그램의 과정 기록(리뷰·관측 로그·감사 체인) **23건** — [archive/README.md](archive/README.md)
