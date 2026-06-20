# R2-E Step 0.5 — Collectible Architecture Audit

> **상태:** 조사 완료 (구현·리팩토링 없음)  
> **날짜:** 2026-06-19  
> **상위:** R2-E Step 0 Work Card Audit · [link-identity-policy.md](../policy/link-identity-policy.md)

---

## Executive Summary

현재 **Work = `AkashaItem` + `BrowseCard` + `PosterCard` + Workbench** 로 강결합되어 있다.  
Person / Concept / Event / Place / Organization 을 **동일 컬렉션 대상**으로 취급하려면 **표현 모델(`CollectibleItem`)과 카드·파이프라인 분리**가 필요하나, **Phase 1은 Entity 전용 카드 + 기존 Sheet** 로 Work급 UX의 70%를 최소 비용으로 달성 가능하다.

**추천:** 단기 **EntityCollectibleCard + Entity Sheet** 유지 · 중장기 **CollectibleItem** 도입 후 IP/태그 필터 확장.

---

## 1. `AkashaItem` 필드 분류

**소스:** `lib/models/akasha_item.dart`, `ContentItem` / `GameItem` 서브클래스

| 필드 | 분류 | Entity 재사용 | 근거 |
|------|------|:-------------:|------|
| `workId` | **Work 전용** | △ (`entityId`로 대응) | Work/Registry ID 체계; Entity는 `pe_u_*` 등 |
| `title` | Generic | ✅ | catalog · journal 공통 |
| `category` (`MediaCategory`) | **Work 전용** | ❌ | manga/game 등 **매체**; Entity는 `EntityAnchorType` |
| `domain` (`AppDomain`) | Generic | ✅ | catalog에 존재 |
| `filePath` | Generic | ✅ | vault `.md` 경로 (entity journal 동일 개념) |
| `creator` | Generic (Work 중심) | △ | catalog 필드 있으나 Entity UI 미사용 |
| `releaseYear` | Work 중심 | △ | Entity에 의미 제한적 |
| `rating` | **Work 전용** | ❌ | 감상 메타; Entity 스키마 없음 |
| `posterPath` | **Work 전용** | ❌ | Tier 1.5 Entity catalog 정책상 금지 |
| `description` | Generic | △ | Work Sanctum; Entity는 `body` |
| `memorableQuotes` | **Work 전용** | ❌ | 회상 카드 |
| `review` | **Work 전용** | ❌ | Work 감상 |
| `isHallOfFame` | **Work 전용** | ❌ | 서재 HoF 섹션 |
| `tags` | Generic (미활용→Work) | ❌* | Work `.md`에 존재; **Entity tags 없음** |
| `addedAt` | Generic | ✅ | catalog · journal |
| `bodyRaw` | Generic | ✅ | journal body SSOT |
| `workStatusLabel` / `myStatusLabel` | **Work 전용** | ❌ | `ContentWorkStatus` / `GameMyStatus` enum |
| `setWorkStatus` / `setMyStatus` | **Work 전용** | ❌ | 카테고리별 상태 머신 |
| `combinedStatusLabel` | **Work 전용** | ❌ | PosterCard 상태 행 |

**구조적 Work 가정:** abstract `AkashaItem`이 **감상 상태 API**를 core contract로 강제 → Entity가 `AkashaItem`을 implement하기 **불가능에 가깝다**.

---

## 2. `PosterCard` 필드 사용 (라인 단위)

**소스:** `lib/widgets/poster_card.dart` (+ `status_helpers.dart`, `catalog_display_title.dart`, `poster_image.dart`, `file_service.dart`)

### 2.1 `widget.item` (`AkashaItem`) 직접 접근

