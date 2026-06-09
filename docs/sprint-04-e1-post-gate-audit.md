# Sprint 04 Phase B-4 — E1 Post-Gate 재분류 감사

> **단계:** Sprint 04 Phase B-4 (Quality Gate **적용 시뮬레이션** · apply **아님**)  
> **대상:** E1 Steam candidate **15건**  
> **규칙:** [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) E1–E5  
> **기준일:** 2026-06-09 · Registry **430 works** · externalId **201** (46.74%)  
> **측정 도구:** `dart run tool/coverage_sprint_04_e1_post_gate.dart --write-json`  
> **원본 JSON:** `akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_e1_post_gate.json`

**금지 준수:** apply **금지** · Registry **수정 없음** · enrich **없음**

---

## Executive Summary

| 항목 | Phase B (감사 등급) | **Post-Gate (E1–E5)** |
|------|---------------------|------------------------|
| cohort | 15 | 15 |
| 통과 (무인 attach) | LOW **7** | **AUTO_APPROVE 0** |
| 인적 확인 | MEDIUM **4** | *(E2로 BLOCK)* |
| 차단 | HIGH **4** | **BLOCK 8** |
| REVIEW 큐 | — | **REVIEW 7** |

### 요약 지표

| # | 지표 | 값 |
|---|------|-----|
| 1 | **AUTO_APPROVE** | **0** |
| 2 | **REVIEW** | **7** |
| 3 | **BLOCK** | **8** |
| 4a | 예상 coverage 증가 — **AUTO_APPROVE만** | **+0** → **46.74%** (201/430) |
| 4b | 예상 coverage 증가 — **AUTO_APPROVE + REVIEW** | **+7** → **48.37%** (208/430) |
| 5 | **G2 50% (215작) 달성** | **미달** — AUTO_APPROVE만 **-14** · REVIEW 포함 **-7** |

### 핵심 판정

| 관점 | 결과 |
|------|------|
| **차단 강도 (E1·E2·E3·E5)** | Phase B HIGH **4** + MEDIUM **4** 전건 **BLOCK** — **실효** |
| **E4 실효** | cohort **15/15** token overlap **0.0** (< 0.15) — 한·영 로컬라이즈 제목 **전량 REVIEW** |
| **무인 파이프라인** | 이전 LOW **7**건도 **AUTO_APPROVE 0** — E4가 **완전 자동 attach 차단** |
| **G2 경로** | E1 cohort만으로는 **50% 불가** — E2(TMDB) 또는 REVIEW 큐 **해소** 필요 |

---

## 1. 적용 규칙 · 판정 로직

| Rule | 조건 | Gate 조치 | 최종 판정 기여 |
|:----:|------|:---------:|----------------|
| E1 | `titles.en == "Site Error"` | BLOCK | **BLOCK** |
| E2 | `titles.en` startsWith `"Save "` | BLOCK | **BLOCK** |
| E3 | candidate steam id **다른 work** 보유 | BLOCK | **BLOCK** |
| E4 | token overlap **< 0.15** 또는 교차게임 사전 | REVIEW | **REVIEW** (BLOCK 없을 때) |
| E5 | duplicate externalId across `wk_` | BLOCK | **BLOCK** |

**최종 판정 우선순위:** E1/E2/E3/E5 중 하나라도 해당 → **BLOCK** · else E4 → **REVIEW** · else **AUTO_APPROVE**.

**E4 측정식:** 알파벳·숫자 토큰(len ≥ 2) 집합 · overlap = |A ∩ B| / max(|A|, |B|) · 임계 **T = 0.15** ([B-3 초안](externalid-quality-gate-rules.md) 동일).

---

## 2. cohort 전체 재평가

| # | work_id | title | appId | triggered rule(s) | 최종 판정 | Phase B |
|---|---------|-------|------:|:------------------:|:---------:|:-------:|
| 1 | wk_000000143 | 포털 2 | 620 | **E4** | **REVIEW** | LOW |
| 2 | wk_000000144 | 더 엘더스크롤 V: 스카이림 | 489830 | **E3** · **E5** · E4 | **BLOCK** | HIGH |
| 3 | wk_000000145 | 스타듀 밸리 | 413150 | **E4** | **REVIEW** | LOW |
| 4 | wk_000000146 | 더 위처 3: 와일드 헌트 | 292030 | **E4** | **REVIEW** | LOW |
| 5 | wk_000000266 | 블루 아카이브 | 3511790 | **E2** · E4† | **BLOCK** | HIGH |
| 6 | wk_000000267 | 셀레스테 | 504230 | **E2** · E4 | **BLOCK** | MEDIUM |
| 7 | wk_000000268 | 단간론파 | 413410 | **E2** · E4 | **BLOCK** | MEDIUM |
| 8 | wk_000000270 | 파이널 판타지 XIV | 39210 | **E1** · E4† | **BLOCK** | HIGH |
| 9 | wk_000000275 | 몬스터 헌터: 월드 | 582010 | **E2** · E4 | **BLOCK** | MEDIUM |
| 10 | wk_000000276 | 니어: 오토마타 | 524220 | **E4** | **REVIEW** | LOW |
| 11 | wk_000000277 | 승리의 여신: 니케 | 2358720 | **E3** · **E5** · E4† | **BLOCK** | HIGH |
| 12 | wk_000000278 | 옥토패스 트래블러 | 921570 | **E4** | **REVIEW** | LOW |
| 13 | wk_000000279 | 페르소나 5 로열 | 1687950 | **E4** | **REVIEW** | LOW |
| 14 | wk_000000286 | 언더테일 | 391540 | **E2** · E4 | **BLOCK** | MEDIUM |
| 15 | wk_000000289 | 용과 같이 0 | 638970 | **E4** | **REVIEW** | LOW |

