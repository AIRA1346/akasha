# Wikidata Spine Plan — 1차 데이터 연동 전략

> **상태:** 확정 방향 (2026-06-10)  
> **지위:** Discovery·Registry 확장의 **구조·확장성 SSOT**  
> **근거:** [discovery-legal-baseline.md](../policy/discovery-legal-baseline.md) · [catalog-growth-charter.md](../programs/catalog-growth-charter.md) · live shadow·SPARQL 검증  
> **상위:** [data-policy.md](../data-policy.md) · [discovery-policy.md](../discovery-policy.md)

---

## 1. 한 줄 결정

```
Canonical ID = wk_ (불변)
데이터 spine = Wikidata (Q-id + 허용 Fact + P-관계 그래프)
제품 단위 = Franchise(IP 1카드) + Work(매체) + seasons[](시즌 메타)
```

**Wikidata를 가장 중요한 연동 상대로 둔다.**  
다만 Wikidata가 AKASHA Registry를 **대체하지는 않는다** — ingest·참조·관계의 **1차 축**이다.

---

## 2. 왜 Wikidata인가

| 기준 | Wikidata | AniList/MAL API | Steam/TMDB |
|------|----------|-----------------|------------|
| 범위 | 만화·애니·게임·책·영화 **횡단** | 매체별 편중 | 도메인 편중 |
| 법무 (Facts) | CC0 structured data | ToS·bulk 금지 (폐기) | 약관·이미지 리스크 |
| 관계 모델 | Q + P 그래프 (시리즈·시즌·원작) | relations 미러 부적합 | 앱/에디션 중심 |
| 확장성 | Q-id 무한 증가 | — | — |

**폐기:** AniList API bulk ingest (코드·정책 반영 완료).  
**보조:** `steam` · `mal` · `tmdb` — **해당 category dedupe용 sparse** (Wikidata 대체 아님).

---

## 3. 설계 원칙 (절대 규칙)

| # | 원칙 |
|---|------|
| W1 | **`wk_`는 절대 불변** — 볼트·legacy_aliases·샤딩의 유일 본체 |
| W2 | **`externalIds.wikidata`는 가능한 모든 Work에 부착** — spine |
| W3 | **Fact만 Registry** — description·poster·raw SPARQL JSON **Git 금지** |
| W4 | **Q-id는 label·P31 검증 후만 저장** — 번호만 믿지 않음 (§7) |
| W5 | **Wikidata 그래프는 내부**, **UX는 단순** — 시즌마다 `wk_` 남발 금지 (기본) |
| W6 | **자동 merge 금지** — Q·제목 일치도 PR/리뷰 큐 |
| W7 | **충돌 시 AKASHA Canonical 우선** — Wikidata는 갱신·수정 **참고** |

---

## 4. 3계층 정체성 모델

```
┌─────────────────────────────────────────────────────────┐
│ Tier 0   wk_                    AKASHA 불변 ID          │
├─────────────────────────────────────────────────────────┤
│ Tier 1   title · titles · category · releaseYear · …   │
│          externalIds.wikidata   (대표 Q, spine)         │
├─────────────────────────────────────────────────────────┤
│ Graph    wikidataRelations[]    (P-id → target Q)       │
│          extensions.seasons[]   (시즌 Q · label · year) │
│          Franchise.externalIds.wikidata (IP Q)          │
└─────────────────────────────────────────────────────────┘
```

### 4.1 Franchise ↔ Wikidata

| AKASHA | Wikidata 대응 | 예 (귀멨) |
|--------|---------------|-----------|
| `franchise_*` · IP 1카드 | `P31` = media franchise | **Q105037706** |
| `displayNames` | label (다언어) | ko/en/ja |
| `members[]` | `P527` (has part) 자식 Work | 만화·애니·극장판 Q들 |

### 4.2 Work ↔ Wikidata

