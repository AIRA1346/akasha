# akasha-db Schema

## 현재 (v4)

`manifest.json` → `"version": 4`, `"shardBits": 8`  
샤딩: **해시 기반** (`shards/{category}/{hh}.json`, `hash(wk_)%256`)  
규모: **402작** / **331 sparse 버킷** (Steam v1 엄선)

상세 정책: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)  
아키텍처 로드맵: [docs/data-architecture-redesign.md](../docs/data-architecture-redesign.md)

### Work entry (shard JSON)

| 필드 | 필수 | 설명 |
|------|------|------|
| `workId` | ✅ | 마스터 형식 `wk_000000042` (9자리) |
| `legacyIds` | | 옛 `sub_*` / `gen_*` ID 배열 |
| `title` | ✅* | 레거시 단일 제목 (*`titles`만 있어도 됨) |
| `titles` | | `{ "ko", "en", "ja", "romaji", "native", "zh" }` |
| `aliases` | | 검색용 별칭 배열 |
| `posterPath` | | `https://...` URL 또는 `null` |
| `externalIds` | | `{ "anilist", "steam", "tmdb", "isbn", ... }` |
| `category` | ✅ | manga · animation · game · book · movie · drama · webtoon |
| `domain` | ✅ | subculture · generalCulture |
| `extensions` | | 레거시 확장 (`externalIds`로 승격 권장) |

### search_index.json (빌드 산출)

- `searchTokens`: 교차 언어 검색 (빌드 시 생성)
- `titles`: 샤드에 있을 때만 인덱스에 포함

---

## v3 → v4 전환 (완료)

| 항목 | v3 (이전) | v4 (현재) |
|------|-----------|-----------|
| **workId** | `sub_manga_one-piece_1997` | **`wk_000012345`** (9자리, 불변) |
| **legacy** | — | `legacy_aliases.json` + 샤드 `legacyIds` |
| **샤드 키** | 슬러그 첫 글자·연대 | **`sha256(wk_)[0] % 256`** → `{hh}.json` |
| **manifest** | `version: 3` | `version: 4`, `shardBits: 8`, per-shard `sha256` |

전환 기록: [docs/v4-migration-plan.md](../docs/v4-migration-plan.md)

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
- 설명: **자체 1~2문장**; 외부 시놉시스 복제 금지
- 포스터: URL 링크만 — [POSTER_POLICY.md](POSTER_POLICY.md)
- 중복: [canonicalization-policy.md](../docs/canonicalization-policy.md)

---

## 도구

```bash
cd ..  # akasha 앱 루트
dart run tool/registry_builder.dart --sync-assets
dart run tool/ci_registry_check.dart
dart run tool/franchise_linter.dart
dart run tool/dedupe_linter.dart
# dart run tool/retire_work_ids.dart --survivor=wk_xxx --retire=wk_yyy --apply
dart run tool/manifest_v4_check.dart
# (일회성) dart run tool/migrate_shards_v3_to_v4_hash.dart --apply
```
