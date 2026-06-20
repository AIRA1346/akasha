# R2-E Step 1.5 — Entity Collection Vision Audit

> **상태:** 조사 완료 (구현 없음)  
> **날짜:** 2026-06-19  
> **상위:** [Step 1 Information Audit](r2e-step1-entity-collectible-information-audit.md) · [Step 0.5 Architecture](r2e-step0.5-collectible-architecture-audit.md)

---

## Executive Summary

장기 비전(Work · Person · Concept · Event 각각 독립 Collectible) 대비 **현재 Entity는 Work browse 스택 밖**에 있다.  
Phase 1은 `PosterCard` **직접 재사용 불가** → **`EntityBrowseCard` + `EntityCollectibleCard`** 병렬 추가가 최소 경로.  
상세 진입은 **Entity Sheet(Dialog) 유지**가 맞고, Entity Workspace는 Phase 3+.  
Work 통합 Collectible 추상화가 필요해지면 **`BrowseDashboardSections`가 최초 대상** — 단 Entity-only 수집은 `CatalogEntityBrowseView`로 우회 가능.

---

## 1. PosterCard → EntityCard 기반 재사용 가능성

### 1.1 결론

**아키텍처 “패턴”은 차용 가능, 위젯 “그대로” 재사용은 불가.**

`PosterCard`는 `AkashaItem` + `MediaCategory` + status/rating에 **하드 결합**되어 있다.  
rating · status · poster · franchise fusion을 제외해도 **남는 shell(호버 lift, archived badge, fact-card gradient header)은 Entity에 매핑 가능한 UX 언어**이지만, **입력 타입을 바꾸지 않고는 Entity에 plug-in 할 수 없다.**

### 1.2 PosterCard 의존성 (코드 기준)

| 영역 | 소스 | Entity 매핑 |
|------|------|:-----------:|
| 입력 | `AkashaItem item` 필수 | ❌ `UserCatalogEntity` 아님 |
| 포스터 레이아웃 | `PosterImage(item)` | ❌ `posterPath` 없음 |
| Fact 레이아웃 | `_buildFactCardLayout` — category gradient + icon | △ `EntityAnchorType` icon/badge로 **유사 UI 신규** |
| Border/glow | `isWatchlistItem` / `isFinishedItem` + category | ❌ Entity status 없음 |
| Meta | `resolveCatalogDisplayTitle(item)` · `creator` | △ `title` · `aliases` |
| Footer | `_buildRatingStatusRow` · `_buildFactCardFooter` | ❌ rating/status |
| Chips | `FormatChipRow(formatSlots)` | ❌ |
| Badges | `_buildArchivedBadge` · `isArchivedInVault(item)` | △ journal 존재 = archived (다른 API) |
| Context menu | `onOpenLibraryMenu` (Work library) | ❌ |

**Fact card mode (`showPoster: false`)** 가 Entity와 **시각적으로 가장 가깝다** (gradient header 58px + type icon + title + subtitle).  
그러나 footer가 여전히 status/rating이고 `item.category: MediaCategory`가 필수다.

### 1.3 재사용 가능 vs 불가

| 재사용 | 불가 (Entity 전용 구현) |
|--------|-------------------------|
| 카드 chrome: `AnimatedContainer` hover translate, shadow, `BorderRadius 10` | `PosterCard` 클래스에 Entity prop 추가 |
| `_buildArchivedBadge` **시각** (📄 circle) | `AkashaFileService.isArchivedInVault` |
| Fact-card **레이아웃 아이디어** (header / body / footer 3단) | `PosterImage`, `StarRating`, `FormatChipRow` |
| Grid metrics (`BrowseGridMetrics`, aspect ~0.48) | status border color logic |

**Phase 1 권장:** `EntityCollectibleCard` **신규 위젯** — PosterCard fact layout을 **복제·단순화** (rating/status/poster 제거, `EntityAnchorType` accent).

---

## 2. Collectible 승격 — 어떤 계층이 먼저?

### 2.1 현재 Entity browse 경로

```
FilterSection (BrowseEntityScope)
  → home_shell_body._buildDashboardBrowseContent
      → scope.showsWorkGrid == false  → CatalogEntityBrowseView (ListView / compact strip)
      → scope all|work                → BrowseView + Entity Discovery strip
  tap → showEntityJournalDialog
```

Work 경로:

```
BrowsePipeline / MyLibraryPipeline → List<BrowseCard> → BrowseView / PersonalLibraryView
  → BrowseDashboardSections → posterCardBuilder → PosterCard
  tap → onOpenBrowseItem → Workbench
```

**Entity는 BrowsePipeline을 거치지 않는다.**

### 2.2 계층 우선순위

