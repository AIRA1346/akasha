# Entity-Centric Wave 0 — 설계 검토 보고서

> **일자:** 2026-06-19  
> **범위:** ADR-011 · user-local-catalog-policy · vault-layout-v2 · entity-centric-evolution-plan  
> **대상:** Wave 1 코드 착수 **전** Gate  
> **판정:** 🟢 **통과 (조건부)** — v2 검토 · Wave 1 spec 확정 · W1-0 선행 후 코드  
> **v2:** 2026-06-19 — 코드 경로·UX·Port·Browse/Search 표면 · ensureWorkId inventory

---

## 1. Executive Summary

Wave 0 설계는 **ADR-008 · ultimate-archiving-vision · GPT Entity 대화**와 **95% 정합**하며, **대개편 없이 진화** 가능한 방향이 맞다.

다만 **현재 코드와의 gap**·**문서 간 불일치**·**ID/검색 경계 미정** 이 Wave 1에서 **회귀·중복·silent bug** 를 만들 수 있다.  
본 검토에서 **P0 5건**을 식별했고, §7 패치로 W0 문서를 보완한다.  
**v2**에서 코드 경로·UX 3갈래·Browse vs Search·`ensureWorkId` 7곳·Wave 1 spec을 추가한다.

| 문서 | v2 산출 |
|------|---------|
| [wave1-user-catalog-spec.md](wave1-user-catalog-spec.md) | W1 구현 SSOT |

| 영역 | 등급 | 요약 |
|------|:----:|------|
| 북극성·Phase 순서 | 🟢 | Entity→Record→Connection · Wave 0→6 타당 |
| ADR-011 ID 체계 | 🟡 | `wk_u_*` vs `isWkFormat` · `EntityAnchor.isWork` 충돌 |
| Tier 1.5 정책 | 🟡 | Contribution **저장 위치** 문서≠코드 |
| Vault v2 | 🟢 | lazy·legacy 호환 원칙 적절 |
| Wave 1 구현 준비 | 🟢 | spec · Port · UX 3갈래 확정 |

---

## 2. 강점 (유지)

### 2.1 기존 로드맵과 동일 방향

- `lib/core/archiving/*` — ArchiveRecord · EntityAnchor · RecordKind **이미 존재**
- Phase 4 Timeline read path **부분 구현**
- `FusionSearchDialog` — local `.md` + remote registry + custom CTA **골격 있음**
- Journal First — ADR-008과 GPT Note→Record 정렬 **일치**

### 2.2 대개편 회피 원칙

- `MediaCategory` UI 유지 · legacy `{category}/` 볼트 **영구 호환**
- Tier 1 akasha-db와 Tier 1.5 **분리** — 법무·운영 부담 분리
- Wave Exit gate — scope creep 방지

### 2.3 완성도 지표

「카탈로그 크기 ≠ AKASHA 완성도」— product-vision·GPT 정렬 **명확**

---

## 3. P0 — Wave 1 전 필수 해결

### P0-1. `wk_u_*` vs `WorkIdCodec.wkIdPattern`

**현재 코드:**

```dart
static final RegExp wkIdPattern = RegExp(r'^wk_\d{9}$');
static bool isWkFormat(String workId) => wkIdPattern.hasMatch(workId);
static bool isMasterFormat(String workId) =>
    isWkFormat(workId) || _masterPattern...;
```

**문제:**

- `wk_u_a1b2c3d4`는 `isWkFormat` ❌ · `isMasterFormat` ❌
- `MarkdownParser.ensureWorkId()` — master 아니면 global search 후 **`buildCustom()`** 재발급 → **wk_u 덮어씀**
- `EntityAnchor.isWork` — `startsWith('wk_')` → **`wk_u_*`도 true** (global/user 구분 불가)

**필수 조치 (W1):**

| API | 규칙 |
|-----|------|
| `isGlobalWorkId(id)` | `^wk_\d{9}$` |
| `isUserLocalWorkId(id)` | `^wk_u_[a-z0-9]{8}$` (정규식 ADR-011 확정) |
| `isMasterFormat(id)` | global **OR** user local **OR** legacy sub/gen |
| `EntityAnchor.isWork` | type==work **AND** (global OR user local OR legacy) — prefix만 ❌ |
| `ensureWorkId()` | user local·legacy **보존** — buildCustom 금지 |

---

### P0-2. Contribution 큐 저장 위치 — 문서 ≠ 코드

