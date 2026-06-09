# Registry Growth Strategy

> **전제:** ADR·URV·SW1은 **「작품이 이미 Registry에 있다」** 는 가정 위에 있다.  
> AKASHA 장기 리스크의 1순위는 **구조 붕괴가 아니라 데이터 확보**다.
>
> 본 문서는 **구현 없이** 402 → 5M+ 성장 경로 · 수집 방식 · 최소 등록 기준 · Long Tail · 병목 평가만 정의한다.  
> 커뮤니티·사용자 등록 운영 모델: [contribution-model-strategy.md](contribution-model-strategy.md).

선행 문서:

- [data-policy.md](data-policy.md) — Minimal Core · Discovery ≠ Mirroring
- [catalog-contribution-roadmap.md](catalog-contribution-roadmap.md) — Contribution vs Expansion
- [contribution-model-strategy.md](contribution-model-strategy.md) — Registry vs Platform · 커뮤니티 시점
- [discovery-policy.md](discovery-policy.md) — Signal → Registry 게이트
- [registry-scaling-review.md](registry-scaling-review.md) — 저장·shard 규모
- [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) — search_index 1차 병목
- [universal-registry-validation.md](universal-registry-validation.md) · [adr/](adr/) — 구조·정체성 (작품 존재 후)

---

## 1. 핵심 판단

| 축 | 402 (오늘) | 5M (장기) |
|----|------------|-----------|
| **구조** | v4 `wk_`·hash shard — **검증 중** | 인프라 변경 필요 (search_index 등) — **알려진 과제** |
| **데이터** | 엄선 402 · 수동·파이프라인 혼합 | **수백만 stub·enrich·dedupe** — **미해결 과제** |
| **병목 (오늘)** | 작품 **수** | — |
| **병목 (100k+)** | 메타 **품질·다국어·franchise** + 검색 | 저장은 2순위 이후 |

```
[오늘의 게이트]  작품을 넣을 수 있는가?  ← 본 문서
[다음 게이트]    넣은 작품을 찾을 수 있는가?  ← SW1
[다음 게이트]    넣은 작품이 올바른가?      ← URV
[알려진 게이트]  넣은 작품을 빨리 읽을 수 있는가? ← search_index Validation ✅
```

---

## 2. 성장 경로 (402 → 5,000,000)

### 2.1 단계 요약

| 단계 | 규모 | 시기 (목표) | Registry 성격 | 주 병목 |
|------|------|-------------|---------------|---------|
| **G0** | **402** | 2026 Steam v1 | 엄선·dogfood | **커버리지** (작품 수) |
| **G1** | **5,000** | ~2027 | 서브컬처 코어 + 대표 general | **수집 throughput** |
| **G2** | **50,000** | ~2028 | 카테고리별 주류 + 인디 진입 | **dedupe·메타 enrich** |
| **G3** | **500,000** | ~2030 | 글로벌 주류 + Long Tail 시작 | **검색·메타 품질** |
| **G4** | **5,000,000** | 장기 | Universal Works (정책 범위 내) | **운영·tier·품질 분리** |

### 2.2 단계별 목표 (무엇을 채울 것인가)

| 단계 | 커버리지 목표 | 의도적 제외 (당분간) |
|------|---------------|----------------------|
| G0 | 검증·UX용 엄선 | Long Tail 전면 |
| G1 | 애니·만화·게임 **주류** + 필수 영화·소설 | 전곡·전권·에피소드 단위 |
| G2 | MAL/Steam/OpenLibrary **주류 밴드** · 인디 허브 | 팬픽 bulk · 전수 franchise |
| G3 | 지역별 주류 · OST·드라마 확대 | 음악 전곡(ADR-002 B 전제) |
| G4 | [ADR-005](adr/ADR-005-minimum-recordable-unit.md) 범위 내 Long Tail tier | 비작품 엔티티 |

### 2.3 성장 곡선 (가설)

| 전환 | 신규 Work/월 (가설) | 누적 도달 |
|------|---------------------|-----------|
| G0→G1 | ~400 (배치+수동) | 12~18개월 |
| G1→G2 | ~3,000~5,000 | 12~15개월 |
| G2→G3 | ~30,000~50,000 | 18~24개월 |
| G3→G4 | ~200,000+ (tier별) | 수년 |

**전제:** G2부터 **Catalog Expansion Pipeline** 없이는 G3 **불가능**.

---

## 3. 규모별 수집 방식

### 3.1 네 가지 채널

