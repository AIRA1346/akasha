# Global Search Workload Validation (SW1)

> **목표:** 성능이 아니라 **검색 품질(recall)** 검증  
> **핵심 질문:** 100만 작품을 저장했을 때, 전 세계 사용자가 원하는 작품을 **실제로 찾을 수 있는가?**
>
> 선행 완료: Search Index Bottleneck Validation (인프라) ✅  
> 본 단계: **Architecture Refactor 이전** · 구현 없이 **문서·시나리오·평가 기준**만 확정

선행·병행 문서:

- [search-workload-profile.md](search-workload-profile.md) — W1–W10 유형·비율 v0 가정
- [search-index-validation-plan.md](search-index-validation-plan.md) — 10k/100k/1M synthetic 인프라 실측 ✅
- [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) — search_index = 첫 성능 병목
- [universal-registry-validation.md](universal-registry-validation.md) — **URV** 정체성·Franchise·dedupe (Search와 별도 축)

관련 코드 계약:

- `lib/utils/registry_search_utils.dart` — `normalizeRegistryQuery` + `token.contains(q)`
- `tool/registry_v3_utils.dart` — `buildWorkSearchTokens(title · titles · aliases · creator · tags)`

---

## 1. 왜 SW1인가

| 축 | Search Index Validation (완료) | **SW1 Global Search Validation (본 문서)** |
|----|-------------------------------|-------------------------------------------|
| 질문 | 1M에서 search_index를 **얼마나 빨리** 읽고 스캔하는가? | 1M에서 사용자 쿼리로 **올바른 작품이 상위에 나오는가?** |
| 지표 | 파일 MB · parse ms · RSS · ms/query | **recall@10 · recall@20** |
| 입력 | synthetic 동일 토큰 분포 | **지역·문자계·별칭이 다른 실제형 쿼리** |
| 실패 의미 | 앱이 느리거나 OOM | **글로벌 Registry가 제품 가치를 못 만든다** |

AKASHA 최종 목표는 한국 서비스가 아니라 **Global Registry**이다.  
따라서 다음 게이트는 shardBits·FTS POC가 아니라 **다국어 recall이 데이터·검색 계약을 만족하는가**이다.

---

## 2. 검증해야 할 핵심 질문

| # | 질문 | SW1 매핑 |
|---|------|----------|
| Q1 | 일본어 제목으로 영어권/로컬라이즈 작품을 찾을 수 있는가? | **JA→작품** (en/ko 표기 작품 포함) |
| Q2 | 영어 제목으로 일본 작품을 찾을 수 있는가? | **EN→작품** (ja 원제·로마자 포함) |
| Q3 | 원제 / 현지화 제목 / 별칭(alias)이 충분히 연결되는가? | **ORIG↔LOC · ALIAS** |
| Q4 | 라틴·일본어·한글·중국어가 섞인 환경에서 recall이 유지되는가? | **MIXED_SCRIPT** |
| Q5 | 국가별 검색 패턴 차이가 반영되는가? | **REGION_PERSONA** (JP/US/KR/CN 가정) |
| Q6 | 1M 규모에서도 multilingual recall이 유지되는가? | **Phase B** — synthetic 1M + 동일 스위트 |

---

## 3. SW1 범위

### 3.1 In scope

- Fusion Search Dialog 경로와 동일한 계약: `WorksRegistry.searchAsync` → index 스캔 → shard 로드 → `qualityScore` 정렬
- Workload 유형 W1–W7 ([search-workload-profile](search-workload-profile.md))
- 카테고리: animation · manga · webtoon · game · book (402 Registry 실제 분포)
- **대표 쿼리 스위트** 95건 (recall 집계 87건, 미수록 진단 8건 제외) — [global-search-query-set.md](global-search-query-set.md)
- recall@10 / recall@20 정의 및 합격 기준 (본 문서 §5)
- 402 **baseline 가설** + 1M **재현 계획**

### 3.2 Out of scope (SW1)

- Search index 구조 변경 · FTS/trie POC
- 오타 허용 (W8) · autocomplete UX (W9) — 별도 SW2 이후
- 시놉시스 full-text · external ID 검색
- Telemetry 기반 비율 교정 (SW3)
- 자동화 러너 구현 — SW1.1

---

## 4. 평가 방법

### 4.1 절차 (수동 · Phase A)

1. 앱 또는 동일 계약의 검색 함수로 쿼리 실행
2. 반환 목록에서 **workId 순위** 기록 (최소 상위 20건)
3. 각 쿼리의 `expectedWorkIds`와 대조
4. 쿼리별 PASS/FAIL 및 실패 원인 태그 기록

결과 저장 위치 (구현 시): `akasha-db/pipeline/artifacts/global_search_validation/` (gitignored)

### 4.2 recall 정의

**단일 쿼리 성공 (hit@K):**

```
hit@K(query) = 1  if ∃ id ∈ expectedWorkIds : rank(id) ≤ K
             = 0  otherwise
```

