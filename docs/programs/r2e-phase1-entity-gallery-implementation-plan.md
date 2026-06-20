# R2-E Phase 1 — Entity Gallery Implementation Plan

> **상태:** 구현 계획 + Collectible UX 정렬 (코드 미착수)  
> **날짜:** 2026-06-19  
> **범위:** Entity Gallery only — Collection · Tags · Mixed Library · Collectible 통합 · Entity Workspace **제외**

---

## 0. Collectible UX — 설계 방향 (정렬)

### 0.1 장기 비전 vs Phase 1

| | 장기 | Phase 1 (이번) |
|--|------|----------------|
| 대상 | Work · Person · Concept · Event · Place · Org = **동급 Collectible** | **Entity types only** gallery |
| 통합 | Mixed grid · CollectibleCollection | ❌ Work stack 무변경 |
| 관계 | Related Works / Entities · Tags | ❌ (Sheet graph만) |

Phase 1은 Collectible **통합 구현이 아니라**, Entity가 **독립 감상·전시 대상**임을 UX로 증명하는 단계.

### 0.2 핵심 전제 — 나츠키 스바루

> **Person은 Re:Zero의 메타데이터가 아니다.**  
> 사용자가 아카이브하고, 카드로 전시하고, Sheet에서 감상하는 **하나의 Collectible**.

| ❌ Work metadata UX | ✅ Collectible UX |
|---------------------|-------------------|
| 카드에 「Re:Zero」 부모 작품 강조 | **주인공 = `title` + `aliases` + journal preview** |
| 「등장인물」라벨로 종속 프레이밍 | header **`Person`** = Collectible **kind** (Work의 `MediaCategory`와 대칭) |
| entityId · work link가 카드 주 정보 | entityId **숨김** · 관계는 Sheet/incoming |
| ListTile = 설정 목록 | **Card grid = 감상·탐색 surface** (Poster grid와 **동급 intent**, 다른 visual) |

### 0.3 Work 감상 vs Entity 감상 (parallel, not merged)

| | Work (변경 없음) | Entity (Phase 1) |
|--|------------------|------------------|
| Gallery | PosterCard grid | **EntityCollectibleCard** grid |
| 「표지」 | poster image | type header + **title** + **body excerpt** |
| 감상 진입 | Workbench | **Entity Sheet** (journal) |
| 상태 | rating · status | archived · incoming (연결 richness) |

**같은 mental model:** grid에서 고르고 → 전용 surface에서 감상.  
**다른 implementation:** Workbench vs Sheet — Phase 1에서 **의도적 분리 유지**.

### 0.4 Phase 1 카드 copy · hierarchy

**Visual hierarchy (위 → 아래 = importance):**

1. **`entity.title`** — collectible 이름 (PosterCard title과 동급)
2. **`aliases.first`** — 부제 (creator/subtitle analog)
3. **`bodyPreview`** — 감상 teaser (poster 대신 **본인 journal** 발췌)
4. **`entityTypeBadgeLabel`** — kind chip (header, Work category label analog)
5. **`incomingRecordCount`** — footer, 작고 neutral — 「🔗 연결 N」 (**Record** count, not 「Re:Zero」)
6. **archived badge** — 「내 vault에 journal 있음」= 수집 완료 신호

**Copy 금지 (Phase 1):**

- 「Re:Zero 등장인물」「소속 작품」「→ Re:Zero」
- resolved work title badge
- tags · collection name

**Gallery chrome (full mode header):**

- 현행: `${scope.label} 아카이브 (N)` — 유지 가능
- Collectible framing: scope.label이 **Collectible kind** (Person / Concept / …) — Work의 매체 필터와 **대칭**
- optional micro-copy (Phase 1): subtitle 「카드를 눌러 journal 감상」— 구현 선택

### 0.5 Preview · wiki in body

- preview는 journal **그대로** 120자 (기존 `_preview`) — 사용자 voice 유지
- `[[wk_u_rezero01|Re:Zero]]`가 preview에 **raw로** 보일 수 있음 → **허용** (사용자 기록)
- Phase 1에서 wiki → 「Re:Zero」 **resolve 치환 ❌** (Work 종속 강조 방지 · 구현 범위)

