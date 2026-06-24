# tool/migrations

완료된 스키마·데이터 마이그레이션 스크립트 보관용입니다. **신규 DB에는 적용하지 마세요.**

실행 예 (레거시 DB 복구 시에만):

```bash
dart run tool/migrations/migrate_registry_v3.dart --dry-run
dart run tool/migrations/migrate_shards_v3_to_v4_hash.dart --dry-run
```

## 보관 파일

| 스크립트 | 비고 |
|----------|------|
| `migrate_registry_v3.dart` | v3 monolithic → 샤드 메타 |
| `migrate_shards_v3_to_v4_hash.dart` | v4 해시 샤딩 |
| `migrate_wk_pad9.dart` | wk_ ID 패딩 |
| `sync_legacy_works_registry.dart` | 구 works_registry 동기화 |
| `migrate_manga_to_webtoon.dart` | manga → webtoon 카테고리 |

루트 `tool/` 유틸(`wk_id_utils.dart`, `registry_hash_utils.dart` 등)은 `../`로 import합니다.
