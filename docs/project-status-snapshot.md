# Project Status Snapshot

> **생성:** 2026-06-09  
> **목적:** Phase 0 정리·점검 기준선 — Registry · Gate · Git · 프로그램 상태  
> **다음:** [expansion-tool-grading.md](expansion-tool-grading.md) · Phase 2 Git 분류

---

## Executive Summary

| 항목 | 상태 |
|------|------|
| **Registry** | **412 works** · 339 v4 hex shards · dedupe **0** |
| **4종 핵심 Gate** | **전부 PASS** |
| **ci_registry_check** | **PASS** (전 단계) |
| **프로그램** | Phase 2 **COMPLETE** · A5 Pilot **SUCCESS** · Scale **1차 관측** |
| **Git** | `main` ahead **5** · 작업 트리 **162건** (미커밋) |
| **Scale 차단** | **없음** |

---

## 1. Gate 실행 결과 (@412)

| 도구 | 결과 | 비고 |
|------|:----:|------|
| `registry_builder` | **PASS** | 410 works · 337 shards |
| `dedupe_linter` | **PASS** | 0 duplicate · franchise_groups OK |
| `quality_gate --strict` | **PASS** | invalid_en **0** · source_breakage **0** |
| `coverage_dashboard` | **PASS**† | titles_en **91.71%** ≥0.9 |
| `sw1_a_validation` | **PASS** | recall@10 **1.0** (87/87) |
| `urv_a_validation` | **PASS** | 5축 PASS · exactId **201/201** |
| `franchise_linter` | **PASS** | uncovered cluster 없음 |
| `ci_registry_check` | **PASS** | §3 정리 완료 |

† Charter KPI 기준: titles_en PASS. external_id **49.02%** · zh/ja 등은 Phase 2 Open Question (변화 없음).

### Coverage Dashboard (요약)

| 축 | 값 | status |
|----|-----|:------:|
| titles_en | 376/410 (91.71%) | PASS |
| external_id | 201/410 (49.02%) | FAIL |
| invalid_en | 0 | PASS |
| gap_panel | 16/16 | PASS |

---

## 2. Registry · 샤드 무결성

| 점검 | 결과 |
|------|------|
| v4 hex 샤드 파일 | **337** |
| non-hex (v3) 샤드 | **0** |
| 카테고리 | animation · book · drama · game · manga · movie · webtoon |
| `manifest v4` | 337 shards · 410 works · shardBits=8 |

### Pilot/Scale로 추가된 작품 (의도된 변경)

| workId | shard | 출처 |
|--------|-------|------|
| `sub_animation_pilot-h2-smoke-alpha_2026` | `animation/6d.json` | H2 smoke |
| `sub_book_pilot-h2-smoke-beta_2026` | `book/9b.json` | H2 smoke |
| `sub_game_pilot-h1-supply-b1a_2026` | `game/c7.json` | H1 batch 1 |
| `sub_movie_pilot-h1-supply-b1b_2026` | `movie/23.json` | H1 batch 1 |
| `sub_drama_pilot-h1-supply-b2a_2026` | `drama/6b.json` | H1 batch 2 |
| `sub_book_pilot-h1-supply-b2b_2026` | `book/e2.json` | H1 batch 2 |
| `sub_animation_pilot-h1-supply-b3a_2026` | `animation/4e.json` | H1 batch 3 (기존 샤드) |
| `sub_manga_pilot-h1-supply-b3b_2026` | `manga/93.json` | H1 batch 3 (기존 샤드) |

**신규 hex 파일 (untracked):** 6건 (`6d` · `9b` · `e2` · `6b` · `c7` · `23`)

---

## 3. ci_registry_check · 정리 (2026-06-09)

| 조치 | 결과 |
|------|------|
| `allowedExtensionsKeys` + Sprint 03/04 | data_policy **417 → 0** |
| `cleanup_poster_source --apply` | pilot stub posterSource **8건** 제거 |
| `id_registry_check` maintainer stub 예외 | pilot/scale `sub_*` **10건** 스킵 |
| `preflight_check.dart` | 4종 gate 일괄 래퍼 |

**현재:** `ci_registry_check` **전 단계 PASS**.

---

## 4. Git 인벤토리

| 구분 | 건수 |
|------|-----:|
| **전체** | 162 |
| modified (`M`) | 125 |
| untracked (`??`) | 37 |

| 경로 | 건수 | 비고 |
|------|-----:|------|
| `akasha-db/` | 126 | manifest · search_index · shards |
| `docs/` (untracked) | 26 | A5 전체 · Phase 2 late · Sprint 04 |
| `tool/` | 9 | gate · expansion · coverage |

**브랜치:** `main` @ `6d34742` — **ahead 5** (미 push)

### 커밋 후보 (Phase 2 분류용)

| 묶음 | 포함 |
|------|------|
| **C1** | A5 Pilot + Scale docs (15) |
| **C2** | Phase 2 late docs + Sprint 04 (11) |
| **C3** | tool: gate · expansion · coverage |
| **C4** | akasha-db: registry 410 |

---

## 5. 프로그램 · 문서 타임라인

| 단계 | 상태 | 대표 문서 |
|------|:----:|-----------|
| Phase 1 | **동결** | `phase1-final-review.md` |
| Phase 2 | **COMPLETE** | `phase2-summary.md` · `phase2-final-review.md` |
| A5 Discovery | **닫힘** | `a5-discovery-charter.md` |
| A5 Pilot | **SUCCESS · 동결** | `a5-pilot-final-review.md` |
| A5 Scale | **진행** | `a5-scale-plan.md` · `a5-scale-observation-log.md` |
| SD1~SD3 | **미정** | Scale 1차에는 **불필요** |

---

## 6. 위험 · 알려진 이슈

| # | 이슈 | 심각도 | Scale 영향 |
|---|------|:------:|:----------:|
| R1 | **162건 미커밋** | 중 | 이력·재현성 |
| R2 | **batch3/4/seed_expansion** v3·gate 없음 | **높** | 잘못 실행 시 v3 오염 — [expansion-tool-grading.md](expansion-tool-grading.md) |
| R3 | Expansion batch5/6 **Net-new 0** | 중 | insert는 Maintainer·신규 cohort 필요 |
| R4 | maintainer `sub_*` **10건** (wk_ 미할당) | 낮 | ci **예외 처리** · 장기 wk_ 할당 검토 |
| R5 | **CI/GitHub Actions 없음** | 중 | `preflight_check`로 부분 완화 |
| R6 | remote **ahead 5** · **~170건** 미커밋 | 낮 | push·커밋 시점 미정 |

---

## 7. 다음 권장 작업

| 순서 | Phase | 작업 |
|:----:|-------|------|
| 1 | **2** | Git 커밋 묶음(C1~C4) 확정 — **요청 시** 실행 |
| 2 | **3** | `docs/README.md` 인덱스 |
| 3 | **4** | Scale 2차: Net-new insert 경로 결정 |
| 4 | **2** | Git 커밋 묶음(C1~C4) — **요청 시** |
| 5 | **4** | Scale enrich 병행 (O7·O6) |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 스냅샷 — gate 일괄 · Git · 위험 목록 |
| 2026-06-09 | ci 정리 · Scale 2 Net-new +2 (412작) |