| AKASHA `category` | Wikidata `P31` (대표) | Work 단위 |
|-------------------|----------------------|-----------|
| `manga` | manga series (Q21198342) | 시리즈 1작 |
| `animation` | anime television series | TV 시리즈 1작 |
| `movie` / `animation` | anime film | 극장판·단편 (별도 Work) |
| `game` | video game | 1 타이틀 |
| `book` | literary work / novel | 1 권·시리즈 (정책별) |

**P31 → category 매핑표**는 파이프라인 코드·CI에 유지 (다대일 허용).

### 4.3 시즌 · 파트 (애니)

| Wikidata | AKASHA |
|----------|--------|
| 시즌별 Q (anime television series season) | `extensions.seasons[]` 항목 |
| `P179` part of series → 애니 TV Q | `seasons[].seriesQid` 또는 부모 Work Q |
| `P527` has part (시리즈 → 시즌 목록) | ingest 시 seasons 배열 생성 |
| `P155`/`P156` (있을 때만) | `wikidataRelations[]` |

**기본:** TV 애니 = **`wk_` 1개** + seasons. 시즌별 `wk_`는 **예외** (파워유저·URV 후).

---

## 5. `externalIds` 정책 (sparse)

| provider | 역할 | 규칙 |
|----------|------|------|
| **`wikidata`** | universal spine | **가능하면 필수** |
| `steam` | 게임 dedupe·스토어 | `category=game`만 |
| `mal` / `tmdb` | 애니·영화 exact match | 있으면 유지, 신규는 선택 |
| `isbn` / `openlibrary` | 도서 | 해당 시 |
| **`anilist`** | — | **신규 금지** · Phase 5d 제거 |

**「Wikidata만 남긴다」는 하지 않는다** — dedupe 안전망 유지.  
**「모든 Work에 wikidata」**가 목표.

---

## 6. 스키마 확장 (v4.1 방향)

기존 [SCHEMA.md](../../akasha-db/SCHEMA.md) · v4 shard **호환** — 필드 추가만.

### 6.1 Work shard (신규·선택 필드)

```json
{
  "workId": "wk_000000500",
  "title": "귀멸의 칼날",
  "category": "animation",
  "externalIds": { "wikidata": "Q63350570" },
  "wikidataRelations": [
    { "p": "P144", "target": "Q24862683" }
  ],
  "extensions": {
    "seasons": [
      {
        "label": "season 1",
        "releaseYear": 2019,
        "wikidata": "Q105847391"
      },
      {
        "label": "season 2",
        "releaseYear": 2021,
        "wikidata": "Q105847067"
      }
    ]
  }
}
```

| 필드 | 필수 | 비고 |
|------|:----:|------|
| `externalIds.wikidata` | ⚠️ | spine — 없으면 quality tier ↓ |
| `wikidataRelations` | | P-id + target Q만 (문자열) |
| `extensions.seasons` | | 애니·드라마 시리즈 |
| `extensions.seasons[].wikidata` | ⚠️ | 시즌 Q |

### 6.2 Franchise (`franchise_groups` v2+)

```json
{
  "franchiseId": "franchise_kimetsu",
  "displayNames": { "ko": "귀멸의 칼날", "en": "Demon Slayer: Kimetsu no Yaiba" },
  "externalIds": { "wikidata": "Q105037706" },
  "primaryWorkId": "wk_…",
  "members": ["wk_manga", "wk_anime", "wk_mugen"]
}
```

### 6.3 `wk_` 확장성

| 단계 | 형식 | 상한 |
|------|------|------|
| **현재 v4** | `wk_` + 9자리 | ~10억 |
| **v5 (필요 시)** | `wk_` + **가변 길이 정수** (Q-id와 동일 철학) | 실질 무한 |

9자리 소진 전에 **가변 길이 마이그레이션** 1회. 샤딩은 `hash(wk_)%256` **유지**.

---

## 7. Q-id 검증 게이트 (필수)

대화·SPARQL 검증에서 확인된 **실패 패턴:** 예전 문서·AI가 준 Q-id가 **재사용·오류** (예: Q61093122 ≠ 귀멨 애니, Q112674443 ≠ 1기).

