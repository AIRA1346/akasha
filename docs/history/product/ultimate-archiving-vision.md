# 궁극적 아카이빙 비전 (Ultimate Archiving Vision)

> **Status:** Historical snapshot
>
> 이 문서는 이전 단계에서 작성된 장기 비전 기록이다.
> 현재 권위 있는 제품 비전은 [VISION.md](../../active/VISION.md)다.
> 과거 연구·설계 맥락 보존을 위해 본문은 historical snapshot으로 유지한다.

> **지위 (당시):** AKASHA **제품·아카이빙 북극성 SSOT** — Fact 사전·카탈로그 확장·Memory Core와 **분리**
> **갱신:** 2026-06-14
> **상위 (당시):** `product-vision.md` (현재 저장소에 파일 없음 · 현행 후계 문서: [VISION.md](../../active/VISION.md))
> **인프라·규모 (historical):** [data-architecture-redesign.md](../strategy/data-architecture-redesign.md) · **레이어:** [ADR-007](../adr/ADR-007-app-layering.md)

---

## 1. 한 줄

**개인의 궁극의 아카이빙 시스템 — 나를 구성하는 모든 것(작품·인물·사건·개념·생각·일기·가치관…)을 장기적으로 축적하고, 연결하고, 재활용·확장한다.**

AKASHA는 **회상 앱** · **Memory DB 제품** · **작품 감상 트래커** · **제2의 Obsidian**이 **아니다**.  
**현재 Steam v1 구현 범위 = 작품** — 목표가 아니라 **가장 구조화하기 쉬운 시작점**이다.

---

## 2. AKASHA가 아닌 것 / AKASHA인 것

| ❌ 축소 해석 | ✅ 본질 |
|-------------|---------|
| 인생 **회상** 시스템 (과거를 다시 보는 것만) | **궁극의 아카이빙** — 축적·연결·재활용·확장 |
| **Memory Database** (기록 영구 보존만) | Core는 **수단** · 제품은 **존재 전체의 아카이브** |
| **작품 감상 앱** | 작품 = **Phase 1** · 최종엔 일기·아이디어·가치관까지 |
| **지식 그래프 연구** | 연결은 **통찰·재활용**을 위한 — 그래프 자체가 목표 아님 |

**제품이 만드는 감정:** 「10년 뒤 눈물」 같은 **회상 연출**이 목표가 아니다.  
**「10년 동안 쌓인 모든 기록을 잃지 않고, 서로 이어 새 의미를 만들 수 있는가?」** 가 핵심 질문이다.

---

## 3. 성장 흐름 (북극성)

```
아카이빙 → 축적 → 연결 → 재활용 → 확장
```

| 단계 | 의미 | 예 |
|------|------|-----|
| **아카이빙** | 의미 있는 것을 **남김** | 프리렌 감상 · 창작 메모 · 번아웃 일기 |
| **축적** | 시간에 따라 **쌓임** | 2026~2036 기록이 깨지지 않고 존재 |
| **연결** | Entity ↔ Timeline ↔ Journal **링크** | 「그날 일기」↔「프리렌 재감상」 |
| **재활용** | 과거 기록이 **새 맥락**에서 쓰임 | 슬럼프 때 반복 등장한 작품 = 정서적 닻 |
| **확장** | 새 유형·AI·에이전트가 **같은 틀**에 흡수 | 「이 장면 멋졌어」→ 자동 아카이빙 |

---

## 4. 무엇을 보존하는가

최종적으로 담을 **존재의 구성 요소** (현재 v1은 **굵은 글**만):

| 영역 | Entity Type | 예 | v1 |
|------|-------------|-----|:--:|
| **작품** | `work` | 프리렌 · 바이올렛 · 엘든링 | **✅** |
| **인물** | `person` | 성우 · 작가 · 뉴턴 | 📋 |
| **사건** | `event` | 2차대전 · 삼일절 | 📋 |
| **장소** | `place` | 서울 · 도쿄 | 📋 |
| **개념·현상** | `concept` · `phenomenon` | 진화론 · 블랙홀 · 상대성이론 | 📋 |
| **조직** | `organization` | 기업 · 브랜드 · 팀 | 📋 |
| **일기·생각·아이디어** | *(Record)* `timelineEntry` | 「문득 AI와 인간은…」 | 🔶 |
| **가치관·창작·취향** | `custom` · *(Record)* | 기획 메모 · 세계관 · 큐레이션 | 📋 |

Entity Type SSOT: [ADR-011](../adr/ADR-011-entity-type-subtype.md)

**보존 대상 = 「나」 전체.** 작품은 그중 **첫 레이어**일 뿐이다.

---

## 5. 두 축 — Entity Archive + Timeline Archive

최종 구조는 **단일 축이 아니다.**

### 축 1 — Entity Archive (객체 기반)

