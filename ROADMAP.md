# AKASHA Roadmap

> 목표: **2026 Q3** Steam (Windows) v1 출시  
> 기준일: **2026-06-10** · 현황: [docs/project-status-snapshot.md](docs/project-status-snapshot.md)

---

## 현재 위치 → 출시 경로

**M1 기능 동결 ✅ → M-v4 데이터 아키텍처 ✅ (Phase E 포함, 2026-06-10) → M2 Steam 제출 준비 ← 현재 → M3 출시 (Q3)**

### 병행 트랙 (2026-06-10 확정)

| 트랙 | 다음 작업 | 상태 |
|------|-----------|------|
| **제품 (M2)** | Steamworks 앱 등록 → 빌드 업로드 → 스토어 페이지 → IAP 등록 | **다음 마일스톤** |
| **데이터 — A5 Scale** | SD2.6 hold (insert 중단 @430) · **O3 checkpoint 2026-07-09** | hold 관측 중 |
| **데이터 — Sprint 05** | [후보 백로그](docs/sprint-05-candidate-backlog.md) — My Library UX·Search Quality 등 (우선순위 미확정) | 후보만 |

externalId **G2 50% 달성** (2026-06-10, [sprint-04-e1-resolution.md](docs/sprint-04-e1-resolution.md)) — Phase 2 Coverage 프로그램 완결.

---

## 제품 결정 요약

| 항목 | 결정 |
|------|------|
| 1차 출시 | Steam (Windows) |
| v1 MVP | 볼트 + 글로벌 사전 + IP 1카드 그리드 + **나의 서재** |
| 사전 규모 | **최종: 전 작품 사전** · 현재 **430작** · **v4 운영** (`wk_` 영구 ID·해시 샤드) |
| 사전 운영 | 자체 구축 + GitHub raw sync ([akasha-db-policy.md](docs/akasha-db-policy.md)) |
| 포스터 | URL 링크만 (self-hosted ❌), CI denylist |
| Steam 모델 | 무료 + IAP (서재 꾸미기, 테마, 서포터 팩) |

---

## Steam v1 기능 체크리스트

### ✅ 핵심 (구현·유지)

- [x] Sanctum 볼트 연동 (폴더 생성, watch, 원자적 저장)
- [x] 글로벌 사전 샤딩 v2 + GitHub sync
- [x] IP 1카드 그리드 + 매체 칩
- [x] 작품 검색 (로컬 + 사전 + 직접 등록)
- [x] AI 마크다운 가져오기 + 프롬프트 템플릿
- [x] 대시보드 (필터, HoF, 워치리스트, 섹션 정렬·접기)
- [x] 볼트 아카이빙 (선택 토글 — 아카이브한 작품만 `.md`)

### 🔨 v1 신규 구현

- [x] **나의 서재 — 기본 뷰 (무료)**
  - [x] 아카이브한 작품만 모아 보는 전용 화면/탭 (`MyLibraryScreen`)
  - [x] 대시보드 「카탈로그」와 역할 분리·네이밍 정리
  - [x] 빈 상태·정렬 UX (필터는 v1.1)
- [x] **나의 서재 — 꾸미기 (IAP 스텁)**
  - [x] 배경·테마 프리셋 (`LibraryTheme`, 테마 피커)
  - [ ] 진열 방식(그리드 밀도 등) 커스텀 — v1.1
  - [x] `EntitlementService` 스텁 → Steam 실결제는 M2

### 🎨 v1 다듬기 (품질·출시 준비)

- [x] 회상 카드 UI 숨김 또는 플래그 off (`FeatureFlags.showRecallCard = false`)
- [x] Windows 앱 메타 (`Runner.rc` — Rune Atelier / AKASHA)
- [ ] Steam depot / 인스톨러 / 스토어 페이지 에셋 — **M2 (Steamworks 등록 후)**
- [x] AniList bulk 시드 **제거** (684작 삭제 → 엄선 카탈로그, `purge_anilist_bulk`)
- [x] **만화/웹툰 분리** (`MediaCategory.webtoon`, 2작 이관 + legacy_aliases)
- [x] TMDB 포스터 검증·오매핑 제거 (`poster_validate_tmdb`, `poster_fixup_tmdb`)
- [x] 증분 sync (`generatedAt` early return + 샤드 `entryCount` 스킵)
- [x] `pubspec` description v1 범위 반영
- [x] 앱 번들 전체 샤드 동기화 (`registry_builder --sync-assets` — GitHub 옛 데이터 덮어쓰기 방지)

