# A5 Scale Expansion Cohort Plan — A유형 신규 apply

> **목적:** batch5/6 **B유형(legacy BLOCK)** 대비 **Net-new Expansion** apply 전략.  
> **전제:** [a5-scale-observation-log.md](a5-scale-observation-log.md) Scale 1 · [expansion-tool-grading.md](expansion-tool-grading.md)  
> **기준일:** 2026-06-09

---

## 1. 문제

| cohort | seeds | ADD | BLOCK | 유형 |
|--------|------:|----:|------:|------|
| batch6 | 40 | 0 | 40 | legacyIds→wk_ |
| batch5 | 45 | 0 | 45 | legacyIds→wk_ |

**결론:** 기존 Expansion cohort는 **재insert 불가** — merge·canonical **별도 트랙**.

---

## 2. A유형 정의

| 유형 | 조건 | Scale apply |
|------|------|:-----------:|
| **A — Net-new** | gate PASS · workId·legacyIds·fuzzyTitle **충돌 없음** | **허용** |
| **B — Legacy-blocked** | `legacyIds` → 기존 wk_ | **금지** |
| **C — Fuzzy-blocked** | fuzzyTitle → wk_ | **금지** |

---

## 3. A유형 cohort 공급 전략

### 3.1 단기 (현재~checkpoint)

| 우선 | 경로 | 비고 |
|:----:|------|------|
| 1 | **Maintainer** `a5_scale_supply_batch` | **검증 완료** · +6 (410→416) |
| 2 | **Expansion batch7** (신규 설계) | Net-new seeds only |
| 3 | batch5/6 | dry-run **집계만** · apply **0** |

### 3.2 batch7 설계 원칙 (제안)

| # | 원칙 |
|---|------|
| P1 | `pre_insert_dedupe_gate` **필수** (batch5/6와 동일) |
| P2 | v4 `shardHexForWorkId` **필수** |
| P3 | workId **신규** — 기존 wk_ `legacyIds`에 **미등록** |
| P4 | fuzzyTitle — 기존 wk_·sub_ **충돌 검사** |
| P5 | `--max-add 2` **기본** · SD2.4 검증 |
| P6 | 카테고리 **분산** — Scale maintainer와 동일 (game·movie·drama·book·animation·manga·webtoon) |

### 3.3 batch7 후보 소스 (개념)

| 소스 | 설명 |
|------|------|
| **신규 큐레이션** | Maintainer가 **새 IP** workId 설계 — catalog-expansion-plan 미등록 작 |
| **Signal pipeline** | enabled 시 dry-run **ADD>0** cohort만 (미래) |
| **기존 batch 금지** | batch3/4 **D급** · batch5/6 seeds **B유형** — 재사용 **불가** |

### 3.4 apply 절차

```
1. dry-run 전수 → ADD/BLOCK/SKIP 집계
2. ADD > 0 확인 (A유형 존재)
3. --max-add 2 --apply
4. preflight_check
5. a5-scale-observation-log 갱신
```

---

## 4. B유형 legacy cohort (별도 트랙)

| 항목 | 조치 |
|------|------|
| batch5/6 85건 | **재insert 금지** |
| 장기 | wk_ canonical 유지 · sub_ **merge** 또는 **폐기** — 운영 결정 |
| gate | **의도된 BLOCK** — H2 **정상** |

---

## 5. Scale checkpoint 연동

| SD | 연동 |
|----|------|
| SD1.2 (2026-07-09) | O3 rate에 Expansion A유형 apply **분리 집계** |
| SD2.6 | Maintainer + Expansion **합산** 20 works 상한 |
| SD3 | dedupe·Coverage **동일** |

---

## 6. 다음 실행 (준비 완료 시)

| # | 작업 |
|---|------|
| 1 | `seed_expansion_batch7.dart` — Net-new seeds + gate | **완료** |
| 2 | dry-run → ADD **8** · BLOCK **0** | **완료** |
| 3 | apply `--max-add 2` ×4 · Scale 7–8 | **완료** (+8 → 424) |

**batch7:** cohort **8/8** 완료 · BLOCK **0** · A유형 **검증됨**.

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — A/B유형 · batch7 원칙 |
