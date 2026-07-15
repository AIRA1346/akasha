# AKASHA Current State (현재 상태)

> **지위:** 프로젝트 구현 현황 SSOT (코드 및 레지스트리 실제 기준)  
> **원칙:** [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md) — 구현이 원칙과 충돌하면 구현·본 문서를 교정한다.
> **제품 범위:** [VISION.md](VISION.md)
> **갱신:** 2026-07-15
> **Git:** `git rev-parse HEAD` (문서 커밋 tip과 어긋나면 tip을 따름)
>
> **Verification snapshot (2026-07-15):**
> - P0 recoverable Vault write · SA-01/02/03 derived-index foundation
> - P1 local CLI: bounded `record lookup`/`record read` · user-started `candidate.create`
> - Candidate provenance review UX · Vault-spec self-description
> - `system/` = durable non-rebuildable (candidates, ops, recovery, drafts); `.akasha/` = derived/disposable
> - Bounded Home Read Closure (S0) · Architecture Closure **declared**
> - Steam Inventory sandbox E2E POC passed; production IAP remains disabled
> - **Locator index atomic write + `.bak` restart recovery** — `DerivedIndexAtomicWrite` · Record/Entity path indexes · **done** (corrupt≠empty; stale `.tmp` never promoted). Follow-up only: concurrent write lock on same locator file (separate audit candidate; not blocking this closure)
> - **Entity vault load diagnostics** — `EntityVaultLoader.loadFromVaultWithIssues` · `EntityJournalParser.parseDetailed` · per-file isolation preserved · empty vault ≠ corrupt-only via `issues` · `loadFromVault` remains List wrapper · **no auto-log**; diagnostic consumers handle `issues` explicitly.
> - **Follow-up only (not implemented):** `EntityPathIndexService.rebuildFromVault` still drops parse/I/O failures without exposing issues; `upsertMarkdownFile` has the same diagnostic asymmetry. Do **not** add `rebuildFromVaultWithIssues` alone while all callers keep using `rebuildFromVault` and would discard issues. Reuse `parseDetailed` + `EntityVaultLoadIssue` when an explicit index audit/rebuild consumer exists.
> - **Workbench recovery draft I/O diagnostics** — Work/Entity `_saveRecoveryDraftNow` / `_deleteRecoveryDraft` use transition `appLog` via `WorkbenchRecoveryDraftIoDiagnostics` (save≠delete state; no spam; no UI). **Follow-up only:** late draft write vs delete race · stale draft vs vault freshness · Work/Entity deactivate autosave flush asymmetry
> - **Entity derivedIndexesUpdated** — Entity save/delete sets per-path `VaultPathChange.derivedIndexesUpdated` after successful index mutation; Home skips `ArchiveIndexManager` only (UI side-effects kept). Home debounce **AND-coalesces** pending path flags across batches (`false` survives later `true`). Work/Journal/Timeline still double-update (follow-up)
> - **HomeShell vault-watch dispose lifecycle (ACTION A)** — God Class 전면 리팩터 **기각** (상태 소유권은 이미 coordinator로 분리). `HomeVaultWatchReactor` generation cancel + dispose 순서(reactor → vault sub/debounce → workbench) + `WorkbenchController.syncEntityTabs` await 후 `_disposed` guard. **COUPLED/DEFERRED 유지:** timeline token 과다 bump · 이중 rebuild · Catalog `isCatalogLoading` 직접 set · Vault cold-start bootstrap 추출
> - **Package modularization audit (closed)** — 단일 Flutter 앱 + `akasha_commerce_domain`(유일한 성공 공유 package) + 별도 backend 유지 · package graph **비순환** · 신규 EXTRACT_NOW **없음** · Melos / `akasha_core`·database·ui 전면 분할·줄 수 기준 분리 **기각**. Archive format/codec = PREPARE_BOUNDARY · Vault I/O / UI / Home orchestration = KEEP_IN_APP · Steam bridge는 production IAP·no-IAP 빌드 제외 요구 시 **CMake optional부터** 재검토 · Melos는 package 수·공통 orchestration 필요성이 실제로 늘 때만. **재오픈 트리거:** 앱 외 제2 소비자 · 플랫폼 완전 빌드 제외 · 안정 API/의존 방향 · 앱 타입 역참조 없음 · 독립 테스트·배포·CI 격리 실측 · unrelated 동시 변경 반복
> - Flutter app: `flutter analyze` **0** · `flutter test` **1156**
> - Commerce packages: domain `dart test` **17** · backend `dart test` **18** · domain/root `dart analyze` **0**
> - Windows debug/release build **OK (2026-07-15)**
> - **UX-5A Theme package regression foundation** — 5 preset asset namespace/fallback/reduced-motion 계약 · 핵심 surface 3 viewport/125% text geometry · Classic Dark/Midnight Blue Windows golden · **done**. 실제 bundled artwork 검증은 아래 UX-5B로 확장.
> - **UX-5B Bundled theme artwork** — Classic Dark·Midnight Blue 실제 backdrop/Hero 4개 · asset bundle/hash 검증 · 실제 decode/paint golden · **done**.
> - **UX-5C Premium theme artwork** — Sakura·Amethyst·Nocturne reference·palette·effect 확정 · 실제 backdrop/Hero 6개 · 공식 5테마 Windows golden · **done**. Commerce·entitlement는 계속 비활성.
> - **UX-5D Theme extensibility hardening** — 단일 `AkashaThemeRegistry` · ID-only preference migration · Backdrop/Hero/Interaction/Motion effect 분리 · legacy `LibraryTheme` runtime 제거 · 기존 golden 불변 · **done**.
> - **UX-6 Window frame + Theme Gallery** — 32px themed custom chrome · 창모드/최대화/`F11` fullscreen과 Escape 복원 · control 우측 정렬/hover overlay 격리 · Sidebar 하단 `접기` 제거 · 공식 5테마 gallery · offer/access 상태 분리 · **done**. Release runtime에서 F11/Esc 후 원래 window bounds 복원을 확인했다.
> - **Commerce catalog foundation** — Steam Inventory authority·Astra/Echo 정책 SSOT · 공식 테마 패키지 3종 `500 Astra 또는 500 Echo` · 혼합/상호 교환 금지 · provider-neutral `CommerceAccountSnapshot`/`CommerceGateway` · app-root `CommerceController`/scope가 Store·Inventory와 테마 entitlement를 단일 snapshot으로 연결 · unknown balance는 `0` 대신 미확인 표시 · production 구매 CTA/flag는 계속 비활성 · **done**.
> - **POC ItemDef semantics correction** — `playtimegenerator`의 `10002x5`는 수량 5가 아니라 선택 weight이므로 현재 게시 POC는 성공 시 Echo 1개를 지급한다. Fake/test를 실제 의미에 맞췄고 historical JSON은 증거 보존을 위해 유지한다. production 다중 지급은 intermediate Echo bundle을 사용한다.
> - **Production ItemDef local draft** — POC ID 8개는 `hidden` 퇴역하고 출시 정의는 `40000-41199`로 분리했다. Echo는 10분당 10개·1,440분 창당 최대 6회, starter promo/Support 제외, 테마 3종은 Astra 500 또는 Echo 500의 단일 선택 recipe다. JSON·불변조건 테스트는 완료했지만 Steamworks 게시와 feature flag 활성화는 하지 않았다.
> - **Production Steam read gateway** — 단일 production ItemDef registry와 읽기 전용 `SteamInventoryCommerceGateway`를 연결했다. `GetAllItems`의 production 재화/테마만 snapshot으로 만들고 모든 POC ID를 무시하며, `RequestPrices`의 통화 코드와 raw current/base amount를 보존한다. 가격 실패는 유효한 계정 snapshot을 지우지 않고 거래 메서드는 `read_only`로 거부한다. feature flag와 구매 CTA는 계속 비활성이다.
>
> **형식 명세:** [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md)  
> **무한 아카이브 계획:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md)
> **Architecture Closure:** [ARCHITECTURE_CLOSURE_AUDIT.md](ARCHITECTURE_CLOSURE_AUDIT.md) — **declared** (closure baseline: analyze 0 · test 930)
> **Current track:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md)
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

