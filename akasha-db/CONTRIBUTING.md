# AKASHA-DB 기여 가이드

Rune Atelier **자체 작품 사전**을 수동 큐레이션·PR로 확장하는 저장소입니다.

> **현재:** v4 해시 샤드, **430작** 엄선  
> **장기:** 전 작품 사전 + `wk_` ID + 해시 샤딩 — [docs/strategy/data-architecture-redesign.md](../docs/strategy/data-architecture-redesign.md)  
> **마스터 정책:** [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)

## 빠른 시작

1. `shards/{category}/` 아래 적절한 샤드 JSON 파일을 수정하거나 새 샤드를 추가합니다.
2. `workId`는 [SCHEMA.md](SCHEMA.md) 규칙을 따릅니다 (v4에서 `wk_`로 전환 예정).
3. 로컬 검증:

```bash
cd ../  # akasha 앱 루트
dart run tool/registry_builder.dart --sync-assets
dart run tool/ci_registry_check.dart
```

4. PR을 엽니다.

## 앱 유저 제안 (카탈로그 기여)

AKASHA 앱 **「글로벌 사전에 추가 제안」** / **「정보 수정 제안」** 으로 들어온 JSON 번들은
[contributions/README.md](contributions/README.md) 흐름으로 검수합니다.

```bash
dart run tool/apply_catalog_contributions.dart --import path/to/bundle.json
```

자동 shard merge는 없습니다. inbox 검토 후 수동 반영하세요.

## 작품 1건 추가 체크리스트

- [ ] `workId`가 기존 항목과 **중복되지 않음** (동일 작품·externalId 재확인)
- [ ] `category` / `domain` enum 값 준수
- [ ] **`description`·`posterPath` 추가 금지** (v1 — [POSTER_POLICY.md](POSTER_POLICY.md) · [product-vision.md](../docs/product-vision.md))
- [ ] 같은 IP의 다른 매체는 `franchise_groups.json` 확인
- [ ] `registry_builder` + `ci_registry_check` 통과

## 샤딩 규칙 (v3 — 현재)

| 카테고리 | 샤드 네이밍 예 |
|----------|----------------|
| manga | `manga_K.json` (슬러그 첫 글자) |
| animation | `animation_2020s.json` (연대) 또는 `animation_F.json` |
| game | `game_A.json` 또는 `game_steam_124.json` |
| book / movie / drama / webtoon | 제목 슬러그 첫 글자 |

한 샤드 파일이 **~500KB**를 넘기면 분할 PR을 권장합니다.

**v4 (계획):** `shard_{hash(wk_)%256}.json` — 슬러그 샤드 deprecated.

## 중복·정체성

- 동일 `externalIds`·유사 제목이 있으면 **새 workId 추가 전** 기존 항목 확인
- 자세한 규칙: [docs/policy/canonicalization-policy.md](../docs/policy/canonicalization-policy.md)

## 저작권

- Tier 1 메타데이터: **Fact만** (제목, 작가, 연도, ID, aliases, tags).
- **`description`·포스터:** Tier 1 금지 — 유저 Sanctum vault에만.
- AniList/TMDB API로 메타·이미지를 **자동 bulk 수집**하지 마세요.