| 채널 | 설명 | 적합 규모 |
|------|------|-----------|
| **수동 등록** | Maintainer PR · 앱 직접 등록 | G0~G1 전면 · G2+ **예외·고가치** |
| **반자동 Import** | CSV/JSON 배치 · id_registry 할당 · CI 게이트 | G1~G3 |
| **외부 메타 파이프라인** | Discovery Signal → Minimal Core → dedupe → human/auto | **G2~G4 주력** |
| **커뮤니티 기여** | Contribution add/fix · gap 보고 | **전 단계 보조** |

법무 전제: 외부 소스는 **Signal·Fact 참조**만 — [data-policy](data-policy.md) 미러링 금지.

### 3.2 규모 × 채널 매트릭스

| 규모 | 수동 | 반자동 Import | 파이프라인 | 커뮤니티 |
|------|------|---------------|------------|----------|
| **402** | ████████ 주 | ██ | █ (실험) | █ |
| **5k** | ████ | ██████ | ████ | ██ |
| **50k** | ██ | ████ | ████████ | ███ |
| **500k** | █ | ██ | ████████ | ████ |
| **5M** | ░ | ██ | ████████ tier | █████ |

### 3.3 단계별 상세

#### G0 — 402 (현재)

| 항목 | 방식 |
|------|------|
| 수집 | 수동 큐레이션 · AniList bulk **금지** · TMDB 포스터 검증 |
| 파이프라인 | Discovery **실험** (cursor 1채널, Git 저장 X) |
| 기여 | Contribution 골격 · status.json |
| 인프라 | v4 shard · GitHub raw sync |

#### G1 — 5,000

| 항목 | 방식 |
|------|------|
| 수동 | 신규 IP·争議 작품·포스터 오매핑 수정 |
| 반자동 | OpenLibrary ISBN · Steam app id 배치 (Fact만) |
| 파이프라인 | **Catalog Expansion MVP** — 애니/만화 후보 일 배치 |
| Discovery | AniList animation + MAL cross-check (Signal) |
| 커뮤니티 | fix 우선 · add는 reviewer 큐 |
| Franchise | linter 후보 · **수동 승인** ([ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md)) |

#### G2 — 50,000

| 항목 | 방식 |
|------|------|
| 파이프라인 | **주력** — AI normalize → Minimal Core · dedupe_linter |
| 반자동 | 주간 merge train · `assign_wk_ids` 배치 |
| 수동 | dedupe dispute · 2차 창작 분류 ([ADR-004](adr/ADR-004-work-collection-policy.md)) |
| Enrich | `titles`·`aliases` 비동기 — **등록과 분리** |
| 검색 | search_index **증분 빌드** 검토 (100k 게이트) |

#### G3 — 500,000

| 항목 | 방식 |
|------|------|
| 저장 | Git **소스** + CDN/R2 **read replica** ([data-architecture-redesign](data-architecture-redesign.md)) |
| 파이프라인 | 다소스 (Steam·OL·TMDB·Wikidata Signal) · confidence tier |
| Franchise | universe/subseries **지연 생성** · tier 2 human |
| SW1/URV | recall·canonical **회귀 CI** |
| Long Tail | §5 tier 1~2 |

#### G4 — 5,000,000

| 항목 | 방식 |
|------|------|
| 파이프라인 | **tier 0/1/2** 롱테일 (§5) · 일일 상한 |
| 저장 | shard Git 유지 · search_index **분리 아키텍처** (SW2 후) |
| 메타 | stub vs enriched **이중 품질** — 검색 랭킹 분리 |
| 커뮤니티 | gap-driven add · 팬픽 Contribution only |
| 운영 | dedupe 큐 SLA · maintainer headcount **명시적 병목** |

### 3.4 파이프라인 표준 흐름 (G2+)

```
외부 Signal (TTL, Git X)
  → Legal Field Gate (data-policy)
  → Rule Normalize → Minimal Core draft
  → dedupe_linter (후보만, auto-merge X)
  → confidence router
       ├─ high + exact externalId → auto-stub (optional, ADR 미정)
       ├─ medium → human queue
       └─ low / fanwork → reject or Contribution
  → shard insert + id_registry
  → registry_builder (증분)
  → enrich queue (titles, poster, franchise hint) — 비동기
```

---

## 4. 최소 등록 기준 (Work 생성 가능 조건)

### 4.1 Registry Minimal Core ([data-policy §1.2](data-policy.md#12-registry-minimal-core-필수-영구-저장))

**하드 필수 (없으면 Work 생성 불가)**

| 필드 | 규칙 |
|------|------|
| `workId` | `wk_` 신규 발급 · 불변 |
| `title` | 비어 있지 않음 · Fact |
| `category` | AKASHA taxonomy 1개 |

**하드 필수 (둘 중 하나)**

| 필드 | 규칙 |
|------|------|
| `releaseYear` | 사실 연도 |
| **또는** `externalIds` | 최소 1개 (`mal`·`steam`·`tmdb`·`isbn`·`igdb` …) |

