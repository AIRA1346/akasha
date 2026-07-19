# Canvas Editor Decomposition Plan

> **작성:** 2026-07-08 (Stabilization v0.3-A.4)
> **Status:** Draft plan (open) — B1–B6 not started
> **목적:** `canvas_editor_view.dart` (~1,200줄)를 기능 추가 전에 점진적으로 분해하기 위한 계획
> **원칙:** 동작 변경 없는 behavior-preserving extraction만. 한 PR/슬라이스당 1~2 파일 분리.

---

## 현재 파일 책임 (as-is)

| 파일 | 줄 수 (approx) | 책임 |
|------|----------------|------|
| `canvas_editor_view.dart` | ~1,200 | 메인 StatefulWidget — 로드/저장, 헤더, InteractiveViewer, 노드/엣지 UI, relation dialog, fit-to-content, 드래그 |
| `canvas_node_card.dart` | ~320 | 노드 카드 렌더 (text / work / entity) |
| `canvas_edge_painter.dart` | ~50 | 관계선 CustomPainter |
| `canvas_archive_search_dialog.dart` | — | Work/Entity 아카이브 검색 다이얼로그 |
| `canvas_record.dart` | — | CanvasRecord / CanvasLayout / CanvasNode / CanvasEdge 모델 |
| `canvas_store.dart` | — | CRUD · debounced layout.json 저장 |

---

## v0.3-A.4에서 완료한 1차 분리

| 신규 파일 | 추출 내용 |
|-----------|-----------|
| `canvas_editor_modes.dart` | `CanvasInteractionMode` enum |
| `canvas_viewport_controls.dart` | workspace config · fit-to-content matrix · viewport delta from matrix · default node size helpers |

---

## 권장 분해 순서 (다음 슬라이스)

### Slice B1 — relation helpers (낮은 위험)

**파일:** `canvas_relation_helpers.dart`

- `sanitizeAndValidateCanvasUserRelation(String input)` — create/edit dialog 공통
- (선택) `canvasRelationTokenChoices()` — core + recommended preset 목록

**남는 것:** dialog UI는 아직 view에 유지 (setState·layout 의존)

### Slice B2 — relation dialogs (중간 위험)

**파일:** `canvas_relation_dialogs.dart`

- `showCanvasCreateRelationDialog(...)` → `Future<String?>` (relation token or cancel)
- `showCanvasEditEdgeDialog(...)` → `Future<CanvasEdgeEditResult?>` (save / delete / cancel)

**주의:** `_layout` mutation은 caller(state)에 남김. dialog는 UI + validation만.

### Slice B3 — edge label widget (낮은 위험)

**파일:** `canvas_edge_label.dart`

- `_buildEdgeLabelWidget` → `CanvasEdgeLabel` StatelessWidget
- midpoint 계산은 `canvas_viewport_controls.dart`의 node size helper 재사용

### Slice B4 — interaction banner + header toolbar (낮은 위험)

**파일:** `canvas_editor_toolbar.dart` · `canvas_interaction_banner.dart`

- 헤더 Row (닫기 · fit · 연결 · 아카이브 추가 · 메모 추가)
- 연결 모드 안내 배너

### Slice B5 — node layer (중간 위험)

**파일:** `canvas_node_layer.dart`

- `_buildNodeWidget` · pan/drag handlers
- `CanvasInteractionMode` 상태는 parent에서 callback으로 전달

### Slice B6 — editor state coordinator (높은 위험 · v0.3-B 이후)

**파일:** `canvas_editor_controller.dart` (또는 mixin)

- load/save orchestration
- node/edge CRUD
- interaction mode machine

**보류 이유:** Workbench 탭 lifecycle·debounced save와 강결합. v0.3-B.1 더블클릭 열기는 view callback으로 완료 — controller 추출은 후속.

---

## 분해하지 않을 것 (당분간)

- `InteractiveViewer` + `TransformationController` wiring — view root에 유지
- `HardwareKeyboard` global handler — 단축키 정책 확정 후 별도 slice
- `CanvasStore` — 이미 service로 분리됨

---

## 목표 줄 수

| 마일스톤 | `canvas_editor_view.dart` 목표 |
|----------|-------------------------------|
| v0.3-A.4 (현재) | ~1,050줄 (viewport/modes 추출 후) |
| B1+B2 완료 | ~750줄 |
| B3~B5 완료 | ~450줄 |
| B6 (선택) | ~200줄 (shell only) |

---

## 테스트 전략 (분해와 병행)

| 우선순위 | 대상 | 유형 |
|----------|------|------|
| P0 | `computeCanvasFitToContentMatrix` | unit (empty / 1 node / N nodes) |
| P0 | `canvasViewportDeltaFromMatrix` | unit |
| P1 | `sanitizeAndValidateCanvasUserRelation` | unit |
| P2 | Canvas editor smoke | widget (mount + load fixture layout) |

현재: `canvas_store_test.dart` · `vault_format_validator_test.dart` (canvas group)만 존재. UI/widget 테스트 없음.

---

## v0.3-B 기능과 분해 순서

**권장:** ~~v0.3-B.1 더블클릭 Workbench 열기~~ ✅ → B1(relation helpers) → B2(dialogs) → 선택/Delete 단축키

v0.3-B.1은 view `onDoubleTap` + coordinator `open*FromCanvas`로 완료. B5 node layer 분리는 선택/단축키 슬라이스와 병행 가능.

---

## 알려진 한계 (문서화용 · v0.3-A)

- 노드 kind: UI는 `text` · `work` · `entity`만. `record` · `group` 미구현.
- Edge 편집: `canvas_only`만. `canonical_view` · `candidate` read-only.
- 단축키: `Ctrl+Space` = Fit to Content — Windows/IME 충돌 가능. v0.3-B에서 `Home` / `Ctrl+0` / `F` 후보.
- Widget 테스트 없음 — 회귀는 manual + store/validator tests에 의존.
- `canvas.md` 본문/메타 UI 편집 없음.
