# R2-E Step 2 — Entity Relation Discovery Audit

> **상태:** 조사 완료 (구현 없음)  
> **날짜:** 2026-06-19  
> **상위:** [Step 1.5 Vision](r2e-step1.5-entity-collection-vision-audit.md) · [Step 1 Information](r2e-step1-entity-collectible-information-audit.md)

---

## Executive Summary

Entity 카드에 「Re:Zero」 Work 배지 표시는 **추가 저장 없이 런타임 계산 가능** — 단, **전용 API·카드 wiring 없음**.  
R2-B canonical authoring은 **Work 본문 → Person** (`[[pe_u_…|…]]`)이므로 카드 Work 발견에는 **incoming + vault resolve**가 주 경로.  
Entity body의 `[[wk_u_…|Re:Zero]]`는 **outgoing( entity journal path )** 또는 **body 직접 parse**로 보조 가능.  
**「대표 Work」 선택 알고리즘은 코드에 없음** — 첫 링크 등 정책을 새로 정의해야 함.

---

## 1. Entity body `[[wk_u_xxx|Re:Zero]]` → 대표 Work 계산

### 1.1 파싱 가능 여부 — ✅

| 단계 | API | 결과 |
|------|-----|------|
| body 추출 | `RecordLinkParser.parseFromMarkdown(body)` | entity frontmatter 제외 본문만 (journal `body` 필드 직접 사용 시 동일) |
| id 인식 | `_looksLikeEntityId` → `WorkIdCodec.isUserLocalWorkId` / `isGlobalWorkId` / `isLegacyMasterId` | `wk_u_*`, `wk_000…`, legacy master → **explicitId** |
| Work 타입 | `EntityIdCodec.typeFromId('wk_u_…')` | `EntityAnchorType.work` |
| 표시명 | `ParsedRecordLink.displayLabel` | pipe label `Re:Zero` (canonical `[[wk_u_xxx\|Re:Zero]]`) |

**테스트 근거:** `record_link_index_test.dart` — entity journal body `[[wk_u_demo0001]]`가 index outgoing에 포함됨.

### 1.2 「대표 Work」 — ❌ 기존 로직 없음

코드베이스에 `representativeWork` / `primaryWork` / `linkedWorks` **서비스·필드 없음**.

| 가능한 **신규** 휴리스틱 (설계, 미구현) | 전제 |
|----------------------------------------|------|
| body 내 **첫 `wk_*` explicitId** (`startOffset` 순) | Person journal에 Work 링크를 사용자가 직접 작성한 경우 |
| `displayLabel` → 배지 텍스트 | pipe label 있을 때 |
| label 없는 `[[wk_u_xxx]]` | `vaultItems` / catalog에서 title lookup 필요 |

### 1.3 body만으로의 한계 (코드 기준)

| 케이스 | body parse | 비고 |
|--------|:----------:|------|
| `[[wk_u_rezero01\|Re:Zero]]` in Person journal | ✅ | R2-B canonical — **authoring에서 Person→Work도 허용** |
| Work Sanctum `[[pe_u_natsuki1\|나츠키 스바루]]` only | ❌ body에 Work 링크 없음 | **R2-B E2E 주류 패턴** (`r2b_entity_link_pipeline_test.dart`) |
| `[[Re:Zero]]` titleOnly in Person body | △ | `resolveTitleToEntityId` → vault work title match 시 `wk_*` (best effort) |
| catalog-only (journal 없음) | ❌ body 없음 | incoming 경로만 가능 (§2) |

**결론:** body parse만으로는 **주류 데이터(Work가 Person을 링크)** 를 놓친다. 대표 Work는 **body + index 병합**이 필요.

---

## 2. Link index만으로 Entity → linked Work 목록

### 2.1 Port surface (현재)

```dart
// lib/core/ports/record_link_port.dart
Future<List<RecordLink>> outgoingLinks(String sourcePath);
Future<List<String>> incomingRecordPaths(String entityId);
```

**`linkedWorksForEntity` API 없음** — 조합 필요.

### 2.2 경로 A — **incoming** (Entity ← Record)

```
incomingRecordPaths(pe_u_natsuki1)
  → [ "…/works/…/Re_Zero.md", … ]
  → RecordLinkNavigator.findVaultItemForRecordPath(path, vaultItems)
  → AkashaItem { workId, title }
```

