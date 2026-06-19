# ADR-011: Entity Type & Subtype — 존재 아카이빙 분류 SSOT

| 항목 | 내용 |
|------|------|
| **상태** | **승인 (Accepted)** |
| **날짜** | 2026-06-19 |
| **상위** | [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) · [entity-centric-evolution-plan.md](../programs/entity-centric-evolution-plan.md) |
| **선행** | [ADR-008](ADR-008-record-entity-time-model.md) · [ADR-001](ADR-001-dual-layer-entity-model.md) |
| **관련** | [ADR-005](ADR-005-minimum-recordable-unit.md) · [user-local-catalog-policy.md](../policy/user-local-catalog-policy.md) · [vault-layout-v2.md](../product/vault-layout-v2.md) |

---

## 1. 맥락

AKASHA 최상위 분류가 **매체(Media Type)** — `manga`, `animation`, `game` … — 에 고정되면, 인물·사건·지역·아이디어·일기 확장 시 **분류 체계가 붕괴**한다.

궁극 목표는 **「세상에서 만난 모든 것」** 을 사용자 관점에서 축적·연결·재활용하는 것이다.  
작품은 **Entity Type `work`의 첫 subtype 집합**일 뿐, 제품 정의가 아니다.

[ADR-008](ADR-008-record-entity-time-model.md)은 Record·Entity Anchor·Link를 정의했으나, **Entity Type 전체 목록·ID 규칙·Work subtype 매핑**은 본 ADR에서 확정한다.

---

## 2. 결정

### 2.1 최상위 분류 = **Entity Type** (매체 ❌)

| 계층 | 역할 | 예 |
|------|------|-----|
| **Entity Type** | 「무엇을 아카이빙하는가」 | `work`, `person`, `event`, `place`, `concept` |
| **Subtype** | Type별 세분 (선택) | Work: `anime`, `manga`, `game` … |
| **Record Kind** | 「내가 남긴 것」의 형태 ([ADR-008](ADR-008-record-entity-time-model.md)) | `workJournal`, `timelineEntry`, `freeformJournal` |

**Note·일기·아이디어**는 Entity Type이 **아니다**. `RecordKind.timelineEntry` / `freeformJournal` — **Journal First**.

### 2.2 EntityAnchorType (런타임 enum — 확장)

| Type | Phase | Tier 1 Global | Tier 1.5 User Local | ID prefix |
|------|:-----:|:-------------:|:-------------------:|-----------|
| `work` | 0 | ✅ | ✅ | `wk_` · `wk_u_` |
| `person` | 3 | 📋 | ✅ | `pe_` · `pe_u_` |
| `event` | 3 | 📋 | ✅ | `ev_` · `ev_u_` |
| `place` | 3b | 📋 | ✅ | `pl_` · `pl_u_` |
| `concept` | 3 | 📋 | ✅ | `co_` · `co_u_` |
| `organization` | 3b | 📋 | ✅ | `or_` · `or_u_` |
| `phenomenon` | 3 | 📋 | ✅ | `ph_` · `ph_u_` |
| `custom` | 0 | vault-only | ✅ | `cu_u_` |

- **Global (`*_` 9자리):** Rune Atelier 큐레이션 · akasha-db (또는 entity-db) · CI
- **User local (`*_u_`):** [user-local-catalog-policy.md](../policy/user-local-catalog-policy.md) — 볼트 소유 · 즉시 검색 merge
- **Legacy:** `sub_*_custom_*` — 읽기 호환 · **신규 발급 금지** (Wave 1)

`phenomenon`은 ADR-008과 동일 유지. `place`·`organization`은 Phase 3b.

### 2.3 Work Subtype (= 현재 `MediaCategory`)

Work Entity의 **subtype** — Registry·볼트·UI 필터에 사용.

| Subtype | `MediaCategory` (Phase 0) | Minimum unit |
|---------|---------------------------|--------------|
| `manga` | `manga` | [ADR-005](ADR-005-minimum-recordable-unit.md) |
| `webtoon` | `webtoon` | 동일 |
| `animation` | `animation` | 동일 |
| `game` | `game` | 동일 |
| `book` | `book` | 동일 (라노벨·소설 포함) |
| `movie` | `movie` | 동일 |
| `drama` | `drama` | 동일 |
| `music` | — (미구현) | [ADR-002](ADR-002-music-registry-model.md) **결정 후** |

**Phase 0~1:** 코드·UI에서 `MediaCategory` 이름 유지 — **의미상 Work subtype**.  
**Phase 3+:** frontmatter `entity_type: work` + `subtype: animation` 병행 ([vault-layout-v2.md](../product/vault-layout-v2.md)).

### 2.4 ID 형식

#### Global Entity ID

```
{prefix}_{9-digit-seq}
```

| Type | Prefix | 예 |
|------|--------|-----|
| work | `wk` | `wk_000012345` |
| person | `pe` | `pe_000000001` |
| event | `ev` | `ev_000000042` |
| place | `pl` | `pl_000000010` |
| concept | `co` | `co_000000003` |
| organization | `or` | `or_000000007` |
| phenomenon | `ph` | `ph_000000001` |

- 9자리 zero-padded — Work v4와 동일 규칙
- Phase 3 전: **work만** akasha-db에 존재

