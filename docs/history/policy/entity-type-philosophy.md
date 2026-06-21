# Entity Type 설계 철학 — 「분류」보다 「의미」

> **지위:** Entity Type 세분화·신규 Type 추가 판단의 **철학 SSOT**  
> **갱신:** 2026-06-19  
> **상위:** [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) · [ADR-011](../adr/ADR-011-entity-type-subtype.md)  
> **관련:** [entity-record-storage-masterplan.md](../programs/entity-record-storage-masterplan.md)

---

## 1. 한 줄

**AKASHA는 생물학 백과사전이 아니라 개인 아카이브다.**  
세계를 완벽하게 분류하는 것이 목적이 아니라, **사용자가 의미를 느끼는 대상을 기록하고 연결**하는 것이 목적이다.

---

## 2. 핵심 원칙

| # | 원칙 |
|---|------|
| P1 | **과도한 세분화 금지** — Type을 늘리면 사용자·개발 모두 부담 |
| P2 | **「왜 기록하는가?」가 Type보다 우선** — 호랑이를 어디 넣을지보다 기록 동기 |
| P3 | **재사용 가능한 개념 vs 개별 존재** — 종·상징·문화적 개념은 Concept, 특정 개체는 Person |
| P4 | **Work subtype ≠ Entity Type** — manga/anime는 Work 하위, 최상위 분류 아님 |
| P5 | **Note·일기는 Entity가 아님** — Record (`timelineEntry` / `freeformJournal`) |

---

## 3. 장기 Entity Type (목표 집합)

아래 **7종 (+ Custom)** 이면 충분하다.

| Type | 역할 | 예 |
|------|------|-----|
| **Work** | 작품·콘텐츠 | 정글북, 리제로 |
| **Person** | 실존·가상 **개별** 존재 | 쉬어 칸, 파트라슈, 키우는 고양이 「나비」 |
| **Event** | 사건·행사 | ○○ 전쟁, 콘서트 |
| **Place** | 장소 | 서울, 단골 카페 |
| **Concept** | 종·상징·추상 개념 (개별 존재 아님) | Tiger, 호랑이 상징성, 상대성이론 |
| **Organization** | 단체·브랜드 | 스튜디오, 기업 |
| **Custom** | 사용자 정의 세계관·그룹 | 내 TRPG 설정 |

### 3.1 의도적으로 두지 **않을** Type

| 후보 | 판단 | 대신 |
|------|------|------|
| **Animal** (동물 종) | ❌ 별도 Type 불필요 | **Concept** — Tiger, Wolf, Cat |
| **Species** | ❌ 백과사전 지향 | **Concept** |
| **Media / Genre** | ❌ | **Work subtype** (`manga`, `game` …) |
| **Note** | ❌ Entity 아님 | **RecordKind** |

> **Animal Entity**는 장기적으로도 「호랑이」 종 자체를 위해 만들지 않는다.  
> **특정 개체** (예: 시베리아 호랑이 「아무개」)만 Person으로 두는 것이 자연스럽다.  
> (미래에 Animal Type을 검토할 여지는 「개별 동물 개체」 edge case 한정 — **현재 계획 없음**.)

### 3.2 ADR-011 `phenomenon`과의 관계

[ADR-011](../adr/ADR-011-entity-type-subtype.md)에 `phenomenon`이 ADR-008 호환으로 남아 있다.  
본 철학의 **7종 목표 집합에는 포함하지 않는다.** 신규 Fact 발급·UI 표면은 **7종 + Custom 우선** — phenomenon은 legacy·예외 처리만.

---

## 4. 판단 기준 — 「어디에 넣을까?」

Type을 고를 때 **분류학이 아니라 기록 동기**를 본다.

### 4.1 Concept vs Person