| | 문서 (policy §4) | **현재 코드** |
|--|------------------|---------------|
| 경로 | `{vault}/catalog/catalog_contributions.json` | `{ApplicationDocumentsDirectory}/catalog_contributions.json` |

`CatalogContributionService._queueFile()` — **볼트와 무관**.

**결정 필요 (본 검토 권고):**

| 옵션 | 내용 |
|------|------|
| **A (권고)** | Wave 1: **user_entities만 vault** · Contribution은 **당분간 app data 유지** — policy에 「현재/목표」 분리 |
| B | Wave 1에서 Contribution도 vault `catalog/`로 **이전** — 마이그레이션·볼트 미연결 UX 추가 |

**W1 범위:** 옵션 A — Contribution vault 이전은 **Wave 1.5 또는 W2**.

---

### P0-3. 파일명 불일치 — `user_works.json` vs `user_entities.json`

- `entity-centric-evolution-plan.md` W1-1: `user_works.json` **또는** `catalog/*.json`
- `user-local-catalog-policy.md`: `user_entities.json` ✅

**결정:** SSOT = **`user_entities.json`** (Phase 3+ entity type 공용). evolution plan W1-1 문구 통일.

---

### P0-4. 볼트 미연결 시 Tier 1.5

Tier 1.5를 vault `catalog/`에 두면:

- 볼트 **없음** → user catalog **persist 불가**
- 현재 `add_work_dialog` → in-memory `AkashaItem` + `buildCustom()` — **세션 종료 시 유실**

**필수 스펙 (W1):**

```
볼트 연결됨  → user_entities.json (SSOT)
볼트 없음    → (a) catalog-only 비활성 + 「볼트 연결 후 등록」 UX
            또는 (b) app data 임시 버퍼 → 볼트 연결 시 merge
```

**권고:** v1.x **(a) 볼트 필수** — policy §「볼트 전제」 명시. (b)는 friction log 후.

---

### P0-5. Fusion merge — dedupe·우선순위 미정

Policy §6 순서: global → user local → vault `.md`

**미정 케이스:**

| 케이스 | 위험 |
|--------|------|
| 동일 title · 다른 ID (global vs wk_u) | 검색 결과 **2줄** |
| user catalog + archived `.md` 동일 entityId | **중복 카드** |
| legacy `sub_*_custom_*` .md + 신규 wk_u catalog | **2 entity** |

**필수 규칙 (W1 spec):**

1. Merge key = **`entityId` (canonical)** 우선 · 없으면 normalized title+category
2. 우선순위: archived `.md` > user catalog > global (UI richness)
3. Remote hit excludes IDs in **localWorkIds ∪ userCatalogIds**
4. Legacy custom `.md` — catalog backfill **하지 않음** (Wave 1) · search는 `.md` scan으로 cover

---

## 4. P1 — Wave 1~2에서 해결

### P1-1. `EntityAnchorType` enum — ADR-011 vs 코드

- ADR-011: `place`, `organization` 추가
- `entity_anchor.dart`: **미포함**

**조치:** Wave 4 전까지 enum 추가 **보류 OK** — 단 W1 PR에서 `isWork` 수정 시 ADR-011 주석 링크.

### P1-2. Subtype 명칭 — `anime` vs `animation`

- entity-centric-plan 본문: `anime` (GPT 습관)
- `MediaCategory`: **`animation`**

**조치:** 모든 SSOT에서 **`animation`** 사용. UI 라벨 「애니」와 분리.

### P1-3. `RegistryWork` vs User Entity 모델

- Tier 1.5 JSON: `entityType` + `subtype`
- 런타임: `RegistryWork`는 **work 전용**

**권고 (W1):**

- `UserCatalogEntity` (lightweight) + `toRegistryWork()` adapter for Fusion UI
- `RegistryPort` 일반화는 **W4**

### P1-4. `_skipDirNames`에 `catalog` 없음

Wave 1에서 `catalog/` 추가 시 **반드시** `_skipDirNames`에 `catalog` 추가 — `.md` 오인 스캔 방지.

### P1-5. `CatalogAddWorkProposal` — Tier 1 필드 혼재

Contribution proposal에 `posterPath`·`description` **포함** — Tier 1 정책과 긴장.

**기존 동작 유지** — Contribution = 「글로벌 **제안**」 별도 경로. Tier 1.5 catalog에는 **넣지 않음** (policy ✅).

