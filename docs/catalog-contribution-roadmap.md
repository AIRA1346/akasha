# 카탈로그 기여·확장 로드맵

> **기준일:** 2026-06-08  
> **관련:** [akasha-db/contributions/README.md](../akasha-db/contributions/README.md) · [catalog-ownership.md](catalog-ownership.md) · [registry-growth-strategy.md](registry-growth-strategy.md) · [contribution-model-strategy.md](contribution-model-strategy.md)

---

## 1. 두 개의 파이프라인 (둘 다 필요)

| 파이프라인 | 역할 | 규모 |
|------------|------|------|
| **Contribution System** (지금) | 유저·운영자 **수정·소량 추가** 제안 | 보조, 품질 피드백 |
| **Catalog Expansion Pipeline** (장기) | 운영자·AI **대량 후보** → 검수 → Registry | **주력** (작품 확보 속도) |

**장기 경쟁력:** 유저 제안 UX보다 **수십만 작품을 넣을 수 있는 확장 파이프라인**이 더 중요할 가능성이 큼.

```
유저 제안만으로는 채우기 느림 (애니 2만 · 만화 20만 · 게임 100만 …)
→ 운영자 주도 + AI Candidate Generator 가 주력
→ 유저 Contribution 은 품질·누락 보완
```

### Catalog Expansion Pipeline (미래)

```
외부 카탈로그 / 메타 참고 (bulk Git 저장 금지 — 후보만)
  ↓
AI Candidate Generator
  ↓
AI 중복 검사 (dedupe_linter 연동)
  ↓
Maintainer 승인
  ↓
Registry (wk_ · hash shard)
```

---

## 2. Contribution — 서버비 0원 상태 관리

**원칙:** 제안 **상태도 GitHub(akasha-db) 안**에만 둔다. 앱은 Cloudflare CDN으로 **읽기만**.

```
GitHub akasha-db
  contributions/
    add/
      pending/ | accepted/ | rejected/ | merged/
    fix/
      pending/ | accepted/ | rejected/ | merged/
    status.json          ← 앱이 poll/sync
```

또는 각 JSON에 `"status": "accepted"` + 폴더 이동으로 이중 표현.

### status 생명주기

| status | 의미 |
|--------|------|
| `submitted` | 앱·유저가 제출 (로컬 또는 import 직후) |
| `ai_verified` | AI 검증 통과 (confidence 부여) |
| `accepted` | 운영자 승인 (merge 대기) |
| `rejected` | 반려 (사유 optional) |
| `merged` | 샤드 반영·push 완료 |

### 앱 동작 (v2+)

```
Cloudflare CDN
  ↓ GET contributions/status.json
앱 — 내 제안 id의 status 표시 (선택)
```

---

## 3. 구현 순서 (확정)

| # | 작업 | 상태 |
|---|------|------|
| **1** | **status 필드** + 스키마 v2 + GitHub 폴더 골격 | ✅ |
| **2** | Data Policy + `data_policy_linter` (Legal CI) | ✅ |
| **3** | Quality (`qualitySignals` → score/tier 파생) | ✅ |
| **4** | **Contribution → Quality Loop** (`merge_catalog_contribution`) | ✅ |
| **5** | posterSource 레거시 101건 정리 | ⏳ |
| **6** | Discovery (AniList 1채널) | ⏳ |
| **7** | Catalog Expansion Pipeline | ⏳ |

### Contribution → Quality Loop (구현됨)

```
fixWork 승인 (accepted)
  → merge_catalog_contribution --id <id> --apply
  → 필드별 qualitySignals 검증 신호 갱신
      posterPath    → posterVerified
      externalIds   → externalIdVerified
      description   → descriptionVerified
      franchise(Id) → franchiseVerified
  → 샤드 기록 + status → merged
  → registry_builder: qualityScore/Tier 재계산 + search_index 반영
  → 검색 랭킹 (score DESC) 자동 적용
```

**카운터 없음:** "몇 명이 고쳤나"(userFixCount) 대신 **"어떤 사실이 검증됐나"**(verified signals)만 원본으로 저장. score/tier는 파생값 유지.

---

## 4. 미래 전체 구조

```
[Contribution — 보조]
User → Queue → export → GitHub (status in repo)
                    ↓
              AI Validator → confidence
                    ├─ Auto-merge queue (high, fix·poster)
                    └─ Human review queue (add·연도·프랜차이즈)
                    ↓
              Registry

[Expansion — 주력]
External reference → AI Candidates → dedupe → Maintainer → Registry
```

---

## 5. Steam v1 범위

- 앱: 제안 생성 · 로컬 큐 · export · Issue URL
- akasha-db: `status` 필드 · 폴더 레이아웃 · `status.json` 골격
- **자동 merge · AI validator · 앱 status sync** — Steam 후
