# User Local Catalog Policy — Tier 1.5 (내부 배관)

> **지위:** 사용자 발급 Entity ID · Fusion merge **기술 SSOT** — **UI 1급 개념 ❌**  
> **갱신:** 2026-06-19  
> **Archive-First:** [archive-first-realignment-plan.md](../programs/archive-first-realignment-plan.md)  
> **상위:** [ADR-011](../adr/ADR-011-entity-type-subtype.md) · [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) §5  
> **관련:** [catalog-ownership.md](catalog-ownership.md) · [entity-record-storage-masterplan.md](../programs/entity-record-storage-masterplan.md)

---

## 0. Archive-First — 제품 vs 배관

| | 사용자에게 | 시스템 내부 |
|--|-----------|-------------|
| **아카이브** | `.md` Record · 서재 · 기록 · Sheet/Workbench | Tier 2 vault |
| **catalog** | **노출 금지** | `user_entities.json` |
| **글로벌 사전** | akasha-db에서 **발견** | Tier 1 |

**「나츠키 스바루 추가」= `entities/person/…md` 아카이브.** catalog는 journal save 후 동기화.

---

## 1. 한 줄

**로컬 Entity ID·title·aliases를 `user_entities.json`에 **배관**으로 두고, Fusion·wiki link가 resolve되게 한다.  
사용자가 남기는 것·제품이 보여주는 것은 Tier 2 `.md`(Record)뿐.**

---

## 2. 왜 필요한가

| 문제 | Tier 1.5 해결 |
|------|---------------|
| Wikidata 10k+로도 **전 작품 불가** | 사용자 **롱테일** 자체 커버 |
| `sub_*_custom_*` ID가 검색·Fact layer **미연동** | `wk_u_*` + catalog store → **Fusion search** |
| wiki `[[pe_u_*]]` resolve | catalog + entity journal title/alias — **저장 canonical:** [link-identity-policy.md](link-identity-policy.md) |
| Contribution queue는 **로컬 큐** — 즉시 검색 ❌ | User catalog = **즉시** ID layer |

**AKASHA 완성도 ≠ catalog 크기 ≠ user_entities.json 줄 수.**  
**아카이브된 `.md` Record 수 · 링크 밀도**가 제품 지표.

> ~~「카탈로그 등록」과 「아카이브」 UX 분리 · Fact 먼저 → (선택) Record~~  
> **Archive-First:** Record(`.md`) 먼저 · catalog는 **동기화 부산물** (Work는 이미 이 패턴에 가깝음).

---

## 3. Tier 1.5 정의

| | Tier 1 (Global) | **Tier 1.5 (User Local)** | Tier 2 (Record) |
|--|-----------------|---------------------------|-----------------|
| **제품 노출** | 글로벌 사전 hit | **❌ UI 노출 금지** | **✅ 아카이브·서재·기록** |
| **소유** | Rune Atelier | 사용자 (배관) | **사용자** |
| **저장** | akasha-db · CDN | `catalog/user_entities.json` | `.md` + YAML |
| **내용** | Fact only | ID · title · aliases (minimal) | 감상·본문·메모 |
| **ID** | `wk_000012345` | `pe_u_*`, `wk_u_*`, … | `entity_id` in frontmatter |
| **검색** | WorksRegistry | UserCatalogStore (Fusion tier) | EntityVaultLoader · FileService |

Tier 1.5는 Tier 1을 **대체·덮어쓰지 않음**. Fusion merge **목표 순서** (Archive-First):

```
1. Vault archived .md (Tier 2 — richest · 제품 SSOT)
2. User catalog JSON (Tier 1.5 — ID/alias index)
3. Global registry (Tier 1)
```

코드 정렬: [archive-first-realignment-plan.md](../programs/archive-first-realignment-plan.md) R3-1.

---

## 4. 저장 위치

```
{vault}/
  catalog/
    user_entities.json      ← Tier 1.5 (배관 · UI 노출 ❌)
  works/                    ← Tier 2 work journal (legacy: animation/, manga/, …)
  entities/
    person/                 ← Tier 2 entity journal (Archive-First 제품 SSOT)
    concept/
    event/
    place/
    organization/
  timeline/
  journal/
  posters/
```

**Contribution 큐 (별도 — Tier 1.5 아님):**

