# A5 Pilot Final Review

> **세션:** 2026-06-09  
> **Registry:** 402 baseline → **410** (Pilot 종료 시점)  
> **근거:** [a5-pilot-observation-log.md](a5-pilot-observation-log.md) · [a5-pilot-gate-decision-record.md](a5-pilot-gate-decision-record.md) · [a5-pilot-charter.md](a5-pilot-charter.md) §5.2 · [a5-gate-review.md](a5-gate-review.md) §5  
> **상태:** **최종 확정** — Pilot **종료** · Scale **준비 단계 전환**

---

## Executive Summary

| 항목 | 결과 |
|------|------|
| **Pilot 결과** | **성공** |
| **H1~H5** | **전부 Continue** |
| **Stop** | **없음** |
| **Critical Gate 실패** | **없음** (H2 1차 Pause → Remediation 후 **Continue**) |
| **Assumption A5** | **Deferred** 유지 — Pilot 성공으로 **Unsupported 기각 아님** · **Supported**는 Scale에서 S1~S4 **확정** |
| **다음 단계** | **Scale 준비** 착수 가능 |

**한 줄:** Contribution 없이 Maintainer + gate + v4 경로로 **소량·반복 공급**이 가능하고, 무결성 **Remediation이 재검증**되었다. Pilot **성공** — Scale로 **전환**한다.

---

## 1. H1~H5 최종 상태

| Gate | 가설 | 최종 판정 | S 조건 (Pilot 적용) | 근거 요약 |
|------|------|:---------:|:-------------------:|-----------|
| **G-SUPPLY** | H1 Supply | **Continue** | **S1 충족** | 수동·반복 공급 **+8 net** (402→410) · gate 연동 · G2 경로 **기각 아님** |
| **G-INTEGRITY** | H2 Integrity | **Continue** | **S2 충족** | `pre_insert_dedupe_gate` · duplicate 정리 · dedupe **0** |
| **G-IDENTITY** | H3 Identity | **Continue** | **S3 충족** (Pilot) | titles_en **91.71%** · SW1 **1.0** · URV **PASS** · 퇴화 없음 |
| **G-QUALITY** | H4 Quality | **Continue** | **S4 충족** (Pilot) | `quality_gate --strict` **PASS** · invalid_en **0** |
| **G-PLATFORM** | H5 Platform | **Continue** | **S5 기록** | rebuild **~1.9 s** · index **~298 KB** @ 410작 |

```
Pilot 종료 Gate 상태:

  H1 Continue ──► H2 Continue ──► H3 Continue ──► H4 Continue
                                        │
                                        └── H5 Continue (Informational)
```

| 교차 규칙 | 적용 |
|-----------|------|
| R-X1 H1 Stop | **미발동** |
| R-X2 H2 Pause | **1차 발동** → Remediation + duplicate 정리 후 **해제** |
| R-X3 H3/H4 Pause | **미발동** |
| R-X5 Critical Continue + H2 Pause | **해소** — Pilot **정상 종료** |

---

## 2. Pilot 기간 주요 발견 사항

### 2.1 공급 (H1 · O1 · O14)

| 발견 | 내용 |
|------|------|
| Maintainer v4 경로 | `shardHexForWorkId` + hash shard **동작** |
| 반복 가능성 | `a5_pilot_supply_batch` — 3배치 × 2작, **0 blocked**, 배치마다 전 gate **PASS** |
| Expansion batch6 | v3 샤드 경로로 apply **실패** → 롤백 — cohort **대량 apply 미검증** |
| add(B) | **미개방** 유지 — O14 전제 **유지** |

### 2.2 무결성 (H2 · O4)

| 발견 | 내용 |
|------|------|
| 1차 insert | 수동 3작 → fuzzyTitle **3건** (sub_ ↔ wk_) — gate **없음** |
| gate 부재 | insert **후** dedupe만으로는 **선제 차단 불가** 확인 |
| Remediation 후 | workId · legacyIds · fuzzyTitle **선행 검사** — 신규 insert **0 duplicate** |
| Expansion cohort | batch5 **45** · batch6 **37**건 **BLOCK** (legacyIds→wk_) — 의도된 동작 |

### 2.3 Identity·Quality (H3 · H4)

| 발견 | 내용 |
|------|------|
| titles_en | 402 **91.54%** → 410 **91.71%** — **PASS** 유지 |
| external_id | 201건 고정 — **49.02%** (희석, baseline cohort 동일) |
| 회귀 | SW1 recall@10 **1.0** · URV **PASS** |
| quality_gate | Pilot 전 구간 **PASS** · invalid_en **0** |
| 미관측 | O7 (backlog vs insert) · O6 (Economics) · O9 (semantic) |

### 2.4 Platform (H5 · O11)

| 발견 | 내용 |
|------|------|
| rebuild | **~1.9 s** @ 410작 — 부담 **낮음** |
| shards | 330 → **337** |
| search_index | **~298 KB** |
| 미관측 | O12 franchise 큐 · O3 G2 throughput |

### 2.5 Registry 궤적

| 시점 | works | 비고 |
|------|------:|------|
| Baseline | 402 | Phase 2 COMPLETE |
| Pilot 1차 insert | 405 | 수동 3작 |
| H2 smoke | 407 | gate 통과 +2 |
| Duplicate 정리 | 404 | sub_ 3건 제거 |
| H1 반복 공급 | **410** | 3배치 +6 |

---

## 3. Remediation 결과

### 3.1 조치

