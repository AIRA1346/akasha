# Contribution Model Strategy

> **관점:** 운영 모델 · 성장 모델 — 구현 없음  
> **전제:** AKASHA 규모는 5M을 **넘을 수 있다** (10M~50M+ Long Tail).  
> [registry-growth-strategy.md](registry-growth-strategy.md)의 파이프라인 중심 성장에 **커뮤니티·사용자 등록** 역할을 명시한다.

선행 문서:

- [registry-growth-strategy.md](registry-growth-strategy.md) — G0~G4 · Long Tail tier
- [catalog-contribution-roadmap.md](catalog-contribution-roadmap.md) — Contribution vs Expansion
- [data-policy.md](data-policy.md) — Minimal Core · 미러링 금지
- [adr/ADR-004-work-collection-policy.md](adr/ADR-004-work-collection-policy.md) — 2차 창작·인디

---

## 1. Registry인가, Registry Platform인가?

### 1.1 정의

| 모델 | AKASHA에서의 의미 |
|------|-------------------|
| **Registry** | Rune Atelier가 **단일 SoT** — `wk_`·정책·CI·canonical. 사용자는 **소비·아카이브**. |
| **Registry Platform** | SoT·정책·`wk_`는 유지하되, **다수 공급자**가 Minimal Core·Enrich·Fix를 **제안**하고 게이트를 통과하면 반영. |

**판단:** AKASHA는 오늘 **Registry**에 가깝고, 장기적으로 **Registry Platform**으로 진화한다.  
다만 Wikipedia/Wikidata식 **개방 편집 플랫폼은 아니다.**

### 1.2 불변 vs 가변

| 불변 (Registry 핵심) | 가변 (Platform 확장) |
|----------------------|----------------------|
| `wk_` 불변 ID | 누가 stub을 **제안**했는가 (provenance) |
| [data-policy](data-policy.md) Fact/Legal 게이트 | 제안 **채널** (파이프라인·유저·파트너) |
| dedupe **auto-merge 금지** (add) | 검수 **자동화 비율** |
| AKASHA taxonomy · Minimal Core | Enrich 속도·tier |
| IP 1카드 · [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md) | Franchise **지연 연결** |

### 1.3 진화 경로 (가설)

```
Phase R0  Registry          402~5k    Maintainer + 엄선
Phase R1  Registry+         5k~50k    + Contribution(fix↑) + Pipeline
Phase R2  Platform-lite     50k~500k  + Contribution(add↑) + confidence tier
Phase R3  Platform          500k~5M+  + reputation · Long Tail 공급 주체 전환
Phase R4  Platform-scale    5M~50M+   Pipeline(T0) + Community(T1~T3) 분업 고정
```

**한 줄:** Platform = **「누가 넣느냐」의 다양화**이지, **「무엇이 진실이냐」의 민주화**가 아니다.

---

## 2. 사용자 등록을 언제 허용할 것인가?

「사용자 등록」을 세 가지로 분리한다.

| 유형 | 설명 | 오늘 (402) |
|------|------|------------|
| **A. 볼트 직접 등록** | Registry에 없어도 **개인 .md** 생성 | ✅ (Tier 2) |
| **B. Contribution add** | akasha-db에 **공식 Work** 제안 | 🔶 UI·export 골격 |
| **C. Contribution fix** | 기존 Work **수정** 제안 | 🔶 동일 |

아래는 **B·C가 Registry(Platform)에 미치는 시점** 기준.

### 2.1 규모별 권장 (초안)

| 규모 | 볼트 직접 (A) | fix (C) | add (B) | 근거 |
|------|---------------|---------|---------|------|
| **402** | ✅ 유지 | 🔶 Maintainer만 실질 반영 | ❌ **일반 사용자 add 불가** | dedupe·품질 기반선 없음 |
| **5k** | ✅ | ✅ **공개** (큐·승인제) | ⚠️ **제한** — gap 신고 → maintainer가 add | 주류는 파이프라인이 채움 |
| **50k** | ✅ | ✅ + AI 검증 보조 | ✅ **Long Tail add** (승인제·일 상한) | 희귀·인디 gap 본격 |
| **500k** | ✅ | ✅ + 일부 auto-merge(fix) | ✅ tier별 — T1/T2 add 확대 | 큐 폭발 · reputation 도입 |
| **5M** | ✅ | ✅ auto-merge 확대 (필드 단위) | ✅ **T2/T3 주 공급** (T0는 파이프라인) | Long Tail without community **불가** |
| **5M+** | ✅ | ✅ | ✅ **Platform 핵심 채널** | 절판·지역·니치 |

### 2.2 시점 답 (질문 2 요약)

