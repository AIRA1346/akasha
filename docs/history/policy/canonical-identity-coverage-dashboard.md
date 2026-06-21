# Canonical Identity Coverage Dashboard

> **목적:** A3(Contested)를 **운영 가능한 품질 지표**로 전환한다.  
> **전제:** Registry **구조**는 URV-A에서 검증됨 — 문제는 **표면형 커버리지** 부족.  
> **범위:** 설계 변경 없음 · enrich·CI·Growth 게이트용 KPI만 정의.

선행 검증:

- [assumption-register.md](assumption-register.md) §9 — URV-A
- [universal-registry-validation.md](universal-registry-validation.md) — URV 계획
- [locale-catalog-policy.md](locale-catalog-policy.md) — `titles` · `aliases` 계약

**측정 도구:** `dart run tool/coverage_dashboard.dart`  
**산출물:** `akasha-db/pipeline/artifacts/coverage_dashboard/coverage_snapshot.json` (gitignored)

**기준일:** 2026-06-09 · Registry **402작**

---

## 1. A3 재정의

| 이전 질문 | 현재 질문 |
|-----------|-----------|
| 동일 작품을 **병합**할 수 있는가? | Registry가 **충분한 표면형**을 알고 있는가? |
| Dedupe 알고리즘 | **Canonical Identity Coverage** |

URV-A 근거:

- exactId ingress **100%** · 번역 수렴 **92.7%** → **모델·구조는 Supported**
- 로마자 GAP **0%** · `aliases[]` 필드 **0%** → **커버리지가 Contested**

---

## 2. KPI 체계

### 2.1 두 층

| 층 | 용도 | 예 |
|----|------|-----|
| **Registry-wide** | 전체 카탈로그 enrich 진척 | `titles.en` 보유율 |
| **Panel** | SW1/URV 실패 축 직접 추적 | GAP 16건 · alias 11건 |

Panel은 **운영 게이트**에 우선 사용한다. Registry-wide는 **백로그 규모** 파악용.

### 2.2 합격 기준

| status | 조건 |
|--------|------|
| **PASS** | rate ≥ target |
| **PARTIAL** | rate ≥ phaseTarget (해당 시) |
| **FAIL** | 그 미만 |

기본 **target = 90%**. 단계적 목표가 있는 지표는 §3 표 참고.

---

## 3. 핵심 KPI (7+1)

### 요약表 (402 baseline)

| KPI | 현재값 | target | status | 비고 |
|-----|:------:|:------:|:------:|------|
| **titles.en** | **21.1%** (85/402) | 90% | FAIL | G2 enrich 1순위 |
| **romanized alias** | **22.7%** (85/375) | 90% | FAIL | 분모=로마자 필요 작품 |
| **zh** | **0%** (0/402) | 90% | FAIL | `titles.zh` 전무 |
| **alias (panel)** | **81.8%** (9/11) | 90% | FAIL | SW1 alias 버킷 동일 |
| **subtitle (panel)** | **66.7%** (6/9) | 90% | FAIL | 시즌/부제 SW1 축 |
| **season** | **43.3%** (42/97) | 80% | FAIL | animation+drama만 |
| **externalId** | **14.9%** (60/402) | 90% | FAIL | phase **50%** @ G2 |
| **GAP panel** | **0%** (0/16) | 90% | FAIL | URV 로마자·CJK·약칭·부제 |

---

### 3.1 `titles.en` coverage

| 항목 | 내용 |
|------|------|
| **정의** | `titles.en` 비어 있지 않은 Work 비율 |
| **현재** | **21.1%** (85/402) |
| **target** | **90%** |
| **phase** | G1: 40% · G2: 70% · G3+: 90% |
| **URV/SW1** | 로마자 GAP 7건의 직접 레버 |

---

### 3.2 `romanized alias` coverage

| 항목 | 내용 |
|------|------|
| **정의** | **분모:** primary가 CJK이거나 `titles.ja` 보유(로마자 필요 375작). **분자:** `titles.romaji` 또는 `titles.en` 또는 latin `aliases[]` 중 하나 이상 |
| **현재** | **22.7%** (85/375) · `titles.romaji` 필드만 **0.7%** (3/402) |
| **target** | **90%** |
| **phase** | G2: 50% · G3+: 90% |
| **URV/SW1** | URV 로마자 축 **0%** · SW1 GAP 15건 |

> 운영 시 `titles.romaji` 단독 필드보다 **`titles.en` + `romaji` 병행**을 권장 ([locale-catalog-policy](locale-catalog-policy.md)).

---

### 3.3 `zh` coverage

| 항목 | 내용 |
|------|------|
| **정의** | `titles.zh` (또는 `zh-Hans`/`zh-Hant` 확장) 비어 있지 않은 Work 비율 |
| **현재** | **0%** (0/402) |
| **target** | **90%** |
| **phase** | G3: 30% · G4+: 90% (CN persona 게이트 전) |
| **URV/SW1** | SW1 EN_ZH GAP 4건 (鬼灭之刃 등) |

---

### 3.4 `alias` coverage

