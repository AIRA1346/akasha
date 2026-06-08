# AKASHA 데이터 아키텍처 재설계

> **상태:** 설계 확정 v2 · **구현 0%** (v3 런타임 운영 중)  
> **기준일:** 2026-06-08  
> **한 줄:** **세상의 모든 작품 사전**이 최종 목표다. **Steam v1 출시 전에 v4 런타임**(wk_·해시 샤드)을 완료한다.  
> **실행 계획:** [v4-migration-plan.md](v4-migration-plan.md)

관련: [akasha-db-policy.md](akasha-db-policy.md) · [catalog-ownership.md](catalog-ownership.md) · [ROADMAP.md](../ROADMAP.md)

---

## 0. 제품 정체성 (정정)

### 0.1 최종 비전

**AKASHA = IMDb + OpenLibrary + 개인 Obsidian 볼트**

| 축 | 역할 |
|----|------|
| **글로벌 작품 사전** | 세상의 모든 작품을 검색·발견할 수 있는 레지스트리 (장기 목표) |
| **개인 아카이브** | 사용자가 **선택한** 작품만 `.md`로 감상·평가 기록 (볼트) |

**현재 데이터 양(~410작)은 시작점일 뿐이다.**  
아키텍처 판단은 「지금 몇 개냐」가 아니라 **「5년 뒤 50만 개일 때 갈아엎지 않느냐」**로 한다.

### 0.2 규모 로드맵 (목표)

| 시점 | 레지스트리 작품 수 | 운영 모델 |
|------|-------------------|-----------|
| **2026** (Steam v1) | ~410 | v4 런타임(`wk_`·해시 샤드) + 엄선 |
| **2027** | ~5,000 | 배치 + AI 보조 파이프라인 도입 |
| **2028** | ~50,000 | Registry Pipeline 본격화 |
| **2030** | ~500,000 | Git 소스 + CDN/R2 read, 검색 인덱스 분리 |

### 0.3 잘못 이해했던 점 (v1 문서 정정)

| v1 문서 (틀림) | v2 (맞음) |
|----------------|-----------|
| 「엄선 레지스트리」가 최종 정체성 | **전 작품 사전**이 목표, 엄선은 **현재 단계** |
| 410작이면 flat JSON이 낫다 | **지금 샤딩 인프라를 유지·강화** — 나중에 구조 갈아엎기 방지 |
| `posterPath` 제거, ID만 저장 | **DB에 `posterUrl` 필수** — 검색 즉시 카드 표시 |
| 모든 작품이 볼트 `.md` | **아카이브한 작품만** `.md` 생성 (희소) |
| 수동 큐레이션만 | **장기: AI Registry Pipeline** (하루 수천~수만 건) |

---

## 1. 데이터 3계층 (재정의)

```
┌──────────────────────────────────────────────────────────────────┐
│  Tier 0 — Identity          wk_00001234 (영구 불변)               │
├──────────────────────────────────────────────────────────────────┤
│  Tier 1 — Global Registry     akasha-db (모든 유저 공유)            │
│  · 제목, 카테고리, searchTokens, franchise                        │
│  · posterUrl + externalIds (검색·카드 표시용 — DB에 저장)          │
│  · GitHub → Cloudflare → 앱 sync / 번들                           │
├──────────────────────────────────────────────────────────────────┤
│  Tier 2 — User Archive        Obsidian 볼트 (사용자만, 희소)        │
│  · 아카이브·기록한 작품만 .md 생성                                 │
│  · 평점, 감상, 명대사, 나의 상태, (선택) 로컬 포스터               │
│  · 레지스트리 전체의 md 파일 ❌                                   │
└──────────────────────────────────────────────────────────────────┘
```

### 1.1 Tier 1 vs Tier 2 — 포스터

| | Tier 1 (사전) | Tier 2 (볼트) |
|--|---------------|---------------|
| **포스터** | `posterPath` / `posterUrl` **DB에 저장** → 검색·그리드 즉시 표시 | 사용자가 **직접 넣은** `posters/` 파일만 (선택) |
| **역할** | 「원피스 검색 → 카드에 포스터」 | 「내가 쓴 감상 + 내가 바꾼 커버」 |
| **기본** | 사전 URL이 **기본 표시** | 볼트 로컬 포스터가 있으면 **그 작품만** 덮어씀 |

**검색 서비스 관점:** 매 검색마다 TMDB/Steam/OpenLibrary를 조회하면 성능이 무너진다.  
대형 서비스처럼 **둘 다 저장**한다.

```json
{
  "externalIds": { "tmdb": "37854" },
  "posterPath": "https://image.tmdb.org/t/p/w500/....",
  "extensions": {
    "posterSource": "tmdb",
    "posterVerified": true
  }
}
```

