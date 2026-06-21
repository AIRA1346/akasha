# R2-E Step 1 — Entity Collectible Information Audit

> **상태:** 조사 완료 (구현 없음)  
> **날짜:** 2026-06-19  
> **상위:** [Step 0.5 Collectible Architecture](r2e-step0.5-collectible-architecture-audit.md)

---

## Executive Summary

Entity는 **catalog(JSON) + journal(`.md` frontmatter + body)** 이원 구조다.  
카드 Phase 1에 **즉시 사용 가능:** `title`, `entityType`, `aliases`, `archived`(derived), **`body` 120자 preview**(기존 패턴).  
**없음:** `tags`, `cover/poster`, explicit `relatedWorkIds`.  
Work 관계는 **wiki link + link index**로만 표현 가능 — 카드에 「Re:Zero」 표시는 **outgoing link parse 또는 index** 필요(Phase 2).

---

## 1. Entity 필드 전수 조사

### 1.1 `UserCatalogEntity`

**저장:** `{vault}/catalog/user_entities.json`  
**소스:** `lib/models/user_catalog_entity.dart` · `lib/services/user_catalog_store.dart`

| 필드 | 저장 위치 | UI 사용 | 사용처 |
|------|----------|:-------:|--------|
| `entityId` | catalog JSON | ✅ | Sheet subtitle, browse subtitle, picker subtitle |
| `entityType` | catalog JSON | ✅ | badge, icon, filter (`anchorType`) |
| `subtype` (`MediaCategory`) | catalog JSON | ❌ | Work entity용; non-work 기본 `manga` |
| `title` | catalog JSON | ✅ | browse, sheet, picker, fusion |
| `titles` (`WorkTitles`) | catalog JSON | ❌ | `toRegistryWork().searchTokens` only |
| `creator` | catalog JSON | ❌* | `matchesQuery`; picker 검색 · **카드 미표시** |
| `releaseYear` | catalog JSON | ❌ | Work-centric |
| `domain` | catalog JSON | ❌ | catalog JSON only |
| `aliases` | catalog JSON | ✅ | Sheet, picker trailing; browse **미표시** |
| `addedAt` | catalog JSON | ✅ | browse sort; journal view date |
| `source` (`"user"`) | catalog JSON (toJson) | ❌ | export only |
| `isWorkEntity` | getter | — | filter non-work browse |
| `anchorType` | getter | ✅ | icon/badge 전역 |

\* Person Add dialog에서 입력 UI 없음 — Work catalog mirror 시에만 채워질 수 있음.

**정책 금지 (Tier 1.5):** `posterPath`, `description` — [user-local-catalog-policy.md §4.1](../policy/user-local-catalog-policy.md)

---

### 1.2 `EntityJournalEntry`

**저장:** in-memory model ← vault parse  
**소스:** `lib/core/archiving/entity_journal_entry.dart`

| 필드 | 저장 위치 | UI 사용 | 사용처 |
|------|----------|:-------:|--------|
| `entityType` | frontmatter `entity_type` | ✅ | journal list badge, fusion entity tile |
| `entityId` | frontmatter `entity_id` | △ | Sheet 간접; journal list **미표시** |
| `title` | frontmatter `title` | ✅ | journal list, sheet (mirror) |
| `body` | `.md` 본문 | ✅ | sheet editor; **journal list preview** |
| `addedAt` | frontmatter `added_at` | ✅ | journal list, sheet |
| `storagePath` | filesystem path | ❌ | loader/store; incoming link open |

---

### 1.3 Entity frontmatter (parser SSOT)

**소스:** `lib/services/entity_journal_parser.dart` — `serialize` / `parse`