| 라인 | 필드 / API | 필수 | 용도 |
|------|-----------|:----:|------|
| 58 | `item` → `isArchivedInVault(item)` | 선택 | `filePath`/`workId` 기반 vault 배지 (L416-420, L511-512) |
| 60 | `item.category` | **필수** | `categoryGradient` — 테두리 glow (L60, L76) |
| 62-63 | `item` → `isWatchlistItem` / `isFinishedItem` | **필수** | 카드 border 색 (L62-88) — **myStatus + workStatus** |
| 64 | `item.category` | **필수** | `_categoryAccent` (L64, L437) |
| 173-174 | `item` → `watchlistStatusEmojiLabel` | **필수** | 상태 텍스트 (L339, L358) — **myStatusLabel** |
| 243, 526 | `resolveCatalogDisplayTitle(item)` | **필수** | `item.workId` + `item.title` + WorksRegistry |
| 263-274, 536-546 | `item.creator` | 선택 | 부제 (비어 있으면 생략) |
| 293-295 | `item.releaseYear` | 선택 | `🗓️ N년` |
| 325-327, 363 | `item.rating` | 선택 | StarRating / "평가 대기" |
| 404-407 | `item` → `PosterImage` | 포스터 모드 **필수** | `posterPath`, `workId`, `category`, `title` |
| 437, 468-500 | `item.category` | fact 모드 **필수** | accent, icon, label |

### 2.2 `BrowseCard` / widget props (Work IP 전용)

| 라인 | 필드 | 필수 | 용도 |
|------|------|:----:|------|
| 311-315 | `widget.formatSlots` | 선택 | `FormatChipRow` — IP 매체 칩 |
| 410-414 | `widget.curatedLibraryCount` | 선택 | `★N` 서재 배지 |
| 19, (미사용) | `widget.franchiseId` | — | **prop만 존재, PosterCard 본문 미참조** |

### 2.3 PosterCard 필수·선택 요약

**절대 필수 (카드 렌더 불가):**
- `title` (또는 registry resolve 가능한 `workId`)
- `category` (`MediaCategory`)
- `myStatusLabel` + `workStatusLabel` (border·footer — default enum 값이라도 필요)

**포스터 레이아웃 (`showPoster: true`) 추가 필수:**
- `posterPath` 또는 category placeholder fallback

**선택 (UX 풍부화):**
- `creator`, `releaseYear`, `rating`, vault archive badge, `formatSlots`, `curatedLibraryCount`

**Entity에 매핑 불가:** category(MediaCategory), rating, status enums, formatSlots, registry title resolve via `workId`.

---

## 3. `CollectibleItem` 최소 필드셋 (설계안)

Archive-First · 기존 모델에서 **mapping 가능한** 최소 union:

```dart
/// 설계안 — 구현 아님
enum CollectibleKind {
  work,           // AkashaItem / RegistryWork
  person, concept, event, place, organization, custom,
}

class CollectibleItem {
  const CollectibleItem({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.coverUri,
    this.summary,
    this.tags = const [],
    this.archived = false,
    this.catalogOnly = false,
    this.addedAt,
    // Work-only optional
    this.mediaCategory,
    this.rating,
    this.statusLabel,
    this.formatSlots = const [],
    this.franchiseId,
    // Entity-only optional
    this.aliases = const [],
    this.incomingLinkCount,
  });

  final String id;              // workId | entityId
  final CollectibleKind kind;
  final String title;
  final String? subtitle;       // creator | aliases[0] | type badge text
  final String? coverUri;       // posterPath; Entity null → type placeholder
  final String? summary;        // description | journal body preview
  final List<String> tags;
  final bool archived;          // vault .md exists
  final bool catalogOnly;       // catalog hit without journal
  final DateTime? addedAt;

  // Work extension
  final MediaCategory? mediaCategory;
  final double? rating;
  final String? statusLabel;
  final List<FormatSlot> formatSlots;
  final String? franchiseId;

  // Entity extension
  final List<String> aliases;
  final int? incomingLinkCount; // link_index derived
}
```

### Mapping table

| CollectibleItem | Work (`AkashaItem`) | Entity (`UserCatalogEntity` + journal) |
|-----------------|---------------------|----------------------------------------|
| `id` | `workId` | `entityId` |
| `kind` | `work` | `anchorType` |
| `title` | `title` / registry | `title` |
| `subtitle` | `creator` | `aliases.join` or type label |
| `coverUri` | `posterPath` | — (Phase 1: null) |
| `summary` | `description` (card 미사용) | `EntityJournalEntry.body` preview |
| `tags` | `tags` | **없음** → Phase 2+ |
| `archived` | `isArchivedInVault` | journal file exists |
| `catalogOnly` | registry-only virtual | catalog without `.md` |
| `mediaCategory` | `category` | `subtype` (Work entity only) |
| `rating` / `statusLabel` | ✅ | — |
| `formatSlots` / `franchiseId` | ✅ | — |
| `incomingLinkCount` | — (optional) | `linkIndex.incoming` |

