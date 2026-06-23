# R3-F Preview Stack Extension — Audit

> **갱신:** 2026-06-22  
> **방법:** `home_shell_controller.dart`, `home_shell_body.dart` 호출 경로 실측  
> **코드 수정:** Audit 후 P1-A/P1-B

---

## 정책 (목표)

| 상황 | API | Stack |
|------|-----|-------|
| 새 탐험 시작 (Preview 없음) | `openWorkPreview` / `openEntityPreview` | **clear** |
| 탐험 계속 (Preview 열림) | `previewLinkedWork` / `previewLinkedEntity` | **push** |

---

## Controller API (현재)

| 함수 | push | stack clear |
|------|:----:|:-----------:|
| `openWorkPreview(item)` | false | ✅ |
| `openEntityPreview(entity)` | false | ✅ |
| `previewLinkedWork(work)` | true | — |
| `previewLinkedEntity(entity)` | true | — |

`hasOpenPreview` — **R3-F에서 추가** (`workPreviewItem != null || entityPreviewItem != null`).

---

## Home Dashboard — 섹션별 클릭 (Audit: R3-F 전)

| 섹션 | 콜백 배선 | 현재 | 목표 |
|------|-----------|:----:|:----:|
| 계속 탐험하기 | `onPreviewWork` / `onPreviewEntity` | replace | navigate |
| 오늘의 연결 | `onOpenWork` / `onOpenEntity` | replace | navigate |
| 최근 발견 | `onPreviewWork` | replace | navigate |
| 최근 기록 | `onPreviewWork` | replace | navigate |

**파일:** `home_dashboard_view.dart` → `home_shell_body.dart` L498–510

Preview 패널 이웃 | `previewLinked*` | push | ✅ (R3-D)

---

## Knowledge Graph — 클릭 (Audit: R3-F 전)

| 대상 | 콜백 | 현재 | 목표 |
|------|------|:----:|:----:|
| 행 「열기」 | `onOpenWork` | replace | navigate |
| ExpansionTile neighbors Work | `onOpenWork` | replace | navigate |
| ExpansionTile neighbors Entity | `onOpenEntity` | replace | navigate |

**파일:** `knowledge_graph_view.dart` → `home_shell_body.dart` L484–495

---

## 기타 Preview 진입 (범위 외 — replace 유지)

| 진입점 | API | R3-F |
|--------|-----|------|
| 탐색 그리드 (Browse) | `openWorkPreview` | 유지 |
| Entity 갤러리 | `openEntityPreview` | 유지 |
| 검색 다이얼로그 | `openWorkPreview` | 유지 |
| Wiki (Sanctum) | `open*Preview` | 유지 |
| 사이드바 Recent | `openRecentExploreItem` | 유지 |

---

## 구현 설계 (P1)

### `HomeShellController`

```dart
bool get hasOpenPreview => ...;

void navigateWorkPreview(AkashaItem item) {
  if (hasOpenPreview) previewLinkedWork(item);
  else openWorkPreview(item);
}

void navigateEntityPreview(UserCatalogEntity entity) {
  if (hasOpenPreview) previewLinkedEntity(entity);
  else openEntityPreview(entity);
}
```

### 배선

| 위젯 | Work | Entity |
|------|------|--------|
| `HomeDashboardView` | `navigateWorkPreview` | `navigateEntityPreview` |
| `KnowledgeGraphView` | `navigateWorkPreview` | `navigateEntityPreview` |
| Preview 패널 이웃 | `previewLinked*` (변경 없음) | 동일 |
| Browse / Search | `open*Preview` (변경 없음) | 동일 |

---

## 예시 체인 (목표)

```
Home 카드 → Work A          replace, stack=[]
Preview 이웃 → Entity B     push,    stack=[A]
Preview 이웃 → Work C       push,    stack=[A,B]
Graph 「열기」→ Work D      push,    stack=[A,B,C]  (Preview 열린 상태)
← 이전 ×3                 A 복귀
```

Home에서 Preview 없이 Work A → replace.  
Graph에서 Preview 없이 Work X → replace.

---

## 성공 기준

1. Home 4섹션: Preview 열린 상태에서 탭 → stack push + `← 이전`
2. Graph: Preview 열린 상태에서 열기/이웃 → push
3. Preview 없을 때 Home/Graph 탭 → replace (stack clear)
4. Discovery / Link Index / Schema 변경 없음
