# AKASHA Docs Index

> **갱신:** 2026-06-09 · [project-status-snapshot.md](project-status-snapshot.md) 참고 · Registry **430 works**

---

## 읽는 순서

| 순서 | 문서 | 상태 |
|:----:|------|:----:|
| 1 | [phase2-summary.md](phase2-summary.md) | COMPLETE |
| 2 | [a5-pilot-final-review.md](a5-pilot-final-review.md) | **동결** |
| 3 | [a5-scale-plan.md](a5-scale-plan.md) | **활성** |
| 4 | [a5-scale-observation-log.md](a5-scale-observation-log.md) | **활성** |

---

## 프로그램별

### Phase 2 (동결)

- [phase2-final-review.md](phase2-final-review.md)
- [quality-gate-mvp.md](quality-gate-mvp.md)
- [sprint-04-final-review.md](sprint-04-final-review.md)

### A5 Discovery · Pilot (동결)

- [a5-discovery-charter.md](a5-discovery-charter.md)
- [a5-gate-review.md](a5-gate-review.md)
- [a5-question-register.md](a5-question-register.md)
- [a5-pilot-observation-log.md](a5-pilot-observation-log.md)
- [a5-pilot-gate-decision-record.md](a5-pilot-gate-decision-record.md)

### A5 Scale (활성)

- [a5-scale-plan.md](a5-scale-plan.md)
- [a5-scale-observation-log.md](a5-scale-observation-log.md)
- [a5-scale-operational-decisions.md](a5-scale-operational-decisions.md) — SD1~**SD4**
- [a5-scale-expansion-cohort-plan.md](a5-scale-expansion-cohort-plan.md)

---

## 운영 · 점검

| 문서 / 도구 | 용도 |
|-------------|------|
| [project-status-snapshot.md](project-status-snapshot.md) | Gate · Git · 위험 **기준선** (@430) |
| [expansion-tool-grading.md](expansion-tool-grading.md) | insert 도구 A/B/D 등급 |
| `dart run tool/preflight_check.dart` | 4종 gate 일괄 (로컬) |
| `dart run tool/ci_registry_check.dart` | 통합 registry 점검 |
| `dart run tool/a5_scale_governance_observation.dart --apply` | **O8** governance 번들 wall |
| `dart run tool/a5_scale_semantic_spotcheck.dart --apply` | **O9** semantic cohort 20 |
| `dart run tool/a5_scale_franchise_queue.dart --apply` | **O12** franchise 큐 스냅샷 |
| `dart run tool/a5_scale_hold_observation.dart --apply` | SD2.6 hold 번들 (O8·O9·O12·O7) |
| `dart run tool/a5_scale_o3_checkpoint.dart --apply` | **O3** rate 산출 (`--as-of` 지원) |
| [akasha-db-policy.md](akasha-db-policy.md) | 데이터 정책 |
| [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) | 5k/50k 리스크 |

---

## ADR

[adr/README.md](adr/README.md)
