# R2-D Step 1 — Entity Rename · Wiki Label Drift 조사

> **상태:** 조사 완료 (구현 없음)  
> **날짜:** 2026-06-19  
> **상위:** [link-identity-policy.md](../policy/link-identity-policy.md) · [ADR-013](../adr/ADR-013-connection-link-index.md)

---

## 1. 조사 목표

Entity **title rename** 이후 vault에 남는 canonical wiki token `[[entityId|Title]]` 의 **label drift** 를 코드 경로·레이어·인덱스·정책 관점에서 분석한다.

**본 문서는 설계·조사만.** 코드 변경 없음.

---

## 2. Executive Summary

| 항목 | 현재 상태 |
|------|----------|
| **Identity SSOT** | `entityId` (변경 없음) |
| **Title SSOT (archived entity)** | entity journal `.md` frontmatter `title` → catalog mirror |
| **Wiki label SSOT** | **각 Record `.md` 본문 원문** (rename과 **비동기**) |
| **Production rename UI** | **없음** — Entity Sheet는 body만 저장 |
| **rename 후 label 갱신** | **미구현** (정책 §3.1은 “label만 갱신 가능”을 **허용**만 명시) |
| **explicitId 링크 navigate/incoming** | entityId 기준 → **rename과 무관하게 동작** |
| **Preview 표시** | vault **label(OldTitle)** 그대로 — catalog NewTitle **미반영** |

**Drift 예시**

```
Entity.title:  나츠키 스바루  →  스바루
Vault 링크:    [[pe_u_natsuki1|나츠키 스바루]]   (변경 없음)
Preview:       「나츠키 스바루」(stale)
Navigate tap:  성공 → Entity Sheet 헤더는 「스바루」(catalog)
```

---

## 3. Entity Title 변경 경로

### 3.1 Entity Sheet `_save()` (production)

**파일:** `lib/screens/home/dialogs/entity_journal_dialog.dart`

| 분기 | 호출 | title 전달 |
|------|------|-----------|
| 생성 (`_creating`) | `EntityVaultStore.saveCatalogEntity` | `widget.entity.title` |
| 수정 (journal 존재) | `EntityVaultStore.updateEntry` | **`_current!.title` (기존 entry title 고정)** |

```145:167:lib/screens/home/dialogs/entity_journal_dialog.dart
  Future<void> _save() async {
    // ...
      } else {
        _current = await _store.updateEntry(
          entry: _current!,
          body: body,
          title: _current!.title,
        );
      }
```

- UI는 `widget.entity.title`을 **읽기 전용**으로 표시; **title 편집 필드 없음**.
- 저장 후 `EntityArchiveService.syncCatalogFromJournal(draft: widget.entity, entry: _current!)` 호출.
- **다른 Record의 wiki link 본문은 건드리지 않음.**

### 3.2 `EntityVaultStore.updateEntry`

**파일:** `lib/services/entity_vault_store.dart`

| 필드 | rename 시 동작 |
|------|----------------|
| `title` | frontmatter `title:` 갱신 (`resolvedTitle = title ?? entry.title`) |
| `entityId` | **불변** |
| `storagePath` / 파일명 | **불변** — in-place overwrite |
| `body` | 새 본문 |
| side effect | `signalVaultChanged()` → debounced link index rebuild |

**Filename drift:** `saveCatalogEntity`는 `{entities/{type}/{safeTitle}.md}` 로 생성하지만, `updateEntry`는 **파일 rename 없음**. title만 바꾸면 `나츠키 스바루.md` 안의 frontmatter title은 `스바루`일 수 있음 (R2-C path guard와 별 이슈).

**Call site:** production에서는 Entity Sheet `_save()`만. programmatic rename은 테스트에서만 검증.

### 3.3 `EntityArchiveService.syncCatalogFromJournal`

**파일:** `lib/services/entity_archive_service.dart` → `EntityCatalogSync.mirrorFromJournal`

