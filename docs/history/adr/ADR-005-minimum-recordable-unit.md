# ADR-005: 작품의 최소 기록 단위 (매체별 Minimum Work Unit)

| 항목 | 내용 |
|------|------|
| **상태** | **초안** — §4 대부분 매체 **승인 가능** · 음악만 ADR-002 A/B 미결 |
| **범위** | Universal Works Registry 전 매체 |
| **선행** | [ADR-001](ADR-001-dual-layer-entity-model.md) 승인 · [ADR-003](ADR-003-series-minimum-unit.md) |
| **연관** | [ADR-002](ADR-002-music-registry-model.md) A/B안 — 음악만 **미결** |

---

## 1. 문제

> **「작품의 최소 기록 단위는 무엇인가?」**

AKASHA는 **작품 기록 시스템**이다. Registry Work 단위는 **사용자가 아카이브·감상 기록을 남기는 최소 문화 단위**와 정합해야 한다.

단위가 크면 — 「이 곡」「1071화」를 정확히 기록 못 함.  
단위가 작으면 — 수억 `wk_` · 검색·dedupe·franchise 붕괴.

본 ADR는 매체별 **Work** · **Registry 미만** · **볼트(Tier 2)만** · **Franchise** 를 구분한다.

---

## 2. 용어

| 용어 | 의미 |
|------|------|
| **Minimum Work Unit** | `wk_` 1개가 대표하는 최소 기록 단위 |
| **Registry 미만** | `extensions` 메타만 · 별도 `wk_` 없음 |
| **볼트만** | Tier 2 YAML·노트·진행도 — Registry 엔트리 없음 |
| **Franchise** | IP·아티스트·시리즈 세계관 — Work 묶음 (ADR-001) |
| **Container Work** | 자체 감상 단위는 아니거나 약하고, **다른 Work를 담는** 껍데기 Work (ADR-002 B안) |

---

## 3. 승인된 전제 (리뷰 반영)

| 항목 | 결정 |
|------|------|
| Dual-layer (Work + Franchise) | ✅ 승인 |
| 에피소드 · 챕터 | **Registry 밖** — 볼트 진행 |
| 동인지 · 팬게임 · 팬픽션 | 원작과 **분리** (ADR-004) |
| URV vs SW1 | **분리** 검증 |

---

## 4. 매체별 최소 기록 단위 (통합 표)

| 매체 | `category` | **Minimum Work Unit** | Registry 미만 (extensions 등) | 볼트만 (Tier 2) | Franchise | 비고 |
|------|------------|----------------------|------------------------------|-----------------|-----------|------|
| **소설 (단행본)** | `book` | **책 1권** (완결 1편) | — | 독서 메모·챕터 북마크 | 시리즈·작가 세계관 (선택) | |
| **소설 (연재·장편)** | `book` | **연재 작품 전체** 1 Work | 권 수 · 연재 상태 | 읽은 챕터·권 | 동일 | 권별 wk_ **아님** |
| **라이트노벨** | `book` | **시리즈/권 단위 정책 = 소설과 동일** | tom | 챕터 | IP Franchise | 게임·애니 파생은 별도 Work |
| **만화** | `manga` | **연재본 전체** 1 Work | `volumes` · 연재 상태 | 읽은 권·화 | IP Franchise | [ADR-003](ADR-003-series-minimum-unit.md) |
| **웹툰** | `webtoon` | **시리즈 전체** 1 Work | 연재 상태 · 플랫폼 | 읽은 회차 | IP (선택) | 회차 wk_ **아님** |
| **TV 애니** | `animation` | **TV 시리즈 1 Work** (통합본) | `seasons[]` · 총 화수 | 시청 화수·아크 | IP Franchise | 에피소드 wk_ **아님** ✅ |
| **애니 극장판** | `animation` | **극장판 1편** 1 Work | — | — | IP Franchise 멤버 | 본편 TV와 **별도** Work |
| **영화** | `movie` | **영화 1편** 1 Work | — | — | 시리즈·우주 (선택) | |
| **드라마 (시리즈)** | `drama` | **시리즈 1 Work** | `seasons[]` | 시청 화수 | IP (선택) | 애니와 동일 원칙 |
| **드라마 (스페셜/단편)** | `drama` | **1편** 1 Work | — | — | — | |
| **게임** | `game` | **타이틀 1개** 1 Work | DLC·시즌 패스 메타 | 플레이 시간·엔딩 | IP Franchise | 리마스터·완전판은 **별도 Work** (human) |
| **음악** | `music` | **⚠️ ADR-002 A/B** — B안(곡=Work) **가중** | — | — | 아티스트 `musical_act` | 아래 §5 |
| **동인지** | `manga`/`book` | **1편(1서큘)** 1 Work | — | — | 원작과 **분리** | ADR-004 |
| **팬게임** | `game` | **1 타이틀** 1 Work | — | — | `derivativeOf` | ADR-004 |
| **팬픽션** | `book` | **1편/1연재** 1 Work | — | — | 원작과 **분리** | Contribution 중심 |