### 0.6 이후 Phase (명시 out of scope)

| Phase | Collectible capability |
|-------|------------------------|
| 2 | Related Works badge · IP cast filter · tags |
| 3 | Mixed grid · CollectibleCollection |
| — | Work card와 visual unification |

---

## Success Criteria

> 「리제로 **포스터**를 고르듯, 나츠키 스바루 **카드**를 고르고 **Sheet에서 journal을 감상**할 수 있다」  
> (스바루 ≠ Re:Zero의 부속 정보)

| Done | Criteria |
|:----:|----------|
| ✅ | Filter **Person** → full-screen **card grid** (not ListTile) |
| ✅ | Card shows type · title · alias · preview · archived · incoming count |
| ✅ | tap → **`EntityJournalDialog`** (기존 Sheet) |
| ✅ | Concept / Event / Place / Org **동일 카드** |
| ✅ | Work stack **무변경** |
| ❌ | Collection storage · tags · Workbench Entity · mixed grid |

---

## 1. `EntityBrowseCard` 모델 초안

**파일 (신규):** `lib/models/entity_browse_card.dart`

기존 타입만 조합 · **저장 스키마 추가 없음**.

```dart
import '../core/archiving/entity_journal_entry.dart';
import 'user_catalog_entity.dart';

/// Gallery grid 1칸 view model — Phase 1 derived only.
class EntityBrowseCard {
  const EntityBrowseCard({
    required this.entity,
    this.journal,
    required this.isArchived,
    this.incomingRecordCount = 0,
    this.bodyPreview = '',
  });

  /// catalog SSOT — [UserCatalogEntity]
  final UserCatalogEntity entity;

  /// vault journal — [EntityJournalEntry] or null (catalog-only)
  final EntityJournalEntry? journal;

  /// derived: journal file exists ([EntityVaultLoader.findByEntityId] != null)
  final bool isArchived;

  /// derived: [RecordLinkPort.incomingRecordPaths](entity.entityId).length
  final int incomingRecordCount;

  /// derived: trim(journal.body) ≤120 chars — [EntityJournalView._preview] 동일 규칙
  final String bodyPreview;
}
```

### 1.1 필드 출처 (금지 필드 없음)

| 필드 | 소스 API / 타입 | 비고 |
|------|-----------------|------|
| `entity` | `UserCatalogPort.all` | title, aliases, anchorType, entityId, addedAt |
| `journal` | `EntityVaultLoader.loadFromVault` → map by `entityId` | `EntityJournalEntry.body`, `storagePath` |
| `isArchived` | `journal != null` | picker 「아카이브」와 동일 derived |
| `incomingRecordCount` | `linkIndex?.incomingRecordPaths(entityId)` | null linkIndex → 0 |
| `bodyPreview` | `journal.body` → preview util | empty if no journal / empty body |

**금지 (Phase 1):** tags, cover, relatedWorks, staleLabel, work badge.

### 1.2 빌드 ( `_reload` 확장 )

```dart
// catalog_entity_browse_view.dart — 설계
Future<List<EntityBrowseCard>> _buildBrowseCards(
  List<UserCatalogEntity> entities,
) async {
  final vaultPath = AkashaFileService().vaultPath;
  final journals = await const EntityVaultLoader().loadFromVault(vaultPath);
  final byId = {for (final j in journals) j.entityId: j};

  final cards = <EntityBrowseCard>[];
  for (final entity in entities) {
    final journal = byId[entity.entityId];
    var incoming = 0;
    final index = widget.linkIndex;
    if (index != null) {
      incoming = (await index.incomingRecordPaths(entity.entityId)).length;
    }
    final body = journal?.body.trim() ?? '';
    cards.add(EntityBrowseCard(
      entity: entity,
      journal: journal,
      isArchived: journal != null,
      incomingRecordCount: incoming,
      bodyPreview: body.isEmpty ? '' : EntityBodyPreview.format(body),
    ));
  }
  return cards;
}
```

