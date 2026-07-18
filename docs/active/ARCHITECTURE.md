# AKASHA 데이터 아키텍처 재설계

> **상태:** 설계 확정 v2 · **v4 full-bundle 런타임 운영 중** (10,048 works · 1,713 shards)
> **기준일:** 2026-07-18
> **제품·포스터 SSOT:** [VISION.md](VISION.md) · **아카이빙 북극성:** [history/product/ultimate-archiving-vision.md](../history/product/ultimate-archiving-vision.md)

관련: [history/policy/akasha-db-policy.md](../history/policy/akasha-db-policy.md) · [history/policy/catalog-ownership.md](../history/policy/catalog-ownership.md) · [ROADMAP.md](ROADMAP.md) · [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](../history/closure-2026-07/ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md)

---

## 0. 제품 정체성 (정정)

### 0.0 무한 아카이브 Hardening (2026-07-03)

> **실행 계획:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md)
> **출시 전 감사:** [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](../history/closure-2026-07/ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md)

이 문서에서 "AI 친화적"은 AKASHA가 AI 서비스, 플레이어, 도구 오케스트레이터가 된다는 뜻이 아니다. AKASHA의 책임은 **원본 vault를 보존하고, 외부 도구/AI가 읽고 쓸 수 있는 안정적인 아카이브 계약을 제공하는 것**이다.

무한 확장을 위해 지금부터 엄격하게 볼 축:

1. 원본 vault `.md`는 source of truth
2. `.akasha/` 인덱스는 파생물이며 재구축 가능해야 함
3. 취향은 rating/tag/status/memo/link/collection 등 증거 기반 signal로 모델링
4. Agent write는 파일 난사가 아니라 허용된 operation 계약으로 표현
5. 제목/path가 아니라 안정 ID가 장기 identity의 기준

### 0.1 최종 비전

> **제품 SSOT:** [ultimate-archiving-vision.md](../history/product/ultimate-archiving-vision.md) — 아래는 인프라 문서 관점 요약.

**AKASHA = 지식 정보(Entity Anchor) + 나만의 일기(Subjective Journal) + 시각적 감상(Appreciation) + 외부 도구/AI가 읽을 수 있는 지식 그래프**

| 축 | 역할 |
|----|------|
| **글로벌/로컬 엔티티 사전** | 작품, 인물(성우 등), 사건, 사물 등 검색 및 식별이 가능한 객체 사각화 (닻의 역할) |
| **개인 아카이브 (저널)** | 유저가 기록하고 싶은 기억, 장면, 생각을 엔티티에 묶어 '일기(Journal)' 형식의 자연어로 마크다운 본문에 누적 |
| **감상 레이어 (Appreciation)** | 저널의 감상용 YAML 속성(theme_color, accent_gradient, custom_cover)을 바인딩해 갤러리 뷰 등에서 프리미엄 카드로 미학적 감상 제공 |

**현재 데이터 양(430작)은 시작점일 뿐이다.**  
아키텍처 판단은 「지금 몇 개냐」가 아니라 **「5년 뒤 50만 개일 때 갈아엎지 않느냐」**로 한다.

### 0.2 규모 로드맵 (목표)

| 시점 | 레지스트리 작품 수 | 운영 모델 |
|------|-------------------|-----------|
| **2026** (Steam v1) | ~430 | v4 런타임(`wk_`·해시 샤드) + 엄선 |
| **2027** | ~5,000 | 배치 + AI 보조 파이프라인 도입 |
| **2028** | ~50,000 | Registry Pipeline 본격화 |
| **2030** | ~500,000 | Git 소스 + CDN/R2 read, 검색 인덱스 분리 |

### 0.3 v1 정책 정정 (2026-06-10)

| 이전 설계 (폐기) | v1 Steam (현행) |
|------------------|-----------------|
| Tier 1 `posterPath` / `posterUrl` DB 저장 | **Tier 1 포스터 금지** — CI `tier1_poster`, 플레이스홀더 UI |
| Tier 1 `description` 큐레이션 | **Tier 1 description 금지** — 감상·요약은 Tier 2 Sanctum vault만 |
| Pipeline이 TMDB URL resolve → shard | Pipeline은 **Fact만** — 이미지·시놉은 유저 vault |
| 「엄선 레지스트리」= 최종 정체성 | **전 작품 사전**이 목표, 430작은 **현재 단계** |

