# Phase 1 — 작품 아카이빙 E2E 완성 계획

> **지위:** **현재 실행 SSOT** (2026-06-14~)  
> **북극성:** [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) — Phase 1 Entity Archive (**작품**)  
> **출시:** [release-readiness-checklist.md](../release-readiness-checklist.md) · [ROADMAP.md](../../ROADMAP.md) M3  
> **보류:** 50k/500k 대비 · Entity 일반화 · Timeline · Memory Core(SQLite/MCP/ledger) · 신규 Scale ADR

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

### Sprint A — 출시 마무리 (지금)

| # | 작업 | Exit | 상태 |
|:-:|------|------|:----:|
| A1 | **G-AUTO** 전체 (`flutter test` · ci_registry · preflight · quality_gate --release · Release build) | 0 fail | ✅ 2026-06-14 |
| A2 | **Dogfood E2E** — 본인 볼트로 ①~④ 10작 이상 (아래 §8) | 체크리스트 Pass | ⏳ |
| A3 | **M3** Steam Release 최종 승인 · (필요 시) depot 재업로드 | R1~R6 ✅ | ⏳ |
| A4 | friction log — ①~④ 중 **끊긴 UX만** 이슈 등록 | 목록 0~N | ⏳ |

### Sprint B — 출시 직후 (1~2주)

| # | 작업 | Exit |
|:-:|------|------|
| B1 | 실사용 dogfood · 외부 md·볼트 sync 재확인 | — |
| B2 | **확인된 버그만** 수정 (판단 기준 §2) | E2E 회귀 없음 |
| B3 | C4 recall@10 — 대표 20쿼리 (있으면) | ≥0.8 또는 스토어 카피 조정 |

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
| SQLite · MCP · event_ledger | v1 ship + Phase 1 E2E **통과 후** PoC |
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

---

## 8. Dogfood E2E 수동 체크리스트 (Sprint A2)

**빌드:** `build\windows\x64\runner\Release\akasha.exe`  
**자동 선행:** `.\scripts\dogfood_precheck.ps1` (또는 `-Build`)

| # | ① 발견 | Pass |
|:-:|--------|:----:|
| D1 | 검색으로 작품 3건 찾기 (한/영 혼합 1건) | ☐ |
| D2 | master_index 또는 카테고리 그리드에서 작품 탐색 | ☐ |

| # | ② 아카이브 | Pass |
|:-:|-----------|:----:|
| D3 | 검색 결과 → 아카이브 → `.md` 생성 확인 | ☐ |
| D4 | 나만의 서재 「담기」→ md 자동 생성 (Case A) | ☐ |

| # | ③ 기록 | Pass |
|:-:|--------|:----:|
| D5 | 워크벤치 4열 — 별점·본문·`.md` 탭 저장 | ☐ |
| D6 | 외부 에디터로 `.md` 수정 → 2~3초 내 앱 반영 | ☐ |

| # | ④ 큐레이션 | Pass |
|:-:|-----------|:----:|
| D7 | 나만의 서재에서 5작 이상 열람·정렬 | ☐ |
| D8 | 테마 피커 (IAP 잠금 UI 확인) | ☐ |
| D9 | 서재에서 제거 · 우클릭 메뉴 | ☐ |

**목표:** 최소 **10작** ①~④ 한 바퀴. 문제는 §A4 friction log에만 기록 (즉시 대규모 리팩터 금지).