- `externalIds.tmdb` — 영구 참조·재검증·URL 갱신용  
- `posterPath` — **캐시 URL**, 클라이언트는 이걸로 `Image.network` (즉시 표시)  
- URL 깨지면 파이프라인이 `externalIds`로 **재생성** (배치), 앱은 여전히 URL만 읽음

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
                                   │ raw HTTPS
                                   ▼
                            ┌──────────────┐
                            │ Cloudflare   │  edge CDN (= 사실상 read DB)
                            └──────┬───────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
        앱 번들 (subset)     registry_cache/      search_index
        cold start           증분 sync            전용 fetch
```

| 계층 | v1~2027 | 2028+ (50k~) |
|------|---------|--------------|
| Write | Git PR / Pipeline commit | 동일 + 자동화 bot |
| Read | GitHub raw + Cloudflare | + R2 mirror, search_index brotli |
| App bundle | 엄선 subset (eager + lazy) | manifest만 번들, 샤드 on-demand |
| Server DB | **없음** | 50만+ 시 read replica (R2/D1) 검토 |

**2026 Steam v1:** PostgreSQL / Neo4j / Elastic / Vector DB **불필요**.  
**2030 50만+:** 검색 인덱스·read path만 전용화; Git은 여전히 **기여·감사·버전** 용도.

### 2.2 클라이언트 sync (유지·강화)

1. `GET manifest.json` — `version`, `generatedAt`, `entryCount`, `shards[]`
2. 샤드별 lazy `GET shards/{category}/{shardKey}.json`
3. `GET search_index.json` — 자동완성·전역 검색 (별도 파일 유지)
4. `legacy_aliases.json`, `franchise_groups.json`

**증분 규칙:**

- `generatedAt` 동일 → skip  
- 샤드별 `entryCount` + `sha256` → 변경된 샤드만 fetch  
- 번들이 원격보다 새면 stale cache 무효화 (기 구현)

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
상세 일정: [v4-migration-plan.md](v4-migration-plan.md) Phase A.

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
  "description": "자체 작성 2~3문장.",
  "tags": ["모험", "해적"],
  "externalIds": { "tmdb": "37854", "mal": "13" },
  "posterPath": "https://image.tmdb.org/t/p/w500/....",
  "searchTokens": [
    "원피스", "원조", "one piece", "ワンピース", "op"
  ],
  "extensions": {
    "posterSource": "tmdb",
    "posterVerified": true
  }
}
```

**search_index.json** (빌드 산출): `workId`, `title`, `category`, `searchTokens`, `posterPath` (검색 결과 즉시 렌더)

---

## 6. Registry Pipeline (장기 — 수동 큐레이션 대체)

수만~수십만 작품은 **인간 수동 PR로 불가능**.  
목표 구조:

```
┌─────────┐    ┌─────────────┐    ┌────────┐    ┌────────────┐    ┌──────────┐
│ Source  │───►│ AI Extract  │───►│ Dedupe │───►│ WorkEntry  │───►│ Shard    │
│ lists   │    │ + validate  │    │ + merge│    │ + wk_ assign│    │ batch    │
│ feeds   │    │             │    │        │    │ + posterUrl │    │ + commit │
└─────────┘    └─────────────┘    └────────┘    └────────────┘    └──────────┘
```

| 단계 | 내용 |
|------|------|
| **Source** | 공개 메타 목록, 라이선스 허용 소스, 엄선 시드 리스트 |
| **AI Extract** | 제목·연도·카테고리·**자체 요약 2~3문장**·searchTokens 초안 |
| **Dedupe** | `wk_` / fuzzy title / `externalIds` 교차검증 |
| **Poster** | TMDB/Steam/OL ID → **URL resolve → DB 저장** (배치, 런타임 아님) |
| **Shard** | `hash(wk_) % 256` 버킷에 insert |
| **CI** | denylist URL, duplicate, franchise_linter |
| **Git** | 자동 PR 또는 bot commit |

### 6.1 「API bulk 금지」 재정의

| 금지 (유지) | 허용 (확장) |
|-------------|-------------|
| AniList 응답 **그대로** Git에 영구 저장 (시놉 복붙) | Pipeline이 **가공·요약·검증** 후 저장 |
| `anilistcdn` 등 denylist CDN | `image.tmdb.org`, Steam, Open Library |
| 런타임 API로 사용자 검색마다 fetch | **빌드 시** poster URL resolve → DB |
| 검증 없는 68만작 일괄 시드 | **Dedupe + CI** 통과 분만 merge |

**핵심:** borrow가 아니라 **AKASHA 소유 메타로 가공해 적재**하는 파이프라인.