**성능:** `loadFromVault` 1회 + incoming N회 — Phase 1 catalog 규모에서 허용. (N>50 시 batch cache 후속.)

---

## 2. `EntityCollectibleCard` UI 설계

**파일 (신규):** `lib/widgets/entity_collectible_card.dart`

**이름:** `EntityCollectibleCard` — 장기 Collectible 비전과 정렬. Phase 1은 Entity-only이나 **「수집·전시·감상 대상」** 프레이밍.

**PosterCard 복사 ❌** — **감상 intent만 parallel** (grid cell · hover · tap → detail). 시각 언어만 차용 (`poster_card.dart` L42–52, L98–117, L216–239).

### 2.1 Props

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

### 2.2 레이아웃 (Entity 전용)

```
MouseRegion
└─ GestureDetector(onTap)
   └─ AnimatedContainer                    // hover: translateY(-4), 200ms
      width/height: parent SizedBox (grid cell)
      decoration:
        color: #1E1E2E
        borderRadius: 10
        border: highlighted ? tealAccent 1.5 : white @ 12% (idle)
        boxShadow: depth + subtle teal glow on hover
      child: Column(stretch)
        ├─ Header (h=52)
        │   gradient: tealAccent 38% → #252536 (Entity strip과 톤 통일)
        │   Row: [Icon 28×28 from _iconFor(anchorType)]
        │         [entityTypeBadgeLabel — 11px w700]
        │         Spacer
        │         [archived badge if isArchived — PosterCard doc circle 22px]
        ├─ Body (padding 12,8) Expanded
        │   Text title — 14px w800 maxLines 2
        │   if aliases.isNotEmpty: aliases[0] — 11px grey maxLines 1
        │   SizedBox 6
        │   if bodyPreview.isNotEmpty:
        │     Text preview — 13px grey300 maxLines 3 height 1.35
        │   else:
        │     Text '(메모 없음)' — italic grey500 12px
        │   Spacer()
        └─ Footer (optional, h~18)
            if incomingRecordCount > 0:
              Text '🔗 연결 N' — 10px tealAccent  // neutral graph hint, not parent Work
```

### 2.2b 나츠키 스바루 mockup (Collectible framing)

```
┌─────────────────────────┐
│ 👤 Person          📄   │  ← kind + archived (수집됨)
│─────────────────────────│
│ 나츠키 스바루            │  ← HERO: collectible name
│ ナツキ・スバル           │  ← alias (부제)
│                         │
│ Re:Zero 1기 시청 후      │  ← user's journal voice (not 「Re:Zero 소속」label)
│ 주인공으로 기록…         │
│                         │
│ 🔗 연결 3               │  ← graph richness (Phase 2에서 Work명 resolve 가능)
└─────────────────────────┘
       tap → Entity Sheet (감상·편집)
```

### 2.3 표시 규칙

| 요소 | 조건 | 소스 |
|------|------|------|
| type badge + icon | always | `entity.anchorType` · `entityTypeBadgeLabel` · `_iconFor` (browse view와 동일 switch) |
| title | always | `entity.title` |
| alias | `entity.aliases.isNotEmpty` | `entity.aliases.first` |
| body preview | `bodyPreview.isNotEmpty` | derived |
| archived | `isArchived` | journal exists |
| incoming | `incomingRecordCount > 0` | link index · label **「연결 N」** |
| entityId subtitle | **표시 안 함** | ListTile era · metadata list UX 제거 |
| related Work title | **Phase 1 ❌** | Work metadata framing 방지 |

### 2.3b UX anti-patterns (Phase 1 금지)

| 금지 | 이유 |
|------|------|
| 카드 primary에 Work title | Person = Work metadata 프레이밍 |
| 「등장인물 / 소속 / IP」 copy | 종속 관계 강조 |
| preview wiki → resolved work label | Phase 2 · 카드에서 Work promote |
| Workbench on card tap | Entity 감상 surface = Sheet |
| PosterCard subclass / AkashaItem adapter | Work stack 침범 |

