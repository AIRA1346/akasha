# Extensibility Hardening Plan — 확장성·글로벌·Phase 3 대비

> **상태:** E0~E2 ✅ · **E3 진행** (2026-06-16)  
> **근거:** 전체 설계 점검 (2026-06-16) · [ADR-007](../adr/ADR-007-app-layering.md) · [locale-catalog-policy](../policy/locale-catalog-policy.md)  
> **상위:** [app-architecture-refactor-plan.md](app-architecture-refactor-plan.md) Wave 2~4 · [architecture-evolution-phases.md](architecture-evolution-phases.md)  
> **제품 게이트:** [phase1-work-e2e-plan.md](phase1-work-e2e-plan.md) §2 — 「①~④ E2E에 도움이 되는가?」

---

## 1. 한 줄

**Wave 1(Home 해부) 다음은 리라이트가 아니라, ADR-007 경계·런타임 제목 모델·글로벌 로케일·문서/CI SSOT를 맞춰 Phase 3(Entity)·50k로 가는 비용을 낮춘다.**

---

## 2. 현재 위치

| 항목 | 상태 |
|------|------|
| Wave 1 Home 해부 | ✅ `home_shell.dart` 40줄 · View/Coordinator 분리 |
| Wave 2 Port 골격 | 🔶 `core/ports/` + `data/adapters/` 존재 · **런타임 대부분 singleton 직접 호출** |
| Registry @5181 · ADR-010 | ✅ eager-only 번들 · C2 관측 |
| Sprint B | 🔶 dogfood · friction |
| ADR-007 준수 | 🔶 `home_shell_controller` ~283줄 · `work_detail_workspace` ~721줄 |

**진단 요약**

| 축 | 등급 | 핵심 갭 |
|----|:----:|---------|
| 데이터 (akasha-db) | 🟢 | en 99.2% · franchise 수동·전량 번들 |
| 앱 레이어 | 🟡 | Port 미사용 · fat controller · `RegistryWork` in services |
| 글로벌 | 🟡 | `titles` 스키마 ✅ · `CatalogLocaleScope` ko/en 설정 · ARB 크롬 1차 |
| CI/문서 | 🟡 | 305 tests · checklist/snapshot stale · E2E 수동 |

---

## 3. 판단 기준 (모든 PR)

| | |
|--|--|
| **예** | ①~④ E2E 회귀 없음 · ADR-007 한 단계 전진 · Phase 3/글로벌 **막지 않게** 토대 |
| **아니오** | 추측 50k 설계 · Riverpod 전면 · `works_registry` 재작성 · Entity catalog 전면 |

**PR 규칙:** [app-architecture-refactor-plan.md §9](app-architecture-refactor-plan.md) — 행동 PR ≠ 구조 PR · 한 PR = coordinator 1개 또는 Port 1개.

---

## 4. 실행 Wave (E0~E4)

```
E0 SSOT 동기화 (1주)
  ↓
E1 도메인·표시 경계 (2~3주, 병렬 가능)
  ↓
E2 앱 오케스트레이션 축소 (3~4주)
  ↓
E3 글로벌 v1.1 (2~3주, Sprint D와 병행)
  ↓
E4 스케일 trigger 대비 (측정 후만)
```

---

## E0 — SSOT · CI 정합 (우선, 코드 최소)

**목표:** 「green」의 의미를 문서·CI·실측이 같게.

| ID | 작업 | 산출 | Exit |
|----|------|------|------|
| E0-1 | `project-status-snapshot.md` 갱신 | test **305** · @5181 · Sprint B 스크롤 fix | 수치 일치 |
| E0-2 | `release-readiness-checklist.md` CI 갭 표 | preflight on registry PR ✅ 반영 | stale ❌ 제거 |
| E0-3 | `sprint-b-friction-log.md` | 스크롤·sliver grid ✅ 기록 | B2 테이블 최신 |
| E0-4 | `app-architecture-refactor-plan.md` W1 완료·W2 포인터 | 본 문서 링크 | Wave 상태 명확 |
| E0-5 | (선택) `architecture-evolution-phases.md` §10 | 「다음: E1」 | ✅ |

