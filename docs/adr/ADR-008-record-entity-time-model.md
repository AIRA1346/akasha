# ADR-008: Archive Record — Entity · Time · Link 모델

| 항목 | 내용 |
|------|------|
| **상태** | **승인 (Accepted)** |
| **날짜** | 2026-06-14 |
| **상위** | [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) §6 · [architecture-evolution-phases.md](../programs/architecture-evolution-phases.md) Phase 1 |
| **관련** | [ADR-007](ADR-007-app-layering.md) · [ADR-005](ADR-005-minimum-recordable-unit.md) |

---

## 1. 맥락

AKASHA 최종 목표는 **개인의 궁극의 아카이빙** — 작품만이 아니라 일기·생각·인물·사건까지 **축적·연결·재활용**한다.

현재 런타임은 **`AkashaItem` + `work_id`** 중심(Phase 0).  
Timeline·Entity-less Journal을 **나중에 붙이면** vault·UI·Registry 전부가 **작품 전용** 가정으로 깨진다.

---

## 2. 결정

### 2.1 최소 공통 단위 — **ArchiveRecord**

사용자가 **소유·축적**하는 모든 UGC의 공통 표현.

| 필드 | 필수 | 설명 |
|------|:----:|------|
| `recordId` | ✅ | vault 내 안정 ID (현재: `workId` 또는 path-key) |
| `kind` | ✅ | [RecordKind](lib/core/archiving/record_kind.dart) |
| `entity` | ❌ | [EntityAnchor](lib/core/archiving/entity_anchor.dart) |
| `timeAnchor` | ❌ | 사건·작성 시점 (기본: `addedAt`) |
| `storagePath` | ❌ | `.md` 경로 (Markdown SSOT) |
| `title` | ❌ | 표시용 |

**Journal First:** `entity == null` 인 Record **허용** (Phase 4 Timeline).

### 2.2 Entity Anchor

| `EntityAnchorType` | Tier 1 | Phase |
|--------------------|--------|-------|
| `work` | ✅ `wk_…` | 0 |
| `person` | 📋 | 3 |
| `event` | 📋 | 3 |
| `concept` | 📋 | 3 |
| `phenomenon` | 📋 | 3 |
| `custom` | vault-only | 0 |

`entityId` + `type` — Tier 1 Fact와 **조인**, Tier 2가 Tier 1 **덮지 않음**.

### 2.3 Time Anchor

- **기본:** frontmatter / `addedAt`
- **Timeline (Phase 4):** `occurredAt` — 작성일과 **다를 수 있음**
- **정렬:** Timeline 뷰는 `timeAnchor` 우선

### 2.4 Link

| `RecordLinkKind` | 의미 |
|------------------|------|
| `referencesEntity` | Record → Entity |
| `referencesRecord` | Record → Record (위키링크·명시 링크) |
| `sameDay` | Timeline ↔ Journal (Phase 5) |

초기: Markdown `[[…]]` 파싱 + (Phase 5) YAML link block.

### 2.5 저장 SSOT

**변경 없음:** Sanctum vault **`*.md` + YAML** = Record SSOT.  
Event Store / SQLite = Phase 6 **파생** — Record를 **대체하지 않음**.

### 2.6 레이어

```
Presentation → ArchiveRecordPort / VaultPort
Domain       → ArchiveRecord, EntityAnchor, RecordLink
Data         → Markdown 파일 · (Phase 6) ledger/SQLite cache
```

`AkashaItem`은 Phase 0~1 **workJournal 어댑터** — 즉시 제거하지 않음.

---

## 3. Phase 0 매핑

| AkashaItem | ArchiveRecord |
|------------|---------------|
| `workId` | `entity.entityId` (type: work) |
| `filePath` | `storagePath` |
| `addedAt` | `timeAnchor` |
| — | `kind: workJournal` |

Entity 없는 커스텀 `.md` → `kind: freeformJournal`, `entity: null`.

---

## 4. 검증 질문 (모든 PR)

> **「이 변경이 work-only 가정을 새로 만들지 않는가?」**  
> **「Timeline entry를 ArchiveRecord로 표현할 수 있는가?」**

---

## 5. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-14 | 초판 승인 — Phase 1 Foundation |
