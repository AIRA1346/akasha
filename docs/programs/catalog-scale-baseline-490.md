# Catalog Scale Baseline @1447

> **2026-06-14** · **1447작** · preflight ✅ · G1 ~29%

## 측정

| 항목 | 값 |
|------|-----|
| entryCount | **1447** |
| shard files | 937 |
| search_index parse | 8–14 ms |
| assets total | ~773 KB (~0.75 MB) |

## Discovery (1164 → 1447, +283)

배치 offset 195~280 · drama 255/265 일부 0건 (ko 풀 구간)

## ingest

- `trial_apply._sanitizeTitlesEn` — CJK in `titles.en` → `zh` + entityEnLabel 또는 en 생략

## 앱

- ≤2500작: master_index **전체 번들 shard** 적재 (`browseFullCatalogThreshold`)

## 다음 offset

manga 840 · drama 285 · game 285 · animation 295 · movie 270 · book 270

## 후속

1. Discovery → G1 5k
2. merge backfill
3. drama/game 소진 구간 offset probe