**강력 권장 (없어도 stub 가능 · 품질 tier ↓)**

| 필드 | 규칙 |
|------|------|
| `creator` | 작가·감독·개발사 |
| `domain` | `subculture` / `generalCulture` |
| `titles.{en,ja,ko}` | G2부터 **파이프라인 목표** (SW1/URV) |

**필수 아님 (Enrich · 나중)**

| 필드 | 규칙 |
|------|------|
| `description` | AKASHA 자체 1~3문장 |
| `tags` | |
| `posterPath` | URL null 허용 |
| `aliases` | |
| `franchise` | 멤버십은 별도 파일 · 사후 연결 |

### 4.2 Work 생성 **거부** 조건

| 조건 | 근거 |
|------|------|
| title + category만 있고 year·externalId **둘 다 없음** | dedupe 불가 · 유령 Work |
| [ADR-004](adr/ADR-004-work-collection-policy.md) 제외 유형 | 웹사이트·언어·모델 등 |
| data_policy_linter **error** | API blob · 시놉 복제 · 금지 필드 |
| dedupe exact match 기존 `wk_` | 신규 생성 대신 **merge 후보** |
| ADR-003 위반 (에피소드 단위 wk_) | 구조 정책 |
| 팬픽 bulk ingest | Contribution only |

### 4.3 Stub vs Enriched

| 등급 | Minimal Core | 검색·UX |
|------|--------------|---------|
| **Stub** | §4.1 충족 | 카드·검색 가능 · quality tier 0~2 |
| **Enriched** | + titles·poster·creator verified | tier 3+ · SW1 recall 대상 |
| **Canonical** | + franchise·alias·다국어 쌍 | URV·IP 1카드 대상 |

**성장 전략:** G2+에서는 **Stub 먼저 대량** → Enrich는 비동기.  
「등록」과 「완성」을 분리하지 않으면 throughput이 **0**에 수렴.

---

## 5. Long Tail 전략

### 5.1 정의

| 유형 | 예 | ADR |
|------|-----|-----|
| **마이너 작품** | 소규모 동인 애니·웹소설 | [ADR-004](adr/ADR-004-work-collection-policy.md) |
| **절판 작품** | 오래된 PC 게임·단행본 | externalId 없을 수 있음 — ISBN·수동 Fact |
| **인디 작품** | itch.io · 자가출판 | `origin:indie` · 동일 Minimal Core |

### 5.2 Tier 모델 (G3~G4)

| Tier | 대상 | 수집 | Franchise | 검색 기대 |
|------|------|------|-----------|-----------|
| **T0** | 문화적 주류 · 검색 gap | 파이프라인 자동 stub | 우선 연결 | recall Must |
| **T1** | 인디·니치 · 커뮤니티 요청 | Contribution + 배치 | 선택 | recall Should |
| **T2** | 절판·희귀 · Fact 빈약 | 수동·위키 Signal | 지연 | 존재만 (찾기 어려움 허용) |
| **T3** | 2차 창작 · 팬픽 | Contribution only | 원작 분리 | opt-in 필터 |

### 5.3 Long Tail 리스크 완화

| 리스크 | 완화 |
|--------|------|
| dedupe 폭발 | externalId 우선 · fuzzy는 T0만 |
| 저품질 stub 오염 | quality tier · 검색 랭킹 하한 |
| 절판 메타 부재 | `releaseYear` 생략 + `externalIds.isbn` 또는 maintainer Fact |
| 인디 폭증 | indie tag · 동일 스키마 · 별도 **우선순위 아님** |
| 5M 환상 | T2/T3는 **비율 상한** (예: 전체 10~20%) — 정책 수치는 URV-C에서 확정 |

### 5.4 「모든 작품」의 현실적 의미

**5M = 전 세계 모든 문화 콘텐츠의 완전 커버가 아니라**,  
[ADR-005](adr/ADR-005-minimum-recordable-unit.md) **Minimum Work Unit** 기준 **검색·아카이브 가능한 stub의 상한**에 가깝다.

---

## 6. Registry 성장 병목 평가

### 6.1 세 축 비교 (402 · 50k · 500k · 5M)

| 축 | 402 (오늘) | 50k | 500k | 5M |
|----|------------|-----|------|-----|
| **저장소** | ✅ 여유 | ✅ | ⚠️ Git 한계 | ⚠️ read 분리 필수 |
| **검색** | ✅ | ⚠️ index ~3MB | ❌ index ~300MB+ | ❌ **구조 변경 필수** |
| **메타데이터 품질** | ⚠️ en 28% | ❌ 주 병목 | ❌ | ❌ |

### 6.2 판정 — 우선순위

