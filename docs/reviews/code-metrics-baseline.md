# Code Metrics Baseline — MVR Phase 0

> **일자:** 2026-06-12  
> **경로:** MVR (Minimum Viable Review) · [code-quality-review-plan.md](../programs/code-quality-review-plan.md) v2  
> **0.1~0.2:** [cleanup-inventory.md](../cleanup-inventory.md) · [release-readiness-checklist.md](../release-readiness-checklist.md) **인용** (재수집 생략)

---

## 1. 스냅샷 (2026-06-12)

| 항목 | 값 | 출처 |
|------|-----|------|
| `lib/**/*.dart` | 121 파일 | Phase 0 |
| `test/**/*.dart` | 67 파일 | Phase 0 |
| `tool/**/*.dart` | 113 파일 | Phase 0 (앱 검토 범위 **아님**) |
| `flutter test` | **254/254** PASS | release-readiness G1 |
| `flutter analyze lib/` | error **0** · warning **0** | cleanup G-CLEAN |
| Registry | **490** works | ci_registry_check |
| `home_screen` import | **70** | rg 2026-06-12 |
| `home_screen` 줄 수 | **1385** | PowerShell |
| `home_screen` private 메서드 | **~57** | rg `_` 패턴 |
| `testWidgets` | **10** (5 파일) | poster_card×2, release_p0×1, widget×1, work_info×1, work_library×5 |

---

## 2. 파일 크기 Top 20 (`lib/`)

| 순위 | 줄 | 파일 |
|:----:|---:|------|
| 1 | 1385 | `screens/home_screen.dart` |
| 2 | 650 | `screens/workbench/work_detail_workspace.dart` |
| 3 | 505 | `widgets/poster_card.dart` |
| 4 | 466 | `widgets/fusion_search_dialog.dart` |
| 5 | 444 | `widgets/work_library_panel.dart` |
| 6 | 412 | `services/franchise_fusion_service.dart` |
| 7 | 377 | `screens/home/dialogs/add_work_dialog.dart` |
| 8 | 376 | `services/works_registry.dart` |
| 9 | 363 | `widgets/web_image_search_dialog.dart` |
| 10 | 349 | `services/registry_shard_loader.dart` |
| 11 | 348 | `widgets/dashboard_sidebar.dart` |
| 12 | 345 | `screens/detail/detail_profile_section.dart` |
| 13 | 339 | `screens/detail_screen.dart` |
| 14 | 336 | `screens/home/dialogs/personal_library_edit_dialog.dart` |
| 15 | 325 | `services/file_service.dart` |
| 16 | 316 | `widgets/browse_dashboard_sections.dart` |
| 17 | 302 | `services/registry_sync_service.dart` |
| 18 | 284 | `models/catalog_contribution.dart` |
| 19 | 261 | `services/markdown_parser.dart` |
| 20 | 234 | `widgets/poster_image.dart` |

**500줄+:** 6개 (home, work_detail_workspace, poster_card, fusion_search, work_library_panel, franchise_fusion)  
**350~499줄:** 4개 (add_work_dialog, works_registry, web_image_search, registry_shard_loader)

---

## 3. 싱글톤·static 서비스 인벤토리 (testability)

| 서비스 | 패턴 | 테스트 훅 |
|--------|------|-----------|
| `AkashaFileService` | factory singleton | ❌ |
| `RegistrySyncService` | factory singleton | ✅ `setTextFetcherForTesting` · `resetForTesting` |
| `EntitlementService` | `instance` | ❌ (prefs 직접) |
| `CatalogContributionService` | `instance` | ❌ |
| `UserRegistryPreferences` | `instance` | ❌ |
| `WorksRegistry` | static map + loader | ❌ |
| `FranchiseRegistry` | static maps | ❌ |

**`@visibleForTesting` / `resetForTesting`:** `RegistrySyncService` 등 **소수** — 대부분 싱글톤은 mock 주입 불가.

---

## 4. i18n 준비도 (E6 샘플)

| 항목 | 관측 |
|------|------|
| ARB / l10n | **미도입** |
| UI 문자열 | `lib/` 전역 **한글 리터럴** (SnackBar·Dialog·라벨) |
| 고밀도 파일 | `home_screen`, `home_registry_sync`, `library_theme_picker`, dialogs/* |
| 정책 문구 | `CatalogPosterPolicy` 주석 — Tier1 no-poster |

**판정:** v1 Steam 한국어 우선 출시에는 문제 없음. 다국어는 **전면 grep + ARB 마이그레이션** 필요 (v1.1+).

---

## 5. tool/ 경계 (MVR 범위)

| 모듈 | MVR 조치 |
|------|----------|
| `tool/ci_registry_check.dart` | gate 통과 여부만 ✅ |
| `tool/preflight_check.dart` | gate 통과 여부만 ✅ |
| `tool/discovery/*` | E5 — **경로 추적만** (113파일 전수 검토 제외) |
| `akasha-db/shards` | preflight · manifest **490** 확인 |

---

## 6. Phase 0 DoD

- [x] Top 20 줄 수·import 핵심 수치
- [x] test/analyze — cleanup SSOT 링크
- [x] 싱글톤 인벤토리
- [x] i18n 정성 판정
- [x] tool 범위 명시

**다음:** [code-quality-structure-review.md](code-quality-structure-review.md) (Phase 1 MVR)
