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

## Sprint C3 체크포인트 (2026-06-17)

| 항목 | @8676 실측 | 판정 |
|------|-----------|:----:|
| `flutter test` | **318/318** PASS | ✅ |
| `search_index` parse | **41 ms** | ✅ |
| `sw1_a` recall@10 | **87/87** (1.0000) | ✅ |
| browse 모드 | window (>2500) | ✅ |
| eager bundle | **53** shards · ~0.14 MB | ✅ |
| `assets/registry` total (eager-only) | **~10.75 MB** (15MB trigger 전) | ⚠️ watch |
| dedupe | 0 | ✅ |
| 배치 SSOT | `scripts/discovery_batch.ps1` | ✅ |

**결론:** ADR-010 15MB trigger **근접**. Option A — 배치 파이프라인 eager-only 통일 · `catalog_scale_baseline --strict` 게이트.

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

## Browse UX 검토 — 스크롤 vs 페이지 (2026-06-15)

### 현재 구조 (2층)

| 층 | 방식 | 역할 |
|----|------|------|
| **데이터** | browse window 48 + 「더 불러오기」 | 5181 전량 메모리 로드 방지 (Phase 2.2) |
| **UI** | 세로 스크롤 + 섹션(카탈로그·연도별) + 매체 접기 | 로드된 카드 전부 한 흐름으로 표시 |

→ **데이터는 이미 페이지네이션(윈도우)** 이고, **UI만 스크롤**이다. 웹식 1·2·3 페이지 탭과는 다름.

### 스크롤 유지 권장 (v1)

| 이유 | |
|------|--|
| Steam/데스크톱 탐색 UX | 포스터 그리드는 스크롤이 표준 |
| 검색이 주 경로 | 카탈로그 browse는 보조 — 전량 훑기보다 발견·검색 |
| 이미 윈도우로 메모리 제한 | shard는 48색인 단위; 문제는 **표시 수 vs 윈도우 불일치** |

### 개선 후보 (v1.1 · 체감 병목 시)

1. **표시 수 정합** — `N개 표시`를 실제 prefetch 윈도우·고유 workId 기준으로 맞추기 (IP 중복 카운트 분리)
2. **하단 무한 스크롤** — 「더 불러오기」 버튼 대신 끝 근처 자동 prefetch (동일 데이터 모델)
3. **Sliver 가상화** — 카드 1000+ 체감 렉 시 `CustomScrollView` 전환 (`GridView.builder`는 이미 셀 단위 lazy이나 섹션별 grid 다수)

### 하지 않을 것 (v1)

- **번호 페이지 (1/108)** — browse 목적과 맞지 않음
- **5181 전량 한 번에 로드** — Phase 2.3 eager-only와 충돌
