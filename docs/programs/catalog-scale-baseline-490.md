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
| **Phase 2.3 eager-only** | ✅ 53/1623 shards · **2.39→0.11 MB** |

## Phase 2.3 @5181 (ADR-010)

| 항목 | full bundle | eager-only |
|------|------------|------------|
| shard files (assets) | 1623 | **53** |
| shard size | 2.39 MB | **0.11 MB** |
| assets/registry total | ~5.7 MB | **~3.4 MB** |
| search_index | 2.9 MB | 2.9 MB (유지) |

`build_release.ps1` → `--bundle-eager-only` 기본화

## browse window dogfood ✅

- `test/browse_window_dogfood_test.dart` — 6 tests (CDN mock for loadMore)
- `test/bundle_eager_only_test.dart` — ADR-010 eager bundle 검증

## Discovery (2859 → 5181, +2322)

- 22 + 10 rounds `wikidata_ko_trial --category all --limit 20 --apply`

## 카테고리 (@5181)

animation 1084 · drama 1213 · game 913 · manga 705 · book 490 · movie 475 · webtoon 301

## 후속

1. **Sprint B** — 작품 `.md` dogfood ← **현재 P1**
2. Discovery yield 관측 (채널별 소진) — insert 감속
3. Phase 2.4 `RegistryPort` page API 설계

## Sprint C2 체크포인트 (2026-06-15)

| 항목 | @5181 실측 | 판정 |
|------|-----------|:----:|
| `flutter test` | **299/299** PASS | ✅ |
| `search_index` parse | **26 ms** (assets v1) | ✅ (<50ms) |
| `sw1_a` recall@10 | **87/87** (1.0000) | ✅ |
| browse 모드 | window (>2500) | ✅ |
| eager bundle | **53** shards · 0.11 MB | ✅ |
| `assets/registry` total | **6.60 MB** (search_index 2.9 MB 포함) | ⚠️ watch |
| CDN `akasha-db.pages.dev` | **5181** live | ✅ |
| dedupe | 0 | ✅ |

**결론:** G1 5k 구간 **물리·성능 무위험** 확인. 대량 Discovery 중단·Sprint B 전환 적절.
