# Sprint 04 Phase B — E1 Steam Cohort 감사 보고서

> **단계:** Sprint 04 Phase B (apply **전** 품질 감사)  
> **대상:** E1 Steam candidate **15건**  
> **기준일:** 2026-06-09 · Registry **430 works**  
> **측정 도구:** `dart run tool/coverage_sprint_04_e1_audit.dart --write-json`  
> **원본 JSON:** `akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_e1_audit.json`

**규칙 준수:** apply **금지** · Registry **수정 없음** · enrich **없음**

---

## Executive Summary

| 항목 | 값 |
|------|-----|
| cohort 크기 | **15** |
| **LOW** | **7** |
| **MEDIUM** | **4** |
| **HIGH** | **4** |
| **일괄 apply 권고** | **아니오** |

**판정:** syntactic audit(기존 runner)은 15/15 **ok**였으나, **identity·중복·제목 오염** 관점에서 **4건 HIGH** — Phase B apply는 **HIGH 제외 partial** 또는 **선행 수정 후** 진행.

**현재 externalId coverage (baseline):** **46.74%** (201/430) — [sprint-04-baseline-report.md](sprint-04-baseline-report.md)

---

## 1. appId 획득 방식 정의

| 방식 | E1에서의 의미 |
|------|----------------|
| **direct** | `posterPath` URL `/steam/apps/{id}/` 파싱 |
| **fallback** | `legacyIds` 내 `appid{n}` 만 존재 |
| **slug** | **미사용** (E1 cohort 범위 외) |
| **search** | **미사용** (E1 cohort 범위 외) |

본 cohort 15건: **direct 15** · **fallback 0** (단, 스타듀 밸리는 poster+legacy **동일 id** → direct + legacy 교차확인)

---

## 2. 위험 유형 정의

| 유형 | 감사 기준 |
|------|-----------|
| **wrong game mapping** | poster≠legacy · titles.en **Steam 프로모 스크랩** · ko/en **교차 게임명** |
| **remake/remaster confusion** | 리마스터 appId 대비 제목 토큰 불일치 |
| **edition/version confusion** | SE/Royal 등 edition app 대비 제목 토큰 불일치 |
| **franchise confusion** | franchise 형제 game 간 상이 steam id |
| **duplicate externalId** | 동일 steam appId가 **다른 work**에 이미 부착 |

---

## 3. cohort 요약표

| # | work_id | title | severity | appId | 획득 | 핵심 위험 |
|---|---------|-------|:--------:|------:|:----:|-----------|
| 1 | wk_000000143 | 포털 2 | **LOW** | 620 | direct | — |
| 2 | wk_000000144 | 더 엘더스크롤 V: 스카이림 | **HIGH** | 489830 | direct | duplicate |
| 3 | wk_000000145 | 스타듀 밸리 | **LOW** | 413150 | direct | — |
| 4 | wk_000000146 | 더 위처 3: 와일드 헌트 | **LOW** | 292030 | direct | — |
| 5 | wk_000000266 | 블루 아카이브 | **HIGH** | 3511790 | direct | wrong mapping |
| 6 | wk_000000267 | 셀레스테 | **MEDIUM** | 504230 | direct | wrong mapping† |
| 7 | wk_000000268 | 단간론파 | **MEDIUM** | 413410 | direct | wrong mapping† |
| 8 | wk_000000270 | 파이널 판타지 XIV | **HIGH** | 39210 | direct | wrong mapping |
| 9 | wk_000000275 | 몬스터 헌터: 월드 | **MEDIUM** | 582010 | direct | wrong mapping† |
| 10 | wk_000000276 | 니어: 오토마타 | **LOW** | 524220 | direct | — |
| 11 | wk_000000277 | 승리의 여신: 니케 | **HIGH** | 2358720 | direct | duplicate + wrong mapping |
| 12 | wk_000000278 | 옥토패스 트래블러 | **LOW** | 921570 | direct | — |
| 13 | wk_000000279 | 페르소나 5 로열 | **LOW** | 1687950 | direct | — |
| 14 | wk_000000286 | 언더테일 | **MEDIUM** | 391540 | direct | wrong mapping† |
| 15 | wk_000000289 | 용과 같이 0 | **LOW** | 638970 | direct | — |

† titles.en이 `Save N% on …` Steam 프로모 문자열 — **appId는 poster direct**이나 identity 층 **오염 신호**.

---

## 4. 항목별 상세 감사

### wk_000000143 — 포털 2 · **LOW**

| 필드 | 값 |
|------|-----|
| current externalIds | *(없음)* |
| 추정 Steam appId | **620** |
| 획득 | **direct** (poster) |
| slug / search / fallback | — / — / — |

| 위험 | 존재 | 등급 |
|------|:----:|:----:|
| wrong game mapping | — | — |
| remake/remaster | — | — |
| edition/version | — | — |
| franchise | — | — |
| duplicate externalId | — | — |

---

### wk_000000144 — 스카이림 · **HIGH**

| 필드 | 값 |
|------|-----|
| current externalIds | *(없음)* |
| 추정 Steam appId | **489830** (Skyrim SE) |
| 획득 | **direct** |
| titles.en | The Elder Scrolls V: Skyrim **Special Edition** |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| duplicate externalId | **예** | **HIGH** | `steam:489830` 이미 **wk_000000111** 보유 |
| 기타 | — | — | — |

**권고:** apply **보류** — URV duplicate·exactId 오염. 형제 work 정책 검토 또는 **한쪽만** 유지.

---

### wk_000000145 — 스타듀 밸리 · **LOW**