**v1 blocking에 가까운 검증:** root `flutter test` **1156** · vault 아카이브·Sanctum 저장·기록 UI · dogfood(사용자 직접).
**v1 blocking 아님:** registry 작품 수 · recall@10 · Wikidata 확장 · CDN scale.  
**IAP:** `FeatureFlags.steamInAppPurchasesEnabled = false` — 확정 상품·가격의 read-only preview만 존재한다. 활성 구매 CTA·Steam 결제 가능 표시·재심사 주장은 payment flow 검증 전 금지한다.
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
| root `flutter test` | **1156 PASS** | ✅ |
| commerce domain `dart test` | **17 PASS** | ✅ |
| commerce backend `dart test` | **18 PASS** | ✅ |
| `flutter analyze lib` | 0 issue | ✅ |
| `vault_format_validator` | 적합성 검증기 (spec v3 · 앱 무의존) | — |
| `preflight_check` | PASS | ✅ |
| `sw1_a_validation` recall@10 | 87/87 | — |
| `ci_registry_check` | PASS | — |

### Ⅲ. Home Shell

* Wave 1 + Foundation P2 분해 완료 — coordinator·preview·scaffold parts.
* **UX-2 Responsive Shell 완료** — 단일 `AppDestination`·`PreviewTarget`, `ShellLayoutSpec` 3단계, Sidebar/Dock selection SSOT, 기존 Graph/Records 접근, compact drawer·Preview sheet, utility slot 계약. provider 없는 currency/avatar는 숨김.
* **UX-3 Home 핵심 흐름 완료** — 실제 summary Hero, empty start action, theme-owned Hero artwork fallback, ID 기반 scroll 보존 Continue rail, 실제 metadata card, 반응형 Quick Actions, 기존 link index 기반 Connection Insight, record index 기반 Today activity. 미연결·빈 결과·인덱스 오류를 구분하며 새 추천/그래프 기능으로 과장하지 않음.
* **UX-4A Preview hierarchy 완료** — back/close navigation과 primary action 분리, registry-only Work의 archive 의미 명시, 개인 rating·archive CTA 중복 제거, 연결 0건 action menu, 공통 Preview semantic palette. 중복 dormant `PreviewMemoBar` 플래그·위젯 제거.
* **UX-4B Preview responsive density 완료** — inline/overlay 288px rail 유지, compact sheet readable content 680px·Hero 260px 상한, sheet radius/elevation과 공통 spacing 계약, 연결 하위 표면 semantic palette. 125% text와 Classic/Midnight geometry 회귀 검증.
* **UX-4C Destination roles 완료** — `AppDestinationPurpose`로 Explore=discovery, Library=archive, Collections=curation 역할 고정. 공통 context header를 추가하고 entity discovery strip을 Explore `all` scope에만 제한해 Library·Collections의 의미를 분리.
* **UX-4D Graph/Timeline surface 완료** — Graph는 기존 Canvas=`지식 지도`, 파생 link index=`연결 목록`으로 정직하게 구분하고 Timeline은 시간순 기록·메모·엔티티·후보를 포함한 기록 허브 역할을 설명. 검색 chrome·catalog loading·daily recall의 목적지 오염을 `AppDestinationPurpose` 정책으로 제거하고 공통 빈 상태·테마 토큰·키보드 semantics를 적용.
* **v1 관점:** browse/catalog UI는 **기록으로 이어지는 진입**이지 제품 정체성 자체가 아님.

