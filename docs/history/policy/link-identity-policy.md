# Link Identity Policy — R2-B (Authoring SSOT)

> **상태:** **확정 (Locked)** — R2-B Step 0  
> **날짜:** 2026-06-19  
> **상위:** [ADR-013](../adr/ADR-013-connection-link-index.md) · [user-local-catalog-policy.md](user-local-catalog-policy.md) · [wave5-connection-spec.md](../programs/wave5-connection-spec.md)

---

## 1. 한 줄

**Entity 연결의 identity SSOT는 `entityId`이다.**  
Work body에 **저장**할 때 picker가 id를 알면 **`[[entityId|Title]]`** 을 canonical로 쓰고, **`[[Title]]`** 은 수동·Obsidian 호환 fallback이다.

---

## 2. Identity vs Storage vs Display

| 계층 | SSOT | 비고 |
|------|------|------|
| **Entity 존재** | `.md` frontmatter `entity_id` | Archive-First |
| **연결 대상 (identity)** | `entityId` | catalog merge key · ADR-011 |
| **Vault 저장 (authoring canonical)** | `[[entityId\|Title]]` | R2-B picker 출력 |
| **Vault 저장 (fallback)** | `[[Title]]` | 수동 · 외부 import · best-effort resolve |
| **Preview 표시** | **Title (label)만** | entityId raw 노출 금지 (canonical form 전제) |
| **Link index** | 파생 · `link_index.json` | explicitId 직접 · title resolve (R2-A) |

---

## 3. 저장 문법

### 3.1 Canonical (Authoring tool — Entity picker)

```
[[pe_u_natsuki1|나츠키 스바루]]
[[wk_u_rezero01|Re:Zero]]
```

| 규칙 | 내용 |
|------|------|
| 형식 | `[[entityId\|Title]]` — pipe **필수** (label = catalog/journal title at pick time) |
| primary | `EntityIdCodec.isMasterFormat` 또는 legacy work id → **explicitId** |
| label | 사용자에게 보이는 Title · rename 시 label만 갱신 가능 (id 유지) |

### 3.2 Fallback (수동 · Obsidian · legacy)

```
[[나츠키 스바루]]
[[Tiger]]
```

| 규칙 | 내용 |
|------|------|
| 형식 | `[[Title]]` — primary가 master id 형식이 **아닐 때** titleOnly |
| resolve | navigate · index rebuild 시 `resolveTitleToEntityId` (best effort) |
| 위험 | 동명 cross-type · Work/Entity 충돌 · first-match (Design Review 참고) |

### 3.3 지원하되 Authoring 비권장

```
[[pe_u_natsuki1]]
```

- explicitId이나 **label 없음** → preview에서 id가 그대로 노출될 수 있음  
- picker·authoring 경로에서는 **사용 금지** (canonical은 항상 pipe + Title)

### 3.4 Obsidian alias 형태 (비-id primary)

```
[[Tiger|호랑이]]
```

- primary `Tiger`가 id 형식이 아니면 **titleOnly** (`targetTitle=Tiger`, `displayLabel=호랑이`)  
- AKASHA canonical과 **다른 의미** — fallback으로만 허용

---

## 4. Resolve 우선순위

### 4.1 Navigate (`RecordLinkNavigator.navigateLink`)

```
1. explicitId  → _openEntityId(targetEntityId)  — catalog title resolve 생략
2. titleOnly   → resolveTitleToEntityId(title) → _openEntityId(resolved)
3. unresolved  → SnackBar
```

### 4.2 Title fallback resolve (`resolveTitleToEntityId`)

순서 (exact match, case-insensitive):

1. `userCatalog.all` — entity.title
2. `userCatalog.all` — entity.aliases (entity 순서 = JSON 배열 순)
3. `vaultItems` — work title → workId

**주의:** 동명 시 **first match** · type 구분 없음.

### 4.3 Incoming index (`RecordLinkIndexService.rebuildIndex`)

