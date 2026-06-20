# R2-D Step 2 — Stale Wiki Label 가시화

> **상태:** 조사 + 최소 구현 (rewrite 없음)  
> **날짜:** 2026-06-19  
> **상위:** [R2-D Step 1](r2d-step1-rename-label-drift.md) · [link-identity-policy.md](../policy/link-identity-policy.md)

---

## 1. 목표

Entity rename 이후 **stale wiki label** 을 사용자에게 보여준다.  
**Vault / Work 파일 수정·rewrite 없음.**

---

## 2. Stale 정의 (확정)

| 조건 | stale |
|------|:-----:|
| `RecordLinkKind.explicitId` | ✅ |
| `targetEntityId == entityId` | ✅ |
| `displayLabel` (pipe label) **존재·비어있지 않음** | ✅ |
| `displayLabel.trim() != currentEntityTitle.trim()` | ✅ |
| `[[entityId]]` (label 없음) | ❌ |
| `titleOnly` (`[[Title]]`) | ❌ (Step 2 범위 밖) |

**비교:** trim 후 **exact match** (대소문자 구분).

---

## 3. Stale count 계산 — 조사 결과

### 3.1 가능 여부: **가능**

Entity Sheet Incoming Links 로드 시 **link index만**으로 계산 가능. vault `.md` 재읽기 **불필요**.

```
incomingRecordPaths(entityId)
  → 각 path에 outgoingLinks(path)
  → explicitId + label ≠ currentTitle 집계
```

### 3.2 Index가 제공하는 데이터

| API | 제공 |
|-----|------|
| `incomingRecordPaths` | 역참조 **source record path** 목록 |
| `outgoingLinks(path)` | `RecordLink.displayLabel` · `targetEntityId` · `kind` |

`link_index.json` rebuild 시 vault 본문에서 `displayLabel`을 이미 추출·저장함 (`RecordLinkIndexService`).

### 3.3 집계 지표

| 지표 | 의미 | UX 용도 |
|------|------|---------|
| `incomingRecordCount` | incoming path 수 | “연결된 Record N개” |
| `staleLinkCount` | stale explicitId **링크 occurrence** | Rename dialog “N개 **링크**” |
| `staleRecordCount` | stale 링크 ≥1인 **distinct path** | Entity Sheet “제목 갱신 필요 N개” |

**구현:** `RecordLinkStaleLabel.countForEntity` — `lib/services/record_link_stale_label.dart`

### 3.4 current title 소스

Entity Sheet: `_current?.title ?? widget.entity.title` (journal frontmatter 우선).

### 3.5 한계

| 항목 | 내용 |
|------|------|
| Index stale | rebuild 전 index는 drift 반영 안 함 — save/watch 후 debounced rebuild 전제 |
| titleOnly drift | 본 정의에 **미포함** — 별도 정책 |
| `[[entityId]]` | label 없음 → stale **0** (의도적) |
| Index `displayLabel` vs live vault | index와 vault 불일치 시 index 기준 (rebuild로 수렴) |
| Index `incoming` path 중복 | 동일 Record에 링크 여러 개 시 path 중복 — Step 2에서 `toSet()` dedupe |

---

## 4. UX 옵션 검토 (구현 범위)

### 옵션 A — Entity Sheet (✅ Step 2 최소 구현)

```
연결된 Record 12개
제목 갱신 필요 4개
```

- `4` = **`staleRecordCount`** (stale 링크가 있는 Record 수)
- `staleRecordCount == 0` 이면 두 번째 줄 **숨김**
- rewrite 액션 **없음** — 가시화만

### 옵션 B — Rename 시 확인 (⬜ 미구현 · Step 3+)

```
「스바루」(으)로 변경합니다.
4개 링크가 이전 제목을 사용 중입니다.
[ ] wiki label도 함께 갱신 (향후 rewrite)
```

- `4` = **`staleLinkCount`** 권장 (링크 occurrence가 사용자 기대와 일치)
- rename UI **선행** 필요 (현재 production rename flow 없음)
- Step 2에서는 **설계만**

| | A (Sheet) | B (Rename dialog) |
|--|-----------|-------------------|
| 타이밍 | Sheet 열 때 | rename 확정 전 |
| 카운트 | stale **Record** | stale **Link** |
| rewrite | 없음 | 향후 opt-in |

---

## 5. Auto Rewrite 설계 초안 (구현 없음)

> Step 1 정책 B와 연계. **Step 2에서 코드 변경 없음.**

### 5.1 Incoming index 활용

| 항목 | 평가 |
|------|------|
| 대상 파일 �umeration | ✅ `incomingRecordPaths(entityId)` |
| Full vault scan | ❌ explicitId canonical만이면 **불필요** |
| titleOnly 보완 | ⚠️ incoming만으로 **불충분** — old title grep / alias / optional full scan |

### 5.2 Parser offset 활용

| 항목 | 평가 |
|------|------|
| Index `RecordLink` | offset **없음** — rewrite 시 파일 **재파싱** 필수 |
| `RecordLinkParser.parseFromRecordContent` | `ParsedRecordLink.startOffset` 제공 |
| Patch 전략 | offset 기반 single replace 또는 entityId-scoped regex |
| fenced code block | parser가 제외 — rewrite도 **동일 규칙** 적용 |

### 5.3 예상 수정 파일 수

rename 직후 **통계 산출 (read-only, Step 2와 동일 API):**

```
수정 대상 Record 수  ≈ staleRecordCount
수정 대상 Link 수    ≈ staleLinkCount
```

rewrite 실행 시:

```
for path in incomingRecordPaths(entityId):
  links = parseFromRecordContent(read(path))
  patch each stale explicitId link → [[entityId|newTitle]]
  write(path)  // Step 3+ only
save → signalVaultChanged → debounced rebuildIndex()
```

**비용:** O(|incoming| × file_size) I/O — full vault scan 대비 |incoming|에 비례.

### 5.4 Phase 제안 (Step 3+)

1. Rename UI + Option B preview (`staleLinkCount`)
2. Opt-in rewrite checkbox (default off)
3. `EntityLinkSelection.canonicalWikiToken` 로 새 token 생성
4. Ledger / undo 정책
5. titleOnly Phase 2

---

## 6. 구현 요약 (Step 2)

| 파일 | 변경 |
|------|------|
| `lib/services/record_link_stale_label.dart` | **신규** — stale 판정 · count |
| `lib/screens/home/dialogs/entity_journal_dialog.dart` | Incoming 로드 시 count · Option A UI |
| `test/record_link_stale_label_test.dart` | **신규** |
| `docs/policy/link-identity-policy.md` | §14 R2-D stale 정의 |
| 본 문서 | Step 2 조사·UX·rewrite 초안 |

**금지 준수:** vault rewrite ❌ · Work `.md` 수정 ❌

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Step 2 stale count · Option A UI · rewrite 초안 |
