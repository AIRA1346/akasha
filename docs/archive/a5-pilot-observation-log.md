# A5 Pilot Observation Log

> **기간:** 2026-06-09 (단일 세션)  
> **Baseline:** 402작 · **Pilot 1차:** 405작 · **H2 Remediation 후:** 407작 · **Duplicate 정리 후:** 404작 · **H1 반복 공급 후:** 410작  
> **경로:** Maintainer v4 insert (`a5_pilot_supply_batch`) · PreInsertDedupeGate · Expansion `seed_expansion_batch6` 시도

---

## 세션 맥락 (E0)

| 필드 | 값 |
|------|-----|
| 시작 | 2026-06-09T17:54:11+09:00 |
| add(B) | **미개방** |
| insert 경로 | (1) Expansion batch6 (2) Maintainer v4 hash shard 수동 3작 |
| 증거 | `manifest.json` · `coverage_snapshot.json` · `sw1_a_report.json` · `urv_a_report.json` · `dedupe_linter` stdout |

---

## O1 — G1 insert rate

| 관측 | 결과 |
|------|------|
| Pilot 세션 net insert | **+3** (402→405) |
| 경로 | Maintainer **수동** v4 (`animation/fc`, `93`, `f3`) |
| Expansion batch6 `--apply` | **+40 시도** → v3 샤드 경로 · `registry_builder` **실패** → **롤백** (v3 파일 삭제) |
| Git 이력 (참고) | 2026-06-06~09 다수 배치 커밋 (batch3·batch6·Sprint·v4 마이그레이션) |

---

## O2 — G1 wall·SIM-A

| 관측 | 결과 |
|------|------|
| Pilot insert wall | 단일 세션 · 3작 수동 반영 |
| SIM-A 대비 | Phase 1 합성 throughput **별도 extrapolation 미실시** (Pilot 범위 외) |

---

## O4 — pre-insert dedupe

| 시점 | works | 결과 |
|------|------:|------|
| insert **전** | 402 | **0** duplicate candidates |
| insert **후** (3작) | 405 | **3** fuzzyTitle candidates |

**후보 (fuzzyTitle):**

| 신규 sub_ | 기존 wk_ |
|-----------|----------|
| `sub_animation_jojo-bizarre-adventure_2012` | `wk_000000203` |
| `sub_animation_hunter-x-hunter_2011` | `wk_000000202` |
| `sub_animation_naruto_2002` | `wk_000000218` |

---

## O5 — Coverage 희석

| 축 | 402 | 405 | Δ |
|----|-----|-----|---|
| titles_en | 368/402 (91.54%) | 371/405 (**91.60%**) | **+0.06pp** · dashboard **PASS** |
| external_id | 201/402 (50.0%) | 201/405 (**49.63%**) | **-0.37pp** · dashboard **FAIL** vs 0.9 |

---

## O7 — backlog vs insert

| 관측 | 결과 |
|------|------|
| enrich backlog | Pilot 세션 **enrich 배치 미실행** — stub 3작 titles.en **이미 포함** |
| insert:enrich | **동시 부하 미관측** · O7 **미결** |

---

## O8 · O9 — Quality·Governance

| 도구 | 결과 |
|------|------|
| `quality_gate --strict` | **PASS** · invalid_en **0** · source_breakage **0** |
| semantic spot-check | **미실시** (O9 샘플 미집행) |

---

## O10 — SW1/URV

| 도구 | recall / 수렴 |
|------|----------------|
| SW1 | recall@10 **1.0** (87쿼리) |
| URV | 5축 **PASS** (exactId 201/201) |

---

## O11 · O13 — Platform (H5)

| 항목 | 402 추정 | 405 실측 |
|------|----------|----------|
| `registry_builder` wall | — | **1873 ms** |
| `search_index.json` size | — | **298,034 bytes** |
| shards | 330 | **333** |

---

## O14 — add 없이 G2 경로

| 관측 | 결과 |
|------|------|
| Contribution add | **미개방** |
| Expansion 파이프라인 | cohort **40건** dry-run 가능 · v4 **apply 불가** (도구·샤드 불일치) |
| Maintainer 수동 | v4 hash 경로 **동작** · dedupe **사후** 이슈 |

---

## Expansion batch6 시도 (H1·H2)

| 단계 | 결과 |
|------|------|
| dry-run | 40 added, 0 skipped |
| `--apply` | v3 파일 30개 생성 (`animation_B.json` 등) |
| `registry_builder` | **30 validation errors** (v4 hex 아님) |
| 조치 | v3 파일 **삭제** · registry **402 유지** |

---

## H2 Remediation (2026-06-09)

### 1. insert 전 검사 — `tool/pre_insert_dedupe_gate.dart`

| 신호 | 검사 내용 |
|------|-----------|
| **workId** | registry `byWorkId` 충돌 |
| **legacyIds** | 후보 `workId`가 기존 `legacyIds`에 등록됨 · 후보 legacy 중복 |
| **fuzzyTitle** | `dedupe_linter`와 동일 정규화·category·releaseYear±1 |

**연동:** `seed_expansion_batch5.dart` · `seed_expansion_batch6.dart` — apply **전** gate 호출.

