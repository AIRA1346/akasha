# R2-E Phase 1 — Entity Gallery Sort Audit

> **상태:** 조사·설계 (구현 없음)  
> **날짜:** 2026-06-19  
> **상위:** [Phase 1 Implementation Plan](r2e-phase1-entity-gallery-implementation-plan.md)

---

## Executive Summary

현재 `CatalogEntityBrowseView`는 **`addedAt` 내림차순 하드코딩** · **정렬 UI 없음**.  
`UserCatalogEntity`는 **`title` · `addedAt`만** 정렬에 쓸 수 있고 **`updatedAt` 없음**.  
`archived`는 catalog 필드가 아니라 **`journal != null` 파생**.  
Work `SortCriteria` **enum/UI 일부 패턴 재사용 가능** · **enum/로직 직접 재사용 ❌** (rating/year/manualOrder).  
**Phase 1 권장:** 전용 `EntityGallerySortCriteria` 3종 + header dropdown + prefs 1키.

---

## 1. 현재 `CatalogEntityBrowseView` 정렬

### 1.1 코드

```72:72:lib/screens/home/views/catalog_entity_browse_view.dart
    filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
```

| 항목 | 값 |
|------|-----|
| 기준 | `UserCatalogEntity.addedAt` |
| 방향 | **내림차순** (최근 추가 먼저) |
| UI | **없음** — 사용자 변경 불가 |
| compact strip | 동일 `_entities` list → **동일 정렬** |
| scope | Person/Concept/… filter **후** sort |

### 1.2 선례 (Entity stack)

| Surface | 정렬 |
|---------|------|
| `EntityVaultLoader.loadFromVault` | `journal.addedAt` desc |
| `EntityJournalView` | loader 순서 그대로 (시간순 journal feed) |
| `CatalogEntityBrowseView` | `catalog.addedAt` desc |

**catalog-only entity:** journal 없음 → `addedAt` = catalog 등록 시각 (`userLocal` factory 또는 add 시).

---

## 2. `UserCatalogEntity` — 정렬 가능 필드

### 2.1 모델 필드 (`lib/models/user_catalog_entity.dart`)

| 필드 | 정렬 가능 | Phase 1 | 비고 |
|------|:--------:|:-------:|------|
| **`title`** | ✅ | ✅ 이름순 | `String.compareTo` |
| **`addedAt`** | ✅ | ✅ 최근 추가 | catalog JSON · journal mirror |
| **`updatedAt`** | ❌ | ❌ | **필드 없음** (catalog · frontmatter · parser) |
| **`aliases`** | △ | ❌ | 첫 alias sort — UX unclear |
| `entityId` | △ | ❌ | id sort — gallery UX 부적합 |
| `entityType` | — | — | **filter** (`BrowseEntityScope`) not sort |
| `creator` / `releaseYear` | △ | ❌ | Person gallery 무의미 |
| `domain` / `subtype` | △ | ❌ | Work-centric |

### 2.2 `updatedAt` 조사

| 계층 | `updated_at` / `updatedAt` |
|------|:--------------------------:|
| `UserCatalogEntity` | ❌ |
| `EntityJournalEntry` | ❌ (`addedAt` only) |
| `EntityJournalParser` frontmatter | ❌ (`added_at` only) |
| `EntityVaultStore.updateEntry` | body 저장 시 **`addedAt` 유지** (L112) |
| vault file mtime | 존재하나 **코드 미사용** |

**「최근 수정순」은 Phase 1 불가** — schema 추가 없이는 불가능.

### 2.3 `archived` (파생)

| 정의 | API |
|------|-----|
| **archived** | `EntityVaultLoader.findByEntityId != null` ⇔ `EntityBrowseCard.isArchived` |
| **catalog-only** | catalog hit · journal 없음 · `isArchived == false` |

| 저장 | catalog JSON | journal |
|------|:------------:|:-------:|
| archived flag | ❌ | existence = SSOT |

**정렬:** `isArchived` bool compare — `EntityBrowseCard` 빌드 후 sort.

### 2.4 `addedAt` 의미 (archived vs catalog-only)

