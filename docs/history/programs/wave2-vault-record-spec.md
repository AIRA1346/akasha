# Wave 2 — Vault & Record Schema v2 구현 스펙

> **상태:** 설계 v1 · 코드 착수 **대기** (Gate: wave1-exit-review + 본 spec 검토)  
> **갱신:** 2026-06-19  
> **상위:** [vault-layout-v2.md](../product/vault-layout-v2.md) · [entity-record-storage-masterplan.md](entity-record-storage-masterplan.md)  
> **선행:** Wave 1 ✅ (`d4f8503`)

---

## 1. 목표

모든 Work Record가 **`ArchiveRecord` + Entity frontmatter**로 표현 가능하게 하되, **기존 `.md` 100% 호환** (lazy upgrade, breaking migration 없음).

| 하지 않음 (Wave 2) | 이유 |
|--------------------|------|
| Person/Event catalog | Wave 4 |
| `MediaCategory` UI rename | Phase 0 UI 유지 |
| 볼트 일괄 이동 | lazy only |
| Note → Entity 승격 | ADR-011 금지 |

---

## 2. 아키텍처

```
Presentation     Workbench · saveItem 경로
       ↓
Application      MarkdownParser v2 · ArchiveRecordMapper (round-trip)
       ↓
Domain           EntityAnchor · RecordKind · ArchiveRecord
       ↓
Data             AkashaFileService (works/ path) · MarkdownVaultAdapter
```

**AkashaItem** — Phase 0 DTO **유지**. Wave 2는 parser/mapper가 v2 필드를 **투명하게** infer/add.

---

## 3. Frontmatter v2 — Read/Write SSOT

### 3.1 필드

| 필드 | Write | Read | 비고 |
|------|:-----:|:----:|------|
| `entity_type` | lazy add | ✅ | default infer `work` |
| `entity_id` | lazy add | ✅ | = `work_id` for work |
| `subtype` | lazy add | ✅ | = `category.name` |
| `record_kind` | optional | ✅ | default `workJournal` |
| `work_id` | **항상** | ✅ | legacy alias |
| `category` | **항상** | ✅ | legacy |
| `added_at` | **항상** | ✅ | |

### 3.2 Infer 규칙 (Read)

| 입력 | entity_type | entity_id | subtype | record_kind |
|------|-------------|-------------|---------|-------------|
| v2 full | 그대로 | 그대로 | subtype ∨ category | explicit ∨ infer |
| `work_id` only | `work` | work_id | category | `workJournal` |
| `entity_id` only | entity_type ∨ `work` | entity_id | category | infer |
| 둘 다 없음 | `work` | ensureWorkId() | category | `workJournal` |
| `wk_u_*` | `work` | id | category | `workJournal` |
| `sub_*_custom_*` | `work` | legacy | category | `workJournal` |

**구현:** `EntityFrontmatter.parse(yamlMap)` 신규 (또는 `MarkdownParser` private helper).

### 3.3 Serialize 규칙 (Write — lazy)

| 조건 | 동작 |
|------|------|
| legacy path (`{vault}/{category}/`) | `work_id`+`category` **유지** + `entity_*` **추가** |
| new path (`{vault}/works/{subtype}/`) | `entity_type`+`entity_id`+`subtype` **권장** + `work_id` mirror |
| user local `wk_u_*` | `entity_id` = catalog `entityId` **필수 동기화** |

**Poster/rating/body** — 기존 [sanctum-md-customization.md](../product/sanctum-md-customization.md) 불변.

---

## 4. Vault 경로 (W2-3)

### 4.1 신규 저장 경로 결정

```dart
String resolveWorkJournalPath(AkashaItem item, String vaultRoot) {
  if (item.filePath != null && item.filePath!.isNotEmpty) {
    return item.filePath!;  // 기존 파일 — 이동 금지
  }
  final subtype = item.category.name;
  final safeTitle = makeSafeFilename(item.title);
  // Wave 2 feature flag or prefs: useWorksLayout default false → opt-in true
  if (useWorksLayout) {
    return join(vaultRoot, 'works', subtype, '$safeTitle.md');
  }
  return join(vaultRoot, subtype, '$safeTitle.md');
}
```

| 정책 | 내용 |
|------|------|
| **Default** | Wave 2 초기 — **legacy path 유지** (리스크 최소) |
| **Opt-in** | Vault 설정 「신규 작품 works/ 경로」 토글 (dogfood 후 default 전환 검토) |
| **Scan** | `works/` **포함** · `catalog/` **제외** (Wave 1 ✅) |

### 4.2 `_ensureFolderStructure`

```
works/{each MediaCategory}/
entities/   (empty stub — Wave 4 forward-compat)
journal/    (empty stub — Wave 3)
```

---

## 5. ArchiveRecord round-trip (W2-2 · W2-4)

