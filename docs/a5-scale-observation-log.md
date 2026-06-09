# A5 Scale Observation Log

> **기간:** 2026-06-09 (Scale 1차 관측)  
> **Baseline:** **410작** (Pilot 종료 · [a5-pilot-final-review.md](a5-pilot-final-review.md) 확정)  
> **경로:** Expansion `seed_expansion_batch5/6` · `pre_insert_dedupe_gate` · v4 hex shard

---

## 세션 맥락 (E0)

| 필드 | 값 |
|------|-----|
| 시작 | 2026-06-09 Scale 1차 |
| Pilot 문서 | **동결** — 재판정 없음 |
| SD1~SD3 | **미확정** — 1차 관측 **착수에 불필요** (본 세션) |
| insert 경로 | Expansion batch5 · batch6 (gate 연동) |

---

## Scale 1 — Expansion cohort 전수 dry-run (@410)

**목적:** Scale Plan §3.2 **1단계** — cohort ADD / BLOCK / SKIP 집계.

| cohort | seeds | ADD | SKIP | BLOCK | 유형 |
|--------|------:|----:|-----:|------:|------|
| batch6 | 40 | 0 | 0 | **40** | **전부 B** (legacyIds→wk_) |
| batch5 | 45 | 0 | 0 | **45** | **전부 B** (legacyIds→wk_) |
| **합계** | **85** | **0** | **0** | **85** | Net-new **0** |

**BLOCK 신호:** 전건 `[legacyIds]` — 기존 wk_에 sub_ workId가 legacy로 등록됨.

**결론:** 현재 Expansion cohort (batch5·6)는 **재insert 불가** — Scale Plan §3.2 **5단계**(Legacy 별도 트랙)로만 처리. Net-new apply **대상 없음**.

---

## Scale 1 — Expansion apply 시험 (`--max-add 2`)

| 항목 | 결과 |
|------|------|
| 명령 | `seed_expansion_batch6.dart --apply --max-add 2` |
| added | **0** |
| blocked | **40** (gate 선행 차단) |
| registry Δ | **0** (410 유지) |

**Gate 기록:** BLOCK 로그 **40건** — apply **미반영** (의도된 동작).

---

## Scale 1 — 배치 후 검증

| 도구 | 결과 |
|------|------|
| `registry_builder` | **PASS** — 410 works · 337 shards |
| `dedupe_linter` | **0** duplicate candidates |
| `quality_gate --strict` | **PASS** |
| `coverage_dashboard` | titles_en **91.71%** PASS |

---

## Scale 1 — 운영 발견

| # | 발견 | Scale 함의 |
|---|------|------------|
| F1 | batch5·6 cohort **Net-new 0** | Expansion **신규 insert**는 **새 cohort** 또는 Maintainer anchor **필요** |
| F2 | batch3·4 도구는 gate·v4 hex **미연동** · dry-run **없음** | Scale apply **금지** (Scale Plan §3.5) |
| F3 | gate + batch5/6 경로 **정상** | Legacy-blocked cohort **일괄 유입 차단** 재확인 |

---

## 미관측 (본 세션)

| ID | 사유 |
|----|------|
| O3 | insert 누적 **없음** — throughput 측정 **후속** |
| O6·O7 | enrich **미실행** |
| O8·O9·O12 | 본 세션 **범위 외** |

---

## Scale 2 — Net-new Maintainer anchor (@410→412)

**목적:** Expansion cohort B유형(legacy BLOCK) 대비 **Net-new insert** 경로 확인.

**도구:** `tool/a5_scale_supply_batch.dart` (`--batch 1 --apply`)

| workId | shard | gate |
|--------|-------|:----:|
| `sub_webtoon_scale-supply-b1a_2026` | `webtoon/48.json` | PASS |
| `sub_game_scale-supply-b1b_2026` | `game/d0.json` | PASS |

| 항목 | 결과 |
|------|------|
| added | **2** · blocked **0** |
| works | 410 → **412** |
| dedupe | **0** |
| `quality_gate --strict` | **PASS** |
| `ci_registry_check` | **PASS** (정리 후) |

**정리 (동일 세션):** `data_policy` allowlist · pilot `posterSource` cleanup · `id_registry` stub 예외 · `preflight_check.dart` 추가.

---

## Scale 3 — enrich 병행 (O6 · O7)

**목적:** insert와 enrich **동시 부하** 첫 관측 — Scale Plan O7 · O6.

**도구:** `tool/a5_scale_enrich_batch.dart` (`--batch 1 --apply`)

| workId | enrich | wall |
|--------|--------|------|
| `sub_webtoon_scale-supply-b1a_2026` | titles.**ja** | — |
| `sub_game_scale-supply-b1b_2026` | titles.**ja** | — |

