# R2-E Phase 4.5 — Performance Post-Implementation Audit

> **상태:** MF-1 · MF-2 · SF-1 구현 검증 완료 · **Accept (Phase 5 착수 가능)**  
> **날짜:** 2026-06-19  
> **범위:** EntityRelatedWorksDiscovery · CollectibleCollectionPipeline · CatalogEntityBrowseView · EntityVaultLoader  
> **방법:** 정적 코드 리뷰 + 단위 테스트 근거 (**코드 수정 없음**)  
> **상위:** [Phase 4 Audit](r2e-phase4-entity-related-works-discovery-audit.md) · Phase 4 Step 2.5 / 3.5 / 4.5 Preset Audits

---

## Executive Summary

Phase 4.5 Preparation Audit에서 지정한 **Must Fix 2건(MF-1, MF-2)** 과 **Should Fix SF-1** 이 구현·검증되었다.  
`relatedWorkId` Cast reload 경로의 지배적 병목이었던 **N× vault scan** 과 **Discovery+Gallery incoming 중복** 이 제거되었고, Cast filter는 **catalog 전체 person(N)** 대신 **link graph상 연결 entity(K)** 만 `discoverAll` 대상으로 축소된다.

| 항목 | Preparation 판정 | Post-Implementation |
|------|:----------------:|:-------------------:|
| MF-1 `discoverAll` N× vault scan | Must Fix | **Done · Go** |
| MF-2 reload incoming dedupe | Must Fix | **Done · Go** |
| SF-1 workId → entityIds pre-filter | Should Fix | **Done · Go** |
| SF-2 journal map Gallery 공유 | Should Fix | **Done** (MF-2 일부) |
| SF-3 `_openEntity` vault cache | Should Fix | Open |
| NF persistent cache | Nice To Have | Open |

**Phase 4.5 Overall: Accept**  
**Phase 5 (Mixed Library): Go** — 성능 blocker 없음. 잔여 Should Fix는 Phase 5와 병렬·후속 가능.

---

## 1. 구현 대조 (Preparation → Actual)

### 1.1 MF-1 — `discoverAll` 단일 vault scan

**Before**

```
discoverAll(ids[N])
  └─ Future.wait(N × discover(id))
       └─ findByEntityId(id) → loadFromVault()   × N
```

**After**

```73:96:lib/services/entity_related_works_discovery.dart
  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  ) async {
    ...
    final journals = await _vaultLoader.loadFromVault(_vaultPath);
    final journalByEntityId = <String, EntityJournalEntry>{};
    ...
    _journalByEntityId = journalByEntityId;

    final entries = await Future.wait(
      uniqueIds.map(
        (id) async => MapEntry(
          id,
          await _discoverEntity(id, journalByEntityId: journalByEntityId),
        ),
      ),
    );
```

| 검증 | 결과 |
|------|:----:|
| `discoverAll` → `loadFromVault` 1회 | **Go** |
| outgoing supplement → `journalByEntityId[id]` (findByEntityId 없음) | **Go** |
| `discover(entityId)` public API 유지 (단건 시 findByEntityId) | **Go** |
| Discovery semantics (incoming ∪ outgoing dedupe) | **Go** (기존 7 tests 유지) |
| Pipeline / UI 미변경 (MF-1 범위) | **Go** |

**테스트:** `discoverAll loads vault journals once for batch resolve` — `loadFromVaultCallCount == 1`, `findByEntityIdCallCount == 0`.

---

### 1.2 MF-2 — reload-scope incoming · journal reuse

**Before (Cast reload, N discover + M cards)**

| 작업 | vault scan | incoming lookup |
|------|:----------:|:---------------:|
| Pipeline `discoverAll(N)` | 1× (MF-1 후) | N× |
| Gallery `_buildBrowseCards(M)` | 1× | M× |
| **합계** | **2×** | **N + M** |

**After**

```102:122:lib/screens/home/views/catalog_entity_browse_view.dart
    final relatedWorksDiscovery = widget.relatedWorksDiscoveryFactory?.call();
    ...
      filtered = await CollectibleCollectionPipeline.resolve(
        ...
        relatedWorksDiscovery: relatedWorksDiscovery,
      );
    ...
    final cards = await _buildBrowseCards(
      filtered,
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
```

Discovery cache surface:

```19:29:lib/services/entity_related_works_discovery.dart
  int? cachedIncomingRecordCount(String entityId);
  EntityJournalEntry? cachedJournal(String entityId);
  Map<String, EntityJournalEntry>? get cachedJournalsByEntityId;
```

Gallery reuse:

