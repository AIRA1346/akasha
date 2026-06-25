# Foundation Audit — 기초 다지기 감사 (F0)

> **일자:** 2026-06-25 (F0) · **재검토:** 2026-06-25 (Post-F4)  
> **지위:** Foundation Sprint 감사 SSOT (draft)  
> **상위:** [PROJECT_STATUS.md](../active/PROJECT_STATUS.md) · [CURRENT_STATE.md](../active/CURRENT_STATE.md)  
> **레거시:** [LEGACY_REMOVAL_POLICY.md](LEGACY_REMOVAL_POLICY.md)

---

## 1. Executive Summary

| 항목 | 결과 (재검토 2026-06-25) |
|------|--------------------------|
| `flutter test` | **605/605 PASS** |
| `dogfood_precheck.ps1` | **PASS** |
| `flutter analyze lib` | **0 issue** (Post-F4 lint 정리 후) |
| Release build | `build_release.ps1` OK (`202236a`) |
| Git | `main` **origin보다 17+커밋 앞섬** (미 push) |
| Foundation F0~F4 | **✅ 완료** |
| B1 수동 dogfood | **사용자 진행** (Q/D 체크리스트 미완) |

**판단:** Gate·Registry·Foundation Sprint는 건강. **출시 전 병목**은 B1 수동 검증과 **워크벤치 대형 파일·R14 전역 토큰** 잔여.

---

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
| 857 | `work_detail_workspace.dart` | F2 sanctum ops 분리 — **본체 대형** |
| 796 | `entity_detail_workspace.dart` | P2 분해 후보 |
| 730 | `markdown_body_editor.dart` | P2 분해 후보 |
| 713 | `home_dashboard_discovery_section.dart` | FeatureFlags 숨김 |
| 649 | `home_shell_body.dart` | |
| 641 | `catalog_entity_browse_view.dart` | |
| 630 | `poster_card.dart` | |
| 590 | `work_link_neighbors_sections.dart` | F3 토큰화 |
| 587 | `registry_shard_loader.dart` | |
| 537 | `home_shell_controller.dart` | Phase 7 분해 완료 |
| **254** | `work_sanctum_section_editor.dart` | F2 ✅ |

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
| 6 | Home·Dialog `Colors.grey` ~70파일 | ⬜ R14-C (P3) |

**금지:** Discovery Engine · Preview stack 정책 · Save Return 문구 변경.

---

## 9. Post-Foundation 백로그 (에이전트)

| 우선 | 작업 | 상태 |
|:----:|------|:---:|
| P0 | analyze lint · FOUNDATION_AUDIT 갱신 | ✅ |
| P1 | `hasOpenWork` · `WorkTab` deprecated 제거 | ✅ |
| P1 | Entity neighbors · preview chrome 토큰 | ✅ |
| P2 | `entity_detail_workspace` 분해 | ⬜ |
| P2 | `work_detail_workspace` 추가 분해 | ⬜ |
| P2 | `markdown_body_editor` 분해 | ⬜ |
| P3 | R14-C Home·Dialog grey pass | ⬜ |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-25 | F0 초안 — test 605 · precheck PASS |
| 2026-06-25 | F4 — LEGACY_REMOVAL_POLICY · 9건 게이트 |
| 2026-06-25 | Post-F4 재검토 — 대형 파일 재실측 · R14·백로그 · P0/P1 정리 |
