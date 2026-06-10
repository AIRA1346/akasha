# Project Status Snapshot

> **갱신:** 2026-06-10  
> **목적:** Gate·Registry·프로그램 **운영 SSOT**  
> **확장:** [catalog-growth-charter.md](programs/catalog-growth-charter.md) — **SD2.6 hold 해제**

---

## Executive Summary

| 항목 | 상태 |
|------|------|
| **Registry** | **430 works** · 351 v4 hex shards · dedupe **0** |
| **4종 핵심 Gate** | **전부 PASS** |
| **externalId G2** | **215/430 (50.00%)** |
| **Scale** | SD2.6 hold **해제** — **병행 확장** 모드 |
| **Steam** | M2 제출 + **카탈로그 G1** 동시 진행 |
| **Discovery** | `patchStatus: active_trial` · Wikidata manga |

---

## 1. 운영 결정 (2026-06-10)

**430작은 Steam 출시에 충분하지 않다.**  
insert를 막던 SD2.6 hold는 **폐기**하고, **작품을 추가하면서** search_index·dedupe·gate 부담을 검증하는 **아키텍처 주도 성장**으로 전환한다.

| 유지 | 폐기 |
|------|------|
| `pre_insert_dedupe_gate` · A급 도구 | SD2.6 **+20 상한** |
| SD3 Pause (품질·dedupe 회귀 시 감속) | O3를 insert **스위치**로 쓰기 |
| Fact-only · Wikidata 법무 경계 | 430 **고정 출시** 가정 |

---

## 2. Gate (@430)

| 도구 | 결과 |
|------|:----:|
| `registry_builder` | PASS |
| `dedupe_linter` | PASS |
| `quality_gate --strict` | PASS |
| `coverage_dashboard` | titles_en 92% · external_id G2 |
| `sw1_a_validation` | recall@10 1.0 |
| `urv_a_validation` | PASS |
| `ci_registry_check` | PASS |

---

## 3. 병행 트랙

| 트랙 | 다음 |
|------|------|
| **M2 Steam** | 스토어·depot·IAP — [m2-steam-store-page](programs/m2-steam-store-page.md) |
| **Catalog G1** | Wikidata manga trial · Maintainer supply — [catalog-growth-charter](programs/catalog-growth-charter.md) |
| **아키텍처** | search_index 1k/5k 재측정 · dedupe at scale |

---

## 4. 다음 권장 작업

| # | 작업 |
|---|------|
| 1 | `shadow_write --live --channel wikidata_manga` |
| 2 | trial batch insert (gate 통과분) |
| 3 | `a5_scale_supply_batch` 재개 |
| 4 | M2 Release 빌드·스토어 페이지 |
| 5 | O8 governance 번들 — insert 후 **매 배치** |

---

## 5. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 baseline @430 |
| 2026-06-10 | G2 50% · 문서 IA 재편 |
| 2026-06-10 | **SD2.6 해제** · catalog-growth-charter · 병행 확장 |
