# R2-E Step 3 — Entity Collection Surface Audit

> **상태:** 조사 완료 (구현 없음)  
> **날짜:** 2026-06-19  
> **상위:** [Step 2 Relation Discovery](r2e-step2-entity-relation-discovery-audit.md) · [Step 1.5 Vision](r2e-step1.5-entity-collection-vision-audit.md)

---

## Executive Summary

`CatalogEntityBrowseView`는 **Grid 없음** — full mode는 **세로 `ListView` + `ListTile`**, compact mode는 **가로 `ListView` + `_CompactEntityCard`**.  
**첫 Entity Collection 화면 = `CatalogEntityBrowseView` (non-compact)** — routing·type filter·Sheet tap 이미 완비.  
`BrowseDashboardSections` / `PersonalLibraryView`는 **`BrowseCard` / workId 전용** — Phase 1 부적합.  
**최소 변경:** `entity_collectible_card.dart` + `catalog_entity_browse_view.dart` full branch만 Grid화 · `_openEntity` 유지.

---

## 1. `CatalogEntityBrowseView` Grid/List 구조

### 1.1 현재 레이아웃 (코드)

| 모드 | 트리거 | 레이아웃 | 셀 위젯 | 크기 |
|------|--------|----------|---------|------|
| **compact** | `compact: true` | `Column` → 가로 `ListView.separated` | `_CompactEntityCard` | strip H=132, card W=140 |
| **full** | `compact: false` (기본) | `Column` → 세로 `ListView.separated` | `ListTile` + `Material` | full width row |

**GridView / `BrowsePosterGrid` / `Wrap` 그리드 — 사용하지 않음.**

### 1.2 데이터 로드

```61:77:lib/screens/home/views/catalog_entity_browse_view.dart
  Future<void> _reload() async {
    ...
    final typeFilter = widget.scope.catalogEntityType;
    final all = widget.userCatalog.all.where((e) => !e.isWorkEntity);
    final filtered = typeFilter == null
        ? all.toList()
        : all.where((e) => e.anchorType == typeFilter).toList();
    filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
```

- 소스: **`UserCatalogPort` only** — journal body · incoming count **미로드**
- tap: `_openEntity` → `EntityVaultLoader.findByEntityId` → `showEntityJournalDialog`

### 1.3 배치 (routing)

```265:312:lib/screens/home/home_shell_body.dart
  if (!scope.showsWorkGrid) {
    return CatalogEntityBrowseView(..., compact: false);
  }
  return Column(
    children: [
      _entityDiscoveryStrip(),  // compact: true, scope: all
      Expanded(child: workGrid),  // BrowseView
    ],
  );
```

| `BrowseEntityScope` | 메인 영역 |
|-------------------|-----------|
| `work`, `all` | Work `BrowseView` (+ `all`일 때 Entity strip) |
| `person`, `concept`, `event`, `place`, `organization` | **full `CatalogEntityBrowseView`** |

### 1.4 EntityCollectibleCard — 최소 변경 경로

| 순위 | 변경 | 파일 | 회귀 |
|:----:|------|------|------|
| 1 | `EntityCollectibleCard` widget | **신규** `lib/widgets/entity_collectible_card.dart` | 없음 |
| 2 | `EntityBrowseCard` view model | **신규** `lib/models/entity_browse_card.dart` | 없음 |
| 3 | full mode `ListView` → scroll + **`BrowsePosterGrid` 패턴 Wrap** | **수정** `catalog_entity_browse_view.dart` L171-200 | Entity browse only |
| 4 | `_reload` journal batch (optional Phase 1) | 동일 파일 + `EntityVaultLoader` | lazy per-card 가능 |
| 5 | compact strip | **유지** `_CompactEntityCard` (Phase 1.1 optional upgrade) | — |

**건드리지 않음:** `home_shell_body`, `BrowseDashboardSections`, `PersonalLibraryView`, `BrowsePipeline`, `_openEntity` / `showEntityJournalDialog`.

