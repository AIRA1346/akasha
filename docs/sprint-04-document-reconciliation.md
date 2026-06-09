# Sprint 04 Documentation Reconciliation

> **목적:** Sprint 04 관련 문서의 **현재 진실(SSOT)** 확정  
> **기준일:** 2026-06-09 · Registry **430 works** · externalId **201 (46.74%)**  
> **대상:** 지정 6건 + 교차 참조 문서

**금지 준수:** 기존 문서 **수정 없음** · ADR **없음** · 구현 **없음** · **분석만**

---

## Executive Summary — SSOT 한 줄

| 질문 | SSOT |
|------|------|
| **지금 Registry·coverage는?** | [sprint-04-baseline-report.md](sprint-04-baseline-report.md) · [project-status-snapshot.md](project-status-snapshot.md) — **430 / 201 / 46.74%** |
| **잔여 E1 15건·품질 판정은?** | Phase B 체인: [e1-audit](sprint-04-e1-audit.md) → [high-risk-disposition](sprint-04-high-risk-disposition.md) → [post-gate](sprint-04-e1-post-gate-audit.md) → [e4-effectiveness](sprint-04-e4-effectiveness-review.md) |
| **Sprint 04 1차 실행(apply 141건)은?** | [sprint-04-final-review.md](sprint-04-final-review.md) — **@402 시점 아카이브** · 현재 운영 진실 **아님** |
| **G2 50% 달성 여부 (현재)?** | **미달** (215 필요 · **-14**) — baseline · post-gate **일치** |
| **G2 50% 달성 (과거 @402)?** | **달성** (201/402) — final-review **해당 시점만 유효** |

---

## 1. 현재 유효 문서

### 1.1 SSOT 계층

```
┌─────────────────────────────────────────────────────────┐
│  L0  project-status-snapshot.md  (@430 운영 기준선)      │
├─────────────────────────────────────────────────────────┤
│  L1  sprint-04-baseline-report.md  (Phase A 수치·cohort) │
├─────────────────────────────────────────────────────────┤
│  L2  Phase B (apply 전 · @430 동일 cohort 15건)          │
│      e1-audit → high-risk-disposition                    │
│      → post-gate-audit → e4-effectiveness-review         │
├─────────────────────────────────────────────────────────┤
│  L3  externalid-quality-gate-rules.md (정책 초안 ·       │
│      B-5 분석과 E4 항목 **불일치** — §4 참고)             │
└─────────────────────────────────────────────────────────┘
```

### 1.2 문서별 유효 범위

| 문서 | 역할 | 상태 | SSOT 범위 |
|------|------|:----:|-----------|
| [sprint-04-baseline-report.md](sprint-04-baseline-report.md) | @430 **측정 전** baseline · E1 15 · G2 갭 | **active** | Registry 수 · coverage · cohort **상한** |
| [sprint-04-e1-audit.md](sprint-04-e1-audit.md) | Phase B **수동** 위험 감사 (LOW/MED/HIGH) | **active** | 15건 **severity** · LOW 7 apply 후보 |
| [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md) | HIGH 4건 **disposition** | **active** | 144·266·270·277 **조치 코드** |
| [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) | Rule E1–E5 **시뮬레이션** | **active** | AUTO/REVIEW/BLOCK **건수** · gate 적용 시 coverage |
| [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) | E4 **실효성** · FALSE_REVIEW | **active** | E4 **정책 권고** (overlap 폐기) |
| [sprint-04-final-review.md](sprint-04-final-review.md) | 1차 Sprint **실행 완료** 기록 | **superseded†** | @402 · +141 apply · **역사** |

† 폐기가 아니라 **시점 한정 아카이브** — 본 reconciliation이 **superseded 관계** 정의.

### 1.3 교차 SSOT (본 6건 외 · 읽을 때 함께)

