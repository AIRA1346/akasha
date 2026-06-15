# Project Status Snapshot

> **갱신:** 2026-06-15 (@5181)  
> **현재 실행:** [programs/architecture-evolution-phases.md](programs/architecture-evolution-phases.md) · Phase **1** + **2 Scale 진행**  
> **목적:** Gate·Registry·프로그램 **운영 SSOT**  
> **출시:** [release-readiness-checklist.md](release-readiness-checklist.md)  
> **정리:** [programs/repo-cleanup-plan.md](programs/repo-cleanup-plan.md) · Phase 1~2 ✅ (2026-06-12)  
> **확장:** [catalog-growth-charter.md](programs/catalog-growth-charter.md) — **SD2.6 hold 해제**

---

## Executive Summary

| 항목 | 상태 |
|------|------|
| **Registry** | **5181 works** · v4 hex shards · dedupe **0** |
| **4종 핵심 Gate** | **전부 PASS** |
| **externalId** | **5181/5181 (100%)** |
| **flutter test** | **297/297 PASS** (browse window dogfood +6) |
| **Phase 1** | Record Foundation ✅ |
| **Phase 4.3** | Quick capture UI ✅ · Dogfood ✅ |
| **Phase 4.4a** | Timeline list ✅ |
| **다음** | Sprint B — 작품 `.md` 실사용 · friction · M3 Ready |
| **Scale / Core** | **Phase 2 진행** — @5181 · **G1 ✅** · window 모드 ([baseline](programs/catalog-scale-baseline-490.md)) |
| **Steam** | depot·스토어·IAP ✅ — **Wave 1 Home 해부** ✅ |
| **Discovery** | `patchStatus: active_trial` · Wikidata ko (7 categories) |
| **CDN** | akasha-db.pages.dev — **5181 deploy 대기** (로컬 최신) |

---

## 1. 운영 결정 (2026-06-10)

**430작은 Steam 출시에 충분하지 않다.**  
insert를 막던 SD2.6 hold는 **폐기**하고, **작품을 추가하면서** search_index·dedupe·gate 부담을 검증하는 **아키텍처 주도 성장**으로 전환한다.

| 유지 | 폐기 |
|------|------|
| `pre_insert_dedupe_gate` · A급 도구 | SD2.6 **+20 상한** |
| SD3 Pause (품질·dedupe 회귀 시 감속) | O3를 insert **스위치**로 쓰기 |
| Fact-only · Wikidata 법무 경계 | 430 **고정 출시** 가정 |

**2026-06-13:** Steam depot·스토어·P0 QA 12/12 완료. 정식 릴리즈 전 **Wave 1 Home 해부**를 blocking으로 설정 ([release-readiness-checklist](release-readiness-checklist.md) §7).

---

## 2. Gate (@2008)

| 도구 | 결과 |
|------|:----:|
| `flutter test` | **291/291 PASS** |
| `registry_builder` | PASS |
| `dedupe_linter` | PASS (2008 works) |
| `quality_gate --strict` | PASS |
| `quality_gate --release` | PASS |
| `coverage_dashboard` | titles_en 93% · invalid_en 0 |
| `ci_registry_check` | PASS |
| `preflight_check` | PASS |

---

## 3. Release Readiness (2026-06-14)

| 게이트 | 상태 | 비고 |
|--------|:----:|------|
| **G-AUTO** | ✅ | test 265 · analyze 0 error · Release build OK |
| **G-QA** | ✅ | P0 수동 **12/12** (2026-06-13) |
| **G-STEAM** | ✅ | depot·스토어·IAP·Privacy URL |
| **G-CATALOG** | ✅ | **2008작** · recall@10 **87/87** (@490 SW1-A) |
| **G-COPY** | ✅ | Privacy doc · 스토어 카피 정합 |

---

## 4. 병행 트랙

| 트랙 | 다음 | 우선 |
|------|------|:----:|
| **Sprint B** | 품질 다듬기 ← **현재** | **P0** |
| **Wave 1 Home** | ✅ shell **40줄** | — |
| **Catalog G1** | Sprint C · **관측만** | P2 |
| **M3 Release** | ⏸️ 품질 Ready 시 | — |
| **Scale/Core** | **보류** | — |

---

## 5. 다음 권장 작업

| # | 작업 | Sprint |
|---|------|:------:|
| 1 | **Sprint B1** — 작품 `.md` 지속 dogfood | B |
| 2 | friction 있으면 §2 기준 수정 | B |
| 3 | **M3** — Ready 시 Steam Release | ⏸️ |

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 baseline @430 |
| 2026-06-10 | G2 50% · 문서 IA 재편 |
| 2026-06-10 | **SD2.6 해제** · catalog-growth-charter · 병행 확장 |
| 2026-06-10 | **Release audit** — 490작 · test 250 · release-readiness-checklist |
| 2026-06-13 | Steam depot·P0 QA 12/12 — [release-readiness-checklist](release-readiness-checklist.md) |
| 2026-06-14 | Wave 1 2차 — coordinator·HomeShellBody · shell 1004줄 |
| 2026-06-14 | Wave 1 3차 — UI glue 분리 · shell 710 · test 268 |
| 2026-06-14 | Wave 1 4차 — controller·scaffold · shell **40줄** · test 271 |
| 2026-06-14 | **phase1-work-e2e-plan** — E2E 우선 · Scale/Core 보류 |
| 2026-06-14 | Sprint **A2** Dogfood E2E ✅ |
| 2026-06-14 | **M3 보류** → Sprint **B** |
