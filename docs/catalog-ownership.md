# AKASHA Catalog Ownership Policy

> **AKASHA는 남의 데이터베이스를 빌려 쓰지 않습니다.**  
> `akasha-db`는 Rune Atelier가 **직접 구축·검수**하는 작품 메타데이터입니다.

---

## 1. 원칙

| ✅ 우리가 하는 것 | ❌ 하지 않는 것 |
|------------------|----------------|
| 사실 메타 직접 작성 (제목, 연도, 카테고리, 작가) | AniList/TMDB 등 API **대량 수집·Git 영구 저장** |
| 짧은 **자체 요약** (2~3문장) | 외부 시놉시스·설명 **복제** |
| 수동 PR·큐레이션으로 사전 확장 | 온디맨드 API로 메타 **빌려오기** |
| 없으면 **사용자 직접 등록** | 제3자 DB를 백업/스토리지로 사용 |
| 사용자 볼트 `.md`·`posters/` (UGC) | AniList 상업 라이선스·API 의존 전제 |

**외부 ID** (`externalIds.steam`, `isbn` 등)는 **식별 참조용 숫자**만 허용할 수 있습니다.  
메타·설명·이미지 URL을 가져오는 근거로 쓰지 않습니다.

---

## 2. akasha-db 3계층

```
Tier 0 — Identity     workId (불변)
Tier 1 — AKASHA Meta  title, titles, 연도, 짧은 description, tags (자체 작성)
Tier 2 — User Archive 볼트 YAML·posters/ (사용자 소유, 사전과 독립)
```

앱 UI fusion: Tier 2가 Tier 1을 **덮어쓰지 않음** (사전은 공용, 볼트는 개인).

---

## 3. 작품 추가 경로 (유일)

1. **수동 큐레이션 PR** — [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md)
2. **사용자 직접 등록** — 앱에서 새 작품 (볼트 `.md`)
3. ~~API bulk 시드~~ — **금지** (`purge_anilist_bulk`, CI 차단)

---

## 4. posterPath (사전)

- **링크만 저장** (`posterPath` = URL 문자열). repo·번들에 이미지 파일 **없음** (self-hosted ❌)
- 상세: [akasha-db-policy.md](akasha-db-policy.md), [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md)
- 신규 PR: 금지 CDN(justwatch, bulk 파이프라인, anilistcdn 등) **추가 금지** (CI)
- 불확실·깨진 링크: `posterPath: null` → 앱 placeholder
- 사용자 볼트 `posters/` (UGC)가 registry URL보다 **우선**

---

## 5. CI·도구

| 도구 | 역할 |
|------|------|
| `ci_registry_check.dart` | bulk 금지, borrowed poster 탐지 |
| `registry_builder.dart` | 샤드 검증 |
| `purge_anilist_bulk.dart` | AniList bulk 제거 (1회성) |
| `sanitize_borrowed_metadata.dart` | borrowed poster·seedSource 정리 |

---

## 6. 확장 목표

| 시점 | 규모 |
|------|------|
| v1 Steam | **엄선 ~300–500작** (현재 325) |
| 장기 | 커뮤니티 PR로 **자체 사전** 성장 (수백만은 목표이지 API borrow 아님) |

---

## 7. 관련 문서

- [akasha-db-policy.md](akasha-db-policy.md) — **사전 구축·포스터·CI 마스터**
- [akasha-db/SCHEMA.md](../akasha-db/SCHEMA.md)
- [locale-catalog-policy.md](locale-catalog-policy.md)
- [commerce-boundary.md](commerce-boundary.md)
