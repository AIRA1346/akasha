# Project Status Snapshot

> **지위:** Historical snapshot (2026-07-16) — **superseded** by [CURRENT_STATE.md](../../active/CURRENT_STATE.md) for live implementation facts
> **원칙:** [AKASHA_ARCHIVE_CONSTITUTION.md](../../active/AKASHA_ARCHIVE_CONSTITUTION.md) · **비전:** [VISION.md](../../active/VISION.md) · **구현 SSOT:** [CURRENT_STATE.md](../../active/CURRENT_STATE.md)
> **출시:** [STEAM_RELEASE.md](../../active/STEAM_RELEASE.md)
> **갱신:** 2026-07-16
> **Git:** `git rev-parse HEAD`
>
> **Verification snapshot (2026-07-16):** root analyze **0** · root test **1195** · commerce domain **17** · backend **18** · Steam Inventory sandbox E2E POC passed · Windows debug/default release/sandbox release build OK · Release runtime F11/Esc window bounds restore passed · `system/` durable vs `.akasha/` derived · **UX-3 Home complete · UX-4A/B/C/D core surfaces done · UX-5A/B/C/D five-theme package, artwork, extensibility hardening done · UX-6 window frame and theme gallery done · Commerce catalog foundation done · Steamworks ItemDef upload candidate/gateway, Store/Inventory UX, guarded sandbox transaction and Echo reward foundation, final operation-port allowlist hardening done** · **Locator index atomic+`.bak` recovery done** (concurrent write lock = follow-up only) · **Entity vault load diagnostics done** · **Entity path index rebuild/upsert issue exposure = follow-up only** · **Workbench recovery draft I/O transition diagnostics done** · **Entity `derivedIndexesUpdated` Home skip + debounce AND-coalesce done** (Work/Journal/Timeline = follow-up) · **HomeShell God Class 전면 리팩터 기각** · **vault-watch dispose lifecycle ACTION A done** · **Package modularization audit closed** — 단일 앱 + `akasha_commerce_domain` only · graph acyclic · no new EXTRACT_NOW · Melos/lib 전면 분할 기각 · Archive=PREPARE_BOUNDARY · Vault/UI/Home=KEEP_IN_APP · Steam→CMake optional when IAP/no-IAP exclude needed · reopen only on documented triggers
> **현재 실행:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md) — Architecture Closure 선언 후 Steam 출시 블로커 트랙
> **IAP:** production 비활성 (`steamInAppPurchasesEnabled = false`). 내부 sandbox define에서만 승인 거래 adapter를 열며, Steamworks 실거래 checklist 완료 전 production 구매·Steam IAP 가능 표시·재심사 주장은 금지.
---

## Executive Summary

