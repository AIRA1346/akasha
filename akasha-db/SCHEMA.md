# akasha-db Schema

## 현재 (v4)

`manifest.json` → `"version": 4`, `"shardBits": 8`  
샤딩: **해시 기반** (`shards/{category}/{hh}.json`, `hash(wk_)%256`)  
규모: **430작** / **331 sparse 버킷** (Steam v1 엄선)

데이터 권리 (최상위): [docs/data-policy.md](../docs/data-policy.md)  
상세 정책: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)  
아키텍처 로드맵: [docs/strategy/data-architecture-redesign.md](../docs/strategy/data-architecture-redesign.md)  
**Wikidata spine:** [docs/strategy/wikidata-spine-plan.md](../docs/strategy/wikidata-spine-plan.md)

### Registry Minimal Core (등록 최소)

`workId` + `title` + `category` + (`releaseYear` 또는 `externalIds`) + (`creator` 권장).  
`tags`는 선택. **`description`·`posterPath`는 Tier 1 금지** (v1, null만 허용·신규 추가 ❌). 상세: [data-policy.md §1.2](../docs/data-policy.md#12-registry-minimal-core-필수-영구-저장)

### Work entry (shard JSON)

| 필드 | 필수 | 설명 |
|------|------|------|
| `workId` | ✅ | 마스터 형식 `wk_000000042` (9자리) |
| `legacyIds` | | 옛 `sub_*` / `gen_*` ID 배열 |
| `title` | ✅* | 레거시 단일 제목 (*`titles`만 있어도 됨) |
| `titles` | | `{ "ko", "en", "ja", "romaji", "native", "zh" }` |
| `aliases` | | 검색용 별칭 배열 |
| `posterPath` | | **v1 Tier 1 금지** — `null`만 (CI `tier1_poster`) |
| `description` | | **v1 Tier 1 금지** — Sanctum vault Markdown만 |
| `externalIds` | | **`wikidata` (spine, 권장)** · `steam` · `tmdb` · `mal` · `isbn` … (`anilist` 신규 ❌) |
| `wikidataRelations` | | `[{ "p": "P144", "target": "Q24862683" }]` — P-id·Q-id만 |
| `category` | ✅ | manga · animation · game · book · movie · drama · webtoon |
| `domain` | ✅ | subculture · generalCulture |
| `extensions` | | 레거시 확장 · **`seasons[]`** (애니 시즌 Q-id 메타) |
| `qualitySignals` | | **원본** 품질 신호만 저장 (`tier`·`score` 저장 금지) |

#### Wikidata spine (v4.1)

```json
{
  "externalIds": { "wikidata": "Q24862683" },
  "wikidataRelations": [
    { "p": "P144", "target": "Q24862683" }
  ],
  "extensions": {
    "seasons": [
      { "label": "season 1", "releaseYear": 2019, "wikidata": "Q105847391" }
    ]
  }
}
```

- Q-id 형식: `Q` + 10진수 (`^Q\d+$`) · CI `data_policy_linter`
- 시즌별 `wk_` 기본 **금지** — [canonicalization-policy.md](../docs/policy/canonicalization-policy.md)

#### franchise_groups v2+

| 필드 | 설명 |
|------|------|
| `externalIds.wikidata` | media franchise Q (예: 귀멨 Q105037706) |
| `displayNames` | IP 다국어 명 |
| `members` | 매체별 `wk_` |

#### qualitySignals (shard — 원본만)

```json
{
  "qualitySignals": {
    "hasPoster": false,
    "hasDescription": false,
    "externalIdVerified": false,
    "franchiseVerified": false
  }
}
```

- `hasPoster` / `hasDescription`: **v1 deprecated** — Tier 1에 poster·description 없음
- `externalIdVerified`: 파이프라인·Contribution merge 시 설정
- `franchiseVerified`: 생략 시 `franchise_groups` 멤버십으로 유도 가능
- **`qualityScore` / `qualityTier`는 shard에 저장하지 않음** — `registry_builder`가 계산

점수 (0–100, 파생): 제목 25 · 연도 15 · creator 15 · externalId 25 · 검증 20 (verified 신호 4×5)

tier (파생): 0–19→0, 20–39→1, 40–59→2, 60–79→3, 80–94→4, 95+→5

**Canonicalization**(franchise·edition·dedupe)은 Quality와 **독립 축** — [canonicalization-policy.md](../docs/policy/canonicalization-policy.md)

### search_index.json (빌드 산출)

- `searchTokens`: 교차 언어 검색 (빌드 시 생성)
- `titles`: 샤드에 있을 때만 인덱스에 포함
- `qualityScore`, `qualityTier`: 빌드 시 계산 (검색 랭킹용; 향후 `search/` 샤드에도 동일 필드)

---

## v3 → v4 전환 (완료)

| 항목 | v3 (이전) | v4 (현재) |
|------|-----------|-----------|
| **workId** | `sub_manga_one-piece_1997` | **`wk_000012345`** (9자리, 불변) |
| **legacy** | — | `legacy_aliases.json` + 샤드 `legacyIds` |
| **샤드 키** | 슬러그 첫 글자·연대 | **`sha256(wk_)[0] % 256`** → `{hh}.json` |
| **manifest** | `version: 3` | `version: 4`, `shardBits: 8`, per-shard `sha256` |

전환 기록: [docs/archive/v4-migration-plan.md](../docs/archive/v4-migration-plan.md)

### id_registry.json

```json
{
  "wk_000000042": {
    "category": "manga",
    "legacyIds": ["sub_manga_one-piece_1997"]
  }
}
```

---

## 카탈로그 정책 (법무)

- **AniList API bulk 시드 금지**
- 신규 작품: 수동 PR + (장기) Registry Pipeline
- **`description`·`posterPath`:** Tier 1 **금지** — [POSTER_POLICY.md](POSTER_POLICY.md) · [product-vision.md](../docs/product-vision.md)
- 중복: [canonicalization-policy.md](../docs/policy/canonicalization-policy.md)

---

## 도구

```bash
cd ..  # akasha 앱 루트
dart run tool/registry_builder.dart --sync-assets
dart run tool/ci_registry_check.dart
dart run tool/data_policy_linter.dart
dart run tool/franchise_linter.dart
dart run tool/dedupe_linter.dart
# Contribution → Quality Loop (fixWork 승인 반영)
# dart run tool/merge_catalog_contribution.dart --id <id> --apply
# dart run tool/retire_work_ids.dart --survivor=wk_xxx --retire=wk_yyy --apply
dart run tool/manifest_v4_check.dart
# (일회성) dart run tool/migrate_shards_v3_to_v4_hash.dart --apply
```
