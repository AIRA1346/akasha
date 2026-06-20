# R2-E Phase 3 — CollectibleCollection Architecture Audit

> **상태:** 조사·설계 완료 (구현 없음)  
> **날짜:** 2026-06-20  
> **전제:** Phase 1 Entity Gallery ✅ · Phase 2 Entity.tags ✅  
> **범위:** **Entity Collection only** — Work Collection 일반화 · Mixed Library ❌  
> **상위:** [Phase 2 Tags Audit](r2e-phase2-tags-architecture-audit.md) · [Collection Architecture](r2e-collection-architecture-audit.md)

---

## Executive Summary

「영웅 서재」「성장형 주인공 서재」「최애 캐릭터 서재」를 위해 **신규 `CollectibleCollection` + `collectible_collections.json`** 이 필요하다.  
`PersonalLibraryConfig` **일반화는 비권장** — Work 전용 pipeline·DnD·status filter와 34+ file coupling.

**Phase 3 최소 범위:**
- **정적(curated)** + **동적(filter)** 두 mode 모두 지원
- Sidebar 「컬렉션」 섹션 (Work 「나만의 서재」와 병렬)
- `CatalogEntityBrowseView` **확장 재사용** (별도 grid widget 불필요)
- Filter: `kind` + `tagsAll` (exact set semantics)
- **`relatedWorkId`는 스키마만** — resolver는 **Phase 4**

| Phase | 목표 |
|-------|------|
| **3** | Entity CollectibleCollection 저장·표시 (tags + curated) |
| **4** | `EntityRelatedWorksDiscovery` + `relatedWorkId` filter |
| **5** | Mixed Collectible Library |

---

## 1. PersonalLibrary 분석

### 1.1 구성 요소

| 컴포넌트 | 파일 | 역할 |
|----------|------|------|
| Model | `personal_library_config.dart` | id, name, mode, **memberOrder (workId)**, Work filters |
| Storage | `personal_library_storage_service.dart` | `{vault}/.akasha/personal_libraries.json` |
| Controller | `home_personal_library_controller.dart` | 목록·activeId·`SidebarSelectionMode` |
| Pipeline | `my_library_pipeline.dart` | `BrowseCard` / `AkashaItem` only |
| Membership | `personal_library_membership_service.dart` | addWork, reorder, `setContainsWorkId` |
| View | `personal_library_view.dart` | `BrowseDashboardSections` + `PosterCard` |
| Sidebar | `dashboard_sidebar.dart` | 「나만의 서재」 섹션, Work DnD drop |
| Wiring | `home_sidebar_coordinator.dart`, `home_shell_body.dart` | `isPersonalLibraryMode` routing |

### 1.2 재사용 가능 (패턴만)

| 패턴 | PersonalLibrary | CollectibleCollection에 적용 |
|------|-----------------|------------------------------|
| Vault `.akasha/*.json` | ✅ | `collectible_collections.json` |
| prefs → vault migration | ✅ | 동일 |
| Controller load/save/activeId | ✅ | `HomeCollectibleCollectionController` |
| Sidebar list + add/edit/delete | ✅ | 「컬렉션」 섹션 |
| curated `memberOrder` + reorder | ✅ | `CollectibleRef` memberOrder |
| filter mode vs curated mode | ✅ | `CollectionMode.filter` / `curated` |

### 1.3 Work 전용 — 재사용 불가

| 항목 | Work 전용 근거 |
|------|---------------|
| `memberOrder: List<String>` | workId semantics · `RegistryPort.setContainsWorkId` |
| `MyLibraryPipeline` | `AkashaItem` → `BrowseCard` → `FranchiseFusionService` |
| `categories`, `workStatuses`, `myStatuses` | Entity 무의미 |
| `PersonalLibraryDropTarget` | `WorkDragPayload.workId` |
| `CuratedReorderGrid` | `List<BrowseCard>` + PosterCard builder |
| `PersonalLibraryView` | Poster grid · HoF · watchlist sections |
| `master_archive` | Work archive filter preset |