| 항목 | 상태 |
|------|------|
| **root flutter test** | **1195 PASS** |
| **commerce package tests** | domain **17 PASS** · backend **18 PASS** |
| **flutter analyze** | **0 issue** (gates clean) |
| **Home UI** | **UX-3A/B/C** ✅ · **UX-4A/B/C/D 핵심 surface** ✅ · honest CTA · responsive Preview · 목적지 역할/빈 상태 분리 |
| **앱 테마** | UX-5A/B/C/D + UX-6 Gallery ✅ · canonical 5 preset · 단일 registry · 공식 5종 노출 · premium 3 planned · 승인 가격 500 Astra/500 Echo preview · 실제 backdrop/Hero 10개 · 구매 CTA 비활성 |
| **Commerce UX 기반** | Steam Inventory authority SSOT · 공식 테마 패키지 3종 · production ItemDef registry/gateway · app-root controller/scope · Store/Inventory/theme access 단일 snapshot · Astra pack/theme section · loading/offline/retry/owned · sandbox 확인 dialog/단일 재화 교환 · 선택 재화 즉시 소비/영구 해제 고지 · gateway+MethodChannel 이중 ItemDef allowlist · 별도 Echo reward capability · terminal result+inventory reconciliation · compact/125% text · POC ID 무시 · fake zero/혼합결제/재화교환 금지 ✅ |
| **Responsive Shell** | UX-2A/B/C + UX-6 Window frame · destination/preview SSOT · 256/232/drawer · 288 inline/overlay/sheet · custom chrome · 창/최대화/F11 fullscreen · 기존 Graph/Records 접근 ✅ |
| **Steam Inventory** | 기존 POC purchase/exchange·Overlay E2E 통과 ✅ · production `40110-40112` KRW 가격 조회 통과 · 세 판매 팩의 `store_hidden=true`가 callback `k_EResultFail`/transaction ID `0`을 유발했고 `40110.store_hidden=false` 단일 변수 A/B에서 Steam checkout Overlay가 열려 원인 확정 ✅ · `40001`은 숨김 유지, 실제 판매 팩 3종만 store-visible · `40111-40112` 동일 revision 게시·checkout 검증 대기 · production IAP는 계속 비활성 |
| **사이드바 서재** | `나만의 서재` 목록·active·`+`·select·삭제·DnD ✅ |
| **Poster Localizing** | URL 입력 → vault `posters/` 저장 → `poster: "posters/..."` ✅ |
| **Canvas Editor (지식 지도)** | v0.3-B.1 ✅ · v0.3-A.5 viewport persist ✅ · v0.3-B.2a inertia zoom guard ✅ · Work/Entity 더블클릭 → Workbench · Canvas+Detail 2탭 — [CANVAS_NODE_OPEN_v0.3-B.1_IMPLEMENTATION_PLAN.md](../programs/canvas-editor/CANVAS_NODE_OPEN_v0.3-B.1_IMPLEMENTATION_PLAN.md) |
| **Agent Vault UI** | Work Journal 감상 카드 slice ✅ · dogfood 관찰은 [AGENT_VAULT_UI_DOGFOOD_REVIEW.md](ux-discovery/AGENT_VAULT_UI_DOGFOOD_REVIEW.md) |
| **Infinite Taste Archive** | 외부 도구/AI가 읽기 쉬운 개인 취향 아카이브 ADR ✅ · `.akasha/record_index.json` slice ✅ — [AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md](../../active/AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md) |
| **Infinite Archive Hardening** | 무한 확장을 위한 index · taste signal · agent write contract · ID path 계획 ✅ — [INFINITE_ARCHIVE_HARDENING_PLAN.md](../../active/INFINITE_ARCHIVE_HARDENING_PLAN.md) |
| **Pre-release Architecture Audit** | Vault Layout v3 canonical 후보 — ID path · unified operation · candidate/taste 계약 감사 ✅ — [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) |
| **Vault Layout v3 Slice** | 새 Work/Entity ID path canonical · `schema_version: 3` · full tests **709 PASS** · analyze **0** ✅ |
| **ArchiveOperation Contract** | `createRecord/updateFrontmatter/appendSection/tag/rating/status/link/promote/merge` validator slice ✅ · focused tests **11 PASS** · analyze **0** |
| **Candidate Store** | `catalog/candidates.json` · 후보/승격/중복 검증 · focused archive contract tests **21 PASS** ✅ |
| **Candidate Store Scale** | `system/candidates/*` sharded queue · name-index duplicate lookup · legacy candidate JSON read compatibility · full tests **718 PASS** |
| **Taste Index** | `.akasha/indexes/taste_index.json` evidence-backed rating/status/favorite/tag/memo/quote/link signals · focused tests **2 PASS** · full tests **720 PASS** · analyze **0** |
| **Index Manager** | `ArchiveIndexManager` record/entity/link/candidate/taste rebuild coordinator · candidate name-index recovery · focused tests **17 PASS** · full tests **723 PASS** · analyze **0** |
| **Incremental Indexing** | changed/deleted Markdown path updates record/taste/link/entity-path/title-alias indexes without full vault scan · focused title/link/entity tests **25 PASS** · write-flow tests **19 PASS** · full tests **733 PASS** · analyze **0** |
| **Title/Alias Index** | `.akasha/title_alias_index/names/{shard}.json` resolves normalized title/alias/original/localized names to stable IDs without Markdown scans · focused tests **9 PASS** · full tests **733 PASS** · analyze **0** |
| **Index Validator** | `ArchiveIndexValidatorService` rebuilds and audits record/entity-path/title-alias/link/candidate/taste indexes against Markdown source · focused validator tests **5 PASS** · focused index suite **27 PASS** · full tests **738 PASS** · analyze **0** |
| **Record Contract** | `ArchiveRecordContract` freezes v3 Work/Entity/Journal/Timeline metadata (`created_at`, `updated_at`, `source`, `aliases`, `original_title`, `external_ids`, `evidence`, `links`) · focused contract suite **60 PASS** · full tests **774 PASS** · analyze **0** |
| **Operation Executor** | validated `promoteCandidate` → Entity journal · catalog mirror · candidate close ✅ · focused contract tests **34 PASS** · full tests **709 PASS** |
| **Operation Applied Log** | `system/ops/applied.jsonl` · `operationId` retry-safe · `alreadyApplied` result ✅ |
| **Operation Conflict Guard** | `expectedRevision` · mtime/length/hash revision · existing target overwrite block ✅ |
| **Ultimate Archive Backlog** | 발견된 후속 작업 전체 목록화 ✅ — [ULTIMATE_ARCHIVE_BACKLOG.md](../../draft/ULTIMATE_ARCHIVE_BACKLOG.md) |
| **v1 핵심** | **Personal Sanctum vault 아카이브** — 말하기/쓰기 → `.md`/YAML → 예쁜 UI → 외부 도구가 읽기 쉬운 기록 |
| **Phase 1** | Record Foundation ✅ |
| **Sanctum** | C1~C4 ✅ · Vault agent 가이드 ✅ |
| **코드 건강** | Phase 0~7 ✅ · Foundation P2 분해 ✅ |
| **Registry (akasha-db)** | **10,048 works** · **이중 추적 감사 중** — [AKASHA_DB_OWNERSHIP_AUDIT.md](../programs/akasha-db-ownership/AKASHA_DB_OWNERSHIP_AUDIT.md) |
| **다음** | BuildID **24015480** default branch Set Live · Steamworks Build review 갱신 · akasha-db 구조 A/B/C 결정 **보류** |
| **Steam** | 자동 gate ✅ · 수동 dogfood ✅ · 무료 출시 copy ✅ · no-IAP BuildID **24015480** 업로드 완료 |

---

## 1. Steam v1 제품 방향 (2026-06-30)

**v1 핵심:** 글로벌 작품 사전이 아니라 **개인 Sanctum vault 아카이브 앱**.

```
감상을 말하거나 직접 작성
  → Sanctum vault .md / YAML 저장
  → AKASHA가 예쁘게 정리·표시
  → 에이전트가 vault를 읽고 편집하며 기록을 도움
```

| v1 우선 (blocking에 가깝게) | v1에서 낮춤 (구현 유지 · 메시지·우선순위만) |
|-----------------------------|-----------------------------------------------|
| 로컬 vault 안정성 · watch · 원자적 저장 | 10k 글로벌 사전 **강조** |
| 직접 작품 추가 · 아카이브 `.md` 생성 | 대규모 registry **확장** 트랙 |
| 감상·평점·상태·태그·명장면·갤러리 (Sanctum) | TMDB/IGDB 자동 메타·포스터 연동 **제외** · 식별자 Fact만 유지 |
| Personal Library · Collection | Discovery / recommendation |
| Agent Vault Protocol v1 범위 ([AGENT_VAULT_PROTOCOL_V1.md](../../active/AGENT_VAULT_PROTOCOL_V1.md)) · 현장 ([VAULT_AGENT_GUIDE.md](../../active/VAULT_AGENT_GUIDE.md)) | CDN·search recall **scale gate**를 v1 출시 조건으로 두지 않음 |
| 예쁜 기록 UI (Workbench · Sanctum) | |

**akasha-db / registry:** 삭제하지 않음 — **optional catalog support** · starter catalog · **post-v1 scale track**.

**Steam 출시:** Early Access가 아니라 **무료 일반 출시**로 진행. 앱 내 구매/유료 테마는 post-launch로 보류.

### 이전 운영 결정 (2026-06-10, 역사 보존)

