# Coverage Quality Governance

> **목적:** Coverage **확대 이후**에도 Identity 품질을 유지하기 위한 **운영 거버넌스**를 정의한다.  
> **질문:** *「Coverage를 얼마나 늘릴 수 있는가?」* 가 아니라 *「Coverage를 늘려도 품질을 유지할 수 있는가?」*  
> **전제:** [phase2-mid-review.md](phase2-mid-review.md) · Sprint 01~03 실측 · [phase2-late-stage-plan.md](phase2-late-stage-plan.md) **P0**  
> **기준일:** 2026-06-09 · Registry **402작**

**범위:** enrich·insert·release **프로세스**와 **게이트**만 다룬다.  
**금지:** 신규 ADR · Registry/Franchise/search_index **구조 변경** · 본 문서 작성 시점 **실험 실행**.

**관련 도구:** `tool/coverage_sprint_03_titles_en.dart` · `tool/poster_verification.dart` · `tool/coverage_dashboard.dart` · `tool/sw1_a_validation.dart` · `tool/urv_a_validation.dart`

---

## 1. Executive Summary

Sprint 03은 **Coverage 수량**(titles.en **91.5%**)과 **검색 회귀**(SW1/URV/GAP **100%**)를 동시에 달성했다. 그러나 **31건**의 invalid `titles.en`(TMDB HTML 템플릿 오염)은 **수량 KPI만으로는 품질을 보장할 수 없음**을 보여 준다.

| 층 | 역할 |
|----|------|
| **Coverage KPI** | 필드·표면형 **존재 비율** — enrich 백로그 규모 |
| **Quality KPI** | 존재하는 값이 **검색·Identity·출처와 정합**하는지 |

**운영 원칙:** Coverage Sprint·배치 enrich는 **Quality 게이트 통과 후**에만 registry·assets에 반영한다.

---

## 2. 현재 자동 enrich 경로

Sprint 03 `coverage_sprint_03_titles_en.dart` 기준 **우선순위 체인** (상위 실패 시 하위 fallback).

### 2.1 경로 요약

| method | bucket | 입력 신호 | 산출 | Sprint 03 비중 |
|--------|:------:|-----------|------|----------------|
| **`tmdb_fetch`** | auto | `externalIds.tmdb` · TMDB 페이지 HTML | `titles.en` | auto_high tier · **품질 사고 31건** (Run 1, 가드 전) |
| **`steam_fetch`** | auto | `posterPath` / legacy `appid` → Steam store HTML | `titles.en` | game cohort · 네트워크 I/O |
| **`latin_title`** | semi | `title` ASCII·라틴 비율 높음 · `1984` 등 | `titles.en` = `title` | book·서양권 |
| **`legacy_slug`** | semi | `legacyIds` → `legacySlugStem` → Title Case | `titles.en` | manga/animation **다수** (remediate) |

**보조 semi 경로 (동일 체인):** `franchise_copy` · `description_parse` · `curated_manual` — Sprint 03에서 소량·fallback.

### 2.2 경로별 메커니즘

**`tmdb_fetch`**

- `resolveTmdbId(work)` → `fetchTmdbPageTitle()` (tv/movie 페이지)
- `_extractEnglishFromTmdb()` · `titlesMatchWork()` 또는 `_plausibleEn()` 통과 시 채택
- **가드 (Run 2 이후):** `_isValidEnTitle()` — `#=` · `dataItem` · 한글 혼입 거부

**`steam_fetch`**

- `posterPath`의 `steam/apps/{id}` 또는 legacy `appid{n}`
- Store 페이지 `og:title` / `apphub_AppName` 파싱 · `_isValidEnTitle()` 통과 시 채택

**`latin_title`**

- `_isMostlyLatin(title)` 또는 `_isAsciiCanonicalTitle(title)`
- 별도 출처 대조 없이 `title` 복사

**`legacy_slug`**

- `sub_manga_one-piece_1997` → `One Piece` (휴리스틱 humanize)
- `appid*` stem **스킵** · 라틴 문자 없는 slug **스킵**

---

## 3. 각 경로의 실패 사례 (확인된 리스크)

> Sprint 01~03 · remediate · [phase2-mid-review.md](phase2-mid-review.md) §3.2 근거. **가설·신규 실험 없음.**

### 3.1 실패 유형 정의

| 유형 | 정의 |
|------|------|
| **잘못된 titles.en** | 필드는 채워졌으나 **의미 없거나 오염된** 문자열 |
| **잘못된 매핑** | 출처 ID·slug가 **다른 작품**을 가리킴 |
| **stale 데이터** | 과거에 맞았으나 **출처 메타가 변경**됨 |
| **source 변경** | 스크래핑·HTML·API **형식 변경**으로 파서 실패 또는 오파싱 |

