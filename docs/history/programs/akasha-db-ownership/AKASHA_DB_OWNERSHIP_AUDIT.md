# akasha-db 소유권·백업 구조 감사 (Read-only)

> **Archived:** 2026-07-19 — moved from `docs/draft/` (historical snapshot; not an active contract).
> **Open decision:** A/B/C 선택지는 본문에 보존. 현재 추적 상태는 [ULTIMATE_ARCHIVE_BACKLOG.md](../../../draft/ULTIMATE_ARCHIVE_BACKLOG.md) **D-004**.
> **일자:** 2026-06-30
> **지위:** Non-binding historical audit — 구조 감사·A/B/C **결정 전** (not an active contract) — **destructive 변경 없음**

> **상위:** [PROJECT_STATUS.md](../../closure-2026-07/PROJECT_STATUS.md) · [catalog-ownership.md](../../policy/catalog-ownership.md)
> **앱 repo tip:** `45f89b7` (`origin/main` 동기화)

---

## 1. Executive Summary

| 질문 | 답 |
|------|-----|
| **현재 구조는?** | **하이브리드** — 앱 repo에 **vendored in-tree copy**(1756파일 직접 추적) + 동일 경로에 **중첩 Git repo**(`akasha-db/.git` → `AIRA1346/akasha-db`) |
| **submodule인가?** | **아니오** — `.gitmodules` 없음 |
| **내부 repo dirty?** | **148 modified** (untracked 0) — 샘플 검증: shard **138/138**이 앱 repo `HEAD` blob과 **일치** |
| **앱 repo에 백업됐나?** | **예 (shard·인덱스 본문)** — `origin/main`에 커밋됨. 로컬만 dirty: **manifest 4종** (rebuild 산출물, 커밋 제외 관례) |
| **내부 remote 대비?** | 내부 `main` = `origin/main` @ `7a27249` — **working tree만** 앞섬 (push 안 된 로컬 diff) |
| **당장 할 일?** | ~~구조 변경 전 내부 repo diff 백업 branch push~~ → **✅ 완료** `backup/local-sync-20260630` @ **`bef52e7`** |

---

## 2. 이중 추적 구조

```
akasha/  (AIRA1346/akasha)
├── .git/                    ← 루트: akasha-db/** 1756 files 직접 tracked
├── assets/registry/         ← 앱 번들 sync 대상 (66 files tracked, manifest 별도)
└── akasha-db/
    ├── .git/                ← 중첩: origin → AIRA1346/akasha-db (submodule 아님)
    ├── manifest.json
    ├── search_index/**
    └── shards/{category}/*.json
```

### 2.1 분류

| 관점 | 판정 |
|------|------|
| 앱 빌드·CI 관점 | **Vendored catalog data** — `registry_builder --sync-assets`가 `akasha-db` → `assets/registry` 복사 |
| GitHub Pages / CDN 관점 | **별도 repo mirror** — `akasha-db` push → Pages 배포 ([README.md](../../../../README.md)) |
| Git 메타데이터 관점 | **비정규** — 동일 트리에 두 개의 독립 history (루트 vs 중첩) |

**결론:** “vendored copy + pipeline용 nested clone”에 가깝고, 정식 submodule/subtree는 **아님**.

### 2.2 앱 번들 vs 소스

| 경로 | 역할 | 루트 tracked |
|------|------|:------------:|
| `akasha-db/` | Tier 1 **소스** · pipeline · Pages | 1756 |
| `assets/registry/` | Flutter **앱 asset** (eager/lazy bundle) | 66+ |

로컬 rebuild 시 두 트리 모두 manifest가 갱신되나, **커밋 관례상 manifest 4파일만** unstaged로 둠:

- `akasha-db/manifest.json`
- `akasha-db/search_index/manifest.json`
- `assets/registry/manifest.json`
- `assets/registry/search_index/manifest.json`

---

## 3. 내부 `akasha-db` repo dirty 범위 (2026-06-30)

**기준:** `cd akasha-db && git status` · HEAD `7a27249` (`docs: README 10048 works`)

| 구분 | 파일 수 | 비고 |
|------|:-------:|------|
| **합계 modified** | **148** | untracked **0** |
| `shards/game/` | 92 | 전체의 **62%** |
| `shards/movie/` | 18 | |
| `shards/book/` | 13 | |
| `shards/drama/` | 11 | |
| `search_index/` (+ root `search_index.json`) | 8 | 카테고리별 인덱스 + manifest |
| `shards/manga/` | 2 | |
| `shards/animation/` | 2 | |
| `SCHEMA.md` | 1 | |
| `manifest.json` | 1 | |

**diff 규모:** `148 files changed, 633 insertions(+), 633 deletions(-)` — 대량 추가가 아니라 **기존 레코드 정합·메타 수정** 패턴.

