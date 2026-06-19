# Entity · Record 저장 마스터플랜

> **상태:** Wave 2~4 설계 SSOT (코드 **없음**)  
> **갱신:** 2026-06-19  
> **상위:** [ADR-011](../adr/ADR-011-entity-type-subtype.md) · [ADR-008](../adr/ADR-008-record-entity-time-model.md) · [vault-layout-v2.md](../product/vault-layout-v2.md)  
> **실행:** [entity-centric-evolution-plan.md](entity-centric-evolution-plan.md)

---

## 1. 한 줄

**Entity = 「무엇에 대한 것인가」(Fact, ID)** · **Record = 「내가 남긴 것」(`.md`, Kind)**.  
Type별 ID·catalog·vault 경로·frontmatter는 **동일 패턴**, Wave별로 **Work → Timeline → Person/Event** 순 확장.

---

## 2. 두 축 — Entity vs Record

```
┌─────────────────────────────────────────────────────────┐
│  Entity (Fact)                                          │
│  · entity_type + entity_id [+ subtype]                  │
│  · Tier 1 global · Tier 1.5 user catalog               │
│  · poster/description/rating ❌ (Fact minimum only)       │
└──────────────────────────┬──────────────────────────────┘
                           │ 0..1  (Journal First: 0 OK)
┌──────────────────────────▼──────────────────────────────┐
│  Record (UGC)                                           │
│  · record_kind + title + body                             │
│  · Tier 2 — vault *.md only                             │
│  · rating · poster · 감상 · 메모 ✅                       │
└─────────────────────────────────────────────────────────┘
```

| 질문 | Entity | Record |
|------|--------|--------|
| 무엇인가? | 작품·인물·사건… | 내 감상·일기·메모 |
| SSOT | JSON catalog / akasha-db | `.md` |
| ID 예 | `wk_000012345`, `pe_u_abc12345` | `record_id` / file path |
| 없을 수 있나? | catalog-only (Fact만) | Entity 없이 (Journal First) |

**Note/일기** = Entity ❌ · `RecordKind.timelineEntry` / `freeformJournal` ✅

---

## 3. Entity Type별 저장 (전 Phase)

### 3.1 ID 규칙 ([ADR-011](../adr/ADR-011-entity-type-subtype.md))

| Entity Type | Global (Tier 1) | User Local (Tier 1.5) | Subtype 예 |
|-------------|-----------------|------------------------|------------|
| **work** | `wk_\d{9}` | `wk_u_[a-z0-9]{8}` | manga, animation, game… |
| **person** | `pe_\d{9}` | `pe_u_…` | (Phase 3 — role tag 검토) |
| **event** | `ev_\d{9}` | `ev_u_…` | |
| **place** | `pl_\d{9}` | `pl_u_…` | |
| **concept** | `co_\d{9}` | `co_u_…` | |
| **organization** | `or_\d{9}` | `or_u_…` | |
| **phenomenon** | `ph_\d{9}` | `ph_u_…` | |
| **custom** | — | `cu_u_…` | 사용자 정의 |

### 3.2 Tier 1.5 catalog (공통)

**파일:** `{vault}/catalog/user_entities.json` (Wave 1~)

```json
{
  "entityId": "pe_u_x9y8z7w6",
  "entityType": "person",
  "subtype": "",
  "title": "아인슈타인",
  "creator": "",
  "addedAt": "…",
  "source": "user"
}
```

| Wave | `entityType` 지원 |
|------|-------------------|
| Wave 1 ✅ | `work` only |
| Wave 4 | `person`, `event`, `concept`, … |

**Fact 금지 필드:** `posterPath`, `description`, `rating` — Record만.

### 3.3 Tier 1 Global (Phase별)

| Phase | akasha-db |
|:-----:|-----------|
| 0~1 | **work** only (`wk_*`) |
| 3 | person · event · concept spine (100~500 seed MVP) |
| 3b | place · organization |

Global DB bulk 10k+ person — **하지 않음** (charter).

---

## 4. RecordKind별 저장

### 4.1 RecordKind enum (현재 코드)

| Kind | 의미 | Entity | Wave |
|------|------|--------|------|
| `workJournal` | 작품·(Phase 3+) Entity journal | work 등 | 0~ |
| `timelineEntry` | 일기·생각·타임라인 | optional | 4 ✅ partial |
| `freeformJournal` | 자유 메모·아이디어 | none | 3 |

**Phase 3 검토:** non-work journal용 `entityJournal` RecordKind rename — Wave 4 ADR addendum.

### 4.2 Vault 경로 ([vault-layout-v2](../product/vault-layout-v2.md))

| Record Kind | Wave | 신규 저장 경로 | Legacy (영구) |
|-------------|------|----------------|---------------|
| `workJournal` | 2+ | `{vault}/works/{subtype}/{title}.md` | `{vault}/{subtype}/{title}.md` |
| `timelineEntry` | 4 | `{vault}/timeline/{date}-{slug}.md` | — |
| `freeformJournal` | 3 | `{vault}/journal/{title}.md` | — |
| entity journal (non-work) | 4 | `{vault}/entities/{type}/{title}.md` | — |

