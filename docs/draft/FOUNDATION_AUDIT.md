# Foundation Audit — 기초 다지기 감사 (F0)

> **일자:** 2026-06-25 (F0) · **재검토:** 2026-06-25 (Post-F4)  
> **지위:** Foundation Sprint 감사 SSOT (draft)  
> **상위:** [PROJECT_STATUS.md](../active/PROJECT_STATUS.md) · [CURRENT_STATE.md](../active/CURRENT_STATE.md)  
> **레거시:** [LEGACY_REMOVAL_POLICY.md](LEGACY_REMOVAL_POLICY.md)

---

## 1. Executive Summary

| 항목 | 결과 (재검토 2026-06-25) |
|------|--------------------------|
| `flutter test` | **610/610 PASS** |
| `dogfood_precheck.ps1` | **PASS** |
| `flutter analyze lib` | **0 issue** (P8 workspace UI part 정리 후) |
| Release build | `build_release.ps1` OK (`202236a`) |
| Git | `main` **origin 동기화** (`2af7872` push 완료) |
| Foundation F0~F4 | **✅ 완료** |
| B1 수동 dogfood | **✅ 완료** |

**판단:** Gate·Registry·Foundation Sprint는 건강. **R14 토큰화 완료.** Vault agent readme·path index ✅. 다음 병목: 대형 파일 분해·M3.

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
| 테스트 | `flutter test` | **605 PASS** |
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

## 3. 대형 파일 (600줄+, 2026-06-25 재실측)

| 줄 수 | 파일 | 비고 |
|------:|------|------|
| **583** | `work_detail_workspace.dart` | P2 ✅ (draft bundle·sanctum·link ops) |
| **615** | `entity_detail_workspace.dart` | P2 ✅ |
| **248** | `home_dashboard_discovery_section.dart` | P5 ✅ loader·cards 분리 |
| **471** | `home_shell_body.dart` | P6 ✅ browse·center·preview 분리 |
| 297 | `home_shell_body_center.dart` | P6 추출 |
| **361** | `catalog_entity_browse_view.dart` | P7 ✅ loader·widgets 분리 |
| **126** | `poster_card.dart` | P9 ✅ style·layouts 분리 |
| 590 | `work_link_neighbors_sections.dart` | P10 ✅ **207** + chrome·layouts |
| **93** | `registry_shard_loader.dart` | P12 ✅ **93** shell + cache·search·shards·sync |
| **89** | `file_service.dart` | P13 ✅ **89** shell + paths·watch·scan·save·bootstrap |
| **278** | `entity_detail_workspace.dart` | P15 ✅ + vault·links·persist parts |
| **273** | `work_detail_workspace.dart` | P15 ✅ + vault·links·persist parts |
| **276** | `fusion_search_dialog.dart` | P14 ✅ + tiles·search part |
| **256** | `entity_link_picker_dialog.dart` | P14 ✅ + widgets·actions part |
| 239 | `registry_shard_loader_search_index.dart` | P12 추출 |
| 537 | `home_shell_controller.dart` | P11 ✅ **156** + bundle·mixins |
| **254** | `work_sanctum_section_editor.dart` | F2 ✅ |

> `markdown_body_editor.dart` **455줄** (P2 완료) — `markdown_editor_*_ops`·`markdown_slash_command_patch`·shortcuts part 추출.

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

Foundation F0~F4 · Sanctum C1~C4 · manifest sync 포함 **17+커밋** (`origin/main` 대비). `git push` 대기.

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
| P23 | `AppVault` + `DetailArchiveSave` Port | ✅ 2차 · entity·catalog·library·sanctum import |

**금지:** M3 Steam · Discovery Engine · Preview stack · Save Return 정책.

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-25 | F0 초안 — test 605 · precheck PASS |
| 2026-06-25 | F4 — LEGACY_REMOVAL_POLICY · 9건 게이트 |
| 2026-06-25 | Post-F4 재검토 — 대형 파일 재실측 · R14·백로그 · P0/P1 정리 |
| 2026-06-24 | P23 — `AppVault.port` · `DetailArchiveSave` · fusion·entity picker |
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