```
[글로벌/로컬 Entity]     entity_id + type (wk_… · person · event · concept …)
        │
        │  아카이브 (희소 — 기록할 때만)
        ▼
[Entity Journal]         Sanctum vault/*.md · YAML + Markdown
        · 감상 · 장면 · 메모 · 창작 · [[위키링크]]
```

- **지금:** `work_id` (`wk_…`) + Tier 1 Fact 사전  
- **이후:** `type`만 늘려 인물·사건·개념·현상 동일 패턴

### 축 2 — Timeline Archive (시간 기반)

```
[Timeline Entry]         날짜·시간 축
        · 일기 · 생각 · 아이디어 · 일상
        · entity_id로 분류하기 **어려운** 기록
```

- **Journal First:** Entity 없는 기록도 **1급 시민** (예: 「오늘 너무 힘들었다」)  
- 나중에 **소급 연결** 가능: 「그날 밤 프리렌을 봤다」→ `wk_…` 링크

### 연결 (양축의 핵심)

```
timeline_entry: "2026-05-01 — 허무함. 밤에 프리렌 다시 봤다."
        ↕
entity_journal: wk_frieren — 감상·별점·장면 메모
```

연결되면 AI·사용자 모두 **「프리렌 좋아함」** 이 아니라 **「특정 시기·정서와 묶인 객체」** 로 해석할 수 있다.

---

## 6. 최소 공통 추상화 (설계 기준)

앞으로 추가될 **모든** 유형을 담을 공통 틀. (스키마 확정 전 **검증 질문**)

| 개념 | 역할 |
|------|------|
| **Record** | 사용자가 **소유·축적**하는 최소 단위 (Journal entry · Timeline entry) |
| **Entity Anchor** | Record에 **선택적으로** 붙는 닻 (`entity_id` + `type`) |
| **Time Anchor** | Record에 **선택적으로** 붙는 시점 |
| **Link** | Record ↔ Entity · Record ↔ Record (`[[…]]` · 향후 그래프) |

**아키텍처 검증 질문 (출시·리팩터마다):**

> ❌ 「작품을 얼마나 잘 저장하냐?」  
> ⭕ **「이 구조가 나중에 작품이 아닌 개인의 생각까지 담을 수 있냐?」**

지금 **작품만** 구현하는 것은 OK. **작품만** 영원히 가정하는 설계는 NG.

---

## 7. Entity–Journal (Phase 1 — 현재 런타임)

v1 Steam이 **실제로 구현한** 모델. §5 축 1의 **작품(`work`) subset**.

```
[Tier 1 Entity]          work_id (wk_…) — 사전·볼트 조인 키
      │
      │  아카이브 / 직접 등록 (희소)
      ▼
[Tier 2 Journal]         Sanctum vault/*.md
      ▼
[Appreciation View]      Tier 1 + Tier 2 런타임 융합 UI — §8
```

| 규칙 | 내용 |
|------|------|
| **희소 아카이브** | 사전 N만 작 ≠ N만 `.md`. **내가 기록한 것만** |
| **Tier 2가 Tier 1을 덮지 않음** | Fact는 Fact · 감상은 감상 |
| **편집 완결** | 찾기 → 아카이브 → 기록 → 큐레이션 — **앱 안에서** |

상세: [sanctum-md-customization.md](sanctum-md-customization.md) · [workbench-layout.md](workbench-layout.md)

---

## 8. Appreciation Viewport (감상·표현 계층)

**경험 계층** — Core(Memory DB) **위**에 올라가는, 인간이 기록을 **보고·꾸미는** UI.

| 사전 (Entity) | 볼트 저널 | UI |
|:---:|:---:|---|
| ✅ | ❌ | **가상 카드** — Fact + 플레이스홀더 |
| ✅ | ✅ | **아카이브 카드** — Fact + 유저 포스터·YAML + 저널 |
| ❌ | ✅ | **커스텀 저널** — 볼트만 (Timeline 축의 전단) |

Appreciation은 **회상 연출**이 아니라 **축적된 Record를 미학적으로 다루는 계층**이다.  
(갤러리 · 서재 · 타임라인 뷰 · 앨범 — v1.1+)

---

## 9. 기술·AI의 위치 (Core vs 제품)

```
┌─────────────────────────────────────────────────────────┐
│  제품 — 궁극의 아카이빙 경험                              │
│  Sanctum · Library · Appreciation · Timeline · 연결 UI   │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│  AKASHA Core — AI-agnostic Memory substrate (장기)      │
│  Markdown SSOT · Event Store · SQLite cache · MCP …     │
└─────────────────────────────────────────────────────────┘
```

| | 역할 |
|--|------|
| **`.md` (지금)** | 사용자·AI가 읽을 수 있는 **기록 SSOT** — 「이 장면 멋졌어」만으로도 아카이빙 가능 |
| **MCP · AI (미래)** | 에이전트가 **아카이빙을 도움** · Record 연결·재활용 |
| **Event Store** | **제품 핵심 ❌** — sync·이관·기계 재구성용 **인프라 선택** |
| **AI 없음** | **여전히 가치 ✅** — 아카이브·연결·정체성은 **사용자 소유** |

