# ADR-003: 시리즈 작품 최소 단위

| 항목 | 내용 |
|------|------|
| **상태** | **초안** — 에피소드/챕터 Registry 밖 **원칙 승인** · 세부는 URV-A |
| **범위** | 연재·시즌·에피소드·권 단위가 있는 모든 작품 |
| **선행** | [ADR-001](ADR-001-dual-layer-entity-model.md) · [canonicalization-policy.md](../canonicalization-policy.md) |

---

## 1. 문제

「원피스」를 어디까지 하나의 Registry 항목으로 볼 것인가?

| 후보 단위 | 예 |
|-----------|-----|
| IP 전체 | 원피스 (만화+애니+게임+…) |
| 매체·시리즈 | 원피스 TV 애니 1~2기 |
| 최소 소비 단위 | 에피소드 1071화 |

단위가 작을수록 사용자 정밀도는 올라가지만, 수천만 wk_에서 **운영·검색·franchise**가 붕괴한다.

---

## 2. 결정 (초안)

### 2.1 3계층 모델

```
Franchise (IP)     … 원피스
  └─ Work (매체 에디션) … 원피스 만화 / 원피스 TV 애니 / 극장판 Work
       └─ extensions (비-Work) … 시즌 · 권 · 아크 · 에피소드 메타
            └─ User Vault (Tier 2) … 시청·독서 진행 (몇 화·몇 권)
```

### 2.2 계층별 정의

| 계층 | Registry 엔티티 | 원피스 예 | Work 생성? |
|------|-----------------|-----------|------------|
| **IP 전체** | **Franchise** | `franchise_one_piece` | — |
| **매체별 연속 시리즈** | **Work** | 만화 연재본 · TV 애니 시리즈 | **예** |
| **시즌 / 쿨 / 파트** | `extensions.seasons[]` | 애니 1기·2기 (동일 TV Work) | **아니오** (기본) |
| **극장판 · TV특별 · 스핀오프** | **Work** (별도) | Film: Red | **예** |
| **리메이크·완전판** | **Work** (별도) | — (타 IP) FMA vs Brotherhood | **예** |
| **권 (tankōbon)** | `extensions.volumes[]` | 제 1권 … 제 110권 | **아니오** |
| **에피소드 / 챕터** | **Registry 밖** | 1071화 | **아니오** |

### 2.3 질문별 답

| 질문 | 답 |
|------|-----|
| 원피스 **전체**는? | **Franchise** (IP). Work 아님. |
| 원피스 **애니**는? | **Work** 1개 (`category: animation`) — TV 시리즈 통합본. 시즌은 extensions. |
| 원피스 **에피소드**는? | **Work 아님.** 볼트 진행·노트로 표현. |

**만화**도 동일: 연재본 전체 = **1 Work** (연재 중·완결). 권 = extensions.

### 2.4 시즌을 별도 Work로 쪼개는 경우 (예외)

기본은 **거부**. 다음만 human review 후 별도 Work:

| 조건 | 예 |
|------|-----|
| 제작진·캐스트·브랜드가 명확히 다른 리부트 | 네토플릭스 Castlevania 시즌군 vs 게임 IP |
| 공식적으로 **별도 작품명**을 쓰는 완결 시리즈 | — (드문 케이스) |

「애니 2기」만으로 별도 wk_ **생성 금지** — [canonicalization-policy](../canonicalization-policy.md) 시즌 규칙과 동일.

### 2.5 extensions 스키마 (제안)

```json
{
  "workId": "wk_…",
  "category": "animation",
  "title": "원피스 (TV 애니메이션)",
  "extensions": {
    "seriesKind": "tv",
    "seasons": [
      { "season": 1, "label": "East Blue", "episodeCount": 61, "firstAired": "1999-10-20" },
      { "season": 2, "label": "Entering into the Grand Line", "episodeCount": 16 }
    ],
    "totalEpisodes": 1100
  }
}
```

```json
{
  "category": "manga",
  "extensions": {
    "seriesKind": "serial",
    "volumes": 110,
    "serializationStatus": "serializing"
  }
}
```

---

## 3. 규모 가설

| 단위 | 글로벌 추정 | wk_로 두면 |
|------|-------------|------------|
| IP (Franchise) | ~500k–2M | 관리 가능 (분할 파일) |
| 매체 Work | ~10M–30M | **목표 상한 밴드** |
| 에피소드 | ~500M+ | **불가** |

**전제:** 에피소드·챕터를 Work로 올리지 않으면, 시리즈 작품도 **수천만 Work** 밴드 안에 일관 등록 가능.

---

## 4. 사용자 아카이브와의 관계

| Registry (Tier 1) | 볼트 (Tier 2) |
|-------------------|---------------|
| 「원피스 TV 애니」Work 1개 | 「1071화까지 봄」·「워노스미 끝」 |
| 에피소드 ID 없음 | YAML `progress: { episode: 1071 }` (향후) |

사용자 정밀도는 **Registry가 아니라 볼트**가 담당한다.

---

## 5. URV 검증 시나리오 (ADR-003)

| id | 시나리오 | 기대 | 축 |
|----|----------|------|-----|
| URV-SU01 | 원피스 만화+애니+극장판 | Franchise 1 · Work ≥3 | Franchise |
| URV-SU02 | TV 애니 시즌 1·2기 | **Work 1** · seasons[] 2 | granularity |
| URV-SU03 | 에피소드 1071 wk_ 생성 시도 | linter **거부** | scale |
| URV-SU04 | 귀멸 무한열차 | 별도 Work · 동일 Franchise | spinoff |
| URV-SU05 | FMA vs Brotherhood | Work 2 · Franchise 공유 여부 **정책 선택** (O1) | edition |
| URV-SU06 | 장편 드라마 시즌 1·2 (동일 제목) | Work 1 · seasons[] (기본) | drama |
| URV-SU07 | synthetic 10M — 에피소드 없이 시리즈 Work만 | search_index 크기 · recall 유지 | scale |

---

## 6. 미결정

| # | 항목 |
|---|------|
| O1 | FMA/Brotherhood — 공유 Franchise vs 분리 |
| O2 | 웹소설 **회차** 단위 — book Work 1개 + extensions.chapters? |
| O3 | `extensions` formal schema 버전 |

---

## 7. 대안 기각

| 대안 | 기각 이유 |
|------|-----------|
| 에피소드 = Work | 5억+ wk_ · IP 1카드 무의미 |
| IP 전체 = Work 1개 | 매체·극장판·리메이크 구분 불가 |
| 시즌마다 wk_ | 귀멸·원피스형 장기작 폭발 · franchise 의미 퇴색 |
