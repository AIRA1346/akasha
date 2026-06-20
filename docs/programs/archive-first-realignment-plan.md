# Archive-First Realignment Plan — catalog는 배관, `.md`가 제품

> **일자:** 2026-06-19  
> **상태:** **방향 확정 · R0 doc ✅ · R1 구현 전**  
> **트리거:** Person(예: 나츠키 스바루) 추가 시 catalog만 생기고 `.md`/서재에 안 들어가는 UX — **제품 의도와 불일치**  
> **북극성:** [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) §5 Entity Archive  
> **대체하지 않음:** Wave 0~6 기술 산출 — **UX·우선순위·용어** 재정렬

---

## 1. 한 줄 (수정된 방향)

**AKASHA에서 사용자가 「추가」하는 것 = Tier 1.5 catalog Fact ❌ → Sanctum vault `.md` Record ✅**

- **catalog (`user_entities.json`)** = Fusion 검색 · ID 조인 · wiki link resolve **내부 배관**
- **서재 · Browse · 기록 · Workbench/Entity Sheet** = 사용자가 보는 **아카이브 표면**
- **완성도 지표** = catalog 크기 ❌ · **아카이브된 Record 수 · 링크 밀도** ✅

---

## 2. 무엇이 잘못 기울었나

### 2.1 Wave 4가 만든 UX (현재)

```
Person 추가
  → user_entities.json (기본·필수)
  → entities/person/*.md (체크 opt-in)
  → SnackBar 「catalog 추가」
  → Browse 포스터 그리드 ❌
  → 서재 ❌
```

### 2.2 사용자(제품) 의도

```
Person 추가 = 「나츠키 스바루를 아카이빙한다」
  → entities/person/나츠키 스바루.md (기본)
  → 기록 축 / Entity 목록 / (선택) 서재
  → catalog는 보이지 않음 (배경 동기화만)
```

### 2.3 문서·구현 gap

| 문서 | 말하는 것 | Wave 4 UX |
|------|-----------|-----------|
| ultimate §5 | Entity Journal = `.md` | catalog-first |
| user-local-catalog-policy | Fact 먼저 → (선택) Record | Person은 Record가 **선택** |
| storage-masterplan S5 | pe_u_* + **(선택)** journal | **기본이 S3 catalog-only** |

**결론:** Tier 1.5 **엔지니어링 패턴**을 **제품 1급 경험**으로 올린 것이 근본 원인.

---

## 3. 제품 언어 SSOT (User-facing)

| ❌ UI/카피에서 제거 | ✅ 대체 |
|-------------------|--------|
| catalog 추가 | **아카이브에 추가** |
| 내 catalog | **내 아카이브** / **내 Entity** |
| catalog-only | **이름만 등록** (고급·예외) |
| Tier 1.5 | *(사용자에게 노출 금지)* |
| Fact layer | *(내부)* |

**Fusion 검색 섹션:**

| 현재 | 목표 |
|------|------|
| 📋 내 catalog — Work | 📂 **내 아카이브** — Work |
| 📋 내 catalog — Entity | 📂 **내 아카이브** — Person/Concept… |
| (catalog-only hit) | **「아직 아카이브 안 됨 — 아카이브하기」** CTA |

---

## 4. 목표 사용자 여정 (Person 예)

### 4.1 Primary — Archive First (기본)

```
Fusion → 직접 추가 → Person → 「나츠키 스바루」
  1. pe_u_* 발급 (배경, user_entities.json upsert)
  2. entities/person/나츠키 스바루.md 생성 (기본 ON)
  3. Entity Sheet 열림 (journal 편집)
  4. SnackBar 「아카이브에 추가됨 · 기록 → Entity에서 확인」
  5. (Phase R2) 서재에 담기 제안
```

### 4.2 Secondary — Name-only anchor (예외)

```
「이름만 링크용으로 등록」 (고급)
  → .md 없음 · wiki [[pe_u_*]] resolve만
  → UI: 「아카이브되지 않음」 badge · 「지금 아카이브」 CTA
```

### 4.3 Work와의 관계

| | Work | Person (목표) |
|--|------|---------------|
| 기본 결과 | `.md` + workbench | `.md` + Entity Sheet |
| catalog JSON | saveItem 후 **부수 동기화** | journal save 후 **부수 동기화** |
| Browse | 포스터 그리드 | Entity tile (strip / 기록) |
| 서재 | ✅ | ✅ (R2) |

**Work-first Browse 그리드 유지** — Person을 Work 포스터로 합치지 **않음**.  
대신 **「아카이브됐다」** 는 동일한 무게감.

---