| 필드 | 값 |
|------|-----|
| 추정 appId | **413150** |
| 획득 | **direct** (+ legacy `appid413150` **일치**) |

전 위험 **없음**.

---

### wk_000000146 — 더 위처 3 · **LOW**

| 필드 | 값 |
|------|-----|
| 추정 appId | **292030** |
| 획득 | **direct** |

전 위험 **없음**.

---

### wk_000000266 — 블루 아카이브 · **HIGH**

| 필드 | 값 |
|------|-----|
| 추정 appId | **3511790** |
| 획득 | **direct** |
| titles.en | `Save 30% on **Songs of Conquest - Roots**` |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **HIGH** | ko **블루 아카이브** vs en **다른 게임명** |

**권고:** poster·titles.en **선행 정리** 후 attach 재감사.

---

### wk_000000267 — 셀레스테 · **MEDIUM**

| 필드 | 값 |
|------|-----|
| 추정 appId | **504230** |
| titles.en | `Save 75% on Celeste` |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **MEDIUM** | Steam 프로모 스크랩 제목 |

**권고:** appId **504230**은 Celeste와 **정합** — attach 가능하나 **titles.en 정리 병행** 권장.

---

### wk_000000268 — 단간론파 · **MEDIUM**

| 필드 | 값 |
|------|-----|
| 추정 appId | **413410** |
| titles.en | `Save 50% on Danganronpa: Trigger Happy Havoc` |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **MEDIUM** | 프로모 스크랩 제목 |

---

### wk_000000270 — 파이널 판타지 XIV · **HIGH**

| 필드 | 값 |
|------|-----|
| 추정 appId | **39210** |
| titles.en | **`Site Error`** |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **HIGH** | identity 층 붕괴 (placeholder en) |

**권고:** apply **보류** — poster·제목 fetch **복구 후** 재감사.

---

### wk_000000275 — 몬스터 헌터: 월드 · **MEDIUM**

| 필드 | 값 |
|------|-----|
| 추정 appId | **582010** |
| titles.en | `Save 74% on Monster Hunter: World` |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **MEDIUM** | 프로모 스크랩 제목 |

---

### wk_000000276 — 니어: 오토마타 · **LOW**

| 필드 | 값 |
|------|-----|
| 추정 appId | **524220** |
| titles.en | NieR:Automata™ |

전 위험 **없음**.

---

### wk_000000277 — 승리의 여신: 니케 · **HIGH**

| 필드 | 값 |
|------|-----|
| 추정 appId | **2358720** |
| titles.en | **`Black Myth: Wukong`** |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **HIGH** | ko **니케** vs en **Wukong** |
| duplicate externalId | **예** | **HIGH** | `steam:2358720` 이미 **wk_000000075** 보유 |

**권고:** apply **금지** — 중복 키 + 교차 게임명. wk_000000075와 **통합·정리** 선행.

---

### wk_000000278 — 옥토패스 트래블러 · **LOW**

| 필드 | 값 |
|------|-----|
| 추정 appId | **921570** |
| titles.en | OCTOPATH TRAVELER™ |

전 위험 **없음**.

---

### wk_000000279 — 페르소나 5 로열 · **LOW**

| 필드 | 값 |
|------|-----|
| 추정 appId | **1687950** |
| titles.en | Persona 5 Royal |

전 위험 **없음** (Royal edition·appId **정합**).

---

### wk_000000286 — 언더테일 · **MEDIUM**

| 필드 | 값 |
|------|-----|
| 추정 appId | **391540** |
| titles.en | `Save 75% on Undertale` |

| 위험 | 존재 | 등급 | 상세 |
|------|:----:|:----:|------|
| wrong game mapping | **예** | **MEDIUM** | 프로모 스크랩 제목 |

---

### wk_000000289 — 용과 같이 0 · **LOW**

| 필드 | 값 |
|------|-----|
| 추정 appId | **638970** |
| titles.en | Yakuza 0 |

전 위험 **없음**.

---

## 5. 집계 · G2 영향

| 시나리오 | attach 가능 (감사 기준) | 건수 | 예상 coverage |
|----------|-------------------------|-----:|--------------:|
| cohort 전체 (기계적) | 15 | 15 | 50.23% |
| **LOW만** | 7 | 7 | **208/430 = 48.37%** |
| LOW + MEDIUM | 11 | 11 | 49.30% |
| HIGH 제외 | 11 | — | G2 50% **미달** (-7작) |

| 판정 | 내용 |
|------|------|
| G2 50% (215작) | LOW 7건만 apply 시 **미달** |
| G2 달성 + 품질 | HIGH 4건 **해소** 후 LOW+MEDIUM 11건 검토 시 **근접** (216/430) |
| **권고 트랜치** | **LOW 7건** 1차 apply 후보 · MEDIUM 4건은 titles.en 정리 동반 · HIGH 4건 **제외** |

---

## 6. Phase B apply 전 체크리스트

| # | 조건 |
|---|------|
| 1 | HIGH **4건** disposition 기록 (skip / merge / fix) |
| 2 | MEDIUM **4건** titles.en 프로모 문자열 정리 여부 결정 |
| 3 | duplicate 2건 URV **사전 dry-run** |
| 4 | apply 후 `externalId coverage` **재측정** |
| 5 | `quality_gate --strict` · SW1 · URV |

---

## 7. 재현

```bash
dart run tool/coverage_sprint_04_e1_audit.dart --write-json
dart run tool/coverage_sprint_04_external_id.dart --dry-run --phase steam
```

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 Phase B E1 감사 — 15건 · apply 전 |