**Grid 구현:** `BrowsePosterGrid`는 `List<BrowseCard>` 전용 — Entity는 **동일 Wrap 수식 복제** (`cardMinWidth` 170, `childAspectRatio` ~0.65–0.72, poster 없음).

---

## 2. 첫 Entity Collection 화면 — 3-way 비교

| 화면 | Entity 전시 | type filter | Sheet tap | Phase 1 적합 |
|------|:-----------:|:-----------:|:---------:|:------------:|
| **`CatalogEntityBrowseView` (full)** | ✅ 전용 | ✅ `BrowseEntityScope` | ✅ `_openEntity` | **✅ 최적** |
| `CatalogEntityBrowseView` (compact strip) | △ 미리보기 | `all` only | ✅ | 보조 strip |
| **`BrowseDashboardSections`** | ❌ | ❌ Work | Workbench | ❌ |
| **`PersonalLibraryView`** | ❌ | ❌ workId membership | Workbench | ❌ |
| `EntityJournalView` (Records 탭) | △ list | ❌ 시간순 | ✅ | journal 축, gallery 아님 |

### 2.1 `BrowseDashboardSections` — 부적합

- 입력: `List<BrowseCard>` · `posterCardBuilder(BrowseCard)`
- HoF / watchlist / year / `MediaCategory` — **Work 전용**
- `BrowseView` childAspectRatio **0.78** · `PosterCard`

### 2.2 `PersonalLibraryView` — 부적합

- `myLibraryPipeline` → **`BrowseCard` / workId** only
- `applyCuratedGridReorder` → **`memberOrder` workId**
- **개인 서재 모드**에서도 browse 영역은 `PersonalLibraryView` 고정 — **`entityScope` chip을 Person으로 바꿔도 Entity gallery로 전환되지 않음** (`home_shell_body` L239-251)

### 2.3 권장: Entity Gallery = **`CatalogEntityBrowseView` full mode**

- Filter `Person` / `Concept` chip → 이미 full-screen Entity browse
- Work 대규모 Collectible 통합 **불필요** (장기 과제)

---

## 3. 「Person만 / Concept만」— 기존 필터 지원

### 3.1 ✅ 지원 (type axis)

| UI | 코드 |
|----|------|
| Scope chips | `FilterSection` — `BrowseEntityScope.values` 전부 |
| Person only | `BrowseEntityScope.person` → `catalogEntityType == EntityAnchorType.person` |
| Concept only | `BrowseEntityScope.concept` |
| Event / Place / Org | 동일 패턴 |
| All entities (non-work) | `BrowseEntityScope.all` → `catalogEntityType == null` |

**테스트:** `test/browse_entity_scope_test.dart`

### 3.2 ❌ 미지원 (장기 vision)

| 필터 | 이유 |
|------|------|
| Tag (「영웅」) | tags 필드 없음 |
| Re:Zero 연결 Person | relatedWorks UI/filter 없음 (Step 2: API 조합만 가능) |
| Concept 연결 Entity | 동일 |
| Work scope 내 Entity grid | `showsWorkGrid` → Work grid 우선 |

### 3.3 기본 scope

`HomeBrowseFilterController.entityScope` **default = `BrowseEntityScope.work`** — Entity gallery 진입 시 사용자가 **Person/Concept chip 선택** 필요.

---

## 4. Grid 추가 + `EntityJournalDialog` 유지

### 4.1 결론 — **✅ 가능**

`_openEntity` (L80-96)는 **itemBuilder와 독립**. Grid cell `onTap: () => _openEntity(card.entity)` 만 연결.

```dart
// 변경 없음 — grid/itemBuilder만 교체
await showEntityJournalDialog(
  context,
  entity: entity,
  entry: entry,
  linkIndex: widget.linkIndex,
  ...
);
```

| 유지 | 변경 |
|------|------|
| `showEntityJournalDialog` | ListTile → `EntityCollectibleCard` |
| `EntityVaultLoader.findByEntityId` on tap | 레이아웃 ListView → Wrap grid |
| `linkIndex` / `vaultItems` props | `_reload` enrichment (optional) |

