# Wave 2 Pre-Implementation Review

> **일자:** 2026-06-19  
> **범위:** [wave2-vault-record-spec.md](wave2-vault-record-spec.md) · [vault-layout-v2.md](../product/vault-layout-v2.md)  
> **선행:** Wave 1 ✅ · [wave1-exit-review.md](wave1-exit-review.md)  
> **판정:** 🟡 **조건부 통과** — P0-W2-1~5 결정 확정 후 코드 Gate 🟢  
> **구현 SSOT:** [wave2-vault-record-spec.md](wave2-vault-record-spec.md)

---

## 1. Executive Summary

Wave 2는 **Work Record의 frontmatter v2 + ArchiveRecord round-trip** — Entity-centric 모델을 `.md`에 **명시**하는 단계다.  
기존 `{category}/` 경로·`work_id` **100% 유지** · lazy write만.

| 영역 | 등급 | 요약 |
|------|:----:|------|
| 목표·scope | 🟢 | Person/Event 제외 · breaking 없음 |
| Parser gap | 🟡 | entity_* 미구현 — P0 |
| Path resolver | 🟢 | default legacy · opt-in works/ |
| ArchiveRecord | 🟡 | timeline ✅ · work journal ❌ |
| Wave 1 연속 | 🟡 | R1 upsert 순서 → W2-5 |

---

## 2. 코드 Gap Inventory

### 2.1 `markdown_parser.dart`

| 기능 | 현재 | Wave 2 |
|------|------|--------|
| Read `entity_type` | ❌ | W2-1 |
| Read `entity_id` | ❌ (work_id only) | W2-1 |
| Read `subtype` | ❌ (category only) | W2-1 |
| Read `record_kind` | ❌ | W2-1 infer |
| Write `entity_*` lazy | ❌ | W2-2 |
| `wk_u_*` registry fusion | N/A (null) | user catalog path 유지 |

**리스크:** deserialize 시 `entity_id`≠`work_id` 불일치 파일 — **entity_id 우선** 규칙 필요 (§4.2).

### 2.2 `file_service.dart`

| 기능 | 현재 | Wave 2 |
|------|------|--------|
| save path | `{vault}/{category}/{title}.md` | resolver W2-3 |
| `works/` scan | ✅ (skip 아님) | include |
| `journal/` stub | ❌ | W2 `_ensureFolderStructure` |
| fingerprint | `.md` only · catalog skip | unchanged |

### 2.3 `archive_record_mapper.dart`

| 기능 | 현재 | Wave 2 |
|------|------|--------|
| `fromAkashaItem` | work Entity only | typeForEntityId |
| `fromTimelineEntry` | ✅ | unchanged |
| `fromWorkMarkdown` | ❌ | W2-4 신규 |

### 2.4 `vault_archive_record_adapter.dart`

| 기능 | 현재 | Wave 2 |
|------|------|--------|
| timeline save | ✅ | unchanged |
| workJournal via Port | ❌ throws — VaultPort.saveItem | **유지** W2 |
| list kinds filter | workJournal + freeformJournal via vault scan | unchanged |

**결정 D-W2-1:** Wave 2에서 workJournal을 ArchiveRecordPort로 **통합하지 않음** — mapper round-trip만. saveItem 경로 유지.

### 2.5 `EntityAnchorType` enum

| Type | enum | typeForEntityId |
|------|:----:|:---------------:|
| work | ✅ | ✅ |
| person/event/place | ❌ enum partial | pe_/ev_ → custom (Wave 4 전 OK) |

**결정 D-W2-2:** Wave 2는 **work frontmatter only** — non-work entity_id in work `.md` **금지** (validation warn only).

---

## 3. P0 — 결정표

