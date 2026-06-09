# A5 Duplicate Resolution Review — 기존 3건 운영 결정

> **목적:** Pilot H2에서 발생한 **fuzzyTitle duplicate 3건**에 대한 **운영 결정** (실행 전).  
> **질문:** *「JoJo · Hunter×Hunter · Naruto — 무엇을 어떻게 정리해야 하는가?」*  
> **전제:** H2 **Continue** · `pre_insert_dedupe_gate` **신규 차단 확인** · Registry **407작**  
> **기준일:** 2026-06-09

**금지:** 본 문서는 **판단만** — merge · remove **미실행**.

**신호:** `dedupe_linter` **fuzzyTitle** — 동일 category · 정규화 제목 · releaseYear ±1.

---

## Executive Summary

| 작품 | wk_ (생존) | sub_ (중복) | merge | remove | **권장** |
|------|------------|-------------|:-----:|:------:|----------|
| **JoJo** | `wk_000000203` | `sub_animation_jojo-bizarre-adventure_2012` | **불필요** | **가능** | **sub_ 제거** |
| **Hunter×Hunter** | `wk_000000202` | `sub_animation_hunter-x-hunter_2011` | **불필요** | **가능** | **sub_ 제거** |
| **Naruto** | `wk_000000218` | `sub_animation_naruto_2002` | **불필요** | **가능** | **sub_ 제거** |

**한 줄:** 세 건 모두 **wk_가 이미 canonical**이고 `legacyIds`에 sub_ slug가 **등록됨**. sub_ 레코드는 Pilot **오삽입 stub** — **필드 흡수 merge 불필요**, **sub_ shard 키 제거**가 정합.

**정리 후 규모:** 407 → **404작** (중복 3건 제거) · dedupe fuzzyTitle **3 → 0** (예상).

---

## 공통 맥락

| 항목 | 내용 |
|------|------|
| **원인** | Pilot 1차 — `pre_insert_dedupe_gate` **이전** Maintainer 수동 v4 insert |
| **Phase 2 모델** | **wk_** 영구 ID · **sub_** → `legacyIds[]` 로 **흡수** (Phase A v4) |
| **현재 역설** | wk_가 sub_를 legacy로 **이미 보유**하는데 sub_가 **독립 shard 키**로 **재존재** |
| **franchise_groups** | 세 sub_ / 해당 wk_ **멤버 참조 없음** |
| **dedupe_exceptions** | `allowedPairs` **비어 있음** — 예외 등록 **비권장** |
| **retire_work_ids** | **wk_↔wk_** 전용 — sub_ 제거 **대상 아님** |

---

## 1. JoJo — 죠죠의 기묘한 모험

### 1.1 wk_ 레코드 상태

| 필드 | 값 |
|------|-----|
| **workId** | `wk_000000203` |
| **shard** | `akasha-db/shards/animation/35.json` |
| **releaseYear** | 2012 |
| **legacyIds** | `["sub_animation_jojo-bizarre-adventure_2012"]` |
| **externalIds** | `tmdb: 46393` |
| **qualitySignals** | `externalIdVerified` · `hasPoster` · `hasDescription` |
| **extensions** | `coverageSprint04ExternalId: tmdb` · seasons 1~6부 |
| **posterPath** | `.../dgjo0nFXKoOJ5y8NBMjYfsSdMmI.jpg` |

### 1.2 sub_ 레코드 상태

| 필드 | 값 |
|------|-----|
| **workId** | `sub_animation_jojo-bizarre-adventure_2012` |
| **shard** | `akasha-db/shards/animation/fc.json` (**단독 키**) |
| **releaseYear** | 2012 |
| **legacyIds** | **없음** |
| **externalIds** | **없음** |
| **qualitySignals** | **없음** |
| **posterPath** | wk_와 **동일 URL** |

### 1.3 차이점

| 구분 | wk_ | sub_ |
|------|-----|------|
| 식별자 체계 | 영구 `wk_` | 레거시 slug **독립 엔트리** |
| Sprint 04 enrich | **있음** | **없음** |
| externalId | **있음** | **없음** |
| 메타·포스터·시즌 | 동일 | 동일 (wk_ **부분집합**) |
| sub_ 고유 필드 | — | **없음** (wk_에 없는 필드 **0**) |

### 1.4 merge 가능 여부

| 판단 | **불필요 / 비해당** |
|------|---------------------|
| 근거 | wk_가 sub_의 **모든 표면형·메타**를 **이미 포함** · `legacyIds`에 slug **이미 등록** |
| `retire_work_ids` | wk_ 대상만 지원 — sub_ **미지원** |
| 흡수 merge | sub_ → wk_로 **추가할 필드 없음** |

### 1.5 remove 가능 여부

| 판단 | **가능** |
|------|----------|
| 근거 | wk_가 canonical · search·identity는 **wk_ 기준** 유지 |
| 부작용 | `fc.json` **단일 키** — 제거 후 **빈 샤드** 또는 파일 삭제 · `registry_builder` **필수** |
| id_registry | sub_를 **primary key**로 쓰는 흔적 **없음** (조사) |

### 1.6 권장 처리

**`sub_animation_jojo-bizarre-adventure_2012` shard 키 제거** — survivor **`wk_000000203`**.

---

## 2. Hunter×Hunter — 헌터×헌터

### 2.1 wk_ 레코드 상태

| 필드 | 값 |
|------|-----|
| **workId** | `wk_000000202` |
| **shard** | `akasha-db/shards/animation/06.json` |
| **releaseYear** | 2011 |
| **legacyIds** | `["sub_animation_hunter-x-hunter_2011"]` |
| **externalIds** | `tmdb: 46298` |
| **qualitySignals** | `externalIdVerified` · `hasPoster` · `hasDescription` |
| **extensions** | `coverageSprint04ExternalId: tmdb` |