### 2. Expansion → v4 경로

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 샤드 경로 | `{category}_{Letter}.json` (v3) | `{category}/{hex}.json` (`shardHexForWorkId`) |
| `registry_builder` | batch6 apply 시 **30 errors** | smoke 후 **OK** |

### 3. batch6·batch5 gate dry-run (@405작)

| cohort | added | skipped | blocked |
|--------|------:|--------:|--------:|
| batch6 (40) | 0 | 3 (pilot sub_) | **37** (legacyIds→wk_) |
| batch5 (45) | 0 | 0 | **45** (legacyIds→wk_) |

→ Expansion cohort는 **wk_ legacy 보유**로 sub_ 재insert **전부 차단** (의도된 동작).

### 4. 소규모 insert 재시험 (gate 통과)

| workId | shard | gate |
|--------|-------|------|
| `sub_animation_pilot-h2-smoke-alpha_2026` | `animation/6d.json` | **PASS** |
| `sub_book_pilot-h2-smoke-beta_2026` | `book/9b.json` | **PASS** |

| 시점 | works | duplicate candidates |
|------|------:|---------------------:|
| smoke **전** | 405 | **3** (기존 pilot sub_ — **미정리**) |
| smoke **후** | **407** | **3** (**신규 0**) |

**결론:** 새 insert **2건** — dedupe 후보 **증가 없음**.

---

## Duplicate 정리 (2026-06-09, 승인 실행)

[a5-duplicate-resolution-review.md](a5-duplicate-resolution-review.md) 권장대로 **sub_ 제거** · **wk_ 유지**.

| sub_ 제거 | shard 조치 | survivor wk_ |
|-----------|------------|--------------|
| `sub_animation_jojo-bizarre-adventure_2012` | `animation/fc.json` **삭제** | `wk_000000203` |
| `sub_animation_hunter-x-hunter_2011` | `animation/93.json` 키 삭제 | `wk_000000202` |
| `sub_animation_naruto_2002` | `animation/f3.json` **삭제** | `wk_000000218` |

| 검증 | 정리 전 | 정리 후 |
|------|--------:|--------:|
| works | 407 | **404** |
| fuzzyTitle duplicate | 3 | **0** |
| `registry_builder` | — | **PASS** (404 works) |
| `quality_gate --strict` | — | **PASS** · invalid_en **0** |
| `dedupe_linter` | 3 candidates | **No duplicate candidates found** |

**유지:** smoke test 2작 (`pilot-h2-smoke-alpha/beta`) · wk_ canonical 3작 · `legacyIds` on wk_ **변경 없음**.

---

## H1 반복 공급 관측 (2026-06-09)

**목표:** 공급 경로가 일회성이 아니라 **반복 가능**함을 확인.

**원칙:** Maintainer 경로 · `pre_insert_dedupe_gate` · 소규모 insert(배치당 2작) · 배치마다 동일 검증.

**도구:** `tool/a5_pilot_supply_batch.dart` (`--batch 1|2|3 --apply`)

| 배치 | workId | shard | gate | 검증 |
|:----:|--------|-------|:----:|------|
| 1 | `sub_game_pilot-h1-supply-b1a_2026` | `game/c7.json` | PASS | PASS |
| 1 | `sub_movie_pilot-h1-supply-b1b_2026` | `movie/23.json` | PASS | PASS |
| 2 | `sub_drama_pilot-h1-supply-b2a_2026` | `drama/6b.json` | PASS | PASS |
| 2 | `sub_book_pilot-h1-supply-b2b_2026` | `book/e2.json` | PASS | PASS |
| 3 | `sub_animation_pilot-h1-supply-b3a_2026` | `animation/4e.json` | PASS | PASS |
| 3 | `sub_manga_pilot-h1-supply-b3b_2026` | `manga/93.json` | PASS | PASS |

| 시점 | works | blocked | duplicate | registry_builder | quality_gate | dashboard |
|------|------:|--------:|----------:|:----------------:|:------------:|:---------:|
| 시작 (duplicate 정리 후) | 404 | — | 0 | PASS | PASS | titles_en PASS |
| batch 1 후 | 406 | 0 | 0 | PASS | PASS | titles_en PASS |
| batch 2 후 | 408 | 0 | 0 | PASS | PASS | titles_en PASS |
| batch 3 후 | **410** | 0 | 0 | PASS | PASS | titles_en **91.71%** PASS |

**누적:** net **+6** (404→410) · 3회 연속 insert · **0 blocked** · dedupe **0 유지**.

**Coverage (410작):**

| 축 | 값 | status |
|----|-----|--------|
| titles_en | 376/410 (**91.71%**) | PASS |
| external_id | 201/410 (**49.02%**) | FAIL (baseline cohort 동일) |
| invalid_en | 0 | PASS |

**결론 (O1·O14):** Maintainer + gate + v4 hex 경로로 **소규모 배치 3회 반복 insert 성공** — 각 배치 후 `registry_builder` · `quality_gate --strict` · `dedupe_linter` · Coverage Dashboard **전부 PASS** (external_id 희석은 기존과 동일 패턴).

---

## 미관측 (Pilot 범위·시간)

| ID | 사유 |
|----|------|
| O3 | Scale 이관 |
| O6 | Economics runner 미실행 |
| O9 | semantic 샘플 미집행 |
| O12 | franchise 큐 미집계 |