### 2.4 PosterCard에서 가져오지 않는 것

rating · status border · PosterImage · FormatChipRow · library menu · WorkDraggableCard · category gradient per MediaCategory

### 2.5 Preview util (신규, 선택)

**파일:** `lib/utils/entity_body_preview.dart`

```dart
abstract final class EntityBodyPreview {
  static String format(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}…';
  }
}
```

`EntityJournalView._preview` → delegate (동작 동일, DRY).

---

## 3. `CatalogEntityBrowseView` 변경 범위

### 3.1 ✅ full mode만 Grid 전환 가능

| 구간 | 변경 |
|------|------|
| L123–158 `compact` | **유지** — `_CompactEntityCard` + horizontal ListView |
| L161–202 full | **교체** — ListView.separated → Scrollbar + SingleChildScrollView + Wrap |
| L61–77 `_reload` | **확장** — `List<UserCatalogEntity>` → `List<EntityBrowseCard>` |
| L80–96 `_openEntity` | **유지** — `onTap: () => _openEntity(card.entity)` |
| empty / loading | **유지** |

### 3.2 Grid 구현 (Entity stack 내부)

`BrowsePosterGrid`는 `BrowseCard` 전용 — **import하지 않음**.  
동일 Wrap 수식을 full branch **인라인** 또는 **`EntityCollectibleGrid`** (신규, `List<EntityBrowseCard>`).

```dart
// 상수 — poster 0.48보다 낮음 (이미지 없음)
const _cardMinWidth = 170.0;
const _childAspectRatio = 0.68;

Expanded(
  child: Scrollbar(
    child: SingleChildScrollView(
      padding: …,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // BrowsePosterGrid L32-37 동형
          return Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              for (final card in _cards)
                SizedBox(
                  width: cellWidth,
                  height: cellHeight,
                  child: EntityCollectibleCard(
                    card: card,
                    highlighted: card.entity.entityId == widget.highlightEntityId,
                    onTap: () => _openEntity(card.entity),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  ),
)
```

### 3.3 건드리지 않는 파일

`home_shell_body.dart` (routing 이미 full → CatalogEntityBrowseView), `BrowsePosterGrid`, `PosterCard`, pipelines, Workbench.

---

## 4. Entity 타입 — 단일 카드 가능 여부

### 4.1 ✅ 단일 `EntityCollectibleCard`로 처리

`CatalogEntityBrowseView._iconFor` / `entityTypeBadgeLabel` 이미 5+2 타입 지원:

| Scope / Type | Badge | Icon | 동일 카드 |
|--------------|-------|------|:---------:|
| Person | Person | person_outline | ✅ |
| Concept | Concept | lightbulb_outline | ✅ |
| Event | Event | event_outlined | ✅ |
| Place | Place | place_outlined | ✅ |
| Organization | Org | groups_outlined | ✅ |
| Custom | Custom | category_outlined | ✅ |
| Phenomenon | Legacy | category_outlined | ✅ |
| `BrowseEntityScope.all` | per entity | per entity | ✅ |

**타입별 분기 widget 불필요** — header icon + label만 switch.

### 4.2 필터

기존 `BrowseEntityScope` + `FilterSection` chip — **변경 없음**.  
Person gallery = user selects **Person** chip → `showsWorkGrid == false` → full grid.

---

## 5. Entity Sheet routing

### 5.1 ✅ 기존 흐름 100% 유지

```dart
// 변경 없음 — L80-96
Future<void> _openEntity(UserCatalogEntity entity) async {
  final entry = await EntityVaultLoader().findByEntityId(...);
  await showEntityJournalDialog(
    context,
    entity: entity,
    entry: entry,
    linkIndex: widget.linkIndex,
    userCatalog: widget.userCatalog,
    vaultItems: widget.vaultItems,
    onOpenWork: widget.onOpenWork,  // Sheet incoming → Work only, not card tap
  );
}
```