### 2.2 sub_ 레코드 상태

| 필드 | 값 |
|------|-----|
| **workId** | `sub_animation_hunter-x-hunter_2011` |
| **shard** | `akasha-db/shards/animation/93.json` |
| **동 shard** | `wk_000000192` (불꽃 소방대) — **hash 충돌 공존** |
| **legacyIds / externalIds / qualitySignals** | **없음** |
| **posterPath** | wk_와 **동일 URL** |

### 2.3 차이점

| 구분 | wk_ | sub_ |
|------|-----|------|
| shard 배치 | `06.json` (wk_202·218 공존) | `93.json` (Fire Force와 **공존**) |
| enrich·externalId | **있음** | **없음** |
| 콘텐츠 | 2011판 148화 | **동일** |
| sub_ 고유 필드 | — | **없음** |

### 2.4 merge 가능 여부

**불필요 / 비해당** — JoJo와 동일. `legacyIds` **이미 연결**.

### 2.5 remove 가능 여부

| 판정 | **가능** |
|------|----------|
| 근거 | `93.json`에서 sub_ 키만 삭제 · **`wk_000000192` 유지** |
| 주의 | 동일 샤드 **다른 작품** — Hunter sub_만 **선별 제거** |

### 2.6 권장 처리

**`sub_animation_hunter-x-hunter_2011` shard 키 제거** — survivor **`wk_000000202`**.

---

## 3. Naruto — 나루토

### 3.1 wk_ 레코드 상태

| 필드 | 값 |
|------|-----|
| **workId** | `wk_000000218` |
| **shard** | `akasha-db/shards/animation/06.json` |
| **releaseYear** | 2002 |
| **legacyIds** | `["sub_animation_naruto_2002"]` |
| **externalIds** | `tmdb: 46260` |
| **titles.zh** | `火影忍者` |
| **aliases** | `["火影忍者"]` |
| **extensions** | `posterVerified: true` |
| **qualitySignals** | **없음** (Hunter·JoJo 대비 Sprint 04 블록 **미기재**) |

### 3.2 sub_ 레코드 상태

| 필드 | 값 |
|------|-----|
| **workId** | `sub_animation_naruto_2002` |
| **shard** | `akasha-db/shards/animation/f3.json` (**단독 키**) |
| **titles.zh / aliases** | **없음** |
| **externalIds** | **없음** |
| **posterPath** | wk_와 **동일 URL** |

### 3.3 차이점

| 구분 | wk_ | sub_ |
|------|-----|------|
| 중국어 표면형 | **zh + alias** | **없음** |
| externalId | **tmdb 46260** | **없음** |
| posterVerified | **true** | **없음** |
| sub_ 고유 필드 | — | **없음** — wk_가 **상위집합** |

### 3.4 merge 가능 여부

**불필요 / 비해당** — wk_가 sub_보다 **풍부**.

### 3.5 remove 가능 여부

| 판정 | **가능** |
|------|----------|
| 근거 | canonical wk_ · legacyIds **보존** |
| 부작용 | `f3.json` **단독 키** — 제거 후 빈 샤드 처리 |

### 3.6 권장 처리

**`sub_animation_naruto_2002` shard 키 제거** — survivor **`wk_000000218`**.

---

## 4. 비권장 대안

| 대안 | 이유 |
|------|------|
| **dedupe_exceptions 등록** | 의도적 별매체 **아님** — 진짜 중복 |
| **sub_ 유지 + wk_ retire** | Phase 2 wk_ canonical **퇴행** · externalId·enrich **wk_ 측** |
| **sub_ → wk_ 필드 merge** | sub_에 **wk_ 미보유 필드 없음** |
| **구조 변경** | 샤드 키 삭제만 — 스키마·ADR **불필요** |

---

## 5. 실행 체크리스트 (미실행 — 승인 후)

| # | 단계 |
|---|------|
| 1 | `animation/fc.json` — JoJo sub_ 키 삭제 |
| 2 | `animation/93.json` — Hunter sub_ 키만 삭제 (Fire Force **유지**) |
| 3 | `animation/f3.json` — Naruto sub_ 키 삭제 |
| 4 | 빈 샤드 파일 정리 (필요 시) |
| 5 | `registry_builder` |
| 6 | `dedupe_linter` — fuzzyTitle **0건** 확인 |
| 7 | `coverage_dashboard` · SW1 · URV — **회귀 없음** 확인 |
| 8 | Observation Log · Gate Record — **정리 완료** 기록 |

**예상:** 407 → **404작** · H2 dedupe **clean** (기존 3건).

---

## 6. 판정 요약

| # | 질문 | 답 |
|---|------|-----|
| 1 | 무엇이 canonical? | **wk_000000203 / 202 / 218** |
| 2 | sub_ 역할은? | **legacy slug** — 이미 `legacyIds`에만 있어야 함 |
| 3 | merge? | **아니오** — 흡수할 필드 없음 |
| 4 | remove? | **예** — sub_ **3키** |
| 5 | dedupe_exception? | **아니오** |

**운영 결정 (권장):** 세 건 모두 **sub_ 레코드 제거** · **wk_ 단일 생존**.

---

## 7. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-duplicate-resolution-review.md](a5-duplicate-resolution-review.md) | **본 문서** |
| [a5-pilot-observation-log.md](a5-pilot-observation-log.md) | 중복 발생 맥락 |
| [a5-pilot-gate-decision-record.md](a5-pilot-gate-decision-record.md) | H2 Continue |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 3건 조사·권장 (merge/remove 미실행) |