| YAML 키 | EntityJournalEntry | catalog mirror | UI |
|---------|-------------------|----------------|:----:|
| `entity_type` | ✅ | → `entityType` | badge |
| `entity_id` | ✅ | → `entityId` | subtitle |
| `record_kind` | parse gate | — | — |
| `title` | ✅ | sync on save | title |
| `added_at` | ✅ | sync on save | date |
| `tags` | ❌ | ❌ | — |
| `poster_path` / `cover` | ❌ | ❌ | — |
| `aliases` | ❌ | catalog only | — |
| `creator` | ❌ | catalog only | — |
| `related_work_ids` | ❌ | ❌ | — |

**Body (frontmatter 외):** freeform markdown + `[[wiki links]]` — Record SSOT ([entity-record-storage-masterplan.md §2](entity-record-storage-masterplan.md))

---

### 1.4 Derived (코드 계산, 저장 없음)

| 값 | 계산 | UI |
|----|------|:----:|
| `isArchived` | `EntityVaultLoader.findByEntityId` != null | picker subtitle 「아카이브」 |
| `catalogOnly` | catalog 있음 · journal 없음 | fusion 「아카이브되지 않음」 |
| `incomingRecordCount` | `linkIndex.incomingRecordPaths` | Sheet incoming (R2-D) |
| `staleLabelRecordCount` | `RecordLinkStaleLabel` | Sheet (R2-D) |

---

## 2. Body → 카드 summary (preview) 조사

### 2.1 기존 코드 패턴

**유일한 Entity body preview:** `EntityJournalView._preview`

```117:120:lib/screens/home/views/entity_journal_view.dart
  static String _preview(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}…';
  }
```

**사용:** journal list tile — type badge + date + title + preview (L197-228)

| 전략 | 구현 여부 |
|------|:--------:|
| 첫 120자 + `…` | ✅ **유일 패턴** |
| 첫 문단 | ❌ |
| 첫 heading 이전 | ❌ |
| markdown strip | ❌ |
| wiki `[[…]]` → label 치환 | ❌ |
| fenced code 제외 | ❌ (RecordLinkParser는 link용만) |

### 2.2 카드 preview 생성 가능성

| 조건 | Phase 1 |
|------|:-------:|
| archived + journal `body` non-empty | ✅ `_preview(body)` 재사용 가능 |
| catalog-only (journal 없음) | ❌ summary 없음 — 빈 또는 placeholder |
| body가 wiki link만 | △ raw `[[wk_u_…\|Re:Zero]]` 노출 |

**결론:** **journal body + 120자 trim**으로 Phase 1 summary **가능**. 품질 개선(문단/markdown strip)은 Phase 2.

---

## 3. Entity image (cover/poster) 조사

### 3.1 현재 구조

| 계층 | image 필드 |
|------|-----------|
| `UserCatalogEntity` | **없음** (policy **금지**) |
| Entity frontmatter | **없음** (`EntityJournalParser` 5키 only) |
| Entity body | 사용자가 markdown image 넣을 수 있으나 **parser/UI 미지원** |
| `vault/posters/` | Work `AkashaItem.posterPath` 전용 |

### 3.2 추가 시 영향 범위 (설계)

| 영역 | 파일 / 범위 |
|------|------------|
| **정책** | `user-local-catalog-policy.md`, `entity-record-storage-masterplan.md` |
| **Catalog** | `user_catalog_entity.dart`, `user_catalog_store.dart`, JSON schema v2 |
| **Journal** | `entity_journal_parser.dart` serialize/parse (`cover_uri`?) |
| **Store** | `entity_vault_store.dart`, `entity_catalog_sync.dart` |
| **UI** | 신규 card widget, optional `entity_journal_dialog` header |
| **Reuse** | `PosterImage` / `CategoryPosterPlaceholder` — **`MediaCategory` 대신 `EntityAnchorType` gradient** adapter 필요 |
| **Work 경로** | **영향 없음** (Entity parallel) |

**난이도:** 중 — policy unlock + parser + catalog migration + card UI.

---

## 4. Entity tags 조사

