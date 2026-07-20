# Legacy Removal Policy — Foundation F4

> **일자:** 2026-06-25 · marker inventory note 2026-07-20 · works-layout contract note 2026-07-20
> **지위:** active removal-gate contract — `TODO(remove)` 제거 조건 SSOT
> **상위:** [FOUNDATION_AUDIT.md](../history/closure-2026-07/foundation/FOUNDATION_AUDIT.md) · [vault-layout-v2.md](../history/product/vault-layout-v2.md)
> **원칙:** [vault-layout-v2 §2 V1](../history/product/vault-layout-v2.md) — **Breaking migration 없음**

---

## 1. Executive Summary

| 항목 | 결정 |
|------|------|
| `TODO(remove)` 이전 문서 기준 (2026-06-25) | **9건** (6파일) — 정책 ID L1–L4 · R1–R5 |
| `TODO(remove)` 현재 저장소 관측 (2026-07-20) | **`lib/` 내 마커 6건** — 아래 §4. 건수 불일치만으로 제거 완료를 단정하지 않음 |
| **M3 Steam v1.0** | **전부 유지** — 제거 PR 없음 |
| Works 레이아웃 preference fallback | Wave2 도입 **`false`** → **UA-131부터 shipping `true`** · L1 잔여 = preference key/getter/setter 호환 표면 제거 |
| `legacy_aliases.json` | **889건** — 해석 경로 **필수 유지** |
| 레거시 볼트 경로 읽기 | **영구 지원** (이동 강제 없음) |

**판단:** F4는 **제거 일정·게이트 확정**이 목표다. 코드 삭제는 각 게이트 통과 후 **별도 PR**로 진행한다.

---

## 2. Works 레이아웃 정책 (Vault Layout)

### 2.1 현재 동작

| 설정 | 키 | 도입 당시 기본값 | 현재 shipping fallback | 경로 계약 |
|------|-----|:------:|:------:|----------------|
| Works 레이아웃 | `akasha_vault_use_works_layout` | **`false`** (Wave2) | **`true`** (UA-131) | ID 있음 → 항상 `{vault}/works/{category}/{workId}.md` (flag 무관). ID 없는 title-only만 `false` → `{vault}/{category}/` · `true` → `{vault}/works/{category}/` |

- 구현: `VaultWorkJournalPaths`, `VaultRecordPathResolver`, `UserPreferences`, `FileService._ensureFolderStructure`
- **기존 `filePath`는 항상 우선** — 이 preference만으로 저장 시 경로 강제 이동 없음 ([vault-layout-v2 §3.1](../history/product/vault-layout-v2.md))
- bootstrap은 `works/{category}/`와 legacy `{category}/`를 **모두** 생성하지만 preference key는 **저장하지 않음**
- UI 노출: 없음 (SharedPreferences·테스트만 설정) — v1.1+ 설정 화면 후보
- 자동 migration·key backfill 없음 — opt-in 도구는 `tool/migrations/migrate_personal_vault.dart`

### 2.2 Works layout preference 제거 조건 (L1)

**대상:** works-layout preference 호환 표면 — `vaultWorksLayoutKey`, `isVaultWorksLayoutEnabled()`, `setVaultWorksLayoutEnabled()`, 및 title-only 경로 선택에서의 preference 소비. legacy 경로 분기·삭제 후보·bootstrap legacy 디렉터리는 **L2–L4**에서 별도 관리한다.

**원래 결정 (2026-06-25):** v1.0 출시 전 기본값 **`false`**를 유지하고, v1.2에서 다음 G1–G3를 재평가한 뒤 `true` 전환을 검토하기로 했다.

| # | 원래 게이트 | 검증 | 현재 증거 상태 |
|---|-------------|------|----------------|
| G1 | Steam v1.0 dogfood **B1 완료** | Sprint B1 §5 체크리스트 | 이번 정리에서 충족 증거 미확인 |
| G2 | 신규 유저 온보딩에서 works 경로 **문서화** | vault-layout-v2 사용자 안내 | 이번 정리에서 충족 증거 미확인 |
| G3 | **v1.2 마일스톤** 합의 | PROJECT_STATUS · release-readiness | 원 계획 이후 UA-131이 선행됐으나 원 게이트 충족으로 간주하지 않음 |

**현재 구현 상태 (UA-131 이후):** 원래 G1–G3의 충족 여부와 별개로, key 미설정 fallback은 코드에서 이미 **`true`**로 전환됐다. ID 기반 Work는 preference와 관계없이 canonical `works/{category}/{workId}.md` 경로를 사용한다. 이 변경은 원래 제거 게이트가 충족됐음을 의미하지 않는다.

**현재 L1 잔여 조건** (원래 G1–G3를 대체하지 않음):

| ID | 현재 L1 잔여 조건 | 상태 |
|----|-------------------|:----:|
| L1-R1 | key 없음과 key=`false` 사용자에서 ID 기반 저장 경로가 동일함을 회귀 테스트로 고정 | 미충족 |
| L1-R2 | ID 없는 title-only 레코드의 지원·migration·rollback 정책 확정 (기존 `filePath`·dual-path 상태 포함) | 미충족 |
| L1-R3 | preference 소비처가 0이 되거나 L2–L4 제거와 함께 대체됨을 확인 | 미충족 |

