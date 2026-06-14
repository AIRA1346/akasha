# Phase 1 — 작품 아카이빙 E2E 완성 계획

> **지위:** Phase 0 완료 기록 · **실행 SSOT는** [architecture-evolution-phases.md](architecture-evolution-phases.md)  
> **북극성:** [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) — Phase 1 Entity Archive (**작품**)  
> **출시:** M3 Steam — **사용자 품질 기준 충족 시** (일정 고정 아님)  
> **보류:** 50k/500k 대비 · Entity 일반화 · Timeline · Memory Core · Scale ADR · **M3 Release**

---

## 1. 한 줄

**지금은 아키텍처를 더 만드는 단계가 아니라, 이미 정한 Phase 1(작품) 구조를 실제 제품으로 완성·검증하는 단계다.**

---

## 2. 판단 기준 (모든 작업에 적용)

> **「이 변경이 지금 작품 아카이빙 ①~④를 완성·검증하는가?」**

| | |
|--|--|
| **예** | 지금 한다 |
| **아니오** | **나중** (백로그만 기록) |

**추가 금지 (측정 전):** search_index 분리 · manifest-only bundle · Entity type 확장 · Timeline Archive · Event Store / SQLite / MCP 전면 도입 · 추측 기반 50k/500k 설계

---

## 3. v1 제품 수직 슬라이스 (증명 대상)

**Memory Core(v6)는 v1 blocking 아님.** `.md` Sanctum vault가 현재 SSOT.

```
① 발견     검색 · Fact 그리드 · work_id 조회
② 아카이브  .md 생성 (수동 · auto-archive · 담기)
③ 기록     워크벤치 저장 · 외부 .md sync
④ 큐레이션  나만의 서재 · 테마(IAP) · 멤버십
```

### 3.1 단계별 상태 (@490 · 2026-06-14)

| # | 단계 | 구현 | 자동 테스트 | P0 수동 | 남은 일 |
|:-:|------|:----:|:-----------:|:-------:|---------|
| ① | **발견** | ✅ | `fusion_search_test` 등 | Q01·Q12 ✅ | C4 recall@10 ⏳ (스토어 약속) |
| ② | **아카이브** | ✅ | `vault_archive_test` | Q02·Q03 ✅ | auto-archive 정책 dogfood 확인 |
| ③ | **기록** | ✅ | `workbench_controller_test` | Q09 ✅ | — |
| ④ | **큐레이션** | ✅ | `library_membership_*` | Q06~Q08·Q10 ✅ | v1.1: 그리드 밀도 등 |

**Wave 1 Home 해부:** ✅ shell **40줄** (ADR-007)

### 3.2 v6 Core 슬라이스 (별 트랙 · v1 후)

```
.md → event_ledger.jsonl → SQLite cache → MCP
```

→ Steam v1 **완료 조건에 포함하지 않음**. Phase 1 E2E **통과 후** PoC.

---

## 4. 실행 순서 (차근차근)

### Sprint A — E2E 검증 ✅

| # | 작업 | Exit | 상태 |
|:-:|------|------|:----:|
| A1 | **G-AUTO** 전체 | 0 fail | ✅ 2026-06-14 |
| A2 | **Dogfood E2E** ①~④ | Pass | ✅ 2026-06-14 |
| A3 | **M3** Steam Release | R1~R6 | ⏸️ **보류** — 원하는 품질 될 때 |
| A4 | friction log | 0~N | — (없음) |

### Sprint B — 품질 다듬기 ← **현재**

| # | 작업 | Exit |
|:-:|------|------|
| B1 | **지속 dogfood** — 본인 볼트 실사용 | 습관 |
| B2 | friction **메모 → 확인된 것만** 수정 (§2) | E2E 회귀 없음 |
| B3 | **출시 품질** 자가 점검 (원할 때 §9) | 본인 Ready 판단 |
| B4 | C4 recall@10 · 검색 체감 (선택) | 스토어 정합 |

### Sprint C — Catalog G1 (병행 · 측정만)

| # | 작업 | Exit |
|:-:|------|------|
| C1 | Wikidata trial batch insert ([catalog-growth-charter](catalog-growth-charter.md)) | gate 통과분만 merge |
| C2 | **관측만** — `entryCount` 1k/3k/5k 시 cold start ms · APK MB · master_index 체감 | 스프레드시트 기록 |
| C3 | **문제 확인된 것만** 수정 — 추측 확장 금지 | — |

### Sprint D — v1.1 (E2E 피드백 기반)

| # | 작업 | 조건 |
|:-:|------|------|
| D1 | dogfood·사용자 friction에서 나온 ①~④ 갭 | Sprint B log |
| D2 | Appreciation/Timeline **연결 UX** 일부 | ultimate §10 v1.1 |
| D3 | search_index / browse / bundle | **C2에서 병목 확인 후에만** |

---

## 5. 명시적 보류 (백로그)

| 항목 | 재개 조건 |
|------|-----------|
| search_index 분리 · lazy | C2에서 5k **체감** 병목 확인 |
| manifest-only bundle | APK 또는 fetch **실측** 문제 |
| Entity 일반화 (인물·사건·개념) | Phase 1 dogfood **충분히** 검증 |
| Timeline Archive (일기·생각) | Phase 3~4 ([ultimate-archiving](../product/ultimate-archiving-vision.md) §10) |
| SQLite · MCP · event_ledger | Phase 1 E2E + **출시 후** PoC |
| **M3 Steam Release** | 사용자 **품질 만족** + §9 체크 (일정 아님) |
| 신규 Scale ADR | 위 보류 항목 **착수 시** |

---

## 6. 관련 문서

| 문서 | 역할 |
|------|------|
| [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) | 장기 북극성 |
| [product-vision.md](../product-vision.md) | Tier 1/2 · v1 In/Out |
| [catalog-growth-charter.md](catalog-growth-charter.md) | G1 insert (Sprint C) |
| [registry-scaling-review.md](../validation/registry-scaling-review.md) | **참고만** — 지금 수정 트리거 아님 |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-14 | 초판 — E2E 우선 · Scale/Core 보류 · Sprint A~D |
| 2026-06-14 | Sprint **A1** G-AUTO ✅ — test 271 · analyze 0 error · Release exe |
| 2026-06-14 | Sprint **A2** Dogfood E2E ✅ |
| 2026-06-14 | **M3 보류** — Sprint **B** 품질 다듬기로 전환 |

---

## 8. Dogfood E2E (Sprint A2 — ✅ 완료)

사용자 Dogfood OK (2026-06-14). 참고용 체크리스트:

| # | ① 발견 | |
|:-:|--------|:--:|
| D1 | 검색 3건 | ✅ |
| D2 | 그리드 탐색 | ✅ |

| # | ②~④ | |
|:-:|-----|:--:|
| D3~D9 | 아카이브 · 기록 · 큐레이션 | ✅ |

---

## 9. 출시 품질 자가 점검 (원할 때 · M3 전)

**「이 정도면 Steam Release」** — 전부 ✅일 필요 없음. **본인 기준**으로 판단.

| # | 질문 | 메모 |
|:-:|------|------|
| Q1 | ①~④가 **매끄럽게** 이어지는가? | |
| Q2 | 본인 볼트로 **2주 이상** 실사용했는가? | |
| Q3 | **friction**이 남아 있어도 출시해도 되는 수준인가? | |
| Q4 | 카탈로그 **490+** · 검색 **체감** OK? | C4 선택 |
| Q5 | 스토어 페이지·스크린샷이 **현재 앱**과 맞는가? | |

Ready면 → M3 (Steamworks Release). 아니면 Sprint B 계속.