| 케이스 | `addedAt` source |
|--------|------------------|
| archive-first create | journal `added_at` → `EntityCatalogSync.mirrorFromJournal` |
| catalog-only add | `UserCatalogEntity.userLocal(addedAt: now)` |
| journal body edit | **변경 없음** (creation time frozen) |

→ 「최근 추가」= catalog/journal **최초 등록** 시각 · **최근 편집 아님**.

---

## 3. Work `SortCriteria` 재사용 가능성

### 3.1 Work enum (`lib/utils/helpers.dart`)

```dart
enum SortCriteria {
  manualOrder('직접 배치 순'),
  titleAsc('작품/제목명 순'),
  ratingDesc('별점 높은 순'),
  recentlyAdded('최근 추가 순'),
  yearDesc('출시 연도 순');
}
```

### 3.2 Entity 매핑

| SortCriteria | Entity 적용 | 재사용 |
|--------------|:-----------:|:------:|
| `titleAsc` | `entity.title` asc | △ 로직만 |
| `recentlyAdded` | `entity.addedAt` desc | △ 로직만 |
| `ratingDesc` | ❌ no rating | ❌ |
| `yearDesc` | ❌ `releaseYear` 무의미 | ❌ |
| `manualOrder` | ❌ memberOrder Work only | ❌ Phase 2 Collection |

### 3.3 Work sort 함수

```dart
List<BrowseCard> sortBrowseCards(List<BrowseCard> cards, SortCriteria criteria)
// compare via AkashaItem.rating, releaseYear, addedAt, title
```

**`EntityBrowseCard`에 직접 적용 불가** — `BrowseCard` / `AkashaItem` 전용.

### 3.4 UI 재사용

| | |
|--|--|
| `SectionSortDropdown` | **패턴 재사용 ✅** — generic `DropdownButton` + options list |
| `SortCriteria` enum | **직접 사용 ❌** — label 「작품/제목」「별점」「출시 연도」 |
| `HomeSectionPreferences` | **패턴 재사용 ✅** — 새 key `entity_gallery` |

**결론:** Work **SortCriteria enum/logic 재사용 ❌** · **dropdown + prefs 패턴 재사용 ✅**.

---

## 4. Phase 1 최소 정렬안 (설계)

### 4.1 전용 enum (신규)

```dart
// lib/models/entity_gallery_sort.dart — 설계
enum EntityGallerySortCriteria {
  titleAsc('이름순'),
  recentlyAdded('최근 추가순'),
  archivedFirst('아카이브 우선');

  final String label;
  const EntityGallerySortCriteria(this.label);

  static const List<EntityGallerySortCriteria> galleryOptions = [
    recentlyAdded,
    titleAsc,
    archivedFirst,
  ];
}
```

**Collectible UX:** label에서 「작품」 제거 · Entity gallery 전용 copy.

### 4.2 Sort semantics

| Criteria | Primary | Secondary | Default |
|----------|---------|-----------|:-------:|
| **recentlyAdded** | `addedAt` ↓ | `title` ↑ | **✅** (현행 유지) |
| **titleAsc** | `title` ↑ (case-insensitive 권장) | `addedAt` ↓ | |
| **archivedFirst** | `isArchived` ↓ (true first) | `title` ↑ | |

```dart
// lib/utils/entity_browse_sort.dart — 설계
List<EntityBrowseCard> sortEntityBrowseCards(
  List<EntityBrowseCard> cards,
  EntityGallerySortCriteria criteria,
) { ... }
```

### 4.3 UI 배치

```
CatalogEntityBrowseView full header (L164-169 확장):

Row(
  Text('${scope.label} … (${N})'),
  Spacer(),
  SectionSortDropdown-adjacent widget  // EntityGallerySortDropdown
)
```

- **compact strip:** sort UI **생략** (discovery preview · Phase 1)
- scope 전환 시 **동일 sort prefs** 유지 (Person/Concept 공용)

### 4.4 Persistence

```dart
// HomeSectionPreferences — Phase 1 additive
EntityGallerySortCriteria entityGallerySort = EntityGallerySortCriteria.recentlyAdded;

// SharedPreferences key: akasha_sort_entity_gallery
```

**Work `sectionPrefs`와 분리** — Entity gallery 독립 prefs.

