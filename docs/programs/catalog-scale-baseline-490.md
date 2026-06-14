# Catalog Scale Baseline @1006

> **2026-06-14** · **1006작** · preflight ✅ · id_registry ✅ · **entryCount >1000 트리거 도달**

## 측정 (catalog_scale_baseline)

| 항목 | 값 |
|------|-----|
| entryCount | **1006** |
| shard files | 724 |
| search_index v1 parse | 18–35 ms (watch) |
| search_index v2 manifest parse | 0 ms |
| search_index total | ~572 KB |
| shards total | ~572 KB (~0.56 MB) |

| Phase 2 트리거 | 상태 |
|----------------|------|
| search_index parse >50ms | ⏳ watch (18–35ms) |
| entryCount >1000 | ✅ **도달** |
| APK assets/registry >15MB | ❌ 여유 (~0.56MB) |

## Discovery 진행 (619 → 1006, +387)

Wikidata ko 라벨 G1 Discovery, 7카테고리 × limit 15, offset 스텝 ~15.

| 구간 | 작품 수 | 비고 |
|------|---------|------|
| 시작 | 619 | id_registry orphan 5건 수정 후 |
| +batch 1–2 | 673 → 737 | manga 600/615 소진 구간 회복 |
| +batch 3–5 | 793 → 911 | |
| +batch 6–7 | 963 → **1006** | wk_937 titles.en CJK → romanization 수정 |

## 품질

- dedupe: 0 duplicate
- external_id: 100%
- invalid_en: 0 (wk_000000937 `Hwan-u Tongji` + zh 분리)
- merge skip: 카테고리별 다수 (shadow wk 제목 매칭 한계)

## 다음 offset

manga 705 · drama 150 · game 150 · animation 160 · webtoon 150 · movie 135 · book 135

## 후속

1. **1000+ 체감 지연** — master_index 48작 윈도우·lazy load 실기기 dogfood
2. merge backfill (`wikidata_merge_backfill`) 또는 merge 로직 개선
3. titles_ja/zh coverage KPI (Discovery와 별 트랙)