---

## 마일스톤

### M1 — 기능 동결 (2026 Q2)

- [x] v1 체크리스트 (Steam depot 제외)
- [x] `flutter test` 94/94 · `ci_registry_check` green
- [x] 번들 smoke (`steam_v1_bundle_test` — ~410작·웹툰 이관)
- [x] Windows release 빌드 (`.\scripts\build_release.ps1`)
- [x] **akasha-db GitHub push** — ~410작 엄선 카탈로그 반영
- [x] dogfood 자동 사전 검증 (`scripts/dogfood_precheck.ps1` — test 96/96 · ci_registry_check)
- [x] 내부 dogfood (본인 볼트 + 동기화 검증)
- [x] 나만의 서재 `master_archive` (대시보드 `master_index`와 대응)

### M-v4 — 데이터 아키텍처 v4 (Steam 출시 **게이트**)

> 상세: [v4-migration-plan.md](docs/v4-migration-plan.md) · 설계: [data-architecture-redesign.md](docs/data-architecture-redesign.md)

- [x] **Phase A** — `assign_wk_ids.dart` + `id_registry.json` + `legacy_aliases`
- [x] **Phase B** — `WorkIdCodec`·loader·볼트 `wk_` 해석
- [x] **Phase C** — `dedupe_linter` + canonicalization CI (402작)
- [x] **Phase D** — 해시 샤딩 v4 + manifest v4 + builder/loader/sync (331 버킷)
- [x] v4 dogfood (`110/110` tests · `ci_registry_check` green)
- [x] **Phase E** — akasha-db GitHub push (2026-06-10 · 430작·G2 50% CDN 반영)

### M2 — Steam 제출 준비 (현재 마일스톤 · ~Q3)

- [x] `main` push (akasha + akasha-db) — 2026-06-10
- [ ] Steamworks 앱 등록, 빌드 업로드
- [ ] 스토어 페이지 (스크린샷, 태그, 한/영 설명)
- [ ] IAP 상품 등록 (서재 테마, 서포터 팩)

### M3 — Steam v1 출시 (2026 Q3)

- [ ] Windows 무료 출시
- [ ] akasha-db 운영 가이드 공개 (기여 PR 워크플로)

---

## v1.1+ (보류)

| 기능 | 상태 | 메모 |
|------|------|------|
| **글로벌 i18n (UI)** | 스키마만 | `CatalogLocale` · ARB `ko`/`en` — [locale-catalog-policy.md](docs/locale-catalog-policy.md) |
| **다국어 카탈로그** | v3 스키마 ✅ | `titles`/`aliases`/`searchTokens` · 샤드 마이그레이션 `migrate_registry_v3` |
| **제휴 커머스** | entitlement 분리 ✅ | cosmetic(Steam) vs content(제휴) — [commerce-boundary.md](docs/commerce-boundary.md) |
| 오늘의 회상 카드 | 코드 있음 | v1에서 제외, v1.1에 스토어 노출 |
| 타임라인 / 완성 캘린더 | 미구현 | 철학 2번 축 |
| 취향 기반 추천 (Discover) | 미구현 | 철학 3번 축, 규칙 기반 MVP 설계됨 |
| TMDB / IGDB API | 미구현 | 저작권·라이선스 검토 후 |
| Riverpod 마이그레이션 | 미구현 | v1 안정화 후 |
| 모바일 | 미구현 | Windows 검증 후 |

---

## 데이터·인프라 백로그

> **Steam 게이트:** [v4-migration-plan.md](docs/v4-migration-plan.md) Phase A~D  
> **비전:** [data-architecture-redesign.md](docs/data-architecture-redesign.md)

### Steam 전 (v4 게이트) ✅