| 저장소 | tags | 근거 |
|--------|:----:|------|
| `user_entities.json` | ❌ | `toJson`/`fromJson` 필드 없음 |
| journal frontmatter | ❌ | parser 5키 only |
| journal body | △ | `#tag` 또는 plain text 가능하나 **parse/索引 없음** |
| `UserCatalogEntity.matchesQuery` | — | title, creator, aliases, searchTokens only |

**Add Entity dialog:** aliases 입력 ✅ · tags 입력 ❌ (`add_catalog_entity_dialog.dart`)

**결론:** tags **어디에도 구조화되어 있지 않음**. Phase 2는 **catalog `tags: []` + frontmatter mirror** 권장.

---

## 5. Entity ↔ Work 관계 데이터

### 5.1 저장 형태

| 방식 | 존재 | 예 (스바루 → Re:Zero) |
|------|:----:|----------------------|
| **Explicit field** | ❌ | `relatedWorkIds` / `franchiseId` on Entity **없음** |
| **Wiki link (body)** | ✅ | Person `.md`: `[[wk_u_rezero01\|Re:Zero]]` |
| **Link index** | ✅ | `outgoing[person.md path]` → `RecordLink(targetEntityId=wk_u_…)` |
| | ✅ | `incoming[pe_u_subaru]` ← Work `.md`가 person link |

### 5.2 카드에서 「Re:Zero」 표시 — 현재 코드만으로

| 방법 | 가능 | 비고 |
|------|:----:|------|
| catalog field | ❌ | |
| body raw substring | △ | `[[wk_u_…\|Re:Zero]]` 그대로 보일 수 있음 |
| `RecordLinkParser.parseFromRecordContent(body)` | ✅ | runtime parse · work id filter |
| `linkIndex.outgoingLinks(journal.storagePath)` | ✅ | index loaded 시 · **displayLabel** 보유 |
| `WorksRegistry.getWorkById` | ✅ | id → title for subtitle |
| FranchiseRegistry | △ | Person entityId와 **직접 연결 없음** — Work franchise only |

**Phase 1 카드:** Work 관계 **표시 불가**( 또는 raw wiki 노출).  
**Phase 2:** `outgoingLinks` + work id filter → subtitle 「Re:Zero」**가능**.

---

## 6. Phase 1 vs Phase 2 정보 구분

### Phase 1 — 오늘 코드로 카드 가능 (최소)

| 정보 | 소스 | 기존 UI 선례 |
|------|------|-------------|
| `title` | catalog / journal | `_CompactEntityCard`, journal list |
| `type` (`EntityAnchorType`) | catalog | badge + `_iconFor` |
| `aliases` | catalog | sheet; card subtitle **신규** |
| `archived` | vault loader | picker 「아카이브」 |
| `body preview` | journal body | `EntityJournalView._preview` |
| `entityId` | catalog | optional footer (browse subtitle) |
| `addedAt` | catalog/journal | optional meta |

### Phase 2 — 스키마/인프라 추가

| 정보 | 필요 작업 |
|------|----------|
| `tags` | catalog + frontmatter + filter UI |
| `coverImage` | policy + parser + card visual |
| `linked works` (outgoing) | link index + work title resolve |
| `linked entity count` / incoming | `incomingRecordPaths.length` (R2-D已有) |
| `creator` / `domain` | catalog已有 · card 선택 표시 |
| markdown-aware summary | new preview util |
| `catalogOnly` badge | fusion hint 재사용 |

### Phase 3+ (장기)

- franchise / IP scoped collection  
- hero tag filter  
- mixed Work+Entity grid (`CollectibleItem`)

---

## 7. 「나츠키 스바루」카드 — 오늘 코드 mockup

**가정 데이터 (Archive-First R1 정상 flow):**

