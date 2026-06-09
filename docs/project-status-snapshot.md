# Project Status Snapshot

> **생성:** 2026-06-09  
> **목적:** Phase 0 정리·점검 기준선 — Registry · Gate · Git · 프로그램 상태  
> **다음:** [expansion-tool-grading.md](expansion-tool-grading.md) · [a5-scale-observation-log.md](a5-scale-observation-log.md)

---

## Executive Summary

| 항목 | 상태 |
|------|------|
| **Registry** | **430 works** · 351 v4 hex shards · dedupe **0** |
| **4종 핵심 Gate** | **전부 PASS** |
| **ci_registry_check** | **PASS** (전 단계) |
| **프로그램** | Phase 2 **COMPLETE** · A5 Pilot **SUCCESS** · Scale **SD2.6 도달** · O8–O12 **1차** |
| **Git** | `main` ahead **9+** · 작업 트리 **커밋 대기** (Scale 7–11) |
| **Scale 차단** | **SD2.6 hold** — insert 중단 · O3 checkpoint **2026-07-09** |

---

## 1. Gate 실행 결과 (@430)

| 도구 | 결과 | 비고 |
|------|:----:|------|
| `registry_builder` | **PASS** | 430 works · 351 shards |
| `dedupe_linter` | **PASS** | 0 duplicate · franchise_groups OK |
| `quality_gate --strict` | **PASS** | invalid_en **0** · source_breakage **0** |
| `coverage_dashboard` | **PASS**† | titles_en **92.09%** ≥0.9 |
| `sw1_a_validation` | **PASS** | recall@10 **1.0** (87/87) |
| `urv_a_validation` | **PASS** | 5축 PASS |
| `franchise_linter` | **PASS** | uncovered cluster **0** |
| `ci_registry_check` | **PASS** | maintainer stub **28건** 예외 |

† Charter KPI: titles_en PASS. external_id **46.74%** · ja/zh 등 Phase 2 Open Question.

### Coverage Dashboard (요약)

| 축 | 값 | status |
|----|-----|:------:|
| titles_en | 396/430 (92.09%) | PASS |
| titles_ja | 126/430 (29.30%) | FAIL |
| external_id | 201/430 (46.74%) | FAIL |
| invalid_en | 0/396 | PASS |
| gap_panel | 16/16 | PASS |

---

## 2. Registry · 샤드 무결성

| 점검 | 결과 |
|------|------|
| v4 hex 샤드 파일 | **351** |
| non-hex (v3) 샤드 | **0** |
| 카테고리 | animation · book · drama · game · manga · movie · webtoon |
| `manifest v4` | 351 shards · **430** works · shardBits=8 |

### Scale @410 누적 insert

| 경로 | net |
|------|----:|
| Maintainer (`a5_scale_supply_batch` b1–6) | **+12** |
| Expansion (`seed_expansion_batch7`) | **+8** |
| **합계** | **+20** → **430** (SD2.6 상한) |

---

## 3. ci_registry_check · 정리 (2026-06-09)

| 조치 | 결과 |
|------|------|
| `allowedExtensionsKeys` + Sprint 03/04 | data_policy **0** error |
| `cleanup_poster_source --apply` | pilot stub posterSource 제거 |
| `id_registry_check` maintainer stub 예외 | `sub_*` **28건** 스킵 |
| `preflight_check.dart` | 4종 gate 일괄 래퍼 |
| O8·O9·O12 관측 도구 | SD4 확정 · Scale 10–11 기록 |

**현재:** `ci_registry_check` **전 단계 PASS**.

---

## 4. Git 인벤토리

| 구분 | 건수 (커밋 전) |
|------|---------------:|
| **전체** | **27** |
| modified (`M`) | 15 |
| untracked (`??`) | 12 |

| 경로 | 비고 |
|------|------|
| `akasha-db/` | batch7 · supply b4–6 shards · manifest/index |
| `tool/` | batch7 · supply/enrich b4–8 · O8/O9/O12 관측 3종 |
| `docs/` | observation log · SD4 · grading · snapshot |

**브랜치:** `main` — **ahead 9** (미 push) + 본 세션 커밋 예정

---

## 5. 프로그램 · 문서 타임라인

| 단계 | 상태 | 대표 문서 |
|------|:----:|-----------|
| Phase 1 | **동결** | `phase1-final-review.md` |
| Phase 2 | **COMPLETE** | `phase2-summary.md` · `phase2-final-review.md` |
| A5 Discovery | **닫힘** | `a5-discovery-charter.md` |
| A5 Pilot | **SUCCESS · 동결** | `a5-pilot-final-review.md` |
| A5 Scale | **진행** | `a5-scale-plan.md` · `a5-scale-observation-log.md` |
| SD1~SD4 | **확정** | O3 checkpoint **2026-07-09** |
| Assumption A5 | **Deferred** | S1·S3·S4 Scale 확정 대기 |

---

## 6. 위험 · 알려진 이슈

| # | 이슈 | 심각도 | Scale 영향 |
|---|------|:------:|:----------:|
| R1 | 미커밋·미 push | 중 | 이력·재현성 — **본 세션 정리 중** |
| R2 | **batch3/4/seed_expansion** v3·gate 없음 | **높** | 실행 금지 — [expansion-tool-grading.md](expansion-tool-grading.md) |
| R3 | maintainer `sub_*` **28건** (wk_ 미할당) | 낮 | ci 예외 · 장기 wk_ 할당 검토 |
| R4 | **CI/GitHub Actions 없음** | 중 | `preflight_check`로 부분 완화 |
| R5 | Expansion batch5/6 **Net-new 0** | 정보 | batch7 A유형으로 **해소** |

---

## 7. 다음 권장 작업

| 순서 | 상태 | 작업 |
|:----:|:----:|------|
| 1 | **진행** | Git 커밋 · push (Scale 7–11) |
| 2 | **done** | `project-status-snapshot` @430 갱신 |
| 3 | **done** | `docs/README` SD4·도구 인덱스 |
| 4 | **hold** | SD2.6 — insert 중단 → **2026-07-09** |
| 5 | **next** | O3 checkpoint · Maintainer rate vs G2 |
| 6 | **next** | 5k 마일스톤 — O12·O8 재관측 |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 스냅샷 — gate · Git · 위험 |
| 2026-06-09 | Scale 2–5 (412→416) · ci 정리 |
| 2026-06-09 | Scale 7–11: batch7 + supply b4–6 → **430** · O8–O12 · SD4 |
