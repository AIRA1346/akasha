# Cleanup Inventory — Keep / Delete / Defer

> **작업용** — [repo-cleanup-plan.md](programs/repo-cleanup-plan.md) Phase 0 산출  
> **갱신:** 2026-06-12 · 정리 완료 후 `docs/archive/` 이동 또는 삭제

---

## 1. 코드

| ID | 경로 | 판정 | call site | 비고 |
|----|------|:----:|-----------|------|
| C01 | `lib/screens/my_library_screen.dart` | **Delete** | 0 | analyze **error 7** · import 깨짐 |
| C02 | `showAddToLibrarySheet` (`work_library_menu.dart`) | **Delete** | 0 | `@Deprecated` wrapper |
| C03 | `EntitlementService.purchase()` | **Delete** | 0 | → `purchaseCosmetic` only |
| C04 | `archive_then_add_dialog.dart` | — | — | ✅ 이미 삭제 (804accb) |
| C05 | `lib/models/sample_data.dart` | **Keep** | `home_screen` L198 | 볼트 없을 때 데모 |
| C06 | `TodayRecallCard` / `RecallPicker` | **Keep** | `home_screen` (flag off) | v1.1 |
| C07 | `home_screen.dart` (~1390줄) | **Defer** | — | 분할은 별도 트랙 |
| C08 | `work_detail_workspace.dart` | **Defer** | — | E2 워크벤치 |
| C09 | `fusion_search_dialog.dart` | **Defer** | — | 서비스 추출 백로그 |

---

## 2. tool / untracked

| ID | 경로 | 판정 | 비고 |
|----|------|:----:|------|
| T01 | `tool/discovery/anilist_client.dart` | **Delete** | untracked · active fetch 없음 |
| T02 | `tool/discovery/anilist_strip.dart` | **Keep** | removal pipeline |
| T03 | `tool/discovery/anilist_removal_*` | **Keep** | test·CLI |
| T04 | `tool/purge_anilist_bulk.dart` | **Keep** | CI·정책 |
| T05 | `tool/migrate_anilistcdn_posters.dart` | **Defer** | legacy migration · 주석만 |
| T06 | `discovery_source_fetch.dart` | **Keep** | anilist → UnsupportedError ✅ |

---

## 3. 문서 Tier A drift

| ID | 파일 | 현재 | 목표 | 판정 |
|----|------|------|------|:----:|
| D01 | `README.md` L60,66 | 430 | 490 / manifest | **Fix** |
| D02 | `docs/README.md` L3 | Registry 430 | 490 | **Fix** |
| D03 | `ROADMAP.md` L32 | 현재 430작 | 490 | **Fix** |
| D04 | `ROADMAP.md` L86 | test 96/96 | 254 | **Fix** |
| D05 | `project-status-snapshot.md` L42 | 250/250 | 254 | **Fix** |
| D06 | `product-vision.md` | 430+ (§7) | 490+ | **Fix** |
| D07 | `m2-steam-store-page.md` | 490+ | — | ✅ OK |
| D08 | `release-readiness-checklist.md` | 254 | — | ✅ OK |
| D09 | `project-status-snapshot.md` L27,34 | 「430 결정」문맥 | 각주 유지 | **Keep** (역사) |
| D10 | `ROADMAP.md` L20,33,83,99,142 | 완료·결정 문맥 430 | 각주 | **Keep** (역사) |

---

## 4. 문서 Tier B

| ID | 파일 | 판정 | 조치 |
|----|------|:----:|------|
| B01 | `product/my-library-design.md` | **Fix** | As-Is `MyLibraryScreen` → 통합 홈 모드 |
| B02 | `curated-personal-library-plan.md` | **Fix** | 헤더: 완료 vs E2/polish 백로그 분리 |
| B03 | `unified-library-add-flow-plan.md` | **Fix** | §2.3 historical 표기 |
| B04 | `curated-library-membership-ui-plan.md` | **Keep** | 이미 완료 표기 |

---

## 5. analyze (2026-06-12)

| 수준 | 건수 | 처리 |
|------|:----:|------|
| error | 7 | C01 삭제 → **0 예상** |
| warning | 9 | Phase 1.5 |

| 파일 | 이슈 |
|------|------|
| `my_library_screen.dart` | error ×7 → **Delete** |
| `sample_data.dart` | unused import |
| `detail_profile_section.dart` | unused import |
| `home_screen.dart` | `_isLoading` unused |
| `franchise_fusion_service.dart` | unused local ×2 |
| `my_library_pipeline.dart` | unused import |
| `works_registry.dart` | unnecessary `!` |
| `browse_dashboard_sections.dart` | unused import |
| `work_tab_rail.dart` | unused import |

---

## 6. git

| 항목 | 상태 |
|------|------|
| branch | `main` · origin +2 commits |
| untracked | `tool/discovery/anilist_client.dart` → T01 Delete |

---

## 7. 처리 체크 (Phase 1~3)

| ID | 완료 |
|----|:----:|
| C01 | ☐ → ✅ |
| C02 | ☐ → ✅ |
| C03 | ☐ → ✅ |
| T01 | ☐ → ✅ |
| Phase 1.5 warnings | ☐ → ✅ |
| D01~D06 | ☐ → ✅ |
| B01~B03 | ☐ → ✅ |
| G-CLEAN 전체 | ✅ (test 254 · analyze error/warning 0) |