| link kind | incoming key |
|-----------|--------------|
| explicitId | `targetEntityId` 직접 |
| titleOnly | `resolveTitleToEntityId(...)` 결과 (null이면 incoming skip) |

explicitId **우선** — id가 vault에 있으면 title resolve 불필요.

---

## 5. Preview 렌더 (`RecordLinkMarkdown`)

| vault 원문 | preprocess 출력 (표시 텍스트) | href |
|------------|------------------------------|------|
| `[[pe_u_xxx\|나츠키 스바루]]` | `[나츠키 스바루](akasha-wiki:…)` | `id=pe_u_xxx&label=나츠키 스바루` |
| `[[나츠키 스바루]]` | `[나츠키 스바루](akasha-wiki:…)` | `id=나츠키 스바루` (titleOnly) |
| `[[pe_u_xxx]]` | `[pe_u_xxx](akasha-wiki:…)` ⚠️ | id만 — **authoring 비권장** |

Preview UI는 markdown link **텍스트 노드만** 렌더 — entityId는 href query에만 존재 (사용자에게 링크 글자로 id 미노출, canonical form 전제).

---

## 6. R2-B 구현 범위 (Step 0 이후)

| 항목 | Step 0 | R2-B 구현 시 |
|------|:------:|:------------:|
| Parser grammar | ✅ 기존 코드 충족 | 변경 없음 |
| Preview label-only | ✅ canonical form 충족 | `[[id]]` without label — picker가 pipe 강제 |
| Index explicit + title | ✅ R2-A | 변경 없음 |
| Navigate priority | ✅ | 변경 없음 |
| Entity picker | ✅ Step 1 | `EntityLinkPickerDialog` |
| `MarkdownEditActions.insertWikiLink` | ✅ Step 2 | `TextEditPatch` |
| Toolbar 「Entity 연결」 | ✅ Step 3 | Sanctum 본문 탭 |
| Sanctum `_applyPatch` wiring | ✅ Step 3 | `handleRequestEntityLink` |
| save → index → incoming E2E | ✅ Step 4 | `test/r2b_entity_link_pipeline_test.dart` |

---

## 6.1 Authoring Pipeline (R2-B)

```
EntityLinkPickerDialog
    → EntityLinkSelection (entityId, title, entityType)
    → MarkdownEditActions.insertWikiLink(text, selection, entityId, title)
    → TextEditPatch.text contains [[entityId|Title]]
    → MarkdownBodyEditor._applyPatch (Step 3)
    → vault .md save
    → RecordLinkIndexService.rebuildIndex
```

| 단계 | Step | 상태 |
|------|------|------|
| Picker | 1 | ✅ |
| `insertWikiLink` | 2 | ✅ |
| Editor toolbar + undo | 3 | ✅ |
| save → index → incoming | 4 | ✅ E2E test |

---

## 7. 관련 코드 (현재 — Step 0 baseline)

| 파일 | 역할 |
|------|------|
| `lib/services/record_link_parser.dart` | grammar · explicitId vs titleOnly |
| `lib/services/record_link_markdown.dart` | preview preprocess · tap round-trip |
| `lib/services/record_link_navigator.dart` | navigate · title resolve |
| `lib/services/record_link_index_service.dart` | incoming · title resolve (R2-A) |
| `lib/widgets/vault_markdown_body.dart` | Sanctum preview · `onWikiLinkTap` |
| `lib/widgets/markdown_body_editor.dart` | 본문 편집 · URL link만 (wiki picker ❌) |
| `lib/screens/home/dialogs/entity_link_picker_dialog.dart` | R2-B Step 1 · Entity 선택 UI |
| `lib/services/entity_link_picker_candidates.dart` | archived 우선 · R1 type filter |
| `lib/utils/markdown_edit_actions.dart` | `insertWikiLink` · canonical patch (R2-B Step 2) |
| `lib/models/entity_link_selection.dart` | picker 반환값 · canonical token helper |

---

## 9. R2-B Step 1 — Entity Picker (완료)

