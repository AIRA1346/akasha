# Wave 4 — Entity Types (Person · Event · Concept · …) 구현 스펙

> **상태:** W4-0~9 **MVP Exit** · **Archive-First R1 pending** (Add flow UX debt)  
> **갱신:** 2026-06-19  
> **Archive-First:** [archive-first-realignment-plan.md](archive-first-realignment-plan.md)  
> **철학:** [entity-type-philosophy.md](../policy/entity-type-philosophy.md) — **7종 + Custom · Animal ❌**  
> **저장:** [entity-record-storage-masterplan.md](entity-record-storage-masterplan.md)

---

## 1. 목표

Work 외 Entity를 **동일 3-tier 패턴** (Global Fact · User catalog · Record)으로 확장.

**MVP (W4 Exit):** Person 1 + Event 1 + Concept 1 — **발견 → catalog → (선택) journal → 재탐색** E2E.

> **Archive-First (R1):** E2E 목표를 **발견 → `.md` 아카이브 → catalog 동기화 → 재탐색** 으로 수정.  
> Wave 4 코드는 **catalog-first** — [wave4-exit-review §4](wave4-exit-review.md).

| 하지 않음 | 이유 |
|-----------|------|
| Animal Entity Type | Concept + Person으로 충분 |
| 10k person bulk DB | charter |
| Browse grid 전면 교체 | Entity type **필터** 추가만 |
| phenomenon Tier 1 | legacy only |

---

## 2. Type별 역할 (철학 정렬)

| Type | Fact 예 | User local 예 | Record 예 |
|------|---------|---------------|-----------|
| **Person** | `pe_000000001` Einstein | `pe_u_*` 나비(고양이) | `entities/person/나비.md` |
| **Event** | `ev_*` WW2 | `ev_u_*` 내 첫 콘서트 | `entities/event/…md` |
| **Concept** | `co_*` (sparse global) | `co_u_*` Tiger | `entities/concept/Tiger.md` |
| **Place** | `pl_*` | `pl_u_*` 단골 카페 | `entities/place/…md` |
| **Organization** | `or_*` | `or_u_*` | `entities/organization/…md` |
| **Custom** | — | `cu_u_*` | vault journal |

### 2.1 Concept vs Person (Tiger)

| 대상 | Type | 이유 |
|------|------|------|
| Tiger (종·개념) | **Concept** | 개별 존재 아님 · 재사용 |
| 쉬어 칸 | **Person** | 작품 속 개별 캐릭터 |
| 고양이 나비 | **Person** | 특정 개체 |
| 「호랑이 작품 좋아함」 | **Record** | Entity link → Concept Tiger |

---

## 3. ID · Codec

### 3.1 `EntityIdCodec` (신규 — WorkIdCodec **래핑**)

```dart
abstract final class EntityIdCodec {
  static bool isGlobalId(String id, EntityAnchorType type);
  static bool isUserLocalId(String id, EntityAnchorType type);
  static String buildUserLocal(EntityAnchorType type);
  static EntityAnchorType? typeFromId(String id);  // prefix parse
}
```

| Type | Global | User local |
|------|--------|------------|
| work | `wk_\d{9}` | `wk_u_*` |
| person | `pe_\d{9}` | `pe_u_*` |
| event | `ev_\d{9}` | `ev_u_*` |
| concept | `co_\d{9}` | `co_u_*` |
| place | `pl_\d{9}` | `pl_u_*` |
| organization | `or_\d{9}` | `or_u_*` |
| custom | — | `cu_u_*` |

**WorkIdCodec** — work branch delegate · **breaking rename 없음**.

### 3.2 `EntityAnchorType` enum 확장

```dart
enum EntityAnchorType {
  work, person, event, place, concept, organization, custom,
  phenomenon,  // @Deprecated legacy — 신규 Fact ❌
}
```

`EntityAnchor.typeForEntityId` — prefix table로 **Wave 4에서 확장**.

---

## 4. Tier 1.5 catalog 일반화

### 4.1 `user_entities.json` v2 (호환)

Wave 1 v1 **유지** — `entityType` 필드 이미 존재.

```json
{
  "entityId": "co_u_tiger01",
  "entityType": "concept",
  "subtype": "",
  "title": "Tiger",
  "aliases": ["호랑이", "백호"]
}
```

| entityType | subtype |
|------------|---------|
| work | MediaCategory.name **필수** |
| person/event/concept/… | **optional** tag (Phase 3b) |

### 4.2 `UserCatalogEntity` → generic

| Wave | Approach |
|------|----------|
| W4-1 | `UserCatalogEntity` 필드 유지 · `entityType` enum 확장 |
| W4-2 | `UserCatalogPort.search(type filter)` |
| W4-3 | `FusionSearchService` — multi-type merge |

### 4.3 Fact minimum (all types)

