# Project Status Snapshot

> **갱신:** 2026-06-10  
> **목적:** Gate·Registry·프로그램 **운영 SSOT**  
> **출시:** [release-readiness-checklist.md](release-readiness-checklist.md)  
> **정리:** [programs/repo-cleanup-plan.md](programs/repo-cleanup-plan.md) · Phase 1~2 ✅ (2026-06-12)  
> **확장:** [catalog-growth-charter.md](programs/catalog-growth-charter.md) — **SD2.6 hold 해제**

---

## Executive Summary

| 항목 | 상태 |
|------|------|
| **Registry** | **490 works** · v4 hex shards · dedupe **0** |
| **4종 핵심 Gate** | **전부 PASS** |
| **externalId** | **275/490 (56.1%)** |
| **flutter test** | **254/254 PASS** |
| **Release readiness** | G-AUTO ✅ · G-QA ⏳ · G-STEAM ⏳ |
| **Scale** | SD2.6 hold **해제** — **병행 확장** |
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

## 2. Gate (@490)

| 도구 | 결과 |
|------|:----:|
| `flutter test` | **254/254 PASS** |
| `registry_builder` | PASS |
| `dedupe_linter` | PASS (490 works) |
| `quality_gate --strict` | PASS |
| `quality_gate --release` | PASS |
| `coverage_dashboard` | titles_en 93% · invalid_en 0 |
| `ci_registry_check` | PASS |
| `preflight_check` | PASS |

---

## 3. Release Readiness (2026-06-10 audit)

| 게이트 | 상태 | 비고 |
|--------|:----:|------|
| **G-AUTO** | ✅ | test 254 · analyze 0 error · **Release build OK** |
| **G-QA** | 🔶 | P0 auto 4건 · **수동 0/12** |
| **G-STEAM** | ⏳ | depot·스토어·IAP |
| **G-CATALOG** | 🔶 | 490작 · 스토어 카피 일치 |
| **G-COPY** | 🔶 | Privacy doc ✅ · Steam URL pending |

---

## 4. 병행 트랙

| 트랙 | 다음 |
|------|------|
| **M2 Steam** | P0 QA → depot → 스토어 — [release-readiness-checklist](release-readiness-checklist.md) |
| **Catalog G1** | Wikidata manga trial · Maintainer supply — [catalog-growth-charter](programs/catalog-growth-charter.md) |
| **아키텍처** | search_index 1k/5k 재측정 · dedupe at scale |

---

## 5. 다음 권장 작업

| # | 작업 |
|---|------|
| 1 | **P0 QA 12건** Release 빌드로 실행 |
| 2 | **Steam Playtest** depot 1회 업로드 |
| 3 | m2 스토어 카피 **490+** 반영 |
| 4 | `quality_gate --strict` CI 연동 |
| 5 | Privacy policy URL |
| 6 | Wikidata trial batch insert (gate 통과분) |

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 baseline @430 |
| 2026-06-10 | G2 50% · 문서 IA 재편 |
| 2026-06-10 | **SD2.6 해제** · catalog-growth-charter · 병행 확장 |
| 2026-06-10 | **Release audit** — 490작 · test 250 · release-readiness-checklist |