| 항목 | 코드 |
|------|------|
| index build | Work 본문 `[[pe_u_…\|…]]` or `[[나츠키 스바루]]` → incoming[pe_id] |
| Work title | `AkashaItem.title` or md frontmatter `work_id` + vaultItems |
| 검증 | `record_link_index_test.dart` L83-139, `r2b_entity_link_pipeline_test.dart` L109-128 |

**장점:** R2-B canonical **Work→Person** 링크를 그대로 역추적.  
**한계:** incoming path가 `works/` 외 (`timeline/`, `journal/`)이면 Work가 아님 — **Work 필터 필요**.

### 2.3 경로 B — **outgoing** (Entity journal path → Work)

```
EntityVaultLoader.findByEntityId → entry.storagePath
  → outgoingLinks(storagePath)
  → filter link.targetEntityId where EntityIdCodec.typeFromId == work
  → displayLabel or catalog/vault title
```

| 항목 | 코드 |
|------|------|
| index build | entity `entities/person/*.md` body `[[wk_u_…]]` scanned (`wave5-connection-spec` §4.1) |
| 검증 | `record_link_index_test.dart` L47-55 entity journal `[[wk_u_demo0001]]` |

**장점:** explicit `[[wk_u_xxx\|Re:Zero]]` → **pipe label 즉시 사용**.  
**한계:** journal 없으면 storagePath 없음 → outgoing 불가.

### 2.4 경로 C — body 직접 parse (index 우회)

`RecordLinkParser.parseFromMarkdown(journal.body)` — index rebuild 전·offline에도 동일 결과 가능.  
index outgoing과 **동일 소스**(entity `.md` body) — index는 캐시.

### 2.5 link index만으로 가능한가?

**✅ 가능** — incoming + (optional) entity path outgoing 조합.  
**❌ one-call 불가** — dedupe·Work 필터·title resolve **신규 계층** 필요.

---

## 3. incoming vs outgoing — 어느 방향이 적합?

| 기준 | incoming | outgoing (entity journal) |
|------|:--------:|:--------------------------:|
| R2-B canonical Work→Person | **✅ 주 경로** | △ Person body에 Work 링크 있을 때만 |
| titleOnly `[[나츠키 스바루]]` in Work | **✅** (catalog resolve) | ❌ |
| pipe label `Re:Zero` 즉시 | △ Work `AkashaItem.title` | **✅** `displayLabel` |
| catalog-only entity | **✅** (Work가 링크하면) | ❌ journal 없음 |
| 다중 Work | ✅ paths N개 | ✅ links N개 |
| 구현 선례 | Entity Sheet `_loadIncoming` | 없음 (카드·Sheet Work 목록 UI 없음) |

### 설계 권장 (Phase 2 card badge)

1. **Primary:** `incomingRecordPaths` → `findVaultItemForRecordPath` → Work list (dedupe by `workId`)
2. **Supplement:** entity `storagePath` → `outgoingLinks` → explicit `wk_*` (body에만 있는 Work)
3. **Badge 1개:** merge 후 정렬·첫 항목 — **정책 미정** (addedAt, explicit 우선 등)

**incoming이 데이터 커버리지 면에서 더 적합.** outgoing은 label 품질·Person→Work explicit authoring 보완.

---

## 4. 「Re:Zero」 배지 — 추가 저장 없이 가능?

### 4.1 결론 — **✅ 런타임 계산 가능 / ❌ 오늘 카드 UI 불가**

| 필요 입력 | 이미 존재 | 카드 wiring |
|-----------|:--------:|:-----------:|
| `RecordLinkPort linkIndex` | ✅ `CatalogEntityBrowseView` prop | ❌ 미사용 |
| `List<AkashaItem> vaultItems` | ✅ prop | ❌ Work resolve 미연결 |
| `EntityJournalEntry?` (storagePath/body) | ✅ loader | ❌ |
| `UserCatalogPort` | ✅ | title fallback |

**추가 catalog/frontmatter 필드 불필요** — link index + vaultItems + optional journal body.

### 4.2 배지 텍스트 소스 (저장 없이)

| 소스 | 텍스트 | 조건 |
|------|--------|------|
| outgoing `displayLabel` | `Re:Zero` | `[[wk_u_rezero01\|Re:Zero]]` in entity body |
| incoming → `AkashaItem.title` | `Re:Zero` | Work vault item title |
| incoming → md `title` frontmatter | Work title | vaultItems miss 시 `_readWorkIdFromMd` 경로 |
| catalog Work entity | `UserCatalogEntity.title` | `wk_*` in catalog, vault 없음 |