### 3.2 경로별 실패 매트릭스

| 경로 | 잘못된 titles.en | 잘못된 매핑 | stale 데이터 | source 변경 |
|------|------------------|-------------|--------------|-------------|
| **`tmdb_fetch`** | ✅ **31건** `#= data.dataItem.date #` (Run 1 · 가드 전) | △ `titlesMatchWork` 통과해도 **시즌/극장판 혼동** 가능 | △ TMDB 개명·로컬라이즈 제목 변경 | ✅ HTML 템플릿·`og:title` 구조 변경 시 **일괄 오파싱** |
| **`steam_fetch`** | △ 빈 응답·지역화 제목 (미확인 대량 사례) | △ 잘못된 `appId` (poster·legacy 불일치) | △ Steam store 개명 | ✅ `og:title`·`apphub_AppName` 선택자 변경 |
| **`legacy_slug`** | △ 비표준 영문 (`86 Eighty Six` vs 공식 표기) | △ slug가 **비공식 약칭** (`danmachi` 등) | — (정적 slug) | — |
| **`latin_title`** | △ 비영어 라틴 문자 혼입 (`Müller` 등 — rare) | ✅ **한글 제목을 en으로 쓰지 않음** (latin 아님) | — | — |

### 3.3 cross-cutting 리스크 (경로 무관)

| 리스크 | 증거 | 영향 |
|--------|------|------|
| **enrich 성공 ≠ linguistic QA** | legacy_slug·latin 다수 | SW1 **현 쿼리 세트**에서는 100% — **쿼리 확대 시** 품질 리스크 |
| **poster ↔ externalId 불일치** | `poster_verification.dart` — TMDB poster는 `externalIds.tmdb`+캐시 일치 필요 | 포스터 검증 FAIL · **매핑 신뢰도** 저하 |
| **`extensions.coverageSprint03`만으로 추적** | method 기록은 있으나 **품질 등급 없음** | 사후 감사·spot-check 어려움 |
| **franchise_copy 오염 전파** | peer `titles.en`이 invalid였을 경우 연쇄 (가드 후 완화) | 동일 franchise **일괄 오염** |

---

## 4. 품질 게이트 정의

기존 [phase2-charter.md](phase2-charter.md) §7 워크플로에 **품질 층**을 추가한다. **구조 변경 없음** — 체크리스트·도구 호출 순서만.

### 4.1 insert 전 (신규 Work·stub)

| # | 게이트 | 자동/수동 | 내용 |
|---|--------|-----------|------|
| I1 | **Minimal Core 계약** | 자동 | `title` · `category` · `workId` 필수 ([locale-catalog-policy](locale-catalog-policy.md)) |
| I2 | **externalId 선검증** | 자동 | tmdb/steam id **양수·중복 ingress** — URV exactId 축 |
| I3 | **poster–ID 정합** | 자동 | TMDB poster 시 `resolveTmdbId` + `isPosterVerified` ([poster_verification.dart](../tool/poster_verification.dart)) |
| I4 | **stub 희석 감시** | 수동·주기 | G1 insert 시 Coverage rate **하락** 추적 (A2 — [phase2-late-stage-plan](phase2-late-stage-plan.md)) |

**실패 시:** insert는 허용(stub-first)하되 **enrich queue·Coverage KPI**에 즉시 반영 — **Quality FAIL은 insert 차단이 아님**.

### 4.2 enrich 후 (배치·Sprint·PR)

| # | 게이트 | 자동/수동 | 내용 |
|---|--------|-----------|------|
| E1 | **invalid-en 가드** | 자동 | `_isValidEnTitle` — `#=` · `{{` · `dataItem` · 한글 in `titles.en` **거부** |
| E2 | **출처 매칭** | 자동 | `tmdb_fetch`: `titlesMatchWork` / `_plausibleEn` · `steam_fetch`: non-empty + 가드 |
| E3 | **fallback 체인** | 자동 | auto 실패 시 semi로 **낙하** — tmdb 단독 success 금지 (Sprint 03 remediate 교훈) |
| E4 | **registry_builder** | 자동 | shard·`search_index` 재생성 |
| E5 | **Coverage KPI** | 자동 | `coverage_dashboard.dart` — **수량** 스냅샷 |
| E6 | **회귀** | 자동 | `sw1_a_validation.dart` · `urv_a_validation.dart` — **≥ Sprint 03 baseline** |
| E7 | **invalid-en 스캔** | 자동 | shard 전수: `titles.en` 가드 재적용 · `dataItem` 패턴 **0건** |
| E8 | **spot-check** | 수동 | auto tier **N%** · semi `legacy_slug` **샘플** · heuristic vs 공식 표기 |

