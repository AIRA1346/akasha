# ADR-004: 작품 수집 정책 (상업 · 인디 · 2차 창작)

| 항목 | 내용 |
|------|------|
| **상태** | **초안** (URV-A 전 검토 필요) |
| **범위** | Registry에 **포함**하는 작품의 출처·법적·운영 경계 |
| **선행** | [ADR-001](ADR-001-dual-layer-entity-model.md) · [catalog-ownership.md](../catalog-ownership.md) · [data-policy.md](../data-policy.md) |

---

## 1. 문제

「인류의 모든 **작품**」에는 상업·인디·2차 창작이 모두 포함된다.  
하지만 AKASHA는 [Universal Works Registry](../universal-registry-validation.md#21-작품-범위) — **웹사이트·소프트웨어·데이터셋·AI 모델은 작품이 아니다.**

각 출처를 어떻게 등록·표시·dedupe·Discovery 할지 없으면 수천만 규모에서 **정책 드리프트**가 발생한다.

---

## 2. 작품 정의 (전제)

**작품 (Work):** 인간이 의도적으로 창작·발표한 **문화적 콘텐츠 단위** — 소비·감상·아카이브 대상.

포함 매체 (현재·장기): 소설 · 만화 · 애니 · 영화 · 드라마 · 게임 · **음악** · 웹툰 · 라이트노벨 · 독립·마이너 작품.

---

## 3. 결정 (초안) — 출처별 정책

### 3.1 요약 표

| 출처 | Registry 포함 | Work 단위 | Franchise | Discovery / Pipeline | 비고 |
|------|---------------|-----------|-----------|----------------------|------|
| **상업 작품** | ✅ 기본 | ADR-003 매체 단위 | IP별 | 전면 파이프라인 | 기본 경로 |
| **인디 작품** | ✅ | 동일 | 선택 (시리즈 있으면) | 동일 · `origin:indie` | 상업과 **동일 모델** |
| **동인지** | ✅ | ADR-003 (동인 서큘 1작 = 1 Work) | 원작 IP Franchise에 **링크만** | 보수적 · human queue 비중 ↑ | canonical과 **merge 금지** |
| **팬게임** | ✅ | `category: game` | 원작 Franchise `derivative_of` | human queue · IP 태그 | 상업 게임과 동일 Work 규칙 |
| **팬픽션** | ✅ (제한적) | 1 편/1 연재 = 1 Work | 선택 · 원작과 **분리** | 사용자·Contribution 중심 · bulk 금지 | canonical IP Work와 dedupe **제외** |

### 3.2 상업 작품

- Registry의 **기준선**. Catalog Expansion Pipeline 주력.
- `qualitySignals` · externalIds · 다국어 titles 정상 적용.

### 3.3 인디 작품

- 상업과 **동일한 Work/Franchise 규칙** (ADR-001~003).
- 구분은 **메타 태그**로만:

```json
{
  "tags": ["인디"],
  "extensions": { "origin": "indie", "publisher": "자가출판" }
}
```

- 인디라서 검색·그리드에서 **열등 취급하지 않음** (quality는 신호 기반, 출처 차별 없음).

### 3.4 동인지

| 항목 | 규칙 |
|------|------|
| Work | 동인 **1서큘 1이슈** 또는 **완결 1편** = 1 Work (ADR-003: 에피소드급 쪼개기 금지) |
| Franchise | 원작 IP Franchise에 **멤버로 넣지 않음** — `relations.derivativeOf: wk_canonical` |
| dedupe | 원작과 fuzzy match 되어도 **자동 merge 금지** |
| 표시 | UI에 `2차 창작` 배지 (선택) |
| Discovery | auto-merge off · 저신뢰 소스 bulk 금지 |

**이유:** 원작 Franchise 오염 방지 · 법무 리스크는 [data-policy](../data-policy.md) Fact-only 메타로 완화.

### 3.5 팬게임

| 항목 | 규칙 |
|------|------|
| Work | `category: game` · ADR-003 단위 |
| 관계 | `relations.derivativeOf` → 원작 Franchise 또는 canonical game Work |
| dedupe | 동명 상업 게임과 **별도 wk_** 유지 |
| Pipeline | Steam/itch.io ID 있으면 `externalIds` · human review |

### 3.6 팬픽션

| 항목 | 규칙 |
|------|------|
| 포함 여부 | ✅ **작품**으로 인정 (사용자 아카이브 대상) |
| Work | 연재 1편·단편 1편 = 1 Work (`category: book` 또는 `webtoon`) |
| Franchise | 원작 IP와 **공유 Franchise 금지** — `franchise_fanfic_*` 독립 또는 Franchise 없음 |
| dedupe | 원작 제목 포함 시에도 **별도 Work** · `extensions.fanwork: true` |
| Pipeline | **사용자 Contribution·수동 PR 중심** — AI bulk ingest **금지** |
| 검색 | 원작 Franchise 검색에 팬픽 **기본 미포함** (필터로 opt-in) |

**이유:** 수억 팬픽을 파이프라인으로 넣으면 canonical recall 붕괴. 사용자 주도·희소 등록.

---

## 4. 공통 메타: `relations` (제안)

```json
{
  "relations": {
    "derivativeOf": "wk_000000343",
    "derivativeKind": "doujin | fangame | fanfiction | parody",
    "canonicalFranchiseId": "franchise_kimetsu"
  }
}
```

- [data-policy](../data-policy.md) `relations` = Fact · franchise 자동 결정에 **사용하지 않음**

---

## 5. 명시적 제외 (작품이 아님)

Registry에 **넣지 않는다** (ADR-004 범위 밖):

| 유형 | 예 | 이유 |
|------|-----|------|
| 일반 웹사이트 | 개인 블로그 | 작품 아님 |
| 소프트웨어 프로젝트 | Linux, VS Code | **게임이 아닌** 도구 |
| 프로그래밍 언어 | Python, Rust | 작품 아님 |
| 데이터셋 | ImageNet | 작품 아님 |
| AI 모델 | GPT-4, Stable Diffusion | 작품 아님 |

**경계:** 게임 엔진·MOD **도구**는 제외 · MOD **콘텐츠 팩**이 독립 체험물이면 Work 검토.

---

## 6. 규모 · 일관성 가설

| 출처 | 10M 규모 시 Work 비중 (가설) | 일관 등록 |
|------|------------------------------|-----------|
| 상업 | ~85% | Pipeline 표준 |
| 인디 | ~10% | 동일 스키마 |
| 동인·팬게임 | ~4% | human queue · relations 필수 |
| 팬픽션 | ~1% (상한) | Contribution only · 폭발 방지 |

**전제:** 출처별 규칙이 Work/Franchise 모델을 **바꾸지 않는다** — 태그·relations·queue만 다르다.  
→ 수천만에서도 **동일 dedupe·search·IP 1카드** 계약 유지.

---

## 7. URV 검증 시나리오 (ADR-004)

| id | 시나리오 | 기대 | 축 |
|----|----------|------|-----|
| URV-C01 | 인디 만화 1편 | Work 1 · origin=indie · Franchise 선택 | indie |
| URV-C02 | 귀멸 동인지 | Work 1 · derivativeOf · **원작 Franchise 멤버 아님** | doujin |
| URV-C03 | 포켓몬 팬게임 | game Work · derivativeOf · dedupe≠공식 게임 | fangame |
| URV-C04 | 팬픽 1편 | Work 1 · fanwork · 원작 검색 상위 **미노출** (기본) | fanfiction |
| URV-C05 | 동인지 제목≈원작 | dedupe 후보 **생성** · merge **거부** | dedupe |
| URV-C06 | Python 언어 등록 시도 | data_policy_linter **거부** | exclusion |
| URV-C07 | synthetic 1M — 상업 85% + 2차 5% | recall@10 canonical · 2차 오염 0 | scale |
| URV-C08 | Contribution 팬픽 1000건/월 | queue SLA · franchise 오염 0 | throughput |

---

## 8. 미결정

| # | 항목 |
|---|------|
| O1 | 팬픽 Registry 상한 (절대 건수 vs 비율) |
| O2 | 동인지 Discovery 자동 후보 허용 여부 |
| O3 | `derivativeKind` enum CI |
| O4 | 검색 시 fanwork 기본 필터 (opt-in vs opt-out) |

---

## 9. 대안 기각

| 대안 | 기각 이유 |
|------|-----------|
| 2차 창작 전면 제외 | 「모든 작품」·사용자 아카이브 목표 위반 |
| 2차 창작 = 원작 Franchise 멤버 | IP 1카드·검색·dedupe 오염 |
| 팬픽 Pipeline bulk | 규모·법무·canonical recall 붕괴 |
