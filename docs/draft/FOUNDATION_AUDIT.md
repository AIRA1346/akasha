# Foundation Audit — 기초 다지기 감사 (F0)

> **일자:** 2026-06-25 (F0) · **재검토:** 2026-06-30 (Post-P2 분해 SSOT)
> **지위:** Foundation Sprint 감사 SSOT (draft)  
> **상위:** [PROJECT_STATUS.md](../history/closure-2026-07/PROJECT_STATUS.md) · [CURRENT_STATE.md](../active/CURRENT_STATE.md)
> **레거시:** [LEGACY_REMOVAL_POLICY.md](LEGACY_REMOVAL_POLICY.md)

---

## 1. Executive Summary

| 항목 | 결과 (재검토 2026-06-30 · Post-P2 SSOT) |
|------|--------------------------------------|
| `flutter test` | **614/614 PASS** |
| `dogfood_precheck.ps1` | **PASS** |
| `flutter analyze lib` | **0 issue** |
| Release build | `build_release.ps1` OK |
| `origin/main` HEAD | **56d669f** |
| code/test baseline | **5526ce4** |
| SSOT baseline | **57c66fd** |
| Foundation F0~F4 | **✅ 완료** |
| Foundation P2 분해 | **P27~P31 + P2 배치** ✅ |
| P30 dialog 저장 widget test | **✅ 완료** (filter·validation·curated **4**) |
| B1 수동 dogfood | **✅ 완료** |

**판단:** Gate·Registry 건강. **계획된 Foundation P2 대형 파일 분해 완료** — 400줄+ 잔여는 `home_shell_body`·`markdown_body_editor` shell (parts 분리됨).

---

## 1-b. Vault Agent (2026-06-26)

| 항목 | 상태 |
|------|------|
| `VAULT_README.md` 자동 생성 | ✅ `2af7872` |
| `entity_path_index.json` | ✅ |
| Entity 제목 변경 → 파일 rename | ✅ |
| SSOT | [VAULT_AGENT_GUIDE.md](../active/VAULT_AGENT_GUIDE.md) |

## 2. F0 자동 검증 로그

| 단계 | 도구 | 결과 |
|------|------|:----:|
| 테스트 | `flutter test` | **614 PASS** |
| Registry | `ci_registry_check` | PASS (@10048) |
| Preflight | `preflight_check` | PASS |
| Recall | `sw1_a_validation` | 87/87 recall@10 |
| Release gate | `quality_gate --release` | PASS |

### F0-1 테스트 수정 (회귀)

| 파일 | 원인 | 조치 |
|------|------|------|
| `test/sanctum_html_exporter_test.dart` | `const` + `toMarkdownLine()` | `final`로 수정 |
| `test/views/home_dashboard_view_test.dart` | 제거된 `onVaultSettings` | 파라미터 삭제 |
| `test/work_detail_workspace_smoke_test.dart` | 완성도 바 «감상» 칩 중복 | `기록 완성도` assertion 추가 |

### 환경 이슈

- `build\unit_test_assets` Windows 잠금 → F0에서 디렉터리 삭제 후 해소.

---

## 3. 대형 파일 (400줄+, 2026-06-30 재실측 · Post-P2)

### 잔여 후보

| 줄 수 | 파일 | 우선 |
|------:|------|:----:|
| **503** | `markdown_body_editor.dart` | — (P26 parts 분리 완료) |
| **479** | `home_shell_body.dart` | P3 (P6 ✅, 추가 여지) |

### P2 분해 완료 (shell · code baseline `5526ce4`)

| 파일 | shell | commit | part / 비고 |
|------|------:|--------|-------------|
| `home_shell_scaffold` | **31** | `194db17` | layout·app bar·body·bottom nav |
| `home_dialogs_coordinator` | **124** | `955967e` | search·vault·capture·entity |
| `franchise_fusion_service` | **76** | `5526ce4` | fuse·slots·grouping·representative |

### P27~P31 분해 완료 (shell)

| 작업 | shell | part / 비고 |
|------|------:|-------------|
| P27 `dashboard_sidebar` | **152** | 8 part (nav·thumbnail·sections) |
| P28 R14-B tokens | — | poster·editor·sidebar 인라인 스타일 |
| P29 `browse_dashboard_sections` | **165** | 6 part + grid `KeyedSubtree`/`findChildIndexCallback` 유지 |
| P30 `collectible_collection_edit_dialog` | **73** | session·filter·curated·actions·delete parts |
| P31 `work_library_panel` | **162** | logic·header·library·hide·actions parts |