---

## 5. 음악 — ADR-002 A안 vs B안 (미결)

| | **A안: 앨범 = Work** | **B안: 곡 = Work** |
|--|----------------------|---------------------|
| **Minimum Work Unit** | 앨범·EP·싱글 **릴리스** | **곡(Recording/Composition)** |
| **앨범 역할** | Work 본체 | **Container Work** (수록곡 묶음) |
| **사용자 기록** | 앨범 아카이브 + 볼트에 곡명 | **곡 Work** 직접 아카이브 |
| **Bohemian Rhapsody** | 앨범 Work 토큰으로 검색 | **곡 Work** 1개 |
| **규모 (가설)** | ~5M–15M Work | ~30M–100M+ Work |
| **SW1** | 트랙명 → 앨범 hit | 곡명 **직접** hit |
| **상세** | [ADR-002 §2A](ADR-002-music-registry-model.md#a안-앨범--work-현재-초안) | [ADR-002 §2B](ADR-002-music-registry-model.md#b안-곡--work-앨범--container-work-대안) |

**URV-A 전 결정 필요:** 음악 행만 표에서 미결로 남김 — 나머지 매체는 본 ADR + ADR-003으로 **일관 전제 확정**.

---

## 6. 원칙 (매체 공통)

### 6.1 Work를 쪼개지 않는 것 (승인)

- 애니·드라마 **에피소드**
- 만화·웹툰·소설 **챕터·개별 회차**
- 앨범 **수록 순서 슬롯** (A안)

→ **볼트 `progress`** · 노트로 표현.

### 6.2 Work를 나누는 것 (기본)

- **매체가 다르면** 별도 Work (만화 vs 애니) — Franchise로 IP 1카드
- **극장판·스핀오프·리메이크** — 별도 Work (human 판단)
- **게임 리마스터/완전판** — 별도 Work 검토

### 6.3 Franchise와 Work 경계

| Franchise | Work |
|-----------|------|
| IP·아티스트·시리즈 **세계** | 사용자가 「봤다/들었다/했다」고 말하는 **구체 단위** |
| 그리드 1카드 | 볼트·검색·Contribution의 기본 타겟 |

---

## 7. 규모 일관성 (수천만)

| 매체 | Work 단위 유지 시 추정 | 일관 등록 |
|------|------------------------|-----------|
| 책·만화·애니 (시리즈형) | ~10M–20M | ✅ ADR-003 |
| 영화·극장판 | ~2M–5M | ✅ |
| 게임 | ~3M–8M | ✅ |
| 음악 A안 | ~5M–15M | ✅ |
| 음악 B안 | ~30M–100M | ⚠️ **파이프라인 tier·인기곡 우선** 전제 필요 |

**전제:** 에피소드·챕터를 Work로 올리지 않는 한, 음악을 제외한 매체는 **~30M Work** 밴드 안에서 Dual-layer 유지 가능.

---

## 8. URV 검증 시나리오 (ADR-005)

| id | 매체 | 시나리오 | 기대 |
|----|------|----------|------|
| URV-U01 | book | 해리포터 1권 | Work 1 (단권) |
| URV-U02 | book | 장편 연재 소설 | Work 1 · 챕터 wk_ **거부** |
| URV-U03 | manga | 원피스 연재 | Work 1 · 권=extensions |
| URV-U04 | animation | 원피스 TV | Work 1 · 1071화 wk_ **거부** |
| URV-U05 | animation | 극장판 Red | Work 1 (별도) |
| URV-U06 | movie | 인셉션 | Work 1 |
| URV-U07 | game | Elden Ring | Work 1 |
| URV-U08 | game | DLC Only | extensions 또는 별도 Work — **O1** |
| URV-U09 | music | Bohemian Rhapsody | A: 앨범 hit / B: **곡 Work** hit |
| URV-U10 | cross | 볼트 progress만 | Registry Work 수 **불변** |

---

## 9. 미결정

| # | 항목 | ADR |
|---|------|-----|
| O1 | 게임 DLC·시즌 패스 — 별도 Work vs extensions | 005 |
| O2 | 단행본 **시리즈** — 권마다 Work vs 시리즈 1 Work | 005 |
| O3 | 음악 A vs B | **002** |
| O4 | 동일 곡 **다른 녹음 버전** (라이브 vs 스튜디오) — B안에서 Work 1 vs N | 002 B |

---

## 10. URV-A 선행 체크리스트

- [x] Dual-layer
- [x] 에피소드/챕터 Registry 밖
- [x] 2차 창작 분리
- [x] 매체별 Minimum Work 표 (본 문서 §4) — **음악 제외 확정**
- [ ] **ADR-002 A vs B** (B안 가중 · 미결정)
- [ ] **ADR-006** Franchise 계층 F1 승인
- [x] ADR-003 · ADR-004 원칙 승인
