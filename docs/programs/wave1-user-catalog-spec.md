# Wave 1 — Tier 1.5 User Local Catalog 구현 스펙

> **상태:** 검토 v2 확정 · 코드 착수 Gate  
> **갱신:** 2026-06-19  
> **상위:** [entity-centric-evolution-plan.md](entity-centric-evolution-plan.md) · [user-local-catalog-policy.md](../policy/user-local-catalog-policy.md) · [entity-centric-wave0-review.md](entity-centric-wave0-review.md)

---

## 1. 목표

사전( Tier 1 )에 없는 Work를 **`wk_u_*` Fact**로 등록하고, **Fusion search**에서 즉시 찾을 수 있게 한다.  
감상·포스터는 Tier 2 `.md` — **선택**.

---

## 2. 아키텍처 (ADR-007)

```
Presentation     FusionSearchDialog · add_work_dialog
       ↓
Application      HomeDialogsCoordinator · FusionSearchService (신규)
       ↓
Domain           UserCatalogEntity · WorkIdCodec
       ↓
Data             UserCatalogPort (신규) → UserCatalogStoreAdapter
                   vault/catalog/user_entities.json
```

**RegistryPort 확장 ❌** — Tier 1 global과 **별 Port**.  
BrowsePipeline은 Wave 1 **필수 변경 아님** (§6).

---

## 3. Domain — `UserCatalogEntity`

```dart
class UserCatalogEntity {
  final String entityId;       // wk_u_xxxxxxxx
  final EntityAnchorType entityType;  // Wave 1: work only
  final MediaCategory subtype;
  final String title;
  final WorkTitles titles;
  final String creator;
  final int? releaseYear;
  final AppDomain domain;
  final List<String> aliases;
  final DateTime addedAt;
}
```

| 메서드 | 역할 |
|--------|------|
| `toRegistryWork()` | Fusion UI · RegistryWorkAutocomplete adapter |
| `toAkashaItemSkeleton()` | 워크벤치 열기 (rating 0 · filePath null) |

**금지 필드:** `posterPath`, `description` (Tier 1.5 policy).

---

## 4. Data — `UserCatalogPort`

```dart
abstract class UserCatalogPort {
  Future<void> load();
  List<UserCatalogEntity> get all;
  List<UserCatalogEntity> search(String query, {MediaCategory? subtype});
  UserCatalogEntity? getById(String entityId);
  Future<void> upsert(UserCatalogEntity entity);
  Future<void> remove(String entityId);
  Stream<void> get onChanged;
}
```

**저장:** `{vault}/catalog/user_entities.json` v1 ([policy §4.1](../policy/user-local-catalog-policy.md))

**볼트 없음:** Port no-op · `all` empty · coordinator에서 vault 필수 안내.

---

## 5. WorkIdCodec (W1-0 — 선행)

| API | 정규식 / 규칙 |
|-----|----------------|
| `isGlobalWorkId(id)` | `^wk_\d{9}$` |
| `isUserLocalWorkId(id)` | `^wk_u_[a-z0-9]{8}$` |
| `isLegacyMasterId(id)` | `sub_*` / `gen_*` master patterns |
| `isMasterFormat(id)` | global ∨ user local ∨ legacy |
| `buildUserLocal()` | `wk_u_` + 8 char base32 (crypto Random) |
| `buildCustom()` | **@Deprecated** → 내부 `buildUserLocal` 위임 금지 · 호출부 교체 |

### `EntityAnchor` (W1-0)

```dart
bool get isGlobalWork =>
  type == EntityAnchorType.work && WorkIdCodec.isGlobalWorkId(entityId);

bool get isUserLocalWork =>
  type == EntityAnchorType.work && WorkIdCodec.isUserLocalWorkId(entityId);

bool get isWork => isGlobalWork || isUserLocalWork || isLegacyMasterId(entityId);
```

`startsWith('wk_')` **삭제**.

### `ensureWorkId` — 호출부 전부 (W1-3)

| 파일 | 위험 |
|------|------|
| `markdown_parser.dart` | buildCustom 재발급 |
| `file_service.dart` | save 시 덮어쓰기 |
| `home_poster_card_factory.dart` | 카드 ID |
| `home_membership_coordinator.dart` | 서재 담기 |
| `library_membership_apply.dart` | membership |
| `franchise_library_scope.dart` | franchise scope |
| `personal_library_view.dart` | curated reorder |

