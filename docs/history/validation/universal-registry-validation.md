# Universal Registry Validation (URV)

> **목표:** AKASHA는 검색 엔진이 아니라 **인류의 모든 작품(Universal Works Registry)** 을 담는 레지스트리이다.  
> **모든 엔티티**가 아니라 **모든 작품**만 대상으로 설계·검증한다.
>
> SW1이 **찾기(recall)** 를 검증한다면, URV는 **정체성·관계·중복·수집 경계**를 검증한다.
>
> **핵심 질문:** 수천만 작품 규모에서도, 동일한 Work/Franchise 규칙으로 **일관 등록**되는가?
>
> 본 문서는 **구현·스키마 변경 없이** 검증 축·시나리오·ADR 게이트만 확정한다.

선행·병행 문서:

- [global-search-validation-plan.md](global-search-validation-plan.md) — SW1 recall@10/@20
- [adr/README.md](adr/README.md) — ADR-001~006 (URV-A 선행)
- [registry-growth-strategy.md]](../strategy/registry-growth-strategy.md) — **데이터 확보** (ADR는 작품 존재 후)
- [canonicalization-policy.md]](../policy/canonicalization-policy.md) — dedupe·franchise·edition 규칙
- [locale-catalog-policy.md](locale-catalog-policy.md) — titles·aliases·표시 fallback
- [catalog-ownership.md](catalog-ownership.md) — Tier 0 Identity · Tier 1 Registry
- [data-policy.md]](../data-policy.md) — 필드 분류 (Fact vs Derived)

관련 구현 (현재 계약):

- `wk_` — 불변 저장 단위 (shard · search_index · 볼트)
- `franchise_groups.json` — IP 1카드 (`displayName` · `displayNames` · `members` · `primaryWorkId`)
- `FranchiseFusionService` · `RegistryVisibilityService` — 그리드 Franchise-first 표시
- `buildWorkSearchTokens` — Work 단위 검색 토큰 (Franchise 메타 미포함)

---

## 1. Validation 두 축

| 축 | ID | 질문 | 대표 지표 |
|----|-----|------|-----------|
| **Search** | SW1 | 원하는 작품을 **찾을 수 있는가?** | recall@10 · recall@20 |
| **Registry** | **URV** | 찾은 대상이 **무엇이며 서로 어떤 관계인가?** | identity consistency · relation accuracy · dedupe precision |

```
[인프라] Search Index Bottleneck ✅
    ↓
[Search]  SW1 — recall·다국어 쿼리
    ↓
[Registry] URV — Work/Franchise·정체성·관계·dedupe  ← 본 문서
    ↓
[정책 ADR] 기본 엔티티·canonical 규칙 확정
    ↓
[구현] 메타 파이프라인 · 스키마 · linter 보강
    ↓
[Search POC] SW2 — 인덱스 아키텍처 (URV+SW1 게이트 후)
```

**원칙:** SW1 실패가 많아도 URV를 건너뛰지 않는다. recall 갭의 상당수는 **Registry 메타 누락**에서 온다.

---

## 2. Universal Works Registry — 범위

### 2.1 장기 목표

**인류의 모든 작품** — 상업·인디·마이너·2차 창작을 포함한, **감상·아카이브 가능한 문화 콘텐츠**.

### 2.2 포함 (In scope)

| 매체·유형 | Registry | 비고 |
|-----------|----------|------|
| 소설 · 라이트노벨 | ✅ | `book` |
| 만화 · 웹툰 | ✅ | `manga` · `webtoon` |
| 애니메이션 | ✅ | `animation` |
| 영화 · 드라마 | ✅ | `movie` · `drama` |
| 게임 (플레이 가능 콘텐츠) | ✅ | `game` |
| 음악 (릴리스 단위) | ✅ (장기) | [ADR-002](adr/ADR-002-music-registry-model.md) |
| 독립·마이너 작품 | ✅ | [ADR-004](adr/ADR-004-work-collection-policy.md) |
| 동인지 · 팬게임 · 팬픽션 | ✅ (정책 제한) | canonical과 분리 |