당시 **430작은 Steam 출시에 충분하지 않다**는 전제로 catalog 성장·SD2.6 해제를 결정했다.
2026-06-30 재정렬 이후 **v1 출시를 막는 조건은 개인 아카이브 품질**이며, registry 규모 확장은 **post-v1**로 이동한다.
아래 Gate 표의 registry·recall 수치는 **엔지니어링 자산**으로 보존한다.

---

## 2. Gate (@10048)

> Registry·검색 상세는 [CURRENT_STATE.md](../../active/CURRENT_STATE.md). **v1 blocking**은 §3 참고.

| 도구 | 결과 | v1 blocking |
|------|:----:|:-----------:|
| root `flutter test` | **1159 PASS** | ✅ |
| commerce domain `dart test` | **17 PASS** | ✅ |
| commerce backend `dart test` | **18 PASS** | ✅ |
| `flutter analyze` | **0 issue** | ✅ |
| `preflight_check` | PASS | ✅ |
| `registry_builder` | PASS | — (post-v1 scale) |
| `dedupe_linter` | PASS (10048) | — |
| `quality_gate --strict` | PASS | — |
| `ci_registry_check` | PASS | — |
| `sw1_a_validation` recall@10 | 87/87 | — (optional catalog QA) |
| `dogfood_precheck.ps1 -Build` | PASS | ✅ |

---

## 3. Release Readiness — Steam v1

| 게이트 | 상태 | v1 blocking | 비고 |
|--------|:----:|:-----------:|------|
| **G-AUTO** | ✅ | ✅ | app **1159** · domain **17** · backend **18** · analyze **0** · debug/release build **PASS** |
| **G-VAULT** | ✅ | **✅** | 볼트 연동·아카이브·Sanctum 저장·기록 UI — 사용자 수동 dogfood 완료 |
| **G-QA** | ✅ | ✅ | P0 수동 **12/12** (2026-06-13) · 사용자 dogfood 확인 |
| **G-STEAM** | 🔶 | ✅ | no-IAP BuildID **24015480** 업로드 완료 · Set Live/review 대기 |
| **G-COPY** | ✅ | ✅ | Privacy doc · [STEAM_RELEASE.md](../../active/STEAM_RELEASE.md) copy |
| **G-CATALOG** | ✅ | — | 10048작 · recall 87/87 — **optional / post-v1 scale** |
| **G-DISCOVERY** | ✅ | — | Wikidata spine — **v1 메시지·blocking 아님** |

---

## 4. 병행 트랙

| 트랙 | 다음 | v1 우선 |
|------|------|:-------:|
| **정리 스프린트** | dead wiring·도구·Registry legacy 정리 ✅ · analyze 0 · test 952 | — |
| **akasha-db 소유권** | backup branch 완료 · 장기 A/B/C 구조 결정은 보류 | — |
| **Personal Archive (v1)** | vault 안정성 · Sanctum · Library/Collection · Agent Protocol | **P0** |
| **Sprint B** | ✅ B1 · Vault agent 가이드 | — |
| **Wave 1 Home** | ✅ shell 분해 완료 | — |
| **Foundation P2** | ✅ scaffold · dialogs · fusion | — |
| **Catalog / akasha-db** | optional starter · CI 관측 | post-v1 |
| **Discovery / Scale** | Wikidata · 10k+ 확장 | post-v1 |
| **Steam 무료 출시** | **진행** (사용자 지시) | ✅ |

---

## 5. 코드 건강 스프린트 (2026-06)

| Phase | 내용 | 상태 |
|:---:|------|:---:|
| 0 | README SSOT · `PROJECT_STATUS` 정리 | ✅ |
| 1 | Vault works 레이아웃 rename | ✅ |
| 2 | `FeatureFlags` v1 post-v1 UI 숨김 | ✅ |
| 3 | Workbench 상태 레이어 분해 (archive·link pick·connections coordinator) | ✅ |
| 4 | `tool/archive` · `tool/migrations` 스크립트 이동 | ✅ |
| 5 | `registry_shard_loader` workId 캐시 | ✅ |
| 6 | vault fingerprint 조건부 polling | ✅ |
| 7 | Home preview·recent·archive/reorder · Workbench shared ops | ✅ |
| **S** | **Sanctum C1~C4** — wiki 칩·출연·갤러리·완성도·템플릿·HTML | ✅ |
| **F** | **Foundation F0~F4** — 감사·Sanctum 분해·R14-B·레거시 정책 | ✅ |

**대형 파일 (2026-06-30 재실측 · Post-P2):** `markdown_body_editor` **503** (shell + parts) · `home_shell_body` **479**

**P2 분해 완료 (shell 줄 수 · code baseline `5526ce4`):** `home_shell_scaffold` **31** (`194db17`) · `home_dialogs_coordinator` **124** (`955967e`) · `franchise_fusion_service` **76** (`5526ce4`)

**P27~P31·P30 후속:** `work_library_panel` **162** · `dashboard_sidebar` **152** · `browse_dashboard_sections` **165** · `collectible_collection_edit_dialog` **73** · P30 dialog 저장 widget test **4** · `poster_card_layouts` **~270** (P24) · markdown editor 6 parts (P26)

감사 SSOT: [FOUNDATION_AUDIT.md](foundation/FOUNDATION_AUDIT.md) · Vault: [AGENT_VAULT_PROTOCOL_V1.md](../../active/AGENT_VAULT_PROTOCOL_V1.md) · [VAULT_AGENT_GUIDE.md](../../active/VAULT_AGENT_GUIDE.md)

---

## 6. 다음 권장 작업

