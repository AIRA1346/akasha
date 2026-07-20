# akasha-db v4 마이그레이션 실행 계획 (Steam 출시 게이트)

> **결정 (2026-06-08):** Steam v1 출시 **전에** 데이터 아키텍처 v4 런타임을 완료한다.  
> **설계:** `data-architecture-redesign.md` (당시 경로 · 현재 문서: [ARCHITECTURE.md](../active/ARCHITECTURE.md)) · **정책:** [akasha-db-policy.md](akasha-db-policy.md)  
> **기준일:** 2026-06-08

---

## 0. 현재 상태

| 레이어 | 상태 | 비고 |
|--------|------|------|
| 설계·ADR·정책 문서 | ✅ | v2 확정, canonicalization-policy 포함 |
| 앱 기능 (M1) | ✅ | dogfood 통과, `master_archive`, ~410작 |
| **v4 런타임 코드** | ✅ Phase A~D | `wk_` 402작, dedupe CI ✅, manifest v4·해시 샤드 331버킷 |

**Steam 출시 게이트 = 아래 Phase A~D 완료 + dogfood 재검증.**

---

## 1. Steam 게이트 — 포함 / 제외

### ✅ 출시 전 필수 (Phase A~D)

| Phase | 내용 |
|-------|------|
| **A** | `wk_` 영구 ID + `id_registry.json` + `legacy_aliases` |
| **B** | 앱·볼트·CI — `wk_` 해석 (dual-ID: 옛 `sub_*` 병행) |
| **C** | canonicalization CI (`dedupe_linter`, 자동 merge 없음) |
| **D** | 해시 샤딩 v4 + manifest v4 + loader/builder/sync 전환 |

### 🔶 출시 전 권장 (시간 있으면)

| 항목 | 내용 |
|------|------|
| Pipeline 스켈레톤 | `tool/registry_pipeline/` 디렉터리·README·수동 ingest 스텁 |
| `franchise_groups` | members를 `wk_` 기준으로 정리 |

### ❌ 출시 후 (v4 게이트에 포함 안 함)

| 항목 | 시점 |
|------|------|
| AI 자동 수집 (일 1k~10k) | 2027~ |
| 50k+ CDN·R2·search_index 분리 | 2028~ |
| 카탈로그 수천~수만 작 확장 | Pipeline 본격화 후 |

---

## 2. `wk_` assign 도구란?

**`tool/assign_wk_ids.dart`** — 기존 작품에 영구 ID `wk_`를 일괄 부여하는 마이그레이션 스크립트.

### 왜 필요한가

현재 ID: `sub_manga_one-piece_1997` (슬러그·연도에 종속 → 메타 변경 시 조인 깨짐)  
목표 ID: `wk_000000042` (9자리, 한 번 부여 후 **절대 불변**)

### 하는 일

1. 모든 샤드 JSON에서 work 엔트리 수집 (현재 ~410작)
2. **전역 순번**으로 `wk_000000001` … 할당 (9자리 zero-pad, 최대 ~10억 작)
3. `akasha-db/id_registry.json` 생성 — `wk_` ↔ legacy `sub_*` 매핑
4. `legacy_aliases.json` 확장 — 앱·볼트가 옛 ID로도 `wk_` 해석
5. `--apply` 시 샤드 `workId`를 `wk_`로 교체 (`legacyIds` 필드에 옛 ID 보존)

### 이후

- 신규 작품: `registry_builder` 또는 Pipeline이 `nextWorkId`로 할당
- CI: `wk_` 중복·orphan alias·registry↔shard 불일치 검사

---

## 3. Phase 상세

### Phase A — `wk_` ID (예상 3~4일) ✅

| # | 작업 | 산출물 | 상태 |
|---|------|--------|------|
| A1 | 할당 규칙 확정 | 9자리 `wk_`, 전역 순번 (최대 999,999,999) | ✅ |
| A2 | `assign_wk_ids.dart` | dry-run / `--apply` | ✅ |
| A3 | `id_registry.json` | 410작 매핑 | ✅ |
| A4 | `legacy_aliases.json` | 전량 `sub_*` → `wk_` | ✅ |
| A5 | 샤드 `workId` 교체 | `legacyIds` 배열 유지 | ✅ |
| A6 | `id_registry_check.dart` | CI 연동 | ✅ |