| 항목 | 값 |
|------|-----|
| enriched | **2** |
| wall | **237 ms** |
| estimatedMinutes (O6) | **30** (15 min/work × 2) |
| insert:enrich (동일 세션) | **2:2** (Scale supply batch 1 대비) |
| 산출 | `scale_enrich_b1.json` |

**Economics (@412):** `coverage_sprint_02_economics.dart` — registry-wide 추정 갱신 (`sprint_02_economics.json`).

| 검증 | 결과 |
|------|------|
| `registry_builder` | **PASS** (412) |
| `preflight_check` | **PASS** |
| titles_en | **PASS** 유지 |

**O7 초기 신호:** insert 2 + enrich 2 **동일 세션** — backlog **追越 없음** (stub 2건 ja 보강 완료).

---

## Scale 4 — insert·enrich 반복 (O7 시계열 · O3 누적)

**목적:** Scale supply/enrich **2회차** — insert:enrich 균형·누적 throughput **초기 신호**.

### Supply batch 2

| workId | shard | gate |
|--------|-------|:----:|
| `sub_movie_scale-supply-b2a_2026` | `movie/a1.json` | PASS |
| `sub_drama_scale-supply-b2b_2026` | `drama/65.json` | PASS |

### Enrich batch 2

| workId | enrich |
|--------|--------|
| `sub_movie_scale-supply-b2a_2026` | titles.**ja** |
| `sub_drama_scale-supply-b2b_2026` | titles.**ja** |

| 항목 | batch 1 | batch 2 | **누적 (Scale @410)** |
|------|--------:|--------:|----------------------:|
| insert | +2 | +2 | **+4** → **414** works |
| enrich (ja) | +2 | +2 | **+4** |
| insert:enrich | 2:2 | 2:2 | **4:4** |
| enrich wall | 237 ms | **118 ms** | — |
| blocked | 0 | 0 | 0 |

| 검증 | 결과 |
|------|------|
| `registry_builder` | **PASS** (414 · 341 shards) |
| `preflight_check` | **PASS** |
| dedupe | **0** |

### O3 · O7 신호 (초기)

| ID | 관측 |
|----|------|
| **O3** | Scale Maintainer 경로 **+4 net** (410→414) · 2회 배치 · **측정 가능** — 월간 rate는 **후속** (SD1) |
| **O7** | 2회 연속 **insert:enrich 1:1** · ja backlog on scale stubs **0** · 퇴화 **없음** |

**산출:** `scale_enrich_b2.json` (로컬 artifacts)

---

## Scale 5 — O7 압력 시나리오 (insert 2 · enrich 4)

**목적:** enrich **> insert** 세션 — pilot ja **backlog** 소진 관측.

### Supply batch 3

| workId | shard |
|--------|-------|
| `sub_book_scale-supply-b3a_2026` | `book/de.json` |
| `sub_animation_scale-supply-b3b_2026` | `animation/60.json` |

### Enrich batch 3 (4건)

| workId | 유형 |
|--------|------|
| `sub_book_scale-supply-b3a_2026` | scale stub |
| `sub_animation_scale-supply-b3b_2026` | scale stub |
| `sub_game_pilot-h1-supply-b1a_2026` | **pilot backlog** |
| `sub_movie_pilot-h1-supply-b1b_2026` | **pilot backlog** |

| 항목 | 값 |
|------|-----|
| 세션 insert:enrich | **2:4** |
| works | 414 → **416** |
| enrich wall | **192 ms** |
| estimatedMinutes (O6) | **60** (15×4) |
| pilot ja backlog | **6 → 4** (H1 supply 6건 중 2건 보강) |
| dedupe | **0** |

### O7 · O3 누적 (@410 Scale baseline)

| 항목 | batch 1–2 | batch 3 | **누적** |
|------|----------:|--------:|---------:|
| insert | +4 | +2 | **+6** |
| enrich (ja) | +4 | +4 | **+8** |
| insert:enrich (균형 세션) | 2:2 ×2 | **2:4** | — |

| ID | 신호 |
|----|------|
| **O7** | enrich **> insert** 세션에서도 gate **PASS** · titles_en **91.83%** 유지 · SW1 **1.0** — **Pause 미발동** |
| **O3** | Maintainer **+6 net** (410→416) · 경로 **지속** |

**산출:** `scale_enrich_b3.json`

---

## Scale 6 — enrich-only (pilot ja backlog 소진)

**목적:** insert **없이** enrich만 — O7 backlog **0** 목표.

**도구:** `a5_scale_enrich_batch.dart` `--batch 4 --apply` **[insert-free]**

