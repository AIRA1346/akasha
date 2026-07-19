# R3-G Save → Preview Return — Implementation Report

> **완료:** 2026-06-22  
> **Audit:** [R3G_SAVE_RETURN_AUDIT.md](./R3G_SAVE_RETURN_AUDIT.md)

---

## 요약

Preview에서 「기록하기」로 진입한 Workbench에서 **명시적 저장** 후 Preview(+ Stack)로 자동 복귀한다.

| 항목 | 상태 |
|------|------|
| `PreviewReturnSnapshot` | ✅ |
| Work Preview → 저장 → Preview | ✅ |
| Entity Preview → 저장 → Preview | ✅ |
| Preview Stack 복원 | ✅ |
| Autosave 시 Workbench 유지 | ✅ |
| 직접 Workbench 진입 → 기존 동작 | ✅ |

---

## Before / After

### Before

```
openWorkFromPreview()
  → closeAllPreviews()        // stack 소실
  → Workbench

onWorkbenchWorkSaved()
  → reloadItems + updateTab   // Preview 복귀 없음
```

### After

```
openWorkFromPreview()
  → snapshot = current + backStack
  → closeAllPreviews()
  → _previewReturnSnapshot = snapshot
  → Workbench

onWorkbenchWorkSaved(saved, silent: false)
  → reloadItems + updateTab
  → ID 일치 시 stack restore + showBrowse()
```

---

## 핵심 구현

### PreviewReturnSnapshot (`preview_frame.dart`)

```dart
class PreviewReturnSnapshot {
  final PreviewFrame current;
  final List<PreviewFrame> backStack;
}
```

### 스냅샷 생명주기

| 이벤트 | 동작 |
|--------|------|
| `openWorkFromPreview` / `openEntityFromPreview` | 진입 전 캡처 → Workbench |
| `openBrowseItem` / `openEntity` / `open*Preview`(replace) | clear |
| `closeAllPreviews` | clear |
| 명시적 저장 + ID match | restore + `workbench.showBrowse()` |
| Autosave (`silent: true`) | 복귀 안 함 |
| 탭 삭제 (스냅샷 대상) | clear |

### silent 플래그 전파

```
WorkDetailWorkspace._saveArchive(silent:)
  → onSaved(saved, silent: silent)
  → WorkbenchShell → HomeShellController.onWorkbenchWorkSaved(..., silent:)
```

Entity 동일.

---

## 변경 파일

| 파일 | 변경 |
|------|------|
| `preview_frame.dart` | `PreviewReturnSnapshot` |
| `home_shell_controller.dart` | stash / restore / clear |
| `work_detail_workspace.dart` | `onSaved` + silent |
| `entity_detail_workspace.dart` | 동일 |
| `workbench_shell.dart` | silent 전달 |
| `home_shell_body.dart` | 콜백 시그니처 |
| `work_detail_workspace_smoke_test.dart` | mock 시그니처 |

---

## 성공 기준

| # | 시나리오 | 달성 |
|---|----------|:----:|
| 1 | Work Preview → Workbench → 저장 → Work Preview | ✅ |
| 2 | Entity Preview → Workbench → 저장 → Entity Preview | ✅ |
| 3 | A→B stack + Entity B 기록 → B Preview + `← 이전` → A | ✅ |
| 4 | Autosave 중 Workbench 유지 | ✅ |
| 5 | Search → Workbench → 저장 → Workbench 유지 | ✅ |

---

## R3-E Dogfood

| 항목 | 상태 |
|------|------|
| D3 저장 후 Preview 미복귀 | ✅ **해소** |

**루프 완성도 추정:** ~88% → **~92%**

---

## 금지 사항

Discovery / Pipeline / Link Index / Schema 변경 **없음**.