- [x] Phase A: `assign_wk_ids` + `id_registry.json`
- [x] Phase B: 앱·볼트 `wk_` 호환
- [x] Phase C: `dedupe_linter` CI (402작)
- [x] Phase D: 해시 샤딩 v4 (manifest v4 · 331 버킷)
- [x] Phase E: akasha-db GitHub push (430작 · 2026-06-10)

### Steam 후 — 카탈로그 운영 (우선순위 상단)

> 상세: [docs/catalog-contribution-roadmap.md](docs/catalog-contribution-roadmap.md)  
> **장기:** 유저 Contribution = **보조** · **Catalog Expansion Pipeline** = 주력 (작품 확보 속도)

**확정 구현 순서:** ① status → ② contribution 커밋 → ③ add/fix 분리 → ④ AI validation → ⑤ catalog expansion

| # | 백로그 | 상태 | 목적 |
|---|--------|------|------|
| **C0** | **Contribution status** (GitHub SoT) | 🔶 | `status` 필드 · `contributions/{add,fix}/{pending…}/` · `status.json` CDN |
| C0b | contribution 구조 커밋 | ⏳ | 앱 제안 UI + export |
| **C1** | add / fix **운영 분리** | ⏳ | 폴더 분리 완료 · Issue·SLA·검수 난이도 분리 |
| **C3** | **AI Validation Pipeline** | ⏳ | confidence → auto-merge vs human queue |
| C4 | `fixWork --apply` | ⏳ | accepted 수정 → 샤드 patch |
| C5 | Issue 폭발 완화 | ⏳ | 주간 배치 import · dedupe 선행 |
| **E1** | **Catalog Expansion Pipeline** | ⏳ | 외부 참고 → AI 후보 → dedupe → maintainer → Registry |

### Steam 후 — 인프라·확장

> **Registry Stress Review (선행 게이트):** Discovery 확장 전 Registry 그릇 검증 — [docs/registry-scaling-review.md](docs/registry-scaling-review.md)
> **Bottleneck Validation:** ✅ search_index = 첫 병목 (실측) — [docs/registry-bottleneck-validation-report.md](docs/registry-bottleneck-validation-report.md)
> **Search Index Validation:** ✅ 10k/100k/300k/1M synthetic — [docs/search-index-validation-plan.md](docs/search-index-validation-plan.md)
> **Architecture Options:** ✅ 후보 비교 — [docs/search-index-architecture-options.md](docs/search-index-architecture-options.md)
> **Search Workload Profile:** ✅ 가정 v0 — [docs/search-workload-profile.md](docs/search-workload-profile.md)
> **SW1 Global Search Validation:** 🔶 계획·스위트 ✅ — [docs/global-search-validation-plan.md](docs/global-search-validation-plan.md)
> **URV Universal Registry Validation:** 🔶 계획 ✅ — [docs/universal-registry-validation.md](docs/universal-registry-validation.md)
> **Registry Growth Strategy:** ✅ — [docs/registry-growth-strategy.md](docs/registry-growth-strategy.md)
> **Contribution Model Strategy:** ✅ — [docs/contribution-model-strategy.md](docs/contribution-model-strategy.md)
> **Baseline v1 (고정):** ✅ ADR-001~006·SW1·URV·Growth·Contribution — [docs/baseline-v1.md](docs/baseline-v1.md)
> **5k Risk Analysis:** ✅ Top3=수집·dedupe·alias — [docs/scale-5k-risk-analysis.md](docs/scale-5k-risk-analysis.md)
> **Search Index Refactor:** ⏸ SW1 게이트 + POC + ADR 전까지 보류

