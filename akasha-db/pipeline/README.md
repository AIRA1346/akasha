# AKASHA Pipeline (akasha-db)

> **CDN·앱 sync 제외** — `pipeline/`은 빌드·Discovery 전용.  
> 정책: [docs/discovery-policy.md](../../docs/discovery-policy.md)  
> 소스 결정: [docs/discovery-source-decision.md](../../docs/discovery-source-decision.md)

## Git에 들어가는 것

```
pipeline/
  discovery/
    manifest.json       ← 채널·한도·KPI·정책 버전
    cursors/            ← 소스별 cursor (offset 등)
```

현재 채널: **`wikidata_manga`** (`enabled: false`)

## Git에 들어가지 않는 것

```
pipeline/
  staging/              ← 일회성 후보 (TTL)
  signals/              ← 실행 중 Signal 버퍼
  raw/                  ← API·SPARQL 응답 (절대 금지)
  artifacts/            ← CI artifact 대체
  **/*.jsonl
```

`.gitignore`가 위 경로를 차단한다.

## official_sync 흐름

```
manifest + cursor
  → fetch (런타임만, discovery_source_fetch.dart)
  → extract Facts (wikidata_facts.dart)
  → signal_gate (금지 필드 차단)
  → dedupe_index lookup
  → Minimal Core → shard patch (hold 중이면 shadow만)
  → manifest KPI 갱신 + cursor commit
```

Signal은 **메모리 또는 CI artifact**에서만 존재한다.

## 실행 (기본 채널)

```bash
dart run tool/discovery/official_sync.dart --contract-test --offline --channel wikidata_manga
dart run tool/discovery/shadow_write.dart --offline --channel wikidata_manga
dart run tool/discovery_manifest_check.dart
```

## mergeCandidate (externalId 연결 후보)

fuzzy dedupe로 기존 `wk_`와 매칭된 Signal — **Discovery 성공**, Trial Write 대상 아님.

- **Phase B:** Registry Impact Test — Gap·Core·Franchise 축 5~10건
- **Phase 5a:** Snapshot Compare — 가상 diff → `registry_diff_report.md`
- **Phase 5c:** Product Value Review → `product_value_report.md`
- **Phase 5d:** Source Independence Test → `anilist_removal_report.md`
- **Phase 5b (patch):** **보류** — SD2.6 hold + 3-gate

`mergeCandidate`: 기존 `wk_`에 `externalIds.*` 연결 후보 (`artifacts/`, Git 금지)
