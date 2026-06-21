# Sprint 04 Phase B-2 — HIGH Risk Disposition

> **단계:** Sprint 04 Phase B-2 (원인 분류 · **apply 금지**)  
> **대상:** E1 감사 **HIGH 4건**  
> **기준일:** 2026-06-09  
> **측정 도구:** `dart run tool/coverage_sprint_04_high_risk_analyze.dart --write-json`  
> **선행:** [sprint-04-e1-audit.md](sprint-04-e1-audit.md)

**규칙:** Registry **수정 없음** · apply **금지** · enrich **금지**

**현재 externalId coverage:** **46.74%** (201/430)

---

## Executive Summary

| work_id | title | 분류 | 수정 가능 여부 |
|---------|-------|------|----------------|
| wk_000000144 | 더 엘더스크롤 V: 스카이림 | **DUPLICATE_ERROR** | **MANUAL_FIX** |
| wk_000000266 | 블루 아카이브 | **SOURCE_ERROR** | **RULE_FIX** |
| wk_000000270 | 파이널 판타지 XIV | **SOURCE_ERROR** · **MATCHING_ERROR** | **MANUAL_FIX** |
| wk_000000277 | 승리의 여신: 니케 | **DUPLICATE_ERROR** · **SOURCE_ERROR** · **MATCHING_ERROR** | **DO_NOT_APPLY** |

**공통:** E1 경로는 전건 **poster (direct)** — slug/search **미사용**. legacy `appid` fallback **미사용**(legacy slug만 존재).

---

## 분류 정의

| 코드 | 의미 |
|------|------|
| **DATA_ERROR** | Registry 필드 자체 결손·오염 |
| **SOURCE_ERROR** | Steam fetch/스크래핑이 **titles.en** 등에 잘못된 문자열 기록 |
| **MATCHING_ERROR** | appId는 poster에서 **결정론적**이나 **작품 identity**와 표면형 불일치 |
| **DUPLICATE_ERROR** | 동일 `steam` appId가 **다른 work**에 이미 부착 |

| 수정 가능 여부 | 의미 |
|----------------|------|
| **AUTO_FIX** | 규칙 적용만으로 안전 복구 |
| **RULE_FIX** | attach **차단 규칙**·게이트 추가 후 일괄 처리 |
| **MANUAL_FIX** | 큐레이터 판단·merge·제목 정리 **필수** |
| **DO_NOT_APPLY** | externalId attach **금지** (통합·정리 전) |

---

## 1. wk_000000144 — 더 엘더스크롤 V: 스카이림

### Registry 스냅샷

| 필드 | 값 |
|------|-----|
| **title** | 더 엘더스크롤 V: 스카이림 |
| **titles.en** | The Elder Scrolls V: Skyrim Special Edition |
| **titles.ko** | 더 엘더스크롤 V: 스카이림 |
| **aliases** | *(없음)* |
| **externalIds** | *(없음)* |
| **posterPath** | `…/steam/apps/489830/library_600x900.jpg` |
| **legacyIds** | `gen_game_skyrim_2011` |
| **releaseYear** | 2011 |
| **extensions** | `coverageSprint03: steam_fetch` |

### Steam 후보 선택 경로

| 경로 | 사용 | appId |
|------|:----:|------:|
| slug | — | — |
| search | — | — |
| **poster** | **예** | **489830** |
| fallback (legacy appid) | — | — |

legacy `gen_game_skyrim_2011`에는 **`appid{n}` 패턴 없음** → poster URL만이 attach 근거.

### 왜 HIGH인가

| 위험 | 판정 |
|------|------|
| wrong game mapping | **아님** — SE appId·제목 **정합** |
| duplicate externalId | **예** — `steam:489830` 이미 **wk_000000111** |

**중복 work (wk_000000111):**

| 필드 | wk_000000111 |
|------|----------------|
| title | 스카이림 SE |
| titles.en | The Elder Scrolls V: Skyrim Special Edition |
| externalIds.steam | **489830** |
| posterPath | **동일** URL |
| legacyIds | `gen_game_appid489830_2016` |
| releaseYear | 2016 |

동일 IP·동일 Steam listing에 **work 2건** — 하나는 이미 Sprint 04 externalId **부착 완료**.

### 분류