- [x] **[Validation P0] Search Index Bottleneck** — 파일·메모리·parse·latency 실측
- [x] **[Validation P0b] Architecture Options** — 후보 비교 문서
- [x] **[Validation P0c] Search Workload Profile** — 유형·비율 가정 v0
- [x] **[Validation P1] SW1 Global Search Validation** — 계획·쿼리 스위트 95건·recall 기준 ([global-search-validation-plan.md](docs/global-search-validation-plan.md))
- [x] **[Validation P1] URV Universal Registry Validation** — Work/Franchise·canonical·alias·series·dedupe ([universal-registry-validation.md](docs/universal-registry-validation.md))
- [x] **[Baseline v1 고정]** ADR-001~006·SW1·URV·Growth·Contribution ([docs/baseline-v1.md](docs/baseline-v1.md))
- [x] **[Validation P1] ADR-001 Dual-layer** — Work + Franchise 승인 ([docs/adr/ADR-001-dual-layer-entity-model.md](docs/adr/ADR-001-dual-layer-entity-model.md))
- [x] **[Validation P1] ADR-006 Franchise 계층** — F1·depth≤3·IP 1카드 **승인** ([ADR-006](docs/adr/ADR-006-franchise-boundary-hierarchy.md))
- [x] **[Validation P1] ADR-005 최소 기록 단위** — 비음악 매체 승인 ([ADR-005](docs/adr/ADR-005-minimum-recordable-unit.md))
- [ ] **[Validation P1] ADR-002 A/B 결정** — B안(곡=Work) 가중 · 음악 도입 전 확정 ([ADR-002](docs/adr/ADR-002-music-registry-model.md))
- [ ] **[Validation P1] URV-A 402 baseline** — 정체성·관계·dedupe 수동 실행
- [ ] **[Validation P1] SW1-A 402 baseline** — recall@10/@20 수동 실행
- [ ] **[Validation P1] 5k 시뮬레이션 SIM-A/B/C** — 수집·dedupe·alias Top3 ([scale-5k-risk-analysis.md](docs/scale-5k-risk-analysis.md))
- [ ] **[Validation P1] Architecture Options POC** — Workload 기준 · A / B / E1 벤치
- [ ] **[Validation P1] shardBits 임계 실측** — 8/12/14 bits별 shard당 작품 수·로드 비용 비교
- [ ] **[Validation P1] quality 재빌드 실측** — 전량 rebuild vs 증분
- [ ] **[Validation P2] franchise 운영량 검증** — 수동 큐레이션 throughput
- [ ] **[Validation 장기] Discovery Throughput** — 1M에서 dedupe cost · merge/create ratio · Discovery Cost vs Registry Growth
- [ ] Registry Pipeline 스켈레톤
- [ ] AI 자동 수집 (2027~)
- [ ] 50k+ CDN·R2
- [ ] searchTokens 품질 CI · poster URL 배치 재검증

- [x] cold start preload 축소 (`main.dart` — master_index 진입 시에만 full prefetch)
- [x] `flutter_ci.yml`에 `ci_registry_check` 연동
- [x] akasha-db **~410작** 엄선 (batch 시드 + 수동 큐레이션, AniList bulk 금지)
- [x] lazy 샤드 정책 — 번들은 eager 15샤드만, 나머지 온디맨드
- [x] **akasha-db v4** — `wk_`·해시 샤드·`sha256` manifest ([SCHEMA.md](akasha-db/SCHEMA.md))
- [ ] 샤드 v3 전량 마이그레이션 (`migrate_registry_v3.dart` — 점진 실행)
- [ ] `franchise_groups.json` `displayNames` 커버리지 확대
- [ ] `locale_linter` — PR 시 titles·externalIds 검증
- [x] 포스터 링크 전용 정책 + CI denylist (`poster_url_policy.dart`, `poster_url_baseline.json`)
- [x] `registry_cache` 자동 무효화 (번들·원격 manifest 갱신 시)
- [ ] 증분 sync + `lastSyncTime` UX 고도화

---

## 코드 품질·리팩터 (우선순위 낮음)

- [ ] `fusion_search` 서비스 추출
- [ ] `home_screen.dart` 추가 분할 (필요 시)
- [ ] RegistrySyncService 통합 테스트 확대

---

## 완료된 주요 작업 (참고)

- 샤딩 레지스트리 v2 + work_id 코덱
- 포스터 link-reference 정책
- HomeScreen / DetailScreen 다단계 분할
- Flutter CI + registry CI
- IP 1카드 + FranchiseFusion
- AI clipboard import / prompt templates 다이얼로그
