# R3-F Preview Stack Extension — Implementation Report

> **완료:** 2026-06-22  
> **Audit:** [R3F_PREVIEW_STACK_EXTENSION_AUDIT.md](./R3F_PREVIEW_STACK_EXTENSION_AUDIT.md)

---

## 요약

Home Dashboard·Knowledge Graph 클릭을 `navigateWorkPreview` / `navigateEntityPreview`로 전환하여 Preview Stack 정책을 통일했다.

| 항목 | 상태 |
|------|------|
| P1-A Home → Stack 연동 | ✅ |
| P1-B Graph → Stack 연동 | ✅ |
| `hasOpenPreview` | ✅ |
| Browse / Search replace 유지 | ✅ |

---

## 정책

```
Preview 없음 → open*Preview (replace, stack clear)
Preview 있음 → previewLinked* (push)
```

---

## 변경 파일

| 파일 | 변경 |
|------|------|
| `home_shell_controller.dart` | `hasOpenPreview`, `navigateWorkPreview`, `navigateEntityPreview` |
| `home_shell_body.dart` | HomeDashboard + Graph → navigate 콜백 |
| `home_shell_scaffold.dart` | navigate 배선 |

---

## 배선 (구현 후)

| 표면 | Work | Entity |
|------|------|--------|
| Home 4섹션 | `navigateWorkPreview` | `navigateEntityPreview` |
| Knowledge Graph | `navigateWorkPreview` | `navigateEntityPreview` |
| Preview 이웃 | `previewLinked*` | `previewLinked*` |
| Browse / Search | `open*Preview` | `open*Preview` |

---

## 성공 기준

| # | 기준 | 달성 |
|---|------|:----:|
| 1 | Home 탭 + Preview 열림 → push | ✅ |
| 2 | Graph 열기/이웃 + Preview 열림 → push | ✅ |
| 3 | Preview 없을 때 Home/Graph → replace | ✅ |
| 4 | 데이터 계층 무변경 | ✅ |

---

## Dogfood 기여 (R3-E 후보 해소)

| R3-E 항목 | 상태 |
|-----------|------|
| D4 Graph/홈 replace → stack 소실 | ✅ 해소 |

**루프 완성도 추정:** ~85% → **~88%**