---

## 3. UI 및 워크벤치 (UI & Workbench)

### Ⅰ. 홈 화면

* **나의 서재 (Personal Library):** v1 핵심 — 아카이브 작품 포스터·테마.
* **대시보드 (Dashboard):** optional catalog 탐색 — Fact 카드 그리드.
* **앱 테마 foundation + UX-5A/B/C/D + UX-6 Gallery:** canonical preset 5종과 별도 catalog, preferred/effective resolver, app-root theme, backdrop fallback, 5종 harness 구현. asset namespace·reduced-motion resolver·5테마 핵심 surface geometry matrix를 고정하고 공식 5테마의 실제 backdrop/Hero 10개와 Windows decode/paint golden을 통합했다. preset·catalog·alias는 단일 `AkashaThemeRegistry`에서 등록하고 효과는 Backdrop/Hero/Interaction/Motion으로 분리한다. no-IAP Theme Gallery도 공식 5종을 모두 보여주며 premium 3종은 `planned`와 승인 가격 `500 Astra 또는 500 Echo`를 표시하되 구매 CTA는 비활성이다. Store & Inventory는 app-root `CommerceController`의 nullable snapshot을 읽고, 동일 entitlement snapshot이 premium theme access에도 전달된다. 미연결 재화를 가짜 `0`으로 표시하지 않는다. 이관표는 [UX_THEME_MIGRATION_INVENTORY.md](UX_THEME_MIGRATION_INVENTORY.md), commerce SSOT는 [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md), 회귀 SSOT는 [UX_THEME_REGRESSION_MATRIX.md](UX_THEME_REGRESSION_MATRIX.md), artwork 기록은 [assets/themes/ARTWORK_PROVENANCE.md](../../assets/themes/ARTWORK_PROVENANCE.md).

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
| **M3** | Steam 무료 출시 | **진행 중** — Architecture Closure 선언 · [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md) · no-IAP BuildID **24015480** |
| **Phase 3** | Entity 타입 다각화 (Work 이외) | **미착수** |
| **Phase 4** | 타임라인 아카이브 | **미착수** |
| **Phase 5** | 엔티티 연결성 (Connection) | **미착수** |