| 마일스톤 | 사용자 Registry add (B) |
|----------|---------------------------|
| **5k** | **아직 전면 불가** — fix·gap 보고만. add는 maintainer 대행. |
| **50k** | **허용 시작** — 승인제 · Long Tail·인디·오매핑 수정 중심. |
| **500k** | **확대** — 검증제·confidence · 일일 처리량 상한 필수. |
| **5M** | **Long Tail의 주력** — 파이프라인은 T0 유지, T2/T3는 커뮤니티. |

**볼트 직접 등록(A)** 은 **모든 규모에서 허용** — Registry 부재를 사용자 기록이 막지 않음 ([catalog-ownership](catalog-ownership.md) Tier 2).

### 2.3 5M 이후

- **B add** 는 T0(주류)에 **닫히고** T1~T3에 **열림** — 주류 오염 방지.
- 신규 주류 IP는 **Expansion Pipeline 전용** + maintainer veto.
- 50M 스케일에서는 **지역·언어 커뮤니티 큐** 분할 (운영 모델만; 인프라는 별도).

---

## 3. 커뮤니티 없이 도달 가능한 규모

### 3.1 공급자 = Maintainer + 반자동 + Expansion Pipeline 만

| 구간 | 누적 Work (가설) | 전제 |
|------|------------------|------|
| G0→G1 | **~5,000** | 수동·소배치 · 1~2 FTE maintainer |
| G1→G2 | **~30,000~50,000** | Pipeline MVP · 주류 카테고리 |
| G2→G3 | **~150,000~300,000** | 다소스 Signal · AI normalize · dedupe queue **처리 가능 한도** |
| **천장 (커뮤니티 0)** | **~300,000~500,000** | enrich SLA 붕괴 전 · **주류·준주류** 위주 |

### 3.2 천장을 넘으면

| 요인 | 설명 |
|------|------|
| Long Tail 비율 | 절판·희귀는 **외부 DB에도 빈약** — Pipeline 신호 약함 |
| dedupe 큐 | human review **선형 폭발** |
| enrich | titles·alias·franchise **인력 한계** |
| 검색 품질 | stub만 쌓이면 SW1 recall **형식적 통과·실질 실패** |

**결론 (질문 3):**

- **커뮤니티 없이 현실적 상한 ≈ 30만~50만 Work** (주류 중심).
- **5M·5M+** 는 커뮤니티(또는 파트너) **필수** — 파이프라인 단독으로는 **불가**에 가깝다.
- 5M은 [registry-growth-strategy](registry-growth-strategy.md)의 **한 단계**이지 **최종 상한이 아님**.

### 3.3 5M → 50M (플랫폼 가정)

| 채널 | 비중 (가설) |
|------|-------------|
| Expansion Pipeline (T0) | 20% 신규 |
| Contribution add (T1~T3) | **50% 신규** |
| 반자동·파트너 배치 | 20% |
| Maintainer 수동 | 10% |

---

## 4. Long Tail 공급원

