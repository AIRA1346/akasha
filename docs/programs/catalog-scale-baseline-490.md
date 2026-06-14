# Catalog Scale Baseline @2859

> **2026-06-14** · **2859작** · preflight ✅ · G1 ~57% · **2500 window 전환 ✅**

## 측정

| 항목 | 값 |
|------|-----|
| entryCount | **2859** |
| shard files | 1351 |
| search_index parse | watch (≤50ms) |
| assets total | watch (~1.5 MB) |

| Phase 2 트리거 | 상태 |
|----------------|------|
| entryCount >1000 | ✅ |
| browse full load | ❌ **>2500 → window 모드** |
| browse window prefetch | ✅ ~242 loaded @2859 |
| APK >15MB | ❌ 여유 |

## Discovery (2008 → 2859, +851)

- 10+ rounds `wikidata_ko_trial --category all --limit 20 --apply`
- drama·movie·webtoon 채널 고yield

## ingest

- cursor 자동 갱신 (`--offset` 포함)

## 다음 offset (post-run cursors)

cursor 파일 SSOT — `akasha-db/pipeline/discovery/cursors/wikidata_ko_*.json`

## 후속

1. Discovery → G1 5k
2. **browse window dogfood** @2859 (loadMore · 카테고리 필터)
3. Phase 2.3 manifest-only / eager bundle (ADR-010)
4. merge backfill (Wikidata 안정 시)