### P1-6. vault-layout v2 §4.5 `record_kind: workJournal` for person

Person journal에 `workJournal` — **임시**. Phase 3에 `entityJournal` RecordKind 추가 검토. Wave 2 전 문서 주석으로 충분.

### P1-7. product-vision §7 stale

「490+ Fact」— manifest **10048**. 스토어 카피 이슈와 별도 · 문서 housekeeping.

---

## 5. P2 — Wave 3+ / 별도 ADR

| 항목 | 비고 |
|------|------|
| akasha-db v5 `entityType` | W4 |
| `music` subtype | ADR-002 A/B 미결 |
| `cu_u_*` custom Entity ID | vault-only · Phase 3b |
| Franchise + Person/Event | ADR-001 Work-centric — 별 ADR |
| Browse grid에 catalog-only Fact | W1-2 UI spec |
| Contribution → wk_u ID 치환 migration tool | merge 후 |

---

## 6. 코드 Gap 매트릭스 (Wave 1)

| 컴포넌트 | 현재 | W1 필요 |
|----------|------|---------|
| `WorkIdCodec` | `buildCustom()` only | `buildUserLocal()` · pattern helpers |
| `UserCatalogStore` | ❌ | `catalog/user_entities.json` |
| `WorksRegistry.search` | global only | **FusionSearchService** or merge layer |
| `FusionSearchDialog` | local md + remote | + user catalog tier |
| `RegistryWorkAutocomplete` | global only | + user catalog (optional W1.1) |
| `MarkdownParser.ensureWorkId` | → buildCustom | preserve wk_u / legacy |
| `EntityAnchor.isWork` | `startsWith('wk_')` | global/user split |
| `AkashaFileService._skipDirNames` | no `catalog` | add `catalog` |
| `CatalogContributionService` | app documents | **문서 정정** (이전 defer) |
| `_ensureFolderStructure` | no `catalog/` | create `catalog/` |

---

## 7. W0 문서 패치 (본 검토 반영)

| # | 문서 | 패치 |
|---|------|------|
| 1 | user-local-catalog-policy | §4 Contribution **현재 vs 목표** · §「볼트 전제」 |
| 2 | ADR-011 | §2.4.1 ID validation · `isWork` 주의 |
| 3 | entity-centric-evolution-plan | W1-1 filename · Fusion dedupe task W1-2a |
| 4 | vault-layout-v2 | §3.2 `catalog` skip — **W1 필수** 명시 |

---

## 8. Wave 1 권장 구현 순서 (검토 후)

```
W1-0  WorkIdCodec + EntityAnchor.isWork (P0-1)     ← 선행
W1-1  UserCatalogStore + catalog/ folder
W1-2  Fusion merge + dedupe rules (P0-5)
W1-3  ensureWorkId / add_work_dialog / FusionSearchDialog
W1-4  MarkdownParser · skip catalog dir
W1-5  tests: wk_u round-trip · search hit · no duplicate
W1-6  (선택) RegistryWorkAutocomplete merge
```

**W1 Exit 재정의:** P0 전부 green + policy §10 checklist.

---

## 9. 최종 판정

| 질문 | 답 |
|------|-----|
| Wave 0 설계 방향 맞나? | ✅ |
| 바로 코드 가능? | 🟡 P0 문서 패치 + W1-0 ID layer **선행** |
| 대개편 위험? | 낮음 — **ensureWorkId 버그**만 방치 시 중간 |
| Steam v1 영향? | W1은 v1.x — Sprint B와 **병행 가능** |

---

## 11. v2 — 코드 경로 검토 (추가)

### 11.1 「작품 추가」3갈래 (현재)

| 경로 | 진입 | ID | 저장 |
|------|------|-----|------|
| **A. Global 선택** | add_work_dialog autocomplete | `wk_*` | `.md` (vault) |
| **B. 직접 추가** | FusionSearch → onCustomAdd → add_work_dialog | `sub_*_custom_*` | vault `.md` or **in-memory** |
| **C. 글로벌 제안** | FusionSearch → onCatalogPropose | (없음) | app `catalog_contributions.json` |

Wave 1: **B → Tier 1.5 catalog + wk_u_*** · C **유지** · A **유지**.

[`home_dialogs_coordinator.dart`](../../lib/screens/home/coordinators/home_dialogs_coordinator.dart) · [`home_dialogs_facade.dart`](../../lib/screens/home/dialogs/home_dialogs_facade.dart)

