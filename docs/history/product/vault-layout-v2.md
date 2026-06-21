# Sanctum Vault Layout v2 — Entity-Aware Storage

> **상태:** 스펙 확정 · 구현 Wave 2  
> **갱신:** 2026-06-19  
> **상위:** [ADR-011](../adr/ADR-011-entity-type-subtype.md) · [ADR-008](../adr/ADR-008-record-entity-time-model.md) · [sanctum-md-customization.md](sanctum-md-customization.md)  
> **실행:** [entity-centric-evolution-plan.md](../programs/entity-centric-evolution-plan.md) Wave 2

---

## 1. 한 줄

**볼트는 Entity-aware frontmatter와 Record 종류별 폴더를 지원하되, Phase 0 경로·필드는 영구 호환한다.**

---

## 2. 설계 원칙

| # | 원칙 |
|---|------|
| V1 | **Breaking migration 없음** — 구 `.md` 그대로 읽힘 |
| V2 | **Lazy upgrade** — 저장 시에만 새 필드 추가 |
| V3 | `work_id` **deprecated 아님** — Work Entity의 alias |
| V4 | Record SSOT = **`.md`** — JSON catalog(Tier 1.5)와 분리 |
| V5 | `timeline/` · `posters/` 스캔 규칙 **유지** |

---

## 3. 볼트 디렉터리 (v2 목표)

```
{vault}/
├── catalog/
│   ├── user_entities.json          # Tier 1.5 ([policy](../policy/user-local-catalog-policy.md))
│   └── catalog_contributions.json  # 글로벌 제안 큐 (기존)
├── posters/                        # 이미지 (공통)
├── attachments/                    # (선택) 본문 첨부
│
├── works/                          # ★ Wave 2+ 신규 Entity Journal (work)
│   ├── animation/
│   ├── manga/
│   └── …
│
├── animation/                      # ★ Phase 0 legacy — 영구 지원
├── manga/
├── … (MediaCategory.name)
│
├── timeline/                       # Timeline Record (Phase 4)
├── journal/                        # freeformJournal (Wave 3)
│
├── entities/                       # Phase 3+ — work 외 Entity Journal
│   ├── person/
│   ├── event/
│   ├── concept/
│   └── …
```

### 3.1 경로 해석 우선순위 (신규 저장)

| Record Kind | Wave | 기본 경로 |
|-------------|------|-----------|
| `workJournal` | 2+ | `{vault}/works/{subtype}/{title}.md` |
| `workJournal` | 0 (legacy) | `{vault}/{subtype}/{title}.md` |
| `timelineEntry` | 4 | `{vault}/timeline/{date}-{slug}.md` |
| `freeformJournal` | 3 | `{vault}/journal/{title}.md` |
| entity journal (non-work) | 3+ | `{vault}/entities/{type}/{title}.md` |

**기존 파일 이동 강제하지 않음.** `filePath`가 있으면 **그 경로 유지**.

### 3.2 스캔 제외 (`_skipDirNames`)

```
posters, timeline, journal, catalog, entities, node_modules, .git, .obsidian, …
```

- `catalog/` — JSON only · AkashaItem 스캔 **제외** — **Wave 1 `_skipDirNames` 필수**
- `timeline/` — ArchiveRecordPort 전용 (기존)

---

## 4. Frontmatter v2

### 4.1 Work Entity Journal (기존 `.md` 확장)

```yaml
---
# ── Entity anchor (v2 — optional) ──
entity_type: work
entity_id: "wk_000012345"      # or wk_u_a1b2c3d4
subtype: animation             # = MediaCategory

# ── Legacy (v1 — 유지) ──
work_id: "wk_000012345"        # entity_type=work 이면 entity_id와 동일 권장

# ── Record meta ──
title: "장송의 프리렌"
category: animation            # legacy — subtype과 동기화
domain: subculture
poster: "posters/frieren.jpg"
rating: 5.0
work_status: "완결"
status: "전부 봄"
my_status: "전부 봄"
is_hall_of_fame: false
creator: "…"
release_year: 2023
tags: []
added_at: "2026-06-19T12:00:00.000Z"
record_kind: workJournal       # v2 optional — infer 가능
---
```