| 문서 | 관계 |
|------|------|
| [project-status-snapshot.md](project-status-snapshot.md) | L0 — gate·coverage **운영** |
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | Rule **초안** (B-3) — E4는 B-5와 **정책 충돌** |
| [sprint-04-charter.md](sprint-04-charter.md) | Charter **@402** — 수치 **구식** |
| [doc-inventory-externalid.md](doc-inventory-externalid.md) | 문서 인벤토리 |

---

## 2. 폐기 또는 Superseded 문서

| 문서 | 판정 | 근거 |
|------|------|------|
| **sprint-04-final-review.md** | **superseded** (현재 진실) | @**402** · G2 **달성** · audit blocking **0** · Sprint **종료 GO** — 이후 Scale **+28** · Phase B **재감사**로 **서사 분기** |
| *(없음)* | **폐기(deprecated) 아님** | final-review는 **1차 실행 증빙**으로 **보존** |

### Superseded 관계 (권고 표기 — 미적용)

| 구 문서 | 신 SSOT | superseded 항목 |
|---------|---------|-----------------|
| final-review §Executive | baseline-report | Registry **402→430** · coverage **50%→46.74%** |
| final-review §8.2 「Sprint 종료 GO」 | Phase B 체인 | 잔여 15건 **품질 재검토 중** · 무조건 apply **아님** |
| final-review §5.2 「blocking 0」 | e1-audit | runner syntactic **0** ≠ semantic HIGH **4** |
| final-review §8.2 「남은 15작 NO-GO」 | e1-audit · post-gate | **일치**(즉시 apply 금지) — **이유**는 final=G2 달성 vs Phase B=**품질** |

---

## 3. 수치 충돌

### 3.1 충돌 매트릭스

| 지표 | final-review | baseline · Phase B · snapshot | 해석 |
|------|-------------:|--------------------------------:|------|
| **Registry works** | **402** | **430** | Scale **+28** after 1차 Sprint |
| **externalId count** | **201** | **201** | **동일** — 신규 작품에 id **미부착** |
| **coverage %** | **50.0%** (201/402) | **46.74%** (201/430) | 분모 증가로 **rate 하락** |
| **시작 coverage** | **14.9%** (60/402) | *(baseline은 시작 미기록)* | 1차 Sprint **전** 상태 |
| **G2 50% (현재)** | **PASS** (@402) | **FAIL** (@430, **-14**) | **둘 다 사실** · **시점** 다름 |
| **E1 잔여 cohort** | **15** (미적용) | **15** | **일치** |
| **E1 적용 (1차)** | **110** (+ E2 31) | — | 1차 run **만** 해당 |
| **E1 cohort audit OK** | **blocking 0** (runner) | HIGH **4** · LOW **7** (manual) | **감사 깊이** 다름 |
| **E1만 적용 시 예상** | — | **216/430 = 50.23%** | baseline **기계적 상한** |
| **Post-gate AUTO_APPROVE** | — | **0** · REVIEW **7** | gate 시뮬 **미적용** 상태 |

### 3.2 시계열 (충돌 해소)

```
@402  Sprint 04 1차 apply (+141)  →  201/402 = 50.0%  G2 PASS
         │  (final-review SSOT)
         ▼
      A5 Scale +28 works
         │
         ▼
@430  externalId still 201  →  201/430 = 46.74%  G2 FAIL (-14)
         │  (baseline-report SSOT)
         ▼
      Phase B: 15건 재감사 · apply 보류
         │  (e1-audit ~ e4-effectiveness SSOT)
         ▼
      (미래) partial apply TBD
```

### 3.3 권고: 수치 인용 규칙

| 맥락 | 인용 |
|------|------|
| **현재 운영·Gate** | **430** · **46.74%** · G2 **215** |
| **1차 Sprint 성과** | **402** · **50.0%** · +141 · automation 100% |
| **잔여 cohort** | **15** · baseline cohort 목록 |
| **품질 이후 예상** | post-gate 표 (AUTO 0 / REVIEW +7 / BLOCK 8) |

---

## 4. 정책 충돌

