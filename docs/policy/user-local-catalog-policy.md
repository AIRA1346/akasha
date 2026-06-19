# User Local Catalog Policy — Tier 1.5

> **지위:** 사용자 발급 Entity Fact **정책 SSOT**  
> **갱신:** 2026-06-19  
> **상위:** [ADR-011](../adr/ADR-011-entity-type-subtype.md) · [entity-centric-evolution-plan.md](../programs/entity-centric-evolution-plan.md) Wave 1  
> **관련:** [catalog-ownership.md](catalog-ownership.md) · [catalog_contribution_service.dart](../../lib/services/catalog_contribution_service.dart)

---

## 1. 한 줄

**글로벌 akasha-db에 없는 Entity도, 사용자 볼트 안에서 Fact layer(Tier 1.5)로 등록·검색·조인할 수 있다.  
감상·포스터·본문은 Tier 2 `.md`(Record)에만 둔다.**

---

## 2. 왜 필요한가

| 문제 | Tier 1.5 해결 |
|------|---------------|
| Wikidata 10k+로도 **전 작품 불가** | 사용자 **롱테일** 자체 커버 |
| `sub_*_custom_*` ID가 검색·Fact layer **미연동** | `wk_u_*` + catalog store → **Fusion search** |
| 「카탈로그 등록」과 「아카이브」 UX 분리 | **Fact 먼저 → (선택) Record** 한 흐름 |
| Contribution queue는 **로컬 큐** — 즉시 검색 ❌ | User catalog = **즉시** 발견 layer |

**AKASHA 완성도 ≠ 카탈로그 크기.** 사용자가 **기록하고 싶은 대상**을 담는 그릇이 우선.

---

## 3. Tier 1.5 정의

| | Tier 1 (Global) | **Tier 1.5 (User Local)** | Tier 2 (Record) |
|--|-----------------|---------------------------|-----------------|
| **소유** | Rune Atelier | **사용자** | **사용자** |
| **저장** | akasha-db · CDN | **볼트 내 catalog** | `.md` + YAML |
| **내용** | Fact only | **Fact only** | 감상·포스터·본문 |
| **ID** | `wk_000012345` | **`wk_u_a1b2c3d4`** | `work_id` / `entity_id` 조인 |
| **검색** | WorksRegistry | **UserCatalogStore** | FileService / vault scan |
| **배포** | Git · CDN | **로컬 only** | **로컬 only** |

Tier 1.5는 Tier 1을 **대체·덮어쓰지 않음**. Fusion 시 **global → user local → vault record** 순 merge.

---

## 4. 저장 위치

```
{vault}/
  catalog/
    user_entities.json      ← Tier 1.5 SSOT (Wave 1)
  animation/                ← Tier 2 (기존)
  manga/
  timeline/
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

검색·자동완성·Browse pipeline merge 순서:

```
1. WorksRegistry (Tier 1 global)
2. UserCatalogStore (Tier 1.5) — 동일 entityType/subtype 필터
3. Vault archived .md (Tier 2 — title/work_id match)
```

| 케이스 | 표시 |
|--------|------|
| Global only | Fact 카드 (포스터 ❌) |
| User local only | Fact 카드 + 「내 catalog」badge |
| Global + archived `.md` | 나만의 서재 카드 |
| User local + `.md` | 동일 |

**Tier 1.5만 있고 Record 없음** — **허용** (Fact 등록만 한 상태).

### 6.1 Dedupe · 우선순위 (Wave 1 필수)

| 규칙 | 내용 |
|------|------|
| Merge key | `entityId` canonical 우선 · 없으면 normalized `title` + `subtype` |
| 표시 우선 | archived `.md` > user catalog > global (UI richness) |
| Remote exclude | `localWorkIds ∪ userCatalogEntityIds` |
| Legacy `sub_*_custom_*` | Wave 1 catalog backfill **안 함** — `.md` scan으로 검색 |
| 동일 title · 다른 ID | **두 Fact 허용** — 사용자 merge는 Phase 5 Connection 전까지 수동 |

---

## 7. UX 흐름 (Wave 1 목표)

```
검색 miss
  → 「직접 추가」
  → Tier 1.5 Fact 생성 (wk_u_*)
  → (선택) 아카이브 → Tier 2 .md 생성
  → (선택) 글로벌 Contribution 제출
```

**한 다이얼로그**에서 Fact 필드 + (선택) rating/poster는 **아카이브 시** Record로.

볼트 없을 때 in-memory custom add는 **Wave 1에서 deprecated** — [wave1-user-catalog-spec.md](../programs/wave1-user-catalog-spec.md) §7.

### 7.1 Search vs Browse 표면

| 표면 | catalog-only (`wk_u_*`, `.md` 없음) |
|------|-------------------------------------|
| FusionSearchDialog | ✅ Wave 1 |
| BrowsePipeline 그리드 | ❌ Wave 1 (Tier 1 virtual only) |
| RegistryWorkAutocomplete | 🔶 W1.1 optional |

상세: [wave1-user-catalog-spec.md](../programs/wave1-user-catalog-spec.md) §6.

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

## 10. 검증 (Wave 1 Exit)

- [ ] `wk_u_*` 발급 · `user_entities.json` persist
- [ ] Fusion search에서 user-only work **hit**
- [ ] Global work와 **ID namespace 충돌 없음**
- [ ] `.md` 없이 catalog-only entry **표시 가능**
- [ ] Contribution queue와 catalog store **역할 분리** 문서·코드 일치
- [ ] Legacy `custom_*` 신규 생성 경로 **제거**

---

## 11. 관련 문서

| 문서 | 역할 |
|------|------|
| [ADR-011](../adr/ADR-011-entity-type-subtype.md) | Entity Type · ID |
| [vault-layout-v2.md](../product/vault-layout-v2.md) | `.md` frontmatter |
| [entity-centric-evolution-plan.md](../programs/entity-centric-evolution-plan.md) | Wave 1 실행 |

---

## 12. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | 초판 — Tier 1.5 · wk_u_* · user_entities.json · Fusion merge |
| 2026-06-19 | §4 Contribution · §4.3 볼트 · §6.1 dedupe |
| 2026-06-19 | §7.1 Search vs Browse · in-memory deprecated |