† E4 교차게임 사전 hit (266·270·277).

### Rule별 발화 건수

| Rule | 발화 | 판정에 **결정적** |
|:----:|-----:|:-----------------:|
| E1 | 1 | 1 (270) |
| E2 | 5 | 5 (266·267·268·275·286) |
| E3 | 2 | 2 (144·277) |
| E4 | **15** | **7** (143·145·146·276·278·279·289) |
| E5 | 2 | 2 (144·277, E3 동시) |

---

## 3. Phase B → Post-Gate 재분류

```
Phase B severity          Post-Gate verdict
─────────────────         ─────────────────
LOW      ×7      ──────►  REVIEW   ×7   (E4 only)
MEDIUM   ×4      ──────►  BLOCK    ×4   (E2)
HIGH     ×4      ──────►  BLOCK    ×4   (E1/E2/E3/E5)
                          ─────────
                          BLOCK 8 · REVIEW 7 · AUTO_APPROVE 0
```

| 전환 | 건수 | 해석 |
|------|-----:|------|
| LOW → REVIEW | 7 | E4 token overlap — **무인 attach 불가** |
| MEDIUM → BLOCK | 4 | E2가 Phase B **권고 수준**을 **hard block**으로 승격 |
| HIGH → BLOCK | 4 | E1/E2/E3/E5 — B-3 예측과 **일치** |
| LOW → AUTO_APPROVE | **0** | — |

---

## 4. Coverage · G2 영향

| 시나리오 | attach 건수 | externalId | coverage | G2 (215) |
|----------|------------:|-----------:|---------:|:--------:|
| baseline | — | 201 | **46.74%** | **-14** |
| 기계적 E1 전량 (gate 없음) | 15 | 216 | 50.23% | **+1** |
| **AUTO_APPROVE만** | 0 | 201 | **46.74%** | **-14** |
| **AUTO_APPROVE + REVIEW** | 7 | 208 | **48.37%** | **-7** |
| AUTO + REVIEW + BLOCK 중 E2 해소‡ | 11 | 212 | 49.30% | -3 |

‡ E2 차단 5건 중 appId 정합 4건(MEDIUM) + 266 — **titles.en 정리 후** 재평가 가정 · 본 측정 범위 **외**.

| G2 판정 | 내용 |
|---------|------|
| AUTO_APPROVE 경로 | **달성 불가** (Δ0) |
| REVIEW 전량 승인 시 | **미달** (208 < 215, **-7**) |
| Gate 없이 E1 15건 | **초과 달성** (+1) — **품질 리스크 수반** |

---

## 5. Rule Set 강도 · 실효성 평가

### 5.1 차단 규칙 (E1 · E2 · E3 · E5) — **강함**

| 평가 | 내용 |
|------|------|
| HIGH 4건 | **전건 BLOCK** — [B-3 매핑](externalid-quality-gate-rules.md) **검증** |
| MEDIUM 4건 | Phase B "attach 가능·titles 정리 권장" → Gate는 **선행 BLOCK** |
| false negative | cohort 내 **0** — 기계적 runner 15/15 ok 대비 **8건 추가 차단** |
| false positive (BLOCK) | **관측 0** — E2 차단 4건(MEDIUM)은 appId **정합**이나 identity **오염** |

### 5.2 E4 — **과민 (false positive 높음)**

| 평가 | 내용 |
|------|------|
| 관측 | 15/15 overlap **0.0** — 한글 `title` vs 영문 `titles.en` **공통 토큰 없음** |
| LOW 7건 | 전건 **REVIEW** — Phase B "안전" 판정과 **충돌** |
| HIGH 보조 | 266·270·277 — **교차게임 사전** hit · 이미 BLOCK이라 **한계 기여** |
| 144 | E4 발화하나 E3/E5가 **BLOCK** — B-3 "E4 통과"는 **판정 비결정** 의미 |