인프라(샤딩·`wk_`·search_index)는 유지. **콘텐츠·이미지 호스팅**만 Tier 2로 이동 — [VISION.md](VISION.md).

---

## 1. 데이터 3계층 (재정의)

```
┌──────────────────────────────────────────────────────────────────┐
│  Tier 0 — Identity          wk_00001234 (영구 불변)               │
├──────────────────────────────────────────────────────────────────┤
│  Tier 1 — Global Registry     akasha-db (모든 유저 공유)            │
│  · 제목, 카테고리, searchTokens, franchise, externalIds (Fact)      │
│  · posterPath·description **없음** (v1)                             │
│  · production 앱은 검증된 전체 로컬 bundle만 읽음                 │
├──────────────────────────────────────────────────────────────────┤
│  Tier 2 — User Archive        Sanctum 볼트 (사용자만, 희소)        │
│  · 아카이브·기록한 작품만 .md 생성                                 │
│  · 평점, 감상, 명대사, poster URL/로컬, 본문 Markdown              │
│  · 레지스트리 전체의 md 파일 ❌                                   │
└──────────────────────────────────────────────────────────────────┘
```

### 1.1 Tier 1 vs Tier 2 — 포스터·설명 (v1)

| | Tier 1 (사전) | Tier 2 (볼트) |
|--|---------------|---------------|
| **포스터** | ❌ **미제공** — 플레이스홀더 | YAML `poster:` · `posters/` |
| **설명·감상** | ❌ **미제공** | Markdown 본문 + YAML 자유 |
| **역할** | 「원피스 검색 → Fact 카드」 | 「내가 쓴 기록 + 내 커버」 |

