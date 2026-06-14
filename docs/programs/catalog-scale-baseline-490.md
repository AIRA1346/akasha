# Catalog Scale Baseline @1735

> **2026-06-14** · **1735작** · preflight ✅ · G1 ~35%

## 측정

| 항목 | 값 |
|------|-----|
| entryCount | **1735** |
| shard files | 1027 |
| search_index parse | 7–14 ms |
| assets total | ~903 KB (~0.88 MB) |

## Discovery (1447 → 1735, +288)

offset 285~405 · Wikidata **간헐 503/타임아웃** → retry/skip

| 카테고리 | 비고 |
|----------|------|
| drama/game/movie/book | 정상 공급 |
| manga | merge skip 多 |
| **webtoon** | offset 0·30 **wouldCreate=0** — 채널/쿼리 조사 필요 |

## ingest

- `_sanitizeTitlesEn`: CJK in en · **too_short en 제거**
- wk_1669 `V` → `V (TV series)`

## merge backfill

- offset 0–300 시도 → **Wikidata SPARQL 503** — **보류** (야간/소구간 재시도)

## 다음 offset

manga 975 · drama 420 · game 420 · animation 430 · movie 405 · book 405

## 마일스톤

| 목표 | 진행 |
|------|------|
| G1 5k | 35% |
| 2000 | 87% (1735) |
| 2500 browse 윈도우 전환 | 여유 |
