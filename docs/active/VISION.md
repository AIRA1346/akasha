# AKASHA Product Vision

> **Long-horizon architecture authority:**
> [AKASHA Archive Constitution](AKASHA_ARCHIVE_CONSTITUTION.md). This document
> retains the v1 product scope; when it conflicts with the Constitution on
> ownership, durable preservation, AI boundaries, or scale architecture, the
> Constitution governs.

> **지위:** **v1 제품 범위 SSOT** (정책·ROADMAP·스토어 카피의 제품 북극성; 원칙은 Constitution)
> **갱신:** 2026-07-12 — 문서 2차 정렬 · Steam v1 = Personal Sanctum Archive
> **Git:** current tip은 `git log -1` 기준
> **법무:** [history/policy/data-policy.md](../history/policy/data-policy.md)

---

## 1. 정체성

### 한 문장 (프로토콜)

> **AKASHA는 사용자가 소유한 개인 아카이브 프로토콜이다.** 앱은 첫 인터페이스이고, Markdown은 현재 원본 형식이며, 인덱스·AI는 파생 탐색·교체 가능한 활용자다.

### 한 문장 (Steam v1)

> **AKASHA v1은 사용자의 감상을 Sanctum vault에 남기고, 외부 도구/AI가 그 구조를 읽고 도울 수 있게 하는 개인 아카이브 앱이다.**

작품 아카이빙은 이 비전을 검증하는 **첫 번째 도메인**이다. 장기적으로는 사람·사건·개념·일기·타임라인·관계·미디어를 같은 보존 원칙 위에서 다루되, 도메인 의미를 하나의 Universal Record로 평탄화하지 않는다 ([Constitution §3.6](AKASHA_ARCHIVE_CONSTITUTION.md)).

### AI / Agent 경계

AKASHA는 AI 서비스, 채팅 동반자, 플레이어, 도구 오케스트레이터가 아니다.

역할은 **사용자의 vault와 취향 증거를 오래 보존하고, 외부 도구/AI가 읽고 쓸 수 있는 안정적인 아카이브 구조를 제공하는 것**이다. 예를 들어 외부 에이전트가 "좋아하는 액션영화 OST 틀어줘"를 처리할 때, AKASHA는 취향 근거와 연결 정보를 제공하고 재생은 외부 도구가 담당한다.

실행 계획: [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md).

---

### 층 1 — 표면: Personal Archive App (v1)

사용자가 처음 보는 모습:

- **내 vault**에 감상·평점·상태·태그·명장면·갤러리를 남김
- Personal Library · Collection으로 **내가 아카이브한 것**을 큐레이션
- (보조) starter catalog로 작품을 찾아 아카이브로 가져옴

겉모습은 Goodreads · Letterboxd와 겹칠 수 있으나, **v1 핵심은 글로벌 사전이 아니라 내 기록**이다.

---

### 층 2 — 도메인 확장: Work를 넘어선 기록 대상

작품은 첫 진입점이다. 같은 보존 원칙 위에서 Entity(인물·개념·사건 등)·Journal·Timeline·Canvas로 확장한다. 도메인마다 고유 의미가 있다 — Work의 평점/상태, Timeline의 경험 시각, Journal의 자유 기록, Canvas의 공간 표현.

```
Work → Entity → Relationship → Collection
```

Hero / Villain / Cast Collection 등은 작품 목록을 넘어 **사람·개념을 큐레이션하는** 현재 구현의 신호다. 이것은 “위키를 만든다”가 아니라 **사용자가 중요하다고 고른 세계를 남긴다**는 뜻이다.

---

### 층 3 — 장기: 시간에 따라 변하는 개인 기록

AKASHA는 최신 평점만 남기는 프로필이 아니다. 왜 그렇게 생각했는지, 언제 바뀌었는지, 원본·가져오기·AI 파생이 무엇인지가 장기적으로 남도록 한다 ([Constitution §3.2–3.3](AKASHA_ARCHIVE_CONSTITUTION.md)).

위키는 “세계의 정보”를 저장한다. AKASHA는 **“내가 중요하다고 생각하는 세계”**를 사용자 소유로 보존한다.

의미 이력·행동 흔적 정책은 [Constitution §7](AKASHA_ARCHIVE_CONSTITUTION.md)에 결정되어 있다 — 의미 변경은 복구 가능 역사에 보존하되 1급 Record 승격은 사용자 선택이며, 행동 집계는 로컬 최소치만 기본 수집한다.

---

## 2. 핵심 철학 (제품 표현)

헌법의 비협상 원칙을 v1 제품 언어으로 옮기면:

```
사용자가 원본을 소유한다.
원본과 파생을 섞지 않는다.
결과만이 아니라 의미 있는 변화를 보존한다.
형식보다 보존 원칙이 앞선다.
도메인 의미를 평탄화하지 않는다.
```