### 11.2 볼트 없을 때 in-memory — policy와 충돌

현재 `showAddDialog`: vault 없으면 `onSavedInMemory(result)` — **세션 한정**.

Policy §4.3: Tier 1.5 **볼트 필수**.

**v2 결정:** Wave 1에서 custom add **볼트 필수** · in-memory custom **deprecated**.  
데모 `sample_data` 2작은 **기존 유지** (HomeVaultLoader).

### 11.3 Browse vs Search 표면

| | BrowsePipeline | FusionSearchDialog |
|--|----------------|-------------------|
| 데이터 | Tier 1 virtual + user `.md` | local + remote |
| catalog-only | ❌ **안 나옴** | Wave 1 **추가** |
| 이유 | 10k virtual grid 정책 | 「찾기」= 3-tier merge |

[`browse_pipeline.dart`](../../lib/services/browse_pipeline.dart) — UserCatalog **W1 범위外**.

### 11.4 `ensureWorkId` 호출 7곳 — W1-3 필수

| # | 파일 | 트리거 |
|---|------|--------|
| 1 | `markdown_parser.dart` | deserialize · ensureWorkId |
| 2 | `file_service.dart` | saveItem |
| 3 | `home_poster_card_factory.dart` | 카드 workId |
| 4 | `home_membership_coordinator.dart` | 서재 membership |
| 5 | `library_membership_apply.dart` | apply draft |
| 6 | `franchise_library_scope.dart` | franchise card id |
| 7 | `personal_library_view.dart` | curated card |

**단일 수정 insufficient** — `ensureWorkId` 내부 + 호출부 audit.

### 11.5 `ArchiveRecordMapper` · Timeline

`fromTimelineEntry`: `entityId.startsWith('wk_')` → work — **wk_u 포함** (OK).  
`sub_*` → custom type (OK). W1-0에서 `WorkIdCodec.isGlobalWorkId` 사용 권장.

### 11.6 `WorksRegistry.isLegacyWorkId`

```dart
!WorkIdCodec.isMasterFormat(workId) && workId.isNotEmpty
```

`wk_u_*`가 master가 되면 **legacy 아님** — naming 혼란.  
Wave 1: `isNonRegistryWorkId` alias 검토 · 사용처 grep.

### 11.7 `setContainsWorkId`

`wk_u_*`는 `_legacyAliases` **없음** — literal match only.  
user catalog id와 `.md` work_id **동일 문자열**이면 OK.

### 11.8 Auto-archive와 user catalog

`HomeAutoArchive` — Tier 1 registry만 대상. **user catalog 제외** (정상).

### 11.9 Port 설계

**RegistryPort 확장 ❌** — [wave1-user-catalog-spec.md](wave1-user-catalog-spec.md) §2.  
`UserCatalogPort` + adapter · HomeShellController wiring.

---

## 12. v2 — P0 패치 상태

| P0 | v1 | v2 |
|----|----|-----|
| P0-1 ID | ADR-011 §2.4.1 | + wave1 spec §5 |
| P0-2 Contribution | policy 현재/목표 | ✅ |
| P0-3 filename | user_entities.json | ✅ |
| P0-4 볼트 | policy §4.3 | + in-memory deprecated |
| P0-5 dedupe | policy §6.1 | + wave1 spec §8 |

---

## 13. v2 — 잔여 P1 (Wave 1~2)

| ID | 항목 | Wave |
|----|------|------|
| P1-8 | Browse grid에 catalog-only (optional) | W1.2+ |
| P1-9 | RegistryWorkAutocomplete merge | W1.1 |
| P1-10 | Demo mode custom add UX copy | W1 |
| P1-11 | `isLegacyWorkId` rename | W1 |
| P1-12 | Contribution vault co-location | W2+ |

---

## 14. v2 최종 판정

| 질문 | v1 | v2 |
|------|----|----|
| Wave 0 설계 | ✅ | ✅ |
| 바로 코드? | 🟡 | 🟢 **W1-0부터** |
| 문서 충분? | 🟡 | 🟢 wave1 spec |
| 리스크 | ensureWorkId | + 7 call sites · 3 UX paths |

---

## 15. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | 초판 — Wave 0 전면 검토 · P0~P2 · W1 순서 |
| 2026-06-19 | **v2** — 코드 경로 · Browse/Search · ensureWorkId 7 · wave1 spec · in-memory 정책 |
