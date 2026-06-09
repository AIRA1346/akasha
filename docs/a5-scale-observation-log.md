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

## 다음 Scale 관측 (후속)

| 우선 | 항목 |
|:----:|------|
| 1 | enrich **병행** 시작 → O7 · O6 |
| 2 | G1 구간 insert **누적** → O3 |
| 3 | Expansion **신규 A유형 cohort** 설계 (batch5/6는 B유형 전수) |
