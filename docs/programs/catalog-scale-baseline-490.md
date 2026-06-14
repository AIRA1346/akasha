# Catalog Scale Baseline @2008

> **2026-06-14** · **2008작** · preflight ✅ · G1 ~40% · **2000 milestone ✅**

## 측정

| 항목 | 값 |
|------|-----|
| entryCount | **2008** |
| shard files | 1113 |
| search_index parse | watch (≤50ms) |
| assets total | ~1.03 MB |

| Phase 2 트리거 | 상태 |
|----------------|------|
| entryCount >1000 | ✅ |
| browse full load | ✅ (<2500 threshold) |
| APK >15MB | ❌ 여유 |

## Discovery (1735 → 2008, +273)

- offset 420~490 + **webtoon 재개** (offset 0~60)
- **webtoon fix**: SPARQL P31에서 manga series(Q21198342) 제외 → dedupe-only 구간 해소

## ingest

- `_sanitizeTitlesEn`: CJK · too_short en

## 다음 offset

webtoon 75 · manga 1050 · drama 495 · game 495 · animation 505 · movie 480 · book 480

## 후속

1. Discovery → G1 5k
2. **2500** 도달 시 browse 윈도우 모드 전환 검증
3. merge backfill (Wikidata 안정 시)