| catalog 필드 | 소스 |
|-------------|------|
| `entityId` | `entry.entityId` (journal SSOT) |
| `title` | **`entry.title`** (journal frontmatter) |
| `aliases`, `subtype`, … | **`draft`** (`widget.entity` — 기존 catalog 메타 유지) |

→ catalog JSON `title`만 journal과 align. **wiki label 전파 없음.**

### 3.4 테스트로 확인된 rename 경로 (UI 외)

**파일:** `test/archive_first_r1_test.dart` — `Person create then title update keeps .md and catalog aligned`

```
saveFromAddResult → updateEntry(title: '나츠키 스바루 (改)') → syncCatalogFromJournal
```

검증: `.md` frontmatter title = catalog title. **wiki link label은 범위 밖.**

### 3.5 Gap 요약

1. **UI gap:** 앱 내 Entity title rename flow **사실상 없음**.
2. **Filename gap:** frontmatter title ≠ 파일명 가능.
3. **Label gap:** rename 시 vault-wide `[[entityId|…]]` rewrite **없음**.

---

## 4. Rename 이후 `[[entityId|OldTitle]]` 상태

### 4.1 무엇이 갱신되는가

| 저장소 | entityId | title / label |
|--------|----------|---------------|
| entity journal `.md` | 불변 | frontmatter title만 (rename API 사용 시) |
| `vault/catalog/entities.json` | 불변 | title mirror |
| Work / timeline / journal `.md` 본문 | 불변 | **`[[entityId|OldTitle]]` 원문 유지** |
| `link_index.json` incoming key | explicitId → **entityId** | label 필드는 outgoing 메타; incoming key **불변** |

### 4.2 사용자가 보는 불일치

| 화면 | 표시 |
|------|------|
| Work Preview (wiki link) | **OldTitle** (vault label) |
| Work 본문 탭 (raw `.md`) | `[[entityId|OldTitle]]` |
| Entity Sheet 헤더 | **NewTitle** (catalog / `widget.entity`) |
| Incoming links 목록 | source **파일 basename** (wiki label 미사용) |

---

## 5. RecordLink 레이어별 동작

시나리오: vault `[[pe_u_natsuki1|나츠키 스바루]]`, catalog `Entity.title = 스바루`

### 5.1 `RecordLinkParser`

**파일:** `lib/services/record_link_parser.dart`

- 순수 문자열 파싱 — **catalog 조회 없음**.
- `explicitId` + `displayLabel: "나츠키 스바루"`.
- rename과 **무관**; vault 원문이 SSOT.

### 5.2 `RecordLinkMarkdown`

**파일:** `lib/services/record_link_markdown.dart`

**Preview (`preprocessForDisplay`):**

```dart
display = label != null && label.isNotEmpty ? label : primary;
// → [나츠키 스바루](akasha-wiki:?id=pe_u_natsuki1&label=나츠키 스바루)
```

- pipe label이 있으면 **catalog title로 덮어쓰지 않음**.
- rename 후 Preview는 **OldTitle** 유지.

**Tap round-trip:** href의 `id` + `label` → synthetic `[[id|label]]` 재구성. label은 navigator까지 전달되나 **navigate에서 미사용**.

### 5.3 `RecordLinkNavigator`

**파일:** `lib/services/record_link_navigator.dart`

| kind | navigate | label 사용 |
|------|----------|-----------|
| `explicitId` | `_openEntityId(targetEntityId)` | **없음** |
| `titleOnly` | `resolveTitleToEntityId(title)` | title 문자열만 |

`[[entityId|OldTitle]]` + catalog NewTitle:

- **탐색 성공** (entityId 유효 시).
- Entity Sheet는 **catalog NewTitle** 표시.
- label ≠ title **경고·검증 없음**.

**titleOnly** `[[나츠키 스바루]]`는 rename 후 alias에 old title이 없으면 navigate **실패** + incoming index **skip** (rebuild 시).

### 5.4 레이어 요약표

