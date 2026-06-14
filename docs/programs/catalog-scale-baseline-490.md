# Catalog Scale Baseline @490

> **측정:** 2026-06-14 · `dart run tool/catalog_scale_baseline.dart`  
> **용도:** Phase 2.1~2.3 착수 **trigger** 비교

| 지표 | akasha-db | assets/registry |
|------|-----------|-----------------|
| entryCount | 490 | 490 |
| shardBits | 8 | 8 |
| shard files | 382 | 382 |
| shards total | 274.6 KB | 274.6 KB |
| search_index entries | 490 | 490 |
| search_index size | 318.0 KB | 318.0 KB |
| search_index parse | 9 ms | 4 ms |

## Phase 2 trigger (architecture-evolution-phases §12)

| 조건 | @490 | 착수 |
|------|------|------|
| search_index parse > 50ms | 9 ms | ❌ |
| entryCount > 1000 | 490 | ❌ |
| assets/registry > 15MB | ~0.6 MB | ❌ |

**판정:** Phase 2.1~2.3 **보류** — G1 insert 후 **재측정**.