### 3.1 앱 repo와의 관계 (핵심)

샘플: **138개 shard** 전부 `git rev-parse HEAD:akasha-db/<path>` == `akasha-db` working tree hash.

→ 내부 repo의 dirty shard 내용은 **이미 앱 repo `origin/main`에 커밋된 blob과 동일**합니다.
→ **데이터 유실 위험은 낮음** (앱 repo가 사실상 백업 역할).
→ **갭**은 `AIRA1346/akasha-db` remote가 앱 repo에 반영된 shard 갱신을 **아직 못 받은 것**.

manifest working hash는 앱 repo `HEAD` manifest와도 **다름** (최신 rebuild 산출물).

---

## 4. 루트 repo 백업 상태

| 항목 | 상태 |
|------|------|
| `git ls-files akasha-db` | **1756** |
| `origin/main` 동기화 | **예** (`45f89b7`) |
| 로컬 unstaged (akasha-db) | manifest 2종만 (`manifest.json`, `search_index/manifest.json`) |
| shard 본문 | **committed** on `origin/main` (내부 dirty와 일치) |

**판정:** 카탈로그 **본문 데이터는 앱 repo에 백업 완료**.
미백업/미동기화 채널: **`AIRA1346/akasha-db` Git remote** + 로컬 rebuild manifest 4종.

---

## 5. 장기 선택지 (결정 보류)

| ID | 방안 | 요약 | 장점 | 리스크 |
|:--:|------|------|------|--------|
| **A** | **Vendored 유지** + 내부 `.git` 제거/무시 | 앱 repo만 SSOT, `akasha-db/.git` 삭제 또는 `.gitignore` 처리 | 단일 history · CI 단순 | Pages 전용 repo workflow 재설계 필요 |
| **B** | **정식 submodule / subtree** | `akasha-db` → `AIRA1346/akasha-db` 고정 pointer | upstream 분리·CDN 파이프라인 명확 | 마이그레이션 비용 · 이중 커밋 습관 교체 |
| **C** | **현 구조 유지** + 주기 sync | 앱 repo + `akasha-db` repo **둘 다** push | 당장 변경 없음 | drift 재발 · “어느 쪽이 SSOT?” 혼란 지속 |

**이번 스프린트:** 위 결정 **보류**. 신규 기능·M3·Agent operation layer와 **병행하지 않음**.

**권장 조사 순서 (다음 단계):**

1. `AIRA1346/akasha-db`에 앱 repo shard 커밋을 **어떻게 반영할지** (cherry-pick vs 일괄 PR)
2. Pages 배포가 **어느 repo tip**을 따르는지 운영 확인
3. A/B/C 중 하나 선택 후 [catalog-ownership.md](../../policy/catalog-ownership.md)에 **단일 SSOT** 문장 추가

---

## 6. 백업 실행 내역 (2026-06-30)

**상태:** ✅ **완료** — `akasha-db/main`에는 push **하지 않음**.

| 항목 | 값 |
|------|-----|
| **Remote** | `https://github.com/AIRA1346/akasha-db.git` |
| **Branch** | `backup/local-sync-20260630` |
| **Commit** | **`bef52e7`** (`bef52e72b9e2cacfe46296f69bdb69d763fec41c`) |
| **Message** | `backup: local catalog sync snapshot 20260630` |
| **변경** | 148 files · +633 / −633 |
| **base** | internal `main` @ `7a27249` |

**PR:** merge **하지 않음** — backup branch로만 보존.
**다음:** `main` merge 여부는 구조 결정(§5) 후 별도 검토.

<details>
<summary>당시 실행 명령 (기록)</summary>

```bash
cd akasha-db
git checkout -b backup/local-sync-20260630
git add -A
git commit -m "backup: local catalog sync snapshot 20260630"
git push -u origin backup/local-sync-20260630
```

</details>

---

## 7. 리스크·관찰

| # | 리스크 | 완화 |
|---|--------|------|
| 1 | 개발자가 **어느 repo에 commit할지** 혼동 | 본 문서 + PROJECT_STATUS Watchlist **301** |
| 2 | `registry_builder`가 한쪽만 갱신 | rebuild 후 **루트 vs 중첩 status** 루틴 점검 |
| 3 | Pages CDN이 **구 akasha-db tip** 서빙 | backup push 후 Pages 빌드 SHA 확인 |
| 4 | 중첩 `.git`이 `git status` 상위에 **미표시** | audit 주기적 재실행 |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-30 | 초안 — read-only 구조 감사 · 148 dirty 분류 · 백업 branch 제안 |
| 2026-06-30 | 백업 실행 — `backup/local-sync-20260630` @ **`bef52e7`** pushed (`akasha-db` remote, **main 미변경**) |