**결론:** Storage/controller/sidebar **패턴 복제**, pipeline/view **신규 Entity 전용**.

---

## 2. CollectibleCollection 모델 설계

### 2.1 핵심 타입 (초안)

```dart
/// Phase 3: person · concept · event · place · organization
/// Phase 5+: work (schema only, Phase 3 미사용)
enum CollectibleKind {
  person, concept, event, place, organization,
}

class CollectibleRef {
  final CollectibleKind kind;
  final String id;  // pe_u_* · co_u_* · …
}

enum CollectibleCollectionMode {
  /// explicit memberOrder — 「최애 캐릭터」
  curated,

  /// filter predicate — 「영웅」「성장형 주인공」
  filter,
}

class CollectibleCollectionFilter {
  final List<CollectibleKind>? kinds;      // default [person] for Phase 3 UX
  final List<String>? tagsAll;             // exact AND — semantic tags
  final String? relatedWorkId;            // Phase 4 only — schema reserved
}

class CollectibleCollection {
  final String id;                          // col_u_{base32}
  String title;
  String? iconKey;                          // optional Material icon name
  CollectibleCollectionMode mode;
  List<CollectibleRef> memberOrder;         // curated SSOT · manual order
  CollectibleCollectionFilter? filter;      // filter mode SSOT
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 2.2 mode 규칙

| mode | SSOT | memberOrder | filter |
|------|------|:-----------:|:------:|
| **curated** | `memberOrder` | ✅ required | optional overlay (Phase 3.1) |
| **filter** | `filter` | empty or sort hint | ✅ required |

**Phase 3 필수 validation:**
- `curated`: `memberOrder.isNotEmpty`, each ref `kind != work`
- `filter`: `filter != null`, (`tagsAll` non-empty **or** `relatedWorkId` set — Phase 4)

### 2.3 명시 멤버 vs 필터 — 둘 다 필요

| 사용자 예 | mode | 이유 |
|-----------|------|------|
| **최애 캐릭터 서재** | `curated` | 사용자가 직접 고른 3~10명 · **순서** 의미 |
| **영웅 서재** | `filter` | tag 추가/삭제 시 **자동 갱신** · 멤버 수 unbounded |
| **성장형 주인공 서재** | `filter` | `tagsAll: ["성장"]` or `["영웅","성장"]` |

**curated만:** tag 변경 시 수동 유지보수.  
**filter만:** 「최애」처럼 주관적·고정 set 표현 어려움.

**Phase 3:** 두 mode **필수**.  
**Phase 3.1 (optional):** hybrid — filter pool ∩ explicit order (PersonalLibrary curated+filter overlay analog).

---

## 3. Collection 종류 분류

### A. 정적 (Curated)

```json
{
  "id": "col_u_favorites01",
  "title": "최애 캐릭터",
  "mode": "curated",
  "memberOrder": [
    { "kind": "person", "id": "pe_u_subaru01" },
    { "kind": "person", "id": "pe_u_emilia01" }
  ]
}
```

- DnD reorder (Entity 전용 grid)
- Gallery에서 Sheet tap — Phase 1 동일
- Work ID **금지** (Phase 3)

### B. 동적 (Filter)

```json
{
  "id": "col_u_heroes01",
  "title": "영웅",
  "mode": "filter",
  "filter": {
    "kinds": ["person"],
    "tagsAll": ["영웅"]
  }
}
```

```json
{
  "id": "col_u_growth01",
  "title": "성장형 주인공",
  "mode": "filter",
  "filter": {
    "kinds": ["person"],
    "tagsAll": ["성장"]
  }
}
```

- Resolve: catalog `UserCatalogEntity.tags` **exact `tagsAll` subset**
- Entity tag 변경 → collection view **자동 반영**
- Sort: collection-level default (titleAsc / recentlyAdded) — `memberOrder` 없음

### C. Phase 4 예약 (Filter + link graph)

```json
{
  "title": "Re:Zero 등장인물",
  "mode": "filter",
  "filter": {
    "kinds": ["person"],
    "relatedWorkId": "wk_u_rezero01"
  }
}
```

**Phase 3 구현 ❌** — schema field만 허용, pipeline에서 `relatedWorkId` hit 시 Phase 4 gate.

---

## 4. 저장 구조

### 4.1 위치

```
{vault}/.akasha/collectible_collections.json
```

`PersonalLibraryStorageService`와 **동일 디렉터리** · **별 파일** (Work library 오염 방지).

### 4.2 스키마 v1 (초안)

```json
{
  "version": 1,
  "collections": [
    {
      "id": "col_u_heroes01",
      "title": "영웅",
      "iconKey": "shield_outlined",
      "mode": "filter",
      "memberOrder": [],
      "filter": {
        "kinds": ["person"],
        "tagsAll": ["영웅"]
      },
      "createdAt": "2026-06-20T12:00:00.000Z",
      "updatedAt": "2026-06-20T12:00:00.000Z"
    },
    {
      "id": "col_u_fav01",
      "title": "최애",
      "mode": "curated",
      "memberOrder": [
        { "kind": "person", "id": "pe_u_subaru01" },
        { "kind": "person", "id": "pe_u_rimuru01" }
      ],
      "filter": null,
      "createdAt": "2026-06-20T12:00:00.000Z",
      "updatedAt": "2026-06-20T12:00:00.000Z"
    }
  ]
}
```

| 필드 | 필수 | 비고 |
|------|:----:|------|
| `version` | ✅ | v1 |
| `id` | ✅ | `col_u_*` user-local |
| `title` | ✅ | sidebar·header 표시 |
| `mode` | ✅ | `curated` \| `filter` |
| `memberOrder` | △ | curated 필수 |
| `filter` | △ | filter mode 필수 |
| `iconKey` | | sidebar icon |
| `createdAt` / `updatedAt` | ✅ | |

### 4.3 PersonalLibraryConfig 일반화 vs 신규

| | PLC 확장 | 신규 CollectibleCollection |
|--|----------|---------------------------|
| Migration | memberOrder 의미 파괴 | 깨끗 |
| Regression | ~34 files | 격리 ~12–18 files |
| 제품 개념 | 「서재」= Work | 「컬렉션」= Entity collectible |
| Phase 3 Work 충돌 | 높음 | **없음** |
| **권장** | ❌ | ✅ |

---

## 5. Sidebar UX (HomeShell 기준)

### 5.1 현재 구조

```
DashboardSidebar
├── 나만의 서재 (PersonalLibrary)     ← Work · amberAccent
├── 기록 (Timeline)
└── 대시보드 서재 (Dashboard)         ← Work filter preset · tealAccent

