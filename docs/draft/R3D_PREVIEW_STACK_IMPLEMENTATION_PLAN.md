# R3-D Preview Stack — Implementation Plan

> **작성:** 2026-06-22  
> **전제:** [R3D_PREVIEW_STACK_AUDIT.md](./R3D_PREVIEW_STACK_AUDIT.md)  
> **P2 완료:** [R3D_ENTITY_WORKBENCH_P2_IMPLEMENTATION_REPORT.md](./R3D_ENTITY_WORKBENCH_P2_IMPLEMENTATION_REPORT.md)

---

## Audit — 호출 경로 추적

### 1. Preview 상태 저장 위치

| 심볼 | 파일 | 역할 |
|------|------|------|
| `workPreviewItem` | `home_shell_controller.dart` L77 | 현재 Work Preview |
| `entityPreviewItem` | `home_shell_controller.dart` L78 | 현재 Entity Preview |

**단일 슬롯.** 스택·히스토리 필드 **없음**.

렌더: `home_shell_scaffold.dart` → `home_shell_body.dart` L431–455  
조건: `!workbench.hasOpenDetail` 일 때만 패널 표시.

### 2. 상호 배타 구조

```dart
void openWorkPreview(AkashaItem item) {
  entityPreviewItem = null;  // Entity 제거
  workPreviewItem = resolved;
}

void openEntityPreview(UserCatalogEntity entity) {
  workPreviewItem = null;    // Work 제거
  entityPreviewItem = entity;
}
```

Work·Entity **동시 불가**. 이전 프레임 **저장 없음**.

### 3. 호출 경로 매트릭스

| 호출자 | 함수 | push? | 스택 영향 |
|--------|------|:-----:|-----------|
| Browse 그리드·포스터 | `openWorkPreview` / `openEntityPreview` | ❌ | replace |
| Home Dashboard | `onPreviewWork` / `onPreviewEntity` | ❌ | replace |
| Knowledge Graph | `onPreviewWork` / `onPreviewEntity` | ❌ | replace |
| Recent 탐험 | `openRecentExploreItem` → open*Preview | ❌ | replace |
| Wiki (`handleWikiLinkTap`) | `openWorkPreview` / `openEntityPreview` | ❌ | replace |
| **Preview 이웃 탭** | `onPreviewWork` / `onPreviewEntity` (패널) | ❌→✅ | **replace (버그)** |
| `previewLinkedWork` | `openWorkPreview` | ❌ | **미배선 (dead code)** |
| `previewLinkedEntity` | `openEntityPreview` | ❌ | **미배선 (dead code)** |
| Workbench 진입 | `closeAllPreviews` | — | clear |
| `openBrowseItem` | `closeAllPreviews` | — | clear |

**핵심:** `previewLinked*` 가 정의만 되어 있고 Preview 패널은 `onPreviewWork/Entity`(replace)를 사용 중.

### 4. Stack 추가 최소 변경 지점

| 레이어 | 변경 | 이유 |
|--------|------|------|
| `preview_frame.dart` (신규) | `PreviewFrame` sealed union | Work/Entity 프레임 직렬화 |
| `home_shell_controller.dart` | `_previewBackStack`, push/pop | **유일 상태 소유자** |
| `home_shell_body.dart` | 이웃 콜백 분리 | 패널만 linked push |
| `dashboard_preview_panel.dart` | `← 이전` 헤더 | UX |
| `entity_dashboard_preview_panel.dart` | 동일 | UX |
| `home_shell_scaffold.dart` | `canPopPreview`, `popPreview` 배선 | — |

**변경 없음:** Discovery, Link Index, Graph 엔진, Workbench, vault.

### 5. Shell 레벨 관리 가능 여부

**가능.** Preview 상태는 이미 `HomeShellController` 단일 소유.

- `workPreviewItem` / `entityPreviewItem` = **현재 프레임** (기존 유지)
- `_previewBackStack: List<PreviewFrame>` = **이전 프레임** (신규)
- UI는 current만 렌더 — 320px 유지

### 6. Navigation 충돌

| 이벤트 | 정책 | 충돌 |
|--------|------|------|
| 이웃 탭 (Preview 내) | `push` | 없음 |
| 그리드·Graph·Recent | `replace` + stack clear | 없음 |
| `← 이전` | `pop` | 없음 |
| `X` 닫기 | `closeAllPreviews` + stack clear | 없음 |
| Workbench 진입 | `closeAllPreviews` | 의도적 (편집 분리) |
| Wiki (Sanctum) | `replace` (Workbench 열림 시 Preview 숨김) | 없음 |

---

## 구현 설계

### PreviewFrame

```dart
sealed class PreviewFrame {
  const PreviewFrame();
}
class WorkPreviewFrame extends PreviewFrame {
  const WorkPreviewFrame(this.item);
  final AkashaItem item;
}
class EntityPreviewFrame extends PreviewFrame {
  const EntityPreviewFrame(this.entity);
  final UserCatalogEntity entity;
}
```

### Controller API

| 메서드 | 동작 |
|--------|------|
| `openWorkPreview(item, {push: false})` | push=false → stack clear + show; push=true → current를 stack에 push 후 show |
| `openEntityPreview(entity, {push: false})` | 동일 |
| `previewLinkedWork(work)` | `openWorkPreview(work, push: true)` |
| `previewLinkedEntity(entity)` | `openEntityPreview(entity, push: true)` |
| `popPreview()` | stack pop → restore; empty면 closeAll |
| `closeAllPreviews()` | current null + stack clear |
| `canPopPreview` | `stack.isNotEmpty` |

### UI

Preview 패널 헤더:

```
[← 이전]  (canPopPreview일 때만)
카테고리/타입 배지                    [X]
```

- `← 이전` → `popPreview()`
- `X` → `closeAllPreviews()`

### 배선 변경

```dart
// home_shell_body — Preview 패널만
onOpenEntity: onPreviewLinkedEntity,
onOpenWork: onPreviewLinkedWork,
canGoBack: canPopPreview,
onBack: onPopPreview,
onClose: onCloseAllPreviews,  // closeAllPreviews
```

Browse·Graph·Dashboard는 기존 `onPreviewWork` / `onPreviewEntity` 유지.

---

## 변경 파일

| 파일 | 작업 |
|------|------|
| `lib/screens/home/preview_frame.dart` | 신규 |
| `home_shell_controller.dart` | stack 로직 |
| `home_shell_scaffold.dart` | 콜백 배선 |
| `home_shell_body.dart` | linked 콜백 분리 |
| `dashboard_preview_panel.dart` | 뒤로 버튼 |
| `entity_dashboard_preview_panel.dart` | 뒤로 버튼 |

---

## 성공 기준

1. Work A → Entity B → `← 이전` → Work A Preview 복귀
2. A → B → C → `← 이전` → B → `← 이전` → A
3. 그리드에서 새 Preview 열면 stack 초기화
4. Workbench 진입 시 stack 초기화
5. Discovery / Link Index / Schema 변경 없음

---

## 루프 완성도 목표

P2 후 83~88% → P3 후 **90~92%**
