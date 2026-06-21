# Sprint 04 Phase B-5 — E4 Title Similarity 실효성 검토

> **단계:** Sprint 04 Phase B-5 (E4 규칙 **분석** · apply **아님**)  
> **대상:** E1 Steam candidate **15건** (E4 발화 **15/15**) · 심층 판정 **REVIEW 7건** (Phase B LOW)  
> **근거:** [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) · [externalid-quality-gate-rules.md](../externalid-quality-gate-rules.md)  
> **기준일:** 2026-06-09 · Registry **430 works**

**금지 준수:** 구현 **금지** · apply **금지** · Registry **수정 없음** · **문서만** 작성

---

## Executive Summary

| 지표 | 값 |
|------|-----|
| E4 token overlap (cohort 15) | **전건 0.0** (< 0.15) |
| **REVIEW 7건 — FALSE_REVIEW** | **7** |
| **REVIEW 7건 — TRUE_REVIEW** | **0** |
| E4 cohort 전체 — TRUE_REVIEW (교차게임·identity 붕괴) | **3** (266 · 270 · 277) |
| E4 cohort 전체 — FALSE_REVIEW | **12** |

### E4 유지 권고

| 항목 | 권고 |
|------|------|
| **현행 E4** (token overlap < 0.15 **단독**) | **유지 비권고** — FALSE_REVIEW **12/15** (80%) · LOW 7건 **전량 오탐** |
| **E4 개념** (semantic mismatch 검출) | **조건부 유지** — **교차게임 사전** + identity 붕괴 신호만 REVIEW · overlap 단독 **폐기** |
| **보조 신호** (alias · steamTitle) | 본 cohort **미가용** (전건 공백) — **후속 enrich 후** 재평가 |

**결론:** E4는 **과도하게 보수적**이 맞다. token overlap은 한·영 로컬라이즈 레지스트리에서 **판별력 없음**. REVIEW 7건은 인적 감사 시 **전건 attach 가능** → E4 단독 REVIEW는 **운영 가치 없음**.

---

## 1. 배경 · 검증 질문

Phase B-4에서 E4(token overlap T=0.15) 적용 시:

- cohort **15/15** E4 발화
- Phase B **LOW 7건** → Post-Gate **REVIEW 7건** (AUTO_APPROVE **0**)

**본 Phase 질문:** E4 REVIEW가 **실제 위험**을 잡는가, 아니면 **정상 로컬라이즈**를 오탐하는가?

---

## 2. E4 token overlap — cohort 15건 기록

측정식 ([B-4](sprint-04-e1-post-gate-audit.md) 동일): 알파벳·숫자 토큰(len ≥ 2) · overlap = |A ∩ B| / max(|A|, |B|) · **T = 0.15**

| # | work_id | title | titles.en | appId | **overlap** | E4 발화 |
|---|---------|-------|-----------|------:|:-----------:|:-------:|
| 1 | wk_000000143 | 포털 2 | Portal 2 | 620 | **0.0** | ✓ |
| 2 | wk_000000144 | 더 엘더스크롤 V: 스카이림 | The Elder Scrolls V: Skyrim Special Edition | 489830 | **0.0** | ✓ |
| 3 | wk_000000145 | 스타듀 밸리 | Stardew Valley | 413150 | **0.0** | ✓ |
| 4 | wk_000000146 | 더 위처 3: 와일드 헌트 | The Witcher 3: Wild Hunt | 292030 | **0.0** | ✓ |
| 5 | wk_000000266 | 블루 아카이브 | Save 30% on Songs of Conquest - Roots | 3511790 | **0.0** | ✓† |
| 6 | wk_000000267 | 셀레스테 | Save 75% on Celeste | 504230 | **0.0** | ✓ |
| 7 | wk_000000268 | 단간론파 | Save 50% on Danganronpa: Trigger Happy Havoc | 413410 | **0.0** | ✓ |
| 8 | wk_000000270 | 파이널 판타지 XIV | Site Error | 39210 | **0.0** | ✓† |
| 9 | wk_000000275 | 몬스터 헌터: 월드 | Save 74% on Monster Hunter: World | 582010 | **0.0** | ✓ |
| 10 | wk_000000276 | 니어: 오토마타 | NieR:Automata™ | 524220 | **0.0** | ✓ |
| 11 | wk_000000277 | 승리의 여신: 니케 | Black Myth: Wukong | 2358720 | **0.0** | ✓† |
| 12 | wk_000000278 | 옥토패스 트래블러 | OCTOPATH TRAVELER™ | 921570 | **0.0** | ✓ |
| 13 | wk_000000279 | 페르소나 5 로열 | Persona 5 Royal | 1687950 | **0.0** | ✓ |
| 14 | wk_000000286 | 언더테일 | Save 75% on Undertale | 391540 | **0.0** | ✓ |
| 15 | wk_000000289 | 용과 같이 0 | Yakuza 0 | 638970 | **0.0** | ✓ |