Main browse (dashboard mode)
├── FilterSection (Work domain/category + Entity scope chips)
└── WorkbenchShell.browseContent
    ├── Person scope → CatalogEntityBrowseView (full)
    └── Work scope   → BrowseView (Poster grid)
```

`SidebarSelectionMode`: `dashboard` | `personalLibrary` | `timeline`  
Entity type browse (`BrowseEntityScope.person`) = **session filter**, **영속 collection 아님**.

### 5.2 권장: 「컬렉션」 섹션 추가

```
DashboardSidebar
├── 나만의 서재          ← Work (변경 없음)
├── ★ 컬렉션 ★          ← Entity CollectibleCollection (NEW)
│     ├── 영웅
│     ├── 성장형 주인공
│     └── 최애
├── 기록
└── 대시보드 서재
```

| 항목 | 값 |
|------|-----|
| Accent | `Colors.purpleAccent` or `Colors.deepPurpleAccent` (Work amber / Entity teal과 구분) |
| Selection | `SidebarSelectionMode.collectibleCollection` (enum 확장) |
| Add | 「컬렉션 추가」→ name · mode · filter/tags or pick members |
| Active state | prefs `akasha_active_collectible_collection_id` |

### 5.3 Collection 선택 시 Main 영역

```
isCollectibleCollectionMode == true
  → FilterSection: Entity scope chips **숨김** (collection이 scope 정의)
  → WorkbenchShell.browseContent:
       CollectibleCollectionView
         └─ CatalogEntityBrowseView(collection: active, …)
