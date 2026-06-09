# A5 Gate Decision Record

> **세션:** 2026-06-09 A5 Pilot  
> **근거:** [a5-pilot-observation-log.md](a5-pilot-observation-log.md) · [a5-verification-charter.md](a5-verification-charter.md) §4

---

## 판정 요약

| 순서 | 가설 | Gate | 판정 | 시각 (UTC+9) |
|:----:|------|------|:----:|--------------|
| 1 | **H1** Supply | G-SUPPLY | **Continue** (반복 공급 강화) | 2026-06-09 |
| 2 | **H2** Integrity | G-INTEGRITY | **Pause** → **Continue** | 2026-06-09 |
| 3 | **H3** Identity | G-IDENTITY | **Continue** | 2026-06-09 |
| 4 | **H4** Quality | G-QUALITY | **Continue** | 2026-06-09 |
| 5 | **H5** Platform | G-PLATFORM | **Continue** | 2026-06-09 |

---

## H1 — G-SUPPLY · **Continue** (반복 공급 강화)

**증거:** O1 +3 net (수동 v4) · O14 add 미개방 · batch6 dry-run 40건 cohort 존재 · **H1 반복 공급 +6** (404→410).

### 반복 공급 관측 (2026-06-09)

| 항목 | 결과 |
|------|------|
| 경로 | Maintainer · `a5_pilot_supply_batch` · `pre_insert_dedupe_gate` · v4 hex shard |
| 배치 | 3회 × 2작 = **+6** |
| blocked | **0** (3회 연속) |
| 배치 후 검증 | `registry_builder` · `quality_gate --strict` · `dedupe_linter` · Coverage Dashboard — **전부 PASS** |
| dedupe | **0** 유지 (신규 fuzzyTitle 없음) |

**판정 근거:**
- 공급 경로 **존재·측정 가능** — **3회 반복 insert 성공** (일회성 아님)
- gate **선행 통과** 후 insert만 반영 — H2 Remediation과 **동일 원칙 유지**
- Expansion `seed_expansion_batch6`는 v4 registry에서 **apply 실패** — cohort 경로 **부분 가동** (변경 없음)
- G2 경로 **기각 신호 없음** · Stop 조건 **미충족**

**잔여 리스크:** Expansion cohort **대량 apply** 미검증 · 파이프라인–v4 **연동 공백** (운영·도구 과제, 구조 변경 아님).

---

## H2 — G-INTEGRITY · **Pause** (1차) → **Continue** (Remediation 후)

### 1차 (Pilot insert) — **Pause**

**증거:** O4 — insert 후 `dedupe_linter` **3 fuzzyTitle** (sub_ ↔ wk_).

**조치:** 추가 insert **중단** (R-X2).

### Remediation (2026-06-09)

| # | 조치 | 결과 |
|---|------|------|
| 1 | `pre_insert_dedupe_gate.dart` — workId · legacyIds · fuzzyTitle | **구현** |
| 2 | `seed_expansion_batch5/6` — v4 hex + gate | **정합** |
| 3 | smoke insert **+2** (405→407) | dedupe **3→3** (신규 0) |

**2차 판정 근거:**
- O4 **수용** — 신규 insert 경로에서 **선제 차단** 동작 확인
- batch6 37·batch5 45건 **BLOCK** (legacyIds) — 중복 cohort **유입 차단**
- 기존 **3 fuzzyTitle** — **미정리** (별도 merge/remove **대기**)

**현재 조치:** gate **통과** insert만 허용 · Expansion **gate 연동** apply 가능.

### Duplicate 정리 (승인 실행)

| 항목 | 결과 |
|------|------|
| sub_ 3건 제거 | **완료** |
| works | 407 → **404** |
| fuzzyTitle | 3 → **0** |
| `registry_builder` | **PASS** |
| `quality_gate --strict` | **PASS** |

**H2 상태:** Remediation **완료** — 선제 gate + **기존 중복 정리** · O4 **수용**.

---

## H3 — G-IDENTITY · **Continue**

**증거:** O5 titles_en **PASS** (91.60%≥0.9) · O10 SW1 **1.0** · URV **PASS**.

**판정 근거:**
- Phase 2 baseline **대비 퇴화 패턴 없음** (titles_en·회귀)
- external_id **49.63%** — 희석 신호 있으나 dashboard PARTIAL은 **402부터** 동일 cohort 201건
- O7 **미결** — enrich backlog **미관측**

**잔여:** O7·O6 **후속 관측** · Scale에서 A2·A3 **확정**.

---

## H4 — G-QUALITY · **Continue**

**증거:** `quality_gate --strict` **PASS** · invalid_en **0** · source_breakage **0**.

**판정 근거:**
- Pilot 볼륨에서 gate **실행 가능** (O8 샘플 충족)
- O9 semantic **미집행** — 기각 신호 **없음**

---

## H5 — G-PLATFORM · **Continue**

**증거:** O11·O13 — rebuild **~1.9 s** · index **~298 KB** · **410작** (H1 +6 후).

**판정 근거:** Informational — 부담 **가시화** · 단독 Stop **없음**.

---

## 교차 규칙

| 규칙 | 적용 |
|------|------|
| R-X1 H1 Stop | **미발동** |
| R-X2 H2 Pause | **1차 발동** → Remediation + duplicate 정리 후 **해제** |
| R-X3 H3/H4 Pause | **미발동** |
| R-X5 Critical Continue + H2 Pause | Pilot **관측 종료** · Scale **조건부** |
