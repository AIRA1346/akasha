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

## 다음 Scale 관측 (후속)

| 우선 | 항목 |
|:----:|------|
| 1 | pilot ja backlog **4건** 소진 또는 insert **일시 중단** 후 enrich 우선 |
| 2 | O3 **기간 윈도** (SD1) 확정 |
| 3 | Expansion **신규 A유형 cohort** |
