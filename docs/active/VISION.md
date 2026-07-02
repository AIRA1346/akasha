# AKASHA Product Vision

> **지위:** 제품 **최상위 SSOT** (정책·ROADMAP·스토어 카피의 북극성)
> **갱신:** 2026-06-30 — **Steam v1 = Personal Sanctum Archive**
> **Git:** code/test baseline **5526ce4** · current tip은 `git log -1` 기준
> **법무:** [history/policy/data-policy.md](../history/policy/data-policy.md)

---

## 1. 정체성 — 3층 구조

### 한 문장 (Steam v1)

> **AKASHA v1은 사용자의 감상을 Sanctum vault에 아름답게 남기고, 에이전트와 함께 기록하는 개인 아카이브 앱이다.**

장기 북극성(변하지 않음):

> **작품을 진입점으로 삼아, 인물·개념·사건까지 연결되는 개인 지식 우주(Personal Knowledge Universe)를 구축하는 시스템이다.**

---

### 층 1 — 표면: Personal Archive App (v1)

사용자가 처음 보는 모습:

- **내 vault**에 감상·평점·상태·태그·명장면·갤러리를 남김
- Personal Library · Collection으로 **내가 아카이브한 것**을 큐레이션
- (보조) starter catalog로 작품을 찾아 아카이브로 가져옴

겉모습은 Goodreads · Letterboxd와 겹치지만, **v1 핵심은 글로벌 사전이 아니라 내 기록**이다.

---

### 층 2 — 핵심: Entity Graph

작품은 사실 하나의 **진입점**이다. AKASHA의 진짜 중심은 그 안의 **인물·개념·사건**이다.

```
Re:Zero
 ├─ Subaru      (Entity: Person)
 ├─ Emilia      (Entity: Person)
 ├─ Rem         (Entity: Person)
 └─ 성장        (Entity: Concept)
```

AKASHA는 점점 이 방향으로 이동한다:

```
Work → Entity → Relationship → Collection
```

현재 구현된 것만 봐도 Hero Collection · Villain Collection · Re:Zero Cast · Fate Cast 모두  
작품 자체보다 **사람·개념·사건**을 수집하는 기능이다.

---

### 층 3 — 장기: Personal Knowledge Layer

AKASHA는 **위키를 만들려는 것이 아니다.**

위키는 "세계의 정보"를 저장한다.  
AKASHA는 **"내가 중요하다고 생각하는 세계"**를 저장한다.

```
내가 좋아하는 영웅들
  Subaru · Lelouch · Saber · Aragorn
```

이건 객관적 분류가 아니라 **사용자의 관점**이다.  
AKASHA는 Knowledge Base보다 **Curated Knowledge Space**에 가깝다.

---

## 2. AKASHA의 핵심 철학

```
작품은 소비한다.
인물은 기억한다.
개념은 연결된다.
컬렉션은 의미를 만든다.
```

그리고 AKASHA는 그 연결들을 사용자가 **스스로 구축**하게 만드는 시스템이다.

### 진화 경로

```
Work
 ↓
Entity
 ↓
Tag
 ↓
Collection
 ↓
Related Work Collection
 ↓
Mixed Library (예정)
```

이건 라이브러리 기능을 확장한 것이 아니라,  
**"작품 중심 저장소"에서 "개인 지식 그래프"로 진화하는 과정**이다.

---

## 3. AKASHA가 아닌 것

| ❌ | 이유 |
|----|------|
| 단순 독서 기록 앱 | 기능의 일부일 뿐 |
| Obsidian 대체재 | 볼트는 수단, 지식 구조화가 목적 |
| 위키 클론 | 객관적 정보가 아닌 사용자 관점 |
| 데이터베이스 관리 툴 | 데이터는 수단 |
| 미디어 소비 트래커 | 소비 기록은 진입점일 뿐 |

---

## 4. Entity · Record · Connection (+ Tier)

**북극성:** 세상에서 만난 모든 것(Entity)을 찾고, 내가 남긴 것(Record)을 축적하고, 관계(Connection)로 연결한다.  
실행 SSOT: [history/programs/entity-centric-evolution-plan.md](../history/programs/entity-centric-evolution-plan.md) · [ADR-011](../history/adr/ADR-011-entity-type-subtype.md)