| 항목 | 상태 |
|------|------|
| `showEntityLinkPickerDialog` | ✅ |
| `EntityLinkSelection` (entityId, title, entityType) | ✅ |
| catalog search + archived 우선 정렬 | ✅ |
| Person / Event / Concept only | ✅ |
| Sanctum / toolbar / insert 연결 | ✅ Step 3 |

---

## 10. R2-B Step 2 — Wiki Link Insert (완료)

| 항목 | 상태 |
|------|------|
| `MarkdownEditActions.insertWikiLink` | ✅ |
| `EntityLinkSelection.canonicalWikiToken` 재사용 | ✅ |
| collapsed / ranged / multiline / unicode | ✅ 테스트 |
| MarkdownBodyEditor 연결 | ✅ Step 3 |

---

## 11. R2-B Step 3 — Toolbar Wiring (완료)

| 항목 | 상태 |
|------|------|
| `onRequestEntityLink` callback | ✅ |
| Toolbar 「Entity 연결」 | ✅ |
| `HomeShellController.handleRequestEntityLink` | ✅ |
| widget test (toolbar insert) | ✅ `markdown_body_editor_entity_link_test.dart` |

---

## 12. R2-B Step 4 — Pipeline Verification (완료)

| 검증 항목 | 결과 |
|-----------|------|
| `insertWikiLink` → canonical token | ✅ |
| `syncBodyFromEditor` + save → `.md` 보존 | ✅ |
| `RecordLinkParser` explicitId | ✅ |
| `rebuildIndex` → `incoming[entityId]` | ✅ |
| Entity Sheet `_loadIncoming` (동일 API) | ✅ |
| `findVaultItemForRecordPath` → Work reopen | ✅ |
| Entity Sheet widget smoke | ⬜ CI hang — 수동 dogfood |

E2E: `test/r2b_entity_link_pipeline_test.dart`

---

## 13. R2-D — Stale Wiki Label (Step 2)

### 13.1 정의

explicitId canonical link `[[entityId|Label]]` 에서  
`Label.trim() != Entity.title.trim()` 이면 **stale label**.

- `[[entityId]]` (pipe label 없음) · titleOnly — stale **아님** (본 정의)
- navigate · incoming index — entityId 기준 **정상** (identity drift 없음)

### 13.2 가시화 (구현됨)

| 위치 | 표시 |
|------|------|
| Entity Sheet Incoming | `연결된 Record N개` · stale > 0 시 `제목 갱신 필요 M개` (`M` = stale **Record** 수) |

계산: `RecordLinkStaleLabel.countForEntity` — link index `incoming` + `outgoing` only. vault mutation 없음.

### 13.3 Incoming refresh (Step 3)

| 항목 | 상태 |
|------|------|
| Sheet open 중 manual refresh | ✅ `Icons.refresh` → `_loadIncoming()` |
| stale count 재계산 | ✅ refresh 시 함께 |
| link index rebuild 자동 구독 | ⬜ Step 3 범위 밖 |

상세: [r2d-step3-incoming-refresh.md](../programs/r2d-step3-incoming-refresh.md)

### 13.4 미구현

| 항목 | 상태 |
|------|------|
| vault label rewrite | ⬜ Step 3+ |
| Rename dialog stale 안내 (Option B) | ⬜ rename UI 선행 |
| Preview title override (정책 C) | ⬜ |

상세: [r2d-step2-stale-label-visibility.md](../programs/r2d-step2-stale-label-visibility.md)

---

## 14. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — R2-B Step 0 Link Identity Policy Lock |
| 2026-06-19 | v1.1 — §9 R2-B Step 1 Entity Picker Dialog |
| 2026-06-19 | v1.2 — §6.1 Authoring Pipeline · §10 Step 2 insertWikiLink |
| 2026-06-20 | v1.3 — §11 Step 3 wiring · §12 Step 4 E2E verification |
| 2026-06-19 | v1.4 — §13 R2-D Step 2 stale label definition · Entity Sheet count |
| 2026-06-19 | v1.5 — §13.3 Step 3 Incoming refresh button |