| # | 작업 | 우선 |
|---|------|:----:|
| 1 | ~~내부 repo **backup branch push**~~ → **`backup/local-sync-20260630` @ `bef52e7`** ✅ | **완료** |
| 2 | `main` release baseline push | P0 |
| 3 | BuildID **24015480** default branch Set Live + Steamworks Build review 갱신 | P0 |
| 4 | Store screenshots 촬영 (demo/owned/generated images only) | P0 |
| 5 | Agent Vault Protocol v1 구현·dogfood | **post-launch** |
| 6 | Operation crash recovery marker — write 성공 후 log 실패를 roll-forward | P0 architecture |
| 7 | ~~Locator index in-place overwrite + corrupt silent empty + `.bak` restart recovery~~ | **완료** — `DerivedIndexAtomicWrite` · Record/Entity path indexes · analyze **0** · test **1030** |
| 8 | Locator concurrent write lock (same shard/file) | **후속 감사 후보** — 이번 Locator 종료와 분리 · 착수 전 dogfood 확인 |
| 9 | ~~Entity malformed Markdown/YAML silent skip~~ | **완료** — `loadFromVaultWithIssues` · no auto-log · callers unchanged |
| 10 | `EntityPathIndexService.rebuildFromVault` parse/I/O issue 미노출 | **후속 감사 후보** — 상세 API 단독 추가는 보류(호출자가 `rebuildFromVault`만 쓰면 issues 폐기). `upsertMarkdownFile` 동일 비대칭. 명시적 index audit/rebuild 소비자 등장 시 `parseDetailed`+`EntityVaultLoadIssue` 재사용 |
| 11 | ~~Work/Entity recovery draft I/O silent catch~~ | **완료** — 전환형 `appLog` · UI/포맷 불변 |
| 12 | Recovery draft late-write vs delete race · stale vs vault freshness · deactivate flush 비대칭 | **후속 감사 후보** — 이번 진단 슬라이스와 분리 |
| 13 | ~~Entity Home duplicate derived index mutation~~ | **완료** — `derivedIndexesUpdated` · Entity only · UI side-effects kept |
| 14 | Work/Journal/Timeline Home duplicate index mutation | **후속 감사 후보** — Entity와 동일 패턴 · 미적용 |

---

## 7. Ops Watchlist (300+)

> 운영·구조 백로그 — 신규 기능 ID와 분리. **301+** 번호대.

| ID | 항목 | 상태 | SSOT |
|:--:|------|:----:|------|
| **301** | akasha-db **이중 추적** 구조 감사 (vendored + nested `.git`) | ✅ draft | [AKASHA_DB_OWNERSHIP_AUDIT.md](../programs/akasha-db-ownership/AKASHA_DB_OWNERSHIP_AUDIT.md) |
| **302** | 내부 `akasha-db` **148파일** → `backup/local-sync-20260630` @ **`bef52e7`** | ✅ pushed | audit §6 |
| **303** | 장기 구조 결정 — **A** vendored+`.git` 제거 · **B** submodule/subtree · **C** dual push | ⏸️ 보류 | audit §5 |
| **304** | `AIRA1346/akasha-db` remote vs 앱 repo shard 커밋 **동기화** | 🔶 | audit §3.1 |
| **305** | registry manifest 4파일 — 동일 `generatedAt` metadata를 별도 커밋으로 정렬 | ✅ `8ada29d5` | 본 문서 헤더 |
| **306** | Home UI 정리 — search-first · Slice 1 앱 테마 · Slice 2 사이드바 서재 · dead wiring cleanup | ✅ | `0db21d38` |
| **307** | root `flutter test` **952** · `flutter analyze` **0** 유지 | ✅ | §2 Gate |
| **308** | Agent Vault UI dogfood — P1-8 raw wiki link · P1-9 중앙 감상 밀도 · P1-10 앱 테마 범위 | 🔶 | [AGENT_VAULT_UI_DOGFOOD_REVIEW.md](ux-discovery/AGENT_VAULT_UI_DOGFOOD_REVIEW.md) |
| **309** | M3 · Agent/player implementation layer · 대규모 index/path migration | 🚫 **금지** (본 스프린트) | — |
| **310** | 중복 dormant `PreviewMemoBar`와 `showPreviewMemoBar` 제거 — `내 감상`을 단일 진입점으로 유지 | ✅ UX-4A | [UX_DESIGN_SYSTEM.md](../../active/UX_DESIGN_SYSTEM.md) §11 |
| **311** | Poster URL localizing — URL 입력 → vault `posters/` 저장 → YAML 상대경로 | ✅ | `6922f0a` |
| **312** | Infinite Taste Archive ADR — AI/플레이어가 아닌 외부 도구 친화적 취향 아카이브 경계 | ✅ | [AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md](../../active/AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md) |
| **313** | Steam 무료 출시 RC — 자동 gate green, 수동 dogfood 완료, no-IAP BuildID **24015480** 업로드 완료 · Set Live/review 대기 | 🔶 | [STEAM_RELEASE.md](../../active/STEAM_RELEASE.md) |
| **314** | Derived record index — `.akasha/record_index.json`로 record 요약·tagIndex 작성 | ✅ | [record_summary_index_service.dart](../../../lib/services/record_summary_index_service.dart) |
| **315** | Vault trash safety slice — Work/Entity/Journal/Timeline 삭제를 `.trash/` 격리로 전환 | ✅ | [vault_trash_service.dart](../../../lib/services/vault_trash_service.dart) |
| **316** | Vault ZIP backup export — 볼트 전체를 표준 `.zip`으로 내보내기 | ✅ | [vault_backup_exporter.dart](../../../lib/services/vault_backup_exporter.dart) |
| **317** | Workbench recovery drafts — Work/Entity 편집 중 `system/drafts/` 임시 스냅샷 · Snackbar 복구 제안 | ✅ | [workbench_recovery_draft_store.dart](../../../lib/services/workbench_recovery_draft_store.dart) |
| **318** | Vault trash UI — Vault 설정에서 휴지통 목록·복구·영구 삭제 | ✅ | [vault_trash_dialog.dart](../../../lib/screens/home/dialogs/vault_trash_dialog.dart) |
| **319** | Desktop preferences slice — `Esc` 앱 메뉴 · 한국어/English 전환 · 표시 배율 저장 · 종료 버튼 | ✅ | [app_preferences_dialog.dart](../../../lib/screens/home/dialogs/app_preferences_dialog.dart) |
| **320** | Infinite Archive Hardening Plan — index · taste signal · agent write contract · ID path 기준 정리 | ✅ docs | [INFINITE_ARCHIVE_HARDENING_PLAN.md](../../active/INFINITE_ARCHIVE_HARDENING_PLAN.md) |
| **321** | Ultimate Archive pre-release audit — Vault Layout v3 canonical 전환 가능성 평가 | ✅ docs | [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) |
| **322** | Vault Layout v3 feasibility slice — `VaultRecordPathResolver` · 새 Work/Entity ID path · schema_version 3 | ✅ code | [vault_record_path_resolver.dart](../../../lib/services/vault_record_path_resolver.dart) |
| **323** | ArchiveOperation contract slice — agent/app/script write intent model · validator · operation JSON round-trip | ✅ code | [archive_operation_validator.dart](../../../lib/core/archiving/archive_operation_validator.dart) |
| **324** | Candidate Store slice — `catalog/candidates.json` · promotion validator · duplicate/title/type checks | ✅ code | [archive_candidate_store.dart](../../../lib/services/archive_candidate_store.dart) |
| **325** | Ultimate Archive backlog — 놓치면 안 되는 operation/index/taste/taxonomy/agent 후속 작업 목록화 | ✅ docs | [ULTIMATE_ARCHIVE_BACKLOG.md](../../draft/ULTIMATE_ARCHIVE_BACKLOG.md) |
| **326** | Operation Executor slice — validated `promoteCandidate`를 Entity journal + catalog mirror + candidate close로 실행 | ✅ code | [archive_operation_executor.dart](../../../lib/services/archive_operation_executor.dart) |
| **327** | Operation Applied Log slice — `system/ops/applied.jsonl`로 operation retry를 idempotent 처리 | ✅ code | [archive_operation_applied_log.dart](../../../lib/services/archive_operation_applied_log.dart) |
| **328** | Operation Conflict Guard slice — `expectedRevision`과 파일 revision으로 기존 target overwrite 차단 | ✅ code | [archive_record_revision_service.dart](../../../lib/services/archive_record_revision_service.dart) |