| ID | 이슈 | 결정 | 상태 |
|----|------|------|:----:|
| P0-W2-1 | entity_id read | **W2-1 필수** · entity_id > work_id 우선 | ✅ |
| P0-W2-2 | wk_u_* registry null | UserCatalogPort join · WorksRegistry skip | ✅ |
| P0-W2-3 | works/ default | **default OFF** · Vault settings opt-in | ✅ |
| P0-W2-4 | pe_u_* in work md | Wave 2 **거부** · parse warn | ✅ |
| P0-W2-5 | AkashaItem.entity_type field | **❌ 추가 안 함** · infer only | ✅ |
| P0-W2-6 | work_id deprecated? | **❌** · permanent alias | ✅ |
| P0-W2-7 | R1 upsert order | **saveItem 성공 후 upsert** (W2-5) | ✅ |

---

## 4. EntityFrontmatter API (W2-0)

Wave 2 코드 **첫 PR** — pure Dart · no UI.

```dart
/// Parsed entity metadata from YAML frontmatter ([vault-layout-v2 §4]).
class EntityFrontmatter {
  final EntityAnchorType entityType;
  final String entityId;
  final MediaCategory? subtype;  // work only Wave 2
  final RecordKind recordKind;

  static EntityFrontmatter inferFromYaml(Map yamlMap, {required MediaCategory categoryFallback});
  Map<String, dynamic> toLazyWriteFields({required bool mirrorWorkId});
}
```

### 4.1 Infer 우선순위 (Read)

1. `entity_type` + `entity_id` explicit  
2. `entity_id` only → type = typeForEntityId  
3. `work_id` only → type=work, id=work_id  
4. empty → work + ensureWorkId on save (deserialize defer)

### 4.2 Conflict 규칙

| conflict | rule |
|----------|------|
| `entity_id` ≠ `work_id` (both set) | **entity_id wins** · log warn · mirror work_id on lazy save |
| `subtype` ≠ `category` | **subtype wins** · category legacy sync on write |
| `entity_type` ≠ work but id is wk_* | **warn** · treat as work |

### 4.3 Lazy write (Serialize)

항상 출력: `work_id`, `category`, `added_at`, … (기존)  
추가 출력 (Wave 2+): `entity_type`, `entity_id`, `subtype` (=category.name)  
Optional: `record_kind: workJournal`

---

## 5. UserPreferences (W2-3)

| Key | Type | Default |
|-----|------|---------|
| `vault_use_works_layout` | bool | `false` |

Vault settings dialog — advanced section · Wave 2 optional UI.

---

## 6. 테스트 전략

| Layer | 파일 |
|-------|------|
| Unit | `test/entity_frontmatter_test.dart` (신규) |
| Unit | `test/markdown_parser_v2_test.dart` (신규) |
| Fixture | `test/fixtures/vault_v1_legacy.md`, `vault_v2_work.md` |
| Regression | 전체 `flutter test` · Wave 1 suite unchanged |

---

## 7. Wave 2 **하지 않음** (재확인)

- Person/Event catalog · Concept Entity UI
- `MediaCategory` rename
- Bulk migration tool
- ArchiveRecordPort for workJournal save
- `EntityAnchorType.place` enum (Wave 4)

---

## 8. Gate → 코드

| # | 조건 | 상태 |
|---|------|:----:|
| G1 | 본 review P0 전부 ✅ | ✅ |
| G2 | wave1-dogfood 1회 또는 friction logged | ⏳ |
| G3 | EntityFrontmatter API §4 팀 합의 | ✅ |
| G4 | Test fixtures §6 작성 | ⏳ (코드와 동시) |

**Gate 🟢 시:** W2-0 (`EntityFrontmatter`) 부터 순차 구현.

---

## 9. 구현 PR 분할 (권고)

| PR | Scope | Exit |
|----|-------|------|
| PR-1 | W2-0 EntityFrontmatter + tests | infer round-trip |
| PR-2 | W2-1/W2-2 MarkdownParser v2 | T1~T3 |
| PR-3 | W2-3 path resolver + prefs | T4~T5 |
| PR-4 | W2-4 ArchiveRecordMapper | T6 |
| PR-5 | W2-5 upsert-after-save + dogfood | R1 fix |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 2 pre-implementation review · P0 · EntityFrontmatter API |
