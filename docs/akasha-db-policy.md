# AKASHA 사전(akasha-db) 구축 정책

> **AKASHA는 남의 데이터베이스를 빌려 쓰지 않습니다.**  
> `akasha-db`는 Rune Atelier가 **직접 구축·검수**하는 작품 메타데이터이며,  
> 포스터는 **URL 링크 참조만** 사용합니다. (이미지 파일을 repo에 넣지 않음)

> **필드·소스·법무 최상위:** [data-policy.md](data-policy.md) — Discovery ≠ DB Mirroring, Registry Minimal Core, 소스별 필드 분류

**상태:** v2 방향 (2026-06)  
**현재 규모:** **~410작** 엄선 (Steam v1)  
**장기 비전:** 세상의 **모든 작품 사전** — [data-architecture-redesign.md](data-architecture-redesign.md)

---

## 1. 한 줄 요약

| 항목 | 방침 |
|------|------|
| 메타데이터 | AKASHA가 직접 작성·큐레이션 (장기: Registry Pipeline) |
| 포스터 | `posterPath`에 **https URL만** 저장 (hotlink) |
| ID | **`wk_` 영구 불변** + `legacy_aliases` (전환 예정) |
| 확장 | 수동 PR + Pipeline + 사용자 직접 등록 |
| 금지 | API bulk → Git 영구 저장, Git 이미지 호스팅, 외부 DB 미러 |

---

## 2. 하지 않는 것

| ❌ | 이유 |
|----|------|
| AniList/TMDB 등 API **대량 수집 → Git 영구 저장** | 약관·법무 리스크 (bulk 제거 완료) |
| 온디맨드 API로 메타 **빌려오기** | 자체 DB 철학과 불일치; 없으면 사용자 등록 |
| **self-hosted** — 포스터 이미지를 `akasha-db`에 커밋 | 복제·공중송신의 **직접 주체**가 됨 |
| 사전 **전 작품**에 볼트 `.md` 생성 | 아카이브한 작품만 `.md` (희소) |
| 외부 시놉시스·설명 **복제** | 메타는 자체 1~2문장만 |
| flat `works/manga.json` 단일 파일 | 규모 커지면 재작업 — **샤딩 유지** |

---

## 3. 하는 것

### 3.1 메타데이터 (Tier 1 — 사전)

- **직접 작성:** 제목(`title` / `titles`), 연도, 카테고리, 짧은 설명(1~2문장), 태그
- **식별 참조:** `externalIds` (steam, tmdb, isbn 등) — **중복 탐지·포스터 URL 확보**에 활용 가능
- **추가 경로:**
  1. 수동 큐레이션 PR — [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md)
  2. Registry Pipeline (장기) — extract → dedupe → shard → Git
  3. 사용자 직접 등록 — 앱 볼트 `.md` (아카이브한 작품만)

### 3.2 포스터 (링크만)

- JSON 필드: **`posterPath`** — `https://...` URL 문자열 또는 `null`
- **repo·앱 번들에 이미지 바이너리 없음** (`Image.network`로만 표시)
- 카테고리마다 **같은 필드·같은 규칙**
- 링크 실패 시 앱 **placeholder**
- 사용자 볼트 `posters/`는 **개인 UGC**로 최우선 표시

### 3.3 작품 정체성 (최우선 과제)

데이터가 늘수록 검색보다 **identity·canonicalization**이 중요하다.

| 순위 | 과제 |
|------|------|
| 1 | `wk_` 영구 ID 체계 |
| 2 | 중복 제거·canonicalization 규칙 — [canonicalization-policy.md](canonicalization-policy.md) |
| 3 | 해시 샤딩 (`hash(wk_)%256`) |
| 4 | Registry Pipeline |
| 5 | AI 자동 수집 |

---

## 4. 포스터 URL — 실무 규칙

상세 체크리스트: [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md)

### 4.1 우선 사용 (티어 A~B)

| 출처 | 예시 | 비고 |
|------|------|------|
| 공식 스토어·홍보 | Steam `store_item_assets` | 게임 |
| ISBN 메타 | Open Library 커버 | 도서 |
| TMDB poster path | `image.tmdb.org` | 애니·영화 (링크만) |
| 공식 보도·홍보 URL | 배급사·출판사 press | 확인된 경우만 |

### 4.2 피할 것

| 구분 | 처리 |
|------|------|
| **신규 PR** | `justwatch`, AniList bulk 파이프라인 URL **금지** |
| **신규 PR** | `anilistcdn` 등 **금지 CDN** 추가 금지 (CI) |
| 불확실·깨진 링크 | `posterPath: null` |

### 4.3 법무 인식 (비변호사 의견)

- **링크만 저장** ≠ 저작권 면책. UI 표시는 여전히 회색 지대일 수 있음
- **이미지를 repo에 복제하지 않음**으로 self-hosted 대비 리스크 완화

---

## 5. 데이터 3계층

```
Tier 0 — Identity     wk_ (불변) + legacy_aliases
Tier 1 — AKASHA Meta  title, titles, 연도, description, posterPath(URL), tags
Tier 2 — User Archive 볼트 YAML·posters/ (아카이브한 작품만, 희소)
```

- 사전 500k 작품 = **가상 카드** (md 없음, 검색·포스터 즉시)
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
| Steam v1 (2026) | **엄선 ~410작** (현재) |
| v4 해시 샤드 | 동일 410작, 인프라 전환 |
| 2027 Pipeline | 1k~10k/일 ingest |
| 장기 | **전 작품 사전** (수백만) — API borrow 아님 |

---

## 8. 관련 문서

| 문서 | 내용 |
|------|------|
| [data-policy.md](data-policy.md) | **데이터 권리·필드·소스** (최상위) |
| **이 문서** | 사전 **구축·운영** |
| [data-architecture-redesign.md](data-architecture-redesign.md) | v2 아키텍처·ADR |
| [v4-migration-plan.md](v4-migration-plan.md) | **Steam 전 v4 실행 계획** |
| [canonicalization-policy.md](canonicalization-policy.md) | identity·dedupe |
| [catalog-ownership.md](catalog-ownership.md) | 소유권·3계층 |
| [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) | 포스터 URL |
| [SCHEMA.md](../akasha-db/SCHEMA.md) | v3 현재 · v4 계획 |
| [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md) | PR 절차 |

---

## 9. 구현·백로그

- [x] CI denylist, AniList bulk 제거
- [x] ~410작 엄선, `posterPath` in DB, M1 dogfood
- [ ] **Steam 게이트** — [v4-migration-plan.md](v4-migration-plan.md) Phase A~D
  - [ ] `assign_wk_ids.dart` + `id_registry.json`
  - [ ] 앱·볼트 `wk_` 호환
  - [ ] dedupe CI
  - [ ] 해시 샤딩 v4
- [ ] Registry Pipeline · AI 수집 (출시 후)
