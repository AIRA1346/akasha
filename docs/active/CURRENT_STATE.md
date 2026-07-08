# AKASHA Current State (현재 상태)

> **지위:** 프로젝트 구현 현황 SSOT (코드 및 레지스트리 실제 기준)  
> **갱신:** 2026-07-08 (test **838** · analyze 0 · **Canvas v0.3-B.1** · **viewport persist + inertia zoom guard** · **Steam v1 = Personal Archive** · **Vault Format Spec v3 확립**)
> **Git:** code/test baseline **1729cef2** · current tip **`8df18978`**
> **형식 명세:** [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) — 독립 검증기 `tool/vault_format_validator.dart`
> **무한 아카이브 계획:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md)

---

## 0. Steam v1 제품 초점 (2026-07-06)

**구현된 것의 우선순위 재정렬:** 코드 삭제 없음.

| 계층 | 역할 | v1 |
|------|------|:--:|
| **Tier 2 Sanctum vault** | `.md` / YAML 감상 기록 | **핵심** |
| **Personal Library · Collection** | 내가 아카이브한 것의 큐레이션 | **핵심** |
| **Workbench · Sanctum UI** | 예쁜 기록·편집 | **핵심** |
| **Vault Format Spec v3** | 독립 명세 확립 — 7종 타입 · 관계 어휘 · 시간 이원화 · 자기 서술(`.akasha/spec/`) · 독립 검증기 · 명세-템플릿 동기화 가드 | [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) |
| **Agent Vault** | v1 프로토콜 문서화 완료 및 명세 v3 동기화 (source·시간·관계 규약) | [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) |
| **Infinite Archive Hardening** | index · taste signal · agent write · ID path 기준 정렬 | **pre-release decision / post-v1 guard** |
| **Tier 1 akasha-db** | starter / optional catalog | **보조** |
| **Discovery · Scale (10k+)** | Wikidata · CDN · recall gate | **post-v1** |

**v1 blocking에 가까운 검증:** `flutter test` **830** · vault 아카이브·Sanctum 저장·기록 UI · dogfood(사용자 직접).
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
| `flutter test` | **838 PASS** | ✅ |
| `flutter analyze lib` | 0 issue | ✅ |
| `vault_format_validator` | 적합성 검증기 (spec v3 · 앱 무의존) | — |
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
* **Canvas Editor (지식 지도):** Knowledge Graph → Workbench 탭 — **v0.3-B.1** (post-v1 P1, v1 blocking 아님). 분해 계획: [CANVAS_EDITOR_DECOMPOSITION_PLAN.md](../draft/CANVAS_EDITOR_DECOMPOSITION_PLAN.md) · 구현 계획: [CANVAS_NODE_OPEN_v0.3-B.1_IMPLEMENTATION_PLAN.md](../draft/CANVAS_NODE_OPEN_v0.3-B.1_IMPLEMENTATION_PLAN.md)

| 슬라이스 | 기능 | 상태 |
|:---:|------|:---:|
| v0.0 | `canvases/{cv_u_*}/` · `canvas.md` + `layout.json` 저장 계약 | ✅ |
| v0.1 | text 메모 노드 · Work/Entity 아카이브 노드 검색·추가 · 노드 카드 렌더 | ✅ |
| v0.2 | 관계선 CustomPainter · `canvas_only` edge 생성/편집/삭제 · preset relation picker | ✅ |
| v0.3-A | Zoom/Pan · 뷰포트 경계 · 중심 좌표 원점 · 노드 드래그 · Fit to Content · `Ctrl+Space` | ✅ |
| v0.3-A.4 | viewport listener 통합 · partial file extraction · SSOT 문서 | ✅ |
| v0.3-A.5 | viewport persist (layout session · Work/Entity 복귀 · `alignment: topLeft`) | ✅ |
| v0.3-B.1 | Work/Entity 노드 더블클릭 → Workbench 상세 탭 · Canvas+Detail 2탭 push (canvas active만) | ✅ |
| v0.3-B.2a | pan 관성 중 wheel zoom guard (`InteractiveViewer` + custom wheel · lock on fling) | ✅ |

**Canvas v0.3-B.1 한계 (알려진):**
- UI 노드 kind: `text` · `work` · `entity`만. `record` · `group` 미구현.
- Edge 편집: `canvas_only`만. `canonical_view` · `candidate`는 read-only snackbar.
- text 노드 더블클릭은 no-op (기존 편집 버튼 유지).
- 선택/Delete 단축키 · 리사이즈 · 미니맵 · 베지에 곡선: **미구현**.
- Fit to Content 단축키 `Ctrl+Space` — Windows/IME 환경 충돌 가능. 후보: `Home`/`Ctrl+0`/`F`.
- Canvas UI widget 테스트 없음 (`canvas_store_test` · `vault_format_validator` canvas group · `openDetailBesideCanvas` unit만).
- `canvas.md` 본문/메타 UI 편집 없음.
- Browse `openWork`/`openEntity`는 기존 `tabs.clear()` 유지. 2탭 push는 Canvas active 경로만.

핵심 모듈: `CanvasStore`, `CanvasEditorWorkspace`, `CanvasNodeCard`, `CanvasEdgePainter`, `WorkbenchController.openDetailBesideCanvas`.

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
