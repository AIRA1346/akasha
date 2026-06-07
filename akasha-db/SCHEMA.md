# akasha-db Schema

현재 버전: **v3** (`manifest.json` → `"version": 3`)

상세 정책: [docs/locale-catalog-policy.md](../docs/locale-catalog-policy.md)

## Work entry (shard JSON)

| 필드 | 필수 | 설명 |
|------|------|------|
| `workId` | ✅ | 마스터 형식 식별자 |
| `title` | ✅* | 레거시 단일 제목 (*`titles`만 있어도 됨) |
| `titles` | | `{ "ko", "en", "ja", "romaji", "native", "zh" }` |
| `aliases` | | 검색용 별칭 배열 |
| `externalIds` | | `{ "anilist", "steam", "isbn", ... }` |
| `category` | ✅ | manga · animation · game · book · movie · drama |
| `domain` | ✅ | subculture · generalCulture |
| `extensions` | | 레거시 확장 (v3에서 `externalIds`로 승격 권장) |

## search_index.json (빌드 산출)

- `searchTokens`: 교차 언어 검색 (빌드 시 생성, 샤드에 저장 안 함)
- `titles`: 샤드에 있을 때만 인덱스에 포함

## 카탈로그 정책 (법무)

정책 마스터: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)

- **AniList API bulk 시드 금지** — `seedSource: anilist_popularity`, `-a{id}` 슬러그
- 신규 작품은 **수동 큐레이션 PR**만
- 설명은 **자체 1~2문장**; 외부 시놉시스 복제 금지
- 포스터: URL 링크만 (`posterPath`). [POSTER_POLICY.md](POSTER_POLICY.md)

## 도구

```bash
dart run tool/purge_anilist_bulk.dart       # dry-run / --apply
dart run tool/migrate_registry_v3.dart      # 샤드 titles/externalIds 승격
dart run tool/registry_builder.dart --sync-assets
dart run tool/ci_registry_check.dart
```