† 교차게임 사전 hit (266 · 270 · 277).

**관측:** 한글 `title` vs 영문 `titles.en`은 **공통 알파벳 토큰 0** — overlap **구조적으로 0.0**. 임계 0.15와 **무관하게** 전건 E4 해당.

---

## 3. 보조 신호 측정 (Registry 스냅샷)

| # | work_id | `title` ↔ `titles.en` **문자열 일치** | `title` == `titles.ko` | **alias 존재** | **steamTitle 존재** | ko ↔ en **번역 차이** |
|---|---------|:--------------------------------------:|:----------------------:|:--------------:|:-------------------:|:---------------------:|
| 1 | 143 | 불일치 | 일치 | **없음** | **없음** | 정상 로컬라이즈 |
| 2 | 144 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |
| 3 | 145 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |
| 4 | 146 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |
| 5 | 266 | 불일치 | 일치 | 없음 | 없음 | **이상** (다른 게임명) |
| 6 | 267 | 불일치 | 일치 | 없음 | 없음 | 표면 오염 (E2) |
| 7 | 268 | 불일치 | 일치 | 없음 | 없음 | 표면 오염 (E2) |
| 8 | 270 | 불일치 | 일치 | 없음 | 없음 | **identity 붕괴** (E1) |
| 9 | 275 | 불일치 | 일치 | 없음 | 없음 | 표면 오염 (E2) |
| 10 | 276 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |
| 11 | 277 | 불일치 | 일치 | 없음 | 없음 | **이상** (교차 게임) |
| 12 | 278 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |
| 13 | 279 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |
| 14 | 286 | 불일치 | 일치 | 없음 | 없음 | 표면 오염 (E2) |
| 15 | 289 | 불일치 | 일치 | 없음 | 없음 | 정상 로컬라이즈 |

### 보조 신호 해석

| 신호 | cohort 관측 | E4 보완 가능성 |
|------|-------------|----------------|
| `title` ↔ `titles.en` 일치 | **0/15** 일치 | 한·영 이중 제목 **정상** — 일치 기대 **부적절** |
| `title` == `titles.ko` | **15/15** 일치 | ko identity 층 **안정** — REVIEW 7건 공통 |
| alias | **0/15** | overlap 대체 **불가** (데이터 없음) |
| steamTitle (`extensions`) | **0/15** | Steam 공식명 교차검증 **불가** |
| ko ↔ en 번역 차이 | LOW 7 **정상** · HIGH 3 **이상** | **번역 차이 단독**으로는 LOW/HIGH **분리 가능** |

---

## 4. REVIEW 7건 — 인적 attach 가능성 판정

**대상:** Post-Gate **REVIEW** · Phase B **LOW** (E4 only · E1/E2/E3/E5 **미해당**)

| # | work_id | title | titles.en | appId | 인적 판정: attach 가능? | E4 분류 |
|---|---------|-------|-----------|------:|:----------------------:|:-------:|
| 1 | wk_000000143 | 포털 2 | Portal 2 | 620 | **예** — poster direct · 위험 없음 | **FALSE_REVIEW** |
| 2 | wk_000000145 | 스타듀 밸리 | Stardew Valley | 413150 | **예** | **FALSE_REVIEW** |
| 3 | wk_000000146 | 더 위처 3: 와일드 헌트 | The Witcher 3: Wild Hunt | 292030 | **예** | **FALSE_REVIEW** |
| 4 | wk_000000276 | 니어: 오토마타 | NieR:Automata™ | 524220 | **예** | **FALSE_REVIEW** |
| 5 | wk_000000278 | 옥토패스 트래블러 | OCTOPATH TRAVELER™ | 921570 | **예** | **FALSE_REVIEW** |
| 6 | wk_000000279 | 페르소나 5 로열 | Persona 5 Royal | 1687950 | **예** | **FALSE_REVIEW** |
| 7 | wk_000000289 | 용과 같이 0 | Yakuza 0 | 638970 | **예** | **FALSE_REVIEW** |

### 판정 근거 (공통)

| 근거 | REVIEW 7건 |
|------|:----------:|
| Phase B 감사 **LOW** · wrong mapping **없음** | 7/7 |
| poster **direct** appId · duplicate **없음** | 7/7 |
| `title` == `titles.ko` · identity ko 층 **정상** | 7/7 |
| ko ↔ en 차이 = **정상 로컬라이즈** (교차 게임 **아님**) | 7/7 |
| E4 overlap 0.0 = **측정 한계** · 실제 위험 **아님** | 7/7 |

