# Catalog Scale Baseline @5181

> **2026-06-15** · **5181작** · G1 **✅ 5k 초과** · browse window 모드

## 측정

| 항목 | 값 |
|------|-----|
| entryCount | **5181** |
| shard files | 1623 |
| G1 (~5k) | **103.6%** ✅ |

| Phase 2 트리거 | 상태 |
|----------------|------|
| entryCount >2500 | ✅ window 모드 |
| G1 5k | ✅ |

## Discovery (2859 → 5181, +2322)

- 22 + 10 rounds `wikidata_ko_trial --category all --limit 20 --apply`

## 카테고리 (@5181)

animation 1084 · drama 1213 · game 913 · manga 705 · book 490 · movie 475 · webtoon 301

## browse window dogfood ✅

- `test/browse_window_dogfood_test.dart` — 6 tests
- 윈도우 prefetch · loadMore 누적 · webtoon 카테고리 · progress state

## 후속

1. **Phase 2.3** manifest-only / eager bundle (ADR-010)
2. Discovery yield 관측 (채널별 소진)