| 항목 | 값 |
|------|-----|
| **분류** | **DUPLICATE_ERROR** |
| **근본 원인** | Registry에 Skyrim SE **중복 엔트리** — E1은 poster에서 **올바른** appId를 고르지만 **키 충돌** |
| **수정 가능** | **MANUAL_FIX** |

### 권고

- wk_000000144에 attach 시 URV **duplicate external key** · exactId 오염.
- **canonical work** 1건 선택 (111 vs 144) · 비canonical은 merge/alias 또는 enrich **제외**.
- attach 대상이 아니라 **중복 정리** 문제.

---

## 2. wk_000000266 — 블루 아카이브

### Registry 스냅샷

| 필드 | 값 |
|------|-----|
| **title** | 블루 아카이브 |
| **titles.en** | `Save 30% on Songs of Conquest - Roots` |
| **titles.ko** | 블루 아카이브 |
| **aliases** | *(없음)* |
| **externalIds** | *(없음)* |
| **posterPath** | `…/steam/apps/3511790/library_600x900.jpg` |
| **legacyIds** | `sub_game_blue-archive_2021` |
| **releaseYear** | 2021 |

### Steam 후보 선택 경로

| 경로 | 사용 | appId |
|------|:----:|------:|
| slug | — | — |
| search | — | — |
| **poster** | **예** | **3511790** |
| fallback | — | — |

### 왜 잘못 매핑되었는가 (분석)

| 층 | 상태 |
|----|------|
| **poster → appId** | `3511790` — Blue Archive Steam global listing과 **일치 가능** (poster host 정상) |
| **titles.en** | Steam 스토어 **프로모 캐러셀** 문자열 — **다른 게임**(Songs of Conquest) |
| **identity** | ko **블루 아카이브** vs en **완전 불일치** |

**근본:** `steam_fetch`(Sprint 03)가 store 페이지에서 **할인 배너 제목**을 `titles.en`으로 저장 — **SOURCE_ERROR**.  
E1 attach 로직은 poster URL만 보고 appId를 고르므로 **appId 자체는 맞을 수 있으나** identity 층이 오염되어 **신뢰 붕괴**.

### 분류

| 항목 | 값 |
|------|-----|
| **분류** | **SOURCE_ERROR** |
| **수정 가능** | **RULE_FIX** |

### 권고

- attach **전** 게이트: `titles.en`이 `^Save \d+% on` 패턴이면 **차단** 또는 titles 정리 **선행**.
- titles.en 정리 후 **재감사** → LOW로 강등 가능.
- **AUTO_FIX** 불가 — 규칙·제목 정리 파이프라인 필요.

---

## 3. wk_000000270 — 파이널 판타지 XIV

### Registry 스냅샷

| 필드 | 값 |
|------|-----|
| **title** | 파이널 판타지 XIV |
| **titles.en** | **`Site Error`** |
| **titles.ko** | 파이널 판타지 XIV |
| **aliases** | *(없음)* |
| **externalIds** | *(없음)* |
| **posterPath** | `…/steam/apps/39210/library_600x900.jpg` |
| **legacyIds** | `sub_game_ffxiv_2013` |
| **releaseYear** | 2013 |

### Steam 후보 선택 경로

| 경로 | 사용 | appId |
|------|:----:|------:|
| slug | — | — |
| search | — | — |
| **poster** | **예** | **39210** |
| fallback | — | — |

### 왜 잘못 매핑되었는가

| 층 | 상태 |
|----|------|
| **titles.en** | fetch **실패 placeholder** (`Site Error`) — **SOURCE_ERROR** |
| **poster** | Steam FFXIV listing **39210** — poster 자산 **존재** |
| **MATCHING_ERROR** | 표면형(en)은 **무의미** · appId만으로는 **신뢰 검증 불가** |

**근본:** Sprint 03 `steam_fetch` **HTTP/파싱 실패**가 placeholder를 en에 기록. poster는 **별도 경로**로 정상 → E1은 en을 **보지 않고** poster만으로 appId 선택.

### 분류

| 항목 | 값 |
|------|-----|
| **분류** | **SOURCE_ERROR** · **MATCHING_ERROR** |
| **수정 가능** | **MANUAL_FIX** |

### 권고

- `titles.en` **복구**(공식 영문명) 후 재감사.
- `Site Error`·빈 en에 대한 attach **RULE_FIX** 권장.
- appId 39210은 FFXIV Steam 엔트리로 ** plausible** — identity 복구 후 **LOW** 강등 가능.

