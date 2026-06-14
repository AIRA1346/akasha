# ADR-009: Search Index Sharding (Phase 2.1)

> **상태:** Accepted (2026-06-14)  
> **Phase:** [architecture-evolution-phases.md](../programs/architecture-evolution-phases.md) §2.1  
> **근거:** [registry-scaling-review.md](../validation/registry-scaling-review.md) §2.3 P0

---

## Context

- `search_index.json` 단일 파일 · 앱 시작 시 **전량 메모리 적재** · 선형 스캔
- ~150k 작품에서 GitHub 100MB/file 한계 · ~100k에서 모바일/데스크톱 시작 지연
- work shard(`hash(wk_)`)는 on-demand인데 search만 병목

**목표:** 카탈로그 **무한에 가깝게** 성장해도 **발견(검색·필터→shard 로드)** 이 깨지지 않는 구조.

---

## Decision

### 1. Search index를 **카테고리별 shard**로 분할

```
akasha-db/
  search_index/
    manifest.json          ← entryCount, shards[]{category, path, entryCount, sha256}
    manga.json
    animation.json
    ...
  search_index.json        ← legacy (v1 호환, G1 동안 dual-write)
```

- **Primary (v2):** `search_index/manifest.json` + `search_index/{category}.json`
- **Legacy (v1):** flat `search_index.json` — loader fallback · G1~5k dual-write

### 2. Loader 계약

1. Bootstrap: `search_index/manifest.json`만 파싱 (수 KB)
2. Category filter / query 시: **해당 category index만** 로드 (Phase 2.1b)
3. v1 fallback: monolithic `search_index.json` 전량 로드

### 3. 이후 단계 (본 ADR 범위外 · Phase 2.x)

| 단계 | 내용 |
|------|------|
| 2.1b | Filter 시 category index **lazy** (전체 merge 금지) |
| 2.2 | Browse pagination · `master_index` 제거 |
| 2.3 | App bundle = manifest + eager shards only |
| 2.4 | `RegistryPort` page API |
| 2.5+ | token prefix shard · SQLite FTS · CDN search read |

### 4. 변경하지 않는 것

- `wk_` · hash work shard · Minimal Core · Tier 1/2 분리
- Git = write/audit, CDN = read (50k+)

---

## Consequences

**Positive**

- Git 100MB/file wall 회피 (카테고리별 파일)
- 증분 sync·partial fetch 가능
- 100k+ search_index **아키텍처 교체**의 1차 마일스톤

**Negative**

- dual-write 기간 동안 빌드 산출물 증가
- Loader·sync·CI 경로 복잡도 소폭 증가

---

## Compliance

- `registry_builder` — sharded + legacy emit
- `RegistryShardLoader` — manifest-first, sharded load
- `pubspec.yaml` — `assets/registry/search_index/`
- Exit: 5k 시나리오 baseline 재측정 ([catalog-scale-baseline-490.md](../programs/catalog-scale-baseline-490.md))