### 4.1 Sprint 종료 vs Phase B 지속

| 출처 | 정책 | 충돌 |
|------|------|------|
| final-review §8 | Sprint 04 **종료 GO** · G2 **인정** | Phase B **미완** — 15건·gate **미확정** |
| e1-audit §5 | **일괄 apply 비권고** · HIGH 제외 | final은 15건 **의도적 미적용** (G2 이미 달성) |
| post-gate §5 | Gate 적용 시 G2 **불가** (AUTO 0) | baseline **기계적** 적용 시 G2 **가능** |

**해소:** Sprint 04를 **두 레이어**로 읽는다.

| 레이어 | 내용 | SSOT |
|--------|------|------|
| **04-R1** Economics 검증 @402 | +141 apply · G2 달성 | final-review |
| **04-R2** Quality 잔여 @430 | 15건 · gate · disposition | Phase B |

**04-R1 종료**와 **04-R2 진행**은 **동시에 참** — final-review 「종료」는 **R1만** 의미하도록 **superseded 해석** 필요.

### 4.2 E4 (title similarity) 정책

| 출처 | E4 정책 |
|------|---------|
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) (B-3 초안) | token overlap **< 0.15** → **REVIEW** |
| [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) (B-4) | 위 규칙 **적용 시** 15/15 발화 · AUTO **0** |
| [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md) (B-5) | overlap **단독 유지 비권고** · 교차게임 사전 **only** 권고 |

| 충돌 유형 | 판정 |
|-----------|------|
| rules vs B-5 | **초안 vs 실측 권고** — **구현 전** 정책 미확정 |
| **현재 SSOT (E4 정책)** | **B-5** — overlap 단독 **채택 비권고** · rules 문서 E4 §는 **수정 대기** |

**E4 사용 여부 (통합 권고안):**

| Rule | 권고 |
|------|------|
| E1·E2·E3·E5 (attach gate) | **유지** (B-4 실효 확인) |
| E4 overlap | **비사용** (B-5) |
| E4 교차게임 REVIEW | **조건부 유지** (TRUE_REVIEW 3건) |

### 4.3 apply 권고 충돌 (15건)

| 출처 | 권고 |
|------|------|
| e1-audit | LOW **7** 1차 후보 · HIGH **4** 제외 |
| post-gate | AUTO **0** · REVIEW **7** (E4) |
| e4-effectiveness | REVIEW 7 = **FALSE_REVIEW** → 인적 승인 시 attach **가능** |
| high-risk-disposition | 277 **DO_NOT_APPLY** · 144·270 **MANUAL_FIX** |

**해소 SSOT:** **작품별** disposition (high-risk-disposition) > **일괄** severity (e1-audit).  
**집계:** 안전 무인 attach **0~7** (E4 정책에 따라) · **절대 15 전량 아님**.

---

## 5. Rule ID 충돌

### 5.1 세 가지 「E1」 네임스페이스

| 네임스페이스 | 문서 | E1 의미 | E2 의미 |
|--------------|------|---------|---------|
| **Sprint cohort** | charter · baseline · final-review | **Steam** attach 경로 | **TMDB** poster 경로 |
| **Governance enrich** | [coverage-quality-governance.md](coverage-quality-governance.md) §4.2 | **invalid-en 가드** | **출처 매칭** |
| **externalId attach gate** | quality-gate-rules · post-gate · e4-review | **Site Error** BLOCK | **Save** prefix BLOCK |

**충돌 심각도:** **높음** — 동일 문서군(Sprint 04) 안에서 **cohort E1** vs **gate E1** **동시 사용**.

### 5.2 ID 대조표 (혼동 방지)

| ID | Sprint cohort | Governance §4.2 | Attach gate (B-3) |
|:--:|---------------|-------------------|-------------------|
| E1 | Steam cohort | invalid-en 가드 | Site Error |
| E2 | TMDB cohort | 출처 매칭 | Save prefix |
| E3 | — | fallback 체인 | dup attach |
| E4 | — | registry_builder | title similarity |
| E5 | — | Coverage KPI | dup across wk_ |
| E6–E8 | — | 회귀·invalid scan·spot-check | — |

