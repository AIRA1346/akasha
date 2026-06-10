# AKASHA Product Vision — Fact Index + Sanctum Archive

> **지위:** 제품·데이터 **최상위 SSOT** (정책·ROADMAP·스토어 카피의 북극성)  
> **갱신:** 2026-06-10 · Registry **430 works** · Steam v1 Q3 2026  
> **법무:** [data-policy.md](data-policy.md) · **구현:** [catalog_poster_policy.dart](../lib/config/catalog_poster_policy.dart)

---

## 1. 한 줄

**AKASHA = 텍스트 Fact 사전(찾기) + Sanctum vault(유저가 무한히 꾸미는 개인 아카이브)**

트래커·포스터 호스팅·미디어 DB가 아니다.

---

## 2. 두 계층

| | Tier 1 — AKASHA | Tier 2 — Sanctum vault |
|--|-----------------|------------------------|
| **누가** | Rune Atelier (큐레이션·CI) | **유저** |
| **저장** | `akasha-db` JSON (Git/CDN) | 로컬 `.md` + YAML + `posters/` |
| **목적** | 「이 작품이 무엇인지」 **발견** | 「나에게 무엇이었는지」 **기록** |
| **포스터·이미지** | ❌ **미제공** (플레이스홀더 UI) | ✅ URL · 로컬 파일 · 본문 삽입 |
| **감상·평점·상태** | ❌ | ✅ YAML + Markdown |
| **시놉·리뷰** | ❌ 외부 복제 | ✅ 유저 자유 작성 |
| **법적 포지션** | Fact 메타데이터만 배포 | UGC · 개인 기록 |

조인 키: `work_id` (`wk_…`). Tier 2는 Tier 1 Fact를 **덮어쓰지 않음**.

---

## 3. 유저 여정

```
검색/발견 → (글로벌 사전 | 내 볼트 | 직접 등록)
    ↓
아카이브 — 앱이 work_id 연결 .md 생성 (YAML 템플릿)
    ↓
이후 전부 유저 — Obsidian·Typora·메모장 등 자유 편집
    · poster: https://…  또는  posters/파일
    · rating, status, 명대사, 감상, 커스텀 YAML
    · Markdown 본문 — 무궁무진 (링크, 헤딩, 표, 임베드)
    ↓
앱 — 볼트 watch · 그리드/상세/나만의 서재 **뷰어 + 입력 보조**
```

---

## 4. Tier 1 — 저장하는 Fact (텍스트)

**Minimal Core** ([data-policy.md §1.2](data-policy.md#12-registry-minimal-core-필수-영구-저장)):

| 필드 | 비고 |
|------|------|
| `workId` | `wk_` 영구 ID |
| `title` / `titles.*` | 다언어 제목 |
| `category` · `domain` | taxonomy |
| `releaseYear` · `creator` | 사실 |
| `externalIds.*` | **식별 숫자만** — 이미지 fetch·attach ❌ |
| `aliases` | AKASHA 선별 |
| `tags` | (선택) 외부 장르 복붙 지양 |

**금지 (Tier 1):** `description`, `posterPath`, raw API blob, synopsis/overview, 이미지 바이너리.  
**설명·감상·시놉**은 Tier 2 Sanctum vault Markdown/YAML만.  
**CI:** `tier1_poster`, `tier1_description`, `data_policy_linter --strict`.

---

## 5. Tier 2 — Sanctum vault

### 앱이 제공 (v1)

- Sanctum vault 폴더 연동 · watch · 원자적 저장
- 작품 검색 (사전 + 볼트 + 신규)
- 아카이브 → `.md` 생성
- YAML front-matter 템플릿 (rating, status, …)
- AI YAML 붙여넣기 (신규 작품)
- 대시보드 · IP 1카드 · 나만의 서재 · 테마(IAP)

### 유저 소유 (무제한)

- **YAML:** `poster`, `rating`, `status`, 커스텀 키(보존)
- **본문 Markdown:** 감상·명대사·에피소드 메모·위키링크·이미지
- **파일:** `posters/` 로컬 이미지

앱은 파싱하는 필드를 UI에 반영하고, **본문은 점진적으로 더 풍부히 렌더** (v1.1+).

---

## 6. AKASHA가 하지 않는 것

- Tier 1 포스터·이미지 URL 큐레이션·hotlink 배포
- 외부 DB(TMDB/AniList) **미러링** · bulk ingest
- 사전 전체 `.md` 일괄 생성
- 유저 감상·평점의 **제공자** 역할
- WebView/자동 이미지 수집 (유저 대신 포스터 찾기)

---

## 7. Steam v1 범위

| In | Out |
|----|-----|
| 430+ Fact 사전 · 검색 · 플레이스홀더 그리드 | Tier 1 포스터 |
| Sanctum 연동 · 아카이브 `.md` | 앱 이미지 큐레이션 |
| YAML 기본 · 나만의 서재 · IAP 테마 | Discover · Timeline · Recall (v1.1) |

스토어: [m2-steam-store-page.md](m2-steam-store-page.md)

---

## 8. 장기 (철학 유지)

| 시점 | Tier 1 | Tier 2 |
|------|--------|--------|
| 2026 v1 | 430 · Fact only | Sanctum |
| 2027~ | 5k · Facts 확장 | 동일 |
| 2030~ | 500k · Pipeline | 동일 |

**변하지 않는 것:** Tier 1에 포스터·UGC를 넣지 않음. 성장 = **Fact 수** not **콘텐츠 호스팅**.

---

## 9. 관련 문서

| 문서 | 역할 |
|------|------|
| **본 문서** | 제품 북극성 |
| [data-policy.md](data-policy.md) | 필드·법무·CI |
| [catalog-ownership.md](catalog-ownership.md) | 3계층 소유 |
| [POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md) | v1 no-poster |
| [data-architecture-redesign.md](data-architecture-redesign.md) | 인프라·규모 (§1 poster는 본 문서 우선) |
| [ROADMAP.md](../ROADMAP.md) | 마일스톤 |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | 초안 — Fact-only Tier 1 + Sanctum user archive SSOT |
