# R3-D Preview Stack Audit — P3

> **갱신:** 2026-06-22  
> **방법:** `home_shell_controller.dart`, `home_shell_body.dart` 실측  
> **코드 수정:** 없음

---

## 검증 질문

탐험 체인 `Work A → Entity B → Work C` 이동 시 **Work A 맥락**이 유지되는가?

**결론: 아니오. 단일 슬롯 Preview 모델로 이전 노드 맥락은 소실된다.**

---

## Preview 상태 모델 (코드)

### 상태 변수 (`home_shell_controller.dart`)

```dart
AkashaItem? workPreviewItem;
UserCatalogEntity? entityPreviewItem;
```

- **동시에 하나만** 존재 (상호 배타)
- 스택·히스토리·breadcrumb **없음**

### 핵심 함수

| 함수 | Work Preview | Entity Preview | 상대 제거 |
|------|--------------|----------------|-----------|
| `openWorkPreview(item)` | `workPreviewItem = resolved` | — | `entityPreviewItem = null` |
| `openEntityPreview(entity)` | — | `entityPreviewItem = entity` | `workPreviewItem = null` |
| `closeAllPreviews()` | both null | both null | — |
| `previewLinkedWork(work)` | → `openWorkPreview` | — | entity cleared |
| `previewLinkedEntity(entity)` | — | → `openEntityPreview` | work cleared |

---

## 체인 추적: Work A → Entity B → Work C

### 시나리오 (탐색 그리드 · 홈 · Preview 이웃)

```
1. openWorkPreview(A)
   state: workPreviewItem=A, entityPreviewItem=null
   UI: DashboardPreviewPanel(A)

2. neighbors.characters 탭 → onPreviewEntity(B)
   openEntityPreview(B)
   state: workPreviewItem=null, entityPreviewItem=B
   UI: EntityDashboardPreviewPanel(B)   ← Work A 패널 사라짐

3. neighbors.connectedWorks 탭 → onPreviewWork(C)
   openWorkPreview(C)
   state: workPreviewItem=C, entityPreviewItem=null
   UI: DashboardPreviewPanel(C)       ← Entity B 패널 사라짐
```

**Work A 맥락:** 2단계에서 **완전 소실**. 사용자는 C만 보고 A에서 왔는지 알 수 없음.

### UI 렌더 조건 (`home_shell_body.dart` L431–455)

```dart
if (workPreviewItem != null && !workbench.hasOpenDetail)
  DashboardPreviewPanel(...)
if (entityPreviewItem != null && !workbench.hasOpenDetail)
  EntityDashboardPreviewPanel(...)
```

- Work·Entity 패널 **동시 표시 불가**
- Workbench 열림 시 Preview **전체 숨김**

---

## 맥락 복구 가능 경로 (코드상)

| 경로 | Work A 복귀 가능? |
|------|-------------------|
| Preview 「뒤로」 버튼 | ❌ 없음 |
| Preview 스택 | ❌ 없음 |
| `RecentExplorationStore` | ⚠️ 간접 — 사이드바·계속 탐험 (순서만, 부모 관계 없음) |
| Workbench 탭 레일 | ⚠️ Workbench에 A 탭 열려 있으면 복귀 (Preview 아님) |
| 브라우저식 닫기 | Preview `onClose` → 전체 닫기만 |

`RecentExplorationStore` (`recent_exploration_store.dart`): 최근 20키, **부모-자식 관계 없음**. A→B→C 탐색 후 목록은 `[C, B, A, ...]`일 수 있으나 **체인 UI는 없음**.

---

## Workbench 진입 시 맥락

```
openEntityFromPreview()
  → closeAllPreviews()
  → workbenchCoord.openEntity(entity)
  → hasOpenDetail=true → Preview 미렌더
```

Preview에서 「기록하기」 후: **모든 Preview 상태 삭제**. Workbench만 남음.

Work `openWorkFromPreview()` 동일.

---

## R3-C Wiki 탐험과 스택

`handleWikiLinkTap` (R3-C):

```dart
workbench.showBrowse();
onOpenWork: openWorkPreview(...)
onOpenEntity: openEntityPreview(...)
```

Workbench Sanctum에서 wiki 탭 → browse 모드 + **새 Preview**.  
이전 Preview는 이미 단일 슬롯 교체로 소실. Workbench 탭은 유지.

---

## Work Preview vs Entity Preview — 패리티

| 항목 | Work | Entity |
|------|------|--------|
| 이웃 → 반대 타입 Preview | ✅ `onPreviewEntity` | ✅ `onPreviewWork` |
| 자기 타입 이웃 체인 | ✅ connected works | ✅ persons 등 |
| 빈 연결 CTA | ✅ R3-C | ✅ `onRecordCta` |
| 상호 배타 | ✅ | ✅ |

**체인 동작은 대칭이나, 둘 다 단일 슬롯 한계를 공유.**

---