### 5.3 rename 필요 여부

| 대상 | rename 권고 | 제안 접두사 |
|------|:-----------:|-------------|
| Attach gate E1–E5 | **예** | **XG1–XG5** 또는 **RB-X1–X5** |
| Sprint cohort E1/E2 | **선택** | **Cohort-Steam / Cohort-TMDB** (문서 각주) |
| Governance E1–E8 | **아니오** (기존 Phase 2 고정) | — |

**최소 조치 (rename 없이):** Sprint 04 Phase B 문서에 **「Gate E*」 vs 「Cohort E*」** 각주 — **superseded 표기와 별도**.

---

## 6. 문서 간 의존·중복

| 중복 내용 | 출현 | SSOT |
|-----------|------|------|
| 15건 cohort 표 | baseline · e1-audit · post-gate · e4 | **e1-audit** (severity) + **post-gate** (verdict) |
| HIGH 4건 | e1-audit · disposition | **disposition** (조치) |
| G2 / coverage 표 | baseline · e1-audit §5 · post-gate §4 | **baseline** (기계적) · **post-gate** (gate 후) |
| E4 overlap 0.0 | post-gate · e4-effectiveness | **동일** — 중복 **허용** (측정 vs 해석) |

**신규 설계 불필요** — 기존 6건 + reconciliation으로 **읽기 순서**만 확정.

---

## 7. 권고안 (문서 작업 — 본 reconciliation에서 미실행)

### 7.1 Superseded 표시

| 문서 | 권고 |
|------|------|
| **sprint-04-final-review.md** | 상단 배너: `Superseded for @430 operations — see sprint-04-document-reconciliation.md` · **1차 실행 @402 아카이브** |
| **sprint-04-charter.md** | `Superseded baseline: 402 → see baseline-report @430` |

### 7.2 Rename

| 항목 | 필요 | 비고 |
|------|:----:|------|
| Attach gate E1–E5 → XG* / RB-X* | **권고** | 구현·문서 개정 **동시** |
| 파일명 변경 | **불필요** | 내용·각주로 해소 가능 |

### 7.3 README 반영

| 항목 | 현재 | 권고 |
|------|------|------|
| Sprint 04 | `sprint-04-final-review.md` 만 | **두 섹션**: `04-R1 아카이브` · `04-R2 Phase B` (5건 링크) |
| SSOT pointer | 없음 | `sprint-04-document-reconciliation.md` **추가** |
| project-status-snapshot | 운영 섹션에 있음 | Sprint 04 **L0** 로 명시 |

### 7.4 정책 문서 동기화 (후속 · 본 작업 외)

| 문서 | 항목 |
|------|------|
| externalid-quality-gate-rules.md | E4 § **B-5 반영** · Gate/Cohort **용어 분리** |
| coverage-quality-governance.md | attach gate **참조** · ID 충돌 **각주** |

### 7.5 ADR

| 판정 | **불필요** (당분간) |
|------|---------------------|
| 근거 | 정책 **미확정** · 문서 reconciliation으로 **SSOT 충분** |

---

## 8. 읽기 순서 (SSOT 확정)

### 8.1 현재 상태만 알 때

1. [project-status-snapshot.md](project-status-snapshot.md)  
2. [sprint-04-baseline-report.md](sprint-04-baseline-report.md)

### 8.2 잔여 15건·품질·Gate

1. [sprint-04-e1-audit.md](sprint-04-e1-audit.md)  
2. [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md)  
3. [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) *(초안 · E4 주의)*  
4. [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md)  
5. [sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md)

### 8.3 1차 Sprint 역사

1. [sprint-04-final-review.md](sprint-04-final-review.md) *(superseded · @402)*

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 6건 비교 · SSOT · 충돌 · 권고안 |