```

**Dashboard Person chip vs Collection:**
- Person chip = **전체 Person type slice** (Phase 1)
- 「영웅」collection = **tag semantic subset** — 다른 진입점·다른 mental model

### 5.4 왜 「나만의 서재」 하위가 아닌가

| | 나만의 서재 하위 | 별도 「컬렉션」 |
|--|-----------------|----------------|
| Work 혼동 | 「영웅」이 Work 서재처럼 보임 | Entity collectible 명확 |
| DnD | Work drop target 오염 | Entity-only reorder |
| Pipeline | MyLibraryPipeline 수정 필요 | Entity pipeline 격리 |
| 장기 Mixed (Phase 5) | PLC bridge 복잡 | top-level merge |

---

## 6. Entity Gallery 재사용성

### 6.1 `CatalogEntityBrowseView` 현状

- Input: `BrowseEntityScope scope` → `catalogEntityType` filter
- Build: `userCatalog.all` → non-work → type filter → `_buildBrowseCards`
- UI: header `${scope.label} 갤러리`, sort dropdown, `EntityCollectibleCard` grid
- Sheet tap: `showEntityJournalDialog` — **재사용 ✅**

### 6.2 재사용 전략 — **확장, 별도 View 불필요**

**Option A (권장):** optional `CollectibleCollection? collection` prop

```dart
// 개념 API — Phase 3
CatalogEntityBrowseView(
  userCatalog: …,
  scope: BrowseEntityScope.person,  // fallback / kind hint
  collectionFilter: activeCollection, // NEW — non-null이면 scope override
  galleryTitle: activeCollection.title, // 「영웅」갤러리 (12)
)
```

Resolve pipeline (`CollectibleCollectionPipeline.resolve`):

```dart
List<UserCatalogEntity> resolve(CollectibleCollection col, UserCatalogPort catalog) {
  switch (col.mode) {
    case CollectibleCollectionMode.curated:
      return col.memberOrder
          .map((ref) => catalog.getById(ref.id))
          .whereType<UserCatalogEntity>()
          .toList(); // + memberOrder sort
    case CollectibleCollectionMode.filter:
      return catalog.all.where((e) => matchesFilter(e, col.filter!)).toList();
  }
}

