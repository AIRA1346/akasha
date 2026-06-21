# externalId Quality Gate Rule Set — 초안

> **Reviewed after Sprint 04 B-5** — E4는 [sprint-04-e4-effectiveness-review.md](archive/sprint-04-e4-effectiveness-review.md) 실측 반영 (token overlap 단독 **폐기**).

> **단계:** Sprint 04 Phase B-3 (규칙 정의 · **구현 금지**)  
> **목적:** externalId attach **파이프라인 이전**에 차단 가능한 오류를 **문서화**  
> **근거:** [sprint-04-high-risk-disposition.md](archive/sprint-04-high-risk-disposition.md) HIGH 4건 · [sprint-04-e4-effectiveness-review.md](archive/sprint-04-e4-effectiveness-review.md)  
> **기준일:** 2026-06-09 · Registry **430 works** · externalId coverage **46.74%**

**금지 (본 문서):** 코드 구현 · Registry apply · enrich 실행

**관계:** 기존 [quality-gate-mvp.md]](../policy/quality-gate-mvp.md)는 `titles.en` **syntactic** 축 — 본 Rule Set은 **externalId attach 전용** **semantic·integrity** 축.

---

## Executive Summary

| Rule | 조건 (요약) | 조치 | Release Block |
|:----:|-------------|------|:-------------:|
| **E1** | `titles.en == "Site Error"` | **BLOCK** | **예** |
| **E2** | `titles.en` startsWith `"Save "` | **BLOCK** | **예** |
| **E3** | candidate externalId **이미 다른 work**에 부착 | **BLOCK** | **예** |
| **E4** | **교차게임 사전** 충돌 · **identity 붕괴** 신호 | **REVIEW** | 아니오† |
| **E5** | duplicate externalId across `wk_` | **BLOCK** | **예** |

† E4 REVIEW 누적 시 운영 정책으로 release hold 가능 — 기본은 **non-blocking queue**.

**HIGH 4건 커버:** E1·E2·E3·E5로 **3건 완전 차단** · **1건(277) E4 보조** · 144는 E3/E5 동일.

---

## 1. 적용 시점 · 범위

```
externalId cohort 선정 (E1 Steam / E2 TMDB)
        │
        ▼
┌───────────────────────────────────┐
│  Rule E1–E5 (attach PRE-check)     │  ← 본 문서
└───────────────────────────────────┘
        │ PASS / REVIEW cleared
        ▼
   shard patch (apply)
        │
        ▼
   registry_builder · quality_gate MVP · URV
```

| 필드 | 값 |
|------|-----|
| **대상 작업** | `coverage_sprint_04_external_id` 및 후속 externalId attach |
| **대상 provider** | Sprint 04 in-scope: **steam** · **tmdb** |
| **대상 workId** | `wk_*` (Maintainer `sub_*` stub는 **별도 정책**) |

---

## 2. Rule 정의

### Rule E1 — Site Error placeholder

| 항목 | 내용 |
|------|------|
| **조건** | `titles.en` **정확히** `"Site Error"` (trim 후, case-sensitive) |
| **조치** | **BLOCK** |
| **목적** | Sprint 03 `steam_fetch` **HTTP/파싱 실패** placeholder가 남은 work에 externalId를 붙이지 않는다. identity 층이 **무효**인 상태에서 deterministic poster attach는 **신뢰 검증 불가**. |
| **검출 가능 여부** | **높음** — 문자열 **완전 일치** · 추가 데이터 불요 |
| **false positive 위험** | **매우 낮음** — 정상 게임 타이틀이 `"Site Error"`일 가능성 **무시 가능** |
| **Release block** | **예** — `--release` 모드에서 attach 후보 **전량 제외** · 기존 registry에 이미 존재 시 **별도 RB-E1** (본 Sprint 범위 외) |

**근거 사례:** wk_000000270 (FFXIV) — `titles.en: Site Error` · poster `39210`만으로 E1 runner는 통과했으나 identity **붕괴**.

---

### Rule E2 — Steam store promo scrape

| 항목 | 내용 |
|------|------|
| **조건** | `titles.en` **startsWith** `"Save "` (대소문자: Sprint 03 scrape는 `Save`로 시작) |
| **조치** | **BLOCK** |
| **목적** | Steam 스토어 **할인 배너/캐러셀** 문자열(`Save N% on …`)이 `titles.en`에 기록된 경우 attach 차단. appId가 poster에서 **맞을 수 있으나** 표면형 오염은 [externalid-quality-risk-review.md](externalid-quality-risk-review.md) B1·B9 신호. |
| **검출 가능 여부** | **높음** — prefix 규칙 |
| **false positive 위험** | **낮음** — 정식 영문 타이틀이 `Save `로 시작하는 경우 **극히 드묾**. 확장 시 `Save \d+% on` 정규식 권장 |
| **Release block** | **예** |

