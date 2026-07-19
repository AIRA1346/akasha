# Legacy Removal Policy — Foundation F4

> **일자:** 2026-06-25
> **지위:** active removal-gate contract — `TODO(remove)` 9건 제거 조건 SSOT
> **상위:** [FOUNDATION_AUDIT.md](../history/closure-2026-07/foundation/FOUNDATION_AUDIT.md) · [vault-layout-v2.md](../history/product/vault-layout-v2.md)
> **원칙:** [vault-layout-v2 §2 V1](../history/product/vault-layout-v2.md) — **Breaking migration 없음**

---

## 1. Executive Summary

| 항목 | 결정 |
|------|------|
| `TODO(remove)` 건수 | **9건** (6파일) |
| **M3 Steam v1.0** | **전부 유지** — 제거 PR 없음 |
| Works 레이아웃 기본값 | **`false` 유지** (v1.2+ 검토) |
| `legacy_aliases.json` | **889건** — 해석 경로 **필수 유지** |
| 레거시 볼트 경로 읽기 | **영구 지원** (이동 강제 없음) |

**판단:** F4는 **제거 일정·게이트 확정**이 목표다. 코드 삭제는 각 게이트 통과 후 **별도 PR**로 진행한다.

---

## 2. Works 레이아웃 정책 (Vault Layout)

### 2.1 현재 동작

| 설정 | 키 | 기본값 | 신규 저장 경로 |
|------|-----|:------:|----------------|
| Works 레이아웃 | `akasha_vault_use_works_layout` | **`false`** | `false` → `{vault}/{category}/` · `true` → `{vault}/works/{category}/` |

- 구현: `VaultWorkJournalPaths`, `UserPreferences`, `FileService._ensureVaultDirs`
- **기존 `filePath`는 항상 우선** — 저장 시 경로 강제 이동 없음 ([vault-layout-v2 §3.1](../history/product/vault-layout-v2.md))
- UI 노출: 없음 (SharedPreferences·테스트만 설정) — v1.1+ 설정 화면 후보

### 2.2 기본값 `true` 전환 조건 (L1)

**대상:** `user_preferences.dart` `isVaultWorksLayoutEnabled()` 기본값

| # | 게이트 | 검증 |
|---|--------|------|
| G1 | Steam v1.0 dogfood **B1 완료** | Sprint B1 §5 체크리스트 |
| G2 | 신규 유저 온보딩에서 works 경로 **문서화** | vault-layout-v2 사용자 안내 |
| G3 | **v1.2 마일스톤** 합의 | PROJECT_STATUS · release-readiness |

**결정 (2026-06-25):** v1.0 출시 전 기본값 **`false` 고정**. v1.2에서 G1~G3 재평가.

### 2.3 레거시 경로 코드 제거 조건 (L2~L5)

**대상:** `vault_work_journal_paths.dart` (2) · `file_service.dart` (1)

| # | 게이트 | 검증 |
|---|--------|------|
| G4 | 기본값 `true` 전환 **배포 완료** | L1 충족 후 1 릴리즈 |
| G5 | 선택적 **일괄 마이그레이션 도구** (opt-in) 또는 공식 가이드 | `tool/migrations/` 또는 문서 |
| G6 | dogfood·테스트에서 legacy-only 신규 저장 **0건** 2연속 릴리즈 | B1 회귀 + vault_archive_test |
| G7 | `resolveDeleteCandidates` legacy 후보 제거 시 **삭제 회귀 테스트** green | `vault_archive_test.dart` |

**결정:** G4~G7 전부 충족 전까지 `{vault}/{category}/` 분기 **삭제 금지**. 읽기·삭제 후보 경로는 레거시 볼트 호환을 위해 **마지막에 제거**.

---

## 3. Registry 레거시 정책

### 3.1 `legacy_aliases` 슬러그 해석 (R1)

**대상:** `registry_shard_loader.dart` — `bundledLegacyAliasesAsset` · `_legacyAliases`

| 항목 | 실측 (2026-06-25) |
|------|-------------------|
| 번들 alias 수 | **889** |
| 볼트 `work_id` | `sub_*` · 커스텀 슬러그 혼재 가능 |