### 2.3 레거시 경로 코드 제거 조건 (L2~L5)

**대상:** `vault_work_journal_paths.dart` (2) · `file_service.dart` (1)

| # | 게이트 | 검증 |
|---|--------|------|
| G4 | L1 제거 조건 충족 후 최소 1개 실제 배포 릴리즈 관찰 | release evidence · 회귀 결과 |
| G5 | 선택적 **일괄 마이그레이션 도구** (opt-in) 또는 공식 가이드 | `tool/migrations/` 또는 문서 |
| G6 | dogfood·테스트에서 legacy-only 신규 저장 **0건** 2연속 릴리즈 | B1 회귀 + vault_archive_test |
| G7 | `resolveDeleteCandidates` legacy 후보 제거 시 **삭제 회귀 테스트** green | `vault_archive_test.dart` |

UA-131의 코드 변경 존재만으로 G4의 실제 배포·관찰 조건을 충족했다고 간주하지 않는다.

**결정:** G4~G7 전부 충족 전까지 `{vault}/{category}/` 분기 **삭제 금지**. 읽기·삭제 후보 경로는 레거시 볼트 호환을 위해 **마지막에 제거**. legacy 파일을 자동 삭제하지 않으며, 데이터 손실 방지 게이트를 우회하지 않는다.

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

## 4. 제거 조건표 (정책 ID ↔ 코드)

게이트와 제거 규칙은 유지한다. 아래 **현재 관측**은 2026-07-20 `lib/` 내
`TODO(remove)` 검색 결과이며, 마커 부재만으로 정책 충족·삭제 완료로 보지 않는다
(리팩터링·경로 이동·마커 소멸 가능).

| ID | 파일 (정책 대상 / 현재 관측) | TODO 위치 | 제거 게이트 | 최조 목표 | 현재 관측 |
|:--:|------|-----------|-------------|-----------|-----------|
| **L1** | `user_preferences.dart` 및 preference 소비처 | works-layout key/getter/setter 호환 표면 | §2.2 원래 G1–G3 기록 + L1-R1~R3 | v1.2+ | 마커 있음 · fallback은 UA-131에서 `true`, preference 제거 조건은 미충족 |
| **L2** | `vault_work_journal_paths.dart` | `resolveNewPath` legacy 분기 | §2.3 G4~G7 | v1.2+ | **마커 검색 안 됨** (미충족으로 보지 않음) |
| **L3** | `vault_work_journal_paths.dart` | `resolveDeleteCandidates` legacy 후보 | §2.3 G4~G7 | v1.2+ | 마커 있음 |
| **L4** | 정책: `file_service.dart` · 관측: `file_service_bootstrap.dart` | 구 `{category}/` 폴더 생성 | §2.3 G4~G7 | v1.2+ | 마커 있음 (경로 이동) |
| **R1** | `registry_shard_loader.dart` | `legacy_aliases` 로드 | §3.1 G8~G9 | **보류** | 마커 있음 |
| **R2** | 정책: `registry_shard_loader.dart` · 관측: `registry_shard_loader_sync.dart` | `mergeLegacyMonolithicJson` | §3.2 G10~G12 | M3+2 릴리즈 | 마커 있음 (경로 분리) |
| **R3** | `works_registry.dart` | bootstrap `mergeLegacy…` | §3.2 (R2 동시) | M3+2 릴리즈 | **마커 검색 안 됨** (미충족으로 보지 않음) |
| **R4** | `works_registry.dart` | sync 후 `mergeLegacy…` | §3.2 (R2 동시) | M3+2 릴리즈 | **마커 검색 안 됨** (미충족으로 보지 않음) |
| **R5** | `registry_sync_service.dart` | `clearLegacyRegistryCache` | §3.2 (R2 동시) | M3+2 릴리즈 | 마커 있음 |

---

## 4b. AppDomain compatibility (post-deprecation)

Completed plan (historical): [DOMAIN_DEPRECATION_PLAN.md](../history/closure-2026-07/DOMAIN_DEPRECATION_PLAN.md).
Domain UI/runtime removal is done; the following remain required for vault and
registry compatibility and are **not** M3 removal targets:

| 항목 | 이유 |
|------|------|
| `AkashaItem.domain` · YAML `domain:` | 읽기 시 `AppDomain.fromStorage` → subculture |
| `WorkIdCodec` `sub_`/`gen_` | 레거시 마스터 ID |
| `RegistryWork.domain` | Tier 1 필드 — 값은 항상 subculture |

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
| 2026-07-20 | Works layout 계약 정합 — UA-131 shipping fallback=`true` 반영 · ID canonical path의 flag 비의존 명시 · 원래 G1–G3는 미입증 상태로 보존 · L1 preference 제거 잔여 조건 분리 |