| | 현재 (코드) | 목표 (장기) |
|--|-------------|-------------|
| 파일 | `{AppDocuments}/catalog_contributions.json` | `{vault}/catalog/` co-location 검토 |
| 역할 | 글로벌 akasha-db **제안** export | user catalog와 **분리** 유지 |

Wave 1: Contribution 경로 **이전하지 않음** — [entity-centric-wave0-review.md](../programs/entity-centric-wave0-review.md) P0-2.

### 4.1 `user_entities.json` 스키마 (v1)

```json
{
  "version": 1,
  "entities": [
    {
      "entityId": "wk_u_a1b2c3d4",
      "entityType": "work",
      "subtype": "animation",
      "title": "내가 만든 작품명",
      "titles": { "ko": "…", "en": "" },
      "creator": "",
      "releaseYear": 2024,
      "domain": "subculture",
      "aliases": [],
      "addedAt": "2026-06-19T12:00:00.000Z",
      "source": "user"
    }
  ]
}
```

| 필드 | 필수 | 비고 |
|------|:----:|------|
| `entityId` | ✅ | [ADR-011](../adr/ADR-011-entity-type-subtype.md) `*_u_*` |
| `entityType` | ✅ | Wave 1: `work` only · Phase 3+: person, event, … |
| `subtype` | ✅ (work) | = `MediaCategory.name` |
| `title` | ✅ | 검색 키 |
| `creator` · `releaseYear` · `domain` | | Fact minimum |
| `posterPath` · `description` | ❌ | **Tier 1.5 금지** — Record만 |

### 4.3 볼트 전제

Tier 1.5 SSOT는 **Sanctum vault `catalog/`** 에 둔다.

| 상태 | 동작 |
|------|------|
| **볼트 연결됨** | `user_entities.json` read/write · Fusion search merge |
| **볼트 없음** | Tier 1.5 **비활성** — 「직접 추가」는 볼트 연결 안내 (Wave 1) |

세션 한정 in-memory catalog는 **Wave 1 범위外** (friction log 후 검토).

### 4.4 파일 잠금·원자성

- 저장: **write temp → rename** (Tier 2 `.md`와 동일)
- vault watch: `user_entities.json` 변경 시 Fusion search **invalidate**

---

## 5. ID 발급

### 5.1 Work (Wave 1)

```
wk_u_{8-char-base32}
```

- `WorkIdCodec.buildUserLocal()` — 구현 Wave 1
- **Legacy `sub_*_custom_*`:** 기존 `.md` 읽기 유지 · 신규 **발급 금지**

### 5.2 Phase 3+ Entity

```
{prefix}_u_{8-char-base32}
```

- `pe_u_*`, `ev_u_*`, … — [ADR-011](../adr/ADR-011-entity-type-subtype.md) §2.4

### 5.3 Global merge (Contribution)

| 단계 | 동작 |
|------|------|
| 1 | 사용자 `wk_u_*`로 Fact + (선택) Record |
| 2 | Contribution 제출 → `catalog_contributions.json` |
| 3 | Rune Atelier merge → akasha-db `wk_0000xxxxx` |
| 4 | 앱 migration: user catalog `entityId` 치환 · `.md` `work_id` / `entity_id` 갱신 |
| 5 | `legacyIds`에 `wk_u_*` 보존 |

**자동 merge 금지** — [catalog-ownership.md](catalog-ownership.md) §4.

---

## 6. Fusion Search (발견)

검색 merge 순서 (**Archive-First SSOT**):

```
1. Vault archived .md (works/ · entities/ · timeline/ · journal/)
2. UserCatalogStore (Tier 1.5 — catalog-only · 이름만 등록 잔여)
3. WorksRegistry / EntityRegistry (Tier 1 global)
```

| 케이스 | UI 표시 (목표 카피) |
|--------|---------------------|
| Global only | 글로벌 사전 |
| Archived `.md` only | **내 아카이브** |
| Archived + global | 내 아카이브 (global 메타) |
| Catalog-only (`.md` 없음) | **「아카이브되지 않음」** + 「아카이브하기」 CTA — **예외** |

**Tier 1.5만 있고 Record 없음** — **고급 「이름만 등록」** 으로만 허용 · 기본 Person/Concept 추가 flow ❌.

### 6.1 Dedupe · 우선순위

| 규칙 | 내용 |
|------|------|
| Merge key | `entityId` canonical |
| 표시·richness | **archived `.md` > catalog JSON > global** |
| SSOT on conflict | **frontmatter `entity_id` + journal title** > catalog JSON |
| Remote exclude | archived entityIds ∪ catalog ids already covered by `.md` |