```153:185:lib/screens/home/views/catalog_entity_browse_view.dart
    final cachedJournals = relatedWorksDiscovery?.cachedJournalsByEntityId;
    if (cachedJournals != null) {
      byId = cachedJournals;
    } else {
      ... loadFromVault ...
    }
    ...
        final cached = relatedWorksDiscovery?.cachedIncomingRecordCount(
          entities[i].entityId,
        );
        if (cached != null) {
          incomingByEntity[i] = cached;
        } else {
          uncachedIncoming.add(i);
        }
```

| 검증 | 결과 |
|------|:----:|
| 동일 reload에서 discovery 인스턴스 1개 공유 | **Go** |
| Badge = `incomingPaths.length` (workId 개수 아님) | **Go** |
| Cast member(M) — discoverAll 캐시 hit → Gallery incoming 0 | **Go** |
| tags-only / scope gallery — 캐시 miss → 기존 fallback | **Go** |
| Dialog / Preset / Sidebar / Wiring 미변경 | **Go** |

**테스트:** `discoverAll caches incoming record counts for gallery reuse`.

**SF-2 (journal map 공유):** `discoverAll` 후 `cachedJournalsByEntityId`가 Gallery `loadFromVault`를 대체 → **Done**.

---

### 1.3 SF-1 — workId → entityIds pre-filter

**Before**

```dart
discoverAll(candidates.map((e) => e.entityId))  // N = kind+tags 후보 전체
```

**After**

```66:76:lib/services/collectible_collection_pipeline.dart
    final linkedEntityIds =
        await relatedWorksDiscovery.entityIdsForWork(relatedWorkId);
    final discoverTargets = linkedEntityIds.isEmpty
        ? candidates.map((e) => e.entityId)
        : candidates
            .where((e) => linkedEntityIds.contains(e.entityId))
            .map((e) => e.entityId);

    final relatedByEntity = await relatedWorksDiscovery.discoverAll(
      discoverTargets,
    );
```

`entityIdsForWork` — incoming index ∪ outgoing journal:

```99:124:lib/services/entity_related_works_discovery.dart
  Future<Set<String>> entityIdsForWork(String workId) async {
    ...
    for (final entityId in await _linkIndex.incomingEntityIds()) { ... }
    final journals = await _vaultLoader.loadFromVault(_vaultPath);
    for (final journal in journals) {
      final outgoing = await _linkIndex.outgoingLinks(journal.storagePath);
      if (outgoing.any((link) => link.targetEntityId == workId)) {
        linked.add(journal.entityId);
      }
    }
    return linked;
  }
```

| 검증 | 결과 |
|------|:----:|
| Re:Zero Cast — linked만 discover, filter predicate 동일 | **Go** |
| `linkedEntityIds.isEmpty` → full candidates fallback | **Go** (false negative 방지) |
| Hero / tags-only — Discovery 미호출 경로 | **Go** (변경 없음) |
| Intersection AND semantics | **Go** (pipeline tests) |
| `RecordLinkPort.incomingEntityIds()` 추가 | **Go** |

**테스트:** `entityIdsForWork returns incoming and outgoing linked entities`.

**참고:** SF-1은 Pipeline에 **의도된** 최소 변경. Collection **resolve semantics** (`workIds.contains(relatedWorkId)`) 는 동일.

---

## 2. 복잡도 Before / After (1× `_reload`, Re:Zero Cast)

기호: **C** catalog non-work, **N** kind+tags 후보, **K** link graph 연결 ∩ candidates, **M** filter 결과 카드, **E** vault journals, **W** vaultItems.

### 2.1 Phase 4 (최적화 전)

| 단계 | 복잡도 |
|------|--------|
| catalog filter | O(C) |
| discoverAll | O(N·E) vault + O(N) incoming + O(N·P·W) path resolve |
| Gallery | O(E) vault + O(M) incoming |
| **vault file ops (upper)** | **(N+1)·E** |

N=300, E=400 → **~120,400** journal read/parse (Discovery dominant).

### 2.2 Phase 4.5 (현재)

| 단계 | 복잡도 |
|------|--------|
| catalog filter | O(C) |
| `entityIdsForWork` | O(I·P·W + E) — I=incoming index entity 수 |
| discoverAll(**K**) | O(E) vault + O(K) incoming + O(K·P·W) |
| Gallery | **0** vault (cache) + **0** incoming (M cached) |
| **vault file ops (upper)** | **2·E** (entityIdsForWork + discoverAll) |

Cast 현실값: N=300, K≈M≈20, E=400 → **~800** journal ops (vs ~120k, **~150×**).

### 2.3 tags-only Collection (비교)

| | Phase 4 | Phase 4.5 |
|--|---------|-----------|
| Discovery | 0 | 0 |
| Gallery vault | 1×E | 1×E |
| Gallery incoming | M× | M× (캐시 없음) |

tags-only 대형 gallery(1000+) incoming batch는 **잔여 병목** — Cast 경로와 무관.

---

## 3. Semantics 회귀 검증