현재 앱 enum: manga · webtoon · animation · game · book · movie · drama — **음악은 ADR 승인 후 추가**.

### 2.3 제외 (Out of scope — 작품이 아님)

| 유형 | 예 | 이유 |
|------|-----|------|
| 일반 웹사이트 | 개인 블로그 | 작품 아님 |
| 소프트웨어 프로젝트 | Linux, VS Code | 도구·플랫폼 |
| 프로그래밍 언어 | Python, Rust | 작품 아님 |
| 데이터셋 | ImageNet | 작품 아님 |
| AI 모델 | GPT-4, SD | 작품 아님 |

→ URV·SW1·Pipeline은 **위 제외 유형을 Work로 등록하지 않음**을 전제로 한다.

### 2.4 Registry가 표현하는 것

| 개념 | 사용자가 기대하는 것 | Registry 표현 |
|------|---------------------|---------------|
| **문화적 대상 (IP)** | 「귀멸의 칼날」한 장의 카드 | Franchise (IP 1카드) |
| **구체적 매체/에디션** | 만화 vs TV애니 vs 극장판 | Work (`wk_` + `category`) |
| **이름 (다국어)** | Demon Slayer / 鬼滅の刃 / 귀멸의 칼날 | Canonical Identity |
| **별칭** | KNY · NGE · Eva | Alias 체계 |
| **시리즈 구조** | 1기·2기 · 무한열차 · BROTHERHOOD | [ADR-003](adr/ADR-003-series-minimum-unit.md) |
| **출처** | 상업·인디·동인 | [ADR-004](adr/ADR-004-work-collection-policy.md) |
| **중복 없음** | 같은 작품이 ID 두 개 | Dedupe 전략 |

**제품 약속 (Steam v1):** 홈 그리드 **IP 1카드** · 매체 칩 · 검색에서 개별 Work 노출 가능 (`tracksMultipleFormats`).

---

## 3. 기본 엔티티 결정 — Work vs Franchise

### 3.1 현재 상태 (이중 모델)

| 계층 | 엔티티 | 역할 | 근거 |
|------|--------|------|------|
| **저장·Identity** | **Work** (`wk_`) | 샤드·search_index·볼트·legacy_aliases의 원자 | v4 아키텍처·불변 ID |
| **제품·표시** | **Franchise** (`franchise_*`) | IP 1카드·`displayNames`·형제 억제 | `FranchiseFusionService` · franchise_groups v2 |

→ 저장은 Work-first, **사용자가 마주하는 카탈로그 경험은 Franchise-first**.

### 3.2 후보 모델

| 모델 | 설명 | 장점 | 단점 |
|------|------|------|------|
| **A. Work-only** | Franchise 제거, Work만 카드 | 단순 스키마 | IP 1카드·다매체 UX 붕괴 |
| **B. Work-primary** | Work가 유일한 엔티티, Franchise는 뷰 힌트 | shard 단순 | 검색·표시·dedupe가 Work에만 묶임 |
| **C. Franchise-primary (저장 포함)** | `fr_*` ID가 1급, Work는 매체 슬롯 | IP 중심 직관 | v4 `wk_` 전면·볼트·CI 마이그레이션 비용 큼 |
| **D. Dual-layer** | **Work = 저장 원자**, **Franchise = 문화적 정체성 레이어** | IP 1카드 유지 + `wk_` 불변 + 점진 확장 | 두 계층 동기화·검증 필요 |

### 3.3 결정 — **승인** ([ADR-001](adr/ADR-001-dual-layer-entity-model.md))

> **AKASHA의 기본 저장 엔티티는 Work(`wk_`)이고, 제품·큐레이션·다국어 IP 정체성의 기본 단위는 Franchise이다.**

| 질문 | 답 |
|------|-----|
| 볼트·Contribution·retire가 가리키는 ID는? | **Work** (`wk_`) |
| 홈 그리드 1카드가 대표하는 문화적 대상은? | **Franchise** |
| 검색 인덱스의 최소 단위는? | **Work** (오늘) — Franchise 토큰 **상속 여부는 URV로 검증** |
| Pipeline dedupe의 survivor는? | **Work** |
| 다국어 **IP 공식명** canonical은? | **Franchise `displayNames`** (Work `titles`와 정합 유지) |

