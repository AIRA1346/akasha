# AKASHA Pipeline (akasha-db)

> **CDN·앱 sync 제외** — `pipeline/`은 빌드·Discovery 전용.  
> 정책: [docs/discovery-policy.md](../../docs/discovery-policy.md)

## Git에 들어가는 것

```
pipeline/
  discovery/
    manifest.json       ← 채널·한도·KPI·정책 버전
    cursors/            ← 소스별 cursor (lastPage, lastId)
```

## Git에 들어가지 않는 것

```
pipeline/
  staging/              ← 일회성 후보 (TTL)
  signals/              ← 실행 중 Signal 버퍼
  raw/                  ← API 응답 (절대 금지)
  artifacts/            ← CI artifact 대체
  **/*.jsonl
```

`.gitignore`가 위 경로를 차단한다.

## official_sync 흐름 (목표)

```
manifest + cursor
  → fetch (런타임만)
  → extract Facts (anilist_facts.dart)
  → signal_gate (금지 필드 차단)
  → dedupe_index lookup
  → Minimal Core → shard patch
  → manifest KPI 갱신 + cursor commit
```

Signal은 **메모리 또는 CI artifact**에서만 존재한다.

## mergeCandidate (externalId 연결 후보)

fuzzy dedupe로 기존 `wk_`와 매칭된 Signal — **Discovery 성공**, Trial Write 대상 아님.

- **Phase B (Registry Impact Test):** Gap·Core·Franchise 축 5~10건 선정 + Impact Report
- **Phase 5a (Snapshot Compare):** 402 vs 412 가상 diff → `registry_diff_report.md`
- **Phase 5c (Product Value Review):** AniList 존재 vs 사용자 가치 → `product_value_report.md`
- **Phase 5d (AniList Removal):** anilist 제거 후 독립 가치 → `anilist_removal_report.md`
- **Phase 5b (patch):** **보류** — recommend5bPatch + Product + Removal 3-gate
- Coverage KPI > 등록 건수 KPI
- `mergeCandidate`: 기존 `wk_`에 `externalIds.anilist` 연결 후보 (`artifacts/`, Git 금지)