**E0 Exit:** ✅ 2026-06-16

---

## E1 — Domain 경계 · 런타임 제목 (Phase 3·글로벌 토대) · **진행**

### E1-A `RegistryWork` 도메인 승격

| PR | 내용 | 상태 |
|----|------|:----:|
| E1-A1 | `lib/models/registry_work.dart` | ✅ |
| E1-A2 | `RegistryPort` → `models/` only | ✅ |
| E1-A3 | `RegistryShardLoader` merger callback · loader↔registry 순환 제거 | ✅ |
| E1-A3b | `registry_sync` ↔ `works_registry` 순환 | ⏳ E2 |

**DoD:** `rg "import.*works_registry" lib/core/ports` → facade 타입만 · loader 순환 **0** ✅

### E1-B 카탈로그 표시 제목 런타임 resolve

**문제:** `itemFromRegistryWork()`가 `displayTitle()`을 `AkashaItem.title`에 bake → 로케일 전환·글로벌 시 불일치.

| PR | 내용 | 상태 |
|----|------|:----:|
| E1-B1 | `resolveCatalogDisplayTitle` | ✅ |
| E1-B2 | `PosterCard` runtime resolve | ✅ |
| E1-B3 | test — locale switch · vault fallback | ✅ |
| E1-B4 | `HomeAutoArchive` bake 유지 | ✅ (UI만 runtime) |

**DoD:** `CatalogLocaleScope.setCurrent(en)` 후 카드 제목이 en fallback으로 바뀜 (test 1건). 볼트 저장 title 불변.

**의존:** E1-A 권장 (동시 가능).

---

## E2 — Application 축소 (ADR-007) · **진행**

**목표:** `home_shell_controller`를 **오케스트레이션 허브**에서 **조립(wiring)만** 하는 클래스로.

| ID | 추출 대상 | 신규 클래스 | 상태 |
|----|-----------|-------------|:----:|
| E2-1 | catalog prefetch · sync · contribution | `HomeCatalogCoordinator` | ✅ |
| E2-2 | vault init · auto-archive · watch | `HomeVaultCoordinator` | ✅ |
| E2-3 | workbench listener · open/save/delete | `HomeWorkbenchCoordinator` | ✅ |
| E2-4 | Dialog/Navigation/Browse/Wiring 분리 | `HomeShellController` **283줄** (676→283) | ✅ |

| PR | 내용 | 상태 |
|----|------|:----:|
| E2-5 | Port DI to coordinators | ⏳ |
| E2-6 | `work_detail_workspace` 분리 | ⏳ |

**DoD:** `home_shell_controller.dart` ≤200줄 · coordinator unit test 각 ≥1 — **줄 수 미달** (283) · catalog coordinator test ✅

---

## E3 — 글로벌 v1.1 (Sprint D · [locale-catalog-policy](../policy/locale-catalog-policy.md)) · **진행**

### E3-A 앱 로케일

| PR | 내용 | 상태 |
|----|------|:----:|
| E3-A1 | `main.dart` — `CatalogLocalePreferences.loadInitial()` · OS fallback | ✅ |
| E3-A2 | Vault 설정 — 「표시 언어」`ko` / `en` (SharedPreferences) | ✅ |
| E3-A3 | `l10n/` ARB · `lib/generated/l10n/` — **크롬만** | ✅ |
| E3-A4 | BrowseView 로딩·빈 상태·footer 1차 이전 | ✅ |

**비목표:** 작품명 번역은 `titles` · UI 문자열만 ARB.

### E3-B 데이터 커버리지

| PR | 내용 |
|----|------|
| E3-B1 | `coverage_dashboard` — `titles_ko` KPI 추가 (`title` 또는 `titles.ko`) |
| E3-B2 | `titles.en` 39건 remediate 배치 |
| E3-B3 | `quality_gate` / release — ko+en **minimum** 문서화 (strict는 en 유지) |