**AI는** 사용자를 이해하는 **미래 수단**이면서, **사용자 스스로 정체성**을 갖게 하는 **현재·미래 경험**과 공존한다.

---

## 10. 구현 로드맵 (존재 아카이브 — 카탈로그와 별도)

| Phase | 범위 | 비고 |
|:-----:|------|------|
| **1** | **작품** Entity Archive | `work_id` · v1 Steam **현재** |
| **2** | 사용·다듬기 | 구조 검증 · Appreciation UX |
| **3** | 인물 · 사건 · 개념 · 현상 | `entity_id` + `type` 확장 |
| **4** | 일기 · 일상 · 생각 · 아이디어 | **Timeline Archive** · Entity와 **링크** |

### v1.x 릴리즈 (Phase 1~2 세부)

| 단계 | 범위 | 상태 |
|------|------|:----:|
| **v1.0** | Sanctum · `.md` · 4열 워크벤치 · 나만의 서재 · IAP 테마 | ✅ |
| **v1.0.1** | 외부 `.md` watch · Home shell 리팩터 | ✅ |
| **v1.1** | Timeline 뷰 일부 · 연결 UX · 감상 YAML · 서재 밀도 | ⏳ |
| **v1.2** | Appreciation 갤러리 · Album · `::: block` md | ⏳ |
| **장기** | Phase 3~4 · AI 아카이빙 보조 · 지식 연결 | 📋 |

**카탈로그 490→5k+** = [catalog-growth-charter.md](../programs/catalog-growth-charter.md) — **발견(Phase 1) 품질** · 궁극 아카이빙을 **대체하지 않음**.

---

## 11. v1 유저 여정 (Phase 1 범위)

```
① 발견     검색 · Fact 그리드
② 아카이브  work_id 연결 .md
③ 기록     워크벤치 4열
④ 큐레이션  나만의 서재
⑤ 연결·확장  (v1.1+) Timeline · Entity 간 링크 · Appreciation 뷰
```

**v1 Steam: ①~④.** ⑤는 Phase 2~4와 맞물림 ([ROADMAP.md §v1.1+](../../ROADMAP.md)).

---

## 12. 화면별 역할 (혼동 방지)

| 화면 | 역할 |
|------|------|
| **대시보드 서재** | Entity **탐색** · 발견 |
| **나만의 서재** | **큐레이션** · Appreciation |
| **워크벤치** | Entity Journal **기록·편집** |
| **(장기) Timeline** | Timeline Archive · **연결** 허브 |

설계: [my-library-design.md](my-library-design.md)

---

## 13. AKASHA가 하지 않는 것

- Tier 1 포스터·시놉·UGC 호스팅  
- 사전 전 작 `.md` 일괄 생성  
- AniList/TMDB **미러 DB**  
- **회상 연출만**을 위한 제품 (아카이빙·연결 없이 감동 UI만)

---

## 14. 관련 문서 맵

| 문서 | 역할 |
|------|------|
| **본 문서** | 궁극 아카이빙 **제품 SSOT (당시)** |
| `product-vision.md` (현재 저장소에 파일 없음 · 후계: [VISION.md](../../active/VISION.md)) | Tier 1/2 · **v1 Steam In/Out** |
| [product/README.md](README.md) | product/ 색인 |
| [sanctum-md-customization.md](sanctum-md-customization.md) | Phase 1 `.md` |
| [workbench-layout.md](workbench-layout.md) | 4열 워크벤치 |
| [data-architecture-redesign.md §7](../strategy/data-architecture-redesign.md) | 인프라·융합 |
| [ADR-007](../adr/ADR-007-app-layering.md) | 레이어 가드레일 |
| [catalog-growth-charter.md](../programs/catalog-growth-charter.md) | **별 트랙** — Registry |

---

## 15. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-14 | 초판 — Entity-Journal·Sanctum **단일 SSOT** |
| 2026-06-14 | **v2** — 회상 중심 → **궁극의 아카이빙** · Entity+Timeline 이축 · Phase 1~4 · Core/제품 분리 |
| 2026-06-14 | **실행 SSOT** → [phase1-work-e2e-plan.md](../programs/phase1-work-e2e-plan.md) (Phase 1 E2E · Scale 보류) |

---

## 16. 당시 실행 포커스

**당시 실행 기준:** [architecture-evolution-phases.md](../programs/architecture-evolution-phases.md)

| Phase | 내용 | 상태 |
|:-----:|------|:----:|
| 0 | 작품 E2E | ✅ |
| **1** | **Record Foundation** — [ADR-008](../adr/ADR-008-record-entity-time-model.md) | **진행** |
| 2~6 | Scale · Entity · Timeline · Link · Core | 대기 |
| M3 | Steam | ⏸️ 품질 Ready |