**명시적 보류 (ADR 필요):**

- Franchise에 독립 ID (`fr_`)를 부여할지, 지금처럼 `franchise_kimetsu` 문자열 키만 쓸지
- Franchise를 shard에 역정규화할지, `franchise_groups` 분리 파일을 유지할지

**Work-only로 회귀하지 않는다** — IP 1카드는 제품 핵심이며 [registry-scaling-review.md](registry-scaling-review.md)에서 franchise 운영 병목은 **별도 축**으로 이미 식별됨.

---

## 4. 검증 항목 (5축)

### 4.1 Work vs Franchise 모델

**검증 질문**

| # | 질문 |
|---|------|
| F1 | 다매체 IP가 **항상 하나의 Franchise**로 묶이는가? |
| F2 | Franchise 없는 단일 매체 Work가 그리드·검색에서 **오염 없이** 동작하는가? |
| F3 | `primaryWorkId`가 IP 대표 매체로 **일관**되는가? |
| F4 | 형제 Work가 그리드에서 **중복 카드**로 나타나지 않는가? |
| F5 | 검색·아카이브·Contribution이 Work/Franchise 중 **어느 ID를 쓰는지** 계약이 명확한가? |

**현재 관측 (402)**

- `franchise_groups.json` v2 — 약 30 IP, `displayNames` 다국어는 **일부만** 채움
- `franchise_linter` — 미등록 다매체 **후보** 탐지 (자동 결정 아님)
- 귀멸·스파이·반지 등: Franchise는 있으나 Work `titles.en` 누락 → SW1 GAP와 연동

**URV 시나리오 (예시)**

| id | 시나리오 | 기대 | 유형 |
|----|----------|------|------|
| URV-F01 | 만화+애니 둘 다 있는 IP | 단일 Franchise · 그리드 1카드 | consistency |
| URV-F02 | `primaryWorkId` 변경 시 그리드 대표 | primary만 대표 카드 | regression |
| URV-F03 | Franchise 미등록 다매체 쌍 | linter 후보 · 수동 큐 | coverage |
| URV-F04 | 단일 매체 (book) | Franchise 없음 · Work 1카드 | isolation |
| URV-F05 | Re:제로 3 Work 1 Franchise | 멤버 3 · 칩 3 · 검색 개별 노출 | multi-format |
| URV-F06 | LOTR book + movie | 동일 displayName ko만 · en Franchise명 없음 | **GAP** |

**지표**

| 지표 | 정의 | Phase B 목표 |
|------|------|--------------|
| `franchise_coverage` | 다매체 IP 중 Franchise 등록 비율 | ≥ 95% (linter 후보 대비) |
| `grid_duplicate_rate` | 그리드에서 동일 Franchise 2카드 이상 | **0%** |
| `primary_consistency` | primary ∈ members · category 대표성 | 100% (수동 샘플) |

---

### 4.2 다국어 Canonical Identity

**검증 질문**

| # | 질문 |
|---|------|
| I1 | Work·Franchise 각각 **canonical 이름 집합**이 정의되어 있는가? |
| I2 | `titles` / `displayNames` / `searchTokens`가 **동일 의미**로 연결되는가? |
| I3 | 로케일 fallback ([locale-catalog-policy](locale-catalog-policy.md))이 빈 필드에서 **깨지지 않는가?** |
| I4 | Franchise `displayNames.en`과 멤버 Work `titles.en`이 **충돌 없이** 공존하는가? |
| I5 | 1M에서도 canonical 연결이 **유지**되는가? (메타 파이프라인 회귀) |

**Canonical Identity 계층 (제안)**

```
Franchise.displayNames  →  IP 수준 공식명 (그리드·IP 검색)
Work.titles           →  매체 수준 공식명 (상세·매체별 검색)
Work.aliases          →  매체 수준 별칭
searchTokens (빌드)    →  Work + (향후) Franchise 상속 토큰
```