| 항목 | 내용 |
|------|------|
| **Registry-wide** | `aliases[]` 비어 있지 않음 **또는** `titles.romaji` — 현재 **8.9%** (36/402) |
| **Panel (운영 게이트)** | SW1 ABBR/ALIAS 11쿼리 표면형 부착 — **81.8%** (9/11) |
| **target** | **90%** (panel 기준) |
| **실패 패널** | `Re:ゼロ` · `FMA` |
| **관찰** | 402 샤드에 `aliases[]` 키 **0건** — 약칭이 `titles.romaji`·`titles.en`에 흡수됨. enrich 시 **`aliases[]` 복원** 권장 |

---

### 3.5 `subtitle` coverage

| 항목 | 내용 |
|------|------|
| **Panel (운영 게이트)** | SW1 SERIES 9쿼리 — **66.7%** (6/9) |
| **Registry-wide (보조)** | Franchise 비-primary 멤버 중 `titles.en` 또는 latin alias — **56.3%** (36/64) |
| **target** | **90%** (panel) |
| **실패 패널** | Lord of the Rings · Fellowship of the Ring · Dandadan |
| **URV/SW1** | URV 시즌/부제 **78.6%** · stub 유입 시 B-4 수준 하락 예상 |

부제·spin-off는 **별도 Work** + Franchise 유지 ([canonicalization-policy]](../policy/canonicalization-policy.md)) — `titles.en`·alias에 **부제 표면형**을 명시적으로 부착.

---

### 3.6 `season` coverage

| 항목 | 내용 |
|------|------|
| **정의** | `animation`·`drama` Work 중 `extensions.seasons[]` 비어 있지 않은 비율 |
| **현재** | **43.3%** (42/97) |
| **target** | **80%** (시즌 분리 `wk_` 남발 금지 정책과 정합) |
| **phase** | G2: 60% · G3+: 80% |
| **정책** | 시즌은 **동일 wk_** + `extensions.seasons` ([ADR-003](adr/ADR-003-series-minimum-unit.md)) |

---

### 3.7 `externalId` coverage

| 항목 | 내용 |
|------|------|
| **정의** | `externalIds` 맵에 1개 이상 키 보유 Work 비율 |
| **현재** | **14.9%** (60/402) |
| **target** | **90%** (장기) |
| **phaseTarget** | **50%** @ G2 · **70%** @ G3 |
| **URV/SW1** | exactId ingress **100%** — **구조 Supported** · **밀도 Contested** |
| **variant-only** | externalId 없는 표면형 stub → fuzzy **0%** (SIM-B B-3) |

---

### 3.8 `GAP panel` (통합 운영 게이트)

| 항목 | 내용 |
|------|------|
| **정의** | URV-A/SW1 **GAP 16건** 표면형이 target `wk_` identity에 부착되었는가 |
| **현재** | **0%** (0/16) |
| **target** | **90%** |
| **축 분해** | 로마자 0/7 · CJK 0/4 · alias 0/2 · subtitle 0/3 |

이 패널이 **90%**에 도달하면 SW1 GAP recall·URV 로마자 축이 동시에 개선될 것으로 예상.

---

## 4. 운영 워크플로

```
enrich / contribution merge
    ↓
dart run tool/coverage_dashboard.dart
    ↓
panel KPI ≥ target? ──no──→ 백로그 우선순위 (§5)
    ↓ yes
dart run tool/urv_a_validation.dart  (회귀)
dart run tool/sw1_a_validation.dart    (회귀)
    ↓
CI 게이트 (향후): coverage_snapshot.json threshold
```

**원칙:** 구조·스키마 PR 없이 **메타 enrich PR**만으로 panel KPI를 올린다.

---

## 5. enrich 백로그 우선순위 (402 → 5k)

| 순위 | KPI | 이유 |
|:----:|-----|------|
| 1 | **GAP panel** (0→90%) | SW1·URV 동시 실패 16건 — 최대 leverage |
| 2 | **titles.en** (21→90%) | 로마자·공식 영문 표면형 |
| 3 | **externalId** (15→50%) | variant-only fallback |
| 4 | **alias panel** (82→90%) | Re:ゼ로 · FMA |
| 5 | **subtitle panel** (67→90%) | LOTR · Dandadan |
| 6 | **zh** | G3 CN persona 전 |
| 7 | **season** | 시즌 메타 정합 |

---

## 6. 가정 등급 (변경 없음)

| 가정 | 판정 |
|------|------|
| A1 | Supported |
| A2 | Supported |
| **A3** | **Contested → Canonical Identity Coverage** |
| A4 | Supported |
| A5 | 미검증 |
| A6 | 장기 과제 |

---

## 7. 상태

| 항목 | 상태 |
|------|------|
| KPI 정의 (본 문서) | ✅ 초안 |
| 측정 도구 `coverage_dashboard.dart` | ✅ |
| 402 baseline snapshot | ✅ 2026-06-09 |
| CI threshold 게이트 | ⏳ |
| URV-B (enrich before/after) | ⏳ |

---

## 8. 원칙

1. **구조 변경 없이** 커버리지를 올린다 — URV-A가 구조 안정을 확인함.
2. **Panel KPI**가 **Registry-wide**보다 운영 게이트 우선.
3. SW1 recall·URV 수렴·Coverage KPI는 **같은 표면형 부착**을 다르게 측정 — 통합 게이트 유지.
4. `aliases[]` 필드는 스키마상 존재하나 402에서 **미사용** — enrich 파이프라인이 채울 대상.
