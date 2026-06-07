# AKASHA 사전(akasha-db) 구축 정책

> **AKASHA는 남의 데이터베이스를 빌려 쓰지 않습니다.**  
> `akasha-db`는 Rune Atelier가 **직접 구축·검수**하는 작품 메타데이터이며,  
> 포스터는 **URL 링크 참조만** 사용합니다. (이미지 파일을 repo에 넣지 않음)

**상태:** v1 확정 방향 (2026-06)  
**현재 규모:** 325작 (AniList bulk 제거 완료)

---

## 1. 한 줄 요약

| 항목 | v1 방침 |
|------|---------|
| 메타데이터 | AKASHA가 직접 작성·큐레이션 |
| 포스터 | `posterPath`에 **https URL만** 저장 (hotlink) |
| 확장 | 수동 PR + 사용자 직접 등록 |
| 금지 | API bulk, Git 이미지 호스팅, 외부 DB 미러 |

---

## 2. 하지 않는 것

| ❌ | 이유 |
|----|------|
| AniList/TMDB 등 API **대량 수집 → Git 영구 저장** | 약관·법무 리스크 (bulk 제거 완료) |
| 온디맨드 API로 메타 **빌려오기** | 자체 DB 철학과 불일치; 없으면 사용자 등록 |
| **self-hosted** — 포스터 이미지를 `akasha-db`에 커밋 | 복제·공중송신의 **직접 주체**가 됨 → 1인 스튜디오에 가장 위험 |
| `posterProvenance` 전수 장부 (325작 `sourceUrl`·`license`·`verifiedAt`) | v1 리소스 과부하; **신규 PR도 필수 아님** |
| AniList 상업 라이선스 메일·API 의존 전제 | 빌리지 않으므로 불필요 |
| 외부 시놉시스·설명 **복제** | 메타는 자체 1~2문장만 |

---

## 3. 하는 것

### 3.1 메타데이터 (Tier 1 — 사전)

- **직접 작성:** 제목(`title` / `titles`), 연도, 카테고리, 짧은 설명(1~2문장), 태그
- **식별 참조만:** `externalIds` (steam app id, isbn 등 **숫자·코드**).  
  외부 ID로 메타·이미지를 **자동 가져오는 근거로 쓰지 않음**
- **추가 경로 (유일):**
  1. 수동 큐레이션 PR — [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md)
  2. 사용자 직접 등록 — 앱 볼트 `.md`

### 3.2 포스터 (링크만)

- JSON 필드: **`posterPath`** — `https://...` URL 문자열 또는 `null`
- **repo·앱 번들에 이미지 바이너리 없음** (`Image.network`로만 표시)
- 카테고리(만화·애니·게임·책·영화·드라마)마다 도구를 나누지 않고 **같은 필드·같은 규칙**
- 링크 실패 시 앱 **placeholder** (이미 구현)
- 사용자 볼트 `posters/`는 **개인 UGC**로 최우선 표시 (사전과 독립)

### 3.3 선택 메타 (v1 경량)

신규·기존 작품 모두 **필수 아님**. 여유 있을 때만:

```json
"extensions": {
  "posterSource": "steam_store | openlibrary | official | other"
}
```

---

## 4. 포스터 URL — 실무 규칙

상세 체크리스트: [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md)

### 4.1 우선 사용 (티어 A~B)

| 출처 | 예시 | 비고 |
|------|------|------|
| 공식 스토어·홍보 | Steam `store_item_assets` | 게임 |
| ISBN 메타 | Open Library 커버 | 도서 |
| 공식 보도·홍보 URL | 배급사·출판사 press | 확인된 경우만 |
| 메타 DB 이미지 URL | TMDB, (신중히) 기타 | **링크만**; 메타 bulk와 별개 |

### 4.2 v1에서 피할 것

| 구분 | 처리 |
|------|------|
| **신규 PR** | `justwatch`, AniList bulk 파이프라인 URL **금지** |
| **신규 PR** | `anilistcdn` 등 **금지 CDN** 추가 금지 (CI) |
| 불확실·깨진 링크 | `posterPath: null` — placeholder가 더 낫다 |

### 4.3 기존 325작

- Steam·Open Library 등 **동작하는 링크는 당분간 유지** 가능
- 금지 CDN·깨진 URL만 점진 정리 (일괄 325작 재검수 **하지 않음**)

### 4.4 법무 인식 (비변호사 의견)

- **링크만 저장** ≠ 저작권 면책. UI 표시는 여전히 회색 지대일 수 있음
- 다만 **이미지를 repo에 복제하지 않음**으로써, self-hosted 대비 **실무·리스크 균형**이 낫다는 판단
- 인디 트래커·스토어 앱에서 흔한 **URL 참조** 패턴과 정렬

---

## 5. 데이터 3계층

```
Tier 0 — Identity     workId (불변)
Tier 1 — AKASHA Meta  title, titles, 연도, description, posterPath(URL), tags
Tier 2 — User Archive 볼트 YAML·posters/ (사용자 소유, 사전과 독립)
```

- 앱 UI: Tier 2가 Tier 1을 **덮어쓰지 않음** (사전은 공용, 볼트는 개인)
- Registry CDN URL을 vault 마크다운에 **중복 저장하지 않음** (런타임 UI Fusion)

---

## 6. CI·도구

| 도구 | 역할 |
|------|------|
| `ci_registry_check.dart` | bulk 금지, **denylist URL** (justwatch, bulk seed 등) |
| `registry_builder.dart` | 샤드 검증, `search_index` 생성 |
| `purge_anilist_bulk.dart` | AniList bulk 제거 (1회성, 완료) |
| `sanitize_borrowed_metadata.dart` | borrowed poster·seedSource 정리 (범위는 정책에 따름) |

**v1 CI 원칙:** provenance JSON 강제 ❌ → **금지 목록만** 강제 ✅

---

## 7. 확장 목표

| 시점 | 규모 |
|------|------|
| v1 Steam | **엄선 ~300–500작** (현재 325) |
| 장기 | 커뮤니티 PR로 **자체 사전** 성장 (API borrow 아님) |

---

## 8. 관련 문서 (역할 분담)

| 문서 | 내용 |
|------|------|
| **이 문서** | 사전 **구축·운영·법무 방향** (마스터) |
| [catalog-ownership.md](catalog-ownership.md) | 소유권·3계층 요약 (이 문서 링크) |
| [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) | 포스터 URL 티어·기여 체크리스트 |
| [SCHEMA.md](../akasha-db/SCHEMA.md) | v3 필드·JSON 스키마 참조 |
| [locale-catalog-policy.md](locale-catalog-policy.md) | 다국어 제목·검색 |
| [commerce-boundary.md](commerce-boundary.md) | 유료 콘텐츠·코스메틱 경계 |
| [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md) | PR 절차 |

---

## 9. 구현·백로그

- [x] CI denylist (`tool/poster_url_policy.dart`, `poster_url_baseline.json`)
- [x] `catalog-ownership.md`·`POSTER_POLICY.md` 정렬
- [x] README / ROADMAP / CONTRIBUTING 반영
- [x] manifest 변경 시 `registry_cache` 자동 무효화 (앱)
- [x] 기존 `anilistcdn` URL 교체 완료 (127→0, TMDB/Open Library/Steam)
- [ ] 상세 진행: [akasha-db-implementation-plan.md](akasha-db-implementation-plan.md)