**실패 시:** shard **미반영** 또는 remediate 재실행 — E6 회귀 하락 시 **배치 롤백** (구조 변경 없이 patch revert).

### 4.3 release 전 (registry → assets · 앱·배포)

| # | 게이트 | 자동/수동 | 내용 |
|---|--------|-----------|------|
| R1 | **Panel Quality** | 자동 | GAP · alias · subtitle panel **≥ 90%** ([canonical-identity-coverage-dashboard](canonical-identity-coverage-dashboard.md)) |
| R2 | **회귀 하한** | 자동 | SW1 recall@10 · URV convergence **≥ 100%** (Sprint 01 이후 baseline) |
| R3 | **invalid-en 0** | 자동 | E7 전 registry 동일 |
| R4 | **연속 스냅샷** | 수동 | panel PASS **2회 연속** (Phase 2 Charter §6) |
| R5 | **manifest sync** | 자동 | `registry_builder --sync-assets` · manifest sha 일치 |

**실패 시:** **release 보류** — Coverage 수량만으로 release 하지 않음.

### 4.4 게이트 흐름

```
insert (I1–I4)
    ↓
enrich batch
    ↓
E1–E3 (per-work) → E4 → E5 Coverage KPI
    ↓
E6 회귀 · E7 invalid scan
    ↓
E8 spot-check (semi/auto)
    ↓
R1–R5 release
```

---

## 5. 자동 검증 가능한 항목

기존 도구·규칙으로 **추가 구조 없이** 실행 가능한 항목.

### 5.1 title consistency

| 검증 | 구현·도구 | 통과 조건 |
|------|-----------|-----------|
| `titles.en` non-empty 가드 | `_isValidEnTitle()` | 템플릿·한글 혼입 **0건** |
| TMDB 매칭 | `titlesMatchWork()` · `_plausibleEn()` | auto tier 채택 시 **match 또는 plausible latin** |
| `titles.ko` 보존 | enrich 시 `titles.ko` ← `title` (Sprint 03) | ko **덮어쓰기 없음** |
| normalize 비교 | `normalizeTitle()` ([dedupe_utils.dart](../tool/dedupe_utils.dart)) | alias·subtitle panel **히트** |

### 5.2 alias consistency

| 검증 | 구현·도구 | 통과 조건 |
|------|-----------|-----------|
| Panel alias | `coverage_dashboard` alias panel | **≥ 90%** |
| SW1 alias bucket | `sw1_a_validation` | recall@10 **≥ baseline** |
| 중복 alias | enrich 시 set merge (Sprint 01) | 동일 alias **중복 삽입 없음** |

### 5.3 externalId validity

| 검증 | 구현·도구 | 통과 조건 |
|------|-----------|-----------|
| TMDB id parse | `resolveTmdbId()` | 양수 정수 |
| Poster–TMDB | `isPosterVerified()` | TMDB host poster는 id+캐시 **일치** |
| Steam app id | `posterPath` / legacy regex | id 추출 가능 시에만 `steam_fetch` |
| URV exactId | `urv_a_validation` | exactId ingress **100%** 유지 |

---

## 6. 수동 검수 필요한 항목

자동 게이트만으로 **불충분**하다고 Sprint 03이 확인한 영역.

| # | 항목 | 이유 | 권장 시점 |
|---|------|------|-----------|
| M1 | **`legacy_slug` 공식 표기 대조** | 휴리스틱 humanize — SW1 미커버 쿼리·브랜드 표기 | E8 · semi cohort **100% 샘플** (소량) 또는 **10%** (대량) |
| M2 | **`tmdb_fetch` 시즌/극장판 구분** | 동일 IP 다른 시즌 ID 혼동 | auto tier **100% spot-check** (Sprint 03: 31건 교훈) |
| M3 | **Steam 지역화·부제** | store HTML 지역·번들명 | game auto **샘플 검수** |
| M4 | **linguistic·stylistic QA** | `titles.en`이 검색 가능 ≠ **공식 영문** | release 전 **panel 외** 샘플 |
| M5 | **franchise_copy 전파** | peer 오염 연쇄 | franchise 그룹 단위 **1 peer 검수** |
| M6 | **curated_manual** | `wk_000000253` 등 수동 맵 | **100%** maintainer 확인 |
| M7 | **쿼리 세트 한계** | SW1 100%가 **402·87 쿼리** 범위 | 쿼리 확대 시 **재기준** 필요 (수동 정책) |