| workId | enrich |
|--------|--------|
| `sub_drama_pilot-h1-supply-b2a_2026` | titles.ja |
| `sub_book_pilot-h1-supply-b2b_2026` | titles.ja |
| `sub_animation_pilot-h1-supply-b3a_2026` | titles.ja |
| `sub_manga_pilot-h1-supply-b3b_2026` | titles.ja |

| 항목 | 값 |
|------|-----|
| insert | **0** |
| enrich | **4** |
| 세션 insert:enrich | **0:4** |
| pilot ja backlog | **4 → 0** |
| works | **416** (변동 없음) |
| wall | **200 ms** |
| gate | **PASS** |

**O7:** H1 pilot+scale maintainer stub ja backlog **전량 소진** — SD3.5 Pause 조건 **미충족**.

---

## SD1 · Expansion cohort (2026-06-09 확정)

| 문서 | 내용 |
|------|------|
| [a5-scale-operational-decisions.md](a5-scale-operational-decisions.md) | SD1~SD3 수치 |
| [a5-scale-expansion-cohort-plan.md](a5-scale-expansion-cohort-plan.md) | A유형 · batch7 원칙 |

### O3 (SD1 적용)

| 필드 | 값 |
|------|-----|
| Clock 시작 | **2026-06-09** |
| 1차 checkpoint | **2026-07-09** |
| Scale net insert (day 0) | **+6** (410→416) |
| 월 환산 rate | **checkpoint까지 보류** |

---

## Scale 7 — Expansion batch7 A유형 apply

**목적:** [a5-scale-expansion-cohort-plan.md](a5-scale-expansion-cohort-plan.md) — **Net-new** Expansion 경로 **첫 apply**.

**도구:** `seed_expansion_batch7.dart`

| 단계 | 결과 |
|------|------|
| dry-run (8 seeds) | **8 WOULD_ADD** · **0 BLOCK** |
| `--apply` (default max-add 2) | **+2** |

| workId | shard |
|--------|-------|
| `sub_animation_scale-exp-b7-probe-alpha_2026` | `animation/ae.json` |
| `sub_manga_scale-exp-b7-probe-beta_2026` | `manga/d6.json` |

| 항목 | 값 |
|------|-----|
| works | 416 → **418** |
| 경로 | **Expansion** (Maintainer 아님) |
| gate | **PASS** · dedupe **0** |

### O3 누적 (@410 · SD1)

| 경로 | net insert |
|------|----------:|
| Maintainer (`a5_scale_supply_batch`) | **+6** |
| Expansion (batch7) | **+2** |
| **합계** | **+8** → **418** |

---

## Scale 8 — Expansion batch7 cohort 완료

**도구:** `seed_expansion_batch7.dart` · `--apply` ×3 (각 `--max-add 2`)

| round | ADD | works |
|:-----:|----:|------:|
| 2 | gamma · delta (game · movie) | 418→**420** |
| 3 | epsilon · zeta (drama · book) | 420→**422** |
| 4 | eta · theta (webtoon · animation) | 422→**424** |

| 항목 | 값 |
|------|-----|
| batch7 cohort | **8/8** · BLOCK **0** |
| Expansion net | **+8** (416→424) |
| gate | **PASS** · dedupe **0** |

### O3 누적 갱신 (@410 · SD1)

| 경로 | net insert |
|------|----------:|
| Maintainer | **+6** |
| Expansion (batch7) | **+8** |
| **합계** | **+14** → **424** |
| SD2.6 잔여 상한 | ~~6~~ → **0** (Scale 9에서 소진) |

---

## Scale 9 — Maintainer supply b4–b6 (SD2.6 상한 도달)

**도구:** `a5_scale_supply_batch.dart` · `a5_scale_enrich_batch.dart`

| 세션 | supply | enrich | works |
|------|--------|--------|------:|
| A | batch **4** (+2) | batch **5** (2 ja†) | 424→**426** |
| B | batch **5** (+2) | batch **6** (2 ja) | 426→**428** |
| C | batch **6** (+2) | batch **8** (2 ja) | 428→**430** |
| D | — | batch **7** insert-free (0‡) | **430** |

† batch7 probe는 seed에 **ja 내장** — enrich SKIP.  
‡ epsilon–theta 동일.

| 항목 | 값 |
|------|-----|
| Maintainer net (b4–6) | **+6** |
| **SD2.6** | 410→430 **상한 도달** |
| gate | **PASS** · dedupe **0** |

### O3 누적 최종 (@410 · day 0 세션)

| 경로 | net insert |
|------|----------:|
| Maintainer (b1–6) | **+12** |
| Expansion (batch7) | **+8** |
| **합계** | **+20** → **430** |

