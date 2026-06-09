# Expansion Tool Grading — insert 경로 등급

> **목적:** Registry insert 도구의 **운영 등급** — Scale/Pilot에서 **허용·금지** 명확화  
> **기준일:** 2026-06-09 · Registry **410 works**

---

## 등급 요약

| 등급 | 의미 | apply |
|:----:|------|:-----:|
| **A** | gate + v4 hex · dry-run 또는 BLOCK 선행 | **허용** |
| **B** | 읽기·감사·enrich 전용 | **해당 없음** |
| **D** | v3 샤드 또는 gate 없음 · **항상 쓰기** | **금지** |

---

## A급 — Scale/Pilot insert 허용

| 도구 | gate | v4 hex | dry-run | 비고 |
|------|:----:|:------:|:-------:|------|
| `pre_insert_dedupe_gate.dart` | — | — | — | 선행 검사 라이브러리 |
| `seed_expansion_batch5.dart` | **예** | **예** | implicit | `--max-add` · cohort 45 (현재 **전부 BLOCK**) |
| `seed_expansion_batch6.dart` | **예** | **예** | implicit | `--max-add` · cohort 40 (현재 **전부 BLOCK**) |
| `a5_pilot_supply_batch.dart` | **예** | **예** | `--apply` 없으면 WOULD_ADD | Pilot Maintainer 소량 |
| `a5_scale_supply_batch.dart` | **예** | **예** | `--apply` 없으면 WOULD_ADD | Scale Net-new anchor |

**배치 후 필수:** `registry_builder` · `quality_gate --strict` · `dedupe_linter` · `coverage_dashboard`

---

## B급 — insert 아님

| 도구 | 용도 |
|------|------|
| `registry_builder.dart` | manifest · search_index 재생성 |
| `dedupe_linter.dart` | 중복 후보 |
| `quality_gate.dart` | 품질 KPI |
| `coverage_dashboard.dart` | Coverage KPI |
| `coverage_sprint_*` | enrich 배치 |
| `ci_registry_check.dart` | 통합 점검 |
| `franchise_linter.dart` | franchise 큐 |
| `sw1_a_validation.dart` · `urv_a_validation.dart` | 회귀 |
| `a5_scale_enrich_batch.dart` | Scale 소량 enrich (O6·O7) |
| `coverage_sprint_02_economics.dart` | registry-wide Economics (O6) |

---

## D급 — insert 금지

> **이유:** v3 샤드 경로(`animation_A.json` 등) 또는 gate 없음 · 실행 시 **registry_builder FAIL** · dedupe 오염 위험

| 도구 | 문제 |
|------|------|
| `seed_expansion.dart` | v3 · gate 없음 · **항상 쓰기** |
| `seed_expansion_batch3.dart` | v3 · gate 없음 · **항상 쓰기** |
| `seed_expansion_batch4.dart` | v3 · gate 없음 · **항상 쓰기** |

**Scale Plan §3.5 · Pilot batch6 롤백 사례와 동일 리스크.**

---

## cohort 현황 (@410)

| cohort | seeds | ADD | BLOCK | 유형 |
|--------|------:|----:|------:|------|
| batch6 | 40 | 0 | 40 | legacyIds→wk_ |
| batch5 | 45 | 0 | 45 | legacyIds→wk_ |

Net-new insert는 **A급 Maintainer** 또는 **신규 A유형 cohort** 필요.

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 1 초안 — A/B/D 등급 |