### 4.2 파싱 규칙 (infer)

| 입력 | `entity_type` | `entity_id` | `subtype` |
|------|---------------|-------------|-----------|
| `entity_type` + `entity_id` 있음 | 그대로 | 그대로 | `subtype` or `category` |
| `work_id` only (legacy) | `work` | `work_id` | `category` |
| 둘 다 없음 | `work` (infer) | `ensureWorkId()` | `category` |
| `sub_*_custom_*` | `work` | legacy id | `category` |

### 4.3 Timeline Entry

```yaml
---
record_kind: timelineEntry
title: "오늘 프리렌 다시 봤다"
occurred_at: "2026-06-19T22:00:00.000Z"
added_at: "2026-06-19T22:05:00.000Z"
entity_type: work              # optional
entity_id: "wk_000012345"      # optional — Phase 4.4b link
---

본문 (Entity 없어도 OK — Journal First)
```

### 4.4 Freeform Journal (Wave 3)

```yaml
---
record_kind: freeformJournal
title: "스타트업 아이디어 메모"
added_at: "2026-06-19T12:00:00.000Z"
# entity_* 없음 — 나중에 concept/or organization 링크
---
```

### 4.5 Person / Event Journal (Phase 3 — 예시)

```yaml
---
entity_type: person
entity_id: "pe_u_x9y8z7w6"
record_kind: workJournal       # generic entityJournal — Phase 3 rename 검토
title: "아인슈타인"
added_at: "…"
---
```

---

## 5. ArchiveRecord 매핑

| frontmatter | ArchiveRecord |
|-------------|---------------|
| `entity_id` + `entity_type` | `EntityAnchor` |
| `work_id` (legacy) | `EntityAnchor(work, work_id)` |
| (없음) | `entity: null` · `freeformJournal` |
| `record_kind` | `RecordKind` |
| `added_at` / `occurred_at` | `timeAnchor` |
| file path | `storagePath` |

상세: [ADR-008](../adr/ADR-008-record-entity-time-model.md) · `archive_record_mapper.dart`

---

## 6. Serialize 정책 (Wave 2)

| 동작 | 규칙 |
|------|------|
| **Read** | legacy + v2 **모두** |
| **Write (legacy path)** | `work_id` + `category` **유지** · `entity_*` **추가** (lazy) |
| **Write (works/ path)** | `entity_type` + `entity_id` + `subtype` **권장** · `work_id` mirror |
| **poster** | [sanctum-md-customization.md](sanctum-md-customization.md) · registry CDN mirror 금지 |

---

## 7. Tier 1.5 catalog ↔ `.md` 조인

```
user_entities.json   entityId: wk_u_xxx
        ↕ (동일 ID)
work journal .md     entity_id: wk_u_xxx  (아카이브 후)
```

- catalog-only: `.md` **없음** — Fact 카드만
- archive: `.md` 생성 시 `entity_id` = catalog `entityId`

---

## 8. 마이그레이션

| 항목 | 정책 |
|------|------|
| 일괄 폴더 이동 | **하지 않음** |
| 일괄 frontmatter | **선택 도구** (Wave 2 후) |
| lazy | 저장 시 `entity_type`/`entity_id` 추가 |
| legacy `custom_*` | 읽기 유지 · catalog backfill **선택** |

---

## 9. Wave 2 Exit 체크리스트

- [ ] Parser: `entity_type` / `entity_id` read + legacy infer
- [ ] Serializer: lazy v2 fields on save
- [ ] `works/` 신규 경로 · legacy 경로 **병행**
- [ ] `ArchiveRecordMapper` — frontmatter ↔ domain **round-trip**
- [ ] 기존 test fixtures **무변경 pass**

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | 초판 — v2 layout · frontmatter · 호환 규칙 |