## 5. 아키텍처 — 유지 vs 변경

### 5.1 유지 (코드 자산)

| 컴ponent | 이유 |
|----------|------|
| `UserCatalogStore` / `user_entities.json` | 로컬 ID · Fusion merge · `[[wiki]]` resolve |
| `EntityIdCodec` | cross-type ID |
| `EntityVaultStore` / `entities/{type}/` | Record SSOT |
| `RecordLinkIndexService` | Connection |
| akasha-db (Tier 1 global) | Work/Person **발견** 사전 — 별 트랙 |

### 5.2 변경 (우선순위·기본값·카피)

| 영역 | 변경 |
|------|------|
| Add Person dialog | journal **기본 ON** · 「이름만」→ 고급 |
| `onCatalogEntityAdded` | → `onEntityArchived` · strip/highlight **journal path** |
| Fusion sections | catalog-only hit → **「아카이브하기」** |
| `EntityVaultLoader` | **1급 load path** (Browse/기록/Fusion local tier) |
| 서재 membership | workId only → **entityId** (R2) |
| dogfood checklist | catalog 단계 → **.md 존재** 단계 |

### 5.3 장기 (선택)

| 항목 | 내용 |
|------|------|
| catalog-only S3 | **예외 API**로 격하 — bulk link import 등 |
| Person Browse tile | 포스터 없는 **Archive tile** (Phase A strip 확장) |
| Unified ArchiveRecord UI | Work workbench ‖ Entity Sheet **공통 shell** (R4) |

---

## 6. 실행 Phase

### Phase R0 — 방향·문서 (코드 최소) · **지금**

| ID | 작업 | Exit |
|----|------|------|
| R0-1 | 본 plan SSOT | ✅ |
| R0-2 | `user-local-catalog-policy.md` — 「배관 layer」 명시 · Person default **Record** | ✅ |
| R0-3 | `entity-record-storage-masterplan.md` S3/S5 순서 수정 | ✅ |
| R0-4 | `entity-centric-roadmap.md` — Archive-First Phase R | ✅ |
| R0-5 | Wave 4~5 exit review · wave4 spec §7 · dogfood checklist | ✅ |

**Gate:** 팀(=본인) 「catalog는 UI에 안 나온다」 합의 — **문서 SSOT 완료** · R1 착수 대기.

---

### Phase R1 — Add flow 뒤집기 · **P0**

| ID | 작업 | 파일(주) | Exit |
|----|------|----------|------|
| R1-1 | Person/Event/Concept/Place/Org 추가 **기본 journal 생성** | `add_catalog_entity_dialog.dart`, `home_dialogs_coordinator.dart` | E2E: Person → `.md` exists |
| R1-2 | catalog upsert **journal save 이후** (title/aliases frontmatter 동기화) | `entity_vault_store.dart`, `user_catalog_store.dart` | idempotent |
| R1-3 | SnackBar/카피 전면 교체 「catalog」→「아카이브」 | `home_shell_controller.dart`, fusion, dialogs | grep `catalog` UI 0 |
| R1-4 | Fusion **local tier** = vault `entities/` scan 우선 | `fusion_search_service.dart` | archived Person hit |
| R1-5 | catalog-only hit → 「아카이브하기」 CTA | `fusion_search_dialog.dart` | no dead-end |
| R1-6 | tests + dogfood checklist 갱신 | `test/`, `wave5-dogfood-checklist.md` | green |

**Exit:** 나츠키 스바루 Person 추가 → **`.md` 1클릭** · Entity Sheet · link index.

---

### Phase R2 — 서재·기록 축 · **P1**

| ID | 작업 | Exit |
|----|------|------|
| R2-1 | `PersonalLibraryMembership` — **entityId** (non-work) | Person in curated library |
| R2-2 | `RecordsView` / Entity tab — **primary** Entity 목록 (journal 기준) | catalog strip 보조 |
| R2-3 | Entity Discovery strip — **archived only** (journal 있는 것) | strip = 아카이브 preview |
| R2-4 | Add flow 후 「서재에 담기」 (Work parity) | optional dialog |

---

### Phase R3 — Fusion·검색 재정렬 · **P1**

| ID | 작업 | Exit |
|----|------|------|
| R3-1 | Fusion merge order 명시: **vault `.md` > catalog JSON > global** | doc+code align |
| R3-2 | Local search: `EntityVaultLoader` + `AkashaItem` merge | Person title search |
| R3-3 | 「이름만 등록」 엔트리 — 검색 hit 시 아카이브 CTA | S3 예외 UX |
| R3-4 | titleOnly `[[나츠키 스바루]]` → archived journal 우선 resolve | wave5 enhancement |