### 7.1 ingest 전 체크

| 단계 | 검증 |
|------|------|
| V1 | `wbgetentities` 또는 SPARQL로 **영문/일문 label** 존재 |
| V2 | **P31**이 채널 기대 클래스와 일치 (manga series, anime TV, …) |
| V3 | Franchise Q는 `media franchise` 등 허용 클래스 |
| V4 | 동일 Q가 **다른 workId**에 이미 있으면 **E3 BLOCK** |
| V5 | label이 title과 **완전 무관**하면 REVIEW |

### 7.2 금지

- Q-id만 보고 자동 merge
- 검증 없이 `seasons[].wikidata` bulk paste
- 삭제된 Q 가정 (항상 live 조회)

---

## 8. 참조 예시 — 귀멸의 칼날 (live Wikidata, 2026-06)

> **SSOT 샘플 IP** — 파이프라인·테스트·수동 PR 시 이 Q-id 사용.

```
[Q105037706] media franchise
  P527 ── Q24862683   manga
  P527 ── Q63350570   anime TV
  P527 ── Q96376192   Mugen Train film
  P527 ── Q107367351   game (선택)

[Q24862683] manga
  P31 manga series · P50 Koyoharu Gotōge

[Q63350570] anime TV
  P144 → Q24862683 (based on manga)
  P527 → Q105847391 season 1
  P527 → Q105847067 season 2
  P527 → Q117113126 season 3
  P527 → Q124624636 season 4

[Q96376192] Mugen Train (film)
  P31 anime film · P144 → Q24862683
```

### AKASHA 매핑 (목표)

| 엔티티 | `wk_` | 대표 Q |
|--------|-------|--------|
| Franchise | `franchise_kimetsu` | Q105037706 |
| Work 만화 | `wk_*` | Q24862683 |
| Work TV애니 | `wk_*` | Q63350570 + seasons[] |
| Work 극장판 | `wk_*` | Q96376192 |

**주의:** 무한열차의 `P144`는 **만화**이지 1기 Q가 아님. P155 체인을 **억지로 만들지 않음**.

---

## 9. Discovery 파이프라인 로드맵

### Phase 0 — 완료·진행 중

| 항목 | 상태 |
|------|------|
| AniList ingest 폐기 | ✅ |
| `wikidata_manga` 채널 · manifest | ✅ |
| live shadow 100 (offset 0) | ✅ 60 create / 40 merge |
| legal baseline · UA · 429 retry | ✅ |

### Phase 1 — Manga trial (G1)

| # | 작업 |
|---|------|
| 1.1 | merge 40 — 기존 `wk_`에 `externalIds.wikidata` |
| 1.2 | trial insert ≤60 — `preflight_check` · cursor → 100 |
| 1.3 | `P31=manga series` SPARQL 채널 안정화 (~17.9k) |

### Phase 2 — Graph enrich (IP 대표작)

| # | 작업 |
|---|------|
| 2.1 | `wikidata_franchise` 수동 큐 — media franchise Q → franchise_groups |
| 2.2 | 애니 TV Work: `P527` → `seasons[]` 자동 채움 |
| 2.3 | `wikidataRelations` (P144, P179, P527) 제한 집합만 |

### Phase 3 — 채널 확장

| 채널 | SPARQL 스코프 | category |
|------|---------------|----------|
| `wikidata_manga` | P31=Q21198342 | manga |
| `wikidata_anime` | anime television series | animation |
| `wikidata_game` | video game | game |
| `wikidata_book` | (정의 후) | book |

각 채널: **trialBatchSize ≤100** · **dailyLimit ≤500** · 배치마다 gate.

### Phase 4 — 대량 (10k+)

| 경로 | 용도 |
|------|------|
| Wikidata **JSON dump** | SPARQL 연속 호출 대신 오프라인 Fact 추출 |
| 증분 sync | dump revision + cursor |

---

## 10. AKASHA ↔ Wikidata 대응 요약

