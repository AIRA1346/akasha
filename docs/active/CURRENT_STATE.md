# AKASHA Current State (현재 상태)

> **지위:** 프로젝트 구현 현황 SSOT (코드 및 레지스트리 실제 기준)  
> **갱신:** 2026-07-06 (test **743** · analyze 0 · **Steam v1 = Personal Archive**)
> **Git:** code/test baseline **7be7b51b** · current tip은 `git log -1` 기준
> **무한 아카이브 계획:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md)

---

## 0. Steam v1 제품 초점 (2026-07-06)

**구현된 것의 우선순위 재정렬:** 코드 삭제 없음.

| 계층 | 역할 | v1 |
|------|------|:--:|
| **Tier 2 Sanctum vault** | `.md` / YAML 감상 기록 | **핵심** |
| **Personal Library · Collection** | 내가 아카이브한 것의 큐레이션 | **핵심** |
| **Workbench · Sanctum UI** | 예쁜 기록·편집 | **핵심** |
| **Agent Vault** | v1 프로토콜 문서화 완료 및 UA-115 시스템 타임스탬프 UTC 정렬 완료 | [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) |
| **Infinite Archive Hardening** | index · taste signal · agent write · ID path 기준 정렬 | **pre-release decision / post-v1 guard** |
| **Tier 1 akasha-db** | starter / optional catalog | **보조** |
| **Discovery · Scale (10k+)** | Wikidata · CDN · recall gate | **post-v1** |

**v1 blocking에 가까운 검증:** `flutter test` **743** · vault 아카이브·Sanctum 저장·기록 UI · dogfood(사용자 직접).
**v1 blocking 아님:** registry 작품 수 · recall@10 · Wikidata 확장 · CDN scale.

---

## 1. 데이터 계층

### Ⅰ. Tier 1 (Global Fact DB) — **optional catalog / post-v1 scale**

* **등록 작품 수:** **10,048개** — 엔지니어링·CI 자산. **v1 제품 핵심으로 과장하지 않음.**
* **샤딩:** v4 hex shards · `wk_` 영구 ID · dedupe **0**
* **역할:** 작품 **검색·starter catalog** 보조. 삭제·축소 없음.
* **데이터 원칙:** posterPath·description Tier 1 금지 · Fact-only CI 유지

### Ⅱ. Tier 2 (Sanctum Vault) — **v1 핵심**
* 로컬 파일 시스템 연동 및 Watch 시스템 구현 완료.
* YAML front-matter 템플릿 파싱 및 자동 아카이브 생성.
* 로컬 포스터(`posters/` 하위 이미지) 및 이미지 URL 표시 지원.

---

## 2. 검색 및 품질 검증

### Ⅰ. 검색 (optional catalog)

* `search_index` 인메모리 검색 — **볼트·직접 등록과 함께** 작품 찾기 보조.
* 다언어 제목·aliases 검색.

### Ⅱ. CI 검증

| 도구 | 결과 | v1 blocking |
|------|:----:|:-----------:|
| `flutter test` | **743 PASS** | ✅ |
| `flutter analyze lib` | 0 issue | ✅ |
| `preflight_check` | PASS | ✅ |
| `sw1_a_validation` recall@10 | 87/87 | — |
| `ci_registry_check` | PASS | — |

### Ⅲ. Home Shell

* Wave 1 + Foundation P2 분해 완료 — coordinator·preview·scaffold parts.
* **v1 관점:** browse/catalog UI는 **기록으로 이어지는 진입**이지 제품 정체성 자체가 아님.

---

## 3. UI 및 워크벤치 (UI & Workbench)

### Ⅰ. 홈 화면

* **나의 서재 (Personal Library):** v1 핵심 — 아카이브 작품 포스터·테마.
* **대시보드 (Dashboard):** optional catalog 탐색 — Fact 카드 그리드.

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
* **F1** ✅ — SSOT·B1 Sanctum 시나리오 D7~D9
* **F2** ✅ — `work_sanctum_section_editor` 분해 · `work_detail_sanctum_ops`
* **F3** ✅ — R14-B Preview·Neighbors·Sanctum hint 토큰
* **F4** ✅ — [LEGACY_REMOVAL_POLICY.md](../draft/LEGACY_REMOVAL_POLICY.md) · 9건 게이트 · v1.0 works=false

### Ⅳ. Sprint B1 (Dogfood) — ✅ 완료

* SSOT: [SPRINT_B1_DOGFOOD.md](SPRINT_B1_DOGFOOD.md)
* Sanctum 컴팩트 푸터 · Release 빌드 UI 검증 완료

### Ⅳ-b. Vault Agent (2026-06-26)

* [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) — Agent ↔ vault v1 계약
* [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) — index · taste signal · structured operation · ID path 계획
* [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md) — 볼트 경로·ID·예시
* 볼트 `VAULT_README.md` 자동 생성 · `.akasha/entity_path_index.json`

---

## 4. Phase별 개발 진척도 (Actual Phase Status)

| Phase / 마일스톤 | 내용 | 실제 구현 현황 |
|:---:|---|:---:|
| **Phase 0** | 작품 E2E 아카이빙 | **완료 (100%)** |
| **Phase 1** | Record 기초 (Foundation) | **완료 (100%)** |
| **Phase 2** | 카탈로그 CI·10k scale | **완료** — post-v1 scale track |
| **Phase 6.2** | 워크벤치 상세 통합 (Workbench Parity) | **완료 (100%)** |
| **Phase 6.3** | incoming/sameDay·connections coordinator | **완료 (100%)** |
| **M3** | Steam 무료 출시 | **진행 중** — no-IAP BuildID **24015480** 업로드 완료, Set Live/review 대기 |
| **Phase 3** | Entity 타입 다각화 (Work 이외) | **미착수** |
| **Phase 4** | 타임라인 아카이브 | **미착수** |
| **Phase 5** | 엔티티 연결성 (Connection) | **미착수** |