**Workbench / Work 경로 무영향.**

---

## 5. `EntityBrowseCard` — 존재 필드만

### 5.1 모델 (설계)

```dart
/// lib/models/entity_browse_card.dart — 설계, 미구현
class EntityBrowseCard {
  const EntityBrowseCard({
    required this.entity,
    this.journal,
    required this.isArchived,
    this.incomingRecordCount = 0,
  });

  /// catalog SSOT — lib/models/user_catalog_entity.dart
  final UserCatalogEntity entity;

  /// vault journal — lib/core/archiving/entity_journal_entry.dart
  final EntityJournalEntry? journal;

  /// derived: journal != null (EntityVaultLoader.findByEntityId)
  final bool isArchived;

  /// derived: linkIndex.incomingRecordPaths(entity.entityId).length
  final int incomingRecordCount;
}
```

### 5.2 `UserCatalogEntity` (card가 직접 사용)

| 필드 | 카드 Phase 1 |
|------|:------------:|
| `entityId` | △ optional footer |
| `entityType` / `anchorType` | ✅ badge · icon |
| `title` | ✅ |
| `aliases` | ✅ subtitle |
| `addedAt` | △ sort only (이미 list order) |
| `subtype`, `titles`, `creator`, `releaseYear`, `domain` | ❌ Phase 1 미표시 |

### 5.3 `EntityJournalEntry` (journal != null)

| 필드 | 카드 Phase 1 |
|------|:------------:|
| `body` | ✅ preview (`EntityJournalView._preview` — 120자) |
| `title`, `entityType`, `entityId`, `addedAt` | mirror catalog; card는 catalog 우선 |
| `storagePath` | loader only |

### 5.4 파생 (저장 없음 · 기존 API)

| 파생 | 출처 |
|------|------|
| `isArchived` | `journal != null` |
| `catalogOnly` | getter `journal == null` |
| `bodyPreview` | `journal?.body` → trim 120자 (기존 `_preview` 패턴) |
| `incomingRecordCount` | `RecordLinkPort.incomingRecordPaths` |
| `typeBadgeLabel` | `entityTypeBadgeLabel(entity.anchorType)` |

**포함하지 않음 (Phase 1 · 코드 없음):** `tags`, `coverUri`, `relatedWorkTitle`, `staleLabelCount` (Sheet 전용).

### 5.5 빌드 입력 (loader)

| 입력 | 기존 API |
|------|----------|
| entities | `userCatalog.all` + scope filter |
| journal map | `EntityVaultLoader.loadFromVault` or per-id `findByEntityId` |
| incoming | `linkIndex.incomingRecordPaths` (linkIndex null → 0) |

---

## 6. `EntityCollectibleCard` Phase 1 — Flutter 위젯 mockup

### 6.1 참조 위젯 (코드에 존재)

| 위젯 | 차용 |
|------|------|
| `PosterCard` | `MouseRegion` hover, `AnimatedContainer` translateY(-4), `BorderRadius 10`, `_buildArchivedBadge` 형태 |
| `PosterCard._buildFactCardLayout` | header H≈58 gradient + icon 30×30 — **EntityAnchorType icon**으로 대체 |
| `_CompactEntityCard` | type badge + title (compact strip) |
| `EntityJournalView` list row | preview text style (grey 13px) |
| `BrowsePosterGrid` | cell sizing Wrap |

### 6.2 `EntityCollectibleCard` API (설계)

```dart
class EntityCollectibleCard extends StatefulWidget {
  const EntityCollectibleCard({
    super.key,
    required this.card,
    required this.onTap,
    this.highlighted = false,
  });

  final EntityBrowseCard card;
  final VoidCallback onTap;
  final bool highlighted;
}
```

### 6.3 위젯 트리 mockup