| 순위 | 계층 | 이유 |
|:----:|------|------|
| **1** | **`EntityBrowseCard`** (view model) | `UserCatalogEntity` + `EntityJournalEntry?` + `isArchived` + optional `incomingCount` 조합 SSOT. 현재 browse는 raw catalog만 사용. |
| **2** | **`EntityCollectibleCard`** (presentation) | grid/list **전시** 목표의 최소 deliverable. `CatalogEntityBrowseView` 교체 대상. |
| **3** | `EntityBrowseLoader` (optional service) | vault loader + linkIndex count를 card model로 merge — card/widget 다음 또는 동시. |
| **4** | **`EntityCollectionPipeline`** | tag filter · mixed IP scope · reorder. **tags 필드 없음** → Phase 2 이후. Work `BrowsePipeline`과 **병렬** 유지. |

**`EntityCollectionPipeline`은 가장 나중.**  
Phase 1에 필요한 것은 pipeline이 아니라 **card model + card widget + browse view wiring**.

### 2.3 EntityBrowseCard 최소 shape (설계, 미구현)

```dart
class EntityBrowseCard {
  final UserCatalogEntity entity;
  final EntityJournalEntry? journal;
  final bool isArchived;       // journal file exists
  final int incomingRecordCount; // linkIndex.incomingRecordPaths.length
}
```

---

## 3. Phase 1 — Sheet 유지 vs EntityWorkspace

### 3.1 결론

**Phase 1~2: 카드 tap → `EntityJournalDialog`(Entity Sheet) 유지가 맞다.**  
**초기부터 EntityWorkspace를 고려할 필요 없음** (Phase 3 optional).

### 3.2 근거

| | Entity Sheet (현재) | Entity Workspace (미존재) |
|--|---------------------|---------------------------|
| 구현 | ✅ journal CRUD, incoming, same-day, wiki links | ❌ Workbench fork 대규모 |
| Workbench | 분리 — Fact journal vs Sanctum Work | `WorkbenchController` Work-tab 모델 충돌 |
| 카드 flow | `catalog_entity_browse_view._openEntity` → dialog | Work `onOpenBrowseItem` 패리티 필요 |
| R2-B~D 투자 | 재사용 | 이전 |

`EntityJournalDialog`는 이미 **상세 페이지 역할**을 수행한다 (modal이지만 기능 완결).  
Work의 `WorkDetailWorkspace`는 rating · poster · Sanctum · format fusion 전제 — Entity에 **부적합**.

### 3.3 Phase 3 검토 시점

- multi-entity compare · split pane research UX
- optional Workbench tab `openEntity` (Sanctum 복제 아님: journal + link graph)

---

## 4. Collectible 추상화 — BrowseDashboardSections vs CuratedReorderGrid vs PersonalLibraryView

### 4.1 Phase 1 (Entity-only 수집)

**세 레이어 모두 변경 불필요.**  
Entity 수집은 이미 **`CatalogEntityBrowseView`** + `BrowseEntityScope` 필터로 분리되어 있다.

### 4.2 장기 (Collectible = Work \| Person \| Concept \| Event **단일 그리드**)

| 레이어 | Work 결합도 | Collectible 추상화 필요 시점 |
|--------|------------|------------------------------|
| **`BrowseDashboardSections`** | **최고** — `List<BrowseCard>`, HoF/watchlist/year/category section, `SortCriteria` on AkashaItem, `posterCardBuilder` | **가장 먼저** (또는 Phase 3까지 Entity parallel grid 유지) |
| **`PersonalLibraryView`** | **높음** — `BrowseCard` + `memberOrder` by **workId** | 두 번째 — curated library에 Entity 멤버십 |
| **`CuratedReorderGrid`** | **중간** — `BrowseCard` + DnD | 세 번째 — PersonalLibraryView 하위 |

**우선순위:** `BrowseDashboardSections` → `PersonalLibraryView` → `CuratedReorderGrid`

### 4.3 현실적 Phase 분리

| Phase | 전략 |
|-------|------|
| 1~2 | Work stack **무변경**; Entity = `CatalogEntityBrowseView` + `EntityCollectibleCard` |
| 3 | IP mixed grid → `CollectibleItem` union + `BrowseDashboardSections` adapter **또는** dual `cardBuilder` |
| 4 | Personal library Entity membership + `CuratedReorderGrid` generalize |

**Tag 필터(「영웅」만)** 는 browse section 추상화 **이전**에 **`Entity.tags` + filter API** (모델)가 선행.

---

## 5. 「나츠키 스바루」카드 — 사용 가능 필드만 Mock

### 5.1 사용 필드 (가정 금지)

| 필드 | 소스 | 카드 조건 |
|------|------|----------|
| `title` | catalog / journal mirror | 항상 |
| `aliases` | catalog | 비어 있으면 행 생략 |
| body preview | `EntityJournalEntry.body` + `_preview` (120자) | journal 있을 때만 |
| `archived` | `EntityVaultLoader.findByEntityId != null` | badge on/off |
| incoming count | `linkIndex.incomingRecordPaths(entityId).length` | linkIndex 전달 시; 0이면 생략 가능 |

