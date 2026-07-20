# Release Readiness Checklist — Steam v1

> **Status:** Historical snapshot
>
> 이 문서는 특정 시점(2026-06-19)의 release-readiness snapshot이다.
> 현재 Steam 출시 상태와 판정은 active Steam 문서를 따른다:
> [STEAM_RELEASE.md](../active/STEAM_RELEASE.md) ·
> [STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](../active/STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md).
> 당시 체크 결과·판정·증거는 덮어쓰지 않는다.

> **지위 (당시):** M2→M3 출시 게이트 **운영 SSOT**
> **갱신:** 2026-06-19 (Release 리허설 · @10048 · CDN push)
> **상위 (당시):** [ROADMAP.md](../../ROADMAP.md) M2 · [m2-steam-store-page.md](programs/m2-steam-store-page.md)

---

## 1. 출시 가능 정의

**M3 출시 = 아래 6개 조건 모두 충족**

| ID | 조건 | 상태 (2026-06-19) |
|----|------|:-----------------:|
| R1 | Steam v1 기능 동결 ([ROADMAP](../active/ROADMAP.md) §체크리스트) | ✅ |
| R2 | 자동 게이트 green (§2) | ✅ |
| R3 | P0 수동 QA 12/12 (§3) | 🔶 Release 빌드 기준 재확인 권장 |
| R4 | Steamworks depot·스토어·IAP (§4) | ✅ |
| R5 | 카탈로그·검색 스토어 약속 일치 (§5) | 🔶 CDN 10k 배포·스토어 카피 정합 |
| R6 | 법무·Privacy URL (§6) | ✅ |

**범례:** ✅ PASS · 🔶 부분 · ⏳ 미착수 · ❌ FAIL

---

## 2. 자동 게이트 (G-AUTO)

**주간 릴리스 리허설 — Release 빌드 전 필수**

```powershell
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\dart.bat run tool/ci_registry_check.dart
C:\src\flutter\bin\dart.bat run tool/preflight_check.dart
C:\src\flutter\bin\dart.bat run tool/quality_gate.dart --release
C:\src\flutter\bin\dart.bat run tool/quality_gate.dart --locale-minimum
C:\src\flutter\bin\dart.bat run tool/coverage_dashboard.dart
```

| # | 게이트 | Pass 기준 | 2026-06-19 |
|---|--------|-----------|:----------:|
| G1 | `flutter test` | 0 fail | ✅ **335/335** |
| G2 | `ci_registry_check` | exit 0 | ✅ (10048 works) |
| G3 | `preflight_check` | 4 step OK | ✅ |
| G4 | `quality_gate --release` | RB1·RB2 PASS | ✅ invalid_en=0 |
| G4b | `quality_gate --locale-minimum` | ko≥99% · en 100% | ✅ 10048/10048 |
| G5 | `flutter analyze lib/` | 0 error | ✅ (33 info/warn, 0 error) |
| G6 | Release 빌드 | exe cold start | ✅ `build\windows\x64\runner\Release\akasha.exe` |

### CI 갭 (출시 전 close)

| 항목 | 현재 | 목표 |
|------|------|------|
| `quality_gate --strict` in CI | ✅ | `flutter_ci.yml` |
| `preflight_check` on registry PR | ✅ `registry_check.yml` | — |
| `flutter test` in CI | ✅ 305+ | `flutter_ci.yml` |
| Windows Release build in CI | ❌ | 수동 `build_release.ps1` |
| `sw1_a_validation` in CI | ❌ | `dogfood_precheck.ps1` |

### 2026-06-10 audit — 수정 완료

| 이슈 | 조치 |
|------|------|
| `discovery_review_test` — `draftWithoutAnilist` API drift | → `draftWithoutSpine` |
| `product_value_review_test` — AniList→ExternalSpine rename | 필드·enum 갱신 |
| `steam_v1_bundle_test` — 430 hardcode | manifest `entryCount` 동적 검증 |

---

## 3. P0 수동 QA (G-QA)

**Release 빌드 · 깨끗한 Windows · 볼트 미연결 시작**

| ID | 시나리오 | 자동 커버 | 수동 | 결과 |
|----|----------|-----------|:----:|:----:|
| Q01 | 첫 실행 CDN sync | `steam_v1_bundle_test` | ☑ | ✅ |
| Q02 | 볼트 연동 → `.md` | `vault_archive_test` | ☑ | ✅ |
| Q03 | 검색 → 담기 (md auto) | `library_membership_apply` T28 | ☑ | ✅ |
| Q04 | 우클릭 popover (ArchiveThenAdd 없음) | `release_p0_qa_test` Q04 | ☑ | ✅ |
| Q05 | 카드 우클릭 메뉴 (키보드 단축키 v1.1로 연기) | `release_p0_qa_test` Q05 | ☑ | ✅ 우클릭 · 단축키 제거 |
| Q06 | DnD-A md 없음 | `library_membership_apply` T34 | ☑ | ✅ |
| Q07 | Case D IP tristate | `franchise_library_scope_test` | ☑ | ✅ |
| Q08 | E9 멤버 관리 | `personal_library_membership_service_test` | ☑ | ✅ |
| Q09 | 외부 `.md` watch | `release_p0_qa_test` Q09 | ☑ | ✅ |
| Q10 | IAP 테마 잠금 UI | `entitlement_service_test` | ☑ | ✅ |
| Q11 | v1 제외 UI (회상 등) | `release_p0_qa_test` Q11 | ☑ | ✅ |
| Q12 | 오프라인 번들 검색 | `fusion_search_test` 등 | ☑ | ✅ |