---

| **329** | Candidate Store Scale slice — `system/candidates/*` sharded queue + name-index duplicate lookup + legacy `catalog/candidates.json` read compatibility | ✅ code | [archive_candidate_store.dart](../../../lib/services/archive_candidate_store.dart) |
| **330** | Taste Index slice — `.akasha/indexes/taste_index.json` evidence-backed signals for future external tools | ✅ code | [taste_index_service.dart](../../../lib/services/taste_index_service.dart) |
| **331** | Index Manager slice — one rebuild coordinator for record/entity/link/candidate/taste indexes plus candidate name-index recovery | ✅ code | [archive_index_manager.dart](../../../lib/services/archive_index_manager.dart) |
| **332** | Incremental Indexing slice — changed/deleted Markdown path updates record/taste indexes without full rebuild | ✅ code | [archive_index_manager.dart](../../../lib/services/archive_index_manager.dart) |
| **333** | Incremental Index Wiring slice — Work/Entity/Journal/Timeline save-delete flows use `ArchiveIndexManager` for record+taste updates | ✅ code | [file_service_save.dart](../../../lib/services/file_service_save.dart) |
| **334** | Link/Entity Incremental slice — `ArchiveIndexManager` also updates link outgoing/incoming and entity-path indexes for changed/deleted Markdown paths | ✅ code | [record_link_index_service.dart](../../../lib/services/record_link_index_service.dart) |
| **335** | Title/Alias Index slice — `.akasha/title_alias_index` sharded name lookup for Work/Entity natural-language resolution | ✅ code | [title_alias_index_service.dart](../../../lib/services/title_alias_index_service.dart) |
| **336** | Index Validator slice — rebuild and audit derived indexes against Markdown source for duplicate IDs, stale paths, missing names, link drift, and taste evidence drift | ✅ code | [archive_index_validator_service.dart](../../../lib/services/archive_index_validator_service.dart) |
| **337** | Record Contract slice — shared v3 frontmatter metadata for Work/Entity/Journal/Timeline with v1/v2 read compatibility | ✅ code | [archive_record_contract.dart](../../../lib/core/archiving/archive_record_contract.dart) |

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Phase 0 baseline @430 |
| 2026-06-10 | G2 50% · 문서 IA 재편 |
| 2026-06-10 | **SD2.6 해제** · catalog-growth-charter · 병행 확장 |
| 2026-06-10 | **Release audit** — 490작 · test 250 · release-readiness-checklist |
| 2026-06-13 | Steam depot·P0 QA 12/12 — [release-readiness-checklist](../release-readiness-checklist.md) |
| 2026-06-14 | Wave 1 2차 — coordinator·HomeShellBody · shell 1004줄 |
| 2026-06-14 | Wave 1 3차 — UI glue 분리 · shell 710 · test 268 |
| 2026-06-14 | Wave 1 4차 — controller·scaffold · shell **40줄** · test 271 |
| 2026-06-14 | **phase1-work-e2e-plan** — E2E 우선 · Scale/Core 보류 |
| 2026-06-14 | Sprint **A2** Dogfood E2E ✅ |
| 2026-06-14 | **M3 보류** → Sprint **B** |
| 2026-06-16 | sliver grid 스크롤 · **extensibility-hardening-plan** · test **305** |
| 2026-06-16 | E2-5 Port DI · E2-6 workspace 분리 · E1-A3b 순환 제거 · test 318 |
| 2026-06-24 | 코드 건강 Phase 0~6 — vault·FeatureFlags·workbench coordinator·`tool/` archive·polling · test **580** |
| 2026-06-24 | 코드 건강 Phase 7b — save ops·collection reorder·docs SSOT · test **591** |
| 2026-06-25 | **Sanctum C1~C4** · Foundation F0 감사 · test **605** · [FOUNDATION_AUDIT.md](foundation/FOUNDATION_AUDIT.md) |
| 2026-06-30 | **Steam v1 재정렬** — 개인 Sanctum 아카이브 중심 · registry scale post-v1 · code **5526ce4** |
| 2026-06-30 | **Agent Vault Protocol v1** — [AGENT_VAULT_PROTOCOL_V1.md](../../active/AGENT_VAULT_PROTOCOL_V1.md) 범위 문서 |
| 2026-06-30 | **Post-P2 SSOT** — scaffold·dialogs·fusion 분해 · SSOT **57c66fd** · code **5526ce4** · test **614** |
| 2026-06-29 | **Post-P30 후속** — dialog 저장 widget test **4** · P30 dialog test commit **48c8c39** · test **614** |
| 2026-06-30 | **Home UI 안정화** — search-first · Slice 1 앱 테마 · Slice 2 사이드바 `나만의 서재` · cleanup **0db21d38** |
| 2026-06-30 | **akasha-db 백업** — `backup/local-sync-20260630` @ **`bef52e7`** (`AIRA1346/akasha-db`, main unchanged) |
| 2026-06-30 | **Poster URL localizing** — URL → vault `posters/` · commit **6922f0a** · 사용자 실기 확인 ✅ |
| 2026-06-30 | **Infinite Taste Archive ADR / Steam RC gate** — tip **2b3d292c** · analyze **0** · test **647** |
| 2026-06-30 | **Derived record index slice** — `.akasha/record_index.json` · work/entity/timeline/journal summary · analyze **0** · test **649** |
| 2026-07-01 | **Vault trash safety slice** — delete paths `.trash/` quarantine · analyze **0** · test **652** |
| 2026-07-01 | **Vault ZIP backup export** — Vault settings에서 `.zip` 백업 생성 · analyze **0** · test **654** |
| 2026-07-01 | **Workbench recovery drafts** — `.akasha/recovery/` 임시 스냅샷 · Work/Entity 복구 Snackbar · analyze **0** · test **657** |
| 2026-07-01 | **Vault trash UI** — Vault 설정에서 휴지통 목록·복구·영구 삭제 · analyze **0** · test **658** |
| 2026-07-01 | **Desktop preferences slice** — `Esc` 앱 메뉴 · 한국어/English 전환 · 표시 배율 · 종료 버튼 · analyze **0** · test **664** · release build **PASS** |
| 2026-07-02 | **Steam 무료 출시 정리** — Early Access 미사용 · 앱 내 구매 post-launch · no-IAP 테마 UI 정리 · [STEAM_RELEASE.md](../../active/STEAM_RELEASE.md) |
| 2026-07-02 | **App theme palette 확장** — `AkashaPalette` ThemeExtension · sidebar/bottom/search/card/preview rail 테마 반영 · analyze **0** · test **672** · release build **PASS** |
| 2026-07-03 | **Infinite Archive Hardening Plan** — AKASHA를 AI 서비스가 아닌 궁극의 아카이브 기반층으로 유지하기 위한 index · taste signal · agent write · ID path 기준 정렬 |
| 2026-07-03 | **Ultimate Archive Pre-release Audit** — 출시 전 Vault Layout v3 canonical 후보 확정: 새 Work/Entity는 ID path, agent write는 operation contract 중심 |
| 2026-07-03 | **Vault Layout v3 feasibility slice** — central path resolver · 새 Work/Entity ID path · `schema_version: 3` · full tests **709 PASS** · analyze **0** |
| 2026-07-03 | **ArchiveOperation contract slice** — agent/app/script 쓰기 intent 모델 · validator · JSON round-trip · focused tests **11 PASS** · full tests **709 PASS** · analyze **0** |
| 2026-07-03 | **Candidate Store slice** — `catalog/candidates.json` · candidate/promoted/dismissed/merged 상태 · 승격 중복/타입 검증 · focused archive contract tests **21 PASS** · full tests **709 PASS** |
| 2026-07-03 | **Ultimate Archive Backlog** — operation execution · index scale · taste signal · markdown contract · entity taxonomy · agent/tool 후속 작업 목록화 |
| 2026-07-03 | **Operation Executor slice** — `promoteCandidate` operation end-to-end 실행: entity journal · catalog mirror · candidate promoted · indexes 생성 · focused contract tests **34 PASS** · full tests **709 PASS** · analyze **0** |
| 2026-07-03 | **Operation Applied Log slice** — `.akasha/ops/applied.jsonl` · operationId 중복 적용 방지 · repeated `promoteCandidate`는 `alreadyApplied`로 반환 |
| 2026-07-03 | **Operation Conflict Guard slice** — `expectedRevision`을 mtime/length/hash 파일 revision으로 정의 · 기존 target 파일/스테일 revision은 `operation_conflict`로 차단 |
| 2026-07-03 | **Taste Index slice** — `.akasha/indexes/taste_index.json` · rating/status/favorite/tag/memo/quote/link signals · focused tests **2 PASS** · analyze **0** |
| 2026-07-03 | **Index Manager slice** — `ArchiveIndexManager` rebuild coordinator · candidate name-index recovery · focused tests **17 PASS** · full tests **723 PASS** · analyze **0** |
| 2026-07-04 | **Incremental Indexing slice** — changed/deleted Markdown path updates record/taste indexes · vault-contained path guard · focused tests **10 PASS** · full tests **727 PASS** · analyze **0** |
| 2026-07-04 | **Incremental Index Wiring slice** — Work/Entity/Journal/Timeline save-delete flows now update record+taste indexes through `ArchiveIndexManager` · focused write-flow tests **19 PASS** · analyze **0** |
| 2026-07-04 | **Link/Entity Incremental slice** — changed/deleted Markdown path updates link outgoing/incoming and entity-path indexes without full rebuild · focused tests **16 PASS** · analyze **0** |
| 2026-07-04 | **Title/Alias Index slice** — `.akasha/title_alias_index` sharded lookup resolves title/alias/original/localized names to stable IDs · focused tests **9 PASS** · full tests **733 PASS** · analyze **0** |
| 2026-07-04 | **Index Validator slice** — `ArchiveIndexValidatorService` rebuilds and audits derived indexes against Markdown source · focused tests **5 PASS** · full tests **738 PASS** · analyze **0** |
| 2026-07-06 | **Date Semantics & Timestamps Alignment** — `UA-114`/`UA-115`/`UA-116` audits and alignments, Z-suffix UTC serialization, timeline occurredAt analysis, tests updated · full tests **774 PASS** · analyze **0** |
| 2026-07-06 | **Entity Custom-to-Object Migration** — Transformed `custom` entity type to `object` (`ob_` prefix) across all layers, kept `cu_` backward compatibility fallback, updated arb l10n, test **774 PASS** · analyze **0** |
| 2026-07-04 | **Record Contract slice** — `ArchiveRecordContract` standardizes v3 metadata and preserves additive fields across app rewrites · focused tests **60 PASS** · full tests **743 PASS** · analyze **0** |
| 2026-07-08 | **Canvas Editor Stabilization v0.3-A.4** — viewport listener 통합 · `canvas_viewport_controls`/`canvas_editor_modes` partial extraction · SSOT 문서 · decomposition plan · full tests **826 PASS** · analyze **0** |
| 2026-07-08 | **Canvas Node Open v0.3-B.1** — Work/Entity 더블클릭 → Workbench · `openDetailBesideCanvas` (canvas active만 2탭) · browse open 경로 유지 · release build PASS · full tests **830 PASS** · analyze **0** · tip **f65e2a03** |
| 2026-07-08 | **Canvas viewport persist v0.3-A.5** — layout session registry · Work/Entity 이탈/복귀 viewport 유지 · `alignment: topLeft` · full tests **838 PASS** · analyze **0** |
| 2026-07-08 | **Canvas inertia zoom guard v0.3-B.2a** — pan fling 관성 중 wheel zoom 차단 · wheel `onInteractionStart` lock 해제 버그 수정 · Windows release build PASS · tip **`8df18978`** |
| 2026-07-13 | **UX-1 Theme foundation** — canonical 5 preset · 무료 2/premium 3 catalog · preferred/effective resolver · app-root theme · backdrop/harness · full tests **974 PASS** · analyze **0** · Windows debug build PASS |
| 2026-07-13 | **UX-2 Responsive Shell** — `AppDestination`/`PreviewTarget` SSOT · 3단계 `ShellLayoutSpec` · Sidebar/Dock 일치 · 기존 Graph/Records 접근 · dirty Workbench navigation guard · full tests **1011 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-3A Home Hero** — 실제 record/entity/collection/tag summary · empty start action · `AkashaThemeVisuals` Hero asset/effect 계약 · 3 viewport/125% text · Classic/Midnight geometry 동일 · full tests **1085 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-3B Continue + Quick Actions** — ID 기반 rail scroll 보존 · 실제 status/tag/creator · 휴리스틱 % 제거 · empty Explore action · 1/2/3열 action panel · keyboard/focus/theme geometry · full tests **1094 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-3C Connection + Today** — 기존 link index의 실제 집계 · record index의 당일 added/updated 활동 · loading/empty/unavailable/error 분리 · Vault 전환 재조회 · 3단계 하단 grid · 125% text/Classic-Midnight geometry · full tests **1102 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-4A Preview hierarchy** — back/close와 primary action 분리 · registry archive/detail 의미 정합 · 중복 rating/archive/memo 제거 · 연결 action menu · semantic palette · keyboard/Work+Entity 125% text/theme geometry · full tests **1107 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-4B Preview responsive density** — 288px inline/overlay 유지 · compact sheet content 680px/Hero 260px 상한 · 공통 surface/spacing · 연결 하위 표면 semantic palette · 3 presentation/125% text/Classic-Midnight geometry · `AkashaColors` **354→342 lines** · full tests **1110 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-4C Destination roles** — `AppDestinationPurpose` SSOT · Explore/Library/Collections context header · entity strip Explore-all 한정 · Library archive/Collections curation 분리 · 3 viewport/125% text/Classic-Midnight geometry · `AkashaColors` **342→334 lines** · full tests **1115 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-4D Graph/Timeline surfaces** — Graph 기존 Canvas=`지식 지도`/파생 index=`연결 목록` 구분 · Timeline 기록 허브 설명 · 목적지별 search/loading/recall chrome 정책 · 공통 empty/unavailable state · 탭 semantics · vault path reload · 3 viewport/125% text/Classic-Midnight geometry · `AkashaColors` **334→328 lines** · full tests **1119 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-5A Theme package regression foundation** — 5 preset asset namespace/fallback/reduced-motion 계약 · 5테마 핵심 surface × 3 viewport × 125% text geometry · Classic Dark/Midnight Blue Windows golden · 실제 artwork와 commerce는 후속 · full tests **1121 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-5B Bundled theme artwork** — Classic Dark·Midnight Blue 실제 backdrop/Hero 4개 (`6,282,701 bytes`) · asset namespace/bundle/hash 검증 · actual decode/paint Backdrop+Hero golden · provenance/prompt 기록 · premium 3종과 commerce는 후속 · full tests **1124 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-14 | **UX-5C Premium theme artwork** — Sakura·Amethyst·Nocturne 실제 backdrop/Hero 6개 · 공식 5테마 artwork 10개 · Windows decode/paint golden · release bundle hash 일치 · commerce는 후속 · full tests **1124 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-15 | **UX-5D Theme extensibility hardening** — 단일 `AkashaThemeRegistry` · ID-only preference migration · Backdrop/Hero/Interaction/Motion effect 분리 · `LibraryTheme` runtime 제거 · 기존 golden 불변 · `AkashaColors` **328 lines / 81 files** 유지 · full tests **1124 PASS** · analyze **0** · Windows debug/release build PASS |
| 2026-07-15 | **UX-6 Window frame + Theme Gallery** — 32px themed custom chrome · 창모드/최대화/`F11` fullscreen · Escape 복원 · control 우측 정렬/hover overlay 격리 · Sidebar 하단 접기 제거 · 공식 5테마 gallery · premium 3종 planned/no fake price · offer/access 상태 분리 · full tests **1128 PASS** · analyze **0** · Windows debug/release build PASS · Release runtime F11/Esc bounds restore PASS |
| 2026-07-15 | **Commerce catalog foundation** — Astra/Echo·Steam Inventory authority SSOT · Astra pack 500/1,000/2,500 allowlist와 backend 호출 guard · launch theme package 3종 500/500 choose-one · mixed/convert 금지 · nullable account snapshot/gateway · app-root CommerceController/scope로 Store·Inventory와 theme entitlement 연결 · POC generator weight 의미 보정 · domain **17 PASS** · backend **18 PASS** · analyze **0** |
| 2026-07-15 | **Steam production ItemDef local draft** — POC ID 8종 `hidden` retirement · production `40000-41199` 분리 · Astra pack VLV500/1000/2500 · Echo Pack 10 + 10분/6회/1,440분 generator · starter promo/Support 제외 · 테마 3종 500 Astra 또는 500 Echo exchange · schema tests **5 PASS** · full **1145 PASS** · analyze **0** · Steamworks 미게시 |
| 2026-07-15 | **Steam production read gateway** — production ItemDef registry · AppID 검증 · `GetAllItems` 잔액/entitlement mapping · POC ID 무시 · `RequestPrices` 통화/raw current/base amount 보존 · account/price failure 및 cold-offline/in-memory cache 분리 · read-only transaction guard · generic `akasha/steam_inventory` channel · root **1156 PASS** · domain **17 PASS** · backend **18 PASS** · analyze **0** · Windows debug/release PASS · feature flag 계속 OFF |
| 2026-07-15 | **Store/Inventory read UX** — 승인 Astra pack 3종과 테마 package 구분 · provider 통화 가격 가용성 · `disabled/loading/ready/offlineCache/unavailable` 피드백 · live retry · owned entitlement · compact 480×720 및 1024×720/125% text 회귀 · raw 가격 단위 미추정 · 구매 CTA 계속 비활성 · root **1159 PASS** · analyze **0** · Windows debug/release PASS |
| 2026-07-15 | **Steam production sandbox transaction foundation** — 승인 pack/theme allowlist · `StartPurchase`/단일 재화 `ExchangeItems` · 실제 instance ID allocation · terminal result polling · order/transaction correlation · inventory reconciliation · duplicate/insufficient/already-owned/cancel/reject/fail/indeterminate guard · 정상 build OFF/내부 sandbox define only · root **1176 PASS** · domain **17 PASS** · backend **18 PASS** · analyze **0** · Windows default/sandbox release PASS · production ItemDef 게시 및 partner 실거래 checklist 대기 |
| 2026-07-15 | **Steamworks upload candidate + Echo reward foundation** — POC schema 업로드 금지 명시 · production whole-schema 파일/검증 script · POC generator `drop_limit: 0` 퇴역 · `40210` Echo 10 bundle + `40220` 10분/6회/1,440분 generator · 별도 reward gate/scheduler · 공통 terminal poller · Steam 결과와 `GetAllItems +10` reconciliation · root **1184 PASS** · domain **17 PASS** · backend **18 PASS** · analyze **0** · Windows debug/default/sandbox release PASS · Steamworks 게시/E2E 대기 |
| 2026-07-16 | **Steamworks pre-upload hardening** — production port purchase `40110-40112`/exchange `41101-41103`/reward `40220 -> 40002` allowlist · raw `40001`/POC ID native call 차단 · duplicate entitlement guard 재확인 · 즉시 재화 소비/영구 해제 copy · `StartPurchase(40001, 1)` partner probe 추가 · Windows ReadOnly `gen-l10n` wrapper 정규화 · schema **7 PASS** · root **1187 PASS** · analyze **0** · sandbox release PASS · upload JSON hash 불변 |
| 2026-07-16 | **Steam runtime diagnostics + safe depot stage** — historical POC Overlay 성공을 기준으로 production provider 결과 우선 진단 · initialized/logged-on/subscribed/Overlay/승인 가격 capability gate · phase/API handle/`EResult`/order/trans 보존 · sanitized 진단 복사 · provider configuration/access/service UX 분리 · `prepare_steam_depot.ps1`가 `steam_appid.txt`/PDB 제외, required payload 검증, 97-file SHA-256 manifest 생성 · upload content root를 stage로 전환 · root **1195 PASS** · analyze **0** · Windows debug/sandbox release PASS |
| 2026-07-17 | **Steam sale-bundle visibility root cause** — 원격 정의·계정·Inventory/Asset Server·Steam-library BuildID `24240688` 확인 · `40110-40112` 모두 callback `k_EResultFail`/transaction ID `0` 재현 · `40110.store_hidden true -> false` 단일 변수 게시 후 Steam checkout Overlay PASS · 구성품 `40001`은 store-hidden 유지, 판매 팩 `40110-40112`만 store-visible로 계약 수정 · `40111-40112` 원격 게시와 cancel/complete 검증 대기 |
| 2026-07-13 | **Locator index atomic write + `.bak` restart recovery** — `DerivedIndexAtomicWrite` · Record/Entity path indexes · corrupt≠empty · stale `.tmp` never promoted · full tests **1030 PASS** · analyze **0** · concurrent write lock = follow-up only |
| 2026-07-13 | **Entity vault load diagnostics** — `loadFromVaultWithIssues` · `parseDetailed` · empty≠corrupt-only · no auto-log (consumers handle `issues`) · callers unchanged · full tests **1042 PASS** · analyze **0** · tip **`13eb227f`** |
| 2026-07-13 | **Entity path index rebuild issue exposure (조사만)** — `rebuildFromVault`/`upsertMarkdownFile` 무음 skip · `rebuildFromVaultWithIssues` 단독 구현 보류 · 명시적 소비자 대기 · 코드 미변경 |
| 2026-07-13 | **Workbench recovery draft I/O transition diagnostics** — Work/Entity save/delete 전환형 `appLog` · UI/포맷 불변 · stale/race/deactivate flush = follow-up · full tests **1055 PASS** · analyze **0** |
| 2026-07-13 | **Entity derivedIndexesUpdated** — Home skips duplicate `ArchiveIndexManager` mutation · debounce AND-coalesce (`false` survives later `true`) · UI rebuild kept · Work/Journal/Timeline = follow-up · full tests **1070 PASS** · analyze **0** |
| 2026-07-13 | **HomeShell vault-watch dispose lifecycle (ACTION A)** — God Class 전면 리팩터 기각 · `HomeVaultWatchReactor` generation cancel · dispose 순서 reactor→vault→workbench · `syncEntityTabs` `_disposed` guard · full tests **1078 PASS** · analyze **0** |
| 2026-07-13 | **Package modularization audit closed** — 단일 앱 + `akasha_commerce_domain` · graph acyclic · no EXTRACT_NOW · Melos/lib 분할 기각 · Archive PREPARE · Vault/UI/Home KEEP · Steam CMake-optional 재검토 트리거 · docs-only · baseline test **1078** (재실행 없음) |
| 2026-06-29 | **Post-P30 SSOT** — P27~P30 분해·P28 tokens · 400줄+ 재실측 · `origin/main` **9d17f75** · test **610** |