**사용하지 않음:** cover, tags, resolved linked works, rating, status, entityId(요청 범위外), stale count(요청 범위外).

### 5.2 Grid cell spec (Work grid metrics 호환)

- **cell:** `BrowseGridMetrics` 기준 ~170px min width, aspect **~0.65** (포스터 0.48보다 짧음 — 이미지 없음)
- **tap:** `showEntityJournalDialog` (현행)

### 5.3 Mock — journal 있음 · aliases 1 · incoming 3

```
╔═══════════════════════════════╗  ← border: EntityAnchorType.person accent (teal)
║ ░░░ gradient header 52px ░░░  ║
║  👤  Person              📄   ║  ← type icon + badge label + archived badge
╠═══════════════════════════════╣
║  나츠키 스바루                 ║  ← title, 14px w800, max 2 lines
║  ナツキ・スバル                ║  ← aliases[0], 11px grey, max 1 line
║                               ║
║  Re:Zero 1기 시청 후          ║  ← body preview 120자 (grey 13px)
║  등장인물으로 기록. [[wk_u_   ║     max 3 lines ellipsis
║  rezero01|Re:Zero]] 성격: …   ║
║                               ║
║  ─────────────────────────    ║
║  🔗 Record 3                  ║  ← incoming count footer (linkIndex)
╚═══════════════════════════════╝
     hover: translateY(-4) + glow (PosterCard 패턴 차용)
```

### 5.4 Mock — catalog-only (journal 없음)

```
╔═══════════════════════════════╗
║ ░░░ gradient header 52px ░░░  ║
║  👤  Person                   ║  ← archived badge 없음
╠═══════════════════════════════╣
║  나츠키 스바루                 ║
║  ナツキ・スバル                ║
║                               ║
║  (메모 없음)                   ║  ← preview placeholder (grey italic)
║                               ║
║  🔗 Record 3                  ║  ← incoming은 journal 없어도 index 가능
╚═══════════════════════════════╝
```

### 5.5 Mock — incoming 0 · aliases 없음

```
╔═══════════════════════════════╗
║  👤  Person              📄   ║
╠═══════════════════════════════╣
║  나츠키 스바루                 ║
║                               ║
║  Re:Zero 1기 시청 후 …        ║
║                               ║
║  (footer 생략)                ║  ← incoming 0 → footer row 없음
╚═══════════════════════════════╝
```

### 5.6 오늘 이미 있는 UI와 비교

| UI | title | aliases | preview | archived | incoming |
|----|:-----:|:-------:|:-------:|:--------:|:--------:|
| `_CompactEntityCard` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `EntityJournalView` row | ✅ | ❌ | ✅ | △ implicit | ❌ |
| **제안 EntityCollectibleCard** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 6. Vision ↔ 코드 갭 (요약)

| Vision | 현재 | Gap |
|--------|------|-----|
| Person만 모아 감상 | `BrowseEntityScope.person` → `CatalogEntityBrowseView` | ListView — **grid card 미구현** |
| Concept / Event 수집 | scope filter ✅ | 동일 |
| Tag(영웅) 필터 | ❌ tags 없음 | catalog + frontmatter `tags` Phase 2 |
| Work와 동급 카드 UX | PosterCard vs compact strip | `EntityCollectibleCard` Phase 1 |
| IP mixed grid (Re:Zero + 캐스트) | Work grid + Entity strip 분리 | Phase 3 Collectible union |
| 카드 → 상세 | Sheet ✅ | Workspace 불필요 Phase 1 |

---

## 7. Step 2 진입 체크리스트

1. `EntityBrowseCard` model
2. `EntityCollectibleCard` widget (PosterCard fact layout **참고**, AkashaItem **미사용**)
3. `CatalogEntityBrowseView` — ListView → GridView (optional `EntityBrowseLoader`)
4. tap → `showEntityJournalDialog` **유지**
5. tests: grid smoke, preview/archived/incoming rendering

---

## 8. 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/widgets/poster_card.dart` | Work card — Entity 직접 재사용 ❌ |
| `lib/models/browse_card.dart` | Work IP 1장 — Entity ❌ |
| `lib/screens/home/views/catalog_entity_browse_view.dart` | Entity browse SSOT |
| `lib/screens/home/home_shell_body.dart` | Work/Entity routing |
| `lib/screens/home/views/entity_journal_view.dart` | `_preview` 패턴 |
| `lib/screens/home/dialogs/entity_journal_dialog.dart` | Sheet + incoming count |
| `lib/widgets/browse_dashboard_sections.dart` | Work sections — 장기 abstract 1순위 |
| `lib/screens/home/views/personal_library_view.dart` | workId membership |
| `lib/widgets/curated_reorder_grid.dart` | BrowseCard DnD |
