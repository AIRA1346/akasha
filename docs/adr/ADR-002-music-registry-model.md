# ADR-002: 음악 Registry 모델 (곡 · 앨범 · 디스코그래피)

| 항목 | 내용 |
|------|------|
| **상태** | **초안 — A/B 대안 검토 중** (URV-A 전 결정 필요) |
| **범위** | 음악 매체 — [Universal Works Registry](../universal-registry-validation.md#22-포함-in-scope) |
| **선행** | [ADR-001](ADR-001-dual-layer-entity-model.md) · [ADR-005](ADR-005-minimum-recordable-unit.md) §5 |
| **승인 대기** | Minimum Work Unit — **A안 vs B안** (리뷰: **B안 가중**) |

---

## 1. 문제

음악은 계층이 세다.

| 사용자가 말하는 것 | 예 |
|-------------------|-----|
| 곡 | 「Bohemian Rhapsody」「Imagine」「Yesterday」 |
| 앨범 | 「A Night at the Opera」 |
| 아티스트 전체 | 「Queen 디스코그래피」 |

**제품 관점:** AKASHA는 **작품 기록 시스템**. 음악에서 사용자가 실제로 기록하는 단위는 **곡**인 경우가 많다.  
**규모 관점:** 전 세계 **곡**을 각각 `wk_`로 두면 Registry·검색·dedupe 부담이 급증한다.

**질문:** 개별 곡 · 앨범 · 아티스트 디스코그래피 — 각각 Work인가 Franchise인가?

→ [ADR-005 §5](ADR-005-minimum-recordable-unit.md#5-음악--adr-002-a안-vs-b안-미결)와 연동.

---

## 2. 공통 (A·B 공통)

### 2.1 Franchise — 음악

| Franchise 유형 | `franchiseType` (제안) | members (A안) | members (B안) |
|----------------|------------------------|---------------|---------------|
| **아티스트 디스코그래피** | `musical_act` | 앨범·싱글 Work | **곡 Work** (+ Container 앨범 선택) |
| **크로스미디어 IP** | (기존 IP) | movie + OST 앨범 | movie + **곡 Works** + OST Container |

- 그리드: 아티스트 Franchise **1카드** (IP 1카드 패턴)
- `primaryWorkId` = 대표 곡 또는 대표 앨범 (큐레이션 · 안에 따라 다름)

### 2.2 아티스트 디스코그래피

| 질문 | A안 | B안 |
|------|-----|-----|
| 디스코그래피는? | **Franchise** | **Franchise** (동일) |

---

## 2A. A안: 앨범 = Work (현재 초안)

> **Minimum Work Unit = 릴리스(앨범·EP·싱글)**  
> 곡은 기본적으로 Work가 **아님**.

### 2A.1 요약

| 대상 | Registry 엔티티 |
|------|-----------------|
| **앨범 / EP / 싱글 릴리스** | **Work** |
| **개별 곡** | Work **아님** — `extensions.tracks[]` |
| **문화적으로 독립 싱글** | Work **예외** (human) |
| **아티스트** | **Franchise** |

### 2A.2 스키마 (앨범 Work)

```json
{
  "workId": "wk_…",
  "category": "music",
  "extensions": {
    "workKind": "release",
    "tracks": [
      { "disc": 1, "track": 1, "title": "Bohemian Rhapsody", "durationSec": 355 }
    ]
  }
}
```

- 트랙명은 `searchTokens`에 포함 → 「Bohemian Rhapsody」검색 시 **앨범 Work** hit
- 사용자 곡 기록: 앨범 Work 아카이브 + 볼트 `highlightTrack` (Registry 수 불증)

### 2A.3 장점 · 단점

| 장점 | 단점 |
|------|------|
| Work 수 ~5M–15M (릴리스 규모) | 「이 곡만」아카이브가 **간접** |
| MusicBrainz Release와 정합 | 독립 곡 정체성(Bohemian Rhapsody)이 **앨범에 종속** |
| search_index 부담 상대적 낮음 | 장기 추천·통계가 **곡 단위**로 어려움 |
| 파이프라인 bulk 현실적 | 사용자 기록 UX와 **어긋날 수 있음** |

### 2A.4 규모 가설

| 시나리오 | Work 수 | 평가 |
|----------|---------|------|
| 전 트랙 wk_ | ~1억+ | B안으로 이동 시 논의 대상 |
| 릴리스만 | ~5M–15M | **A안 목표 밴드** |

---

## 2B. B안: 곡 = Work, 앨범 = Container Work (대안)

> **Minimum Work Unit = 곡 (Recording / Composition 단위)**  
> 앨범은 **Container Work** — 수록·발매 맥락용, 감상 기록의 1차 대상은 **곡 Work**.

### 2B.1 요약

| 대상 | Registry 엔티티 | `workKind` (제안) |
|------|-----------------|-------------------|
| **개별 곡** | **Work** | `recording` (또는 `composition`) |
| **앨범 / EP / 싱글 릴리스** | **Container Work** | `container` |
| **아티스트** | **Franchise** | — |

**Container Work 정의**

- `wk_`를 가지지만 **「들었다」의 1차 기록 단위는 아님** (권장 UX: 곡 Work 아카이브)
- **역할:** 발매일·레이블·커버·수록 순서·플랫폼 ID · 곡 Work ID 목록
- Franchise **아님** — 앨범은 IP가 아니라 **곡들의 릴리스 묶음**

### 2B.2 스키마

**곡 Work**

```json
{
  "workId": "wk_…",
  "category": "music",
  "title": "Bohemian Rhapsody",
  "titles": { "en": "Bohemian Rhapsody" },
  "extensions": {
    "workKind": "recording",
    "primaryArtists": ["Queen"],
    "durationSec": 355,
    "iswc": "T-…"
  },
  "relations": {
    "appearsOn": ["wk_…_album_container"]
  }
}
```

**앨범 Container Work**

```json
{
  "workId": "wk_…",
  "category": "music",
  "title": "A Night at the Opera",
  "extensions": {
    "workKind": "container",
    "containerType": "album",
    "memberWorkIds": ["wk_…_bohemian", "wk_…_love"],
    "releaseDate": "1975-11-21"
  }
}
```

### 2B.3 B안 설계 규칙

| 규칙 | 내용 |
|------|------|
| **1곡 1정체성** | 동일 **녹음/곡**은 survivor Work 1 — 여러 앨범 수록 시 `appearsOn` 다중 |
| **라이브 vs 스튜디오** | 다른 Recording이면 **별도 곡 Work** (O4 — human/ISRC) |
| **컴필레이션** | Container Work · 멤버는 기존 곡 Work 참조 |
| **그리드** | 아티스트 Franchise 1카드 · 칩 = **대표 곡** 또는 앨범 Container (UX 결정) |
| **볼트** | 사용자 아카이브 **기본 = 곡 Work** |
| **검색** | 「Bohemian Rhapsody」→ **곡 Work 직접** hit (SW1 이점) |

### 2B.4 장점 · 단점

| 장점 | 단점 |
|------|------|
| **작품 기록** UX와 정합 | Work 수 ~30M–100M+ |
| Bohemian Rhapsody 등 **독립 정체성** | dedupe·동명곡·커버 버전 복잡 |
| 곡 단위 추천·통계·SW1 recall | search_index · Git · parse 부담 ↑ |
| 앨범 맥락은 Container로 유지 | Container vs Franchise 이중 구조 학습 비용 |
| | 전곡 bulk ingest **비현실** — tier 정책 필수 |

### 2B.5 규모 완화 (B안 채택 시 전제)

| 정책 | 내용 |
|------|------|
| **Tier 0** | 문화적으로 유명한 곡·차트·OST 대표곡 우선 |
| **Tier 1** | 아티스트 디스코그래피 전곡 (Franchise 단위 확장) |
| **Tier 2** | 롱테일 — Contribution·사용자 요청 |
| **상한** | 일일 Pipeline 신규 곡 Work · dedupe 큐 (ADR 별도) |

**전제:** tier 없이 전곡 Work는 **일관 등록 가능하나 운영 불가** — B안은 **점진 커버리지**를 전제로 한다.

---

## 3. A안 vs B안 비교

| 기준 | A안: 앨범 = Work | B안: 곡 = Work |
|------|------------------|----------------|
| **Minimum 기록 단위** | 앨범 (곡은 볼트 보조) | **곡** |
| **AKASHA 기록 정합** | 중 | **상** |
| **독립 곡 정체성** | 약 (토큰/예외) | **강** |
| **Work 규모** | ~5M–15M | ~30M–100M+ |
| **search_index** | 유리 | 부담 (인프라 게이트) |
| **SW1 recall (곡명)** | 앨범 경유 | **직접** |
| **파이프라인** | 릴리스 메타 1건 = 1 Work | 곡 단위 + Container 조립 |
| **MusicBrainz 정합** | Release 중심 | Recording/Work 중심 |
| **Franchise** | 앨범 members | 곡 members |

---

## 4. URV 검증 시나리오

### 4.1 공통

| id | 시나리오 | A안 | B안 |
|----|----------|-----|-----|
| URV-M03 | Queen 디스코그래피 | Franchise · 앨범 Works | Franchise · **곡** Works |
| URV-M04 | Frozen 영화 + OST | movie + OST 앨범 | movie + 곡들 + OST Container |

### 4.2 A안 전용

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-M01 | 스튜디오 앨범 1개 | Work 1 · tracks[] |
| URV-M02 | 트랙 각각 wk_ | linter **거부** |
| URV-M06 | 「Bohemian Rhapsody」검색 | **앨범** Work hit |
| URV-M07 | synthetic 5M 릴리스 | scale 측정 |

### 4.3 B안 전용

| id | 시나리오 | 기대 |
|----|----------|------|
| URV-MB01 | Bohemian Rhapsody | **곡 Work** 1 · recording |
| URV-MB02 | 동곡 2앨범 수록 | 곡 Work 1 · `appearsOn` 2 Container |
| URV-MB03 | 앨범만 등록·곡 없음 | Container만 — **곡 orphan linter** |
| URV-MB04 | 「Imagine」검색 | **곡 Work** 직접 hit (SW1) |
| URV-MB05 | 스튜디오 vs 라이브 동곡 | Work 2 (recording 구분) |
| URV-MB06 | synthetic 30M 곡 Work | search_index · tier 정책 검증 |
| URV-MB07 | 사용자 곡 아카이브 | 볼트 `wk_` = **곡** · Container 불필요 |

### 4.4 A/B 교차 (결정용)

| id | 질문 | A안 결과 | B안 결과 | 가중 |
|----|------|----------|----------|------|
| URV-MX01 | 「작품 기록 최소 단위 = 곡」정합 | △ | ✅ | 제품 |
| URV-MX02 | 30M Work search_index | ✅ | ⚠️ | 인프라 |
| URV-MX03 | 동명곡 다른 아티스트 | 단순 | dedupe 필수 | Registry |
| URV-MX04 | 앨범 전체 감상 기록 | ✅ 직접 | Container 또는 곡 N개 | UX |

**URV-A 권장:** A·B **동일 스위트** subset으로 baseline 비교 후 ADR-002 **단일안 승인** 또는 **B안 + tier 조건부 승인**.

---

## 5. 결정 (미정)

| 안 | 상태 | 한 줄 |
|----|------|-------|
| **A안** | 초안 | 규모·인프라 우선 · 앨범 = Work |
| **B안** | **대안 초안** | **기록·정체성 우선 · 곡 = Work · 앨범 = Container** |

**권장 다음 단계**

1. [ADR-005](ADR-005-minimum-recordable-unit.md) §4 표에서 음악 행 확정  
2. URV-M / URV-MB / URV-MX 시나리오 **402 또는 synthetic** 비교  
3. B안 선택 시 — SW1 곡명 쿼리 · search_index 30M **인프라 게이트** 병행

---

## 6. 미결정

| # | 항목 | 영향 |
|---|------|------|
| O1 | `category: music` + `workKind` enum | A·B 공통 |
| O2 | B안: composition vs recording Work 쪼개기 | dedupe |
| O3 | Container Work를 그리드에 노출할지 | UX |
| O4 | 동일 곡 라이브/스튜디오 — 1 vs N Work | B안 |
| O5 | B안 tier·롱테일 상한 | 운영 |

---

## 7. 폐기·보류

| 항목 | 처리 |
|------|------|
| 음악 Registry 제외 | **폐기** |
| 아티스트 = 단일 Work | **폐기** — Franchise 유지 |
| A·B **동시 운영** (이중 minimum unit) | **금지** — 매체당 하나의 Minimum Work Unit만 |