#### ID 검증 API (Wave 1 — `WorkIdCodec`)

| 함수 | 패턴 | 용도 |
|------|------|------|
| `isGlobalWorkId(id)` | `^wk_\d{9}$` | Tier 1 global |
| `isUserLocalWorkId(id)` | `^wk_u_[a-z0-9]{8}$` | Tier 1.5 |
| `isLegacyMasterId(id)` | `sub_*` / `gen_*` master | Phase 0 custom |
| `isMasterFormat(id)` | 위 셋 **OR** | `ensureWorkId` · parse guard |

**주의:** `EntityAnchor.isWork` — `entityId.startsWith('wk_')` **단독 사용 금지** (`wk_u_*` 오인).  
`type == work` + `isGlobalWorkId || isUserLocalWorkId || isLegacyMasterId`.

#### User Local Entity ID

```
{prefix}_u_{8-char-base32}
```

| Type | Prefix | 예 |
|------|--------|-----|
| work | `wk_u` | `wk_u_a1b2c3d4` |
| person | `pe_u` | `pe_u_x9y8z7w6` |
| (기타) | `{type}_u` | 동일 패턴 |

- 발급: 앱 런타임 · UUID/타임스탬프 base32 — **중앙 순번 없음**
- Global merge 시: Contribution 승인 → `wk_u_*` → `wk_*` **치환** (구 ID는 `legacyIds`)

#### Legacy (읽기 전용)

```
sub_{subtype}_{identifier}_{year?}
gen_{subtype}_{identifier}_{year?}
```

- `identifier`가 `custom_*` — Phase 0 사용자 직접 등록
- 파싱·표시 **유지** · 신규 생성 **deprecated** → `wk_u_*`

### 2.5 Entity vs Record vs Connection

```
Entity (닻)          entity_id + entity_type [+ subtype]
       │
       │ 0..1  (Journal First: 없어도 됨)
       ▼
Record (UGC)         Sanctum *.md — ArchiveRecord ([ADR-008])
       │
       │ 0..N
       ▼
Connection           [[wiki]] · RecordLink · Phase 5
```

| 객체 | 질문 | 저장 SSOT |
|------|------|-----------|
| **Entity** | 「무엇에 대한 것인가?」 | Tier 1 JSON · Tier 1.5 user catalog |
| **Record** | 「내가 무엇을 남겼는가?」 | vault `*.md` |
| **Connection** | 「무엇과 연결되는가?」 | md 본문 + (Phase 5) YAML links |

### 2.6 Tier 1 / 1.5 / 2 (데이터)

| Tier | 이름 | Entity 범위 | Record |
|------|------|-------------|--------|
| **1** | Global Fact | Rune Atelier 큐레이션 | ❌ |
| **1.5** | User Local Catalog | 사용자 발급 `*_u_*` Fact | ❌ (Fact만) |
| **2** | Sanctum Record | Entity **참조** | ✅ `.md` |

Tier 2는 Tier 1·1.5 Fact를 **덮어쓰지 않음** — [product-vision.md](../product-vision.md).

### 2.7 Franchise (ADR-001) — 변경 없음

- **Work** (`wk_`) = 저장·dedupe·shard 원자
- **Franchise** = IP 1카드 · 다매체 묶음
- Person/Event 등은 Phase 3에서 **Franchise와 독립** — Work-only Franchise 가정 확장 시 별도 ADR

### 2.8 `WorksRegistry.isLegacyWorkId` (코드 naming)

현재: `!WorkIdCodec.isMasterFormat(workId)`.  
`wk_u_*`가 master 포함 시 **legacy=false**. Wave 1에서 `isNonGlobalWorkId` 등 **rename 검토** ([wave0 review §11.6](../programs/entity-centric-wave0-review.md)).

---

## 3. Phase 매핑

| Phase | Entity scope | 코드·UI |
|:-----:|--------------|---------|
| **0** | `work` only | `MediaCategory` UI · `AkashaItem` |
| **1** | Record Foundation | `ArchiveRecord` · ADR-008 ✅ |
| **1.5** | `work` user local | `wk_u_*` · Fusion search |
| **2** | vault v2 frontmatter | `entity_type` optional |
| **3** | person · event · concept · place · org | EntityRegistryPort |
| **4** | Timeline Record | Entity **optional** |
| **5** | Connection | Link index |

---

## 4. 검증 질문 (모든 PR)

> **「새 분류가 MediaCategory enum에만 추가되고 Entity Type 없이 확장되지 않는가?」**  
> **「User local ID가 Global ID namespace와 충돌하지 않는가? (`*_u_*`)」**  
> **「Record 없이 Entity Fact만 · Entity 없이 Record만 — 둘 다 표현 가능한가?」**

---

## 5. 하지 않는 것 (본 ADR 범위)

- akasha-db v5 schema 구현 (Phase 3 — 별 PR)
- `MediaCategory` 일괄 rename (UI 호환 유지)
- Note를 Entity Type으로 승격
- Custom type 무제한 사용자 정의 schema (Phase 3b 이후 검토)

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | 초판 승인 — Entity Type · Subtype · ID · Tier 1.5 |
| 2026-06-19 | §2.4.1 ID validation API · isWork 주의 (wave0 review) |