| Collection | Predicate | 회귀 |
|------------|-----------|:----:|
| **Hero** tagsAll only | kind ∩ tags | **Go** |
| **Re:Zero Cast** relatedWorkId only | kind ∩ workIds ∋ id | **Go** |
| **Intersection** tags + relatedWork | AND | **Go** |
| **Curated** | memberOrder, Discovery skip | **Go** |
| **Fate Cast** preset | 동일 Cast semantics | **Go** |

Pipeline 테스트 (`collectible_collection_test.dart` 24) · Discovery 테스트 (10) · Preset (7) · Edit Dialog (8) — **구현 전후 동일 통과 전제**.

---

## 4. 잔여 Should Fix / Nice To Have

### Should Fix (Phase 4.5 잔여 · Phase 5 병렬 가능)

| ID | 항목 | 설명 | Risk |
|----|------|------|:----:|
| SF-R1 | `entityIdsForWork` + `discoverAll` **연속 2× loadFromVault** | 동일 `resolve()` 내 journal 중복 | Low |
| SF-R2 | tags-only 대형 gallery **M× incoming** | 1000+ entity scope | Med |
| SF-R3 | `_openEntity` → `findByEntityId` reload-scope cache | journal dialog 후 `_reload` | Low |
| SF-R4 | `entityIdsForWork` incoming scan — index rebuild 시 역인덱스 persist | `.akasha` 확장 | Med |

### Nice To Have

| ID | 항목 |
|----|------|
| NF-1 | session/persistent discovery cache (`.akasha/entity_works.json`) |
| NF-2 | warm preload on vault connect |
| NF-3 | link_index에 incoming count 필드 |

**Must Fix: 없음** (Preparation MF-1 · MF-2 충족).

---

## 5. Phase 5 (Mixed Library) 영향

| 질문 | 답 |
|------|-----|
| Phase 5 전에 MF 필수? | **완료** — Accept |
| Phase 5가 Phase 4.5 잔여에 의존? | **아니오** — SF-R*는 독립 |
| Mixed Library 추가 부하 | Work + Entity 혼합 시 **catalog C 증가** → tags/scope gallery SF-R2 relevance ↑ |
| Discovery Cast path | Phase 5와 **직交 없음** (Entity Collection 전용) |
| 권장 순서 | **Phase 5 착수 OK** · SF-R1/R2는 dogfood 중 필요 시 |

---

## 6. 변경 파일 SSOT

| 파일 | Phase 4.5 변경 |
|------|----------------|
| `lib/services/entity_related_works_discovery.dart` | MF-1 batch vault · MF-2 cache · SF-1 `entityIdsForWork` |
| `lib/screens/home/views/catalog_entity_browse_view.dart` | MF-2 discovery 공유 · cache reuse |
| `lib/services/collectible_collection_pipeline.dart` | SF-1 pre-filter |
| `lib/core/ports/record_link_port.dart` | `incomingEntityIds()` |
| `lib/services/record_link_index_service.dart` | port 구현 |
| `test/entity_related_works_discovery_test.dart` | MF-1 · MF-2 · SF-1 tests |

**미변경 (요구 준수):** Dialog · Preset · Sidebar routing · HomeShellWiring · EntityCollectibleCard UI · RecordLinkNavigator.

---

## 7. 병목 순위 (Post-4.5)

| Rank | 병목 | 상태 |
|:----:|------|:----:|
| ~~1~~ | ~~N× loadFromVault (Discovery)~~ | **Resolved (MF-1)** |
| ~~2~~ | ~~Cast on all N persons~~ | **Mitigated (SF-1)** |
| ~~3~~ | ~~incoming N+M duplicate~~ | **Resolved (MF-2, Cast path)** |
| 4 | entityIdsForWork + discoverAll 2× vault | Open (SF-R1) |
| 5 | tags gallery M× incoming (1000+) | Open (SF-R2) |
| 6 | GridView build | Low (lazy OK) |

---

## 8. Go / No-Go

| 항목 | 판정 |
|------|:----:|
| MF-1 Acceptance (discoverAll 1× vault) | **Go** |
| MF-2 Acceptance (Cast incoming dedupe) | **Go** |
| SF-1 Acceptance (K ≪ N discover) | **Go** |
| Collection semantics 회귀 | **Go** |
| Phase 4.5 Complete | **Accept** |
| **Phase 5 Mixed Library 착수** | **Go** |

---

## 9. 권장 다음 액션

1. **Phase 5** — Mixed Library (별도 로드맵)
2. **(선택) SF-R1** — `entityIdsForWork`에 optional journal map 주입 → `resolve()` 내 vault 1×
3. **(선택) dogfood** — Re:Zero Cast 1-click preset → gallery reload 체감 확인
4. **(선택) SF-R2** — tags-only 300+ scope gallery incoming batch (Phase 5 이후 우선순위 재평가)

**Phase 4.5 Audit: Complete · Accept**