**확장 (문서 권장, 본 Rule에 포함):**

```text
^Save\s+\d+%\s+on\s+
```

**근거 사례:** wk_000000266 — `Save 30% on Songs of Conquest - Roots` (ko: 블루 아카이브).

**연관:** Sprint 04 E1 감사 **MEDIUM** 4건(셀레스테·단간론파·MHW·언더테일)도 **동일 Rule**로 선행 차단 가능.

---

### Rule E3 — Candidate key collision (attach-time)

| 항목 | 내용 |
|------|------|
| **조건** | attach **후보** `(provider, externalId)`가 **다른 workId**의 `externalIds.{provider}`에 **이미 존재** |
| **조치** | **BLOCK** |
| **목적** | 단일 attach 트랜잭션 직전 **키 충돌** 방지 — URV exactId·duplicate 검사 **사전화**. |
| **검출 가능 여부** | **높음** — registry 전수 스캔 · O(works) |
| **false positive 위험** | **중간** — franchise 형제·의도적 **동일 store listing** 공유 시 차단. ADR-006·franchise 정책 **예외 화이트리스트** 후속 필요 |
| **Release block** | **예** |

**검사 알고리즘 (개념):**

```text
FOR each candidate (workId W, provider P, id I):
  IF EXISTS work W2 ≠ W WHERE externalIds[P] == I:
    BLOCK(E3, W, existing=W2)
```

**근거 사례:**

| work | candidate | 기존 보유 work |
|------|-----------|----------------|
| wk_000000144 | steam:489830 | wk_000000111 |
| wk_000000277 | steam:2358720 | wk_000000075 |

---

### Rule E4 — Semantic identity mismatch (REVIEW)

| 항목 | 내용 |
|------|------|
| **조건** | 아래 **어느 하나** 해당 시 **REVIEW** (자동 BLOCK **아님**) |
| **조치** | **REVIEW** |
| **목적** | [MATCHING_ERROR](archive/sprint-04-high-risk-disposition.md) — poster-derived appId는 맞지만 **ko/en identity 분리** (니케 vs Wukong). syntactic gate **밖** semantic 불일치 **가시화**. |
| **검출 가능 여부** | **중간** — 교차게임 사전·identity 신호에 **의존** |
| **false positive 위험** | **낮음~중** (B-5) — 정상 로컬라이즈 ko/en은 **미해당** |
| **Release block** | **아니오** (기본) — REVIEW 큐 **인적 확인** 후 proceed |

**REVIEW 트리거 (B-5 확정):**

| # | 신호 | 설명 |
|---|------|------|
| 1 | **교차게임 사전 충돌** | `title`(ko) 토큰·`titles.en` 토큰이 **서로 다른 작품**을 가리킨다고 판정 (예: ko **니케** + en **wukong** · ko **블루 아카이브** + en **songs of conquest**) |
| 2 | **identity 붕괴 신호** | identity 층이 attach 신뢰 검증 **불가** — `titles.en` **placeholder·파싱 실패 잔재** 등 (**`Site Error`는 E1이 선행 BLOCK**) · ko/en이 **동일 작품이 아님**이 사전·휴리스틱으로 **확정** |

**폐기 (B-5 · 단독 사용 비권고):**

| 항목 | 내용 |
|------|------|
| token overlap `< 0.15` | cohort 15/15 **오발화** · LOW 7건 **FALSE_REVIEW 100%** — [sprint-04-e4-effectiveness-review.md](archive/sprint-04-e4-effectiveness-review.md) |

**근거 사례:** wk_000000277 — 교차게임 사전 (E3/E5와 **복합**) · wk_000000266 — 교차게임 (E2 **선행 BLOCK**).

**미발화 사례:** wk_000000144 — identity 정상 · wk_000000143 등 LOW 7건 — **정상 로컬라이즈** (E4 **미해당**).

---

### Rule E5 — Duplicate externalId across wk_