### 4.3 오늘 불가한 것

- 카드 위젯에 badge row **없음**
- `relatedWorks` / `EntityWorkDiscovery` **서비스 없음**
- 다중 Work → 단일 badge **선택 규칙 없음**
- Sheet도 Work **이름 목록**은 표시하지 않음 (incoming은 **Record path** 목록)

---

## 5. tags vs relatedWorks — 선행 계층

### 5.1 tags 현황

**catalog · frontmatter · body 구조화 tags — 전부 ❌** (Step 1).

### 5.2 relatedWorks 계층

| 역할 | tags 필요 | link index로 가능 |
|------|:---------:|:-----------------:|
| 카드 「Re:Zero」 badge | ❌ | ✅ §2·§4 |
| 「Re:Zero 등장 Person」 browse filter | ❌ | ✅ inverse: Work `wk_*` incoming/outgoing graph (별도 쿼리) |
| 「영웅」 semantic filter | **✅ tags 필수** | ❌ link만으로 hero 추론 불가 |

### 5.3 선행 순서 결론

| 목표 | 선행 계층 |
|------|----------|
| Entity 카드 Work 배지 · IP-scoped entity browse | **`EntityRelatedWorksDiscovery`** (파생, 저장 없음) — **tags보다 먼저** |
| 「영웅」 컬lection | **`tags` 필드** — relatedWorks **대체 불가** |

**relatedWorks 계층은 Work 연관 기능에 tags보다 먼저 필요·구현 가능.**  
**영웅 컬lection은 tags 없이는 불가** — relatedWorks와 **독립 axis**.

### 5.4 제안 계층 (설계, 미구현)

```dart
/// vault + link_index 파생 — SSOT 변경 없음
class EntityRelatedWorkRef {
  final String workId;
  final String displayTitle;  // label | AkashaItem.title | catalog
  final RelatedWorkSource source; // incoming | outgoingExplicit | bodyParse
}

abstract final class EntityRelatedWorksDiscovery {
  static Future<List<EntityRelatedWorkRef>> forEntity({
    required String entityId,
    required RecordLinkPort linkIndex,
    required List<AkashaItem> vaultItems,
    EntityJournalEntry? journal,
    UserCatalogPort? userCatalog,
  });
}
```

---

## 6. 나츠키 스바루 시나리오 (코드 검증됨)

### 6.1 Setup A — R2-B canonical (Work→Person)

```
Work Re_Zero.md:  [[pe_u_natsuki1|나츠키 스바루]]  or  [[나츠키 스바루]]
Person journal:   (Work 링크 없어도 됨)
```

| 방법 | 결과 |
|------|------|
| body parse | ❌ Work 없음 |
| incoming | ✅ 1 path → `findVaultItemForRecordPath` → title `Re:Zero` |
| badge | **가능** (incoming) |

### 6.2 Setup B — Person journal explicit

```
Person journal:   Re:Zero 1기 … [[wk_u_rezero01|Re:Zero]]
```

| 방법 | 결과 |
|------|------|
| body parse | ✅ first link label `Re:Zero` |
| outgoing(entity path) | ✅ target `wk_u_rezero01` |
| incoming | △ Work body도 Person 링크하면 중복 |
| badge | **가능** (label 직접) |

---

## 7. Step 2.5 / Phase 2 구현 체크리스트

1. `EntityRelatedWorksDiscovery.forEntity` — incoming + outgoing merge, dedupe by workId
2. Work path filter — `incoming` path under `works/` or `findVaultItemForRecordPath != null`
3. `EntityBrowseCard.relatedWorks` / `primaryWorkTitle` derived field
4. `EntityCollectibleCard` — Work badge row (1개 또는 `+N`)
5. tests — Setup A (incoming only), Setup B (outgoing label), multi-work, catalog-only

---

## 8. 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/services/record_link_parser.dart` | body `[[…]]` parse |
| `lib/services/record_link_index_service.dart` | incoming/outgoing index |
| `lib/services/record_link_navigator.dart` | path → AkashaItem, title resolve |
| `lib/models/entity_id_codec.dart` | `wk_*` → work type |
| `lib/screens/home/dialogs/entity_journal_dialog.dart` | incoming UI (Record paths) |
| `test/r2b_entity_link_pipeline_test.dart` | Work→Person E2E |
| `test/record_link_index_test.dart` | bidirectional index + entity→work body |
| `docs/policy/link-identity-policy.md` | `[[entityId\|Title]]` canonical |