**O3 rate:** Maintainer **+12**만 측정 대상 (SD1.3) — 월 환산은 **2026-07-09** checkpoint.

---

## Scale 10 — O8·O9·O12 관측 착수 (@430)

**목적:** SD2.6 insert **hold** 구간 — SC3·SC5 **거버넌스·플랫폼** 관측.

**SD4:** [a5-scale-operational-decisions.md](a5-scale-operational-decisions.md) 확정.

### O8 — governance bundle

**도구:** `a5_scale_governance_observation.dart`

| 도구 | wall | status |
|------|-----:|:------:|
| registry_builder | 1584 ms | PASS |
| dedupe_linter | 1274 ms | PASS |
| quality_gate --strict | 1348 ms | PASS |
| coverage_dashboard | 1536 ms | PASS |
| sw1_a_validation | 1325 ms | PASS |
| urv_a_validation | 1412 ms | PASS |
| franchise_linter | 895 ms | PASS |
| **번들 합계** | **9374 ms** (~0.16 min) | **PASS** |

| 선형 추정 (SD4.4) | 5k | 50k |
|-------------------|----:|----:|
| bundle wall | ~**1.8 min** | ~**18 min** |

산출: `scale_governance_o8.json`

### O9 — semantic spot-check

**도구:** `a5_scale_semantic_spotcheck.dart` · cohort **20** (supply b1–6 + batch7)

| 항목 | 값 |
|------|-----|
| flagged | **0** / 20 |
| errorRate | **0%** |
| status | **PASS** |

산출: `scale_semantic_o9.json`

### O12 — franchise 수동 큐

**도구:** `a5_scale_franchise_queue.dart`

| 항목 | 값 |
|------|-----|
| queue clusters | **0** |
| uncovered members | **0** |
| estimated minutes | **0** |
| 50k 선형 추정 | **0 min** (현재 큐 비어 있음) |

산출: `scale_franchise_o12.json`

**해석:** @430에서 franchise_linter **미커버 클러스터 없음** — O12 부담 **가시화 완료** · 5k+에서 **재관측** 필요.

---

## Scale 11 — O6·O11·O13 platform (@430)

### O6 — Coverage Economics

**도구:** `coverage_sprint_02_economics.dart`

| 항목 | @430 |
|------|------|
| titles.en rate | **92.09%** (396/430) · ≥90% **PASS** |
| titles.en 90% 잔여 | **0** works |
| external_id | **49%** 대역 — 5k extrapolation **유효** |
| 산출 | `sprint_02_economics.json` |

### O11 · O13 — rebuild·index

| 항목 | @402 (Pilot) | @430 (Scale) |
|------|-------------:|-------------:|
| `registry_builder` wall | 1873 ms | **2059 ms** |
| `search_index.json` | 298,034 B | **318,244 B** |
| shard files | 333 | **351** |

**해석:** +28 works 대비 rebuild **+10%** wall — 50k 선형 추정 **보수적** (O8 번들 50k ~18 min 참조).

---

## O3 checkpoint 대기 (SD1.2)

| 필드 | 값 |
|------|-----|
| Clock 시작 | 2026-06-09 |
| Checkpoint | **2026-07-09** |
| Maintainer net (@410) | **+12** |
| Expansion net (@410) | **+8** (O3 **제외**) |
| day-0 세션 rate | **미산출** — elapsed **0** |
| SD2.6 | **hold** — insert **중단** |

---

## Scale 12 — SD2.6 hold 정기 관측 · O3 prep

**목적:** insert **없이** O8·O9·O12·O7 **재확인** · O3 checkpoint **도구화**.

| 도구 | 결과 |
|------|------|
| `a5_scale_hold_observation.dart` | **PASS** · wall **8923 ms** |
| `a5_scale_o3_checkpoint.dart` | elapsed **0** · rate **pending** · checkpoint **30d** |

### Hold bundle

| 관측 | 결과 |
|------|------|
| O8 governance | **PASS** |
| O9 semantic (20) | **PASS** · flagged **0** |
| O12 franchise | 큐 **0** |
| O7 ja backlog | **0** · SD3.5 Pause **미충족** |
| titles_en | **92.09%** PASS |

**CI:** `.github/workflows/scale_hold_check.yml` — 주 1회 + `preflight_check`  
**산출:** `scale_hold_observation.json` · `scale_o3_checkpoint.json`

---

## 다음 Scale 관측 (후속)

| 우선 | 항목 |
|:----:|------|
| 1 | **SD2.6 hold** 유지 → **2026-07-09** |
| 2 | O3 checkpoint — `--as-of 2026-07-09` rate vs G2 |
| 3 | franchise 큐 **5k 마일스톤** 재관측 |