| 항목 | 내용 |
|------|------|
| **조건** | 동일 `(provider, externalId)`를 가진 `wk_*` work가 **2건 이상** (후보 포함 시 **가상 부착 후** 검사) |
| **조치** | **BLOCK** |
| **목적** | Registry **전역 무결성** — URV `duplicateExternalKeyPairs`와 **정합**. E3이 **단건 attach** 관점이면 E5는 **집합·배치** 관점 **중복 금지 불변식**. |
| **검출 가능 여부** | **높음** — registry 인덱스 |
| **false positive 위험** | **중간** — E3과 동일 (franchise 의도적 공유). **형제 예외**는 명시적 allowlist |
| **Release block** | **예** |

**E3 vs E5:**

| | E3 | E5 |
|---|----|----|
| 시점 | **후보 1건** attach 직전 | **배치·release** 전 **전역** |
| 질문 | "이 키가 **이미** 쓰이나?" | "`wk_` 공간에 **유일**한가?" |
| HIGH 144 | **차단** | **차단** |
| HIGH 277 | **차단** | **차단** |

---

## 3. Rule × 조치 매트릭스

| Rule | BLOCK | REVIEW | Release Block |
|:----:|:-----:|:------:|:-------------:|
| E1 | ✓ | — | ✓ |
| E2 | ✓ | — | ✓ |
| E3 | ✓ | — | ✓ |
| E4 | — | ✓ | — |
| E5 | ✓ | — | ✓ |

**우선순위 (동시 해당):** E1 → E2 → E3/E5 → E4 — **하나라도 BLOCK**이면 attach **중단**.

---

## 4. HIGH 4건 × Rule 매핑

| work_id | title | E1 | E2 | E3 | E4 | E5 | **attach 전 차단** |
|---------|-------|:--:|:--:|:--:|:--:|:--:|:------------------:|
| wk_000000144 | 스카이림 | — | — | **✓** | — | **✓** | **BLOCK** |
| wk_000000266 | 블루 아카이브 | — | **✓** | — | REVIEW† | — | **BLOCK** |
| wk_000000270 | FFXIV | **✓** | — | — | — | — | **BLOCK** |
| wk_000000277 | 니케 | — | — | **✓** | **REVIEW** | **✓** | **BLOCK** |

† 266: 교차게임 사전으로 E4 **REVIEW** 해당하나 E2가 **선행 BLOCK** → 실무상 E2만으로 충분.

### 사례별 차단 Rule (최소 집합)

| work | **막는 Rule** | 비고 |
|------|---------------|------|
| **144** | **E3** · **E5** | identity 정상 · **중복만** |
| **266** | **E2** | (+ E4 보조) |
| **270** | **E1** | |
| **277** | **E3** · **E5** · **E4** | 3중 · **DO_NOT_APPLY** |

### Rule만으로 **막히지 않는** HIGH 유형

| 유형 | 사례 | 후속 |
|------|------|------|
| 중복이지만 **titles 정상** | 144 | E3/E5 — **차단됨** |
| **잘못된 work**에 이미 attach된 타작품 id | 075 (Wukong명·NIKKE id) | E5 **기존** 위반 — **retroactive REVIEW** (본 Sprint 범위 외) |

---

## 5. 기존 Gate와의 경계

| 층 | 도구 | 본 Rule Set |
|----|------|-------------|
| titles.en **syntax** | `quality_gate` MVP R0–R6 | **비포함** — 상호 보완 |
| TMDB poster ↔ id | `isPosterVerified` | TMDB E2 cohort — **별도** |
| Steam poster ↔ id | *(없음)* | E1–E2가 **간접** 보호 (identity) |
| URV duplicate | `urv_a_validation` | E3/E5가 **사전** 차단 |
| externalId **수량** KPI | `coverage_dashboard` | E1–E5 **무관** — B9 blind spot 해소 목적 |

---

## 6. 구현 시 권장 (문서만 · 미착수)

| 순서 | 항목 |
|:----:|------|
| 1 | `coverage_sprint_04_external_id.dart` **dry-run** 경로에 E1–E5 평가 **삽입** |
| 2 | `quality_gate.dart --release`에 **RB-E*** 블록 추가 |
| 3 | E4 REVIEW 산출 → `externalid_audit_sample.json` **severity: review** |
| 4 | franchise **allowlist** — E3/E5 예외 (문서화 후) |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 Phase B-3 — Rule E1–E5 초안 · HIGH 4건 매핑 |
| 2026-06-09 | **Reviewed after Sprint 04 B-5** — E4 token overlap 폐기 · 교차게임·identity 붕괴 REVIEW |
