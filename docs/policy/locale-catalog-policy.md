# Locale & Catalog Policy

> AKASHA 글로벌 서비스 — 언어·작품명·검색 정책  
> 스키마: **akasha-db v3** (`manifest.version: 3`)

---

## 1. 식별 vs 표시 vs 검색 (3계층)

| 계층 | 필드 | 규칙 |
|------|------|------|
| **Identity** | `workId` | 불변. `{domain}_{category}_{identifier}_{year}` |
| **Display** | `titles`, `title` | UI·카드용. 로케일별 fallback |
| **Search** | `searchTokens` | `search_index.json`에만 저장. 빌드 시 생성 |

`workId`는 언어와 무관합니다. 표시·검색은 로케일 레이어가 담당합니다.

---

## 2. `titles` 스키마

```json
{
  "workId": "sub_manga_kimetsu-no-yaiba_2016",
  "title": "귀멸의 칼날",
  "titles": {
    "ko": "귀멸의 칼날",
    "en": "Demon Slayer: Kimetsu no Yaiba",
    "ja": "鬼滅の刃",
    "romaji": "Kimetsu no Yaiba",
    "native": "鬼滅の刃"
  },
  "aliases": ["KNY", "鬼滅"],
  "externalIds": {
    "anilist": "101922",
    "mal": "96792"
  }
}
```

### 태그 규칙

| 태그 | 용도 |
|------|------|
| `ko` | 한국어 정식/통용명 |
| `en` | 영어 정식/통용명 |
| `ja` | 일본어 표기 |
| `zh` | 중국어 간체/번체 (필요 시 `zh-Hans` 확장) |
| `romaji` | 로마자 |
| `native` | 원어 표기 (AniList `native`) |

- **`title`**: 하위 호환·정렬 키. v3 신규 시드는 `titles`의 primary와 동기화 권장.
- **`aliases`**: 약칭·구명·팬덤 통칭 (검색 전용).

---

## 3. 표시 제목 fallback

앱 로케일(`CatalogLocale`)별 우선순위:

| 로케일 | fallback chain |
|--------|----------------|
| `ko` | ko → en → ja → romaji → native → zh |
| `en` | en → romaji → ja → native → ko → zh |
| `ja` | ja → native → romaji → en → ko → zh |
| `zh` | zh → native → en → romaji → ja → ko |

코드: `WorkTitles.resolveForLocale()` / `resolveWorkDisplayTitle()`.

### 사용자 볼트와의 관계

| 출처 | 우선순위 | 비고 |
|------|----------|------|
| 볼트 `.md` `title` | **개인 아카이브** | 사용자가 바꾼 이름은 사전을 덮지 않음 |
| 사전 `displayTitle()` | 카탈로그·가상 카드·검색 서브타이틀 | 글로벌 표준 |
| franchise `displayNames` | IP 1카드 그리드 | `displayName` 레거시 유지 |

---

## 4. 검색 (`searchTokens`)

- `registry_builder`가 `title` + `titles` + `aliases` + `creator` + `tags`에서 생성
- 샤드 파일에 **저장하지 않음** — 인덱스만 갱신
- 정규화: 공백 제거 + 소문자 (`normalizeRegistryQuery`)

교차 언어 예: `titles.en = "Demon Slayer"`이면 한국어 UI에서도 `"demon slayer"` 검색 시 매칭.

---

## 5. `externalIds` (제휴·중복 제거)

| provider | 예시 |
|----------|------|
| `anilist` | AniList media id |
| `steam` | Steam App ID |
| `isbn` | 도서 ISBN |
| `igdb`, `tmdb`, `mal` | 장기 제휴용 |

레거시 `extensions.anilistId` 등은 파싱 시 자동 병합. 신규 시드는 `externalIds` 우선.

---

## 6. Franchise (`franchise_groups.json`)

```json
{
  "franchise_kimetsu": {
    "displayName": "귀멸의 칼날",
    "displayNames": {
      "ko": "귀멸의 칼날",
      "en": "Demon Slayer"
    },
    "members": ["..."],
    "primaryWorkId": "..."
  }
}
```

`displayName`은 레거시. `displayNames`가 있으면 `localizedDisplayName()` 사용.

---

## 7. 마이그레이션·도구

```bash
# 샤드에 titles/externalIds 승격 (점진)
dart run tool/migrate_registry_v3.dart

# search_index v3 재생성
dart run tool/registry_builder.dart --sync-assets
```

**AniList API bulk 시드는 금지** (`purge_anilist_bulk.dart`로 제거됨). 신규 작품은 수동 PR만.

---

## 8. 로드맵

| 단계 | 작업 |
|------|------|
| **지금 (v3 스키마)** | 코드·인덱스·정책 문서 |
| **v1.1** | Flutter ARB (`ko`/`en`), `CatalogLocaleScope` 시스템 연동 |
| **v1.2** | KO 메타 번역 배치, `locale_linter` |
| **장기** | 지역별 `primaryWorkId`, 설명·태그 로케일 샤드 |