**DoD:** en 100% · ko KPI PASS · en UI dogfood OK.

**의존:** E1-B 완료 후 E3-A 효과 검증이 명확.

---

## E4 — 스케일 trigger (측정 후만)

**시작 조건 (하나라도):** `entryCount` >10k · search_index 번들 >15MB · franchise JSON >5MB · cold start parse >200ms.

| ID | 작업 | 선행 문서 |
|----|------|-----------|
| E4-1 | search_index **번들 제외 / CDN-only** ADR 초안 | ADR-010 flip 조건 |
| E4-2 | `RegistryPort` page API (browse window formalize) | architecture-evolution Phase 2.4 |
| E4-3 | Franchise 자동 후보 + maintainer 검수 워크플로 | scale-5k-risk §franchise |
| E4-4 | 검색 선형 스캔 → category index 구조화 (필요 시) | registry-scaling-review |

**지금 하지 않음** — C2 @5181 무위험 확인됨.

---

## 5. 테스트 · CI (각 Wave Exit)

| Wave | 테스트 | CI |
|------|--------|-----|
| E0 | — | — |
| E1 | `resolveCatalogDisplayTitle` · locale switch widget test | `flutter test` |
| E2 | coordinator unit (fake port) | 동일 |
| E3 | l10n smoke · `titles_ko` gate | (선택) `sw1_a` on registry PR |
| E4 | perf baseline script | — |

**중기 (E3 후):** `integration_test` 1플로우 — 검색 → 담기 → vault 저장 → 재시작 후 workId 유지.

---

## 6. 일정 · 병행

| 병행 가능 | 불가 |
|-----------|------|
| E0 ‖ Sprint B dogfood | E2 controller 분할 ‖ 대규모 UI feature |
| E1-A ‖ E1-B (후반) | E4 ‖ E1 (측정 없이) |
| E3 ‖ Sprint B friction 수정 | Riverpod 전면 |

**권장 순서:** E0 → E1-A → E1-B → E2-1~4 → E3 → (Sprint B3 Ready) → E4 trigger 시

**주당 부담:** 구조 PR 1~2개 · 행동 PR(Sprint B) 별도.

---

## 7. 성공 지표

| # | 지표 | 목표 |
|:-:|------|------|
| S1 | `home_shell_controller` 줄 수 | ≤200 |
| S2 | registry 서비스 순환 import | 0 |
| S3 | Presentation에서 `WorksRegistry.` 직접 호출 | coordinator 경유로 **50%↓** (E2 Exit) |
| S4 | `titles.en` populated | 5181/5181 |
| S5 | en/ko UI dogfood | 본인 OK |
| S6 | `flutter test` | 0 fail |
| S7 | Phase 3 착수 시 Entity UI 추가 파일 | `features/*` + Port만 |

---

## 8. 하지 않는 것 (명시)

- `works_registry` 전면 재작성
- Riverpod / Bloc 전면 도입
- akasha-db 스키마 breaking change
- Entity catalog (Phase 3 전)
- Memory Core / SQLite (Phase 6)
- M3 Steam Release 일정 고정

---

## 9. 관련 문서

| 문서 | 역할 |
|------|------|
| [app-architecture-refactor-plan.md](app-architecture-refactor-plan.md) | W1~W4 원본 · 파일 상한 |
| [locale-catalog-policy.md](../policy/locale-catalog-policy.md) | titles · fallback · 로드맵 |
| [phase1-work-e2e-plan.md](phase1-work-e2e-plan.md) | Sprint B/D · M3 |
| [scale-5k-risk-analysis.md](../validation/scale-5k-risk-analysis.md) | E4 trigger 근거 |
| [sprint-b-friction-log.md](sprint-b-friction-log.md) | friction → E3 입력 |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-16 | E2-4 coordinator 분리 완료 · E3-A1~A4 1차 구현 |
| 2026-06-16 | E0 ✅ · E1-A/B 1차 구현 |