**현재 갭 (402 실측)**

| 필드 | 보유율 |
|------|--------|
| Work `titles.en` | 28% |
| Work `titles.ja` | 21% |
| Work `titles.zh` | 0% |
| Franchise `displayNames` (en/ja) | 소수 IP만 |

**URV 시나리오**

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-I01 | Franchise ko 표시 + Work en 검색 | 둘 다 성공 (SW1 연동) |
| URV-I02 | Work에만 en, Franchise에 ko만 | fallback 체인 정상 |
| URV-I03 | Franchise·Work 제목 상충 (번역 차) | 정책: 둘 다 유지 · UI는 Franchise 우선 |
| URV-I04 | zh 사용자 표시 | GAP 측정 · 정책 수립 전까지 제외 |
| URV-I05 | `romaji` / `native` 태그 | searchTokens 포함 여부 |

**지표**

| 지표 | 정의 | Phase B 목표 |
|------|------|--------------|
| `locale_pair_coverage` | Franchise 등록 IP 중 (ko,en) 또는 (ko,ja) 쌍 완비 | ≥ 90% |
| `work_title_sync` | Franchise 멤버 중 `titles`에 franchise display와 정합 en/ja | ≥ 85% |
| `identity_conflict_count` | linter가 잡는 Franchise↔Work 제목 충돌 | 감소 추세 · blocker 0 |

---

### 4.3 Alias 체계

**검증 질문**

| # | 질문 |
|---|------|
| A1 | 약칭(NGE · Eva · SAO)이 **Work vs Franchise** 어디에 붙는가? |
| A2 | alias가 `searchTokens`에 **항상** 반영되는가? |
| A3 | 팬덤 약어와 공식 별칭이 **구분**되는가? (품질·출처) |
| A4 | IP 약칭이 **모든 매체 Work**에 상속되어야 하는가? |

**현재 계약**

- `aliases[]` — Work shard 필드만 ([SCHEMA.md](../akasha-db/SCHEMA.md))
- `romaji` — `titles` 태그로 저장 시 토큰 포함 (예: DanMachi, SAO)
- Franchise 레벨 alias 필드 **없음**

**권장 정책 (검증 후 확정)**

| alias 종류 | 소속 | 예 |
|------------|------|-----|
| 매체 공식 별칭 | Work.aliases | 「식극의 소마」↔ Shokugeki |
| IP 팬덤 약어 | **Franchise (신규 필드 후보)** 또는 primary Work | NGE, KNY |
| 로마자 | titles.romaji | DanMachi |

**URV 시나리오**

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-A01 | Work `aliases`만 있음 | 검색 hit (SW1) |
| URV-A02 | IP 약칭이 primary Work에만 있음 | 다른 매체도 hit? — **정책 결정 필요** |
| URV-A03 | 약칭이 Franchise에만 있어야 하는 경우 (NGE) | 현재 **GAP** |
| URV-A04 | alias 중복 (동일 문자열 두 Work) | dedupe 후보 · AMBIGUITY |

**지표**

| 지표 | 정의 | Phase B 목표 |
|------|------|--------------|
| `alias_search_recall` | alias 전용 쿼리 스위트 hit@10 | ≥ 90% |
| `alias_provenance_rate` | alias에 source/tag 있는 비율 | ≥ 80% (파이프라인 도입 후) |
| `franchise_alias_gap` | IP 약칭 필요한데 어디에도 없는 IP 수 | → 0 |

---

### 4.4 Series ↔ Work 관계

**검증 질문**

| # | 질문 |
|---|------|
| S1 | **Franchise(IP)** vs **Series(시즌·편)** vs **Edition(리메이크)** 구분이 명확한가? |
| S2 | 극장판·spin-off는 Work로 남기고 Franchise로 묶는가? |
| S3 | 애니 1기/2기는 [canonicalization-policy]](../policy/canonicalization-policy.md)대로 **동일 wk_** 인가? |
| S4 | 「무한열차」같은 **부분 작품명**이 올바른 Work에 연결되는가? |
| S5 | 시리즈 검색 시 Franchise 전체 vs 개별 Work 중 **어떤 것이 canonical**인가? |

