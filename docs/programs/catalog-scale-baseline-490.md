# Catalog Scale Baseline @1164

> **2026-06-14** · **1164작** · preflight ✅ · G1 ~23%

## 측정

| 항목 | 값 |
|------|-----|
| entryCount | **1164** |
| shard files | 811 |
| search_index v1 parse | 5–15 ms |
| search_index v2 manifest parse | 0 ms |
| assets total | ~644 KB (~0.63 MB) |

| Phase 2 트리거 | 상태 |
|----------------|------|
| entryCount >1000 | ✅ |
| search_index parse >50ms | ❌ (5–15ms) |
| APK >15MB | ❌ |

## Discovery (1006 → 1164, +158)

배치 8–10 · offset 150대~180대 · webtoon **165/180 = 0건** (ko 풀 소진 구간)

품질 수정: wk_1080 `Myeongtonggam` + zh 분리 (CJK in en)

## 앱 (Phase 2.2)

- `loadMoreCatalog` append 시 **fetchRemote await** — 원격 shard 누락 방지

## 다음 offset

manga 750 · drama 195 · game 195 · animation 205 · movie 180 · book 180 · webtoon TBD

## 후속

1. 실기기 dogfood @1164 (master_index 윈도우)
2. Discovery → G1 5k
3. merge backfill · webtoon 소스/offset 재조사
4. ingest 시 CJK→en 자동 romanization (quality gate 예방)
