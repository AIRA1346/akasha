# AKASHA 사전(akasha-db) 구축 정책

> **AKASHA는 남의 데이터베이스를 빌려 쓰지 않습니다.**  
> `akasha-db`는 Rune Atelier가 **직접 구축·검수**하는 작품 메타데이터이며,  
> **v1 Steam:** Tier 1(akasha-db)에는 **포스터 URL 없음** — 이미지는 유저 Sanctum vault만.  
> **필드·소스·법무 최상위:** [data-policy.md](data-policy.md) §0.3

**상태:** v2 방향 (2026-06)  
**현재 규모:** **430작** (G1 **~5k** 병행 확장 중)  
**운영:** [catalog-growth-charter.md](programs/catalog-growth-charter.md) — SD2.6 hold **해제**  
**장기 비전:** 세상의 **모든 작품 사전** — [data-architecture-redesign.md](strategy/data-architecture-redesign.md)

---

## 1. 한 줄 요약

| 항목 | 방침 |
|------|------|
| 메타데이터 | AKASHA가 직접 작성·큐레이션 (장기: Registry Pipeline) |
| 포스터 | **v1: Tier 1 미제공** · 유저 Sanctum vault만 |
| ID | **`wk_` 영구 불변** + `legacy_aliases` (전환 예정) |
| 확장 | 수동 PR + Pipeline + 사용자 직접 등록 |
| 금지 | API bulk → Git 영구 저장, Git 이미지 호스팅, 외부 DB 미러 |

---

## 2. 하지 않는 것

| ❌ | 이유 |
|----|------|
| AniList/TMDB 등 API **대량 수집 → Git 영구 저장** | 약관·법무 리스크 — AniList ingest **폐기** ([discovery-source-decision.md](discovery-source-decision.md)) |
| 온디맨드 API로 메타 **빌려오기** | 자체 DB 철학과 불일치; 없으면 사용자 등록 |
| **self-hosted** — 포스터 이미지를 `akasha-db`에 커밋 | 복제·공중송신의 **직접 주체**가 됨 |
| 사전 **전 작품**에 볼트 `.md` 생성 | 아카이브한 작품만 `.md` (희소) |
| 외부 시놉시스·설명 **복제** | Tier 1 `description` **금지** — Sanctum vault만 |
| flat `works/manga.json` 단일 파일 | 규모 커지면 재작업 — **샤딩 유지** |

---

## 3. 하는 것

### 3.1 메타데이터 (Tier 1 — 사전)

- **직접 작성:** 제목(`title` / `titles`), 연도, 카테고리, `aliases`, `tags`(선택)
- **금지 필드:** `description`, `posterPath` (v1 CI)
- **식별 참조:** `externalIds` (steam, tmdb, isbn 등) — **중복 탐지** (포스터 URL attach **금지**)
- **추가 경로:**
  1. 수동 큐레이션 PR — [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md)
  2. Registry Pipeline (장기) — extract → dedupe → shard → Git
  3. 사용자 직접 등록 — 앱 볼트 `.md` (아카이브한 작품만)

### 3.2 포스터 (v1 — Tier 2 Sanctum vault만)

- **Tier 1:** `posterPath` **저장·표시 안 함** — CI `tier1_poster`
- **Tier 2:** 유저 YAML `poster:` · vault `posters/` (개인 UGC)
- 앱: 사전 카드 = **플레이스홀더** · 아카이브 작품만 유저 이미지

### 3.3 작품 정체성 (최우선 과제)

데이터가 늘수록 검색보다 **identity·canonicalization**이 중요하다.

| 순위 | 과제 |
|------|------|
| 1 | `wk_` 영구 ID 체계 |
| 2 | 중복 제거·canonicalization 규칙 — [canonicalization-policy.md](../policy/canonicalization-policy.md) |
| 3 | 해시 샤딩 (`hash(wk_)%256`) |
| 4 | Registry Pipeline |
| 5 | AI 자동 수집 |

---

## 4. 포스터 (v1)

상세: [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) · [data-policy.md §0.3](data-policy.md#03-tier-1-포스터설명-미제공-v1-steam)

- **akasha-db PR:** `posterPath` **추가·유지 금지**
- **유저:** Sanctum vault에 URL 또는 `posters/` 파일
- **정리:** `dart run tool/strip_tier1_posters.dart --apply --sync-assets` · `dart run tool/strip_tier1_descriptions.dart --apply --sync-assets`

---

## 5. 데이터 3계층

```
Tier 0 — Identity     wk_ (불변) + legacy_aliases
Tier 1 — AKASHA Meta  title, titles, 연도, externalIds, tags (**description·posterPath v1 금지**)
Tier 2 — User Archive 볼트 YAML·posters/·Markdown (아카이브한 작품만, 희소)
```

- 사전 500k 작품 = **가상 카드** (md 없음, 검색 · 플레이스홀더)
- 아카이브 시에만 `.md` 생성
- Tier 2가 Tier 1을 **덮어쓰지 않음** (사전은 공용, 볼트는 개인)

---

## 6. CI·도구

| 도구 | 역할 |
|------|------|
| `ci_registry_check.dart` | bulk 금지, denylist URL, duplicate |
| `registry_builder.dart` | 샤드 검증, `search_index` 생성 |
| `franchise_linter.dart` | IP·다매체 일관성 |
| `dedupe_linter.dart` (계획) | 중복 후보 탐지 |

---

## 7. 확장 목표

| 시점 | 규모 |
|------|------|
| Steam v1 (2026) | **엄선 430작** (현재) |
| v4 해시 샤드 | 동일 430작, 인프라 전환 ✅ |
| 2027 Pipeline | 1k~10k/일 ingest |
| 장기 | **전 작품 사전** (수백만) — API borrow 아님 |

---

## 8. 관련 문서

| 문서 | 내용 |
|------|------|
| [data-policy.md](data-policy.md) | **데이터 권리·필드·소스** (최상위) |
| **이 문서** | 사전 **구축·운영** |
| [data-architecture-redesign.md](../strategy/data-architecture-redesign.md) | v2 아키텍처·ADR |
| [wikidata-spine-plan.md](../strategy/wikidata-spine-plan.md) | **Wikidata 1차 연동·Registry spine** |
| [v4-migration-plan.md](v4-migration-plan.md) | **Steam 전 v4 실행 계획** |
| [canonicalization-policy.md](../policy/canonicalization-policy.md) | identity·dedupe |
| [catalog-ownership.md](../policy/catalog-ownership.md) | 소유권·3계층 |
| `product-vision.md` (당시 문서 · 현재 파일 없음 · 후계: [VISION.md](../../active/VISION.md)) | **제품·Tier 1/2 SSOT (당시)** |
| [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) | v1 no-poster |
| [SCHEMA.md](../akasha-db/SCHEMA.md) | v4 `wk_`·해시 샤드 |
| [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md) | PR 절차 |

---

## 9. 구현·백로그

- [x] CI denylist, AniList bulk 제거
- [x] 430작 엄선, Tier 1 `posterPath` 제거, M1 dogfood
- [x] **Steam 게이트** — [v4-migration-plan.md](v4-migration-plan.md) Phase A~D ✅
- [ ] Registry Pipeline · AI 수집 (출시 후)