- `expectedWorkIds`: 스위트에 명시. 복수 허용(애니/만화 등 동일 IP 다른 매체).
- `acceptableWorkIds`(선택): 시리즈명 검색 시 프랜차이즈 **member 전체**를 성공으로 인정할지 쿼리별 명시.
- `rank`: `qualityScore` 내림차순 → `title` 오름차순 (현재 구현).

**집계:**

```
recall@K = (hit@K = 1 인 쿼리 수) / (평가 대상 쿼리 수)
```

| 지표 | 의미 |
|------|------|
| **recall@10** | 사용자가 스크롤 없이 첫 화면에서 찾을 확률 (주 KPI) |
| **recall@20** | 약간 더 탐색했을 때의 보완 recall |

### 4.3 부분 집계 (카테고리별)

스위트 태그별 recall을 **반드시 분리 보고**한다. 전체 평균만으로 통과 판정하지 않는다.

| 태그 | 설명 |
|------|------|
| `EN_JA` | 영어 쿼리 ↔ 일본어 메타 |
| `EN_KO` | 영어 쿼리 ↔ 한국어 메타 |
| `EN_ZH` | 영어/중국어 교차 (현재 zh 메타 거의 없음 — **갭 측정**) |
| `JA_EN` | 일본어 쿼리 → 영어/로마자 표기 작품 |
| `KO_EN` | 한국어 쿼리 → 영어 표기 작품 |
| `ORIG_LOC` | 원제 ↔ 현지화 제목 |
| `ALIAS` | 공식 별칭 · 시노님 |
| `ABBR` | 약칭 · 팬덤 약어 (NGE, SAO, DanMachi) |
| `SERIES` | 시리즈/IP명 ↔ 개별 작품 (극장판·spin-off) |
| `PARTIAL` | 부분 문자열 (W2) |
| `MIXED` | 혼합 스크립트 입력 |
| `REGION_*` | 지역 페르소나 (JP/US/KR/CN) |
| `GAP` | **메타 누락으로 실패가 예상되는** 진단 쿼리 — 합격 집계에서 제외·별도 리포트 |

### 4.4 실패 원인 태그 (분석용)

| 코드 | 의미 |
|------|------|
| `MISSING_TOKEN` | titles/aliases에 해당 문자열이 searchTokens에 없음 |
| `MISSING_LOCALE` | titles.en/ja/ko/zh 중 필요 로케일 필드 부재 |
| `NORMALIZE` | 정규화(소문자·공백 제거)로 인한 불일치 |
| `RANKING` | 매칭은 되나 qualityScore 순위가 10/20 밖 |
| `AMBIGUITY` | 동명·부분일치 다건 — 기대 작품이 밀림 |
| `NOT_IN_REGISTRY` | 카탈로그에 작품 자체 없음 |

---

## 5. 합격 기준

### 5.1 Phase A — 402 Registry baseline (측정만 · 게이트 아님)

목적: **현재 데이터·계약의 recall 바닥선** 확정. Refactor/메타 보강 우선순위 입력.

| 항목 | 기대 |
|------|------|
| 산출 | 카테고리별 recall@10/@20 표 · GAP 쿼리 실패율 |
| 판정 | 합격/불합격 **없음** — 사실 기록 |

**402 사전 관측 (2026-06-08, search_index 분석):**

| 메타 지표 | 값 |
|-----------|-----|
| 총 작품 | 402 |
| `titles.en` 보유 | 112 (28%) |
| `titles.ja` 보유 | 85 (21%) |
| `titles.ko` 보유 | 375 (93%) |
| `titles.zh` 보유 | 0 (0%) |
| 2개 이상 로케일 | 85 (21%) |

→ EN↔JA/KO 교차 쿼리 상당수가 **데이터 갭**으로 실패할 가능성이 높다.  
예: `귀멸의 칼날` — `titles`에 en/ja 없음 → `Demon Slayer`·`鬼滅の刃` 쿼리 **GAP 예상**.

### 5.2 Phase B — Global Registry 목표 (1M · 메타 정책 확정 후 게이트)

**전제:** Catalog Expansion 시 `titles` + `aliases` + `searchTokens` **다국어 연결 정책**이 ADR로 확정된 상태.

| 계층 | 범위 | recall@10 | recall@20 |
|------|------|-----------|-----------|
| **Must** | `EN_JA` · `EN_KO` · `ORIG_LOC` · `ALIAS` · `ABBR` (GAP 제외) | **≥ 90%** | **≥ 95%** |
| **Should** | `PARTIAL` · `SERIES` · `MIXED` | **≥ 80%** | **≥ 90%** |
| **Track** | `EN_ZH` | baseline 측정 → zh 메타 정책 후 재평가 | 동일 |
| **전체** | GAP 제외 가중 평균 (REGION 페르소나 가중 — §5.3) | **≥ 85%** | **≥ 92%** |