### 이전 분해 (P9~P26 요약)

| shell | 파일 | 비고 |
|------:|------|------|
| **278** | `entity_detail_workspace.dart` | P15 vault·links·persist |
| **273** | `work_detail_workspace.dart` | P15 |
| **~270** | `poster_card_layouts.dart` | P24 badges·meta·layouts |
| **156** | `home_shell_controller.dart` | P11 bundle·mixins |
| **126** | `poster_card.dart` | P9 style·layouts |
| **93** | `registry_shard_loader.dart` | P12 cache·search·shards·sync |
| **89** | `file_service.dart` | P13 paths·watch·scan·save |

> `markdown_body_editor` shell **503줄** + 6 editor parts (P26) + shortcuts part.

---

## 4. Sanctum 아카이빙 (C1~C4 + Post-C4)

| 단계 | 내용 | 상태 |
|:---:|------|:---:|
| C1 | wiki 칩 리치 미리보기 | ✅ |
| C2 | `# 👥 출연` 슬롯 | ✅ |
| C3 | 갤러리·이미지 DnD/붙여넣기·명장면 카드 | ✅ |
| C4 | 완성도 %·템플릿·HTML보내기 (Work) | ✅ |
| Post-C4 | Entity HTML·Sanctum 헤더 토큰·정책 §14 | ✅ |

---

## 5. 레거시 `TODO(remove)` (9건)

> **제거 조건 SSOT:** [LEGACY_REMOVAL_POLICY.md](LEGACY_REMOVAL_POLICY.md) (F4 ✅)

| 파일 | 건수 | F4 결정 |
|------|:----:|---------|
| `vault_work_journal_paths.dart` | 2 | v1.2+ G4~G7 충족 후 제거 |
| `works_registry.dart` | 2 | M3+2 릴리즈 · R2 동시 제거 |
| `registry_shard_loader.dart` | 2 | alias **889건 유지** · monolithic M3+2 |
| `registry_sync_service.dart` | 1 | R2 동시 제거 |
| `file_service.dart` | 1 | v1.2+ works 레이아웃 게이트 |
| `user_preferences.dart` | 1 | v1.0 **기본 false 고정** |

**M3 v1.0:** 코드 삭제 **없음** — 게이트만 확정.

---

## 6. Git · 원격

| 구분 | SHA | 비고 |
|------|-----|------|
| **`origin/main` HEAD** | **859cc35** | live tip |
| **code/test baseline** | **5526ce4** | scaffold `194db17` · dialogs `955967e` · fusion `5526ce4` · test **614** |
| **SSOT baseline** | **57c66fd** | Post-P2 분해 내용 반영 |

로컬/원격 **동기화 완료** (code). dirty = registry manifest 4개 (`generatedAt` only).

---

## 7. Foundation 로드맵 (F0~F4)

| Phase | 기간 | 내용 | 상태 |
|:---:|------|------|:---:|
| **F0** | 0.5~1일 | 기준선 감사·테스트 green | ✅ |
| **F1** | 1일 | SSOT 문서·B1 D7~D9 | ✅ |
| **F2** | 3~5일 | `work_sanctum_section_editor` 분해 · `work_detail_sanctum_ops` | ✅ |
| **F3** | 2~3일 | R14-B Preview·Save status·Neighbors 토큰 | ✅ |
| **F4** | 2일 | `TODO(remove)` 제거 조건표 · works 레이아웃 정책 | ✅ |

**의존성:** F0~F4 ✅ → **B1 수동 dogfood** (사용자) → M3 재개.

---

## 8. R14 잔여 (Post-F3)

| # | 항목 | 상태 |
|---|------|:---:|
| 1 | Preview 정보 계층 (`preview_work_panel_content`) | ✅ F3 |
| 2 | Neighbors `sectionTitle` 토큰 | ✅ F3 + Entity neighbors |
| 3 | Save status semantic 색 | ✅ |
| 4 | Sanctum hint·배너 | ✅ F3 |
| 5 | `preview_panel_chrome` | ✅ Post-F4 |
| 6 | Home·Dialog `Colors.grey` ~70파일 | ✅ R14-C (P3) — `lib/screens/home` 33 + home 위젯 24 |
| 7 | Workbench·Sanctum·Editor `Colors.grey` | ✅ R14-D (P4) — 19파일 · `lib` 전역 0건 |

**금지:** Discovery Engine · Preview stack 정책 · Save Return 문구 변경.

---

## 9. Post-Foundation 백로그 (에이전트)