**관계 유형 (정책 정리)**

| 유형 | 예 | Registry 처리 |
|------|-----|---------------|
| IP · 다매체 | 귀멸 만화+애니 | Franchise + N Works |
| 시즌/파트 | 애니 2기 | **동일 Work** + `extensions.seasons` (별도 wk_ 남발 금지) |
| 극장판·OVA | 무한열차편 | **별도 Work** + 동일 Franchise |
| 리메이크 | FMA vs Brotherhood | **별도 Work** · human 판단 |
| 선속/외전 | 무직전생 LN vs manga | 별도 Work · Franchise로 묶을지 정책 |

**URV 시나리오**

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-S01 | 귀멸 본편 + 무한열차 2 Work | 동일 Franchise · 검색 「무한열차」→ 극장판 Work |
| URV-S02 | FMA manga vs BROTHERHOOD | 별도 Work · 별도 그리드 카드(Franchise 없거나 공유 정책) |
| URV-S03 | Re:제로 애니·LN·본편 | 1 Franchise · 3 Work · primary=본편명 |
| URV-S04 | 시즌을 별도 wk_로 잘못 분리 | dedupe_linter **후보** |
| URV-S05 | 시리즈명만 알 때 | Franchise displayName 또는 primary hit |

**지표**

| 지표 | 정의 | Phase B 목표 |
|------|------|--------------|
| `series_relation_accuracy` | 수동 라벨 50쌍 관계 유형 일치 | ≥ 95% |
| `spinoff_attach_rate` | 극장판/spin-off가 올바른 Franchise 소속 | 100% (샘플) |
| `season_split_violation` | 시즌이 불필요하게 별도 wk_ | 0 (linter) |

---

### 4.5 Dedupe 전략

**검증 질문**

| # | 질문 |
|---|------|
| D1 | 동일 작품 중복 wk_가 **존재하지 않는가?** |
| D2 | 다른 작품이 dedupe 후보로 **오탐**되지 않는가? |
| D3 | Franchise 멤버가 dedupe로 **잘못 병합**되지 않는가? |
| D4 | externalId exact match가 **human review 없이 merge 되지 않는가?** |
| D5 | 1M에서 dedupe 큐가 **폭발하지 않는가?** |

**현재 전략** ([canonicalization-policy]](../policy/canonicalization-policy.md))

1. `externalIds` exact match  
2. `searchTokens` + `titles` fuzzy  
3. 동일 franchise + category + 유사 releaseYear  
→ **자동 merge 금지** · PR/리뷰 큐

**URV 시나리오**

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-D01 | 동일 mal_id 두 shard | dedupe 후보 · merge 금지 until review |
| URV-D02 | FMA vs Brotherhood 유사 제목 | **not duplicate** |
| URV-D03 | 귀멸 애니 2개 항목 (중복 등록 실수) | 후보 · survivor 1 |
| URV-D04 | 영문 제목만 다른 같은 작품 | fuzzy hit · precision 측정 |
| URV-D05 | franchise 멤버 쌍 | dedupe **제외** 규칙 |

**지표**

| 지표 | 정의 | Phase B 목표 |
|------|------|--------------|
| `duplicate_wk_count` | CI가 잡는 확정 중복 | **0** |
| `dedupe_precision` | 후보 중 true duplicate 비율 | ≥ 70% (초기) → 85% |
| `dedupe_recall` | 알려진 중복 쌍 중 후보 포함 비율 | ≥ 90% |
| `false_merge_incidents` | 승인된 잘못된 merge | **0** |
| `queue_growth_1m` | synthetic 1M ingest 후보 수 / 일 | 상한 ADR (미정) |

---

## 5. URV 실행 단계

### 5.1 선행 게이트 — ADR (URV-A 이전)