| 대상 | Type | 이유 |
|------|------|------|
| **Tiger** (호랑이 — 종·개념) | **Concept** | 개별 존재 아님 · 여러 Work·Record에서 재사용 |
| **동양 문화의 호랑이 상징** | **Concept** | 추상·문화적 의미 |
| **내가 키우는 고양이 「나비」** | **Person** | 특정 개체 · 내와의 관계 |
| **리제로의 파트라슈** | **Person** | 가상이지만 **개별** 캐릭터 |
| **시베리아 호랕이 「아무개」** | **Person** | 특정 개체 (Animal Type ❌) |

### 4.2 Work vs Concept

| 대상 | Type |
|------|------|
| 정글북 (작품) | **Work** |
| 「호랑이가 나오는 작품을 좋아한다」 | **Record** (Entity optional — Concept Tiger에 link 가능) |

### 4.3 케이스별 정리

| 케이스 | 기록 동기 | Entity | Record |
|--------|-----------|--------|--------|
| **1** | 호랑이라는 **동물 자체**에 관심 | **Concept** · Tiger | 「호랑이 작품들을 좋아한다」 등 |
| **2** | **키우는 고양이** 나비 | **Person** · 나비 | 감상·일기·사진 메모 |
| **3** | **리제로** 파트라슈 | **Person** (가상) | 캐릭터 감상 |
| **4** | **동양 문화** 호랑이 상징 | **Concept** | 에세이·타임라인 |

---

## 5. 예시 그래프 — 호랑이

```
Concept
└─ Tiger                    ← 종·개념 (Animal Type ❌)

Record
└─ 「호랑이가 등장하는 작품들을 좋아한다」   ← Record (Entity link optional)

Work
└─ 정글북

Person
└─ 쉬어 칸                   ← 작품 속 특정 호랕이 (개별 캐릭터)

Person (또는 미래 edge case)
└─ 시베리아 호랑이 「아무개」  ← 현실 특정 개체 — Person 권장
```

**용 · 호랑이 · 늑대 · 고양이** (종 수준) → 전부 **Concept** 후보.  
**어디에 넣을지**보다 **왜 기록하는지**가 중요하다.

---

## 6. Product · Engineering 함의

| 영역 | 함의 |
|------|------|
| **신규 Entity Type 추가** | 본 문서 P1~P3 **통과** + ADR amend 필수 |
| **Work subtype 확장** | manga/game 등 — Entity Type 증가 **아님** |
| **Fusion / Browse** | Type 7종 필터로 수렴 (Wave 4+) |
| **Tier 1.5 catalog** | `entityType` — Wave 1 `work` only → Wave 4+ 7종 |
| **Connection (Phase 5)** | Concept ↔ Work ↔ Person **관계**가 분류보다 가치 |

### 6.1 검증 질문 (PR · ADR)

1. 이 Type이 **백과사전 완전성**을 위한 것인가? → **거절**
2. 기존 7종 + Custom으로 **표현 불가**한가?
3. 사용자 **「왜 기록하는가」** 에 닿는가?
4. Record-only (Journal First)로 **충분하지 않은가?**

---

## 7. Phase 로드맵 정렬

| Phase | Entity scope | 본 철학 |
|:-----:|--------------|---------|
| 0~1 | Work | subtype = MediaCategory |
| 3~4 | Person · Event · Concept · … | **7종** 순차 — Animal ❌ |
| 5 | Connection | Concept–Work–Person **링크**가 핵심 UX |

상세 저장·ID: [entity-record-storage-masterplan.md](../programs/entity-record-storage-masterplan.md)

---

## 8. 원문 (2026-06-19)

<details>
<summary>대화 원문 요약</summary>

- AKASHA ≠ 생물학 백과사전 · 과세분화 지양
- Tiger (종/개념) → Concept · 특정 호랕이 개체 → Person
- 기록 동기 4케이스 (관심 / 반려동물 / 가상 캐릭터 / 문화 상징)
- 장기 Type: Work, Person, Event, Place, Concept, Organization, Custom
- Animal Type을 「호랕이」 위해 만들지 않음 — 의미·연결이 목적

</details>

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Entity Type 설계 철학 (대화 원문 정리) |