**결론:** 문서화된 E4(token overlap T=0.15)는 **ko/en 로컬라이즈 레지스트리**에서 **실효 REVIEW=100%**. 운영 시 **교차게임 사전 전용** 또는 **romanization·alias 교차**로 **범위 축소** 필요 ([B-3 false positive 경고](externalid-quality-gate-rules.md) **실측 확인**).

### 5.3 종합

| 축 | 등급 | 요약 |
|----|:----:|------|
| 오염·중복 **차단** | **A** | E1+E2+E3+E5 — HIGH·MEDIUM **전량** 차단 |
| 무인 **처리량** | **D** | AUTO_APPROVE **0/15** |
| G2 **경제성** | **C−** | E1만으로 REVIEW 포함해도 **-7** |
| B-3 예측 정합 | **높음** | BLOCK 8건 Rule 매핑 **일치** |

---

## 6. 항목별 상세 (BLOCK 8건)

### wk_000000144 — 스카이림 · **BLOCK** (E3 · E5)

| 필드 | 값 |
|------|-----|
| candidate | steam:**489830** |
| 기존 보유 | **wk_000000111** |
| 결정 Rule | **E3** · **E5** |

### wk_000000266 — 블루 아카이브 · **BLOCK** (E2)

| 필드 | 값 |
|------|-----|
| titles.en | `Save 30% on Songs of Conquest - Roots` |
| 결정 Rule | **E2** (+ E4 교차게임) |

### wk_000000267 · 268 · 275 · 286 — **BLOCK** (E2)

| work_id | title | titles.en (prefix) |
|---------|-------|-------------------|
| 267 | 셀레스테 | `Save 75% on Celeste` |
| 268 | 단간론파 | `Save 50% on Danganronpa…` |
| 275 | 몬스터 헌터: 월드 | `Save 74% on Monster Hunter: World` |
| 286 | 언더테일 | `Save 75% on Undertale` |

**참고:** poster appId는 각 게임과 **정합** — E2는 **identity 오염** 차단이지 **wrong appId** 차단이 아님.

### wk_000000270 — FFXIV · **BLOCK** (E1)

| 필드 | 값 |
|------|-----|
| titles.en | **`Site Error`** |
| 결정 Rule | **E1** |

### wk_000000277 — 니케 · **BLOCK** (E3 · E5)

| 필드 | 값 |
|------|-----|
| candidate | steam:**2358720** |
| 기존 보유 | **wk_000000075** |
| titles.en | `Black Myth: Wukong` (ko **니케** 불일치) |
| 결정 Rule | **E3** · **E5** |

---

## 7. 항목별 상세 (REVIEW 7건)

Phase B **LOW** 전건 — **E4 only** (token overlap 0.0 < 0.15).

| work_id | title | titles.en | appId | 인적 REVIEW 시 예상 |
|---------|-------|-----------|------:|---------------------|
| 143 | 포털 2 | Portal 2 | 620 | **승인 가능** |
| 145 | 스타듀 밸리 | Stardew Valley | 413150 | **승인 가능** |
| 146 | 더 위처 3 | The Witcher 3: Wild Hunt | 292030 | **승인 가능** |
| 276 | 니어: 오토마타 | NieR:Automata™ | 524220 | **승인 가능** |
| 278 | 옥토패스 트래블러 | OCTOPATH TRAVELER™ | 921570 | **승인 가능** |
| 279 | 페르소나 5 로열 | Persona 5 Royal | 1687950 | **승인 가능** |
| 289 | 용과 같이 0 | Yakuza 0 | 638970 | **승인 가능** |

**운영 함의:** REVIEW 큐 **7건 일괄 승인** 시 coverage **+7** (48.37%) — Phase B "LOW 7 apply"와 **동일 수치**이나 **프로세스**는 무인 → **인적**으로 변경.

---

## 8. 권고 (측정 기반 · apply 아님)

| 우선순위 | 항목 |
|:--------:|------|
| 1 | **E4 범위 재정의** — token-only → 교차게임 사전 + alias 교차 (LOW 7 false REVIEW 해소) |
| 2 | **E2 차단 4건(MEDIUM)** — titles.en 정리 후 **재측정** (잠재 +4, 49.30%) |
| 3 | **BLOCK 4건(HIGH)** — [disposition](sprint-04-high-risk-disposition.md) 선행 |
| 4 | G2 잔여 **-7~14** — **E2 TMDB** cohort 또는 타 Sprint 경로 |

---

## 9. 재현

```bash
dart run tool/coverage_sprint_04_e1_post_gate.dart --write-json
dart run tool/coverage_sprint_04_e1_audit.dart --write-json
```

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 Phase B-4 — E1 15건 post-gate 재분류 · AUTO 0 / REVIEW 7 / BLOCK 8 |