| 개념 | 역할 | Phase 0 (v1) |
|------|------|:------------:|
| **Entity** | 기록 대상 (닻) — work · person · event … | `work` only |
| **Record** | Sanctum `.md` — 감상·일기·메모 | workJournal ✅ · timeline 🔶 |
| **Connection** | `[[링크]]` · Record ↔ Entity | 📋 Phase 5 |

### 데이터 Tier

| | Tier 1 — Global Fact | Tier 1.5 — User Local | Tier 2 — Sanctum Record |
|--|----------------------|------------------------|-------------------------|
| **누가** | Rune Atelier (큐레이션·CI) | **유저** (볼트 catalog) | **유저** |
| **저장** | `akasha-db` JSON (Git/CDN) | `catalog/user_entities.json` | 로컬 `.md` + YAML + `posters/` |
| **목적** | 「잘 알려진 것」 **발견** | 「내 catalog에 없던 것」 **발견** | 「나에게 무엇이었는지」 **기록** |
| **포스터·이미지** | ❌ **미제공** | ❌ | ✅ URL · 로컬 · 본문 |
| **감상·평점·상태** | ❌ | ❌ | ✅ YAML + Markdown |
| **법적 포지션** | Fact 메타만 배포 | 로컬 only | UGC · 개인 기록 |

조인 키: `entity_id` (`wk_…` · `wk_u_…` — [history/policy/user-local-catalog-policy.md](../history/policy/user-local-catalog-policy.md)).  
Tier 2는 Tier 1·1.5 Fact를 **덮어쓰지 않음**. Legacy frontmatter `work_id` = work Entity alias.

---

## 5. 유저 여정 (Steam v1)

```
볼트 연결 (또는 신규 작품 직접 추가)
    ↓
감상을 말하거나 직접 작성 — Workbench · Sanctum
    ↓
Sanctum vault .md / YAML 저장 (원자적 · watch)
    ↓
AKASHA가 예쁘게 정리 — 나만의 서재 · Collection · 갤러리
    ↓
(선택) starter catalog 검색으로 작품 발견 → 아카이브
    ↓
에이전트가 vault 읽기·편집 — [Agent Vault Protocol v1](AGENT_VAULT_PROTOCOL_V1.md)
    ↓
(장기) Entity Graph · Timeline · Connection
```

**v1에서 약화:** 「10k 글로벌 사전을 탐색하는 것」을 제품 정체성의 중심으로 두지 않음.
catalog는 **있어도 되고 없어도 되는 보조** — 직접 추가·로컬 기록이 항상 가능해야 함.

---

## 6. Tier 1 — 저장하는 Fact (텍스트)