| 우선 | 작업 | 상태 |
|:----:|------|:---:|
| P0 | analyze lint · FOUNDATION_AUDIT 갱신 | ✅ |
| P1 | `hasOpenWork` · `WorkTab` deprecated 제거 | ✅ |
| P1 | Entity neighbors · preview chrome 토큰 | ✅ |
| P2 | `entity_detail_workspace` 분해 | ✅ 796→**615** |
| P2 | `work_detail_workspace` 분해 | ✅ 857→**583** |
| P2 | `markdown_body_editor` 분해 | ✅ 730→**455** |
| P3 | R14-C Home·Dialog grey pass | ✅ 57파일 · `AkashaColors` semantic |
| P4 | R14-D Workbench·Sanctum grey pass | ✅ 19파일 · `lib` `Colors.grey` 0 |
| P5 | `home_dashboard_discovery_section` 분해 | ✅ 713→**248** + loader·cards |
| P6 | `home_shell_body` 분해 | ✅ 672→**471** + browse·center·preview |
| P7 | `catalog_entity_browse_view` 분해 | ✅ 694→**361** + loader·widgets |
| P8 | workspace UI part analyze 정리 | ✅ `setState`·private builder · lib 0 issue |
| P9 | `poster_card` 분해 | ✅ 668→**126** + style·layouts |
| P10 | `work_link_neighbors_sections` 분해 | ✅ 590→**207** + chrome·character·connected works |
| P11 | `home_shell_controller` 분해 | ✅ 615→**156** + bundle·mixins |
| P12 | `registry_shard_loader` 분해 | ✅ 587→**93** + cache·search·shards·sync mixins |
| P13 | `file_service` 분해 | ✅ 551→**89** + paths·watch·scan·save·bootstrap mixins |
| P14 | `fusion_search_dialog` · `entity_link_picker_dialog` | ✅ 621→**276** + tiles · 586→**256** + widgets·actions |
| P15 | `entity_detail` / `work_detail` workspace 재분해 | ✅ 673→**278** · 646→**273** + vault·links·persist |
| P16 | ADR-007 Port wiring 확대 (coordinator·presentation) | ✅ Home coordinator graph `VaultPort` 주입 · `vaultLinked`/`vaultPath` 스레딩 |
| P16b | Dialog·loader Port wiring 잔여 | ✅ vault·clipboard·add_work·entity_link_picker·catalog browse loader |
| P20 | R14-B spacing·radius·typo 토큰 (Home 핵심) | ✅ `dialogBody`·`settingsLabel`·`vaultBanner` · banner·picker·settings dialog · Preview/Graph/Sanctum 2차 |
| P21 | Workbench presentation `VaultPort` | ✅ `workbench_vault.dart` · archive·autosave·workspace·poster |

---

## 11. Foundation Phase 2 (M3 보류 · 2026-06-26~)

| 우선 | 작업 | 상태 |
|:----:|------|:---:|
| P12 | `registry_shard_loader` 분해 | ✅ |
| P13 | `file_service` 분해 | ✅ |
| P14 | `fusion_search_dialog` · `entity_link_picker_dialog` | ✅ |
| P15 | workspace 재안정화 (entity/work) | ✅ |
| P16 | ADR-007 Port wiring 확대 | ✅ |
| P16b | Dialog·loader Port wiring | ✅ |
| P20 | R14-B design tokens (Home 핵심) | ✅ 3차 · dashboard·journal·browse 전역 |
| P21 | Workbench presentation `VaultPort` | ✅ |
| P23 | `AppVault` + storage/widget Port | ✅ 3차 · adapter DI 완료 |
| P24 | `poster_card_layouts` 분해 | ✅ badges·meta·layouts |
| P26 | `markdown_editor_parts` 분해 | ✅ 6 part files |
| P27 | `dashboard_sidebar` 분해 | ✅ shell **152** · 8 part |
| P28 | R14-B tokens (poster·editor·sidebar) | ✅ |
| P29 | `browse_dashboard_sections` 분해 | ✅ shell **165** · 6 part |
| P30 | `collectible_collection_edit_dialog` 분해 | ✅ shell **73** · session + 7 part |
| P31 | `work_library_panel` 분해 | ✅ shell **162** · 5 part |
| P30 후속 | dialog 저장 플로우 widget test | ✅ filter·validation·curated **4** |
| P2 | `home_shell_scaffold` 분해 | ✅ shell **31** · `194db17` |
| P2 | `home_dialogs_coordinator` 분해 | ✅ shell **124** · `955967e` |
| P2 | `franchise_fusion_service` 분해 | ✅ shell **76** · `5526ce4` |

