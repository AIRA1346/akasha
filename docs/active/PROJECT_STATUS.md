# Project Status Snapshot
 
> **갱신:** 2026-06-30 (@10048 · Foundation Phase 2 · Post-P2 분해 SSOT)
> **Git:** `origin/main` HEAD **56d669f** · code/test baseline **5526ce4** · SSOT baseline **57c66fd**
> **현재 실행:** **Foundation Phase 2** — 대형 파일 분해 마무리 (M3 **사용자 지시 전 보류**)
> **목적:** Gate·Registry·프로그램 **운영 SSOT**  
> **출시:** [release-readiness-checklist](../history/release-readiness-checklist.md)  
> **정리:** [repo-cleanup-plan](../history/programs/repo-cleanup-plan.md) · Phase 1~2 ✅ (2026-06-12)  
> **확장:** catalog-growth-charter — **SD2.6 hold 해제**
 
---
 
## Executive Summary
 
| 항목 | 상태 |
|------|------|
| **Registry** | **10048 works** · v4 hex shards · dedupe **0** |
| **4종 핵심 Gate** | **전부 PASS** |
| **externalId** | **10048/10048 (100%)** |
| **flutter test** | **614 PASS** |
| **Phase 1** | Record Foundation ✅ |
| **Phase 6.2** | 전 경로 Workbench 통합 ✅ |
| **Phase 6.3** | incoming/sameDay·connections coordinator ✅ |
| **코드 건강** | Phase 0~7 ✅ · **Sanctum C1~C4** ✅ |
| **다음** | **Foundation Phase 2** 마무리 점검 · `home_shell_body` 추가 분해 여지 · **M3** 보류 |
| **Scale / Core** | **Phase 2.0~2.3** ✅ @10048 · G1 ✅ · **ADR-010 eager-only batch** ✅ |
| **Steam** | depot·스토어·IAP ✅ — **Wave 1 Home 해부** ✅ |
| **Discovery** | `wikidata_ko` active · **10k milestone** ✅ |
| **CDN** | akasha-db.pages.dev — **10048 push 완료** |

---

## 1. 운영 결정 (2026-06-10)

**430작은 Steam 출시에 충분하지 않다.**  
insert를 막던 SD2.6 hold는 **폐기**하고, **작품을 추가하면서** search_index·dedupe·gate 부담을 검증하는 **아키텍처 주도 성장**으로 전환한다.

| 유지 | 폐기 |
|------|------|
| `pre_insert_dedupe_gate` · A급 도구 | SD2.6 **+20 상한** |
| SD3 Pause (품질·dedupe 회귀 시 감속) | O3를 insert **스위치**로 쓰기 |
| Fact-only · Wikidata 법무 경계 | 430 **고정 출시** 가정 |

**2026-06-13:** Steam depot·스토어·P0 QA 12/12 완료. 정식 릴리즈 전 **Wave 1 Home 해부**를 blocking으로 설정 ([release-readiness-checklist](../history/release-readiness-checklist.md) §7).

---

## 2. Gate (@10048)

> 구현·Registry 상세는 **[CURRENT_STATE.md](CURRENT_STATE.md)** (Reality SSOT)를 따릅니다.

| 도구 | 결과 |
|------|:----:|
| `flutter test` | **614 PASS** |
| `registry_builder` | PASS |
| `dedupe_linter` | PASS (10048 works) |
| `quality_gate --strict` | PASS |
| `quality_gate --release` | PASS |
| `coverage_dashboard` | titles_ko 100% · titles_en 100% · invalid_en 0 |
| `quality_gate --locale-minimum` | PASS |
| `ci_registry_check` | PASS |
| `preflight_check` | PASS |

---

## 3. Release Readiness (2026-06-14)

| 게이트 | 상태 | 비고 |
|--------|:----:|------|
| **G-AUTO** | ✅ | test **614** · analyze 0 error · Release build OK |
| **G-QA** | ✅ | P0 수동 **12/12** (2026-06-13) |
| **G-STEAM** | ✅ | depot·스토어·IAP·Privacy URL |
| **G-CATALOG** | ✅ | **10048작** · recall@10 **87/87** (SW1-A) |
| **G-COPY** | ✅ | Privacy doc · 스토어 카피 정합 |

---

## 4. 병행 트랙

| 트랙 | 다음 | 우선 |
|------|------|:----:|
| **Sprint B** | ✅ B1 dogfood · Vault agent | — |
| **Wave 1 Home** | ✅ shell **40줄** | — |
| **Catalog G1** | Sprint C · **관측만** | P2 |
| **M3 Release** | **보류** (사용자 지시 시 착수) | — |
| **Foundation P2** | scaffold · dialogs coordinator · franchise fusion 분해 | **✅** |
| **Scale/Core** | **보류** | — |