| ADR | 주제 | 상태 | URV-A 블로커 |
|-----|------|------|--------------|
| [ADR-001](adr/ADR-001-dual-layer-entity-model.md) | Dual-layer | **승인** | — |
| [ADR-002](adr/ADR-002-music-registry-model.md) | 음악 — **A안(앨범=Work) vs B안(곡=Work)** | **A/B 검토** | ✅ |
| [ADR-003](adr/ADR-003-series-minimum-unit.md) | 시리즈 최소 단위 (에피소드 Registry 밖) | 초안 · **원칙 승인** | ✅ |
| [ADR-004](adr/ADR-004-work-collection-policy.md) | 수집 정책 (2차 창작 원작 분리) | 초안 · **원칙 승인** | ✅ |
| [ADR-005](adr/ADR-005-minimum-recordable-unit.md) | **매체별 최소 기록 단위** (대부분 승인 가능) | 초안 | ✅ |
| [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md) | **Franchise 경계·계층·깊이** | **초안** | ✅ |

**URV-A 착수 조건:**

1. [ADR-005](adr/ADR-005-minimum-recordable-unit.md) §4 — 음악 제외 **확정**
2. [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md) F1 승인 (parent 포인터 · depth≤3)
3. ADR-002 A/B — **B안 가중** · 단일안 또는 tier 조건부 승인
4. ADR-003·004 세부 open item 명시

### 5.2 단계

| 단계 | Registry | 방법 | 산출 |
|------|----------|------|------|
| **ADR 리뷰** | — | §5.1 ADR-002~004 | 승인·open items |
| **URV-A** | 402 | §4 5축 + §5.3 scale 시나리오 | baseline · GAP |
| **URV-B** | 402+ | 메타·franchise 보강 regression | before/after |
| **URV-C** | synthetic 1M~10M | ADR 규칙 주입 | scale 지표 |

SW1-A와 **병행 가능** — 동일 IP(귀멸·Re:제로)를 Search·Registry 양쪽에서 교차 분석.

결과 저장 (구현 시): `akasha-db/pipeline/artifacts/universal_registry_validation/` (gitignored)

### 5.3 규모 일관성 검증 (수천만 작품)

ADR-002~004가 채택될 때, 아래가 **동일 Work/Franchise 모델**로 유지되는지 검증한다.

| id | 질문 | ADR | 기대 |
|----|------|-----|------|
| URV-X01 | 트랙·에피소드 각각 wk_ 금지 | 002·003 | linter 거부율 100% |
| URV-X02 | 5M music 릴리스 Work | 002 | search_index·dedupe 상한 측정 |
| URV-X03 | 10M 시리즈 Work (에피소드 없음) | 003 | recall@10 canonical 유지 |
| URV-X04 | 2차 창작 5% 혼입 | 004 | Franchise 오염 0 · merge 0 |
| URV-X05 | 제외 유형(언어·모델) 등록 시도 | 004 §5 | policy linter 거부 |
| URV-X06 | 인디=상업 동일 스키마 | 004 | category·Franchise 규칙 동일 |
| URV-X07 | 아티스트 Franchise 50+ 앨범 | 002 | 그리드 1카드 · 멤버 cap 정책 |
| URV-X08 | 30M Work 합성 | 001~004 | shard·franchise 파일 분할 가설 검증 |

상세 시나리오: ADR별 `URV-M*` · `URV-SU*` · `URV-C*` — [adr/](adr/).

---

## 6. SW1 ↔ URV 연동

| SW1 태그 | URV 축 | 연동 |
|----------|--------|------|
| `GAP` (Demon Slayer) | I2 · A4 | Work `titles.en` + Franchise `displayNames` 보강 |
| `SERIES` | S1 · S5 | Franchise 멤버·primary 정책 |
| `ALIAS` / `ABBR` | A1 · A2 | alias 소속·상속 규칙 |
| `NOT_IN_REGISTRY` | — | URV 범위 외 (카탈로그 확장) |

**통합 게이트 (제안):**