**금지:** M3 Steam · Discovery Engine · Preview stack · Save Return 정책.

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-30 | **Post-P2 SSOT** — scaffold·dialogs·fusion 분해 · SSOT **57c66fd** · code **5526ce4** · test **614** |
| 2026-06-30 | SSOT HEAD 정정 · SSOT baseline **04ce025** · P30 dialog test **48c8c39** |
| 2026-06-29 | **Post-P30 후속** — dialog 저장 widget test **4** · P30 dialog test commit **48c8c39** · test **614** |
| 2026-06-29 | **Post-P31** — P31 `work_library_panel` 분해 (**162** shell) · `origin/main` **0c92519** |
| 2026-06-29 | **Post-P30** — P27~P30 분해·P28 tokens 반영 · 400줄+ 재실측 · `origin/main` **9d17f75** |
| 2026-06-25 | F0 초안 — test 605 · precheck PASS |
| 2026-06-25 | F4 — LEGACY_REMOVAL_POLICY · 9건 게이트 |
| 2026-06-25 | Post-F4 재검토 — 대형 파일 재실측 · R14·백로그 · P0/P1 정리 |
| 2026-06-24 | P30 — `collectible_collection_edit_dialog` session + 7 part (**73** shell) |
| 2026-06-24 | P29 — `browse_dashboard_sections` 6 part (**165** shell) |
| 2026-06-24 | P28 — R14-B poster·editor·sidebar tokens |
| 2026-06-24 | P27 — `dashboard_sidebar` 8 part (**152** shell) |
| 2026-06-24 | P26 — `markdown_editor_parts` → status·intents·slash·field·find·toolbar parts |
| 2026-06-24 | P23 3차 — storage adapter `VaultPort` DI 완료 · `HomeVaultCoordinator` vault 주입 |
| 2026-06-24 | P22 — Home dashboard·journal·browse R14-B 3차 (`dashboardHero`·`nano`·`AppVault` colors) |
| 2026-06-24 | P16b — dialog·loader `VaultPort`/`vaultPath` wiring 완료 (`screens/home` `AkashaFileService` 0, `cacheKeyFor` static 제외) |
| 2026-06-26 | P16 — Home coordinator graph `VaultPort` wiring (`HomeVaultCoordinator`·wiring·browse·preview·workbench·dialogs·membership·library UI) · presentation `vaultLinked`/`vaultPath` 스레딩 |
| 2026-06-26 | P15 — `entity_detail` / `work_detail` workspace vault·links·persist part 분해 (**278** / **273** shell) |
| 2026-06-26 | P14 — `fusion_search_dialog` tiles·search · `entity_link_picker` widgets·actions · `FusionSearchEntityIcons` 공유 |
| 2026-06-26 | P13 — `file_service` paths·watch·scan·save·bootstrap mixin 분해 (**89줄** shell) · `VAULT_README.md` 스캔 제외 |
| 2026-06-26 | P12 — `registry_shard_loader` cache·search·shards·sync mixin 분해 (**93줄** shell) |
| 2026-06-26 | P11 — `home_shell_controller` bundle·mixins 분해 (**156줄** shell) |
| 2026-06-26 | P10 — `work_link_neighbors` chrome·layouts 분해 (**207줄** shell) |
| 2026-06-26 | Vault agent — VAULT_README · entity_path_index · `VAULT_AGENT_GUIDE` |
| 2026-06-24 | P9 — `poster_card` style·layouts 분해 (**126줄** shell) |
| 2026-06-24 | P8 — workspace UI part `setState` 위임 · `flutter analyze lib` 0 issue |
| 2026-06-24 | P7 — `catalog_entity_browse_view` loader·widgets 분해 (**361줄**) |
| 2026-06-24 | P6 — `home_shell_body` browse·center·preview 분해 (**471줄**) |
| 2026-06-24 | P5 — `home_dashboard_discovery_section` loader·cards 분해 (**248줄**) |
| 2026-06-24 | P4 R14-D — Workbench·Sanctum·Editor grey → `AkashaColors` (19파일, lib 전역 0) |
| 2026-06-24 | P3 R14-C — Home·Dialog `Colors.grey` → `AkashaColors` (57파일) |
| 2026-06-24 | P2 work workspace 완료 — draft bundle·sanctum·link session (**583줄**) |
| 2026-06-24 | P2 `markdown_body_editor` — undo/slash/find/insert ops · shortcuts part |