### 4.5 Phase 1 scope

| 포함 | 제외 |
|------|------|
| 3 criteria + dropdown | `updatedAt` / 최근 수정 |
| default `recentlyAdded` | `manualOrder` (Collection) |
| sort after `_buildBrowseCards` | incoming count sort |
| prefs persist | per-scope sort (optional Phase 1.1) |

---

## 5. 향후 tags / collections 확장성

### 5.1 enum 확장 전략

```
Phase 1: EntityGallerySortCriteria (3)
Phase 2: + tagAlpha, incomingDesc?, collectionManualOrder?
Phase 3: CollectibleSortCriteria union (Work + Entity applicable subset)
```

**`SortCriteria`(Work)와 분리 유지** — Work rating/year가 Entity enum 오염 방지.

### 5.2 tags (Phase 2)

| Sort | 전제 |
|------|------|
| tagAlpha | `Entity.tags[]` schema |
| tagCount | derived |

→ `EntityGallerySortCriteria`에 값 **추가** · `sortEntityBrowseCards` switch **확장**.

### 5.3 collections (Phase 2)

| Context | Sort SSOT |
|---------|-----------|
| **Global Entity gallery** | `EntityGallerySortCriteria` (Phase 1) |
| **Named collection view** | `CollectibleCollection.memberOrder` → **`manualOrder` wins** (curated library 선례) |

Collection 화면 진입 시:

1. `memberOrder` explicit → manual (DnD Phase 2+)
2. else → collection `filter` + gallery default sort

**Phase 1 gallery sort와 충돌 없음** — collection layer가 **override**.

### 5.4 `EntityBrowseCard` sort key table (extensible)

| Future field | Sort use |
|--------------|----------|
| `tags` | tagAlpha, filter |
| `incomingRecordCount` | connection richness |
| `relatedWorkTitle` | IP grouping (Phase 2) |
| `collectionIndex` | manual order in collection view |

`sortEntityBrowseCards` = **단일 함수** · criteria enum growth — Open/closed for Phase 1.

### 5.5 Work 통합 (Phase 3)

```dart
// 장기 — 설계 sketch only
enum CollectibleSortCriteria {
  titleAsc, recentlyAdded, archivedFirst,
  ratingDesc,   // Work cards only — comparator no-op skip
  manualOrder,  // collection / curated
}
```

Entity gallery는 **`EntityGallerySortCriteria` 유지** 또는 subset map — **breaking 없이** Phase 1 prefs migrate.

---

## 6. Phase 1 구현 touch (sort only)

| | 파일 |
|--|------|
| **신규** | `lib/models/entity_gallery_sort.dart` |
| **신규** | `lib/utils/entity_browse_sort.dart` |
| **신규** | `lib/widgets/entity_gallery_sort_dropdown.dart` *(or reuse SectionSortDropdown generic)* |
| **수정** | `catalog_entity_browse_view.dart` — header dropdown · sort after card build |
| **수정** | `home_section_preferences.dart` — `entityGallerySort` load/save |
| **신규 test** | `test/entity_browse_sort_test.dart` |

**+2~3 files** to Phase 1 plan (~10 → ~12 total). **난이도: S.**

---

## 7. 권장 default · UX copy

| | |
|--|--|
| **Default** | `recentlyAdded` — 현행 hardcode와 **동일** (기존 사용자 습관 유지) |
| **First open** | Person 20+ 시 **이름순** discoverability ↑ — default 변경은 **불필요** (dropdown으로 충분) |
| **archivedFirst** | 「journal 있는 Collectible 먼저」— catalog-only 「미수집」을 아래로 |

---

## 8. 관련 코드

| 파일 | 역할 |
|------|------|
| `catalog_entity_browse_view.dart` L72 | 현재 sort |
| `user_catalog_entity.dart` | title, addedAt |
| `entity_journal_entry.dart` | addedAt mirror |
| `entity_catalog_sync.dart` | addedAt from journal |
| `helpers.dart` | Work SortCriteria · sortBrowseCards |
| `section_sort_dropdown.dart` | UI pattern |
| `home_section_preferences.dart` | Work sort persistence |
