# Project Status Snapshot
 
> **갱신:** 2026-06-30 (@10048 · **Steam v1 개인 아카이브 재정렬**)
> **Git:** code/test baseline **5526ce4** · SSOT baseline *(본 커밋 직후)* · current tip은 `git log -1` 기준
> **현재 실행:** **Steam v1 — Personal Sanctum Archive** (M3 **사용자 지시 전 보류**)
> **목적:** Gate·Registry·프로그램 **운영 SSOT**  
> **출시:** [release-readiness-checklist](../history/release-readiness-checklist.md)  
> **비전:** [VISION.md](VISION.md) · **구현:** [CURRENT_STATE.md](CURRENT_STATE.md)
 
---
 
## Executive Summary
 
| 항목 | 상태 |
|------|------|
| **flutter test** | **614 PASS** |
| **v1 핵심** | **Personal Sanctum vault 아카이브** — 말하기/쓰기 → `.md`/YAML → 예쁜 UI → Agent 편집 |
| **Phase 1** | Record Foundation ✅ |
| **Sanctum** | C1~C4 ✅ · Vault agent 가이드 ✅ |
| **코드 건강** | Phase 0~7 ✅ · Foundation P2 분해 ✅ |
| **다음** | v1 아카이브 루프 E2E · Agent Protocol **구현·dogfood** · **M3** 보류 |
| **Registry (akasha-db)** | **10,048 works** · optional catalog / starter — **v1 blocking 아님** |
| **Steam** | depot·스토어·IAP ✅ — **M3 정식 출시 보류** |

---

## 1. Steam v1 제품 방향 (2026-06-30)

**v1 핵심:** 글로벌 작품 사전이 아니라 **개인 Sanctum vault 아카이브 앱**.

```
감상을 말하거나 직접 작성
  → Sanctum vault .md / YAML 저장
  → AKASHA가 예쁘게 정리·표시
  → 에이전트가 vault를 읽고 편집하며 기록을 도움
```

| v1 우선 (blocking에 가깝게) | v1에서 낮춤 (구현 유지 · 메시지·우선순위만) |
|-----------------------------|-----------------------------------------------|
| 로컬 vault 안정성 · watch · 원자적 저장 | 10k 글로벌 사전 **강조** |
| 직접 작품 추가 · 아카이브 `.md` 생성 | 대규모 registry **확장** 트랙 |
| 감상·평점·상태·태그·명장면·갤러리 (Sanctum) | Wikidata / 외부 API **확장** |
| Personal Library · Collection | Discovery / recommendation |
| Agent Vault Protocol v1 범위 ([AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md)) · 현장 ([VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md)) | CDN·search recall **scale gate**를 v1 출시 조건으로 두지 않음 |
| 예쁜 기록 UI (Workbench · Sanctum) | |

**akasha-db / registry:** 삭제하지 않음 — **optional catalog support** · starter catalog · **post-v1 scale track**.

**M3 Steam 정식 출시:** 여전히 **사용자 지시 전 보류**. dogfood는 **사용자 직접** 수행.

### 이전 운영 결정 (2026-06-10, 역사 보존)

당시 **430작은 Steam 출시에 충분하지 않다**는 전제로 catalog 성장·SD2.6 해제를 결정했다.
2026-06-30 재정렬 이후 **v1 출시를 막는 조건은 개인 아카이브 품질**이며, registry 규모 확장은 **post-v1**로 이동한다.
아래 Gate 표의 registry·recall 수치는 **엔지니어링 자산**으로 보존한다.

---

## 2. Gate (@10048)

> Registry·검색 상세는 [CURRENT_STATE.md](CURRENT_STATE.md). **v1 blocking**은 §3 참고.

| 도구 | 결과 | v1 blocking |
|------|:----:|:-----------:|
| `flutter test` | **614 PASS** | ✅ |
| `flutter analyze lib` | 0 issue | ✅ |
| `preflight_check` | PASS | ✅ |
| `registry_builder` | PASS | — (post-v1 scale) |
| `dedupe_linter` | PASS (10048) | — |
| `quality_gate --strict` | PASS | — |
| `ci_registry_check` | PASS | — |
| `sw1_a_validation` recall@10 | 87/87 | — (optional catalog QA) |

---

## 3. Release Readiness — Steam v1

| 게이트 | 상태 | v1 blocking | 비고 |
|--------|:----:|:-----------:|------|
| **G-AUTO** | ✅ | ✅ | test **614** · analyze 0 · Release build |
| **G-VAULT** | 🔶 | **✅** | 볼트 연동·아카이브·Sanctum 저장·기록 UI — **v1 핵심** |
| **G-QA** | ✅ | ✅ | P0 수동 **12/12** (2026-06-13) · dogfood **사용자 직접** |
| **G-STEAM** | ✅ | ✅ (M3 시) | depot·스토어·IAP·Privacy — **M3 보류** |
| **G-COPY** | ✅ | ✅ (M3 시) | Privacy doc · 스토어 카피 |
| **G-CATALOG** | ✅ | — | 10048작 · recall 87/87 — **optional / post-v1 scale** |
| **G-DISCOVERY** | ✅ | — | Wikidata spine — **v1 메시지·blocking 아님** |

---

## 4. 병행 트랙

| 트랙 | 다음 | v1 우선 |
|------|------|:-------:|
| **Personal Archive (v1)** | vault 안정성 · Sanctum · Library/Collection · Agent Protocol | **P0** |
| **Sprint B** | ✅ B1 · Vault agent 가이드 | — |
| **Wave 1 Home** | ✅ shell 분해 완료 | — |
| **Foundation P2** | ✅ scaffold · dialogs · fusion | — |
| **Catalog / akasha-db** | optional starter · CI 관측 | post-v1 |
| **Discovery / Scale** | Wikidata · 10k+ 확장 | post-v1 |
| **M3 Release** | **보류** (사용자 지시) | — |

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

감사 SSOT: [FOUNDATION_AUDIT.md](../draft/FOUNDATION_AUDIT.md) · Vault: [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) · [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md)

---

## 6. 다음 권장 작업

| # | 작업 | 우선 |
|---|------|:----:|
| 1 | v1 아카이브 루프 E2E (vault → 기록 → Library) · dogfood | **P0** |
| 2 | Agent Vault Protocol v1 **구현·dogfood** ([AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) §8) | P1 |
| 3 | `home_shell_body` 추가 분해 (선택) | P3 |
| 4 | **M3** Steam Release | 보류 |

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
| 2026-06-30 | **Steam v1 재정렬** — 개인 Sanctum 아카이브 중심 · registry scale post-v1 · code **5526ce4** |
| 2026-06-30 | **Agent Vault Protocol v1** — [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) 범위 문서 |
| 2026-06-30 | **Post-P2 SSOT** — scaffold·dialogs·fusion 분해 · SSOT **57c66fd** · code **5526ce4** · test **614** |
| 2026-06-29 | **Post-P30 후속** — dialog 저장 widget test **4** · P30 dialog test commit **48c8c39** · test **614** |
| 2026-06-29 | **Post-P31 SSOT** — P31 `work_library_panel` 분해 (**162** shell) · `origin/main` **0c92519** · test **610** |
| 2026-06-29 | **Post-P30 SSOT** — P27~P30 분해·P28 tokens · 400줄+ 재실측 · `origin/main` **9d17f75** · test **610** |