| 필드 | |
|------|---|
| entityId, entityType, title, addedAt | ✅ |
| creator, aliases, titles | optional |
| poster, description, rating | **❌** |

---

## 5. Record — `entities/{type}/`

```yaml
---
entity_type: concept
entity_id: "co_u_tiger01"
record_kind: entityJournal   # Wave 4 ADR — rename from workJournal
title: "Tiger"
added_at: "…"
---
```

**Wave 4 ADR addendum:** `RecordKind.entityJournal` 추가 · workJournal **유지**.

---

## 6. Global Tier 1 (Person MVP)

| 항목 | 결정 |
|------|------|
| Source | Wikidata Q-id spine (manual seed) |
| Size | **100~500** Person MVP |
| akasha-db | schema v5 draft · `entityType` column |
| CI | separate from work 10k gate |

### 6.1 Person Registry Port

```dart
abstract class EntityRegistryPort {
  Future<List<EntityFact>> search(String query, {EntityAnchorType? type});
  EntityFact? getById(String entityId);
}
```

Wave 4: `WorksRegistryAdapter` implements **work branch** · Person adapter **신규**.

---

## 7. UI (Wave 4 — 최소 · R1 Archive-First 정렬)

| 표면 | Wave 4 (구현) | Archive-First 목표 (R1+) |
|------|---------------|---------------------------|
| Fusion Search | Entity type badge · filter chips | **내 아카이브** 섹션 · catalog-only → 「아카이브하기」 CTA |
| Add dialog | Type picker · **catalog upsert 기본** | **`.md` 기본 ON** · 「이름만」= 고급 |
| Browse | Filter chips · Work grid 유지 | Entity = **archived tile** (strip/기록) · 포스터 그리드 ❌ |
| Workbench / Sheet | non-work journal template | Entity Sheet = 아카이브 표면 |

### 7.1 Add flow (Person 예) — 현재 vs 목표

**Wave 4 코드 (현재 · UX debt):**

```
Fusion → 직접 추가 → Type: Person → 「나츠키 스바루」
  → pe_u_* catalog upsert (기본)
  → ☐ entities/person/{title}.md (opt-in)
  → SnackBar 「catalog 추가」
```

**Archive-First 목표 (R1):**

```
Fusion → 직접 추가 → Type: Person → 「나츠키 스바루」
  → entities/person/나츠키 스바루.md 생성 (기본 ON)
  → pe_u_* catalog upsert (journal save 후 · 배경)
  → Entity Sheet 열림
  → SnackBar 「아카이브에 추가됨」
```

**고급 예외 (S3' · R1):**

```
☐ 이름만 링크용으로 등록 (journal 없음)
  → Fusion hit · 「아카이브하기」 CTA
```

상세: [user-local-catalog-policy.md](../policy/user-local-catalog-policy.md) §7.2 · [entity-record-storage-masterplan.md](entity-record-storage-masterplan.md) S5/S5'.

---

## 8. Fusion merge (multi-type)

```
1. Vault records (richest)
2. User catalog (all entityTypes)
3. Global registry (work + person + … shards)
```

Dedupe: same `entityId` only (title dedupe **cross-type ❌** — homonym OK).

---

## 9. Wave 4 작업 분할

| ID | 작업 | Exit |
|----|------|------|
| W4-0 | ADR-012 entityJournal RecordKind | enum |
| W4-1 | EntityIdCodec + EntityAnchor enum | tests |
| W4-2 | UserCatalog v2 multi-type | JSON round-trip |
| W4-3 | FusionSearch multi-type | concept hit |
| W4-4 | Person seed 100 + EntityRegistryPort | search |
| W4-5 | Add dialog type picker | pe_u_* E2E |
| W4-6 | entities/person journal save | `.md` |
| W4-7 | Concept MVP (user local only) | co_u_* · Tiger dogfood |
| W4-8 | Event MVP | ev_u_* |
| W4-9 | Browse entity type filter | UI |

---

## 10. Wave 4 Exit

- [x] W4-0 EntityIdCodec + EntityAnchor enum
- [x] W4-2 UserCatalog multi-type
- [x] W4-3 FusionSearch multi-type catalog
- [x] W4-4 Person seed 5 + EntityRegistryPort
- [x] W4-5 Add dialog type picker
- [x] W4-6 entities journal save (opt-in)
- [x] W4-7 Concept MVP (user local co_u_*)
- [x] W4-8 Event MVP (user local ev_u_*)
- [x] W4-9 Browse entity type filter
- [ ] Person · Event · Concept E2E dogfood

---

## 11. 의존성

```
Wave 1 (catalog pattern) ✅
Wave 2 (frontmatter v2) — entity_type in all journals
Wave 3 (optional) — journal UX for Record-only paths
```

---

## 12. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 4 entity types spec · philosophy alignment |
| 2026-06-19 | **v1.1 Archive-First** — §7 현재 vs 목표 · R1 pointer |