bool matchesFilter(UserCatalogEntity e, CollectibleCollectionFilter f) {
  if (f.kinds != null && !f.kinds!.contains(e.anchorType)) return false;
  if (f.tagsAll != null && !f.tagsAll!.every(e.tags.contains)) return false;
  if (f.relatedWorkId != null) return false; // Phase 4 — EntityRelatedWorksDiscovery
  return true;
}
```

**변경 범위 (gallery):**

| 파일 | 변경 |
|------|------|
| `catalog_entity_browse_view.dart` | `collection` prop · `_reload` entity source 분기 · header title |
| `collectible_collection_pipeline.dart` | **신규** resolve |
| `collectible_collection_view.dart` | **thin wrapper** (optional — shell wiring만 해도 됨) |

**변경 불필요:** `entity_collectible_card.dart`, grid layout, sort utils, Sheet dialog.

### 6.3 Curated reorder

- `CuratedReorderGrid` **재사용 ❌** (`BrowseCard` 전용)
- Phase 3: `EntityCuratedReorderGrid` **신규** (~80 lines, `CuratedReorderGrid` pattern copy)
- 또는 Phase 3.0: curated **without DnD** (add/remove only) → reorder Phase 3.1

### 6.4 성능

Collection filter = catalog in-memory predicate — **O(N)** entities.  
Card build = Phase 1과 동일 (vault load + incoming N×).  
Phase 1 Should Fix와 **동일** — Collection이 추가 overhead 거의 없음.

---

## 7. Work Collection과의 관계 (Phase 3)

### 7.1 Phase 3 범위

| | 포함 | 제외 |
|--|:----:|:----:|
| Entity person/concept/… collection | ✅ | |
| Work in memberOrder | | ❌ |
| Mixed Work+Person grid | | ❌ |
| PLC → Collection migration | | ❌ |
| PersonalLibrary behavior change | | ❌ |

### 7.2 충돌 분석

| 충돌점 | 위험 | Phase 3 대응 |
|--------|:----:|-------------|
| Sidebar real estate |低 | 새 섹션 — PLC/list 길이 independent |
| `SidebarSelectionMode` |低 | enum value 추가 |
| `home_shell_body` routing |中 | 1 branch 추가 — Work path untouched |
| Storage file | **없음** | 별도 JSON |
| User mental model |低 | 「서재」= Work · 「컬렉션」= Character/Concept |

**Work Personal Library와 기능·데이터·UI 모두 병렬 — Phase 3 충돌 없음.**

---

## 8. 미래 Related Works — 모델 수용 검증

### A) 영웅 서재

```
kind = person
tagsAll = ["영웅"]
```

- **Phase 3:** `CollectibleCollectionFilter.tagsAll` + exact match ✅
- **데이터:** `UserCatalogEntity.tags` (Phase 2) ✅

### B) Re:Zero 등장인물

```
kind = person
relatedWorkId = wk_u_rezero01
```

- **Phase 3:** schema field **`relatedWorkId` reserved** · pipeline **stub** (empty or “Phase 4”)
- **Phase 4:** `EntityRelatedWorksDiscovery.linkedWorkIds(entityId)` + incoming path resolve
- **tags 미사용** ✅

### 모델 통합 검증

```dart
class CollectibleCollectionFilter {
  final List<CollectibleKind>? kinds;
  final List<String>? tagsAll;        // A axis
  final String? relatedWorkId;       // B axis — orthogonal
}
```

| Collection | tagsAll | relatedWorkId | 충돌 |
|------------|:-------:|:-------------:|:----:|
| A 영웅 | ✅ | null | — |
| B Re:Zero cast | null | ✅ | — |
| A∩B (히어로 ∧ Re:Zero) | ✅ | ✅ | **Phase 4** AND semantics — 가능하나 UI 복잡 · defer |

**결론:** 단일 `CollectibleCollectionFilter`가 **tags 기반 · relatedWork 기반 둘 다 수용** — Phase 3 schema에 `relatedWorkId` 포함 권장, resolver는 Phase 4.

---

## 9. 「영웅 서재」— 현재 데이터로 어디까지?

### 지금 (Phase 2 완료)

|能力 | 상태 |
|------|:----:|
| 나츠키·리무루에 `tags: [영웅]` | ✅ |
| 코드 5줄 predicate로 목록 추출 | ✅ |
| 이름「영웅 서재」저장 | ❌ |
| Sidebar 클릭 진입 | ❌ |
| Dedicated gallery header | ❌ |

### Phase 3 완료 후

| 사용자 행동 | 결과 |
|-------------|------|
| Sidebar 「컬렉션」→「영웅」클릭 | Person grid — tag `영웅`만 |
| 나츠키·리무루·(tag 있는) 아르토리아 표시 | filter auto |
| 새 Person에 `영웅` tag 추가 | **다음 open 시 자동 포함** |
| 「최애」curated 생성 | subaru + emilia **고정** · reorder |
| Fusion `영웅` 검색 | 여전히 keyword search (collection ≠ search) |

### Phase 4 이후

| | |
|--|--|
| 「Re:Zero 등장인물」sidebar collection | link graph filter |
| tags와 **독립** | ✅ |

---

## 10. 예상 파일 영향도

### Phase 3 — Entity Collection (신규)

| 파일 | 역할 | 난이도 |
|------|------|:------:|
| `lib/models/collectible_ref.dart` | kind + id | S |
| `lib/models/collectible_collection.dart` | model + json | S |
| `lib/models/collectible_collection_filter.dart` | filter spec | S |
| `lib/services/collectible_collection_storage_service.dart` | persist | S |
| `lib/services/collectible_collection_pipeline.dart` | resolve curated/filter | M |
| `lib/screens/home/home_collectible_collection_controller.dart` | list/active | M |
| `lib/screens/home/dialogs/collectible_collection_edit_dialog.dart` | create/edit | M |
| `lib/screens/home/views/collectible_collection_view.dart` | wrapper (optional) | S |
| `lib/screens/home/views/catalog_entity_browse_view.dart` | collection prop | M |
| `lib/widgets/dashboard_sidebar.dart` | 컬렉션 섹션 | M |
| `lib/screens/home/home_personal_library_controller.dart` | `SidebarSelectionMode` enum | S |
| `lib/screens/home/coordinators/home_sidebar_coordinator.dart` | select collection | M |
| `lib/screens/home/coordinators/home_navigation_coordinator.dart` | routing | S |
| `lib/screens/home/home_shell_body.dart` | browse branch | M |
| `lib/widgets/entity_curated_reorder_grid.dart` | curated DnD (optional 3.1) | M |

**Tests:** storage round-trip, pipeline filter/tagsAll, curated order, sidebar selection.

| | |
|--|--|
| **신규** | ~10–12 files |
| **수정** | ~5–7 files |
| **Work stack touch** | **0** (routing branch only) |
| **총 난이도** | **M** (curated DnD 없으면 **M-**) |

### Phase 3에서 건드리지 않음

`PersonalLibraryConfig`, `MyLibraryPipeline`, `BrowsePipeline`, `PosterCard`, `Workbench`, `BrowseEntityScope` storage.

---

## 11. Phase 3 / 4 / 5 경계선

| | Phase 3 | Phase 4 | Phase 5 |
|--|---------|---------|---------|
| **Storage** | `collectible_collections.json` | — | `CollectibleRef` work kind |
| **Filter** | `tagsAll`, `kinds` | `relatedWorkId` resolver | mixed kinds |
| **Pipeline** | catalog tag exact match | `EntityRelatedWorksDiscovery` | unified resolve |
| **UI** | Sidebar 컬렉션 · Entity grid | Re:Zero cast collection | Work+Entity grid |
| **Schema** | `relatedWorkId` field **nullable** | field **active** | `kind: work` in members |
| **Validation** | tag work-name warn (optional) | — | — |

**Phase 3 Done 기준:**
1. 사용자가 「영웅」filter collection 생성·저장
2. Sidebar에서 진입 → Person tag gallery
3. 「최애」curated collection · explicit members
4. Work library **회귀 없음**

**Phase 3 Explicitly Out:**
- `relatedWorkId` resolve
- Mixed grid
- Work collection
- Gallery tag chips (Phase 2.1 display — optional parallel)
- `Entity.tags` validation hard block

---

## 12. 권장 구현 순서 (Phase 3)

1. **Model + storage** — `CollectibleCollection`, json v1, `col_u_*` id codec  
2. **Pipeline** — `tagsAll` exact filter + curated memberOrder resolve  
3. **Controller** — load/save/activeId (mirror `HomePersonalLibraryController`)  
4. **CatalogEntityBrowseView** — `collection` prop · header override  
5. **Sidebar** — 「컬렉션」section + selection mode  
6. **Shell routing** — `home_shell_body` branch  
7. **Create/edit dialog** — title · mode · tags picker · member picker  
8. **Tests**  
9. **(3.1)** Entity curated reorder grid  

---

## 13. 관련 문서

| 문서 | 내용 |
|------|------|
| [r2e-phase2-tags-architecture-audit.md](r2e-phase2-tags-architecture-audit.md) | tags = semantic axis |
| [r2e-collection-architecture-audit.md](r2e-collection-architecture-audit.md) | PLC 비교 · 초기 sketch |
| [r2e-step2-entity-relation-discovery-audit.md](r2e-step2-entity-relation-discovery-audit.md) | relatedWorkId resolve |
| [r2e-step3-entity-collection-surface-audit.md](r2e-step3-entity-collection-surface-audit.md) | first surface |

---

## 14. 문서 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-20 | Phase 3 CollectibleCollection architecture audit — 조사·설계 only |