---

## 7. 작품이 「저장」되는 경로

### 7.1 레지스트리에 추가 (공식 사전)

**지금 (2026):** `seed_expansion_batchN.dart` + 수동 JSON + PR  
**이후:** Registry Pipeline (§6)

→ **모든 유저**가 검색·가상 카드·포스터에서 사용.

### 7.2 사용자 아카이브 (볼트 `.md`)

**트리거:** 아카이브, 직접 등록, 자동 아카이빙, AI 가져오기  
**결과:** 해당 `work_id`에 대한 `.md` **1파일** (없으면 파일 없음)

**저장 내용:** 평점, 감상, 명대사, 나의/작품 상태, HoF, 태그  
**저장 안 함:** 사전 `posterPath` (YAML 중복 금지 — 기 구현)

### 7.3 UI Fusion (조인)

| 사전 | 볼트 `.md` | UI |
|------|------------|-----|
| ✅ | ❌ | 가상 카드 (사전 메타·포스터) |
| ✅ | ✅ | 아카이브 카드 (Tier2 + Tier1 fusion) |
| ❌ | ✅ | custom 작품 (볼트만) |

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

> **결정:** Steam v1 **이전에** Phase A~D(v4 런타임) 완료. 실행 상세는 [v4-migration-plan.md](v4-migration-plan.md).

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

- [x] v3 슬러그 샤드 + lazy sync + `posterPath` in DB  
- [x] ~410작 엄선 · dogfood 통과 · `master_archive`  
- [x] 설계 v2 문서 · 정책 정렬  

### Phase A — `wk_` 영구 ID ✅

- [x] `assign_wk_ids.dart` (dry-run / `--apply`)  
- [x] `id_registry.json` — 410작 전역 순번  
- [x] `legacy_aliases` 전량 매핑  
- [x] 샤드 `workId` → `wk_` + `legacyIds`  
- [x] CI: `id_registry_check.dart`  

### Phase B — 앱·볼트 호환 (진행 중)

- [x] `WorkIdCodec` — `wk_` 파싱  
- [x] `setContainsWorkId` — legacy·wk 교차 매칭  
- [x] 프랜차이즈·가시성 legacy 호환  
- [ ] Loader `id_registry` 로드 (선택)  
- [ ] dogfood 재검증  

### Phase C — Canonicalization CI ✅

- [x] [canonicalization-policy.md](canonicalization-policy.md) 문서  
- [x] `dedupe_linter.dart` — 후보 제시만, 자동 merge 금지  
- [x] `retire_work_ids.dart` — 중복 8건 병합 (402작)  
- [x] `franchise_groups` = `wk_` members 검증  

### Phase D — 해시 샤딩 v4

- [ ] `migrate_shards_v3_to_v4_hash.dart`  
- [ ] manifest v4 (`shardBits: 8`)  
- [ ] builder / loader / sync / CI v4  
- [ ] 슬러그 샤드(`manga_K`) deprecated  

### Phase E — Steam v1 출시

- [ ] akasha-db push · dogfood 재검증  
- [ ] Steamworks · 스토어 · IAP · 출시  

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
| D3 | `posterPath` **DB 유지** + `externalIds` | 검색 즉시 표시 + URL 갱신 |
| D4 | 볼트 `.md` **희소** | 아카이브한 작품만 |
| D5 | `wk_` 영구 ID | 메타 변경 시 조인 유지 |
| D6 | 장기 **Registry Pipeline** + AI | 수만 작품 인간 불가 |
| D7 | GitHub+Cloudflare (2028까지) | 서버비 0, 검증됨 |
| D8 | flat `works/manga.json` **채택 안 함** | 규모 커지면 재작업 |

---

## 11. 관련 문서

| 문서 | 내용 |
|------|------|
| [README.md](../README.md) | 「전 작품 사전」목표, 현재 엄선 단계 |
| [ROADMAP.md](../ROADMAP.md) | 출시·데이터 백로그 |
| [akasha-db-policy.md](akasha-db-policy.md) | 구축·운영·법무 마스터 |
| [canonicalization-policy.md](canonicalization-policy.md) | identity·dedupe 규칙 |
| [catalog-ownership.md](catalog-ownership.md) | 3계층·소유권 |
| [v4-migration-plan.md](v4-migration-plan.md) | **Steam 전 실행 계획** |
| [akasha-db/SCHEMA.md](../akasha-db/SCHEMA.md) | v3 현재 · v4 `wk_`·해시 샤드 |

---

*이전 v1 초안(엄선 레지스트리 한정·flat JSON·poster URL 제거)은 폐기했다. 본 v2가 제품 비전과 일치하는 기준선이다.*