- SW1 Phase B recall Must 통과  
- **AND** URV Phase B `franchise_coverage` · `duplicate_wk_count` · `series_relation_accuracy` 통과  
→ 그 후 Search Index Refactor · Discovery 확장

---

## 7. 합격 기준 요약

### Phase A (402) — 측정만

- ADR-002~004 리뷰 완료  
- §4 5축 + §5.3 시나리오 실행 · GAP·충돌 목록화

### Phase B (Global Registry) — 게이트

| 축 | Must |
|----|------|
| Work vs Franchise | `grid_duplicate_rate` = 0 · `franchise_coverage` ≥ 95% |
| Canonical Identity | `locale_pair_coverage` ≥ 90% (등록 IP) |
| Alias | `alias_search_recall` ≥ 90% (전용 스위트) |
| Series ↔ Work | `series_relation_accuracy` ≥ 95% (샘플) |
| Dedupe | `duplicate_wk_count` = 0 · `false_merge_incidents` = 0 |

---

## 8. 미결정 사항

### 8.1 URV-A 선행 (ADR — 검토 대기)

| ADR | 핵심 질문 | 상태 |
|-----|-----------|------|
| **005** | **작품의 최소 기록 단위** (대부분 승인) | [ADR-005](adr/ADR-005-minimum-recordable-unit.md) |
| **006** | Franchise **계층·깊이·IP 1카드** | [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md) |
| **002** | 음악 A/B — **B안 가중** | [ADR-002](adr/ADR-002-music-registry-model.md) |
| **003** | 시리즈: IP vs 매체 vs 에피소드 | 원칙 승인 · 세부 초안 |
| **004** | 상업·인디·2차 창작 | 원칙 승인 · 세부 초안 |

### 8.2 구현 단계 (URV-A 이후)

| # | 결정 | 옵션 |
|---|------|------|
| O1 | Franchise 독립 ID | `fr_` vs `franchise_*` |
| O2 | IP alias 소속 | Franchise 필드 vs primary Work |
| O3 | Franchise 토큰 search_index 상속 | 빌드 merge vs 검색 expand |
| O4 | zh canonical | `zh` / `zh-Hans` / `zh-Hant` |
| O5 | dedupe 1M 큐 상한 | 일일 human review 용량 |

---

## 9. 산출물

| 산출물 | 경로 | 상태 |
|--------|------|------|
| 본 검증 계획 | `docs/validation/universal-registry-validation.md` | ✅ |
| 5축 시나리오 상세 (확장) | 본 문서 §4 · URV-* ID | ✅ 초안 |
| ADR-001~006 | `docs/adr/` | 🔶 001·003·004·005(대부분) · 002 B가중 · 006 초안 |
| URV-A baseline | `pipeline/artifacts/...` | ⏳ 미착수 |

---

## 10. 상태

| 항목 | 상태 |
|------|------|
| Search Index Bottleneck | ✅ |
| SW1 계획·쿼리 스위트 | ✅ |
| **URV 계획 (본 문서)** | ✅ |
| ADR-001 Dual-layer | ✅ 승인 |
| ADR-005 최소 기록 단위 | 🔶 대부분 승인 가능 |
| ADR-006 Franchise 계층 | 🔶 초안 |
| ADR-002 음악 A/B | 🔶 B안 **가중** |
| URV-A baseline | ⏸ ADR-006 + ADR-002 결정 후 |
| 스키마·파이프라인 구현 | ⏸ URV-A + ADR 승인 후 |

---

## 11. 원칙

1. AKASHA 최종 목표는 **인류의 모든 작품** 레지스트리 — **모든 엔티티가 아님**. 검색은 접근 수단.
2. **Franchise-first 제품 모델** + **Work-first 저장 원자** (Dual-layer)가 IP 1카드와 v4 `wk_`를 동시에 만족한다.
3. SW1 recall 갭은 URV canonical·alias 갭과 **같은 원인**일 수 있다 — 분리 측정·통합 게이트.
4. Dedupe는 **보수적** — false merge가 false negative보다 치명적이다.
5. 구현·Refactor보다 **검증·ADR·baseline** 우선.