**원칙:** 기존 `filePath` 있으면 **이동 강제하지 않음**.

### 4.3 Frontmatter v2 (요약)

#### Work journal (Wave 2 lazy write)

```yaml
entity_type: work
entity_id: "wk_u_a1b2c3d4"
subtype: animation
work_id: "wk_u_a1b2c3d4"    # mirror — deprecated 아님
record_kind: workJournal
category: animation          # legacy sync
```

#### Timeline (Phase 4 — 구현됨)

```yaml
record_kind: timelineEntry
occurred_at: "…"
entity_type: work           # optional
entity_id: "wk_000012345"   # optional link
```

#### Person journal (Wave 4 — 목표)

```yaml
entity_type: person
entity_id: "pe_u_x9y8z7w6"
record_kind: workJournal     # → entityJournal rename 검토
title: "아인슈타인"
```

#### Freeform (Wave 3)

```yaml
record_kind: freeformJournal
title: "스타트업 아이디어"
# entity_* 없음
```

---

## 5. 시나리오 — 「어떻게 저장되나」

### S1. 글로벌 사전 작품 (Tier 1 work)

| 단계 | 저장 |
|------|------|
| Fact | `wk_000012345` — akasha-db |
| Record (선택) | `{vault}/manga/제목.md` · `work_id` |
| catalog | 불필요 |

### S2. 직접 추가 작품 (Wave 1 ✅)

| 단계 | 저장 |
|------|------|
| Fact | `wk_u_*` → `user_entities.json` |
| Record (현재 UX) | 항상 `{vault}/{subtype}/제목.md` 생성 |
| Fusion | catalog tier + local tier |

### S3. catalog-only (Fact만, .md 없음)

| 단계 | 저장 |
|------|------|
| Fact | `user_entities.json` only |
| Record | 없음 |
| Fusion | 「내 catalog」 hit · Browse 그리드 ❌ |

### S4. 일기 (Journal First)

| 단계 | 저장 |
|------|------|
| Entity | **없음** |
| Record | `timeline/*.md` · `timelineEntry` |
| 나중 | `entity_id` 링크 추가 (Phase 4.4b) |

### S5. 인물 직접 추가 (Wave 4 목표)

| 단계 | 저장 |
|------|------|
| Fact | `pe_u_*` → `user_entities.json` · `entityType: person` |
| Record (선택) | `entities/person/아인슈타인.md` |
| Global (선택) | Contribution → `pe_000000042` merge |
| Fusion | Person tier merge (Work와 동일 알고리즘) |

### S6. 사건 기록 (Wave 4)

| 단계 | 저장 |
|------|------|
| Fact | `ev_u_*` catalog |
| Record | `entities/event/제2차세계대전.md` |
| Timeline link | Record 본문 또는 frontmatter `entity_id` |

---

## 6. 발견(Fusion) merge 순서

```
1. Vault archived .md (Tier 2 — richest)
2. User catalog (Tier 1.5)
3. Global registry (Tier 1)
```

동일 `entityId` → **richest wins** (filePath > catalog > global).

Browse 그리드 = Tier 1 virtual + archived `.md` only (catalog-only ❌).

---

## 7. Phase · Wave 매핑

| Wave | Entity scope | Record scope |
|------|--------------|--------------|
| **1** ✅ | work Tier 1.5 | work `.md` (legacy path) |
| **2** | work frontmatter v2 | `works/` path · ArchiveRecord round-trip |
| **3** | — | `journal/` · freeformJournal UX |
| **4** | person · event · concept | `entities/{type}/` |
| **5** | — | Connection · `[[entity_id]]` |

---

## 8. 미결 (Wave 4 ADR 전)

| # | 질문 | 권고 |
|---|------|------|
| O1 | Person subtype (감독/작가/…) | optional tag · Phase 3 MVP는 subtype 없음 |
| O2 | `entityJournal` vs `workJournal` | Wave 4 ADR addendum |
| O3 | `EntityIdCodec` 일반화 vs `WorkIdCodec` 확장 | `EntityIdCodec` 신규 Port (Wave 4) |
| O4 | akasha-db v5 person shard | Wikidata Q spine · 100~500 seed |
| O5 | Person Franchise | Work Franchise **독립** — 별 ADR |
| O6 | Animal Entity Type | **도입 안 함** — [entity-type-philosophy.md](../policy/entity-type-philosophy.md) |

---

## 9. 검증 질문 (모든 Wave)

1. 새 Type이 `MediaCategory` enum만 추가되지 않았는가?
2. `*_u_*` 와 global `*_\d{9}` namespace가 충돌하지 않는가?
3. Entity-only · Record-only · 둘 다 — 표현 가능한가?
4. Tier 2가 Tier 1/1.5 Fact를 **덮어쓰지** 않는가?

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Entity/Record 저장 SSOT · 시나리오 S1~S6 |