| Wikidata 개념 | AKASHA |
|---------------|--------|
| Item Q | `externalIds.wikidata` + (선택) graph 노드 |
| Property P | `wikidataRelations[].p` |
| media franchise | Franchise + `externalIds.wikidata` |
| manga / anime TV / film | Work (`category`별) |
| anime season Q | `extensions.seasons[]` (기본) |
| P527 has part | seasons ingest · franchise members 힌트 |
| P179 part of series | season → parent anime Q |
| P144 based on | 원작 링크 (만화·소설) |

**의도적 차이**

| Wikidata | AKASHA |
|----------|--------|
| 시즌 = 독립 Q 항목 | 시즌 = **부모 Work 내부** (기본) |
| Q = 전 세계 식별자 | **`wk_` = 제품 식별자**, Q = spine |

---

## 11. 운영 · 법무 · CI

| 항목 | 규칙 |
|------|------|
| User-Agent | `AKASHA-Discovery/1.0` + GitHub URL ([wikidata_client.dart](../../tool/discovery/wikidata_client.dart)) |
| Rate limit | WDQS 1 parallel/IP · 429 Retry-After |
| Git 저장 | Facts·Q·P 참조만 · raw 응답 ❌ |
| 배치 후 | `preflight_check` · `ci_registry_check` · `registry_builder` |
| Pause (SD3) | dedupe·quality FAIL 시 **감속** (전면 hold 아님) |

---

## 12. 하지 않는 것

| ❌ | 이유 |
|----|------|
| `wk_` → Q-id로 교체 | 볼트 불변·Q 병합 리스크 |
| Wikidata description/이미지 복제 | Copyright · Tier 1 금지 |
| 시즌마다 기본 `wk_` | 서재·검색 복잡도 |
| Q-id 무검증 bulk | 재사용·오매칭 (§7) |
| AniList API 재도입 | legal baseline |
| 「Wikidata ontology = UI taxonomy」 | 7 category · domain 유지 |

---

## 13. 성공 지표

| 축 | 지표 | G1 목표 (초안) |
|----|------|----------------|
| Spine | `wikidata_coverage` (Work 중 Q 보유 %) | ↑ 주간 측정 |
| 정확도 | Q 검증 FAIL / insert | **0** |
| 성장 | `wouldCreate` trial 성공 · search 0건 ↓ | charter |
| 그래프 | 대표 IP seasons[] 채움 | 샘플 10 IP |
| 독립성 | `wk_` without external source 가치 | Phase 5d |

---

## 14. 즉시 실행 순서

```
1. merge 40 (wikidata 링크) ─┐
2. trial insert 60 (manga)   ├─ Phase 1
3. cursor offset 100         ─┘
4. 본 문서 스키마 → SCHEMA.md § 보강 (wikidataRelations·seasons)
5. Q 검증 gate → contract_test_runner 확장
6. 귀멨 수동 PR (Franchise + 3 Work) — §8 Q-id SSOT
7. wikidata_anime 채널 manifest 초안
```

---

## 15. 관련 문서

| 문서 | 관계 |
|------|------|
| [discovery-legal-baseline.md](../policy/discovery-legal-baseline.md) | 법무 SSOT |
| [discovery-source-decision.md](../discovery-source-decision.md) | 소스 요약 |
| [discovery-policy.md](../discovery-policy.md) | Fact 경계 |
| [canonicalization-policy.md](../policy/canonicalization-policy.md) | dedupe·시즌 (§4.3과 정합 검토) |
| [catalog-growth-charter.md](../programs/catalog-growth-charter.md) | SD2.6 해제·병행 확장 |
| [wikidata-manga-shadow-2026-06-10.md](../programs/wikidata-manga-shadow-2026-06-10.md) | manga shadow 실측 |
| [universal-registry-validation.md](../validation/universal-registry-validation.md) | Franchise·Series URV |

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | 초안 — 대화·shadow·귀멨 SPARQL 검증 반영 |
