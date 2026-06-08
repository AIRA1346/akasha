# AKASHA 작품 정체성·중복 제거 (Canonicalization) 정책

> **상태:** 설계 초안  
> **기준일:** 2026-06-08  
> **상위 문서:** [data-architecture-redesign.md](data-architecture-redesign.md)

AKASHA가 커질수록 **검색보다** 아래 질문이 더 중요해진다.

1. **이 작품이 어떤 작품인가?** (identity)
2. **이미 있는 작품의 중복인가?** (dedupe)
3. **같은 IP의 다른 매체인가?** (franchise)

---

## 1. 식별자 계층

| 계층 | 필드 | 규칙 |
|------|------|------|
| **Canonical ID** | `wk_00001234` | **절대 불변**. 삭제·재사용 금지 |
| **Legacy ID** | `sub_manga_one-piece_1997` | `legacy_aliases.json`로 `wk_`에 영구 매핑 |
| **External ID** | `externalIds.tmdb`, `mal`, `steam` … | 중복 탐지·대조용 (자동 merge 근거 단독 사용 금지) |

---

## 2. 중복 vs 프랜차이즈 vs 별매체

| 관계 | 예 | 처리 |
|------|-----|------|
| **동일 작품 중복** | 같은 만화가 workId 두 개 | **금지** — 하나의 `wk_`만 유지, 나머지는 alias |
| **같은 IP, 다른 매체** | 원피스 만화 + 원피스 애니 | **별도 `wk_`** + `franchise_groups`로 IP 1카드 |
| **시즌/파트** | 애니 1기 vs 2기 | 기본 **동일 `wk_`** + `extensions.seasons` (별도 workId 남발 금지) |
| **리메이크/완전판** | FMA vs FMA:Brotherhood | **별도 `wk_`** (작품으로 구분) — human 판단 |

---

## 3. Dedupe 신호 (우선순위)

Pipeline·CI가 **후보**를 만들 때 참고하는 신호:

1. `externalIds` exact match (동일 tmdb/mal/steam/isbn)
2. `searchTokens` + `titles` fuzzy match (임계값 tunable)
3. 동일 `franchise` + 동일 `category` + 유사 `releaseYear`

**자동 merge는 하지 않는다.** 후보를 PR/리뷰 큐에 올린다.

---

## 4. Canonical record 규칙

하나의 `wk_`당 **canonical record** 1개.

- `titles`, `category`, `releaseYear`, `description` — **수정 가능**
- `wk_` — **수정 불가**
- 병합 시: survivor `wk_` 유지, loser는 `legacy_aliases`에만 남김

---

## 5. 사용자 볼트와의 관계

| 사전 | 볼트 `.md` |
|------|------------|
| 500k `wk_` 존재 가능 | 사용자가 아카이브한 것**만** `.md` (희소) |
| `posterPath` in DB | 선택적 `posters/` 로컬 덮어쓰기 |
| 가상 카드 (md 없음) | 아카이브 시 `.md` 생성 |

볼트 `work_id`는 한 번 할당되면 **alias로 `wk_` 해석** — 사용자 파일 rename 불필요.

---

## 6. CI·도구 (계획)

| 도구 | 역할 |
|------|------|
| `franchise_linter.dart` | 다매체 IP 미등록 탐지 |
| `dedupe_linter.dart` (신규) | externalId·fuzzy title 중복 후보 |
| `ci_registry_check.dart` | duplicate `wk_`, denylist URL |
| Registry Pipeline | ingest 전 dedupe gate |

---

## 7. 관련 문서

- [data-architecture-redesign.md](data-architecture-redesign.md)
- [akasha-db-policy.md](akasha-db-policy.md)
- [catalog-ownership.md](catalog-ownership.md)