**완료 기준:** `ci_registry_check` + 410/410 wk_ — **달성**

### Phase B — 앱·볼트 호환 (예상 3~4일)

| # | 작업 | 산출물 |
|---|------|--------|
| B1 | `WorkIdCodec` | `wk_` 파싱, `isWkId()` |
| B2 | `RegistryShardLoader` | alias → `wk_` resolve |
| B3 | 볼트 `.md` | 기존 `work_id` rename 없이 alias 해석 |
| B4 | `franchise_groups` | members `wk_` (또는 alias 경유) |
| B5 | 테스트 | `steam_v1_bundle_test` wk_ 케이스 추가 |

**완료 기준:** 옛 `sub_*` 볼트·검색·IP 카드 정상

### Phase C — Canonicalization CI (예상 2~3일) ✅

| # | 작업 | 산출물 | 상태 |
|---|------|--------|------|
| C1 | `dedupe_linter.dart` | `externalIds` exact + fuzzy title 후보 | ✅ |
| C2 | `ci_registry_check` 연동 | 후보 리포트, **자동 merge 금지** | ✅ |
| C3 | `retire_work_ids.dart` | 중복 8건 병합 → 402작 | ✅ |
| C4 | `franchise_groups` | `wk_` members 일관성 검증 | ✅ |

**완료 기준:** CI green, 중복 0건 — **달성** (402작)

### Phase D — 해시 샤딩 v4 (예상 5~7일) ✅

| # | 작업 | 산출물 | 상태 |
|---|------|--------|------|
| D1 | `migrate_shards_v3_to_v4_hash.dart` | `shards/{category}/{hh}.json` (sparse) | ✅ |
| D2 | manifest v4 | `version: 4`, `shardBits: 8`, `sha256` | ✅ |
| D3 | `registry_builder` | hash 키·v4 검증 | ✅ |
| D4 | `RegistryShardLoader` / `RegistrySyncService` | v4 manifest·sha256 증분 sync | ✅ |
| D5 | `ci_registry_check` | `manifest_v4_check` 연동 | ✅ |
| D6 | `--sync-assets` | 번들 331 sparse 버킷 / 402작 | ✅ |

**완료 기준:** 402작 dogfood, lazy sync, 검색·필터 동일 UX — **달성** (110 tests)

### Phase E — Steam 제출 (v4 완료 후, v4와 후반 병행 가능)

| # | 작업 |
|---|------|
| E1 | `main` push (akasha + akasha-db) |
| E2 | Steamworks 등록·빌드 업로드 |
| E3 | 스토어 페이지·IAP |
| E4 | v1 출시 |

---

## 4. 일정 (1인 · 2026 Q3 Steam 목표)

| 주차 | 초점 |
|------|------|
| **W1** | Phase A (`assign_wk_ids`) + Phase B 시작 |
| **W2** | Phase B 완료 + Phase C |
| **W3** | Phase D (해시 migrate + 앱 loader) |
| **W4** | dogfood · akasha-db push · Phase E (Steam) 착수 |
| **W5~6** | Steam 심사·출시 |

---

## 5. 체크리스트 (Steam 게이트)

```
[x] id_registry.json — 402작 wk_ 매핑
[x] legacy_aliases — sub_* → wk_ 전량
[x] WorkIdCodec + loader wk_ resolve
[x] dedupe_linter in CI
[x] manifest v4 + hash(wk_)%256 샤드 (331 sparse 버킷)
[x] registry_builder / ci_registry_check v4
[x] flutter test + dogfood_precheck green (110/110)
[ ] akasha-db GitHub push (Phase E)
```

---

## 6. 관련 문서

- `data-architecture-redesign.md` (당시 경로 · 현재 문서: [ARCHITECTURE.md](../active/ARCHITECTURE.md)) — 비전·ADR
- [canonicalization-policy.md](canonicalization-policy.md) — dedupe 규칙
- [ROADMAP.md](../ROADMAP.md) — 마일스톤
- [akasha-db/SCHEMA.md](../akasha-db/SCHEMA.md) — v4 필드
