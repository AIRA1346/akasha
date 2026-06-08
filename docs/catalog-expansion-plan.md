# 작품 카탈로그 확장 계획 — 애니·만화 우선

> **목적:** akasha-db에 **인지도 높은 애니·만화**를 엄선 추가 (Steam v1 단계)  
> **전제:** [akasha-db-policy.md](akasha-db-policy.md) 법무·운영 방침 **절대 우선**  
> **아키텍처:** 장기 비전·`wk_`·Pipeline은 [data-architecture-redesign.md](data-architecture-redesign.md) 참고  
> **기준일:** 2026-06-08  
> **현재:** **~410작** (batch6 완료) — Steam v1 엄선 목표 달성

---

## 0. 한 줄 요약

| 할 일 | 하지 않을 일 |
|--------|----------------|
| 사람이 골라 **직접 쓴** 메타를 샤드 JSON에 넣기 | AniList/TMDB API로 **대량 수집 → Git 저장** |
| 포스터는 **https URL 한 줄**만 저장 (hotlink) | 이미지 파일을 repo·번들에 넣기 (self-hosted) |
| TMDB 등에서 URL을 **수동 확인·등록** | `anilistcdn`·justwatch 등 **금지 CDN** 신규 추가 |
| 설명은 **자체 2~3문장** | 위키·AniList 시놉 **복사** |

**지금 범위:** game·드라마·도서 확장은 **보류**. 애니·만화만 진행.

---

## 1. 법무·저작권 프레임 (가장 중요)

> 아래는 **변호사 자문이 아닌** 1인 스튜디오 실무 판단입니다.  
> Steam 상업 배포 전 필요 시 현지 IP 전문가 검토를 권장합니다.

### 1.1 AKASHA가 저장하는 것 vs 하지 않는 것

```
┌─────────────────────────────────────────────────────────────┐
│  akasha-db (Tier 1) — Rune Atelier가 직접 작성·검수        │
│  · workId, title/titles, creator, releaseYear, tags         │
│  · description (자체 요약 2~3문장)                         │
│  · posterPath (외부 이미지 URL 문자열만)                     │
│  · externalIds (숫자·코드 참조만 — 자동 fetch 근거 아님)    │
└─────────────────────────────────────────────────────────────┘
         │ hotlink at runtime              │ 사용자 볼트
         ▼                                 ▼
   Image.network(URL)              Tier 2 UGC (posters/, YAML)
   · 바이너리를 repo에 두지 않음    · 개인 소유, 사전과 독립
```

| 구분 | 법무·리스크 관점 | AKASHA 방침 |
|------|------------------|-------------|
| **메타 텍스트** (제목·작가·연도) | 사실 정보; **표현 복제**가 문제 | 사실은 참고서로 확인, **문장은 직접 작성** |
| **줄거리·설명** | 저작권 있는 창작 표현 | **자체 2~3문장만**; MAL/AniList/위키 **복붙 금지** |
| **포스터 이미지** | 저작권·상표가 있는 시각물 | **URL 링크만**; 파일 복제·배포 **금지** |
| **링크만 저장** | 면책이 아님 (회색 지대) | self-hosted보다 **리스크 낮음** (트래커·스토어 앱 관행) |
| **API bulk** | 제3자 약관 + 저작권 연쇄 | **금지** (AniList bulk 684작 제거 완료) |

### 1.2 작품 정보 수집 — 허용 워크플로

**원칙:** *참고(lookup)는 해도 되고, 가져와서 영구 저장(auto-ingest)은 안 된다.*

| 단계 | ✅ 허용 | ❌ 금지 |
|------|---------|---------|
| 1. 작품 선정 | 인지도·프랜차이즈 gap 등 **사람이 목록 작성** | 인기순 API top-N **자동 시드** |
| 2. 사실 확인 | AniList·MAL·위키·공식 사이트 **브라우저로 열람** | API/스크래퍼로 title·creator·plot **일괄 다운로드** |
| 3. 제목 | `titles.ko/en/ja/romaji` **직접 입력** (정식·통용명) | AniList `description` 필드 **복사** |
| 4. 설명 | 본인이 읽고 **2~3문장 재서술** | 영문/일문 시놉 **그대로 번역·붙여넣기** |
| 5. externalIds | `"anilist": "12345"` **숫자만** (식별·검색 보조) | ID로 런타임/빌드 시 메타·이미지 **자동 pull** |
| 6. JSON 반영 | `seed_expansion_batch5.dart`에 **손으로 작성한** 엔트리 | 스크립트가 API 응답을 **그대로 shard에 merge** |

