# R3-G Save → Preview Return — Audit

> **갱신:** 2026-06-22  
> **방법:** Preview→Workbench→저장 호출 체인 코드 추적  
> **코드 수정:** Audit 후 Step 3

---

## 문제

```
Preview → 기록하기 → Workbench → 저장 → Workbench 체류  ❌
Preview → 기록하기 → Workbench → 저장 → Preview 복귀  ✅ (목표)
```

R3-E **D3:** 저장 후 Preview 자동 복귀 없음.

---

## Work Preview → Workbench

| 단계 | 함수 | 파일 |
|------|------|------|
| CTA | `onOpenDetail` → `openWorkFromPreview` | `dashboard_preview_panel.dart` |
| 진입 | `closeAllPreviews()` → `workbenchCoord.openBrowseItem` | `home_shell_controller.dart` L513–518 |
| 빈 연결 CTA | `openWorkFromPreviewToConnect` → `openWorkFromPreview` | L306–311 |
| 렌더 | `!workbench.hasOpenDetail` 일 때만 Preview 패널 | `home_shell_body.dart` L443 |

**진입 시 Preview·Stack 전부 소거** — 복귀 컨텍스트 **미보관**.

---

## Entity Preview → Workbench

| 단계 | 함수 | 파일 |
|------|------|------|
| CTA | `onOpenDetail` → `openEntityFromPreview` | `entity_dashboard_preview_panel.dart` |
| 진입 | `closeAllPreviews()` → `workbenchCoord.openEntity` | `home_shell_controller.dart` L535–540 |

동일하게 컨텍스트 소거.

---

## 저장 성공 콜백 경로

```
WorkDetailWorkspace._saveArchive
  → widget.onSaved(saved)                    [silent 여부 무관 호출]
  → WorkbenchShell.onWorkSaved
  → home_shell_body.onWorkbenchWorkSaved
  → workbenchCoord.onWorkbenchWorkSaved      [reloadItems + updateTab만]

EntityDetailWorkspace._saveJournal
  → widget.onSaved(mirrored, saved)
  → 동일 체인
```

**Preview 복귀 로직 없음.**

### Autosave 주의

`_saveArchive(silent: true)` / `_saveJournal(silent: true)` 도 `onSaved` 호출.  
**명시적 저장(`silent: false`)에서만 Preview 복귀**해야 함.

---

## Workbench 종료 경로

| 경로 | Preview 복귀 |
|------|:------------:|
| 저장 성공 | ❌ (목표: ✅) |
| 탭 닫기 | ❌ |
| `showBrowse()` (탐색 모드) | Preview null — 패널 없음 |
| Wiki → Preview | `open*Preview` replace |

---

## Preview Stack 충돌

| 항목 | 판정 |
|------|------|
| 진입 시 stack clear | ✅ `closeAllPreviews` |
| 복귀 시 stack 복원 필요 | ✅ 스냅샷에 `backStack` 포함 |
| `popPreview` vs 복귀 | 독립 — 복귀 = 전체 세션 restore |
| Workbench `hasOpenDetail` | 복귀 시 `showBrowse()` 필요 |

---

## Preview 컨텍스트 보관 (설계)

```dart
class PreviewReturnSnapshot {
  final PreviewFrame current;
  final List<PreviewFrame> backStack;
}
```

| 이벤트 | 동작 |
|--------|------|
| `openWorkFromPreview` / `openEntityFromPreview` | 진입 **직전** 스냅샷 → `closeAllPreviews` → Workbench |
| `openBrowseItem` / `openEntity` (직접) | 스냅샷 **clear** |
| `openWorkPreview` / `openEntityPreview` | 스냅샷 **clear** |
| 명시적 저장 + ID 일치 | 스냅샷 restore + `showBrowse()` |
| Autosave (`silent: true`) | 복귀 **안 함** |

### ID 일치

| 스냅샷 current | 저장 대상 |
|----------------|-----------|
| `WorkPreviewFrame(A)` | `saved.workId == A` |
| `EntityPreviewFrame(B)` | `saved.entityId == B` |

다른 탭 저장 시 복귀하지 않음.

---

## Work / Entity 정책 대칭

| 항목 | Work | Entity |
|------|:----:|:------:|
| Preview CTA | `openWorkFromPreview` | `openEntityFromPreview` |
| 스냅샷 | ✅ | ✅ |
| 저장 복귀 | ✅ | ✅ |
| Stack 복원 | ✅ | ✅ |

**동일 정책 가능.**

---

## 범위 외 (기존 유지)

| 진입 | Preview 복귀 |
|------|:------------:|
| Search → Workbench | ❌ |
| Sidebar / 그리드 → Workbench | ❌ |
| incoming / same-day → Workbench | ❌ |
| Graph 「기록 열기」 | ❌ |

---

## 구현 파일 (Step 3)

| 파일 | 변경 |
|------|------|
| `preview_frame.dart` | `PreviewReturnSnapshot` |
| `home_shell_controller.dart` | stash / restore / clear |
| `work_detail_workspace.dart` | `onSaved(..., silent:)` |
| `entity_detail_workspace.dart` | 동일 |
| `workbench_shell.dart` | silent 전달 |
| `home_shell_body.dart` | 콜백 시그니처 |

---

## 성공 기준

1. Work Preview → Workbench → **명시적 저장** → Work Preview (+ stack)
2. Entity Preview → Workbench → **명시적 저장** → Entity Preview (+ stack)
3. Autosave 시 Workbench 유지
4. Search → Workbench → 저장 → Workbench 유지
