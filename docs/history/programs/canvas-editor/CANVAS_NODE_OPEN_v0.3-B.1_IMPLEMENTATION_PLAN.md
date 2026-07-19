# Canvas Node Open v0.3-B.1 — Implementation Plan

> **작성:** 2026-07-08
> **상태:** ✅ 구현 완료 (`f65e2a03`) · tests **830 PASS** · analyze **0** · Windows release build PASS
> **선행:** Canvas Editor Stabilization v0.3-A.4 ✅ · `origin/main` push 완료
> **분해 계획:** [CANVAS_EDITOR_DECOMPOSITION_PLAN.md](../../../draft/CANVAS_EDITOR_DECOMPOSITION_PLAN.md)

---

## 1. 목표

캔버스의 **Work / Entity** 노드를 **더블클릭**하면 해당 원본 아카이브 항목이 **Workbench 상세 탭**으로 열린다.

캔버스가 “그림판”이 아니라 AKASHA 아카이브와 연결된 작업대가 되도록, 노드 → 원본 기록으로 바로 진입하는 **문(door)** 을 만든다.

---

## 2. 범위

### 포함

| # | 항목 |
|---|------|
| 1 | `work` 노드 더블클릭 → Work Workbench 탭 |
| 2 | `entity` 노드 더블클릭 → Entity Workbench 탭 |
| 3 | `text` 노드 — 기존 동작 유지 (편집 버튼 · drag · relation 모드). 더블클릭 무반응 또는 기존 `_editTextNode` 유지 중 택1 |
| 4 | missing node (`[Missing work/entity]`) — SnackBar 안내, 탭 열기 없음 |
| 5 | `layout.json` / vault 스키마 변경 없음 |

### 제외 (이번 슬라이스)

- relation helper 분리 (B1)
- 선택 시스템 · Delete/Escape 단축키
- 노드 리사이즈 · 베지에 곡선 · 미니맵
- `record` / `group` 노드
- `canonical_view` / `candidate` edge UX
- 대규모 리팩터링

---

## 3. 현재 코드 분석

### 3.1 진입 경로 (오늘)

```
KnowledgeGraphView → openCanvas()
  → HomeWorkbenchCoordinator.openCanvas()
  → WorkbenchController.openCanvas()   // tabs.clear() + canvas tab 1개
  → WorkbenchShell → CanvasEditorWorkspace
```

`CanvasEditorWorkspace`는 **`onClose`만** 받음. Work/Entity 열기 callback **없음**.

### 3.2 Workbench 탭 모델 (중요)

```dart
// workbench_controller.dart
static const int maxTabs = 1;

void openWork(AkashaItem item) {
  tabs..clear()..add(WorkCollectibleTab(...));  // 기존 탭 전부 제거
}
```

`openEntity` / `openCanvas`도 동일하게 **`tabs.clear()`** 후 1탭만 유지.

**함의:** Canvas 탭에서 기존 `openWork()`를 그대로 호출하면 **캔버스 탭이 사라지고** Work 탭만 남음.
더블클릭 후 Workbench 탭을 닫으면 browse로 돌아가며 **캔버스 컨텍스트 복귀 불가**.

→ v0.3-B.1에서 **탭 push semantics** 최소 도입 필요 (§5.2).

### 3.3 노드 데이터 해석 (이미 구현됨)

`CanvasNodeCard._buildArchiveCard`와 동일 로직 재사용:

| kind | lookup | open 대상 |
|------|--------|-----------|
| `work` | `localItems.firstWhere(workId == node.workId)` | `AkashaItem` → `openBrowseItem` |
| `entity` | `_entities.firstWhere(entityId == node.entityId)` | `EntityJournalEntry` → `UserCatalogEntity` + journal |

Entity는 `UserCatalogEntity.userLocal(entityId, type, title, tags, ...)` 로 변환 후
`HomeWorkbenchCoordinator.openEntity(entity)` 호출 (journal은 coordinator가 vault에서 재로드하거나, 이미 로드된 entry 전달).

### 3.4 제스처 충돌

`_buildNodeWidget`의 `GestureDetector`:

- `onPanStart` / `onPanUpdate` — 노드 drag
- `onTap` — relation 연결 모드 전용
- **더블클릭 슬롯 없음**

주의:

- 더블클릭 vs drag: pan이 먼저 잡히면 double-tap 실패 가능 → **drag threshold** 또는 `onDoubleTap` + pan은 movement 발생 시만 처리 검토
- relation 모드(`CanvasInteractionMode != none`)에서는 더블클릭 **비활성** (tap이 source/target 선택용)

### 3.5 기존 참조 패턴

Workbench 내부 연결 패널은 이미 동일 callback 사용:

```dart
// home_shell_body_center.dart → WorkbenchShell
onRecordOpenWork: onOpenBrowseItem,
onRecordOpenEntity: onOpenEntity,
```

Canvas도 **동일 coordinator 메서드**를 재사용하는 것이 일관적.

---

## 4. 설계

### 4.1 Callback wiring

```
WorkbenchShell
  → CanvasEditorWorkspace(
       onOpenWork: widget.onRecordOpenWork,      // void Function(AkashaItem)
       onOpenEntity: widget.onRecordOpenEntity,  // Future<void> Function(UserCatalogEntity)
     )
```

Coordinator 시그니처:

- Work: `HomeWorkbenchCoordinator.openBrowseItem(AkashaItem)`
- Entity: `HomeWorkbenchCoordinator.openEntity(UserCatalogEntity)`

Canvas 내부 private handler:

```dart
Future<void> _handleNodeDoubleTap(CanvasNode node) async {
  if (_interactionMode != CanvasInteractionMode.none) return;
  switch (node.kind) {
    case 'work': ...
    case 'entity': ...
    default: return; // text — no-op or existing edit
  }
}
```

