# AKASHA 포스터 정책 (v1 Steam)

> **마스터 정책:** [docs/data-policy.md](../docs/data-policy.md) §0.3  
> **코드 SSOT:** `lib/config/catalog_poster_policy.dart`

## v1 핵심

**AKASHA(Tier 1)는 포스터 URL을 제공하지 않습니다.**

| 계층 | 포스터 |
|------|--------|
| **글로벌 사전 (akasha-db)** | `posterPath` **금지** · CI `tier1_poster` |
| **Sanctum vault (유저)** | YAML `poster:` (https URL) · `posters/` 로컬 파일 |

앱은 Tier 1 카드를 **카테고리 플레이스홀더**로 표시합니다.  
아카이브한 작품만 유저가 넣은 이미지가 보입니다.

## 유저 볼트 (Tier 2)

- **로컬:** `{Vault}/posters/` — 사용자 업로드 (YAML `poster: posters/...`)
- **URL:** 사용자가 직접 입력한 `https://...` (개인 기록용)
- Registry 기본 URL은 YAML에 **저장하지 않음** (`MarkdownParser.shouldPersistPosterToYaml`)

**유저 책임:** 권리를 보유한 이미지만 사용. AKASHA는 이미지를 호스팅·큐레이션하지 않습니다.

## Tier 1에서 하지 않는 것

- TMDB / AniList / Steam CDN URL을 `akasha-db` shard·`search_index`에 저장
- `registry_builder`가 search_index에 `posterPath` 복제
- 앱이 `WorksRegistry.resolvePosterPath()`로 Tier 1 포스터 fusion

## CI·도구

```bash
dart run tool/strip_tier1_posters.dart --apply --sync-assets
dart run tool/data_policy_linter.dart --strict
dart run tool/registry_builder.dart --sync-assets
```

| rule | 내용 |
|------|------|
| `tier1_poster` | shard·search_index에 `posterPath` 있으면 **error** |

## search_index

v1부터 `search_index.json` 항목에 **`posterPath` 필드 없음** (lazy load 시에도 Tier 1 포스터 미사용).

## 앱 동작

- `Image.network` — **유저 아이템** URL만
- `SafeLocalImage` — vault `posters/` 상대경로
- 실패·미설정 → `CategoryPosterPlaceholder` (제목·카테고리 아이콘)

## 기여자 (akasha-db PR)

- 신규·수정 PR에 **`posterPath` 추가 금지**
- `externalIds` (tmdb, steam, mal 등)는 **Fact** — 포스터 URL attach **하지 않음**

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | v1 Steam — Tier 1 포스터 전면 미제공, 유저 Sanctum vault 전용 |