**검색 서비스 관점:** Tier 1은 **텍스트 Fact + searchTokens**만 배포한다. 현재
production은 이를 전체 로컬 bundle에서 읽으며 CDN을 호출하지 않는다.
이미지·창작 표현은 AKASHA가 **호스팅·큐레이션하지 않음** — [history/policy/data-policy.md §0.3](../history/policy/data-policy.md#03-tier-1-포스터-미제공-v1-steam).

```json
{
  "workId": "wk_00001234",
  "title": "원피스",
  "category": "manga",
  "releaseYear": 1997,
  "creator": "오다 에이치로",
  "externalIds": { "mal": "13", "tmdb": "37854" }
}
```

- `externalIds.*` — 영구 참조·dedupe·Contribution 대조용 (**자동 fetch·attach 금지**)
- `posterPath` / `description` — **shard·search_index에 없음** (v1)

### 1.2 Tier 2 — `.md`는 희소(sparse)

```
레지스트리 500,000작  →  GitHub akasha-db
사용자 A 볼트         →  37개 .md  (아카이브한 것만)
사용자 B 볼트         →  1,200개 .md
```

- 사전에 있어도 **`.md` 없음** = 「아직 내 기록 없음」  
- 대시보드 **가상 카드** = 사전 메타만으로 UI (볼트 파일 없음)  
- **아카이브** / 직접 등록 / 자동 아카이빙 시에만 `.md` 생성

---

## 2. 인프라: 저장·불러오기

### 2.1 스택 (2026~2028)

```
┌─────────────┐   commit/PR   ┌──────────┐
│ Registry    │ ────────────► │ GitHub   │  소스 오브 트루스
│ Pipeline    │               │ akasha-db│
└─────────────┘               └────┬─────┘
                 ┌─────────────────┴─────────────────┐
                 ▼                                   ▼
        결정적 full-bundle builder          GitHub raw / Cloudflare
                 │                           공개 replica (비활성 provider)
                 ▼
        앱 번들 (전체 1,713 shard)
        manifest/index bootstrap + lazy shard read
```

| 계층 | v1~2027 | 2028+ (50k~) |
|------|---------|--------------|
| Write | Git PR / Pipeline commit | 동일 + 자동화 bot |
| Read | **production full local bundle**; GitHub raw/Cloudflare는 공개 replica | 규모 gate 이후 검증된 remote/data pack 재평가 |
| App bundle | 전체 v4 shard + search index; shard는 asset에서 lazy read | 50k/64 MiB gate에서 재설계 |
| Server DB | **없음** | 50만+ 시 read replica (R2/D1) 검토 |

**2026 Steam v1:** PostgreSQL / Neo4j / Elastic / Vector DB **불필요**.  
**2030 50만+:** 검색 인덱스·read path만 전용화; Git은 여전히 **기여·감사·버전** 용도.

### 2.2 production client read (bundle-only)

1. bundled root/search manifest의 `releaseId`, `sourceRevision`, `schemaVersion`,
   `bundleMode=full`을 검증한다.
2. bundled category search index로 필요한 shard ID를 결정한다.
3. `assets/registry/shards/{category}/{shardKey}.json`을 lazy read하고 manifest SHA를
   검증한다.
4. `legacy_aliases.json`, `franchise_groups.json`도 bundle에서 읽는다.

production에는 CDN manifest 확인, remote shard fallback, registry cache 우선순위, 24시간
auto-sync, 수동 sync/custom URL UI가 없다. 첫 bundle-only release는 registry 전용 cache만
한 번 삭제한다. 미래 remote provider는 release 전체 provenance와 검증을 갖춘 명시적
source로만 재도입할 수 있으며 파일별 혼합 fallback은 허용하지 않는다.

Cloudflare와 remote provider 코드는 독립 source 배포 및 향후 실험을 위해 보존하지만 현재
production dependency graph에는 연결하지 않는다.

---

## 3. 샤딩 — 유지하되 키 전략 변경

### 3.1 왜 샤딩을 유지하는가

410작일 때 205샤드는 **파일당 2작**으로 과해 보인다.  
하지만 목표가 **50만~100만**이면:

- `works/manga.json` 하나 → **수십 MB**, parse·sync·diff 불가  
- 나중에 갈라면 **Sync · Loader · Builder · CI · Cache 전부 재작성**

→ **지금 샤딩·lazy load·manifest 기반 sync는 미래를 위한 선행 투자**다.

### 3.2 현재 (v3) 문제 — 슬러그 기반 샤딩

```
manga_K.json  ← Kimetsu, Kingdom, …
manga_O.json  ← One Piece, …
```

- `The Lord of the Rings`, `The Matrix`, `The Witcher` → 전부 **T**  
- 100만 작품 시 **핫스팟 샤드** 발생

### 3.3 목표 (v4) — 해시 기반 균등 샤딩

```
shardKey = hash(wk_id 또는 work_id) % 256
         → hex "00" .. "ff"

shards/manga/00.json
shards/manga/01.json
...
shards/manga/ff.json
```

| 항목 | v3 (현재) | v4 (목표) |
|------|-----------|-----------|
| 키 | 슬러그 첫 글자 `manga_K` | `hash(id) % 256` → `manga/a3.json` |
| 분포 | 불균형 | **균등** |
| 카테고리 | 디렉터리 분리 유지 | `shards/{category}/{hh}.json` |
| manifest | shard id + entryCount | + `sha256`, `shardKey` 규칙 버전 |

**게임 Steam appid 샤드** (`game_steam_730.json`) 등 특수 케이스는 v4에서 `hash`로 통합하거나 `extensions.shardOverride`로 이관.

### 3.4 샤드 크기 가이드

| 규모 | 샤드당 목표 | 256샤드 × 7카테고리 |
|------|-------------|---------------------|
| 5,000 | ~3작/샤드/카테고리 | 여유 |
| 50,000 | ~28작 | OK |
| 500,000 | ~280작 | ~50~100KB/샤드 (메타만) |
| 1,000,000+ | 샤드 수 256→1024 확장 검토 | manifest `shardBits: 10` |

---

## 4. 작품 ID — `wk_` 영구 불변

### 4.1 정책

```
wk_00001234     ← Tier 0, 절대 불변·재사용 금지
slug, year, category, titles …  ← 메타, 자유 수정
legacy_aliases  ← sub_manga_one-piece_1997 → wk_00001234
```

슬러그 ID `{sub|gen}_{category}_{slug}_{year}`는 **레거시·가독성**용으로 유지하되,  
장기적으로 **primary key = `wk_`**.

### 4.2 할당

- `id_registry.json` / manifest `nextWorkId`  
- Pipeline이 배치 추가 시 자동 할당  
- CI: `wk_` 중복·역참조 금지

### 4.3 `assign_wk_ids` 도구 (Phase A 진입점)

**`tool/assign_wk_ids.dart`** — 기존 ~410작에 `wk_00000001` 형식의 영구 ID를 일괄 부여하는 마이그레이션 스크립트.

| 단계 | 동작 |
|------|------|
| 수집 | v3 샤드 JSON 전 work 엔트리 |
| 할당 | 전역 순번, 8자리 zero-pad (`wk_00000410`) |
| 기록 | `id_registry.json` + `legacy_aliases.json` |
| 적용 | `--apply` 시 샤드 `workId` → `wk_`, `legacyIds`에 옛 `sub_*` 보존 |

옛 볼트 `.md`의 `work_id`는 **rename 없이** `legacy_aliases`로 `wk_`에 조인된다.  
상세 일정: [v4-migration-plan.md](../history/v4-migration-plan.md) Phase A.

---

## 5. WorkEntry 스키마 (v4 초안)

```json
{
  "workId": "wk_00001234",
  "legacyIds": ["sub_manga_one-piece_1997"],
  "title": "원피스",
  "titles": { "ko": "원피스", "en": "One Piece", "ja": "ONE PIECE" },
  "aliases": ["원조", "OP"],
  "category": "manga",
  "domain": "subculture",
  "creator": "오다 에이치로",
  "releaseYear": 1997,
  "tags": ["모험", "해적"],
  "externalIds": { "tmdb": "37854", "mal": "13" },
  "searchTokens": [
    "원피스", "원조", "one piece", "ワンピース", "op"
  ],
  "qualitySignals": {
    "externalIdVerified": true
  }
}
```

**search_index.json** (빌드 산출): `workId`, `title`, `category`, `searchTokens` — **`posterPath` 없음** (v1)

---

## 6. Registry Pipeline (장기 — 수동 큐레이션 대체)

수만~수십만 작품은 **인간 수동 PR로 불가능**.  
목표 구조:

```
┌─────────┐    ┌─────────────┐    ┌────────┐    ┌────────────┐    ┌──────────┐
│ Source  │───►│ AI Extract  │───►│ Dedupe │───►│ WorkEntry  │───►│ Shard    │
│ lists   │    │ + validate  │    │ + merge│    │ + wk_ assign│    │ batch    │
│ feeds   │    │             │    │        │    │ + wk_ assign│    │ + commit │
└─────────┘    └─────────────┘    └────────┘    └────────────┘    └──────────┘
```

| 단계 | 내용 |
|------|------|
| **Source** | 공개 메타 목록, 라이선스 허용 소스, 엄선 시드 리스트 |
| **AI Extract** | 제목·연도·카테고리·searchTokens 초안 (**시놉·포스터 제외**) |
| **Dedupe** | `wk_` / fuzzy title / `externalIds` 교차검증 |
| **Shard** | `hash(wk_) % 256` 버킷에 insert |
| **CI** | `tier1_poster`, duplicate, franchise_linter |
| **Git** | 자동 PR 또는 bot commit |

### 6.1 「API bulk 금지」 (유지)

| 금지 | 허용 |
|------|------|
| AniList/TMDB API 자동 fetch·응답 저장 | 자동 연동 없음 · 검증된 `externalIds.*` 식별자 Fact만 저장 |
| Tier 1 `posterPath`·`description` | Tier 2 유저 vault |
| 외부 포스터 CDN별 denylist | Tier 1 이미지 URL 전체 금지로 별도 denylist 불필요 |
| 검증 없는 68만작 일괄 시드 | **Dedupe + CI** 통과 분만 merge |

**핵심:** AKASHA는 **Fact index**만 배포. 이미지·창작 텍스트는 유저 Sanctum vault.

---

## 7. 엔티티 및 저널이 「저장」되는 경로 (감상 융합)

> **제품·로드맵 SSOT:** [ultimate-archiving-vision.md](../history/product/ultimate-archiving-vision.md) §3–§6

### 7.1 레지스트리에 추가 (공식 사전 - 객체 닻)

**지금 (2026):** `seed_expansion_batchN.dart` + 수동 JSON + PR  
**이후:** Registry Pipeline (§6)

→ **모든 유저**가 작품, 인물(성우), 사건 등의 검색·가상 카드(플레이스홀더)에서 사용.

### 7.2 사용자 아카이브 저널 (볼트 `.md`)

**트리거:** 아카이브, 직접 등록, 일기 작성, AI 추출 기록  
**결과:** 특정 엔티티 ID(`entityId`) 또는 특정 날짜(`date`)에 해당하는 `.md` 파일 생성 (기록이 있을 때만 파일 생성)

**저장 내용**:
- **감상 메타데이터 (YAML)**: `theme_color`, `accent_gradient`, `custom_cover`, `mood_tags` 등 시각화에 필요한 디자인 힌트
- **자연어 서사 (Markdown)**: 개인적 생각, 감상, 어릴 적 기억, 명장면 등 자유 형식의 텍스트와 엔티티 위키 링크(`[[Entity]]`)

### 7.3 UI Fusion 및 감상(Appreciation) 조인

앱은 사전 메타데이터(Tier 1)와 사용자 저널(Tier 2)을 런타임에 결합하여 **`AppreciationViewport`**를 조립합니다.

| 사전 (Entity) | 볼트 저널 (.md) | 최종 UI 감상 뷰포트 (Appreciation Viewport) |
|:---:|:---:|---|
| ✅ | ❌ | **가상 카드**: 사전 Fact와 플레이스홀더 테마 그라디언트로 구성된 뷰 |
| ✅ | ✅ | **감성 아카이브 카드**: 사전 Fact와 사용자의 YAML 감상 스타일(테마색, 커스텀 표지), 본문 일기가 결합된 커스텀 갤러리 뷰 |
| ❌ | ✅ | **커스텀 저널 카드**: 로컬 볼트에만 존재하는 커스텀 엔티티/일기 카드 뷰 |

### 7.4 중복·프랜차이즈

- **Dedupe:** Pipeline + `searchTokens` + `externalIds`  
- **Franchise:** `franchise_groups.json`, members = `wk_`  
- **IP 1카드:** `FranchiseFusionService` (기 구현)

---

## 8. 검색 — `searchTokens` 핵심 자산

- 자동완성·전역 검색: `search_index.json`  
- AI 검색·중복 탐지의 입력  
- Pipeline이 생성, human/CI가 보강  

```json
"searchTokens": [
  "슈타인즈 게이트", "슈타게", "steins gate",
  "steins;gate", "science adventure"
]
```

---

## 9. 구현 우선순위 · Steam 출시 게이트

> **결정:** Steam v1 **이전에** Phase A~D(v4 런타임) 완료. 실행 상세는 [v4-migration-plan.md](../history/v4-migration-plan.md).

| 구분 | Phase | Steam 전 |
|------|-------|----------|
| **게이트** | A `wk_` ID | ✅ 필수 |
| **게이트** | B 앱·볼트 호환 | ✅ 필수 |
| **게이트** | C dedupe CI | ✅ 필수 |
| **게이트** | D 해시 샤딩 v4 | ✅ 필수 |
| 권장 | Pipeline 스켈레톤 | 🔶 시간 있으면 |
| 출시 후 | AI 자동 수집 | ❌ 2027~ |
| 출시 후 | 50k+ CDN·R2 | ❌ 2028~ |

### Phase 0 — v3 기반·M1 ✅

- [x] v4 해시 샤드 + lazy sync · Tier 1 **posterPath 제거** (2026-06-10)  
- [x] 430작 엄선 · dogfood 통과 · `master_archive`  
- [x] 설계 v2 문서 · 정책 정렬  

### Phase A — `wk_` 영구 ID ✅

- [x] `assign_wk_ids.dart` (dry-run / `--apply`)  
- [x] `id_registry.json` — 430작 전역 순번  
- [x] `legacy_aliases` 전량 매핑  
- [x] 샤드 `workId` → `wk_` + `legacyIds`  
- [x] CI: `id_registry_check.dart`  

### Phase B — 앱·볼트 호환 ✅

- [x] `WorkIdCodec` — `wk_` 파싱  
- [x] `setContainsWorkId` — legacy·wk 교차 매칭  
- [x] 프랜차이즈·가시성 legacy 호환  
- [x] `legacy_aliases` 번들 로드 + resolve  
- [x] dogfood 재검증 (110 tests)  

### Phase C — Canonicalization CI ✅

- [x] [canonicalization-policy.md](../history/policy/canonicalization-policy.md) 문서  
- [x] `dedupe_linter.dart` — 후보 제시만, 자동 merge 금지  
- [x] `retire_work_ids.dart` — 중복 병합 (430작)  
- [x] `franchise_groups` = `wk_` members 검증  

### Phase D — 해시 샤딩 v4 ✅

- [x] `migrate_shards_v3_to_v4_hash.dart` — v3 슬러그 206개 제거  
- [x] manifest v4 (`shardBits: 8`, per-shard `sha256`)  
- [x] builder / loader / sync / CI v4 (`manifest_v4_check`)  
- [x] 슬러그 샤드(`manga_K`) deprecated → `shards/{category}/{hh}.json`  

### Phase E — Steam v1 출시

- [ ] akasha-db push · dogfood 재검증  
- [ ] Steamworks · 스토어 · 무료 출시 · IAP post-launch 보류

### Phase F — Registry Pipeline (출시 후)

- [ ] `tool/registry_pipeline/` 스켈레톤  
- [ ] extract → dedupe → shard → Git  

### Phase G — AI 자동 수집 · 50k+ 인프라 (2027~)

- [ ] 일 1k~10k ingest · CDN/R2 분리

---

## 10. ADR 요약 (v2)

| # | 결정 | 근거 |
|---|------|------|
| D1 | 최종 목표 = **전 작품 사전** | 제품 비전 |
| D2 | **샤딩 유지** + 해시 키로 전환 | 50만~100만, 지금 인프라 재사용 |
| D3 | Tier 1 **`posterPath`·`description` 금지** (v1) | Fact index + 유저 vault — [VISION.md](VISION.md) |
| D4 | 볼트 `.md` **희소** | 아카이브한 작품만 |
| D5 | `wk_` 영구 ID | 메타 변경 시 조인 유지 |
| D6 | 장기 **Registry Pipeline** + AI | 수만 작품 인간 불가 |
| D7 | GitHub+Cloudflare (2028까지) | 서버비 0, 검증됨 |
| D8 | flat `works/manga.json` **채택 안 함** | 규모 커지면 재작업 |

---

## 11. 관련 문서

| 문서 | 내용 |
|------|------|
| [VISION.md](VISION.md) | **제품·Tier 1/2 SSOT** |
| [README.md](../README.md) | 「전 작품 사전」목표, 현재 엄선 단계 |
| [ROADMAP.md](ROADMAP.md) | 출시·데이터 백로그 |
| [akasha-db-policy.md](../history/policy/akasha-db-policy.md) | 구축·운영·법무 마스터 |
| [canonicalization-policy.md](../history/policy/canonicalization-policy.md) | identity·dedupe 규칙 |
| [catalog-ownership.md](../history/policy/catalog-ownership.md) | 3계층·소유권 |
| [v4-migration-plan.md](../history/v4-migration-plan.md) | **Steam 전 실행 계획** |
| [akasha-db/SCHEMA.md](../../akasha-db/SCHEMA.md) | v3 현재 · v4 `wk_`·해시 샤드 |

---

*2026-06-10: Tier 1 poster·description 제거로 [VISION.md](VISION.md)와 정렬. 인프라(v4·샤딩·`wk_`)는 본 문서 기준 유지.*