| 레이어 | OldTitle vs NewTitle | entityId |
|--------|------------------------|----------|
| Parser | label = vault 원문 | parse만 |
| Markdown preview | **OldTitle 표시** | href `id=` |
| Navigator | **무시** | **SSOT — open 성공** |
| Link index incoming | label 무관 | **entityId key — 유효** |
| Authoring insert | pick 시점 title 스냅샷 | `EntityLinkSelection.canonicalWikiToken` |

---

## 6. Work 저장 파일 스캔 비용

### 6.1 Link index 구조

**파일:** `lib/services/record_link_index_service.dart`  
**저장:** `{vault}/.akasha/link_index.json`

| 맵 | key | value |
|----|-----|-------|
| `outgoing` | source record path | `List<RecordLink>` |
| `incoming` | **entityId** | `List<source path>` |

**Port API:** `incomingRecordPaths(entityId)` — entityId 역참조 **1-hop**.

### 6.2 Full vault scan 필요 여부

| 목적 | full scan? |
|------|-----------|
| index **최초/전체 rebuild** | **항상 예** — `_scanRecordFiles` 재귀 `*.md` |
| `incomingRecordPaths(entityId)` **조회** | **아니오** — 메모리 `_incoming` O(1) |
| explicitId `[[entityId|…]]` **참조 파일 찾기** | **아니오** (index 최신 시) — incoming 재사용 |
| titleOnly `[[OldTitle]]` 참조 찾기 | **조건부** — rebuild 시 catalog resolve; rename 후 stale 가능 |
| label **rewrite 대상 수집** (explicitId) | **incoming으로 충분** (index 최신 전제) |

**Rebuild 트리거:** vault connect, watch debounce(800ms), index 없음/버전 불일치.  
`changedPath`는 stats 메타만 — **incremental rebuild 미구현** (ADR-013 MVP).

**스캔 제외:** `.akasha`, `catalog`, `posters`, dot-dir 등.

### 6.3 비용 모델 (정성)

```
full rebuild ≈ N_md × (read + parse wiki regex)
             + titleOnly_links × O(catalog entities)   // resolveTitleToEntityId
             + JSON write

targeted rewrite (explicitId) ≈ |incoming[entityId]| × (read + parse + patch write)
```

개인 vault 규모에서는 full rebuild가 debounce 1회로 수용 가능 (ADR-013).  
rename rewrite는 **incoming 파일 수에 비례** — full vault 대비 작음.

### 6.4 Index 재사용 (rename 시)

| 시나리오 | index 내용 stale? | rebuild 필요? |
|----------|-------------------|---------------|
| explicitId, **label만** 변경 | incoming key 불변 | **불필요** (선택적) |
| catalog title 변경 + **titleOnly** 링크 존재 | incoming resolve 변경 | **필요** |
| rewrite 후 save | — | `signalVaultChanged` → 기존 debounced rebuild |

**갭:** index `RecordLink`에 **body offset 없음** — rewrite는 파일별 **재파싱** 필수 (`ParsedRecordLink.startOffset`은 parse 시에만 존재).

---

## 7. 자동 Rewrite 가능성

### 7.1 예시

```
[[pe_u_natsuki1|나츠키 스바루]]  →  [[pe_u_natsuki1|스바루]]
```

### 7.2 기술적 실현성: **가능 (explicitId canonical)**

| 단계 | 재사용 컴포넌트 |
|------|----------------|
| 1. 대상 파일 목록 | `RecordLinkPort.incomingRecordPaths(entityId)` |
| 2. 링크 위치·종류 | `RecordLinkParser.parseFromRecordContent` + `startOffset` |
| 3. 필터 | `kind == explicitId && targetEntityId == entityId` |
| 4. 새 토큰 | `EntityLinkSelection(entityId, newTitle, …).canonicalWikiToken` |
| 5. patch | offset 기반 replace 또는 scoped regex |
| 6. 후처리 | save → `signalVaultChanged` → debounced `rebuildIndex()` |