| # | 조치 | 산출 |
|---|------|------|
| 1 | `tool/pre_insert_dedupe_gate.dart` | workId · legacyIds · fuzzyTitle 선행 검사 |
| 2 | `seed_expansion_batch5/6` v4 hex + gate 연동 | `registry_builder` **정합** |
| 3 | H2 smoke insert +2 | 신규 duplicate **0** |
| 4 | Duplicate 정리 (sub_ 3건 제거, wk_ 유지) | fuzzyTitle **3 → 0** |
| 5 | `tool/a5_pilot_supply_batch.dart` | H1 반복 공급 **3회 성공** |

### 3.2 재검증

| 검증 | Remediation 후 | H1 반복 공급 후 |
|------|:--------------:|:---------------:|
| `registry_builder` | PASS | PASS |
| `quality_gate --strict` | PASS | PASS |
| `dedupe_linter` | 0 duplicate | 0 duplicate |
| Coverage Dashboard | titles_en PASS | titles_en **91.71%** PASS |

### 3.3 H2 Gate 궤적

```
1차 Pilot insert  →  O4 fuzzyTitle 3  →  H2 Pause (R-X2)
        │
        ▼
Remediation (gate + v4 경로 + smoke)
        │
        ▼
Duplicate 정리  →  dedupe 0  →  H2 Continue
        │
        ▼
H1 반복 공급 3회  →  dedupe 0 유지  →  H2 Continue (확인)
```

---

## 4. Pilot Success 여부

**기준:** [a5-pilot-charter.md](a5-pilot-charter.md) §5.2

```
Pilot 성공  IF  S1 AND S2
            AND S3·S4 기각 아님
            AND S5 기록됨
```

| 조건 | 판정 | 근거 |
|------|:----:|------|
| **S1** G-SUPPLY | **충족** | 공급 경로 존재·측정 · 반복 insert 성공 · G2 **기각 아님** |
| **S2** G-INTEGRITY | **충족** | O4 **수용** — gate + duplicate 정리 · dedupe **0** |
| **S3** G-IDENTITY | **충족** (Pilot) | 퇴화 신호 없음 · Pause **미발동** |
| **S4** G-QUALITY | **충족** (Pilot) | gate 동작 확인 · Pause **미발동** |
| **S5** G-PLATFORM | **기록됨** | O11·O13 수치 · H5 Continue |

| 항목 | 결과 |
|------|------|
| **Pilot Success** | **예** |
| Stop 발생 | **없음** |
| Critical Gate 최종 | **H1·H2 Continue** |

**주의:** Pilot 성공 ≠ A5 전체 **Supported** 선언. Assumption A5 **Supported**는 Gate Review §5 **S1~S4 전부 Scale에서 확정** 후 판정 ([a5-pilot-charter.md](a5-pilot-charter.md) §5.2).

---

## 5. Scale 단계 진입 가능 여부

**기준:** [a5-pilot-charter.md](a5-pilot-charter.md) §6.4

| 조건 | 판정 |
|------|:----:|
| §5.2 Pilot 성공 | **충족** |
| S1·S2 통과 | **예** |
| S3·S4 Pause | **아님** (Continue) |
| Stop | **없음** |

| 항목 | 판정 |
|------|:----:|
| **Scale 준비 착수** | **가능 (GO)** |

### Scale 이관 항목 (Pilot 미관측 · 잔여)

| ID | 항목 | Pilot 상태 |
|----|------|------------|
| O3 | G2 throughput | **Scale** |
| O6 | Economics runner | **Scale** |
| O7 | enrich backlog vs insert | **Scale** |
| O8 | 50k governance 주기 | **Scale** |
| O9 | semantic spot-check | **Scale** |
| O12 | franchise 큐 | **Scale** |
| — | Expansion cohort **대량 apply** | **Scale** (gate 연동은 **확인**) |

### Scale 진입 시 전제 (변경 없음)

| # | 전제 |
|---|------|
| T1 | Contribution add(B) **미개방** |
| T2 | Phase 2 **구조 고정** — 구조 변경 예외 **미발동** |
| T3 | `pre_insert_dedupe_gate` **유지** — insert 전 검사 **필수** |
| T4 | 50k **전량 달성**은 Scale 목표 — Pilot 비목표 **유지** |

### Assumption A5 방향

| 판정 | 근거 |
|------|------|
| **Unsupported** | **아님** — 공급·무결성·gate·회귀 **동작** |
| **Deferred** | **유지** — O3·O6·O7·O8·O9·대량 Expansion **Scale 미검증** |
| **Supported 후보** | Scale에서 S1~S4 **확정** 후 |

---

## 6. Pilot 비범위 준수

| 항목 | 준수 |
|------|:----:|
| 50k 달성 | **예** (미시도) |
| 구조 변경 | **예** (v4 스키마·shard 모델 유지) |
| 신규 Charter/Review (Pilot 중) | **예** (기존 산출만 갱신) |
| add(B) 개방 | **예** (미개방) |

---

## 7. 산출물

| ID | 문서 | 상태 |
|----|------|:----:|
| P1 | [a5-pilot-observation-log.md](a5-pilot-observation-log.md) | **확정** |
| P2 | [a5-pilot-gate-decision-record.md](a5-pilot-gate-decision-record.md) | **확정** |
| P3 | **본 문서** | **최종 확정** |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — H2 Pause · **조건부 완료** |
| 2026-06-09 | **최종 확정** — H2 Remediation · duplicate 정리 · H1 반복 공급 반영 · Pilot **성공** · Scale **GO** |