---

## 7. UX 흐름

### 7.1 Work (현재 ✅ — Archive-First 정합)

```
검색 miss → 직접 추가 → Work
  → .md 생성 (Tier 2) — **제품 결과**
  → wk_u_* catalog upsert (부수)
  → workbench
```

### 7.2 Person · Concept · Event … (**목표 R1** · 현재 코드 ❌)

```
검색 miss → 직접 추가 → Person → 「나츠키 스바루」
  → entities/person/나츠키 스바루.md 생성 (기본 ON) — **제품 결과**
  → pe_u_* catalog upsert (journal save 후)
  → Entity Sheet
  → SnackBar 「아카이브에 추가됨」 (catalog ❌)
```

**고급 · 예외 (S3'):**

```
☐ 이름만 링크용으로 등록 (journal 생성 안 함)
  → catalog JSON only
  → Fusion hit 시 「아카이브하기」 CTA
```

### 7.3 Search vs Browse 표면

| 표면 | archived `.md` | catalog-only |
|------|:--------------:|:------------:|
| FusionSearchDialog | ✅ **내 아카이브** | 🔶 아카이브 CTA |
| Browse Work 그리드 | ✅ (work only) | ❌ |
| Entity Discovery / 기록 Entity | ✅ (journal) | ❌ (R2) |
| 서재 | ✅ Work · (R2 Person) | ❌ |

상세: [archive-first-realignment-plan.md](../programs/archive-first-realignment-plan.md) · [wave1-user-catalog-spec.md](../programs/wave1-user-catalog-spec.md) §6.

---

## 8. 법무·데이터

| | Tier 1.5 |
|--|----------|
| 배포 | **사용자 로컬 only** — CDN·Git **없음** |
| Fact 필드 | Tier 1과 동일 minimal core — description·poster **금지** |
| UGC | 사용자 입력 제목·작가 — **개인 데이터** |
| Contribution | 사용자 **명시 opt-in** — 큐에만 |

---

## 9. Phase 0 Legacy 마이그레이션

| Legacy | 처리 |
|--------|------|
| `sub_*_custom_*` in `.md` | 읽기·표시 유지 |
| 신규 custom | `wk_u_*` + user catalog entry |
| (선택) 일괄 migration tool | `.md` work_id 치환 + catalog backfill — **Wave 1 후** |

---

## 10. catalog ↔ journal 동기화 (R1 SSOT)

| 이벤트 | catalog JSON | `.md` journal |
|--------|:------------:|:-------------:|
| Person **아카이브** (기본) | upsert **after** save | **create** (SSOT) |
| journal title/alias 편집 | upsert mirror | SSOT |
| journal 삭제 | remove or orphan flag | delete |
| catalog-only legacy | keep until user archives | — |
| vault load backfill | create if journal exists · catalog missing | exists |

**원칙:** 충돌 시 **frontmatter + journal body** wins.

---

## 11. 검증 (Archive-First Exit)

- [x] `wk_u_*` · multi-type ID · persist (Wave 1~4)
- [ ] Person 추가 **기본 `.md`** (R1)
- [ ] UI copy 「catalog」 user-facing **0건** (R1)
- [ ] Fusion local tier **entities/** scan (R1)
- [ ] catalog-only = **고급 opt-in only** (R1)
- [ ] Contribution queue와 catalog **역할 분리** (기존)

---

## 12. 관련 문서

| 문서 | 역할 |
|------|------|
| [ADR-011](../adr/ADR-011-entity-type-subtype.md) | Entity Type · ID |
| [vault-layout-v2.md](../product/vault-layout-v2.md) | `.md` frontmatter |
| [archive-first-realignment-plan.md](../programs/archive-first-realignment-plan.md) | **Archive-First 실행 SSOT** |
| [entity-record-storage-masterplan.md](../programs/entity-record-storage-masterplan.md) | 시나리오 S1~S7 |

---

## 13. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | 초판 — Tier 1.5 · wk_u_* · user_entities.json · Fusion merge |
| 2026-06-19 | §4 Contribution · §4.3 볼트 · §6.1 dedupe |
| 2026-06-19 | §7.1 Search vs Browse · in-memory deprecated |
| 2026-06-19 | **v2 Archive-First** — catalog=배관 · Person default Record · §10 sync |