```
MouseRegion
└─ GestureDetector(onTap)
   └─ AnimatedContainer                    // PosterCard 패턴
      decoration: BoxDecoration(
        color: #1E1E2E,
        borderRadius: 10,
        border: highlighted ? tealAccent : white12,
        boxShadow: [depth + idle glow],
      )
      child: Column(stretch)
         ├─ SizedBox(height: 52)            // fact-card header 단축
         │  └─ Stack
         │     ├─ DecoratedBox(gradient)    // tealAccent for Person — 고정 palette 없음; icon color만 존재
         │     └─ Padding(11,8)
         │        Row: [Icon 30x30] [entityTypeBadgeLabel] Spacer [archived badge if isArchived]
         ├─ Padding(12,8)                   // body
         │  Column(crossAxis start)
         │    Text(title, 14 w800, maxLines: 2)
         │    if aliases.isNotEmpty
         │      Text(aliases.first, 11 grey, maxLines: 1)
         │    SizedBox(6)
         │    if journal?.body.isNotEmpty
         │      Text(bodyPreview, 13 grey300, maxLines: 3)   // _preview 120자
         │    else
         │      Text('(메모 없음)', italic grey500)
         │    Spacer()
         │    if incomingRecordCount > 0
         │      Text('🔗 Record $incomingRecordCount', 10 tealAccent)
         └─ (no rating/status/footer)
```

### 6.4 Grid 배치 mockup (`CatalogEntityBrowseView` full)

```
Column
├─ Padding: "${scope.label} 아카이브 (N)"     // 기존 L164-169
└─ Expanded
   └─ Scrollbar + SingleChildScrollView       // ListView 대체
      └─ LayoutBuilder
         └─ Wrap                             // BrowsePosterGrid L46-55 동형
            spacing: 12, runSpacing: 12
            padding: 16
            for each EntityBrowseCard:
              SizedBox(
                width: cellWidth,              // (maxWidth-32-spacing*(cols-1))/cols
                height: cellWidth / 0.68,      // poster 0.78보다 낮은 ratio
                child: EntityCollectibleCard(
                  card: card,
                  highlighted: entityId == highlightEntityId,
                  onTap: () => _openEntity(card.entity),
                ),
              )
```

### 6.5 compact strip (Phase 1 optional — 변경 없음)

기존 `_CompactEntityCard` 140×132 가로 스크롤 유지. Phase 1.1에서 동일 `EntityCollectibleCard` compact variant 검토.

---

## 7. Vision 정렬 (Collectible 독립 전시)

| Vision | Step 3 코드 현실 |
|--------|------------------|
| Entity = 독립 Collectible | ✅ `CatalogEntityBrowseView` 전용 surface |
| Work metadata 아님 | ✅ Work pipeline 분리 유지 |
| Person/Concept gallery | ✅ scope filter 존재 — **grid UI만 부재** |
| Tag / IP filter | ❌ Phase 2+ |
| Personal library Entity | ❌ `PersonalLibraryView` workId only |
| 감상 = Sheet | ✅ dialog path 유지 |

**Phase 1 Entity Gallery = Filter chip (Person) → `CatalogEntityBrowseView` Grid of `EntityCollectibleCard` → Sheet.**

---

## 8. Step 4 구현 체크리스트

1. `EntityBrowseCard` model
2. `EntityCollectibleCard` widget (§6.3)
3. `CatalogEntityBrowseView` — full branch Wrap grid + journal/incoming enrich in `_reload`
4. Widget test: Person scope grid smoke, tap → dialog (lightweight)
5. **하지 않음:** BrowseDashboardSections / PersonalLibraryView / Workbench

---

## 9. 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/screens/home/views/catalog_entity_browse_view.dart` | Entity gallery SSOT |
| `lib/screens/home/home_shell_body.dart` | scope routing |
| `lib/widgets/filter_section.dart` | type scope chips |
| `lib/models/browse_entity_scope.dart` | person/concept/… filter |
| `lib/widgets/browse_poster_grid.dart` | Grid Wrap reference |
| `lib/widgets/poster_card.dart` | card chrome reference |
| `lib/screens/home/views/entity_journal_view.dart` | preview pattern |
| `lib/screens/home/views/records_view.dart` | Entity journal tab (non-gallery) |