| 순위 | 병목 | 근거 |
|------|------|------|
| **1 (G0~G1)** | **데이터 확보 (커버리지)** | 402는 구조 검증용 · 작품 수 자체가 제품 가치 상한 |
| **2 (G1~G2)** | **메타데이터 품질 + dedupe throughput** | Stub은 쉬움 · titles/alias/franchise enrich가 SW1·URV 실패 원인 |
| **3 (G2~G3)** | **검색 (search_index)** | [실측](registry-bottleneck-validation-report.md): 300k FAIL · 100k WARN |
| **4 (G3~G4)** | **저장소·Git 운영** | [scaling review](registry-scaling-review.md): 1M에서 ~2GB · shard는 상대적 양호 |
| **5 (전 구간)** | **Franchise 큐레이션 운영** | 물리보다 **인적** 병목 · [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md) tier |

**결론:**

- **오늘~5k:** 병목은 **저장소·검색이 아니라 「넣을 작품」과 「넣는 속도」**다.
- **50k~500k:** **메타 품질**(다국어·alias)과 **검색**이 동시에 드러남 — SW1·URV가 게이트.
- **5M:** 저장·검색 인프라는 **알려진 과제**로 분리 가능 · **지속 가능한 파이프라인+enrich 용량**이 최종 병목.

### 6.3 구조 vs 데이터 (사용자 판단 정렬)

| 질문 | 답 |
|------|-----|
| ADR-006 depth≤3가 5M을 막는가? | **아니오** — franchise는 지연·tier로 완화 |
| search_index가 5M을 막는가? | **예 (읽기·검색)** — 이미 실측 · SW2로 분리 |
| Minimal Core stub가 5M을 막는가? | **아니오** — shard·wk_는 선형 |
| **작품을 누가 언제 enrich하느냐**가 5M을 막는가? | **예** — **핵심 리스크** |

---

## 7. 단계별 게이트 (Go / No-Go)

| 전환 | Go 조건 |
|------|---------|
| G0→G1 | Steam v1 · `ci_registry_check` · Contribution status |
| G1→G2 | Expansion MVP · 일 N건 stub · dedupe precision 측정 |
| G2→G3 | 50k stub · search_index 증분/분할 **POC** · SW1-A baseline |
| G3→G4 | 500k · SW1 Phase B · URV Phase B · CDN read · tier 정책 |
| G4 유지 | 월간 enrich SLA · recall regression · dedupe false merge 0 |

---

## 8. 리스크 레지스터

| ID | 리스크 | 영향 | 완화 |
|----|--------|------|------|
| R1 | 파이프라인 없이 목표 규모 고수 | 일정 붕괴 | G2 전 Expansion MVP |
| R2 | Stub만 쌓고 enrich 정체 | SW1 GAP 90%+ | enrich queue KPI |
| R3 | 외부 DB 미러링 유혹 | 법무·품질 | data-policy CI |
| R4 | franchise 수동 전수 | 운영 불가 | ADR-006 tier·지연 |
| R5 | search_index 방치 | 100k UX 붕괴 | Validation 완료 → SW2 |
| R6 | 음악 전곡 (ADR-002 B) | 30M+ Work | tier·인기곡 우선 |
| R7 | maintainer 단일 인력 | 50k ceiling | 커뮤니티·confidence auto-stub 정책 |

---

## 9. 산출물 · 다음 단계

| 산출물 | 상태 |
|--------|------|
| 본 성장 전략 | ✅ |
| Catalog Expansion Pipeline 구현 | ⏳ G1~G2 |
| G1 반자동 Import playbook | ⏳ |
| enrich SLA · tier 수치 | ⏳ URV-C / 운영 실측 |
| ADR-006 승인 | 🔶 사용자 승인 가능 · 문서 반영 대기 |

**권장 순서**

1. **G1 목표 카테고리·5k 목록** 확정 (주류 밴드)
2. **Expansion MVP** — Minimal Core만 주간 배치
3. **enrich backlog** — titles.en/ja (SW1 GAP 연동)
4. 구조(SW2)는 **50k 게이트** — 데이터 확보와 **병행**하되 우선순위는 본 문서 §6.2

---

## 10. 원칙

1. **Registry는 비어 있으면 무용** — ADR·URV는 품질이지 존재를 보장하지 않는다.
2. **Stub first, enrich later** — 5M은 한 번에 완성 작품이 아니라 **5M개의 출발점**이다.
3. **Discovery ≠ Growth** — Signal은 연료 · Growth는 **Registry insert throughput**이다.
4. **Long Tail는 tier로** — T2/T3 무제한 bulk는 canonical recall을 죽인다.
5. 구조 검증(SW·URV)과 성장(본 문서)은 **직렬 게이트** — 작품을 넣은 뒤 찾고, 찾은 뒤 정제한다.
