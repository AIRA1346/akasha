# AKASHA Roadmap

> 목표: **2026 Q3** Steam (Windows) v1 출시  
> 기준일: 2026-06-07

---

## 제품 결정 요약

| 항목 | 결정 |
|------|------|
| 1차 출시 | Steam (Windows) |
| v1 MVP | 볼트 + 글로벌 사전 + IP 1카드 그리드 + **나의 서재** |
| 사전 규모 | 출시 엄선 ~1,000작 → 장기 수백만 체급 |
| 사전 운영 | GitHub raw sync + 하이브리드 기여 |
| Steam 모델 | 무료 + IAP (서재 꾸미기, 테마, 서포터 팩) |

---

## Steam v1 기능 체크리스트

### ✅ 핵심 (구현·유지)

- [x] Obsidian 볼트 연동 (폴더 생성, watch, 원자적 저장)
- [x] 글로벌 사전 샤딩 v2 + GitHub sync
- [x] IP 1카드 그리드 + 매체 칩
- [x] 작품 검색 (로컬 + 사전 + 직접 등록)
- [x] AI 마크다운 가져오기 + 프롬프트 템플릿
- [x] 대시보드 (필터, HoF, 워치리스트, 섹션 정렬·접기)
- [x] 볼트 자동 아카이빙

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
- [x] 사전 **~1,000작** 시드 배치 (akasha-db **1,009작** / 205샤드)
- [x] 증분 sync (`generatedAt` early return + 샤드 `entryCount` 스킵)
- [x] `pubspec` description v1 범위 반영
- [x] 앱 번들 lazy 샤드 제외 (`registry_builder --sync-assets` eager만)

---

## 마일스톤

### M1 — 기능 동결 (2026 Q2)

- [x] v1 체크리스트 (Steam depot 제외)
- [x] `flutter test` 74/74 · `ci_registry_check` green
- [x] Windows release 빌드 (`.\scripts\build_release.ps1`)
- [ ] **akasha-db GitHub push** — 원격 sync가 1,009작을 받으려면 필수
- [ ] 내부 dogfood (본인 볼트 + 동기화 검증)

### M2 — Steam 제출 준비 (2026 Q3 초)

- Steamworks 앱 등록, 빌드 업로드
- 스토어 페이지 (스크린샷, 태그, 한/영 설명)
- IAP 상품 등록 (서재 테마, 서포터 팩)

### M3 — Steam v1 출시 (2026 Q3)

- Windows 무료 출시
- akasha-db 운영 가이드 공개 (기여 PR 워크플로)

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

- [x] cold start preload 축소 (`main.dart` — master_index 진입 시에만 full prefetch)
- [x] `flutter_ci.yml`에 `ci_registry_check` 연동
- [x] akasha-db 시드 ~1,000작 (`seed_expansion_anilist.dart` + `batch4` + `registry_builder --sync-assets`)
- [x] lazy 샤드 정책 — 번들은 eager 15샤드만, 나머지 온디맨드
- [x] **akasha-db v3** — `titles`/`aliases`/`externalIds`/`searchTokens` ([SCHEMA.md](akasha-db/SCHEMA.md))
- [ ] 샤드 v3 전량 마이그레이션 (`migrate_registry_v3.dart` — 점진 실행)
- [ ] `franchise_groups.json` `displayNames` 커버리지 확대
- [ ] `locale_linter` — PR 시 titles·externalIds 검증
- [ ] 포스터 정책 tier 유지 (`POSTER_POLICY.md`)
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
