# AKASHA Current State (현재 상태)

> **지위:** 프로젝트 구현 현황 SSOT (코드 및 레지스트리 실제 기준)  
> **갱신:** 2026-06-25 (test **605** · analyze 0 error · Foundation F0 ✅ · Sprint B1 dogfood)  

---

## 1. 데이터베이스 및 카탈로그 (akasha-db)

### Ⅰ. Tier 1 (Global Fact DB)
* **등록 작품 수:** **10,048개** (`akasha-db` 내 v4 해시 샤드 관리)
* **샤딩 아키텍처:** SHA256 해시 기반의 v4 샤딩 시스템 (`manifest.json` + `wk_` 고유 영구 ID).
* **데이터 원칙 준수:** 
  * posterPath 및 description 저장 불가 규칙 엄격 준수.
  * 모든 작품은 `title`, `titles` (다언어), `category`, `domain`, `releaseYear`, `creator`, `externalIds` 식별 데이터만 보유.
  * 중복 작품(Duplicate) 수: **0개** (CI 검증 통과)

### Ⅱ. Tier 2 (Sanctum Vault)
* 로컬 파일 시스템 연동 및 Watch 시스템 구현 완료.
* YAML front-matter 템플릿 파싱 및 자동 아카이브 생성.
* 로컬 포스터(`posters/` 하위 이미지) 및 이미지 URL 표시 지원.

---

## 2. 검색 및 품질 검증 (Search & Validation)

### Ⅰ. 검색 시스템 (Global Search)
* `search_index.json`을 통한 인메모리 고속 검색 구현.
* 다언어 제목, 동의어(Aliases), 원제 검색 지원.
* 검색 랭킹: `qualityScore` 가중치 반영.

### Ⅱ. 게이트웨이 및 CI 검증
* **검색 Recall 검증 (`sw1_a_validation.dart`):** baseline 95개 검색 쿼리에 대해 Recall@10 **100% 달성** (87/87 recall-evaluated).
* **CI 검증 게이트:** `flutter test` **605 PASS**, `flutter analyze lib/` **0 error**, `ci_registry_check` 통과, `preflight_check` 통과, `quality_gate --locale-minimum` 통과.

### Ⅲ. Home Shell (Wave 1 + Phase 7)
* **프리뷰:** `HomePreviewCoordinator` — 스택·복귀·연결 픽 pending 통합.
* **최근 탐색:** `HomeRecentExplorationCoordinator` — store + 해석.
* **컨트롤러:** `home_shell_controller` ~516줄 (coordinator 위임).

---

## 3. UI 및 워크벤치 (UI & Workbench)

### Ⅰ. 홈 화면 (HomeScreen)
* **대시보드 (Dashboard):** 글로벌 카탈로그 검색 및 탐색. 포스터 없는 Fact 카드 그리드 UI 적용.
* **나의 서재 (Personal Library):** 유저가 아카이빙한 작품들의 포스터 그리드 및 테마 피커(IAP 스텁 포함).

### Ⅱ. 워크벤치 (4열 상세 편집기)
* **탭 관리:** 다중 Work 및 Entity 탭을 열어둔 다단계 작업 공간.
* **상세 편집:** Markdown 본문 편집과 YAML frontmatter 폼 편집 기능이 완결되어 상호 탭 싱크 처리.
* **연결 패널:** Work·Entity 각각 `*ConnectionsCoordinator`로 incoming / sameDay / link neighbors·vault 외부 편집 감지 분리.
* **공유 ops:** `workbench_linked_record_ops`, `workbench_vault_disk_ops`, `*draft_ops`, `*delete_ops`, `*save_ops`, `workbench_save_shortcuts`.

### Ⅱ-b. Sanctum 아카이빙 (Work 기록, 2026-06)

| 단계 | 기능 |
|:---:|------|
| C1 | `[[entityId\|제목]]` 저장 유지 · 미리보기 **wiki 아바타 칩** |
| C2 | `# 👥 출연` 슬롯 · 패널 인물 추가 → 출연 |
| C3 | `# 🖼 갤러리` · 이미지 DnD/붙여넣기 · **명장면 카드** |
| C4 | **기록 완성도 %** · 카테고리 **템플릿** · **HTML보내기** (Work) |
| + | Entity journal HTML보내기 · [link-identity-policy §14](../history/policy/link-identity-policy.md) |

핵심 모듈: `MarkdownBodyMerger`, `WorkSanctumSectionEditor`, `SanctumPreviewBody`, `SanctumHtmlExporter`, `SanctumArchiveCompletion`.

### Ⅲ. Foundation Sprint (2026-06)

* 감사 SSOT: [FOUNDATION_AUDIT.md](../draft/FOUNDATION_AUDIT.md)
* **F0** ✅ — test 605 · `dogfood_precheck` PASS
* **F1** 🟡 — SSOT·B1 Sanctum 시나리오
* **F2~F4** — Sanctum 편집기 분해 · R14-B · 레거시 `TODO(remove)`

### Ⅳ. Sprint B1 (Dogfood)
* SSOT: [SPRINT_B1_DOGFOOD.md](SPRINT_B1_DOGFOOD.md)
* 자동: `.\scripts\dogfood_precheck.ps1` (test → ci_registry → preflight → sw1_a → quality_gate --release)
* 수동: Release 빌드에서 볼트·Work/Entity `.md` 루프 · P0 QA 12/12 재확인

---

## 4. Phase별 개발 진척도 (Actual Phase Status)

| Phase / 마일스톤 | 내용 | 실제 구현 현황 |
|:---:|---|:---:|
| **Phase 0** | 작품 E2E 아카이빙 | **완료 (100%)** |
| **Phase 1** | Record 기초 (Foundation) | **완료 (100%)** |
| **Phase 2** | 카탈로그 확장성 및 CI (10k scale) | **완료 (100%)** |
| **Phase 6.2** | 워크벤치 상세 통합 (Workbench Parity) | **완료 (100%)** |
| **Phase 6.3** | incoming/sameDay·connections coordinator | **완료 (100%)** |
| **M3** | Steam Release 준비 | **보류 (⏸️)** (M2 depot, IAP, 스토어 등록은 완료되었으나 품질 폴리시 충족을 위해 홀드) |
| **Phase 3** | Entity 타입 다각화 (Work 이외) | **미착수** |
| **Phase 4** | 타임라인 아카이브 | **미착수** |
| **Phase 5** | 엔티티 연결성 (Connection) | **미착수** |