## 탐험 루프 영향 분석

### 루프 단계별

| 단계 | 현재 | 맥락 유지 |
|------|------|-----------|
| 발견 (Home/Search) | Preview | ✅ |
| 연결 탐색 (이웃 탭) | Preview 체인 | ⚠️ 1단계만 기억 |
| 기록 (Workbench) | Sanctum | ✅ (탭 레일) |
| 새 발견 (저장 후) | 수동 Preview 재오픈 | ❌ 자동 없음 |

### 끊김 지점

| # | 지점 | 심각도 |
|---|------|--------|
| 1 | `openEntityPreview` clears Work | **높음** |
| 2 | `openWorkPreview` clears Entity | **높음** |
| 3 | Workbench 진입 clears all Preview | **중간** (의도적) |
| 4 | 링크 저장 후 neighbors 자동 갱신 Preview 없음 | **중간** |
| 5 | 뒤로 가기 UI 없음 | **중간** |

---

## 설계 옵션 (구현 후보 — Audit만)

### 옵션 A: Preview Stack (권장)

```dart
List<PreviewFrame> previewStack; // {work?, entity?} discriminated

void pushEntityPreview(entity) {
  if (workPreviewItem != null || entityPreviewItem != null)
    stack.add(currentFrame);
  showEntity(entity);
}

void popPreview() {
  if (stack.isEmpty) closeAll();
  else restore(stack.removeLast());
}
```

UI: 패널 헤더 `← 이전` + 현재 제목.  
**장점:** A→B→C 맥락 복구, 320px 유지.  
**위험:** 상태 복잡도, Workbench와 상호작용 정의 필요.

### 옵션 B: Breadcrumb (경량)

`Work A › Entity B` 텍스트 + 각 segment 탭으로 해당 Preview 복원 (스택 없이 root만 기억).  
**장점:** 구현 작음.  
**단점:** C 진입 시 A 직접 복귀 어려움.

### 옵션 C: Dual Preview (비권장)

Work + Entity 패널 동시 표시 (640px+).  
**단점:** 레이아웃·좁은 화면.

### 옵션 D: Recent Exploration as Back (최소)

Preview 헤더에 「최근: Work A」칩 → `openWorkPreview(A)`.  
**장점:** `RecentExplorationStore` 재사용, 스택 없음.  
**단점:** 부모 관계 보장 안 됨.

---

## 권장안 (R3-D 구현 Sprint)

| 우선순위 | 안 | 이유 |
|----------|-----|------|
| **P3-1** | 옵션 A (스택 + 뒤로) | 체인 맥락 직접 해결 |
| P3-2 | 저장 후 Preview 자동 리프레시 (선택) | 루프 닫기 |
| 보류 | Dual Preview | 비용 대비 낮음 |

### 스택 + Workbench 규칙

| 이벤트 | 스택 동작 |
|--------|-----------|
| 이웃 탭 (탐험) | `push` 현재 → 새 Preview |
| 뒤로 | `pop` |
| Workbench 진입 | `clear stack` + close preview (현행 유지) |
| `onClose` | `pop` 또는 clear (정책 결정 필요) |

---

## 성공 기준 (P3)

1. Work A → Entity B 후 **「이전」** 으로 Work A Preview 복귀 가능.
2. A→B→C 3단계 체인 후 B로 한 단계 복귀 가능.
3. Workbench 진입 시 스택 초기화 (편집 모드 분리 유지).

---

## 루프 완성도 추정

| 영역 | 현재 | P2 후 | P2+P3 후 |
|------|------|-------|----------|
| Entity Workbench 탐험 | 40% | 85% | 85% |
| Preview 체인 맥락 | 30% | 30% | **80%** |
| **전체 루프** | **75~80%** | **83~88%** | **90~92%** |

---

## Audit 결론

| 항목 | 판정 |
|------|------|
| Preview Stack 존재 여부 | **없음** (단일 슬롯) |
| Work A 맥락 유지 | **불가** |
| `previewLinkedWork/Entity` | push 아닌 **replace** |
| 구현 난이도 | 중간 (컨트롤러 + 패널 헤더) |
| 데이터 변경 | **없음** |

P2(Entity Workbench)와 P3(Preview Stack)를 순차 구현 시 Sprint 목표 **90%+** 달성 가능.

---

## 관련 코드 앵커

| 심볼 | 파일 | 라인(대략) |
|------|------|------------|
| `openWorkPreview` | `home_shell_controller.dart` | 431–437 |
| `openEntityPreview` | `home_shell_controller.dart` | 460–465 |
| `previewLinkedEntity` | `home_shell_controller.dart` | 485–487 |
| Preview 렌더 | `home_shell_body.dart` | 431–455 |
| `onPreviewEntity` 배선 | `dashboard_preview_panel.dart` | 203 |
| `onPreviewWork` 배선 | `entity_dashboard_preview_panel.dart` | 201 |