### 4.2 탭 push semantics (필수)

**목표:** Canvas 탭 유지 + Work/Entity 탭 추가 → 사용자가 탭 rail에서 캔버스로 복귀.

**최소 변경안:**

1. `WorkbenchController.maxTabs = 2` (canvas + detail 1개)
2. 신규 메서드 (이름 예):

```dart
void openDetailBesideCanvas(CollectibleTab detailTab) {
  final canvasTab = tabs.whereType<CanvasCollectibleTab>().firstOrNull;
  if (canvasTab == null) {
    // fallback: 기존 openWork/openEntity 동작
    ...
    return;
  }
  // 이미 같은 id 탭 있으면 selectTab
  if (tabs.any((t) => t.id == detailTab.id)) {
    selectTab(detailTab.id);
    return;
  }
  tabs.removeWhere((t) => t is! CanvasCollectibleTab); // canvas 외 1 detail만
  tabs.add(detailTab);
  activeTabId = detailTab.id;
  _detailViewVisible = true;
  notifyListeners();
}
```

3. `HomeWorkbenchCoordinator`에 `openWorkFromCanvas` / `openEntityFromCanvas` thin wrapper

**범위 통제:** browse에서 Work 여는 기존 `openWork(clear)` 동작은 **변경하지 않음**.
push는 **active tab이 CanvasCollectibleTab일 때만**.

### 4.3 text 노드 정책

**권장 (v0.3-B.1):** text 더블클릭 → **무 반응** (기존 카드 내 편집/삭제 버튼 유지).

대안: 더블클릭 = `_editTextNode` — UX 혼동 가능. 이번 슬라이스에서는 **no-op** 채택.

### 4.4 missing / stale node

- Work/Entity lookup 실패 → SnackBar 2초
  `"아카이브에서 해당 항목을 찾을 수 없습니다."`
- layout.json 변경 없음 (노드 ID는 그대로)

---

## 5. 변경 파일 (예상)

| 파일 | 변경 |
|------|------|
| `lib/features/workbench/data/workbench_controller.dart` | `openDetailBesideCanvas` · `maxTabs = 2` |
| `lib/screens/home/coordinators/home_workbench_coordinator.dart` | `openWorkFromCanvas` · `openEntityFromCanvas` |
| `lib/features/workbench/presentation/workbench_shell.dart` | CanvasEditorWorkspace에 callback 전달 |
| `lib/screens/home/views/canvas_editor_view.dart` | `onOpenWork` / `onOpenEntity` props · `_handleNodeDoubleTap` · GestureDetector `onDoubleTap` |
| `test/workbench_controller_canvas_open_test.dart` | **신규** — push semantics unit test (optional but 권장) |

**변경하지 않음:** `canvas_record.dart` · `canvas_store.dart` · `layout.json` schema

---

## 6. 구현 순서

| Step | 작업 | 검증 |
|------|------|------|
| 1 | `WorkbenchController.openDetailBesideCanvas` + unit test | tabs=[canvas, work], active=work |
| 2 | Coordinator wrapper 2개 | mock controller |
| 3 | WorkbenchShell callback pass-through | analyze |
| 4 | CanvasEditorWorkspace double-tap handler (work) | manual: canvas → dblclick work → work tab |
| 5 | Entity path + UserCatalogEntity mapping | manual: entity tab |
| 6 | relation 모드 / drag / missing node 회귀 | manual checklist |
| 7 | `flutter test` · `flutter analyze lib` | 826+ PASS · 0 issue |

---

## 7. 수동 회귀 체크리스트

- [ ] Canvas pan/zoom · Fit to Content · viewport 저장
- [ ] 노드 drag (더블클릭과 drag 구분)
- [ ] relation 연결 create / edit / delete
- [ ] text 노드 편집·삭제
- [ ] work 더블클릭 → Work 탭 · 탭 rail에 Canvas + Work 2개
- [ ] Canvas 탭 클릭 → 캔버스 복귀
- [ ] entity 더블클릭 → Entity 탭
- [ ] missing node SnackBar
- [ ] browse에서 Work 여는 기존 flow (1탭 clear) unchanged

---

## 8. 테스트 계획

| 유형 | 대상 |
|------|------|
| Unit | `openDetailBesideCanvas` — canvas+work 2탭 · duplicate id select · non-canvas fallback |
| Unit | entity journal → `UserCatalogEntity.userLocal` mapping helper (extract 시) |
| Manual | §7 체크리스트 |
| Widget | v0.3-B.2 이후 (CanvasEditorWorkspace smoke) |

---

## 9. 위험 · 완화

| 위험 | 완화 |
|------|------|
| 더블클릭 vs drag 충돌 | relation 모드 off일 때만 enable · drag 중 double-tap 무시 |
| Canvas 탭 유실 | push semantics (§4.2) — **필수** |
| Entity catalog 불일치 | vault `_entities` + coordinator `openEntity` 재사용 |
| maxTabs=2가 browse flow에 영향 | canvas active일 때만 push; browse open은 기존 clear 유지 |

---

## 10. v0.3-B.2 후보 (이번 범위 아님)

- Work/Entity 탭 닫을 때 자동 canvas select
- text 더블클릭 정책 재검토
- CanvasEditorWorkspace widget test
- `Ctrl+Space` → `Home`/`F` 단축키 교체

---

## 11. 완료 기준

1. Work/Entity 노드 더블클릭으로 Workbench 상세 탭 열림
2. Canvas 탭이 tab rail에 **남아** 복귀 가능
3. text / drag / relation / viewport 회귀 없음
4. `flutter test` green · `flutter analyze lib` 0 issue
5. 스키마·layout.json 변경 없음