### 5.1 AkashaItem → ArchiveRecord

`ArchiveRecordMapper.fromAkashaItem` — 현재 work-only `_entityFor`:

```dart
// 목표
EntityAnchor(
  entityId: entityIdFromItem(item),
  type: EntityAnchor.typeForEntityId(entityId),
);
RecordKind: infer from path or default workJournal
```

### 5.2 `.md` → ArchiveRecord (Work journal)

신규: `ArchiveRecordMapper.fromWorkMarkdown(String content, String path)`  
또는 `MarkdownParser`가 `ParsedWorkDocument { item, entity, kind }` 반환.

### 5.3 Gap (현재 코드)

| 파일 | Gap |
|------|-----|
| `markdown_parser.dart` | `entity_type`/`entity_id` **미파싱** · serialize **미기록** |
| `archive_record_mapper.dart` | `fromAkashaItem` only · markdown round-trip **없음** |
| `file_service.dart` | `works/` path resolver **없음** |
| Home/Browse | `AkashaItem` 직접 — ArchiveRecord Port **1곳 미연결** (W2-4) |

**W2-4 후보:** Timeline quick capture **이미** `ArchiveRecord` — Work save 1곳을 동일 패턴으로.

---

## 6. User catalog ↔ `.md` 조인 (Wave 1 연속)

| 상태 | catalog | `.md` |
|------|---------|-------|
| catalog-only | `wk_u_*` | 없음 |
| archived | `wk_u_*` | `entity_id: wk_u_*` |

**Wave 2 lazy write:** `saveItem` 시 `entity_id` = `item.workId` mirror.

**R1 (Wave 1):** upsert before saveItem — Wave 2에서 **saveItem 성공 후 upsert** 권고.

---

## 7. UI / UX (Wave 2 — 최소)

| 표면 | 변경 |
|------|------|
| Browse 그리드 | **없음** |
| Fusion Search | **없음** (Wave 1 ✅) |
| Workbench | frontmatter v2 **투명** |
| Vault settings | (optional) works/ layout toggle |
| External editor | `work_id` still works — 호환 |

---

## 8. 테스트 (W2-5)

| ID | 케이스 |
|----|--------|
| T1 | Legacy `.md` (work_id only) deserialize → infer entity_type=work |
| T2 | v2 `.md` round-trip entity_id/subtype preserved |
| T3 | `wk_u_*` legacy file — entity_id mirror on lazy save |
| T4 | Existing filePath — save does **not** move to works/ |
| T5 | New item + useWorksLayout → `works/manga/foo.md` |
| T6 | `ArchiveRecordMapper.fromWorkMarkdown` ↔ serialize |
| T7 | All Wave 1 tests **unchanged pass** |
| T8 | Timeline entry frontmatter **unchanged** |

Fixtures: `test/fixtures/vault_v1_legacy.md`, `vault_v2_work.md` ✅

**Pre-implementation review:** [wave2-pre-implementation-review.md](wave2-pre-implementation-review.md)  
**EntityFrontmatter API:** wave2 review §4

---

## 9. P0 — Wave 2 착수 전 검토

| ID | 이슈 | 권고 |
|----|------|------|
| P0-W2-1 | `deserialize`가 `entity_id` 무시 | W2-1 필수 |
| P0-W2-2 | `WorksRegistry.getWorkById(wk_u_*)` null — UI fusion OK | user catalog join path 문서화 |
| P0-W2-3 | works/ default on/off | **default off** Wave 2.0 |
| P0-W2-4 | `EntityAnchor.typeForEntityId` — `pe_u_*` → custom today | Wave 4 전 `typeForEntityId` 확장 **하지 않음** (work only) |
| P0-W2-5 | AkashaItem에 entity_type 필드 추가? | **❌** — infer from workId only Phase 0~2 |

---

## 10. Wave 2 Exit

- [x] Parser read v2 + legacy infer
- [x] Serializer lazy v2 on save
- [x] works/ path opt-in
- [x] ArchiveRecord round-trip 1 Work path
- [x] Wave 1 + legacy fixtures green
- [x] vault-layout-v2 §4 frontmatter ([wave2-exit-review.md](wave2-exit-review.md))

**코드 Exit:** 357 tests @ 2026-06-19 · 상세 [wave2-exit-review.md](wave2-exit-review.md)

---

## 11. 구현 순서 (코드 Gate 후)

```
W2-0  EntityFrontmatter parse/infer helper + tests
W2-1  MarkdownParser deserialize v2
W2-2  MarkdownParser serialize lazy v2
W2-3  file_service path resolver + works/ folders
W2-4  ArchiveRecordMapper markdown round-trip
W2-5  saveItem upsert-after-save (R1 fix)
W2-6  regression + dogfood
```

---

## 12. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 2 spec · P0 · test plan · W2-0~6 순서 |