### 집계 (REVIEW 7건)

| 분류 | 건수 |
|------|-----:|
| **FALSE_REVIEW** | **7** |
| **TRUE_REVIEW** | **0** |

**FALSE_REVIEW 비율:** **100%** (7/7) — E4가 LOW cohort에 대해 **순수 노이즈**.

---

## 5. cohort 15건 — E4 신호 품질 (참고)

E4가 **의미 있게** REVIEW해야 할 건은 **교차 게임·identity 붕괴** — 이미 **E1/E2/E3**가 선행 차단.

| work_id | E4 단독 가치 | E4 분류 (semantic) | 실제 차단 Rule |
|---------|:------------:|:------------------:|:--------------:|
| 266 | **있음** | TRUE_REVIEW | E2 (+ E1 후보) |
| 270 | **있음** | TRUE_REVIEW | E1 |
| 277 | **있음** | TRUE_REVIEW | E3 · E5 |
| 144 | 없음 (dup만) | FALSE_REVIEW | E3 · E5 |
| 267·268·275·286 | 없음 (프로모) | FALSE_REVIEW | E2 |
| **REVIEW 7** | 없음 | **FALSE_REVIEW ×7** | — |

| cohort E4 집계 | 건수 |
|----------------|-----:|
| TRUE_REVIEW | **3** |
| FALSE_REVIEW | **12** |
| **정밀도** (TRUE / 15) | **20%** |

---

## 6. 과보수성 분석

```
                    E4 발화 15건
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   REVIEW 7 (LOW)    BLOCK 8         (없음)
   FALSE_REVIEW 7    E4 중복 발화 8
   TRUE_REVIEW 0     TRUE 3 · FALSE 5
```

| 질문 | 답 |
|------|-----|
| E4가 15/15 REVIEW인가? | **예** (overlap 0.0 구조적) |
| 과도하게 보수적인가? | **예** — LOW 7건 **전건 오탐** |
| E4 없이 위험 노출? | **아니오** — HIGH·MEDIUM은 **E1/E2/E3/E5**가 이미 차단 |
| E4 제거 시 LOW 7건? | **AUTO_APPROVE 후보** (B-4 기준 **+7** coverage) |

### 신호별 분리력 (REVIEW 7 vs TRUE 3)

| 신호 | LOW 7 (FALSE) | 266·270·277 (TRUE) |
|------|:-------------:|:------------------:|
| token overlap | 0.0 | 0.0 — **동일** |
| 교차게임 사전 | — | **hit** |
| ko ↔ en 번역 | 정상 | **이상** |
| E1/E2/E3/E5 | — | **해당** |

→ **overlap 단독**은 TRUE/FALSE **구분 불가**. **교차게임 사전**만 TRUE 3건과 정합.

---

## 7. E4 유지 권고 (상세)

| 옵션 | 내용 | 권고 |
|:----:|------|:----:|
| **A** | 현행 E4 유지 (overlap < 0.15) | **비권고** |
| **B** | E4 **폐기** — E1/E2/E3/E5만 | **가능** — LOW 7 **무인 통과** · 위험 8건 **기차단** |
| **C** | E4 **축소** — 교차게임 사전 **only** → REVIEW | **권고** — TRUE 3건 포착 · FALSE 12건 **제거** |
| **D** | E4 **개정** — overlap **AND** (교차게임 OR steamTitle 불일치) | **조건부** — steamTitle enrich **후** |

**권고안 (문서):**

1. **단기:** E4에서 **token overlap 조건 제거** · 교차게임 사전만 REVIEW (또는 E4 비활성).
2. **중기:** `aliases` · `extensions.steamTitle` enrich 후 **옵션 D** 재측정.
3. **운영:** REVIEW 7건은 E4 수정 시 **AUTO_APPROVE 승격** — coverage **+7** (48.37%) 경로 **복원**.

---

## 8. B-4 · B-5 연계

| Phase | 발견 |
|-------|------|
| B-4 | E4 → AUTO_APPROVE **0** · REVIEW **7** |
| **B-5** | REVIEW 7 **전건 FALSE** — E4 **과보수 확인** |
| 다음 | E4 개정 **문서화** (구현은 별 Phase) → LOW 7 **gate 통과** 가정 재측정 |

---

## 9. 재현 (기존 산출물 참조)

```text
akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_e1_post_gate.json  # overlap
Registry shard 전수 스캔 (read-only)                                        # 보조 신호
docs/sprint-04-e1-audit.md                                                  # Phase B LOW 근거
```

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 Phase B-5 — E4 실효성 · FALSE_REVIEW 7 · TRUE_REVIEW 0 · overlap 단독 유지 비권고 |