---

## 4. wk_000000277 — 승리의 여신: 니케

### Registry 스냅샷

| 필드 | 값 |
|------|-----|
| **title** | 승리의 여신: 니케 |
| **titles.en** | **Black Myth: Wukong** |
| **titles.ko** | 승리의 여신: 니케 |
| **aliases** | *(없음)* |
| **externalIds** | *(없음)* |
| **posterPath** | `…/steam/apps/2358720/library_600x900.jpg` |
| **legacyIds** | `sub_game_nikke_2022` |
| **releaseYear** | 2022 |

### Steam 후보 선택 경로

| 경로 | 사용 | appId |
|------|:----:|------:|
| slug | — | — |
| search | — | — |
| **poster** | **예** | **2358720** |
| fallback | — | — |

### 중복 work (wk_000000075)

| 필드 | wk_000000075 |
|------|----------------|
| title | 블랙 미스 |
| titles.en | Black Myth: Wukong |
| titles.ko | 블랙 미스 |
| externalIds.steam | **2358720** |
| posterPath | **동일** URL |
| legacyIds | `gen_game_appid2358720_2024` |

### 왜 잘못 매핑되었는가

Steam app **2358720** = *Goddess of Victory: NIKKE* (Steam 공식 listing).

| work | ko identity | en identity | poster appId | 해석 |
|------|-------------|-------------|-------------|------|
| wk_000000277 | **니케** | Wukong *(오류)* | 2358720 (NIKKE) | en **오염** — SOURCE + MATCHING |
| wk_000000075 | **블랙 미스** | Wukong | 2358720 | **잘못된 work**에 NIKKE appId가 Wukong으로 기록됨 가능 |

**근본 원인 (복합):**

1. **DUPLICATE_ERROR** — 동일 poster·동일 appId가 **075에 이미 부착**.
2. **SOURCE_ERROR** — 277의 `titles.en`이 **다른 게임**(Wukong)명 — fetch 오염 또는 075와 **poster 공유** 부작용.
3. **MATCHING_ERROR** — 075는 Wukong identity인데 appId는 **NIKKE** listing; 277은 NIKKE identity인데 en은 Wukong.

**핵심:** poster URL이 **동일 asset**을 가리키며, **두 work 중 하나 이상의 identity가 Steam listing과 불일치**. E1 deterministic attach는 이를 **검출하지 못함**.

### 분류

| 항목 | 값 |
|------|-----|
| **분류** | **DUPLICATE_ERROR** · **SOURCE_ERROR** · **MATCHING_ERROR** |
| **수정 가능** | **DO_NOT_APPLY** |

### 권고

- **277에 attach 금지** — duplicate + identity 붕괴.
- **075 vs 277** — 어느 work가 `2358720`의 canonical owner인지 **수동 판정** (NIKKE vs Wukong).
- Wukong Steam appId는 **2358720이 아님** — 075의 기존 attach도 **재검토** 대상 (별도 Sprint).
- merge/retire 전까지 **DO_NOT_APPLY**.

---

## 5. 집계 · Phase B-3 입력

| 분류 | 건수 | work |
|------|-----:|------|
| DUPLICATE_ERROR | 2 | 144, 277 |
| SOURCE_ERROR | 3 | 266, 270, 277 |
| MATCHING_ERROR | 2 | 270, 277 |
| DATA_ERROR | 0 | — |

| 수정 가능 | 건수 | work |
|-----------|-----:|------|
| MANUAL_FIX | 2 | 144, 270 |
| RULE_FIX | 1 | 266 |
| DO_NOT_APPLY | 1 | 277 |
| AUTO_FIX | 0 | — |

### E1 apply 재개 조건 (HIGH 제외 후)

| 트랜치 | 대상 | 전제 |
|--------|------|------|
| **B-3a** | LOW 7건 | 변경 없음 |
| **B-3b** | 266, 270 | titles.en **RULE_FIX/MANUAL_FIX** 후 재감사 |
| **보류** | 144, 277 | duplicate·identity **MANUAL_FIX / DO_NOT_APPLY** |

---

## 6. 재현

```bash
dart run tool/coverage_sprint_04_high_risk_analyze.dart --write-json
dart run tool/coverage_sprint_04_e1_audit.dart --write-json
```

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase B-2 HIGH 4건 disposition |