---

## 4. EntityCollectibleCard vs CollectibleCard 통합

### 4.1 안 A — `PosterCard` 유지 + `EntityCollectibleCard` 추가

| 항목 | 평가 |
|------|------|
| **변경 파일** | **신규 2~4** (`entity_collectible_card.dart`, `entity_browse_card.dart`, optional grid section) · **수정 6~10** (`catalog_entity_browse_view.dart`, `browse_view` scope strip, `entity_journal_view` optional, tests) |
| **회귀 위험** | **낮음** — Work 경로 무변경 |
| **Workbench** | **영향 없음** — tap → `showEntityJournalDialog` |
| **BrowsePipeline** | **영향 없음** — Entity는 parallel `EntityBrowseLoader` |

### 4.2 안 B — `CollectibleCard` 통합

| 항목 | 평가 |
|------|------|
| **변경 파일** | **신규 3~5** + **수정 25~40** (`poster_card`, `browse_card`, `browse_pipeline`, `my_library_pipeline`, `franchise_fusion_service`, `home_poster_card_factory`, `browse_dashboard_sections`, `personal_library_view`, `browse_view`, `work_draggable_card`, `status_helpers`, filters, tests) |
| **회귀 위험** | **높음** — DnD·fusion·status·HoF·watchlist 전부 Work 가정 |
| **Workbench** | `CollectibleItem.kind == work` 일 때만 `openWork`; Entity는 Sheet — **routing layer** 필요 |
| **BrowsePipeline** | **`BrowseCard` → `CollectibleCard` 전환** 또는 adapter; registry fusion Work 전용 유지 |

### 4.3 비교 요약

| | A EntityCollectibleCard | B CollectibleCard |
|--|:------------------------:|:-----------------:|
| 변경 규모 | ~10 files | ~35 files |
| 회귀 | 낮음 | 높음 |
| Workbench | 무영향 | 분기 필요 |
| BrowsePipeline | 무영향 | 대규모 |
| 장기 IP mixed grid | 2 카드 타입 병치 | 단일 그리드 |
| 추천 Phase | **Phase 1~2** | **Phase 3+** |

---

## 5. Entity Sheet vs Entity Workspace

### 5.1 현재

- **Entity:** `UserCatalogEntity` + optional `EntityJournalEntry` → **`EntityJournalDialog`** (modal)
- **Work:** `AkashaItem` → **`WorkDetailWorkspace`** (Workbench tab, Sanctum 3열)

### 5.2 Entity Sheet 유지 (추천 Phase 1~2)

| 장점 | 단점 |
|------|------|
| 이미 journal 편집·incoming·same-day·link index 연동 | modal — multi-entity compare 불편 |
| Workbench와 **관심사 분리** (Fact journal vs Sanctum work) | 카드 grid → sheet 반복 open |
| R2-B~D 투자 재사용 | Workbench급 split pane 없음 |

### 5.3 Entity Workspace (WorkDetailWorkspace 유사)

| 장점 | 단점 |
|------|------|
| 탭·split·wiki authoring UX Work와 **패리티** | Sanctum(Work body)·rating·poster **부적합** |
| 카드 → workspace flow Work와 동일 | **대규모 신규** (entity_detail_workspace, workbench fork) |
| multi-entity research UX | `WorkbenchController` Work-tab 모델과 충돌 |

### 5.4 설계 의견

**Phase 1~2: Entity Sheet 유지.** 카드 tap → `showEntityJournalDialog` (현행).  
**Phase 3:** Entity research heavy user를 위해 **optional Entity Workspace tab** (Workbench 확장 `openEntity` vs Work `openWork`) 검토 — Sanctum 복제가 아닌 **journal + link graph + related works** 패널.

---

## 6. 장기 필터 — 필수 모델 필드

### 6.1 시나리오별

| 시나리오 | 필요 필드 / 인프라 | 현재 |
|----------|-------------------|------|
| **「영웅」 태그 Person만** | `Entity.tags[]` 또는 journal frontmatter `tags` | ❌ **없음** |
| **리제로 등장인물** | (a) `relatedWorkIds[]` / franchiseId (b) link index: incoming from `wk_u_rezero` (c) journal wiki links | △ link index **가능** · explicit relation **없음** |
| **마녀교 관련 Entity** | (a) tags (b) Concept cluster id (c) full-text / link graph query on `[[...]]` | ❌ tags 없음 · search는 title/alias |