**spot-check SLA (권장·미실측):**

| bucket | 샘플률 |
|--------|--------|
| auto (`tmdb_fetch` · `steam_fetch`) | **≥10%** (사고 전까지) · 사고 후 배치 **100%** |
| semi (`legacy_slug` · `latin_title`) | **≥5%** 또는 cohort **≤20건이면 100%** |
| manual (`curated_manual`) | **100%** |

---

## 7. Coverage KPI와 Quality KPI 분리

### 7.1 정의

| 층 | 질문 | 측정 예 | 도구 |
|----|------|---------|------|
| **Coverage KPI** | 값이 **있는가?** | `titles.en` rate **91.5%** | `coverage_dashboard` registry-wide · panel |
| **Quality KPI** | 있는 값이 **믿을 만한가?** | invalid-en **0건** · auto spot-check pass · poster verified rate | E7 스캔 · `poster_verification` · 수동 샘플 |

**분리 이유:** Sprint 03 — Coverage **91.5%** 달성과 동시에 **31건** Quality FAIL 가능. Phase 2 후반은 **Coverage 단독 PASS로 release 금지**.

### 7.2 Quality KPI 제안 (운영·문서 수준)

> 신규 스키마·ADR 없음 — 기존 산출물·체크리스트로 측정.

| ID | Quality KPI | 정의 | Sprint 03 baseline | 게이트 |
|----|-------------|------|--------------------|--------|
| **Q1** | **invalid-en rate** | `titles.en` 중 `_isValidEnTitle` FAIL 비율 | remediate 후 **0%** | E7 · R3 |
| **Q2** | **regression floor** | SW1 · URV · GAP panel | **100%** | E6 · R2 |
| **Q3** | **auto-tier spot-check pass** | M1–M3 샘플 중 maintainer **accept** | 미기록 (프로세스 신규) | E8 |
| **Q4** | **poster–externalId coherence** | TMDB poster verified 비율 (subset) | 기존 `posterVerified` 플래그 | I3 |
| **Q5** | **enrich method auditability** | `extensions.coverageSprint03`(또는 후속 method key) **100%** auto/semi | Sprint 03 적용분 | E8 추적 |

### 7.3 의사결정 규칙

| 상황 | Coverage KPI | Quality KPI | 조치 |
|------|:------------:|:-------------:|------|
| 둘 다 PASS | ✅ | ✅ | release (R1–R5) |
| Coverage ↑ · Quality FAIL | ✅ | ❌ | **release 보류** · remediate · 가드 강화 |
| Coverage 정체 · Quality PASS | ❌ | ✅ | enrich 계속 · **release 가능** (회귀 유지 시) |
| 둘 다 FAIL | ❌ | ❌ | 배치 중단 · 원인 분류 (§3) |

### 7.4 기존 Coverage Dashboard와의 관계

[canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md)는 **Coverage 층**만 정의한다. Quality KPI는 **본 문서 + 게이트 체크리스트**로 운영하며, 향후 `coverage_dashboard`에 **Q1 invalid-en** 같은 파생 지표를 **추가할 수 있음** — 구조 변경이 아닌 **도구 출력 확장** (실행은 별도 작업).

---

## 8. Sprint 03 교훈 → 운영 정책

| 교훈 | 정책 |
|------|------|
| TMDB **31건** 오염 | `tmdb_fetch` 단독 success **금지** — E1·E2·E3 **필수** |
| remediate **101/101** | invalid-en 스캔 **배치 후 필수** (E7) |
| SW1 **100%** 유지 | Quality FAIL이어도 **현 쿼리**는 통과 가능 — **Q3·M7**로 한계 명시 |
| auto+semi **100%** | **수동 0건** ≠ **검수 0건** — E8·M1–M2 **필수** |

---

## 9. 문서 맵

| 문서 | 역할 |
|------|------|
| [coverage-quality-governance.md](coverage-quality-governance.md) | **본 문서** — Quality 거버넌스 |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Coverage KPI |
| [phase2-late-stage-plan.md](phase2-late-stage-plan.md) | P0 QA 검증 질문 |
| [phase2-mid-review.md](phase2-mid-review.md) | Sprint 03 품질 리스크 근거 |
| [phase2-charter.md](phase2-charter.md) | Phase 2 종료·워크플로 |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Sprint 01~03 확인 리스크만 반영 (실험·구조 변경 없음) |
