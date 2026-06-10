# AKASHA Data Policy — 데이터 권리·저장 정책

> **상태:** v1.1 (2026-06-10)  
> **지위:** Discovery·Expansion·Registry 설계의 **최상위 정책**  
> **제품 SSOT:** [product-vision.md](product-vision.md)  
> **전제:** AKASHA 목표는 **「작품 발견」** 이지 **「외부 DB 복제」** 가 아니다.

**이 문서보다 하위:** [akasha-db-policy.md](akasha-db-policy.md) · [discovery-policy.md](discovery-policy.md) · [catalog-ownership.md](catalog-ownership.md) · [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) · [canonicalization-policy.md](canonicalization-policy.md)

> 아래는 **변호사 자문이 아닌** 1인 스튜디오 실무 판단입니다. Steam 상업 배포·대규모 ingest 전 현지 IP 전문가 검토를 권장합니다.

---

## 0. 설계 최상단 원칙

### 0.1 Discovery ≠ Database Mirroring

```
외부 서비스 카탈로그          AKASHA Registry
─────────────────────        ─────────────────
AniList 68만 작품      ≠      AKASHA 100만 작품
TMDB 전체 export       ≠      AKASHA 영구 JSON
```

| 원칙 | 내용 |
|------|------|
| **발견** | Discovery는 「이 작품이 존재한다」는 **신호**만 수집 |
| **미러링 금지** | API 응답·시놉·이미지·리뷰를 **그대로 Git에 적재하지 않음** |
| **법무 게이트** | Registry 영구 저장 **전** 필드별 정책(본 문서) 통과 |
| **AKASHA 소유** | Registry에 남는 텍스트·메타는 **AKASHA가 작성·가공**한 것 |

```
Discovery Signal (일회성, Git X)
  → Legal Field Gate (본 정책)
  → Registry Minimal Core (Facts만)
  → Enrich (AI·유저, 선택)
  → Quality / Canonicalization (독립 축)
```

### 0.2 Signal vs Registry

| | Discovery Signal | Registry (akasha-db) |
|--|------------------|----------------------|
| 수명 | 일회성·TTL | 영구 |
| 저장 | 메모리·CI artifact | GitHub + CDN |
| 내용 | raw title, source id, year hint | **정책 통과 필드만** |
| raw API response | **금지** | **금지** |

---

## 1. 필드 분류 체계

모든 외부·내부 필드는 다음 네 범주 중 하나로 분류한다.

| 분류 | 정의 | Registry 영구 저장 |
|------|------|-------------------|
| **Fact** | 저작권이 없는 사실 정보 (제목·연도·식별자·창작자명) | ✅ 기본 허용 |
| **Licensed Content** | 제3자가 라이선스 조건과 함께 제공하는 콘텐츠 (TMDB 이미지, Steam asset URL) | ⚠️ **조건부** (링크만·약관 준수) |
| **Copyright Risk** | 창작적 표현·시놉·공식 마케팅 문구·이미지 바이너리 | ❌ 복제 금지; AKASHA 자체 작성 또는 링크 참조만 |
| **User Generated** | VNDB 설명·위키·유저 리뷰·Contribution | ⚠️ 사전(Tier 1) 직접 복제 금지; Tier 2 볼트·검증 후 반영 |

### 1.1 Registry 필드 매트릭스 (일반)