**규칙:** `isMasterFormat(resolved)` true면 **절대 변경하지 않음**.  
빈 workId + title → **user catalog upsert 후** `wk_u_*` (global title match는 **user local 생성 전** 기존과 동일).

---

## 6. UI 표면 — Search vs Browse

| 표면 | Wave 1 | catalog-only (`.md` 없음) |
|------|:------:|----------------------------|
| **FusionSearchDialog** | ✅ merge | ✅ 「내 catalog」badge · Fact row |
| **RegistryWorkAutocomplete** | 🔶 W1.1 | optional merge |
| **BrowsePipeline 그리드** | ❌ 변경 없음 | ❌ **표시 안 함** (virtual card = Tier 1 only) |
| **MyLibraryPipeline** | ❌ | ❌ (archived only — 정상) |

**이유:** Browse 그리드 = Tier 1 virtual + archived user. catalog-only는 **검색·직접 추가** 경로.

---

## 7. UX 흐름 (코드 연결)

현재 [`home_dialogs_coordinator.dart`](../../lib/screens/home/coordinators/home_dialogs_coordinator.dart):

```
onCustomAdd → showAddDialog → vault? saveItem : addItemInMemory
onCatalogPropose → contribution queue (app documents)
```

**Wave 1 목표:**

```
onCustomAdd
  → vault 없음: SnackBar 「볼트 연결 후 등록」 (policy §4.3)
  → vault 있음: showAddDialog
       → registry hit: global wk_ (기존)
       → miss: UserCatalogPort.upsert(wk_u_*) 
       → (선택) saveItem → Tier 2 .md
```

**데모 모드 (볼트 없음):** `sample_data` 2작 **유지** · 신규 custom add **차단** (in-memory addItemInMemory **deprecated** for custom works).

**onCatalogPropose:** 변경 없음 — Contribution ≠ Tier 1.5.

---

## 8. FusionSearchService (W1-2)

```dart
class FusionSearchService {
  FusionSearchResult search({
    required String query,
    required List<AkashaItem> localItems,
    required UserCatalogPort userCatalog,
    required RegistryPort registry,
  });
}
```

### Merge 알고리즘 ([policy §6.1](../policy/user-local-catalog-policy.md))

1. **Local tier:** `localItems` title/creator/tags match → `AkashaItem` rows  
2. **User catalog tier:** exclude entityIds in localItems.workIds → `toRegistryWork()` rows  
3. **Global tier:** `registry.searchAsync` exclude `localWorkIds ∪ userCatalogIds`  
4. **Dedupe:** same `entityId` → keep **richest** (has filePath > catalog > global)

### Franchise

- User local `wk_u_*` — **FranchiseRegistry 미등록** → franchise dedupe **skip** (단일 row)

---

## 9. AkashaFileService (W1-4)

```dart
_skipDirNames += 'catalog', 'journal', 'entities';  // vault-layout v2 forward-compat
_ensureFolderStructure → Directory(vault/catalog)
```

---

## 10. 테스트 (W1-5)

| ID | 케이스 |
|----|--------|
| T1 | `buildUserLocal()` unique · pattern match |
| T2 | `isMasterFormat(wk_u_*)` true · `isWkFormat` false |
| T3 | `ensureWorkId` preserves wk_u · legacy sub_* |
| T4 | UserCatalogStore round-trip JSON |
| T5 | FusionSearch: catalog-only hit |
| T6 | FusionSearch: catalog + md same id → single local row |
| T7 | FusionSearch: global excluded when wk_u in catalog |
| T8 | `EntityAnchor.isWork` — wk_u vs pe_u (future) |

**기존 테스트 수정:**

- `vault_archive_test`: custom id → `wk_u_*` (또는 legacy 유지 case 분리)
- `work_id_codec_test`: `buildCustom` → `buildUserLocal` 병행

---

## 11. Wave 1 Exit

- [ ] P0-1 ~ P0-5 ([review §3](entity-centric-wave0-review.md))
- [ ] policy §10 checklist
- [ ] `flutter test` green
- [ ] dogfood: 볼트 연결 → 직접 추가 → 검색 hit → (선택) archive

---

## 12. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 1 구현 스펙 (review v2 산출) |