---

### Phase R4 — Unified Archive UX · **P2**

| ID | 작업 | Exit |
|----|------|------|
| R4-1 | `ArchiveRecordPort` list — work + entity journal 단일 API | coordinator 단순화 |
| R4-2 | Entity Sheet ↔ mini workbench (편집·링크·sameDay 동일 품질) | dogfood |
| R4-3 | Browse: **Archived Entity** 섹션 (Work grid 아래, strip → grid-lite) | 발견성 |
| R4-4 | catalog-only legacy 마이그레이션 tool (opt-in → `.md` 생성) | one-shot script |

---

### Phase R5 — dogfood Gate · **P0 (R1 후)**

| ID | 작업 |
|----|------|
| R5-1 | Archive-First dogfood checklist (Person · Concept · link · 서재) |
| R5-2 | Friction → R1~R3 backfill |
| R5-3 | roadmap 🟢 Gate |

---

## 7. 수정 대상 인벤토리 (코드)

| 모듈 | R1 | R2 | R3 | 비고 |
|------|:--:|:--:|:--:|------|
| `add_catalog_entity_dialog.dart` | ● | | | default journal |
| `home_dialogs_coordinator.dart` | ● | | | save order |
| `home_dialogs_facade.dart` | ● | | | copy |
| `home_shell_controller.dart` | ● | | | snack/highlight |
| `fusion_search_dialog.dart` | ● | ● | ● | sections/CTA |
| `fusion_search_service.dart` | ● | | ● | local merge |
| `catalog_entity_browse_view.dart` | ● | ● | | archived filter |
| `entity_journal_view.dart` | | ● | | primary list |
| `entity_vault_loader.dart` | ● | ● | ● | 1st class |
| `personal_library_*` | | ● | | entityId |
| `record_link_navigator.dart` | | | ● | resolve order |
| `user_catalog_store.dart` | ● | | ● | sync from md |

---

## 8. 수정 대상 인벤토리 (문서)

| 문서 | 변경 |
|------|------|
| `user-local-catalog-policy.md` | §1 「배관」·Person default Record |
| `entity-record-storage-masterplan.md` | S3/S5 · Browse 정의 |
| `wave4-entity-types-spec.md` | §7 UI · exit checklist |
| `entity-centric-roadmap.md` | Archive-First Phase R |
| `wave5-dogfood-checklist.md` | legacy · superseded by archive-first |
| `archive-first-dogfood-checklist.md` | R5 Gate |
| `wave4-exit-review.md` | UX debt pointer |

---

## 9. 마이그레이션 (기존 볼트)

| 케이스 | 처리 |
|--------|------|
| catalog-only Person (`.md` 없음) | 유지 · Fusion hit · **「아카이브하기」** CTA |
| journal만 있고 catalog 없음 (버그) | loadItems 시 catalog **backfill** |
| journal + catalog 불일치 title | journal frontmatter **SSOT** |

**Breaking migration 없음** — lazy backfill only.

---

## 10. 하지 않을 것 (scope guard)

| ❌ | 이유 |
|----|------|
| Person을 Work `BrowseCard`/포스터 그리드에 넣기 | Work-first · 다른 tile UX |
| catalog UI 제거 후 JSON 삭제 | ID·resolve still needed |
| akasha-db Person 10k bulk | charter |
| Graph DB / Memory Core 전면 | W6 PoC 이후 |
| dogfood 전 R4 Unified Shell | R1~R2 먼저 |

---

## 11. 우선순위 (한 장)

```
[R0] 문서·용어 SSOT          ← ✅ 완료
[R1] Person 추가 = .md 기본   ← P0 코드 (1~2 PR) · **다음**
[R5] dogfood Gate            ← R1 직후
[R2] 서재·기록               ← P1
[R3] Fusion 재정렬           ← P1
[R4] Unified Archive UX      ← P2
[W6-2~3] ledger/SQLite/MCP   ← non-blocking · R1과 병렬 가능
```

---

## 12. 성공 지표 (Archive-First)

| 지표 | 측정 |
|------|------|
| Person 추가 → `.md` 생성률 | **>95%** (기본 flow) |
| UI copy 「catalog」 | **0건** (user-facing) |
| catalog-only Person 비율 | **<5%** (고급만) |
| `entities/` journal → Entity tab 노출 | 100% |
| wiki link → archived Entity open | dogfood A1~A6 |

---

## 13. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Archive-First realignment · Phase R0~R5 |
| 2026-06-19 | **v1.1** — R0 doc Exit ✅ · R1 next |
