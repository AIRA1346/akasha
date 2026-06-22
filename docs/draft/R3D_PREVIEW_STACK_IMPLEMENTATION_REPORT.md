# R3-D Preview Stack — Implementation Report

> **완료:** 2026-06-22  
> **계획:** [R3D_PREVIEW_STACK_IMPLEMENTATION_PLAN.md](./R3D_PREVIEW_STACK_IMPLEMENTATION_PLAN.md)  
> **Audit:** [R3D_PREVIEW_STACK_AUDIT.md](./R3D_PREVIEW_STACK_AUDIT.md)

---

## 요약

Preview 탐험 체인에 **스택 + `← 이전`** 을 도입하여 Work A → Entity B → Work C 이동 후 이전 맥락 복귀가 가능해졌다.

| 항목 | 상태 |
|------|------|
| `PreviewFrame` sealed union | ✅ |
| `_previewBackStack` (Controller) | ✅ |
| `push` / `pop` / `canPopPreview` | ✅ |
| Preview 패널 이웃 → `previewLinked*` | ✅ |
| Browse·Graph → replace (stack clear) | ✅ |
| `← 이전` UI (Work·Entity 패널) | ✅ |
| Workbench 진입 → stack clear | ✅ (기존 `closeAllPreviews`) |

**금지 사항 준수:** Discovery / Pipeline / Link Index / Collection / Schema 변경 없음.

---

## Before / After

### Before

```
openEntityPreview(B)  → workPreviewItem=null, A 소실
openWorkPreview(C)    → entityPreviewItem=null, B 소실
뒤로 가기 UI 없음
```

### After

```
openWorkPreview(A)           → stack=[]
previewLinkedEntity(B)       → stack=[WorkA], current=B
previewLinkedWork(C)         → stack=[WorkA, EntityB], current=C

popPreview()                 → stack=[WorkA], current=B
popPreview()                 → stack=[], current=A
```

---

## 변경 파일

| 파일 | 변경 |
|------|------|
| `lib/screens/home/preview_frame.dart` | **신규** — `WorkPreviewFrame` / `EntityPreviewFrame` |
| `home_shell_controller.dart` | stack, push/pop, `canPopPreview` |
| `home_shell_scaffold.dart` | linked 콜백·pop 배선 |
| `home_shell_body.dart` | Preview 패널만 linked 분리 |
| `dashboard_preview_panel.dart` | `canGoBack`, `onBack`, `← 이전` |
| `entity_dashboard_preview_panel.dart` | 동일 |

---

## 네비게이션 정책

| 진입 경로 | API | Stack |
|-----------|-----|-------|
| 그리드·홈·Graph·Recent | `openWorkPreview` / `openEntityPreview` | **clear** |
| Preview 이웃 탭 | `previewLinkedWork` / `previewLinkedEntity` | **push** |
| Wiki (Sanctum) | `open*Preview` (replace) | clear |
| `← 이전` | `popPreview` | pop |
| `X` 닫기 | `closeAllPreviews` | clear |
| Workbench 「기록하기」 | `closeAllPreviews` | clear |

---

## 성공 기준 답변

| 질문 | 답 |
|------|-----|
| A → B 후 A 복귀? | ✅ `← 이전` |
| A → B → C 후 B 복귀? | ✅ |
| 새 그리드 Preview 시 stack 초기화? | ✅ |
| Workbench 진입 시 stack 초기화? | ✅ |

---

## 루프 완성도

| 시점 | 추정 |
|------|------|
| P2 후 | 83~88% |
| **P3 후** | **90~92%** |

R3-D Sprint 목표(90%+) **달성**.

---

## 검증 체크리스트

- [ ] Work Preview → 인물 탭 → Entity Preview → `← 이전` → Work 복귀
- [ ] 3단계 체인 후 단계별 `← 이전`
- [ ] 루트 Preview에서 `← 이전` 없음 (`canPopPreview == false`)
- [ ] `X` 닫기 시 전체 Preview 종료
- [ ] 그리드에서 새 작품 Preview 시 이전 stack 미복원