---

## 5. 코드 건강 스프린트 (2026-06)

| Phase | 내용 | 상태 |
|:---:|------|:---:|
| 0 | README SSOT · `PROJECT_STATUS` 정리 | ✅ |
| 1 | Vault works 레이아웃 rename | ✅ |
| 2 | `FeatureFlags` v1 post-v1 UI 숨김 | ✅ |
| 3 | Workbench 상태 레이어 분해 (archive·link pick·connections coordinator) | ✅ |
| 4 | `tool/archive` · `tool/migrations` 스크립트 이동 | ✅ |
| 5 | `registry_shard_loader` workId 캐시 | ✅ |
| 6 | vault fingerprint 조건부 polling | ✅ |
| 7 | Home preview·recent·archive/reorder · Workbench shared ops | ✅ |
| **S** | **Sanctum C1~C4** — wiki 칩·출연·갤러리·완성도·템플릿·HTML | ✅ |
| **F** | **Foundation F0~F4** — 감사·Sanctum 분해·R14-B·레거시 정책 | ✅ |

**대형 파일 (2026-06-30 재실측 · Post-P2):** `markdown_body_editor` **503** (shell + parts) · `home_shell_body` **479**

**P2 분해 완료 (shell 줄 수 · code baseline `5526ce4`):** `home_shell_scaffold` **31** (`194db17`) · `home_dialogs_coordinator` **124** (`955967e`) · `franchise_fusion_service` **76** (`5526ce4`)

**P27~P31·P30 후속:** `work_library_panel` **162** · `dashboard_sidebar` **152** · `browse_dashboard_sections` **165** · `collectible_collection_edit_dialog` **73** · P30 dialog 저장 widget test **4** · `poster_card_layouts` **~270** (P24) · markdown editor 6 parts (P26)

감사 SSOT: [FOUNDATION_AUDIT.md](../draft/FOUNDATION_AUDIT.md) · Vault: [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md)

---

## 6. 다음 권장 작업

| # | 작업 | 우선 |
|---|------|:----:|
| 1 | `home_shell_body` 추가 분해 (선택) | P3 |
| 2 | **M3** Steam Release | 보류 |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 baseline @430 |
| 2026-06-10 | G2 50% · 문서 IA 재편 |
| 2026-06-10 | **SD2.6 해제** · catalog-growth-charter · 병행 확장 |
| 2026-06-10 | **Release audit** — 490작 · test 250 · release-readiness-checklist |
| 2026-06-13 | Steam depot·P0 QA 12/12 — [release-readiness-checklist](../history/release-readiness-checklist.md) |
| 2026-06-14 | Wave 1 2차 — coordinator·HomeShellBody · shell 1004줄 |
| 2026-06-14 | Wave 1 3차 — UI glue 분리 · shell 710 · test 268 |
| 2026-06-14 | Wave 1 4차 — controller·scaffold · shell **40줄** · test 271 |
| 2026-06-14 | **phase1-work-e2e-plan** — E2E 우선 · Scale/Core 보류 |
| 2026-06-14 | Sprint **A2** Dogfood E2E ✅ |
| 2026-06-14 | **M3 보류** → Sprint **B** |
| 2026-06-16 | sliver grid 스크롤 · **extensibility-hardening-plan** · test **305** |
| 2026-06-16 | E2-5 Port DI · E2-6 workspace 분리 · E1-A3b 순환 제거 · test 318 |
| 2026-06-24 | 코드 건강 Phase 0~6 — vault·FeatureFlags·workbench coordinator·`tool/` archive·polling · test **580** |
| 2026-06-24 | 코드 건강 Phase 7b — save ops·collection reorder·docs SSOT · test **591** |
| 2026-06-25 | **Sanctum C1~C4** · Foundation F0 감사 · test **605** · [FOUNDATION_AUDIT.md](../draft/FOUNDATION_AUDIT.md) |
| 2026-06-30 | **Post-P2 SSOT** — scaffold·dialogs·fusion 분해 · SSOT **57c66fd** · code **5526ce4** · test **614** |
| 2026-06-30 | SSOT HEAD 정정 · SSOT baseline **04ce025** · P30 dialog test **48c8c39** |
| 2026-06-29 | **Post-P30 후속** — dialog 저장 widget test **4** · P30 dialog test commit **48c8c39** · test **614** |
| 2026-06-29 | **Post-P31 SSOT** — P31 `work_library_panel` 분해 (**162** shell) · `origin/main` **0c92519** · test **610** |
| 2026-06-29 | **Post-P30 SSOT** — P27~P30 분해·P28 tokens · 400줄+ 재실측 · `origin/main` **9d17f75** · test **610** |
