# Discovery 법무 기준선 — 최종 검토 (코드·ToS 직접 확인)

> **검토일:** 2026-06-10  
> **방법:** 내부 md **아님** — 구현 코드 감사 + Wikimedia·AniList·Open Library **공식 정책** 대조  
> **지위:** Registry ingest **법무·운영 SSOT** — [discovery-source-decision.md](../discovery-source-decision.md) **대체·확정**  
> **면책:** 변호사 자문 **아님**. Steam 상업 배포·대규모 ingest 전 **현지 IP 변호사** 검토 권장.

---

## 1. 확정 결론 (한 줄)

**AKASHA가 채택하는 안전 경로는 이것뿐이다:**

| 순위 | 경로 | 용도 |
|:----:|------|------|
| **1** | **수동 PR / Maintainer 작성 Fact** | 모든 카테고리 · 최우선 |
| **2** | **Wikidata CC0 구조화 Fact** (Q-id·label·연도·창작자명) | 만화 등 Discovery — **아래 운영 규칙 필수** |
| **3** | **Open Library 월간 덤프** (API bulk ❌) | book·라노벨 — 예정 |
| **❌** | **AniList·MAL·트래커 API 대량 ingest** | **영구 금지** |
| **❌** | description·시놉·이미지·raw API/SPARQL Git 저장 | **영구 금지** |

**저작권 리스크가 가장 낮은 “확정 스택”:**  
`수동 큐레이션` + `Wikidata Facts-only (CC0)` + `gate·CI` + `대량은 덤프·소량은 SPARQL`.

---

## 2. 검토 방법

### 2.1 코드 감사 (실제 ingest 경로)

| 파일 | 확인 내용 |
|------|-----------|
| `tool/discovery/wikidata_client.dart` | SPARQL이 요청하는 필드 |
| `tool/discovery/wikidata_facts.dart` | Registry로 변환되는 필드 |
| `tool/discovery/signal_gate.dart` | Minimal Core draft |
| `tool/discovery/discovery_types.dart` | `discoveryForbiddenFactKeys` |
| `tool/discovery/contract_test_runner.dart` | raw 저장 없음 |
| `tool/data_policy_utils.dart` | Tier 1 CI |

### 2.2 외부 정책 (직접 확인)