v1에서 사용자가 체감하는 축:

```
작품은 소비의 진입점이다.
기록은 vault에 남는다.
연결은 사용자가 만든다.
서재는 의미를 전시한다.
```

### 진화 경로 (제품)

```
Work archive (v1)
 ↓
Entity · Collection
 ↓
Journal · Timeline
 ↓
관계·출처·의미 이력 (계약이 준비된 뒤)
```

이것은 라이브러리 기능 확장이 아니라, **안전하게 보존하는 시스템 → 방대한 기록을 신뢰하며 쓰는 시스템**으로의 이동이다 ([Constitution §5](AKASHA_ARCHIVE_CONSTITUTION.md)).

---

## 3. AKASHA가 아닌 것

| ❌ | 이유 |
|----|------|
| 단순 독서/감상 트래커 | 기능의 일부일 뿐 · 본질은 장기 보존 프로토콜 |
| AI 채팅·에이전트 호스트 | AI는 교체 가능한 독자·보조자 |
| Obsidian 대체재 | 볼트/Markdown은 현재 수단 |
| 위키 클론 | 객관 세계 DB가 아니라 사용자 관점·소유 |
| 인덱스/DB를 원본으로 삼는 앱 | 파생 계층은 버려도 재구축 가능해야 함 |
| 미디어 플레이어·추천 엔진 | 외부 도구 영역 |

---

## 4. Entity · Record · Connection (+ Tier)

**북극성:** 세상에서 만난 대상(Entity)을 식별하고, 내가 남긴 것(Record)을 축적하며, 관계(Connection)로 연결한다 — 단, **소유·출처·도메인 의미를 잃지 않는다**.  
실행 참고: [history/programs/entity-centric-evolution-plan.md](../history/programs/entity-centric-evolution-plan.md) · [ADR-011](../history/adr/ADR-011-entity-type-subtype.md)

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

원본 Vault vs 파생 인덱스 경계는 Constitution §3.4 · `system/`(비재구축) vs `.akasha/`(파생·폐기 가능)를 따른다.

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
(장기) Entity · Timeline · Connection · 의미 이력(§7.1) · 최소 행동 집계(§7.2)
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
- 외부 Markdown 가져오기 (신규 작품, AI 전용 기능 아님)
- 대시보드 · IP 1카드 · 나만의 서재 · 무료 앱 테마

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

**Steam 출시:** 사용자 지시에 따라 무료 일반 출시로 진행. 유료 테마/IAP와 정식 1.0 이후 범위는 별도 결정.

---

## 10. 장기 (철학 유지)

| 시점 | Tier 1 (akasha-db) | 제품 초점 |
|------|-------------------|----------|
| **2026 v1** | optional starter · CI 유지 | **Personal Sanctum archive** |
| 2027~ | post-v1 scale | Entity · Journal · Timeline · 관계 계약 |
| 2030~ | pipeline | 사용자 소유 장기 아카이브 (형식 진화 가능) |

**변하지 않는 것:** Tier 1에 포스터·UGC를 넣지 않음. 원본은 사용자 vault. **v1 성공 = 내 vault에 남는 기록의 품질**.

---

## 11. 관련 문서

| 문서 | 역할 |
|------|------|
| [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md) | **Supreme SSOT** — 원칙·거부 기준 |
| **본 문서** | Steam v1 제품 범위 · Tier 1/2 |
| [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) | **Vault 형식 명세 v3** |
| [ultimate-archiving-vision.md](../history/product/ultimate-archiving-vision.md) | historical — Entity+Timeline 장기상 |
| [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) | index · taste · agent write · ID path |
| [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) | 출시 전 Vault Layout v3 감사 |
| [product/README.md](../history/product/README.md) | 제품 설계 문서 색인 |
| [data-policy.md](../history/policy/data-policy.md) | 필드·법무·CI |
| [catalog-ownership.md](../history/policy/catalog-ownership.md) | 3계층 소유 |
| [POSTER_POLICY.md](../../akasha-db/POSTER_POLICY.md) | v1 no-poster |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 인프라·규모 (§1 poster는 본 문서 우선) |
| [ROADMAP.md](ROADMAP.md) | 마일스톤 |
| [CURRENT_STATE.md](CURRENT_STATE.md) | 구현 현실 |

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
| 2026-07-03 | **Infinite Archive Hardening** — AI 서비스가 아니라 아카이브 기반층 |
| 2026-07-03 | **Pre-release Architecture Audit** — Vault Layout v3 canonical 후보 |
| 2026-07-12 | **문서 2차** — Constitution 정렬 · 프로토콜 정체성 |
| 2026-07-12 | **Constitution §7 결정** — 의미 이력(의미 변경 자동 보존·Record 승격은 선택) · 행동 집계(로컬 최소·원시 로그 비기본) |