**Minimal Core** ([history/policy/data-policy.md §1.2](../history/policy/data-policy.md#12-registry-minimal-core-필수-영구-저장)):

| 필드 | 비고 |
|------|------|
| `workId` | `wk_` 영구 ID |
| `title` / `titles.*` | 다언어 제목 |
| `category` · `domain` | taxonomy |
| `releaseYear` · `creator` | 사실 |
| `externalIds.*` | **식별 숫자만** — 이미지 fetch·attach ❌ |
| `aliases` | AKASHA 선별 |
| `tags` | (선택) 외부 장르 복붙 지양 |

**금지 (Tier 1):** `description`, `posterPath`, raw API blob, synopsis/overview, 이미지 바이너리.  
**설명·감상·시놉**은 Tier 2 Sanctum vault Markdown/YAML만.  
**CI:** `tier1_poster`, `tier1_description`, `data_policy_linter --strict`.

---

## 7. Tier 2 — Sanctum vault

### 앱이 제공 (v1)

- Sanctum vault 폴더 연동 · watch · 원자적 저장
- 작품 검색 (사전 + 볼트 + 신규) — 대시보드 서재는 **포스터 없는 Fact 카드**
- 아카이브 → `.md` 생성
- YAML front-matter 템플릿 (`poster`, `rating`, `status`, `my_status`, …)
- **워크벤치 4열:** Sanctum 페이지 **미리보기 · 본문 편집 · .md 파일 편집**
- AI YAML 붙여넣기 (신규 작품)
- 대시보드 · IP 1카드 · 나만의 서재 · 테마(IAP)

### 유저 소유 (무제한)

- **YAML:** `poster`, `rating`, `status`, 커스텀 키(보존)
- **본문 Markdown:** 감상·명대사·에피소드 메모·위키링크·이미지
- **파일:** `posters/` 로컬 이미지

앱은 파싱하는 필드를 UI에 반영하고, **본문은 점진적으로 더 풍부히 렌더** (v1.1+).

### 화면별 포스터 원칙

| 화면 | 포스터 |
|------|--------|
| **대시보드 서재** | ❌ 항상 숨김 — 작품 찾기용 Fact 카드 |
| **나만의 서재** | ✅ 유저 `.md`의 `poster:` 또는 `posters/` 표시 |
| **상세 화면** | ✅ 아카이브된 유저 항목의 포스터 표시 |

---

## 8. AKASHA가 하지 않는 것 (데이터 정책)

- Tier 1 포스터·이미지 URL 큐레이션·hotlink 배포
- 외부 DB(TMDB/AniList) **미러링** · bulk ingest
- 사전 전체 `.md` 일괄 생성
- 유저 감상·평점의 **제공자** 역할
- WebView/자동 이미지 수집 (유저 대신 포스터 찾기)

---

## 9. Steam v1 범위 (2026-06-30 재정렬)

| v1 In (핵심) | v1 Out / post-v1 |
|--------------|------------------|
| Sanctum vault 연동 · watch · 원자적 저장 | Tier 1 포스터 |
| 직접 작품 추가 · 아카이브 `.md` | 앱 이미지 큐레이션 |
| 감상·평점·상태·태그·명장면·갤러리 | Discover · recommendation |
| Workbench · Sanctum 예쁜 기록 UI | Timeline (v1.1+) |
| Personal Library · Collection | Agent-driven bulk entity operations |
| Agent Vault Protocol v1 ([AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md)) | **10k+ scale을 v1 메시지 중심으로 강조** |
| (보조) starter catalog 검색 | recall·CDN scale을 **v1 blocking**으로 두지 않음 |
| 앱 테마 · 나만의 서재 정리 | Wikidata / 외부 API **확장** |

**akasha-db:** 삭제하지 않음 — optional catalog · CI 자산 · post-v1 scale track.

**Steam Early Access:** 사용자 지시에 따라 진행. 정식 1.0/post-EA 범위는 별도 결정.

---

## 10. 장기 (철학 유지)

| 시점 | Tier 1 (akasha-db) | 제품 초점 |
|------|-------------------|----------|
| **2026 v1** | optional starter · CI 유지 | **Personal Sanctum archive** |
| 2027~ | post-v1 scale | Entity Graph · Person · Concept |
| 2030~ | pipeline | Personal Knowledge Universe |

**변하지 않는 것:** Tier 1에 포스터·UGC를 넣지 않음. **v1 성공 = 내 vault에 남는 기록의 품질**.

---

## 11. 관련 문서

| 문서 | 역할 |
|------|------|
| **본 문서** | Tier 1/2 · Steam v1 In/Out |
| [ultimate-archiving-vision.md](../history/product/ultimate-archiving-vision.md) | **궁극적 아카이빙** — Entity+Timeline · Phase 1~4 |
| [product/README.md](../history/product/README.md) | 제품 설계 문서 색인 |
| [data-policy.md](../history/policy/data-policy.md) | 필드·법무·CI |
| [catalog-ownership.md](../history/policy/catalog-ownership.md) | 3계층 소유 |
| [POSTER_POLICY.md](../../akasha-db/POSTER_POLICY.md) | v1 no-poster |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 인프라·규모 (§1 poster는 본 문서 우선) |
| [ROADMAP.md](ROADMAP.md) | 마일스톤 |

---

## 12. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | 초안 — Fact-only Tier 1 + Sanctum user archive SSOT |
| 2026-06-14 | ultimate-archiving-vision SSOT 링크 · 유저 여정 장기 축 |
| 2026-06-19 | §2 Entity·Record·Connection · Tier 1.5 · ADR-011 |
| 2026-06-19 | §7 Steam v1 · 10k+ · Tier 1.5 v1.x In |
| 2026-06-21 | **정체성 재정의** — 3층 구조 · Personal Knowledge Universe |
| 2026-06-30 | **Steam v1 재정렬** — Personal Sanctum archive 중심 · catalog post-v1 |