**GAP 쿼리:** 실패해도 Phase B **불합격 사유가 아님**. 대신 `MISSING_LOCALE` 비율이 **≤ 5%** (1M 중 평가 샘플 기준)이어야 메타 파이프라인 게이트 통과.

### 5.3 지역 페르소나 가중 (1M 목표)

[search-workload-profile](search-workload-profile.md) v0 비율을 **글로벌** 관점으로 재가정. SW1 보고 시 페르소나별 recall도 병기.

| 페르소나 | 가정 검색 습관 | 스위트 비중 |
|----------|----------------|-------------|
| **JP** | ja 원제·略称·ローマ字 | 25% |
| **US/EU** | en 공식명·약어 | 30% |
| **KR** | ko 현지화 + en 혼용 | 25% |
| **CN/TW** | zh 간체/번체·영어 혼용 | 20% |

---

## 6. 검증 단계 (타임라인)

```
[본 문서] SW1 계획 + 쿼리 스위트 95건 + recall 기준
    ↓
[SW1-A] 402 baseline 수동 실행 → 갭 리포트
    ↓
[정책] titles/aliases 다국어 연결 ADR + 파이프라인 보강
    ↓
[SW1-B] 402 재실행 (메타 보강 후 regression)
    ↓
[SW1-C] synthetic 1M + 동일 스위트 (인프라는 search_index_validation 재사용)
    ↓
[게이트] Phase B 합격 → Architecture Options POC (SW2) 허용
```

| 단계 | Registry | 자동화 | 게이트 |
|------|----------|--------|--------|
| SW1-A | 402 | 수동 | 없음 |
| SW1-B | 402+ | 수동 → 러너 권장 | 메타 보강 regression |
| SW1-C | synthetic 1M | `tool/global_search_validation.dart` (미구현) | **Phase B 합격** |

---

## 7. 1M synthetic 연계

[search-index-validation-plan](search-index-validation-plan.md)의 synthetic 생성기는 **동일 토큰 분포** 위주였다. SW1-C에서는 다음을 **추가 주입**:

| 주입 | 목적 |
|------|------|
| multilingual `titles` 쌍 | EN↔JA/KO recall이 규모에 따라 희석되는지 |
| `aliases` / `romaji` | ABBR·ALIAS 유지율 |
| franchise cluster | SERIES 쿼리에서 멤버 분산·랭킹 |
| noise titles (유사 문자열) | AMBIGUITY·RANKING 실패율 |

**고정 시드 + 고정 스위트**로 인프라 변경 전후·아키텍처 POC 간 **동일 recall 곡선** 비교.

---

## 8. 현재 계약이 풀 수 있는 것 / 없는 것

| 가능 (토큰만 있으면) | 불가 (SW1에서 실패 예상) |
|----------------------|---------------------------|
| W1 exact contains | zh 메타 없음 → `EN_ZH` 전부 GAP |
| W2 partial contains | 음역 차이 (`Kimetsu` vs `Demon Slayer`) — 토큰 없으면 실패 |
| W3 alias / W4 abbr | 오타 (`Evangleion`) |
| W7 cross-script contains | 형태소 (`進撃の巨人` vs `進撃`) — contains는 부분 일치만 |

**중요:** SW1 실패의 상당수는 **검색 알고리즘**이 아니라 **카탈로그 메타 누락**일 수 있다.  
실패 태그를 반드시 분리해, "인덱스 구조 변경" vs "titles/aliases 보강" 우선순위를 가른다.

---

## 9. 산출물 체크리스트

| 산출물 | 경로 | 상태 |
|--------|------|------|
| 본 계획서 | `docs/global-search-validation-plan.md` | ✅ |
| 대표 쿼리 스위트 (95건) | `docs/global-search-query-set.md` | ✅ |
| recall@10/@20 기준 | 본 문서 §4–§5 | ✅ |
| 402 baseline 결과 | `pipeline/artifacts/global_search_validation/` | ⏳ SW1-A |
| 1M recall 결과 | 동일 | ⏳ SW1-C |

---

## 10. 원칙

1. **"100만 작품을 저장할 수 있는가?"** 는 이미 인프라 축에서 1차 답을 얻었다.
2. 다음 질문은 **"100만 작품 속에서 찾을 수 있는가?"** 이다.
3. Architecture Refactor는 SW1-B/C **게이트와 갭 분석** 이후.
4. GAP 쿼리는 제품 결함이 아니라 **의도적 진단** — 메타 파이프라인 KPI로 승격.
5. 구현보다 **시나리오·기준·baseline** 우선 (본 문서).

---

## 11. 상태

| 항목 | 상태 |
|------|------|
| Search Index Bottleneck Validation | ✅ |
| Search Workload Profile v0 | ✅ |
| **SW1 계획 + 쿼리 스위트** | ✅ (본 문서) |
| SW1-A 402 baseline | ⏳ 미착수 |
| SW1-C 1M recall | ⏳ 미착수 |
| Search Index Refactor | ⏸ SW1 게이트 전 보류 |