### 7.3 한계·리스크

| 항목 | 내용 |
|------|------|
| **titleOnly** | incoming만으로 **누락** — `[[나츠키 스바루]]`는 별도 전략 (alias / full scan) |
| **의도적 old label** | rewrite 시 **저작자 의도** 소실 (별칭·초기 표기 등) |
| **동일 파일 다중 링크** | 같은 entityId 링크 여러 개 → 전부 치환 여부 결정 필요 |
| **Work + Entity 혼재** | work id `[[wk_u_…\|Title]]`도 동일 패턴 — entity rename 범위와 분리 |
| **Undo / audit** | vault-wide mutation — ledger·사용자 확인 UX 필요 |
| **Partial failure** | N개 파일 중 일부 patch 실패 시 rollback 정책 |
| **Filename drift** | label rewrite와 **entity 파일 rename**은 별 작업 (R2-C 연계) |

### 7.4 Rewrite 없이도 “동작”하는 것

- explicitId **navigation** · **incoming index** · **identity** — label stale이어도 **기능적 성공**.

---

## 8. 정책 결정안

### A. Label 영구 보존 (Vault SSOT = 삽입 시점 스냅샷)

**내용:** rename해도 `[[entityId|OldTitle]]` **변경하지 않음**. Preview·본문 모두 vault 원문 유지.

| 장점 | 단점 |
|------|------|
| 타 Record **무수정** — 안전·Obsidian 호환 | Preview·본문에 **stale name** |
| 링크 삽입 시점 표기·의도 보존 | Entity Sheet(NewTitle)와 **표시 불일치** |
| rewrite·rollback·감사 부담 없음 | titleOnly fallback은 rename에 **취약** (별도 alias 정책 필요) |
| index/navigation 이미 entityId 기준으로 동작 | 사용자 “이름 바꿨는데 왜 링크는 옛날 이름?” 혼란 |

**적합:** wiki label을 “당시 쓰인 이름”으로 보는 모델; vault를 immutable log에 가깝게 유지.

---

### B. Rename 시 자동 Rewrite (Catalog/Journal title → vault label 동기화)

**내용:** Entity title rename 확정 시 `incoming[entityId]` 파일을 순회, explicitId canonical token label을 **NewTitle로 일괄 갱신**.

| 장점 | 단점 |
|------|------|
| Preview·vault·catalog **표시 일치** | **다른 Record 본문 mutation** — 파급 큼 |
| canonical form `[link-identity-policy §3.1]`과 정합 | 의도적 old label·인용 표기 **소실** |
| incoming 기반 **targeted scan** — full vault 불필요 | titleOnly·legacy 링크 **별도 처리** 필요 |
| picker token과 동일 규칙 재사용 가능 | UX: 확인 dialog·undo·실패 처리 필수 |
| | rename UI 없는 현재는 **선행 작업** 필요 |

**적합:** AKASHA를 “현재 공식 title” 중심 제품으로 통일; R2-B canonical authoring 확산 후.

**구현 시 권장 범위 (설계):**

1. **Phase 1:** explicitId `[[entityId|…]]` only, incoming-driven.
2. **Phase 2:** titleOnly — old title을 `aliases`에 넣거나 optional full scan.
3. rename UI + optional “N개 링크 label 갱신” 확인.

---

### C. Preview만 최신 Title 표시 (Vault 불변 · Display override)

**내용:** vault 원문은 OldTitle 유지; `RecordLinkMarkdown.preprocessForDisplay` (또는 preview layer)에서 explicitId일 때 **catalog/journal title로 display override**.

| 장점 | 단점 |
|------|------|
| vault **무수정** | **Preview vs 본문 탭 vs export** 불일치 |
| 사용자-facing 읽기 경험 개선 | raw `.md` / Git diff / Obsidian sync는 **여전히 OldTitle** |
| rewrite 리스크 없음 | “편집하면 old label 그대로 저장” — 혼란 지속 |
| navigate는 이미 entityId — 변경 최소 | titleOnly preview override는 **resolve 충돌** (동명) |

