# AKASHA Catalog Ownership Policy

> **AKASHA는 남의 데이터베이스를 빌려 쓰지 않습니다.**  
> `akasha-db`는 Rune Atelier가 **직접 구축·검수**하는 작품 메타데이터입니다.  
> **장기 목표:** 세상의 모든 작품 사전 — `data-architecture-redesign.md` (당시 경로 · 현재 문서: [ARCHITECTURE.md](../../active/ARCHITECTURE.md))  
> **필드·Discovery 법무:** [data-policy.md]](../data-policy.md)

---

## 1. 원칙

| ✅ 우리가 하는 것 | ❌ 하지 않는 것 |
|------------------|----------------|
| 사실 메타 직접 작성 (제목, 연도, 카테고리, 작가, ID) | AniList/TMDB 등 API **대량 수집·Git 영구 저장** |
| 수동 PR·Pipeline·큐레이션으로 사전 확장 | Tier 1 `description`·`posterPath` |
| 없으면 **사용자 직접 등록** | 온디맨드 API로 메타 **빌려오기** |
| 사용자 볼트 `.md`·`posters/` (아카이브한 작품만) | 사전 전 작품에 `.md` 일괄 생성 |

| **externalIds** (`steam`, `tmdb`, …) | Fact — 식별·중복 탐지용 (**포스터 URL attach 금지**) |

**감상·설명·포스터**는 Tier 2 Sanctum vault만 — `product-vision.md` (당시 문서 · 현재 파일 없음 · 후계: [VISION.md](../../active/VISION.md)).

---

## 2. akasha-db 3계층 (+ Tier 1.5)

```
Tier 0 — Identity     wk_ (불변) + legacy_aliases
Tier 1 — AKASHA Meta  title, titles, 연도, externalIds, tags (**description·posterPath v1 금지**)
Tier 1.5 — User Local catalog/user_entities.json — Fact only · wk_u_* ([user-local-catalog-policy.md](user-local-catalog-policy.md))
Tier 2 — User Archive 볼트 YAML·posters/ (아카이브한 작품만, 희소)
```

- 사전: 수십만 작품도 **가상 카드** (md 없이 검색 · **플레이스홀더**)
- 아카이브: 사용자가 선택한 작품만 `.md` 생성
- 앱 UI fusion: Tier 2가 Tier 1을 **덮어쓰지 않음**

---

## 3. 작품 추가 경로

1. **수동 큐레이션 PR** — [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md)
2. **Registry Pipeline** (장기) — AI extract → dedupe → Git
3. **사용자 직접 등록** — 앱에서 새 작품 (볼트 `.md`)
4. ~~API bulk 시드~~ — **금지**

---

## 4. 정체성·중복 (최우선)

| 순위 | 과제 | 문서 |
|------|------|------|
| 1 | `wk_` 영구 ID | `data-architecture-redesign.md` (당시 경로 · 현재 문서: [ARCHITECTURE.md](../../active/ARCHITECTURE.md)) |
| 2 | canonicalization·dedupe | [canonicalization-policy.md]](../policy/canonicalization-policy.md) |
| 3 | 해시 샤딩 | SCHEMA v4 |

자동 merge 금지 — Pipeline/CI는 **중복 후보만** 제시.

---

## 5. 포스터 (v1 — Tier 2만)

- **Tier 1 (akasha-db):** `posterPath` **금지** — [data-policy.md §0.3](data-policy.md#03-tier-1-포스터-미제공-v1-steam)
- **Tier 2 (Sanctum vault):** YAML `poster:` · `posters/` — [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md)

---

## 6. CI·도구

| 도구 | 역할 |
|------|------|
| `ci_registry_check.dart` | bulk 금지, denylist, duplicate |
| `registry_builder.dart` | 샤드 검증, search_index |
| `franchise_linter.dart` | IP·다매체 |
| `dedupe_linter.dart` (계획) | 중복 후보 |

---

## 7. 확장 목표

| 시점 | 규모 |
|------|------|
| Steam v1 (2026) | **엄선 ~410작** |
| 장기 | **전 작품 사전** (수백만) — API borrow 아님 |

---

## 8. 관련 문서

- [data-policy.md]](../data-policy.md) — **필드·소스·법무 최상위**
- [akasha-db-policy.md]](../akasha-db-policy.md) — 구축·운영
- [canonicalization-policy.md]](../policy/canonicalization-policy.md)
- [akasha-db/SCHEMA.md](../akasha-db/SCHEMA.md)
- [locale-catalog-policy.md](locale-catalog-policy.md)
- [commerce-boundary.md](commerce-boundary.md)