| 필드 | 분류 | Registry 저장 | 비고 |
|------|------|:-------------:|------|
| `workId` | Fact | ✅ | AKASHA 발급 `wk_` |
| `title` | Fact | ✅ | 공식·통용명 (사실) |
| `titles.{ko,en,ja,…}` | Fact | ✅ | 다언어 정식명 |
| `category` | Fact | ✅ | AKASHA taxonomy |
| `domain` | Fact | ✅ | subculture / generalCulture |
| `releaseYear` | Fact | ✅ | 사실 연도 |
| `creator` | Fact | ✅ | 작가·감독·개발사명 (사실) |
| `externalIds.*` | Fact | ✅ | 숫자·코드 참조만; **자동 fetch 근거 아님** |
| `legacyIds` | Fact | ✅ | AKASHA 내부 |
| `aliases` | Fact / UGC | ✅ | 통용 별칭; 외부 synonyms **복붙 금지** → AKASHA 선별 |
| `tags` | Copyright Risk | ⚠️ | 외부 장르 태그 복제 지양; AKASHA·Enrich·유저 작성 |
| `description` | **Tier 2 only** | ❌ | **v1: Tier 1 금지** — 유저 Sanctum vault Markdown/YAML만 |
| `posterPath` | **Tier 2 only** | ❌ | **v1: Tier 1 금지** — 유저 Sanctum vault만 ([§0.3](#03-tier-1-포스터설명-미제공-v1-steam)) |
| `qualitySignals` | Fact (AKASHA) | ✅ | 검증 상태 원본; score/tier는 파생 |
| `searchTokens` | Fact (파생) | ❌ shard | 빌드 산출만 |
| raw API JSON | Copyright Risk | ❌ | 절대 저장 금지 |
| `synopsis` / `overview` / `plot` | Copyright Risk | ❌ | Signal에서만 참고 후 폐기 |
| `review` / `rating text` | UGC | ❌ | Tier 2 볼트만 |
| cover/poster **바이너리** | Copyright Risk | ❌ | repo·번들 금지 |
| Tier 1 **`posterPath` URL** | — | ❌ | **v1 Steam: AKASHA 미제공** |

### 0.3 Tier 1 포스터·설명 미제공 (v1 Steam)

AKASHA는 **글로벌 작품 사전(Tier 1)에 이미지 URL·description을 저장·배포·표시하지 않는다.**

| 계층 | 포스터 | 설명·감상 |
|------|--------|-----------|
| **Tier 1 — akasha-db** | `posterPath` **금지** (CI `tier1_poster`) | `description` **금지** — Fact만 |
| **Tier 2 — Sanctum vault** | YAML `poster:` · `posters/` | Markdown 본문 + YAML 자유 |

**앱 동작:** `WorksRegistry.resolvePosterPath()`는 v1에서 **항상 null**. `PosterImage`는 **유저 아이템**의 URL/로컬만 표시.

**개발사 포지션:** AKASHA는 포스터·이미지를 **호스팅·큐레이션하지 않는** 개인 아카이브 도구. 이미지는 사용자가 개인 기록용으로 Sanctum vault에 넣는다.

**유저 책임:** 권리 없는 URL·파일 사용 금지 — 이용약관·About에 명시.

**정리 도구:** `dart run tool/strip_tier1_posters.dart --apply --sync-assets` · `dart run tool/strip_tier1_descriptions.dart --apply --sync-assets`

코드 SSOT: `lib/config/catalog_poster_policy.dart` · `CatalogPosterPolicy.tier1RegistryPostersEnabled = false`

---

### 1.2 Registry Minimal Core (필수 영구 저장)

**등록 최소 조건** — 아래가 있으면 Tier 0 stub으로 Registry에 들어갈 수 있다.

```json
{
  "workId": "wk_000012345",
  "title": "원피스",
  "category": "manga",
  "releaseYear": 1997,
  "creator": "오다 에이치로",
  "externalIds": { "mal": "13" }
}
```

| 필드 | 필수 | 없어도 등록 |
|------|:----:|:-----------:|
| `workId` | ✅ | — |
| `title` | ✅ | — |
| `category` | ✅ | — |
| `releaseYear` | ⚠️ | ✅ (`externalId`로 대체 가능) |
| `creator` | ⚠️ | ✅ |
| `externalIds` | ⚠️ | ✅ (최소 하나 권장) |
| `description` | — | ❌ **Tier 1 금지** (Tier 2만) |
| `tags` | — | ✅ |
| `posterPath` | — | ✅ **null 허용** |
| `titles` / `aliases` | — | ✅ |

`domain`은 category에서 유도 가능하나 명시 권장.

---

## 2. AI 역할 (Enrich 계층)

**AI는 Registry 생성기가 아니다.**

| AI가 하는 것 (Enrich) | Registry 등록 조건? |
|----------------------|:-------------------:|
| 설명 초안 (자체 문장) | ❌ 필수 아님 |
| 태그·별칭 보완 | ❌ |
| 누락 후보 추천 (Discovery 보조) | ❌ |
| 프랜차이즈 **힌트** (Canonicalization 보조) | ❌ |

| AI가 하지 않는 것 |
|-------------------|
| `title`·`releaseYear`·`externalIds` **환각 생성**으로 등록 |
| 외부 시놉 **번역·복사** |
| dedupe pass 없이 auto-merge |
| Registry 등록에 AI 텍스트 **요구** |

```
Rule Normalize (Facts) → Registry Minimal Core
                              ↓
                    enrich/queue (AI, 비동기, 선택)
                              ↓
                    Contribution (유저 검증·수정)
                              ↓
                    qualitySignals.verified* 갱신
```

---

## 3. 소스별 Discovery 필드 정책

각 소스에서 **가져올 수 있는 것** · **Registry에 남길 수 있는 것** · **Signal만 쓰고 폐기할 것**.

### 3.1 AniList (GraphQL / REST)

| AniList 필드 | 분류 | Discovery Signal | Registry 저장 | 비고 |
|--------------|------|:----------------:|:-------------:|------|
| `id` | Fact | ✅ | ✅ `externalIds.anilist` | |
| `title.romaji` / `english` / `native` | Fact | ✅ | ✅ `titles` | 사실적 작품명 |
| `synonyms` | Fact / UGC | ✅ | ⚠️ `aliases` | AKASHA 선별·중복 제거 후 |
| `startDate` / `seasonYear` | Fact | ✅ | ✅ `releaseYear` | |
| `format` (TV, MANGA, …) | Fact | ✅ | ✅ `category` 매핑 | |
| `status` (RELEASING, …) | Fact | ✅ | ❌ | Signal만 |
| `genres` | Copyright Risk | ✅ | ⚠️ `tags` | 장르 **이름**은 사실에 가깝으나 복제 최소화; AKASHA 태그 권장 |
| `tags` (콘텐츠 태그) | UGC | ✅ | ❌ | AniList 유저 태그 — 복제 금지 |
| `studios` / `staff` | Fact | ✅ | ✅ `creator` (선별) | 이름만 |
| `description` | **Copyright Risk** | ✅ 참고 | ❌ | **절대 Registry 복제**; Enrich·직접 작성 |
| `coverImage` / `bannerImage` | **Copyright Risk** | ✅ | ❌ | `anilistcdn` **신규 금지** (CI) |
| `averageScore` / `popularity` | Fact (집계) | ✅ | ❌ | 외부 DB 미러링 |
| `relations` | Fact | ✅ | ❌ | Canonicalization 힌트; franchise 수동 |
| `characters` | Copyright Risk | ✅ | ❌ | |
| `siteUrl` | Fact | ✅ | ❌ | Signal evidence |
| `isAdult` | Fact | ✅ | ❌ | 필터용 Signal |
| **전체 API response** | Copyright Risk | 일시 | ❌ | **저장 금지** |

### 3.2 TMDB (API / export)

| TMDB 필드 | 분류 | Discovery Signal | Registry 저장 | 비고 |
|-----------|------|:----------------:|:-------------:|------|
| `id` | Fact | ✅ | ✅ `externalIds.tmdb` | |
| `title` / `original_title` / `name` | Fact | ✅ | ✅ `title` / `titles` | |
| `release_date` / `first_air_date` | Fact | ✅ | ✅ `releaseYear` | |
| `genres` | Fact | ✅ | ⚠️ `tags` | 이름만; AKASHA 태그 권장 |
| `production_companies` | Fact | ✅ | ⚠️ `creator` | |
| `overview` | **Copyright Risk** | ✅ 참고 | ❌ | TMDB·권리자 표현 — **복제 금지** |
| `tagline` | **Copyright Risk** | ✅ | ❌ | |
| `poster_path` / `backdrop_path` | Licensed | ✅ | ❌ | Signal·수동 참고만; Tier 1 `posterPath` **금지** ([§0.3](#03-tier-1-포스터-미제공-v1-steam)) |
| `vote_average` / `popularity` | Fact (집계) | ✅ | ❌ | |
| `imdb_id` / `external_ids` | Fact | ✅ | ✅ `externalIds` | |
| `belongs_to_collection` | Fact | ✅ | ❌ | franchise 힌트 |
| `runtime` / `episode_count` | Fact | ✅ | ❌ | extensions 후보 |
| `credits` (cast) | Fact / Copyright | ✅ | ❌ | 이름만 Signal; 전체 크레딧 미저장 |
| **이미지 바이너리 다운로드** | Copyright Risk | ❌ | ❌ | |
| **TMDB API bulk → Git** | Licensed | ❌ | ❌ | 약관·정책 위반 위험 |

### 3.3 Open Library

| Open Library 필드 | 분류 | Discovery Signal | Registry 저장 | 비고 |
|-------------------|------|:----------------:|:-------------:|------|
| `key` / `edition_key` | Fact | ✅ | ✅ `externalIds.openlibrary` | |
| `title` | Fact | ✅ | ✅ `title` | |
| `authors` | Fact | ✅ | ✅ `creator` | |
| `first_publish_date` / `publish_date` | Fact | ✅ | ✅ `releaseYear` | |
| `isbn` / `isbn_13` | Fact | ✅ | ✅ `externalIds.isbn` | |
| `subjects` | Fact | ✅ | ⚠️ `tags` | 분류어; 선별 |
| `languages` | Fact | ✅ | ❌ | |
| `publishers` | Fact | ✅ | ❌ | |
| `number_of_pages` | Fact | ✅ | ❌ | |
| `covers` (OL cover URL) | Licensed | ✅ | ❌ | Tier 1 저장 금지; 유저 vault만 |
| `description` (IA/Wikipedia 유래) | **Copyright Risk** | ✅ 참고 | ❌ | **복제 금지** |
| **OL dump 전체 Git 적재** | Copyright Risk | ❌ | ❌ | cursor·선별 ingest만 |

### 3.4 Steam (Store / Web API)

| Steam 필드 | 분류 | Discovery Signal | Registry 저장 | 비고 |
|------------|------|:----------------:|:-------------:|------|
| `appid` / `steam_appid` | Fact | ✅ | ✅ `externalIds.steam` | |
| `name` | Fact | ✅ | ✅ `title` | |
| `release_date.date` | Fact | ✅ | ✅ `releaseYear` | |
| `developers` / `publishers` | Fact | ✅ | ✅ `creator` | |
| `genres` / `categories` | Fact | ✅ | ⚠️ `tags` | |
| `header_image` / `capsule_image` | Licensed | ✅ | ❌ | Tier 1 저장 금지; 유저 vault만 |
| `short_description` | **Copyright Risk** | ✅ 참고 | ❌ | Valve/퍼블리셔 문구 — **복제 금지** |
| `detailed_description` | **Copyright Risk** | ✅ 참고 | ❌ | HTML 마케팅 — **복제 금지** |
| `reviews` (텍스트) | UGC | ✅ | ❌ | |
| `metacritic` / `price` | Fact (집계) | ✅ | ❌ | |
| `recommendations` | Fact | ✅ | ❌ | Discovery 힌트 |
| `supported_languages` | Fact | ✅ | ❌ | |
| **Steam API bulk → Git** | Licensed | ❌ | ❌ | app list 선별만 |

### 3.5 VNDB

| VNDB 필드 | 분류 | Discovery Signal | Registry 저장 | 비고 |
|-----------|------|:----------------:|:-------------:|------|
| `id` (v1234) | Fact | ✅ | ✅ `externalIds.vndb` | |
| `title` / `alttitle` | Fact | ✅ | ✅ `title` / `titles` | |
| `aliases` | Fact | ✅ | ⚠️ `aliases` | 선별 |
| `released` | Fact | ✅ | ✅ `releaseYear` | |
| `producers` / `staff` | Fact | ✅ | ✅ `creator` | |
| `platforms` | Fact | ✅ | ❌ | category 힌트 |
| `length` | Fact | ✅ | ❌ | |
| `tags` (VNDB spoiler tags) | UGC | ✅ | ⚠️ | 커뮤니티 분류; 선별 |
| `description` | **UGC / Copyright** | ✅ 참고 | ❌ | **유저 작성 텍스트** — 복제 금지 |
| `image` (cover) | Copyright Risk | ✅ | ⚠️ | URL 정책 검토; null 허용 |
| `relations` | Fact | ✅ | ❌ | franchise 힌트 |
| `rating` / `votes` | UGC (집계) | ✅ | ❌ | |
| `extlinks` | Fact | ✅ | ❌ | evidence |

### 3.6 Wikidata (SPARQL / Entity)

| Wikidata 필드 | 분류 | Discovery Signal | Registry 저장 | 비고 |
|---------------|------|:----------------:|:-------------:|------|
| `Q-id` | Fact | ✅ | ✅ `externalIds.wikidata` | |
| `labels` / `aliases` (다언어) | Fact | ✅ | ✅ `titles` | 사실적 명칭 |
| `inception` / `publication date` (P577) | Fact | ✅ | ✅ `releaseYear` | |
| `author` / `creator` (P50, P170) | Fact | ✅ | ✅ `creator` | |
| `ISBN` / external ID (P212, …) | Fact | ✅ | ✅ `externalIds` | |
| `instance of` (P31) | Fact | ✅ | ✅ `category` 매핑 | |
| `genre` (P136) | Fact | ✅ | ⚠️ `tags` | |
| `part of the series` (P179) | Fact | ✅ | ❌ | Canonicalization |
| `description` (Wikipedia excerpt) | **Copyright Risk** | ✅ 참고 | ❌ | **복제 금지** |
| `image` (P18) | Licensed / Copyright | ✅ | ⚠️ | Commons 라이선스 **눈으로 확인** 후 URL만 |
| **SPARQL dump 전체 Git** | Fact mix | ❌ | ❌ | 쿼리·선별만 |

---

## 4. 통합 분류표 (소스 × 필드)

**범례:** R = Registry 영구 저장 | S = Signal만 (폐기) | — = 해당 없음

### Facts — Registry ✅

| 필드 | AniList | TMDB | OpenLibrary | Steam | VNDB | Wikidata |
|------|---------|------|-------------|-------|------|----------|
| 작품 ID | R `anilist` | R `tmdb` | R `openlibrary` | R `steam` | R `vndb` | R `wikidata` |
| 제목 (다언어) | R | R | R | R | R | R |
| 발표 연도 | R | R | R | R | R | R |
| 창작자/제작사명 | R | R | R | R | R | R |
| ISBN | — | — | R | — | — | R |
| IMDb 등 교차 ID | — | R | — | — | — | R |
| 카테고리 매핑 | R | R | R | R | R | R |

### Licensed Content — Registry ⚠️ (조건부)

| 필드 | AniList | TMDB | OpenLibrary | Steam | VNDB | Wikidata |
|------|---------|------|-------------|-------|------|----------|
| 포스터/커버 URL | S (cdn 금지) | R URL | R URL | R URL | ⚠️ | ⚠️ Commons |

### Copyright Risk — Registry ❌

| 필드 | AniList | TMDB | OpenLibrary | Steam | VNDB | Wikidata |
|------|---------|------|-------------|-------|------|----------|
| synopsis / overview / description | S | S | S | S | S | S |
| tagline / marketing HTML | — | S | — | S | — | — |
| cover 바이너리 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| API response 전체 | S | S | S | S | S | S |
| 캐릭터 목록·상세 플롯 | S | S | — | — | — | — |

### User Generated — Registry ❌ (Tier 2 또는 검증 후)

| 필드 | AniList | TMDB | OpenLibrary | Steam | VNDB | Wikidata |
|------|---------|------|-------------|-------|------|----------|
| 유저 태그 / 리뷰 | S | — | — | S | S | — |
| VNDB description | — | — | — | — | S | — |
| Contribution fix | — | — | — | — | — | — → R (검증 후) |

---

## 5. 구현 우선순위 (수정)

Discovery 채널 확장 **전에** 아래를 확정한다.

| 순위 | 항목 | 상태 |
|:----:|------|------|
| **1** | **Data Policy** (본 문서) | ✅ v1 |
| **2** | Registry Minimal Core + SCHEMA | ✅ [SCHEMA.md](../akasha-db/SCHEMA.md) |
| **3** | Legal-safe Field Matrix + CI gate | ✅ `tier1_poster` · `tier1_description` |
| **4** | Quality (`qualitySignals` → score) | 🔶 구현 중 |
| **5** | Canonicalization (franchise·edition) | 🔶 문서·linter |
| **6** | Discovery — **AniList cursor 1채널** | ⏳ |
| **7** | + Steam, OpenLibrary | ⏳ 10k 작품 |
| **8** | + TMDB, VNDB | ⏳ 50k~100k |
| **9** | Wikidata·웹 발견 | ⏳ 100k+ |

---

## 6. CI·파이프라인 게이트

| 게이트 | 검사 |
|--------|------|
| `data_policy_linter.dart` | 금지 필드, API blob, 텍스트 길이, poster URL, provenance |
| `ci_registry_check.dart` | 위 + registry_builder, dedupe, poster baseline |
| ingest gate (계획) | Signal → **Minimal Core만** shard insert |
| enrich gate (계획) | AI 출력 ≠ Registry 필수 조건 |

### data_policy_linter 규칙

```bash
dart run tool/data_policy_linter.dart            # 경고/에러 구분
dart run tool/data_policy_linter.dart --strict   # 경고도 실패 (CI 기본)
dart run tool/data_policy_linter.dart --contributions
# 레거시 정리: posterPath 없는 posterSource 제거
dart run tool/cleanup_poster_source.dart --apply --sync-assets
```

**레거시 정리 완료 (2026-06-08):** posterPath 없는 `posterSource` 100건 제거 →
`ci_registry_check`가 `data_policy_linter --strict` 실행 (0 error / 0 warning).

| rule | 내용 |
|------|------|
| `forbidden_top_level` | WorkEntry 허용 키 외 최상위 필드 |
| `forbidden_field` | synopsis, overview, review, tagline, coverImage, … |
| `api_blob` | AniList/TMDB형 중첩 객체 (averageScore+favourites 등) |
| `text_length` | description ≤500자, title/creator/tags 상한 |
| `description_html` | description 내 HTML (Steam/TMDB 복붙 탐지) |
| `poster_url` | denylist, self-hosted, http(s) only (**posterPath 없을 때만**) |
| `tier1_poster` | shard·search_index에 `posterPath` **금지** (v1) |
| `tier1_description` | shard에 `description` **금지** (v1) |
| `provenance` | posterSource, registeredVia, qualitySignals 키 검증 |
| `provenance_warn` | posterSource 있는데 posterPath 없음 — 레거시 정리 완료, CI는 **`--strict`** 로 실행 (0건) |
| `build_artifact` | shard 내 searchTokens 금지 |

---

## 7. 관련 문서

| 문서 | 역할 |
|------|------|
| **본 문서** | 필드·소스·법무 **최상위** |
| [akasha-db-policy.md](akasha-db-policy.md) | 운영·구축 방침 |
| [catalog-ownership.md](catalog-ownership.md) | 3계층 소유권 |
| [canonicalization-policy.md](canonicalization-policy.md) | identity·franchise (Quality와 독립) |
| [SCHEMA.md](../akasha-db/SCHEMA.md) | WorkEntry 스키마 |
| [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) | 포스터 URL |

---

## 8. 요약 한 줄

**Discovery는 신호, Registry는 Facts, Enrich는 선택, Contribution은 검증.**  
외부 DB를 복제하지 않으면서도 세상의 모든 작품에 **도달**할 수 있는 유일한 경로다.