```
catalog (user_entities.json):
  entityId: pe_u_natsuki1
  entityType: person
  title: 나츠키 스바루
  aliases: [ナツキ・スバル, Subaru]

vault (entities/person/나츠키 스바루.md):
  body: |
    Re:Zero 1기 시청 후 등장인물로 기록.
    [[wk_u_rezero01|Re:Zero]]
    성격: … (이하 생략)
```

### 7.1 A — `_CompactEntityCard` (이미 구현, Discovery strip)

```
┌──────────────────────┐
│ Person               │  ← entityTypeBadgeLabel
│                      │
│ 나츠키 스바루         │  ← title (max 2 lines)
└──────────────────────┘
   140px wide · no archived · no preview · no aliases
```

### 7.2 B — `EntityJournalView` list row (archived, preview O)

```
┌─────────────────────────────────────────────┐
│ Person                    2026-06-19 14:30 │
│ 나츠키 스바루                                │
│ Re:Zero 1기 시청 후 등장인물로 기록.         │
│ [[wk_u_rezero01|Re:Zero]]                    │  ← raw wiki in preview
│ 성격: …                                      │
└─────────────────────────────────────────────┘
```

### 7.3 C — Phase 1 **Entity Collectible Card** (설계 mockup · 미구현)

오늘 **가능한** 최대 UI (기존 필드 + `_preview` + `isArchived`):

```
┌─────────────────────────┐
│ 👤 Person        📄     │  ← icon + archived badge (vault exists)
│─────────────────────────│
│ 나츠키 스바루            │  ← title
│ ナツキ・スバル           │  ← aliases[0] or join (catalog)
│                         │
│ Re:Zero 1기 시청 후      │  ← _preview(body) 120자
│ 등장인물으로 기록. [[wk…│
│                         │
│ pe_u_natsuki1           │  ← optional id (browse style)
└─────────────────────────┘
```

**오늘 불가 (Phase 2 mockup ghost):**

```
│ 🖼 [cover]              │  ← poster — 없음
│ #영웅 #ReZero           │  ← tags — 없음
│ → Re:Zero               │  ← linked work resolved title — index parse 필요
│ 🔗 연결 3               │  ← incoming count — API 있음, card wiring 없음
```

### 7.4 D — catalog-only (journal 없음)

```
┌─────────────────────────┐
│ 👤 Person               │  ← no archived badge
│ 나츠키 스바루            │
│ (메모 없음)              │  ← preview placeholder
│ ⏳ 아카이브되지 않음      │  ← fusion catalogEntityOnly 힌트 재사용 가능
└─────────────────────────┘
```

---

## 8. Phase 1 구현 입력 (Step 2용, 조사만)

| 입력 | API / 패턴 |
|------|-----------|
| Card model | `UserCatalogEntity` + `EntityJournalEntry?` + `bool isArchived` |
| Loader | `EntityVaultLoader.findByEntityId` + `userCatalog.all` |
| Preview | `EntityJournalView._preview` extract or share util |
| Archived | `archivedEntityIds` pattern from `EntityLinkPickerCandidates` |
| Tap | `showEntityJournalDialog` (catalog_entity_browse_view L80-95) |
| Incoming badge (optional) | `linkIndex.incomingRecordPaths(entityId).length` |

---

## 9. 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/models/user_catalog_entity.dart` | catalog fields |
| `lib/core/archiving/entity_journal_entry.dart` | journal model |
| `lib/services/entity_journal_parser.dart` | frontmatter SSOT |
| `lib/services/entity_vault_loader.dart` | archived lookup |
| `lib/screens/home/views/entity_journal_view.dart` | **body preview pattern** |
| `lib/screens/home/views/catalog_entity_browse_view.dart` | compact card |
| `lib/screens/home/dialogs/entity_link_picker_dialog.dart` | archived + aliases UI |
| `lib/services/record_link_index_service.dart` | Entity↔Work links |
| `docs/policy/user-local-catalog-policy.md` | poster/tags policy |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Step 1 Entity Collectible Information Audit |