[registry-growth-strategy §5](registry-growth-strategy.md#5-long-tail-전략) tier와 정렬.

| Long Tail 유형 | 1차 공급원 | 2차 | Pipeline 적합도 |
|----------------|------------|-----|-----------------|
| **인디** (itch, 자가출판) | Contribution add · 인디 커뮤니티 | Steam/itch Signal 배치 | 중 |
| **절판** (오래된 게임·서적) | **커뮤니티** · 서적 커뮤니티 fix/add | ISBN·아카이브 Signal | **낮음** |
| **희귀** (지역 한정·소수 언어) | **커뮤니티** · 현지 기여자 | Wikidata Signal | **낮음** |
| **동인·팬게임** | Contribution (정책 제한) | — | 낮음 (bulk 금지) |
| **팬픽** | Contribution only | — | **없음** (Pipeline 제외) |
| **오매핑 수정** | Contribution **fix** | linter | 해당 없음 |

**질문 4 답:** Long Tail의 **주요 공급원은 커뮤니티 기여(T1~T3)** 이다.  
Pipeline은 **신호가 있는 주류·준주류**에 한정되고, 절판·희귀는 **사용자·니치 커뮤니티**가 사실상 유일한 확장 경로다.

### 4.1 볼트 고아 작품 → Registry 승격

| 단계 | 정책 |
|------|------|
| A만 존재 (Registry X) | 개인 기록으로 충분 |
| 동일 title 다수 사용자 (미래 신호) | maintainer **후보 큐** — 자동 승격 **금지** |
| Contribution add 승인 | `wk_` 발급 · 볼트·Registry 연결 |

---

## 5. 기여 품질 관리 전략

### 5.1 네 가지 수단 — 역할 분담

| 수단 | 역할 | 적용 시기 |
|------|------|-----------|
| **승인제** | 모든 add · 고위험 fix — human **최종** | R0~R4 **기본** |
| **검증제** | AI·CI가 Fact·policy·dedupe **사전 필터** | R1 (50k~) |
| **평판 시스템** | 기여자 **처리 우선순위·자동화 범위** — 진실 투표 아님 | R2 (500k~) |
| **자동 dedupe 보조** | 후보 생성 · merge **제안** — survivor 결정은 human | R0~ **항상** |

### 5.2 승인제 (Approval)

| 항목 | 규칙 |
|------|------|
| addWork | **항상** human accept → merge ([ADR-004](adr/ADR-004-work-collection-policy.md) 2차 창작) |
| fixWork · 저위험 | 50k+ AI verified → fast track |
| fixWork · 고위험 | title · category · franchise · merge — **항상 human** |
| 거부 | `rejected` + `statusNote` · appeal은 재제출 |

**원칙:** 승인제는 **법무·정체성**의 최후 방어선 — 폐지하지 않는다.

### 5.3 검증제 (Verification)

```
Contribution submitted
  → data_policy_linter (Contribution JSON)
  → catalog_contribution_validate (필드·형식)
  → dedupe_linter (기존 wk_ 후보)
  → confidence score (AI, v3 계획)
       ├─ high:   fix poster/year → auto-accept 후보
       ├─ medium: human queue
       └─ low:    reject 또는 더 많은 Fact 요구
```

| 검증 대상 | 자동 가능 (가설) | human 필수 |
|-----------|------------------|------------|
| posterPath URL | ✅ (denylist 통과) | 오매핑争議 |
| releaseYear | ✅ (externalId 일치) | 불일치 |
| titles.en | ⚠️ (출처 2소스) | 단일 출처 |
| franchise 연결 | ❌ | ✅ |
| addWork 신규 IP | ❌ | ✅ |

### 5.4 평판 시스템 (Reputation)

**목적:** 품질 **대리 지표**가 아니라 **큐 처리 효율**.

| 신호 (가설) | 효과 |
|-------------|------|
| merged fix N건 · reject율 낮음 | fix fast-track 확대 |
| add merged · dedupe 무분쟁 | add 일일 한도 ↑ |
| reject·spam 반복 | add 차단 · fix만 |

**하지 않는 것:**

- 평판으로 canonical **투표** · 다수결이 title 결정
- 평판만으로 **auto-merge add**

**도입 시점:** **500k+** (큐가 human 처리 한도 초과 시).

### 5.5 자동 dedupe 보조

| 동작 | 자동 | human |
|------|------|-------|
| externalId exact duplicate 탐지 | ✅ | merge 승인 |
| fuzzy title 후보 | ✅ | survivor |
| franchise 멤버 vs duplicate 구분 | ⚠️ 힌트 | ✅ |
| add 시 기존 Work 제안 | ✅ | 사용자/UI가 merge 유도 |

[catalog-contribution-roadmap](catalog-contribution-roadmap.md): **auto-merge는 fix·저위험만** — add는 유지.

### 5.6 품질 관리 단계 요약

| 규모 | 승인 | 검증 | 평판 | dedupe 보조 |
|------|------|------|------|-------------|
| 5k | add·fix 전면 | CI only | — | 후보만 |
| 50k | add 전면 | AI + CI | — | 후보 + UI |
| 500k | add tier | AI 필드별 | **도입** | 후보 + fix auto |
| 5M+ | add T1~T3 | 전면 자동화 확대 | **필수** | 전 규모 |

---

## 6. 「존재 우선」vs「품질 우선」균형

### 6.1 두 모드 정의

| 모드 | 목표 | Registry 표현 | 검색·UX |
|------|------|---------------|---------|
| **존재 우선** | 「이 작품이 있다」 | Minimal Core **stub** | tier 0~2 · 낮은 랭킹 |
| **품질 우선** | 「찾고 신뢰할 수 있다」 | Enriched · verified | tier 3+ · SW1·URV 대상 |

**충돌이 아니다** — **레이어 분리**다.

### 6.2 채널별 기본 모드

| 채널 | 기본 모드 | 이유 |
|------|-----------|------|
| Expansion Pipeline (T0) | 존재 → 비동기 enrich | throughput |
| Contribution add (T1~T3) | **존재** (Minimal Core) | Long Tail 발견 |
| Contribution fix | **품질** | 기존 Work 정정 |
| Maintainer 수동 | 품질 (enriched) | 코어 IP |
| 사용자 볼트만 | (Registry 밖) | 개인 기록 |

### 6.3 균형 규칙 (초안)

| # | 규칙 |
|---|------|
| B1 | **등록 게이트** = 존재 (Minimal Core + policy) |
| B2 | **검색 상위 노출** = 품질 (qualityScore · recall 테스트) |
| B3 | stub 폭주 시 — **등록은 계속** · enrich·랭킹으로 희석 |
| B4 | 주류(T0) add는 품질 바가 **높음** (enrich SLA 짧음) |
| B5 | Long Tail(T2) add는 존재 우선 **허용** · 품질은 커뮤니티 점진 |
| B6 | 동일 IP 중복 stub — dedupe가 **존재보다 우선** (merge 후보) |

### 6.4 규모별 균형

| 규모 | 존재 : 품질 (신규 insert) | 설명 |
|------|---------------------------|------|
| 5k | 30 : 70 | 엄선·코어 품질 |
| 50k | 50 : 50 | stub 파이프라인 가동 |
| 500k | 70 : 30 | 존재 확대 · enrich backlog |
| 5M | 80 : 20 | Long Tail mass stub |
| 5M+ | **85 : 15** | Platform — 커뮤니티가 존재 공급 · 품질은 비동기 |

**위험:** 존재 100% · 품질 0% → **「있지만 못 찾는」** Registry ([SW1](global-search-validation-plan.md) 실패).  
**완화:** stub 허용 + **enrich KPI** + 검색 랭킹 분리 (B2·B3).

### 6.5 사용자 경험 문구 (운영)

| 상황 | UX 방향 |
|------|---------|
| stub만 있는 Work | 카드 표시 · 「메타 보완 중」 |
| Contribution add 제출 | 「등록 검토 중」— 존재 확정 전에도 볼트 기록 가능 |
| fix 승인 | 「카탈로그 개선 반영」— 품질 개선 명시 |

---

## 7. Contribution vs Expansion — 재확인

```
[Expansion]  T0 주류 · 신호 강함 · 존재→enrich · Maintainer 주도
[Contribution]  T1~T3 · 신호 약함 · fix+add · 커뮤니티 주도 (50k+)
[볼트]  Registry 없어도 기록 · Platform의 수요 신호
```

| 규모 | 주력 | 보조 |
|------|------|------|
| 5k | Expansion 준비 + 수동 | Contribution fix |
| 50k | Expansion | Contribution add 시작 |
| 500k | Expansion (T0) | Contribution (T1~T2) |
| 5M+ | Expansion (T0 only) | **Contribution (T1~T3)** |

---

## 8. 리스크 · 5M+ 운영

| ID | 리스크 | 완화 |
|----|--------|------|
| C1 | add 큐 폭발 | 일일 상한 · reputation · tier |
| C2 | stub spam | Minimal Core hard gate · rate limit |
| C3 | 평판 게임 | merge 권한과 분리 · reject audit |
| C4 | 커뮤니티 없이 5M 목표 | 본 문서 §3 — **비현실** |
| C5 | 존재만 쌓임 | enrich SLA · SW1 regression |
| C6 | 법무 (2차 창작 add) | ADR-004 · 승인제 유지 |

---

## 9. 질문별 한 줄 답

| # | 답 |
|---|-----|
| 1 | 오늘 **Registry** → 장기 **Registry Platform** (SoT·정책은 AKASHA 유지) |
| 2 | add **50k~** 본격 · **500k** 확대 · **5M** Long Tail 주력 · fix는 **5k~** |
| 3 | 커뮤니티 없이 **~30만~50만** (주류) · **5M+ 불가** |
| 4 | Long Tail = **커뮤니티** 1차 · Pipeline은 보조 |
| 5 | **승인제 상시** + **검증제 50k~** + **평판 500k~** + **dedupe 보조 상시** |
| 6 | **등록=존재** · **랭킹·코어=품질** · 규모 커질수록 존재 비중 ↑ (5M+ ~85%) |

---

## 10. 다음 단계 (문서만)

| 항목 | 연계 |
|------|------|
| 50k Contribution add 파일럿 정책 | [catalog-contribution-roadmap](catalog-contribution-roadmap.md) |
| enrich SLA 수치 | [registry-growth-strategy](registry-growth-strategy.md) |
| reputation 설계 (구현 X) | 500k 게이트 |
| 5M+ tier 비율 실측 | URV-C · 운영 |

---

## 11. 원칙

1. **Platform ≠ 무_gate 개방** — `wk_`·dedupe·data-policy는 중앙.
2. **볼트는 항상 열림** — Registry 부재가 사용자 기록을 막지 않음.
3. **5M은 중간 지점** — 5M+에서 Contribution이 **성장 엔진**.
4. **존재와 품질은 분리 측정** — stub 수 ≠ 성공 · recall/enrich로 품질.
5. 구현 전 **50k·500k 게이트**에서 본 모델 재평가.
