# Foundation Audit — 기초 다지기 감사 (F0)

> **일자:** 2026-06-25  
> **지위:** Foundation Sprint F0 산출물 (draft)  
> **상위:** [PROJECT_STATUS.md](../active/PROJECT_STATUS.md) · [CURRENT_STATE.md](../active/CURRENT_STATE.md)

---

## 1. Executive Summary

| 항목 | 결과 |
|------|------|
| `flutter test` | **605/605 PASS** (F0-1 수정 후) |
| `dogfood_precheck.ps1` | **PASS** |
| `flutter analyze lib` | **0 error** (info/warn 3건) |
| Release build | 최근 `build_release.ps1` OK (`b6d4899`) |
| Git | `main` **origin보다 11커밋 앞섬** (미 push) |
| 문서 SSOT | Sanctum C1~C4 **누락** → F1에서 갱신 |

**판단:** Gate·Registry는 건강. **Sanctum 기능 스프린트 이후 문서·테스트·구조 부채**가 다음 병목이다.

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

## 3. 대형 파일 (600줄+, 2026-06-25 실측)

| 줄 수 | 파일 | 비고 |
|------:|------|------|
| 886 | `work_detail_workspace.dart` | Sanctum toolbar·template·HTML |
| 796 | `entity_detail_workspace.dart` | entity HTML export |
| 730 | `markdown_body_editor.dart` | 슬롯·paste·slash |
| **720** | **`work_sanctum_section_editor.dart`** | **신규 1순위 분해 대상** |
| 713 | `home_dashboard_discovery_section.dart` | FeatureFlags 숨김 |
| 649 | `home_shell_body.dart` | |
| 641 | `catalog_entity_browse_view.dart` | |
| 537 | `home_shell_controller.dart` | Phase 7 분해 완료 |
| 587 | `registry_shard_loader.dart` | workId 캐시 완료 |

**문서 갱신 전 수치:** PROJECT_STATUS는 ~792/~736 — **실측과 불일치** (F1 반영).

---

## 4. Sanctum 아카이빙 (C1~C4 + Post-C4)

| 단계 | 내용 | 상태 |
|:---:|------|:---:|
| C1 | wiki 칩 리치 미리보기 | ✅ |
| C2 | `# 👥 출연` 슬롯 | ✅ |
| C3 | 갤러리·이미지 DnD/붙여넣기·명장면 카드 | ✅ |
| C4 | 완성도 %·템플릿·HTML보내기 (Work) | ✅ |
| Post-C4 | Entity HTML·Sanctum 헤더 토큰·정책 §14 | ✅ |

**미커밋 테스트 수정:** F0 회귀 수정 3파일 (커밋 대기).

---

## 5. 레거시 `TODO(remove)` (9건)

| 파일 | 건수 | F4 결정 필요 |
|------|:----:|-------------|
| `vault_work_journal_paths.dart` | 2 | works 레이아웃 마이그레이션 완료 조건 |
| `works_registry.dart` | 2 | monolithic JSON 병합 제거 |
| `registry_shard_loader.dart` | 2 | legacy alias · v4-only 캐시 |
| `registry_sync_service.dart` | 1 | legacy cache clear |
| `file_service.dart` | 1 | 구 category 폴더 생성 |
| `user_preferences.dart` | 1 | works 레이아웃 기본값 `true` 전환 |

---

## 6. 미 push 커밋 (11건, Sanctum 중심)

```
b6d4899 chore: sync registry manifests after release build
5bf11e5 feat: extend Sanctum HTML export to entities and polish panel tokens
f2931fe chore: sync registry manifests after release build
a2fab30 feat: add Sanctum archive completion, templates, and HTML export
e5ec387 chore: sync registry manifests after release build
e9a476e feat: add gallery drag-drop and clipboard image paste for Sanctum
2052703 chore: sync registry manifests after release build
ec2d388 feat: add Sanctum gallery slot and expand rich preview rendering
66b5cb8 chore: sync registry manifests after release build
9315b58 fix: handle cast slot label in markdown body editor switch
9454397 feat: add Sanctum cast slot and rich wiki link preview chips
```

---

## 7. Foundation 로드맵 (F1~F4)

| Phase | 기간 | 내용 | 상태 |
|:---:|------|------|:---:|
| **F0** | 0.5~1일 | 기준선 감사·테스트 green | ✅ |
| **F1** | 1일 | SSOT 문서·B1 D7~D9 | 🟡 진행 |
| **F2** | 3~5일 | `work_sanctum_section_editor` 분해 · workspace ops 추출 | ⬜ |
| **F3** | 2~3일 | R14-B Preview·Save status·Neighbors 토큰 | ⬜ |
| **F4** | 2일 | `TODO(remove)` 제거 조건표 · works 레이아웃 정책 | ⬜ |

**의존성:** F0 → F1 → B1 수동 dogfood → F2 → F3. M3 재개는 B1 §5 완료 후.

---

## 8. R14 잔여 (F3 범위)

| # | 항목 | 파일 후보 |
|---|------|-----------|
| 1 | Preview 정보 계층 | `dashboard_preview_panel.dart` |
| 2 | Neighbors sectionTitle 토큰 | `work_link_neighbors_sections.dart` |
| 3 | Save status semantic 색 | `workbench_save_status_hint.dart` |
| 4 | Sanctum hint·배너 grey | `sanctum_page_panel.dart` |

**금지:** Discovery Engine · Preview stack 정책 · Save Return 문구 변경.

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-25 | F0 초안 — test 605 · precheck PASS · 대형 파일·Sanctum·TODO 감사 |