| # | 게이트 | 검증 |
|---|--------|------|
| G8 | 번들 `legacy_aliases.json` **0건** (또는 read-only 아카이브 분리) | ci_registry_check |
| G9 | 프로덕션 alias resolve **히트율 0** 2연속 릴리즈 | (미구현 — v1.2+ telemetry 후보) |

**결정:** G8 미충족 — **M3 이후에도 유지**. `wk_` 전환은 샤드·search_index 완료, **볼트 조인은 alias로 영구 지원** ([ARCHITECTURE.md](../active/ARCHITECTURE.md) §Identity).

### 3.2 Monolithic JSON 캐시 (R2~R4)

**대상:** `works_registry.dart` (2) · `registry_shard_loader.dart` `mergeLegacyMonolithicJson` · `registry_sync_service.dart` `clearLegacyRegistryCache` / `readCachedRegistry`

| 파일 | 역할 |
|------|------|
| `local_works_registry.json` | v3 이전 단일 파일 캐시 (app documents) |
| `mergeLegacyMonolithicJson` | 구 캐시 → 샤드 엔트리 병합 |

| # | 게이트 | 검증 |
|---|--------|------|
| G10 | v4 샤드 캐시가 **모든 플랫폼** bootstrap 경로 | registry_shard_loader 테스트 |
| G11 | 신규 설치·업그레이드 후 `local_works_registry.json` **미생성** 2연속 릴리즈 | 수동·스테이징 |
| G12 | `mergeLegacyMonolithicJson` 제거 PR 시 **회귀 테스트** | works_registry · registry 통합 테스트 |

**결정:** G10 ✅ (현재 경로). G11 미확인 — **v1.0 유지**, M3+2 릴리즈 후 R2~R4 일괄 제거 검토.

**동시 제거 규칙:** `mergeLegacyMonolithicJson` 호출부(works_registry 2곳)와 `clearLegacyRegistryCache` / `readCachedRegistry`는 **같은 PR**에서 제거.

---

## 4. 제거 조건표 (9건 ↔ 코드)

| ID | 파일 | TODO 위치 | 제거 게이트 | 최조 목표 |
|:--:|------|-----------|-------------|-----------|
| **L1** | `user_preferences.dart` | `isVaultWorksLayoutEnabled` 기본값 | §2.2 G1~G3 | v1.2 |
| **L2** | `vault_work_journal_paths.dart` | `resolveNewPath` legacy 분기 | §2.3 G4~G7 | v1.2+ |
| **L3** | `vault_work_journal_paths.dart` | `resolveDeleteCandidates` legacy 후보 | §2.3 G4~G7 | v1.2+ |
| **L4** | `file_service.dart` | 구 `{category}/` 폴더 생성 | §2.3 G4~G7 | v1.2+ |
| **R1** | `registry_shard_loader.dart` | `legacy_aliases` 로드 | §3.1 G8~G9 | **보류** |
| **R2** | `registry_shard_loader.dart` | `mergeLegacyMonolithicJson` | §3.2 G10~G12 | M3+2 릴리즈 |
| **R3** | `works_registry.dart` | bootstrap `mergeLegacy…` | §3.2 (R2 동시) | M3+2 릴리즈 |
| **R4** | `works_registry.dart` | sync 후 `mergeLegacy…` | §3.2 (R2 동시) | M3+2 릴리즈 |
| **R5** | `registry_sync_service.dart` | `clearLegacyRegistryCache` | §3.2 (R2 동시) | M3+2 릴리즈 |

---

## 5. 제거 PR 체크리스트

제거 PR을 열기 전:

1. [ ] 해당 ID의 **G1~G12 게이트** 표에서 전부 ✅
2. [ ] `flutter test` · `dogfood_precheck.ps1` PASS
3. [ ] [vault-layout-v2](../history/product/vault-layout-v2.md) V1 원칙 위반 없음 (기존 볼트 읽기 깨짐 없음)
4. [ ] 이 문서 해당 행 **「제거 완료」** 갱신 · `TODO(remove)` 주석 삭제
5. [ ] FOUNDATION_AUDIT §5 건수 갱신

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-25 | F4 초안 — 9건 조건표 · works 레이아웃 v1.0=false 고정 · alias 889 유지 |