| 소스 | 근거 URL |
|------|----------|
| Wikidata CC0 | [Wikidata:Copyright](https://www.wikidata.org/wiki/Wikidata:Copyright) |
| Wikimedia ToU | [Policy:Terms of Use](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use) |
| User-Agent | [Policy:User-Agent policy](https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy) |
| WDQS 한도 | [WDQS User Manual — Query limits](https://www.mediawiki.org/wiki/Wikidata_Query_Service/User_Manual#Query_limits) |
| AniList API | [docs.anilist.co — Terms of Use](https://docs.anilist.co/guide/terms-of-use) |
| Open Library | [Developers / Licensing](https://openlibrary.org/developers/licensing) · [API bulk](https://openlibrary.org/developers/api) |

---

## 3. 소스별 판정

### 3.1 AniList API — **금지 (확정)**

공식 ToS (직접 인용):

- *"Hoarding or mass collection of data from the AniList API is strictly prohibited."*
- *"Using the AniList API as a backup or data storage service is strictly prohibited."*
- *"Prohibited from use within competing noncomplementary services of the same nature… Anime/Manga list/tracker services."*

AKASHA = 글로벌 작품 사전 + 개인 아카이브 → **트래커형 서비스와 동종**으로 해석될 여지가 큼.  
Fact만 넣어도 **수집 행위·Git 영구 저장** 자체가 ToS와 충돌.

**조치:** live fetch 제거됨 · `anilist_*` 채널 CI 금지 · 신규 ingest 없음.

---

### 3.2 Wikidata — **허용 (조건부 · 현재 1차 소스)**

**저작권 (데이터):**

[Wikidata:Copyright](https://www.wikidata.org/wiki/Wikidata:Copyright):

> *"All structured data from the main, Property, Lexeme, and EntitySchema namespaces is available under the Creative Commons **CC0 License**"*

AKASHA가 저장하는 것 = **구조화 Fact** (Q-id, label, publication year, creator **이름**, instance-of→category).  
**description·이미지·Wikipedia 발췌는 요청·저장하지 않음** (코드 확인 §4).

**잔여 리스크 (낮음·관리 가능):**

| 리스크 | 대응 |
|--------|------|
| EU DB권 등 이론적 논쟁 | CC0 + 사실 위주 · 변호사 검토 권장 |
| 잘못된 Wikidata 사실 | dedupe·수동 검수 · `externalIds.wikidata` 참조 |
| **인프라 ToS** (저작권 아님) | User-Agent·rate limit·덤프 우선 (§5) |

**운영 ToS (Wikimedia):**

- [User-Agent policy](https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy): 식별 가능한 UA + **연락처(이메일 또는 URL)** 필수.
- [WDQS Query limits](https://www.mediawiki.org/wiki/Wikidata_Query_Service/User_Manual#Query_limits): 클라이언트당 60초/60초 처리 시간 · 429 시 **Retry-After 준수** · 무시 시 **24h ban** 가능.

→ **법무(저작권)는 양호**, **대량 수집은 WDQS 매너·덤프 전략**이 관건.

---

### 3.3 Open Library — **허용 (덤프만 · API bulk 금지)**

[Licensing](https://openlibrary.org/developers/licensing): DB에 대한 별도 저작권 주장 없음 · 사실(Feist) 위주.

[API](https://openlibrary.org/developers/api): *"Please do not use our APIs for bulk download… use monthly data dumps."*

→ book/ISBN 확장 시 **월간 덤프 + 선별 ingest**. live API 연속 호출 **금지**.

---

### 3.4 수동 PR / Contribution — **최상위 (항상 허용)**

AKASHA가 직접 작성·검수한 Fact. 외부 ToS 범위 밖.  
争議 작품·고가치 IP는 **자동 ingest보다 우선**.

---

### 3.5 TMDB · Steam · MAL · 기타 트래커 API bulk — **미채택**

AniList와 유사: 약관상 bulk·미러·상업 리스크.  
필요 시 **개별 ID 수동 attach** 또는 **사용자 vault**만.

---

## 4. 코드 준수 감사 결과

### 4.1 Wikidata SPARQL (`wikidata_client.dart`)

**요청 필드 (실측):**

- `?item` (Q-id) · `?itemLabel` (en) · `?itemLabelJa` · `?authorLabel` · `?startYear` (P577)
- `P31` = manga series (`Q21198342`)
- **없음:** `description`, `schema:description`, image (P18), sitelinks text

**판정:** ✅ 정책과 일치

### 4.2 Fact 추출 (`wikidata_facts.dart`)

출력: `title`, `titles.{en,ja}`, `releaseYear`, `creator`, `category=manga`  
→ Registry: `externalIds.wikidata`

**판정:** ✅ Minimal Core만

### 4.3 Signal gate (`discovery_types.dart` + `signal_gate.dart`)

`discoveryForbiddenFactKeys`: description, synopsis, tags, coverImage, score, rawResponse 등 **41개 차단**.

**판정:** ✅ 이중 검증

### 4.4 영구 저장 금지

- `contract_test_runner.dart`: KPI만 · raw Git 저장 없음
- `pipeline/.gitignore`: raw·jsonl 차단

**판정:** ✅

### 4.5 코드 갭 (운영·ToS — **수정 완료 또는 필수**)

| 항목 | 이전 | 조치 |
|------|------|------|
| User-Agent 연락처 | 프로젝트명만 | **GitHub URL 포함** (`wikidata_client.dart`) |
| 429 Retry-After | throw만 | **대기 후 1회 재시도** |
| 대량(수천~수만) | SPARQL 연속 | **Wikidata JSON dump** 경로 문서화 (§5.3) |

---

## 5. 확정 운영 규칙 (법무 + ToS)

### 5.1 모든 소스 공통

1. Registry Tier 1 = **Fact only** — `description`·`posterPath`·tags bulk **금지** (CI)
2. raw API / SPARQL 응답 **Git 금지**
3. `pre_insert_dedupe_gate` + `preflight_check` **배치마다**
4. 출처는 `externalIds.*` **숫자·Q-id 참조** — Canonical은 `wk_`

### 5.2 Wikidata live SPARQL (trial·소량)

| 규칙 | 값 |
|------|-----|
| User-Agent | `AKASHA-Discovery/1.0 (https://github.com/AIRA1346/akasha; bot)` + 연락 URL |
| 병렬 쿼리 | **1** (WDQS 5 parallel/IP 한도) |
| 배치 크기 | trial **≤100** · 일일 **≤500** (manifest) |
| 429 | **Retry-After** 또는 최소 60초 대기 후 재시도 |
| 밴 시 | 24h 중단 · 덤프 경로로 전환 |

### 5.3 Wikidata 대량 (G1 이상)

| 규칙 | 내용 |
|------|------|
| 방법 | [Wikidata JSON dumps](https://www.wikidata.org/wiki/Wikidata:Database_download) — **SPARQL 연타 금지** |
| 필터 | 로컬에서 P31·P577·P50 추출 — live와 **동일 Fact 집합** |
| 라이선스 | 덤프도 CC0 structured data 동일 |

### 5.4 Open Library (예정)

- **월간 덤프만** · API bulk ❌
- `description` OL/Wikipedia 유래 → Registry **금지**

### 5.5 Attribution (권장·법무 필수 아님)

CC0는 **표시 의무 없음**. 다만 Wikimedia **선의** 및 투명성을 위해 About/문서에  
*"일부 메타데이터는 Wikidata(CC0)를 참조했습니다"* 수준 권장.

---

## 6. 위험도 매트릭스 (요약)

| 경로 | 저작권 | 계약 ToS | AKASHA |
|------|:------:|:--------:|:------:|
| 수동 PR | 최저 | 해당 없음 | ✅ **1순위** |
| Wikidata Facts + gate | **낮음** (CC0) | **준수 필요** (UA·rate) | ✅ **2순위** |
| OL 덤프 Facts | 낮음 | 덤프 OK / API bulk ❌ | ✅ 3순위 |
| Wikidata SPARQL 무제한 | 낮음 | **높음** (ban) | ❌ |
| AniList API bulk | 중 | **매우 높음** | ❌ **금지** |
| description·이미지 복제 | **높음** | — | ❌ **금지** |

---

## 7. Steam 상업 배포 메모

- Wikidata **CC0 Facts** 상업 이용 **일반적으로 허용** (CC0 명시).
- AniList **금지** 유지가 상업 리스크의 핵심 감소 요인.
- 앱 About: Tier 1에 이미지·시놉 없음 · 유저 vault 책임 — [data-policy.md](../data-policy.md) §0.3.

---

## 8. 관련 코드·문서

| 항목 | 경로 |
|------|------|
| Wikidata client | `tool/discovery/wikidata_client.dart` |
| Fact gate | `tool/discovery/signal_gate.dart` |
| Manifest | `akasha-db/pipeline/discovery/manifest.json` |
| 데이터 정책 | [data-policy.md](../data-policy.md) |
| 소스 결정 (요약) | [discovery-source-decision.md](../discovery-source-decision.md) |

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | 코드·공식 ToS 직접 검토 — **본 문서 확정** |
