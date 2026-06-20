# R2-D Step 3 — Incoming Links Live Refresh

> **상태:** 조사 + 최소 구현 (Option A)  
> **날짜:** 2026-06-19  
> **상위:** [Step 2](r2d-step2-stale-label-visibility.md) · [link-identity-policy.md](../policy/link-identity-policy.md)

---

## 1. 목표

Entity Sheet가 **열린 상태**에서 link index 갱신 후 사용자가 Incoming Links·stale count를 **수동 refresh** 할 수 있게 한다.

**이번 Step:** refresh 버튼 (Option A)만. 자동 이벤트 구독 ❌.

---

## 2. `_loadIncoming()` 호출 위치 조사

**파일:** `lib/screens/home/dialogs/entity_journal_dialog.dart`

| 시점 | 호출 | 비고 |
|------|:----:|------|
| `initState` | ✅ | Sheet 최초 open 시 1회 |
| `didUpdateWidget` | ❌ | **미구현** — widget.entity / linkIndex 변경 무시 |
| `_save()` 후 | ❌ | 저장해도 incoming 재조회 없음 |
| dispose 외 lifecycle | ❌ | |

**갭:** vault save → debounced link index rebuild(800ms) 후에도 Sheet UI는 **stale** — reopen 전까지 count 고정.

---

## 3. Link index rebuild 시점 조사

**파일:** `lib/screens/home/coordinators/home_vault_coordinator.dart`

| 트리거 | 메서드 | debounce |
|--------|--------|----------|
| `loadItems()` | `rebuildLinkIndex()` | 없음 (즉시) |
| `vault.onVaultUpdated` | `rebuildLinkIndex()` | **800ms** |
| index 파일 없음/버전 불일치 | `RecordLinkIndexService._ensureLoaded` → rebuild | — |

**`RecordLinkIndexService`:** in-memory `_incoming` / `_outgoing` 갱신 후 `link_index.json` persist.  
**Sheet에 rebuild 완료 이벤트 전달 없음** — `RecordLinkPort`는 pull-only API.

---

## 4. 구현 옵션 우선순위

| 옵션 | 내용 | Step |
|------|------|:----:|
| **A** | Incoming 섹션 **refresh 아이콘** → `_loadIncoming()` | **✅ Step 3** |
| B | Sheet resume (RouteAware / AppLifecycle) 시 reload | ⬜ |
| C | link index rebuild 이벤트 구독 | ⬜ |

### Option A (구현됨)

- `_IncomingLinksSection` 헤더 우측 `Icons.refresh`
- `Key('entity_incoming_refresh')`
- tap → `_loadIncoming()` → `incomingRecordPaths` + `RecordLinkStaleLabel.countForEntity`
- `linkIndex == null` 이면 섹션 자체 미표시 (기존과 동일)
- incoming **0건**이어도 헤더·refresh 표시 (index 갱신 후 추가 링크 반영 가능)

### Option B (미구현)

- Workbench에서 Sheet 위로 다른 화면 갔다 돌아올 때 reload
- `RouteAware` 또는 dialog `barrier dismissible` 재진입 패턴 필요

### Option C (미구현)

- `HomeVaultCoordinator.rebuildLinkIndex` 완료 callback / stream
- Sheet 다수 open 시 fan-out — Step 3 범위 밖

---

## 5. 구현 요약

| 파일 | 변경 |
|------|------|
| `entity_journal_dialog.dart` | `onRefresh: _loadIncoming`, refresh IconButton, empty incoming에도 헤더 표시 |
| `test/entity_journal_incoming_refresh_test.dart` | refresh → count 갱신 widget test |
| 본 문서 | Step 3 조사·설계 |

**금지 준수:** vault rewrite ❌ · 자동 구독 ❌

---

## 6. 테스트

`entity_journal_incoming_refresh_test.dart`:

1. Fake `RecordLinkPort` — 초기 incoming 0
2. Harness pump → `연결된 Record 0개`
3. index snapshot 변경 (simulate rebuild)
4. refresh tap
5. `연결된 Record 1개` · `제목 갱신 필요 1개`

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Step 3 refresh button · 조사 |