**기록:** Pass/Fail·빌드 hash·스크린샷 → 아래 §8 QA 로그

---

## 4. Steamworks (G-STEAM)

SSOT: [m2-steam-store-page.md](programs/m2-steam-store-page.md)

| # | 작업 | 상태 |
|---|------|:----:|
| S1 | Partner 앱 등록 | ✅ |
| S2 | Store page ko/en | ✅ |
| S3 | Tags·genre·Coming Soon | ✅ |
| S4 | 스크린샷 5~8장 | ✅ |
| S5 | Windows depot 업로드 | ✅ |
| S6 | Playtest branch smoke | ✅ |
| S7 | IAP SKU 2종 등록 | ✅ |
| S8 | `EntitlementService` ← Steam microtxn | ✅ |
| S9 | Privacy policy URL | ✅ [privacy.md](policy/privacy.md) |

**Release 빌드 경로:** `build\windows\x64\runner\Release\`

---

## 5. 카탈로그·검색 (G-CATALOG)

| # | 체크 | 기준 | 2026-06-19 |
|---|------|------|:----------:|
| C1 | manifest `entryCount` = 번들 | `steam_v1_bundle_test` | ✅ **10048** (CDN push) |
| C2 | dedupe | `dedupe_linter` | ✅ 0 |
| C3 | 스토어 숫자 = manifest | m2 카피 「10k+」 | 🔶 스토어 카피 갱신 필요 |
| C4 | 대표 검색 20건 recall@10 | ≥ 0.8 | ⏳ |
| C5 | SD3 Pause 조건 | dedupe·quality·SW1 | ✅ green |

---

## 6. 법무·정책 (G-COPY)

| # | 항목 | 상태 |
|---|------|:----:|
| L1 | Tier 1 포스터 미제공 | ✅ |
| L2 | `data_policy_linter --strict` | ✅ |
| L3 | 스토어 카피 v1.1 기능 미언급 | ⏳ 검수 |
| L4 | IAP = cosmetic only | ⏳ Steamworks |
| L5 | Privacy URL | ✅ [privacy.md](policy/privacy.md) |

---

## 7. 출시 blocking 백로그

> **결정 (2026-06-13):** 스팀 스토어 세팅 및 데포 업로드는 이미 완료되었습니다. 정식 릴리즈 이전에 **Wave 1 구조 리팩토링**을 전면 완수하고 최종 출시하는 방향으로 로드맵을 수정합니다.

| 우선 | 항목 | 담당 | 상태 |
|:----:|------|------|:----:|
| **P0** | **ADR-007 가드레일 문서 수립** | 아키텍트 | ✅ 완료 |
| **P0** | **Wave 1 (Home 해부) 리팩토링** — shell **40줄** (목표 ≤250) | 엔지니어링 | ✅ 완료 |
| **P1** | **Sprint B** — 품질 다듬기 ([phase1-work-e2e-plan](programs/phase1-work-e2e-plan.md)) | 제품 | **진행** |
| — | **M3 Steam Release** | 제품 | ⏸️ **보류** — 품질 Ready 시 |

---

## 8. QA 로그

| 일자 | 빌드 | P0 | G-AUTO | 메모 |
|------|------|:--:|:------:|------|
| 2026-06-10 | — | 0/12 | 4/4 | 자동 게이트 baseline · 테스트 3건 drift 수정 |
| 2026-06-10 | Release exe | 0/12 | 6/6 | test 254 · build OK · P0 auto 4건 · deprecated dialog 삭제 |
| 2026-06-13 | Release exe | 12/12 | 6/6 | 스팀 데포 업로드 및 수동/자동 QA 전수 합격 |
| 2026-06-14 | Release exe | — | 6/6 | Sprint A1 — test 271 · build OK |
| 2026-06-19 | Release exe | — | 7/7 | test **335** · preflight · locale-minimum · build OK · akasha-db CDN push |

---

## 9. 주간 루틴

**월:** §1 상태표 갱신 · blocking 카운트  
**금:** §2 릴리스 리허설 → `project-status-snapshot.md` 동기화

---

## 10. 문서 맵

| 문서 | 역할 |
|------|------|
| **본 문서** | 출시 게이트 SSOT |
| [project-status-snapshot.md](project-status-snapshot.md) | Registry·Gate 숫자 |
| [m2-steam-store-page.md](programs/m2-steam-store-page.md) | 스토어 카피·스크린샷 |
| [catalog-growth-charter.md](programs/catalog-growth-charter.md) | 카탈로그 확장 정책 |

---

## 11. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | 1차 baseline audit · G-AUTO green · P0 미실행 |