### 6.2 반드시 필요한 필드 (장기)

| 필드 | 용도 | 우선순위 |
|------|------|:--------:|
| **`tags: List<String>`** (Entity catalog + journal) | hero, faction, theme 필터 | P0 |
| **`relatedWorkIds` / `franchiseId`** (Entity) | IP scoped collection | P1 |
| **`CollectibleItem.kind` + filter API** | type facet | P0 (존재: `EntityAnchorType`) |
| **Link index 역참조** | "이 Work에 링크된 Person" | P1 (인프라 ✅) |
| **`aliases`** | 검색·display | ✅ 존재 |
| **`coverUri`** (optional) | card parity | P2 |
| **Derived `incomingLinkCount`** | card badge | P2 (R2-D stale count 선례) |

---

## 7. Phase 1 설계 (최소 변경 → Entity 카드 전시)

**목표:** Person/Concept/Event를 **작품 카드처럼 grid 전시** (포스터 parity 아님, **카드 컬렉션 UX**).

### 7.1 범위

| 포함 | 제외 |
|------|------|
| `EntityCollectibleCard` widget | `CollectibleCard` 통합 |
| `EntityBrowseCard` view model | BrowsePipeline / MyLibraryPipeline 변경 |
| `CatalogEntityBrowseView` grid mode | Entity Workspace |
| archived badge, type icon, title, alias subtitle | cover image, rating, tags filter |
| body preview (journal 있을 때) | Workbench 변경 |
| tap → `showEntityJournalDialog` | franchise mixed grid |

### 7.2 신규 (설계)

```
lib/models/entity_browse_card.dart
  - UserCatalogEntity entity
  - EntityJournalEntry? journal
  - bool isArchived (vault loader)
  - int staleLabelRecordCount? (optional, 0 hide)

lib/widgets/entity_collectible_card.dart
  - type icon + gradient (EntityAnchorType)
  - title, subtitle (alias or type)
  - archived badge
  - optional summary (journal body 120 chars — EntityJournalView._preview 패턴)
  - onTap

lib/services/entity_browse_loader.dart (optional)
  - userCatalog + EntityVaultLoader → List<EntityBrowseCard>
```

### 7.3 수정 (설계)

| 파일 | 변경 |
|------|------|
| `catalog_entity_browse_view.dart` | ListView → `GridView` + `EntityCollectibleCard` |
| `browse_view.dart` | Entity discovery strip compact → collectible card (optional) |
| tests | widget smoke for entity card grid |

### 7.4 데이터 흐름 (Phase 1)

```
userCatalog.all (non-work)
  + EntityVaultLoader.findByEntityId (archived?)
  + optional linkIndex (incoming count — later)
→ EntityBrowseCard
→ EntityCollectibleCard
→ onTap → showEntityJournalDialog
```

### 7.5 Phase 2~3 로드맵 (참고)

| Phase | 내용 |
|-------|------|
| **2** | Entity tags · dashboard Entity scope grid · Fusion grid tiles |
| **3** | `CollectibleItem` adapter · IP mixed view (franchise + linked entities) |
| **4** | CollectibleCard unify · optional Entity Workspace tab |

---

## 8. 관련 파일

| 영역 | 파일 |
|------|------|
| Work model | `lib/models/akasha_item.dart` |
| Work card | `lib/widgets/poster_card.dart`, `lib/screens/home/home_poster_card_factory.dart` |
| Grid model | `lib/models/browse_card.dart` |
| Pipeline | `lib/services/browse_pipeline.dart`, `lib/services/my_library_pipeline.dart` |
| Entity model | `lib/models/user_catalog_entity.dart`, `lib/core/archiving/entity_journal_entry.dart` |
| Entity UI | `lib/screens/home/views/catalog_entity_browse_view.dart`, `entity_journal_dialog.dart` |
| Workbench | `lib/features/workbench/presentation/work_detail_workspace.dart` |
| Link filter infra | `lib/services/record_link_index_service.dart` |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Step 0.5 Collectible Architecture Audit |