| | |
|--|--|
| Card tap | `_openEntity` → **Dialog** |
| Workbench | **card에서 호출 ❌** |
| `onOpenWork` | Sheet 내부 incoming link 전용 — prop 유지 |

---

## 6. 예상 수정 파일

### 6.1 신규 (5–6)

| 파일 | 역할 |
|------|------|
| `lib/models/entity_browse_card.dart` | view model |
| `lib/widgets/entity_collectible_card.dart` | card UI |
| `lib/utils/entity_body_preview.dart` | 120자 preview (DRY) |
| `lib/widgets/entity_collectible_grid.dart` | *(optional)* Wrap layout — inline 대체 가능 |
| `test/entity_body_preview_test.dart` | preview unit |
| `test/entity_collectible_card_test.dart` | widget smoke |

### 6.2 수정 (1–2)

| 파일 | 변경 |
|------|------|
| `lib/screens/home/views/catalog_entity_browse_view.dart` | `_reload` → cards · full grid · `_iconFor` → card로 이동 or shared |
| `lib/screens/home/views/entity_journal_view.dart` | *(optional)* `_preview` → `EntityBodyPreview.format` |

### 6.3 테스트 (2–3)

| 파일 | 내용 |
|------|------|
| `test/entity_body_preview_test.dart` | 120자 · empty · exact 120 |
| `test/entity_collectible_card_test.dart` | title · alias · preview · archived · incoming · tap callback |
| `test/catalog_entity_browse_grid_test.dart` | *(optional)* pump CatalogEntityBrowseView full — fake catalog |

### 6.4 명시적 비범위 (0 files)

BrowsePipeline · PosterCard · PersonalLibrary · Workbench · Collection · tags schema · `home_shell_body` · `BrowsePosterGrid`

### 6.5 요약

| | 개수 |
|--|-----:|
| **신규** | **7–8** (+ sort model/util/dropdown/test) |
| **수정** | **2–3** (+ `home_section_preferences.dart`) |
| **테스트** | **3–4** |
| **총 touch** | **~10–12** |
| **난이도** | **S (낮음)** |
| **회귀 위험** | **낮음** (Entity path isolated) |

**Sort:** [entity-gallery-sort-audit.md](r2e-phase1-entity-gallery-sort-audit.md) — Phase 1에 **3 criteria + dropdown 권장**.

---

## 7. 구현 순서 (권장)

1. `EntityBodyPreview` + unit test  
2. `EntityBrowseCard` model  
3. `EntityGallerySortCriteria` + `sortEntityBrowseCards` + unit test  
4. `EntityCollectibleCard` + widget test  
5. `CatalogEntityBrowseView._buildBrowseCards` + sort + header dropdown  
6. full branch Wrap grid wiring  
6. manual: Filter Person → grid → tap Sheet → incoming → Work (기존 graph)  
7. `flutter test` full suite

---

## 8. 수동 테스트 체크리스트

- [ ] Filter **Person** → grid (not ListTile)  
- [ ] sort dropdown: 이름순 / 최근 추가 / 아카이브 우선  
- [ ] Person with journal → preview + archived badge  
- [ ] catalog-only Person → 「(메모 없음)」, no archived badge  
- [ ] incoming > 0 → footer 「연결 N」(Work名 없음)  
- [ ] 카드 주 정보 = title/alias/preview (Re:Zero badge 없음)  
- [ ] alias 표시 / 없으면 생략  
- [ ] Concept / Event scope → 동일 card  
- [ ] compact strip (Work+All) → **unchanged**  
- [ ] tap → EntityJournalDialog, **not** Workbench  
- [ ] Work browse / PosterCard / personal library → no regression

---

## 9. 관련 조사 문서

- [r2e-step3-entity-collection-surface-audit.md](r2e-step3-entity-collection-surface-audit.md)  
- [r2e-architecture-alignment-check.md](r2e-architecture-alignment-check.md)  
- [r2e-collection-architecture-audit.md](r2e-collection-architecture-audit.md) — Phase 2+ out of scope
