# Entity · Record 저장 마스터플랜

> **상태:** Wave 1~5 **코드 Exit** · **Archive-First R0~R1** 정렬 중  
> **갱신:** 2026-06-19  
> **Archive-First:** [archive-first-realignment-plan.md](archive-first-realignment-plan.md)  
> **상위:** [ADR-011](../adr/ADR-011-entity-type-subtype.md) · [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) §5  
> **실행:** [entity-centric-evolution-plan.md](entity-centric-evolution-plan.md)

---

## 1. 한 줄

**Entity = 「무엇에 대한 것인가」(ID · type · title)** · **Record = 「내가 아카이빙한 `.md`」**.  
**제품 SSOT = Record.** catalog JSON / akasha-db = **발견·조인 배관**.

---

## 2. 두 축 — Entity vs Record

```
┌─────────────────────────────────────────────────────────┐
│  Entity anchor (ID layer)                               │
│  · entity_type + entity_id                              │
│  · Tier 1 global · Tier 1.5 user_entities.json (배관)  │
│  · UI 노출 ❌ · poster/description/rating ❌             │
└──────────────────────────┬──────────────────────────────┘
                           │ 0..1  (Journal First: 0 OK)
┌──────────────────────────▼──────────────────────────────┐
│  Record (제품 · UGC)                                    │
│  · record_kind + title + body in vault/*.md             │
│  · rating · poster · 감상 · [[wiki]] ✅                  │
└─────────────────────────────────────────────────────────┘
```

| 질문 | Entity (배관) | Record (제품) |
|------|---------------|---------------|
| 무엇인가? | 작품·인물·사건… **닻** | 내 감상·일기·메모 |
| SSOT | JSON / akasha-db | **`.md`** |
| 사용자가 「추가」? | **직접 ❌** (부수) | **✅** |
| 없을 수 있나? | catalog-only **예외** | Entity 없이 OK (timeline) |

---

## 3. Entity Type별 ID (변경 없음)

[ADR-011](../adr/ADR-011-entity-type-subtype.md) — `wk_*` · `pe_u_*` · `co_u_*` …

`user_entities.json` = Wave 1~ multi-type · **Person default journal** (R1).

---

## 4. RecordKind · Vault 경로

| Record Kind | 경로 | Browse/서재 |
|-------------|------|-------------|
| `workJournal` | `works/{subtype}/` · legacy `{subtype}/` | Work 그리드 |
| `entityJournal` | `entities/{type}/` | Entity tile · 기록 (R2 서재) |
| `timelineEntry` | `timeline/` | 기록 축 |
| `freeformJournal` | `journal/` | 기록 축 |

---

## 5. 시나리오 — Archive-First SSOT

### S1. 글로벌 사전 작품

| 단계 | 저장 |
|------|------|
| 발견 | `wk_000012345` — akasha-db |
| 아카이브 (선택) | `{vault}/…/제목.md` |
| catalog | 불필요 |

### S2. Work 직접 추가 ✅ (정합)

| 단계 | 저장 | 제품 |
|------|------|:----:|
| 1 | `.md` 생성 | ✅ |
| 2 | `wk_u_*` → catalog (부수) | 배관 |
| 3 | workbench | ✅ |

### S5. Person 직접 추가 — **목표 (R1)**

| 단계 | 저장 | 제품 |
|------|------|:----:|
| 1 | `entities/person/{title}.md` **기본 생성** | ✅ |
| 2 | `pe_u_*` catalog upsert (journal 후) | 배관 |
| 3 | Entity Sheet | ✅ |
| 4 | (R2) 서재 membership | ✅ |

**예:** 나츠키 스바루 → `entities/person/나츠키 스바루.md` + `pe_u_*`.

### S5'. Person · Wave 4 **현재 코드** (UX debt)

| 단계 | 저장 | 제품 |
|------|------|:----:|
| 1 | catalog upsert **기본** | ❌ (배관만) |
| 2 | journal **opt-in** | 🔶 |

→ [archive-first-realignment-plan.md](archive-first-realignment-plan.md) R1.

### S3'. 이름만 등록 — **고급 예외**

| 단계 | 저장 |
|------|------|
| catalog JSON only | wiki resolve · Fusion CTA 「아카이브하기」 |
| Record | 없음 |

**기본 flow ❌** · bulk link import 등 edge only.

### S4. 일기 (Journal First)

| 단계 | 저장 |
|------|------|
| Entity | 없음 |
| Record | `timeline/*.md` |
| 나중 | `entity_id` link |

### S6. Concept · Event · Place · Org

S5와 **동일 패턴** — `entities/{type}/` default ON.

---

## 6. 발견(Fusion) merge 순서

```
1. Vault archived .md (richest · 제품)
2. user_entities.json (catalog-only 잔여)
3. Global registry (akasha-db · person seed)
```

Browse Work 그리드 = Tier 1 virtual + **archived work `.md` only**.  
Entity = **archived entity journal** · Discovery strip · 기록 Entity (catalog-only tile ❌ R2).

---

## 7. Phase · Wave · Realignment

| 단계 | Entity | Record | Gate |
|------|--------|--------|------|
| W1~5 | multi-type ID | work + entity journal IO | code ✅ |
| **R0** | doc SSOT | Archive-First | doc ✅ |
| **R1** | sync from journal | Person default `.md` | code ⬜ |
| **R2** | — | 서재 entityId | code ⬜ |
| **R5** | — | dogfood | manual ⬜ |

---

## 8. 검증 질문

1. 사용자 「추가」의 결과가 **`.md`** 인가? (Person 포함)
2. UI에 **「catalog」** 가 보이지 않는가?
3. Tier 2가 Tier 1/1.5를 **덮지 않되**, 제품 표면은 Tier 2인가?
4. `*_u_*` namespace 충돌 없음?

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — S1~S6 |
| 2026-06-19 | **v2 Archive-First** — S5/S5'/S3' · merge · 제품 vs 배관 |