**externalIds 사용 한계 (재확인)**

- AniList/MAL ID는 “이 작품이 무엇인지” 사람·도구가 **대조**할 때만 쓴다.
- ID가 있어도 **설명·포스터를 API에서 채우지 않는다** (정책상 앱·빌드 모두).

### 1.3 포스터 표시 — 허용 워크플로

**원칙:** *이미지 파일을 우리가 호스팅·배포하지 않는다. 런타임에 제3자 URL을 **참조**만 한다.*

| 계층 | 동작 |
|------|------|
| **저장 (akasha-db)** | `posterPath`: `"https://…"` 문자열 **또는** `null` |
| **앱 표시** | `Image.network(posterPath)` — **네트워크 로드만** (repo·번들에 이미지 없음) |
| **실패 시** | placeholder (이미 구현) |
| **사용자 볼트** | `posters/` 로컬 파일이 registry URL보다 **우선** (UGC) |

#### 애니·만화 포스터 출처 티어

| 티어 | 출처 | 애니 | 만화 | 등록 방법 |
|------|------|:----:|:----:|-----------|
| **A** | 공식 보도·배급·출판 홍보 URL | ○ | ○ | 브라우저에서 **직접 URL 복사** (안정성 확인) |
| **B** | [TMDB](https://www.themoviedb.org) `image.tmdb.org` | ○ (TV/극장판) | △ (일부만) | 작품 페이지 → 포스터 → **이미지 URL 수동 복사** |
| **B′** | [AniList](https://anilist.co) 페이지 | ○ (대조용) | ○ (대조용) | **페이지는 참고만**; CDN URL은 아래 금지 |
| **C** | Wikimedia (라이선스 확인) | △ | △ | Commons 라이선스 **눈으로 확인** 후 URL |
| **—** | 불확실 | — | — | **`posterPath: null`** (placeholder가 더 안전) |

#### 포스터 — 절대 금지 (CI·정책)

| 금지 | 이유 |
|------|------|
| `anilistcdn` URL **신규 추가** | increment denylist — baseline 0 초과 시 CI 실패 |
| `justwatch.com` | absolute denylist |
| 구글 이미지 검색 **임의 URL** | 출처·권리 불명 |
| `akasha-db/posters/` 등 **self-hosted** | 복제·재배포 주체가 됨 |
| 만화 작품에 **애니 시즌 커버** (매체 불일치) | 사용자 혼동 + 부정확 |
| 스크립트가 TMDB/AniList API로 **포스터 URL 일괄 수집** | API borrow + bulk 금지 |

#### TMDB 포스터 — 실무 주의 (애니·만화)

- **허용:** 큐레이터가 TMDB에서 작품·매체를 **눈으로 확인**한 뒤, 해당 작품의 poster path를 **수동**으로 JSON에 기입.
- **주의:** TMDB 약관·이미지 권리는 TMDB·권리자에게 있음. AKASHA는 **링크 참조**만 하며, 이미지를 **다운로드·재호스팅하지 않음**.
- **만화:** TMDB 커버가 없거나 부정확한 경우가 많음 → **null 허용**, 억지로 애니 커버를 끼우지 않음.

#### AniList — 실무 주의

- **허용:** 작품 매칭·`externalIds.anilist` 숫자, 제목 철자 대조.
- **금지:** AniList API bulk, `s4.anilistcdn/file/...` URL 신규, description/시놉 복사.
- 상업 라이선스 메일·API 의존 **전제하지 않음** (정책: 빌리지 않음).

### 1.4 앱·Steam 배포 시 인식

| 노출 | 설명 |
|------|------|
| 카드 그리드 | 외부 URL 포스터 **썸네일 표시** (회색 지대 — 링크만으로 완전 면책 아님) |
| 상세 | 사용자 작성 `review`·`memorableQuotes`는 **Tier 2 볼트** (사전과 분리) |
| 완화 요소 | self-hosted 없음, 시놉 복제 없음, bulk 없음, denylist CI |

---

## 2. 현홹 — 애니·만화만

```bash
dart run tool/catalog_stats.dart
dart run tool/ci_registry_check.dart
```

| 카테고리 | 현재 | 비고 |
|----------|-----:|------|
| manga | 72 | TMDB 포스터 다수 |
| animation | 43 | TMDB·일부 Steam |
| **합계** | **115** | 전체 325의 35% |

포스터 호스트 (전체 325 기준): TMDB 149, Steam 132 — 애니·만화 신규는 **TMDB 우선**, 없으면 null.

---

## 3. 목표 (애니·만화만)

| 마일스톤 | manga | animation | 합계 | 총 카탈로그 |
|----------|------:|----------:|-----:|------------:|
| **현재** | 72 | 43 | 115 | 325 |
| **AM1** (1차) | 95 (+23) ✅ | 65 (+22) ✅ | 180 (+45) ✅ | **370** ✅ |
| **AM2** (2차, ~4주) | 115 (+20) | 85 (+20) | 200 (+40) | ~410 |
| **AM3** (v1 상한) | 130 (+15) | 100 (+15) | 230 (+30) | ~450 |

- **AM1만 먼저** 진행 권장: +45작, 배치 2회 (각 20~25작).
- game·drama 등은 AM3 이후 또는 별도 계획.

---

## 4. 큐레이션 기준 (인지도)

**포함**

- 한국·일본에서 **통용명이 분명한** 대작·화제작
- 이미 카탈로그에 **같은 IP의 다른 매체**가 있으면 짝 맞추기 (만화↔애니)
- 완결·연재 중 모두 가능 (단 workId에 연도 반영)

**제외 (1차)**

- 중복 workId·동일 IP 무분별 시즌 남발 (시즌은 **별 workId** + 수동 판단)
- 포스터·설명을 **합법적으로 넣을 수 없는** 작품 → 목록에서 보류
- 성인·극단적 등급 작품 (Steam 심사·브랜드 — 별도 기준 필요 시)

---

## 5. AM1 후보 목록 (45작 — 검수 전 초안)

> **아직 샤드에 넣지 않음.** 반영 전 workId 중복·포스터 수동 확인 필수.

### animation (+22)

| 제목 (ko) | 비고 |
|-----------|------|
| 체인소 맨 | TV |
| 주술회전 2기 | 시즌 분리 여부 검토 |
| 최애의 아이 | |
| 보치 더 록! | |
| 약사의 혼잣말 | |
| 던전밥 | |
| 무창의 프리렌 | |
| 다다다 | |
| 승리의 여신에게 | |
| 패러독스 블루 | |
| 과학적인 애가 다가온다 | |
| 이세계 식당 2 | |
| 스파이 패밀리 2기 | |
| 좀비랜드 사가 리벤지 | |
| 릴리아나, 이 세계에 축복을 | |
| 야마다를 단둘이 | |
| 16bit 센세이 | |
| 사야카 일기 | |
| 기동전사 건담 수성의 마녀 | |
| 오버로드 4 | |
| 무직전생 2 | |
| 마슐 2기 | |

### manga (+23)

| 제목 (ko) | 비고 |
|-----------|------|
| 원펀맨 | |
| 블루 록 | |
| 사카모토 데이즈 | |
| 신석기양 | |
| 루드크로스 | |
| 귀환자의 마법은 특별해야 합니다 | |
| 텐슬ava | |
| 페어리 테일 100년 퀘스트 | |
| 진격의 거인 (만화 완결) | IP 중복 검사 |
| 도쿄 구울 :re | |
| 약사의 혼잣말 (만화) | 애니와 별도 workId |
| 비스타즈 | |
| 하이큐!! (만화) | |
| 테슬라 노트 | |
| 스파이 패밀리 (만화) | |
| 체인소 맨 (만화) | |
| 던전밥 (만화) | |
| 사이버펑크 엣지러너 (만화) | 없으면 스킵 |
| 강철의 연금술사 (완전판) | 중복 검사 |
| 원피스 (에피소드 단위 X, 단일 엔트리 정책 유지) | 이미 있으면 스킵 |
| 나루토 | 중복 검사 |
| 주술회전 (만화) | |
| 귀멸의 칼날 (완결권 등) | 중복 검사 |

---

## 6. 작업 파이프라인 (1배치 = 1 PR)

### 6.1 사람 큐레이터 체크리스트 (작품 1건)

**메타**

- [ ] workId 마스터 규칙 (`sub_{manga|animation}_{slug}_{year}`)
- [ ] 기존 샤드와 **중복 없음** (`registry_builder` / grep)
- [ ] `title` + `titles` (ko, en, ja 최소)
- [ ] `creator`, `releaseYear`, `tags` (3~5개)
- [ ] `description` **직접 작성** 2~3문장 (복붙 금지)
- [ ] `externalIds` (선택, 숫자만)

**포스터**

- [ ] 매체 일치 (만화≠애니 커버)
- [ ] URL `https://` (금지 CDN 아님)
- [ ] 브라우저에서 이미지 **한 번 열어 확인**
- [ ] 불확실하면 `null`

**CI**

- [ ] `dart run tool/ci_registry_check.dart`
- [ ] `dart run tool/registry_builder.dart --sync-assets`

### 6.2 도구 사용 경계

| 도구 | 용도 | 금지 사용 |
|------|------|-----------|
| `seed_expansion_batch5.dart` | **손 작성** 시드 배열을 샤드에 insert | API 응답을 시드에 **자동 채우기** |
| `migrate_anilistcdn_posters.dart` | 레거시 URL 교체 (완료) | 신규 anilistcdn 추가 |
| TMDB/AniList 웹 | 사람이 lookup | headless scrape → JSON |

### 6.3 배치 일정 (AM1)

| 주차 | 배치 | 추가 | 누적 (ani+man) |
|------|------|-----:|---------------:|
| 1 | batch5a | +22 animation | 137 |
| 2 | batch5b | +23 manga | 180 |

각 배치: JSON 작성 → CI → dogfood 10작 spot check → akasha-db push → assets sync.

---

## 7. 작품 1건 JSON 예시 (합법 패턴)

```json
{
  "workId": "sub_animation_oshinoko_2023",
  "title": "최애의 아이",
  "titles": {
    "ko": "최애의 아이",
    "en": "Oshi no Ko",
    "ja": "【推しの子】",
    "romaji": "Oshi no Ko"
  },
  "aliases": ["推しの子"],
  "category": "animation",
  "domain": "subculture",
  "creator": "… (직접 기입)",
  "releaseYear": 2023,
  "description": "자체 작성 2~3문장. 플롯 복사 금지.",
  "tags": ["음악", "연예", "미스터리"],
  "posterPath": "https://image.tmdb.org/t/p/w500/……",
  "externalIds": { "anilist": "150672" },
  "extensions": { "posterSource": "tmdb" }
}
```

- `description`: AniList `description`을 **보지 않고** 쓰거나, 봐도 **완전히 다른 문장**으로 재작성.
- `posterPath`: TMDB 작품 페이지에서 **수동**으로 복사한 path.
- `extensions.posterSource`: 선택 (v1 provenance 장부 대체).

---

## 8. 리스크 매트릭스 (애니·만화)

| 시나리오 | 리스크 | 대응 |
|----------|--------|------|
| 시놉시스 MAL 복붙 | 높음 (저작권) | 자체 요약만 |
| anilistcdn 신규 | 높음 (정책+CI) | TMDB 또는 null |
| TMDB API 스크립트 | 높음 (약관+bulk) | 수동 URL만 |
| TMDB URL hotlink | 중간 (관행) | 링크만, self-hosted 금지 |
| poster null | 낮음 | placeholder |
| externalIds만 저장 | 낮음 | 자동 fetch 금지 유지 |

---

## 9. 즉시 다음 액션

1. **이 계획 확정** — AM1 (+45) 범위 OK 여부  
2. `tool/seed_expansion_batch5.dart` 생성 — **수동 시드 배열만** (API 없음)  
3. **batch5a** animation 22작 — 메타·포스터 **전건 수동 작성**  
4. CI + `--sync-assets` + dogfood  
5. **batch5b** manga 23작 — 동일

---

## 10. 관련 문서

| 문서 | 역할 |
|------|------|
| [akasha-db-policy.md](akasha-db-policy.md) | 마스터 (bulk·self-hosted·링크만) |
| [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) | 포스터 티어·체크리스트 |
| [catalog-ownership.md](catalog-ownership.md) | 3계층·소유권 |
| [locale-catalog-policy.md](locale-catalog-policy.md) | titles·검색 |
| [CONTRIBUTING.md](../akasha-db/CONTRIBUTING.md) | PR 절차 |

---

## 11. 확인 질문

1. **AM1 (+45)** 로 먼저 갈까요, 아니면 첫 배치 **+20**만 파일럿할까요?  
2. TMDB 포스터 없는 만화는 **null 비율**을 어느 정도까지 허용할까요? (예: 30% null OK)  
3. 시즌·기 (주술회전 2기 등)를 **별 workId**로 넣을지, 1작품 1카드로 합칠지?