**적합:** 단기 완화책; **장기 SSOT**로는 preview·storage 이원화 부담.

---

## 9. 비교 요약

| 기준 | A 보존 | B rewrite | C preview override |
|------|:------:|:---------:|:------------------:|
| vault mutation | 없음 | **있음** | 없음 |
| Preview = NewTitle | ❌ | ✅ | ✅ |
| 본문 탭 = NewTitle | ❌ | ✅ | ❌ |
| navigate (explicitId) | ✅ | ✅ | ✅ |
| titleOnly rename 내성 | ❌ | △ (별도) | △ |
| 구현 복잡도 | 낮음 | **높음** | 중간 |
| Obsidian/외부 호환 | 높음 | 중간 | 높음 (storage) |

---

## 10. 조사 결론 · R2-D 후속 제안

### 10.1 현재 baseline

- **Identity drift 없음** (`entityId` SSOT).
- **Label drift 있음** — rename API·UI·rewrite 모두 production 미연결.
- [link-identity-policy.md §3.1](../policy/link-identity-policy.md): *“rename 시 label만 갱신 가능 (id 유지)”* — **허용 문구만 있고 파이프라인 없음**.

### 10.2 Step 2+ 설계 입력 (구현 아님)

| 우선순위 | 항목 |
|----------|------|
| P0 | **Entity title rename UI** 정의 (Sheet? catalog edit?) — 없으면 B/C 모두 dead code |
| P0 | 정책 **A / B / C** Product 결정 |
| P1 | B 선택 시: incoming + parser offset rewrite spike |
| P1 | C 선택 시: preview resolve API (`entityId → catalog.title`) |
| P2 | titleOnly rename: `aliases` 자동 추가 vs rewrite vs ignore |
| P2 | entity **파일 rename** (frontmatter title ↔ filename) — R2-C와 통합 검토 |

### 10.3 권장 방향 (조사 의견)

- **단기:** A 유지 + rename UI 도입 전까지 drift **문서화·known limitation**.
- **중기 (R2-B canonical 확산 후):** **B (opt-in rewrite)** — rename 확인 시 “N건 wiki label 갱신” 체크박스. default off 또는 preview diff 후 confirm.
- **C**는 B 미적용 파일에 대한 **보조 preview layer**로만 고려 (storage SSOT 이원화 최소화).

---

## 11. 관련 코드·테스트

| 파일 | 역할 |
|------|------|
| `lib/screens/home/dialogs/entity_journal_dialog.dart` | Sheet save · incoming load |
| `lib/services/entity_vault_store.dart` | `saveCatalogEntity` · `updateEntry` |
| `lib/services/entity_archive_service.dart` | `syncCatalogFromJournal` |
| `lib/services/entity_catalog_sync.dart` | catalog mirror |
| `lib/services/record_link_parser.dart` | wiki grammar |
| `lib/services/record_link_markdown.dart` | preview preprocess |
| `lib/services/record_link_navigator.dart` | tap navigate · title resolve |
| `lib/services/record_link_index_service.dart` | scan · incoming/outgoing |
| `lib/services/record_link_stale_label.dart` | R2-D Step 2 · stale count |
| `lib/models/entity_link_selection.dart` | `canonicalWikiToken` |
| `test/archive_first_r1_test.dart` | title update → `.md` + catalog |
| `test/r2b_entity_link_pipeline_test.dart` | insert → save → index E2E |
| `test/record_link_stale_label_test.dart` | stale count · index-only |

**없는 테스트:** rename dialog Option B · vault rewrite · preview override.

---

## 12. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — R2-D Step 1 조사·정책 결정안 |
| 2026-06-19 | v1.1 — Step 2 stale label · [r2d-step2-stale-label-visibility.md](r2d-step2-stale-label-visibility.md) |
