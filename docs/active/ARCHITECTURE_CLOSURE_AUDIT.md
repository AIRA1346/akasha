# Architecture Closure Audit

> **Status:** Audit complete (2026-07-12) — architecture/cleanup phase gate  
> **Authority:** [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md) · P0 · SA-02/03/04  
> **Scope:** Verify current implementation against Constitution. No new features, Universal Record, §7 ADR, behavioral traces, or Relationship Assertion work.  
> **Related:** [ULTIMATE_ARCHIVE_BACKLOG.md](ULTIMATE_ARCHIVE_BACKLOG.md) · [SA_02_HOME_WORK_SUMMARY_BOUNDARY.md](SA_02_HOME_WORK_SUMMARY_BOUNDARY.md) · [P0_RECOVERABLE_VAULT_WRITE_GATE.md](P0_RECOVERABLE_VAULT_WRITE_GATE.md)

## Verdict

| Closure question | Result |
|---|---|
| Known major Constitution contradictions? | **None on durable ownership / P0 write / system vs `.akasha` write boundary** |
| Unclassified P0/SA bypass paths? | **None for P0 writers.** SA-02/03 interactive full-load residuals addressed by **Bounded Home Read Closure** (2026-07-12) |
| Active docs vs code? | **Mostly aligned**; S1 stale comments remain |
| Structural vs Steam vs backlog separated? | **Yes** — §Findings below |
| S0 structural (C-01–C-05)? | **Closed** — Graph off; precise watch; shared link index; single-path hydrate |
| Single next priority? | **S1 Steam ship items → Architecture Closure declaration → Steam M3 dogfood** |

**Data-preservation critical defects requiring an in-audit fix slice:** **None found** (P0 writers). **S0 scale/interactive defects:** fixed in Bounded Home Read Closure.

---

## Method

Code review of `lib/` (services, home shell, adapters, writers) against Constitution §3–5 and P0/SA contracts. Agents cross-checked vault/derived boundaries, write gates, and scale hot paths. No new abstractions introduced.

**Verification (this machine, 2026-07-12):** see §Verification at end.

---

## Pass areas (must not be reopened casually)

1. **Durable writers** — Work / Entity / Journal / Timeline / Canvas / `system/*` go through `VaultLosslessRecordWriter` or `VaultRecoveryWriteService` (`file_service_save.dart`, `*_vault_store.dart`, `canvas_store.dart`, candidate/ops/draft stores).
2. **Unknown YAML** — `LosslessFrontmatterPatcher` keeps non-owned keys on valid frontmatter saves.
3. **Conflict** — revision mismatch → proposed preserved under recovery; UI surfaces conflict (no silent overwrite).
4. **`.akasha/` new writes** — derived indexes + vault spec only; durable ops live under `system/` (candidates, ops, drafts, libraries, collections, ledger).
5. **Work Explore SA-02 slice** — `WorkSummaryBrowseView` + `LocalDerivedIndexLifecycle` (paged summaries, selected-source hydration, repair-required without silent `loadAllItems`).
6. **Domain semantics** — separate stores/loaders for Work, Entity, Journal, Timeline, Canvas; no Universal Record merge in code.

---

## Findings

Severity:

- **S0 — Fix now (structural):** Constitution/scale contract violated on interactive paths, or Steam v1 scope contradiction that forces unsafe full-vault work.
- **S1 — Before Steam ship:** Product stability / dogfood / upgrade friction; not silent user-data loss.
- **S2 — Long backlog:** Explicit maintenance tools, dual caches, legacy migration leftovers, post-v1 surfaces.

### S0 — Structural — **CLOSED 2026-07-12 (Bounded Home Read Closure)**

| ID | Finding | Resolution |
|---|---|---|
| C-01 | Legacy Home full-vault MD load on watch | Watch uses `onVaultChanges` + precise `applyVaultChange`; no `loadAllItems` |
| C-02 | Link index full rebuild every `loadItems` | `loadItems` no longer rebuilds links; full rebuild = `rebuildLinkIndexForRepair` only |
| C-03 | Adapter/detail-save `loadAllItems` | Path/id hydrate in `VaultArchiveRecordAdapter.getById` + `DetailArchiveSave` |
| C-04 | Knowledge Graph ON vs v1.1 | `FeatureFlags.showKnowledgeGraph = false` |
| C-05 | Dual `RecordLinkIndexService` | `RecordLinkIndexService.shared` used by Home + `ArchiveIndexManager` |

Regression: `test/bounded_home_read_closure_test.dart`.

### S1 — Before Steam ship

| ID | Finding | Evidence | Impact | Minimal fix | Verify |
|---|---|---|---|---|---|
| S-01 | Search path still uses in-memory `localItems` + entity vault full scan | `fusion_search_service.dart`; dialogs pass `getItems()` | Search degrades with vault size | Prefer title/alias / record indexes for exact lookup; defer fuzzy | Search with vault ≥1k works |
| S-02 | `EntityVaultLoader.findByEntityId` falls back to full `entities/` scan | `entity_vault_loader.dart` | Slow open / wrong “missing” under stale index | Fail closed to repair/index miss UI; no silent full scan | Miss path shows repair, not multi-second scan |
| S-03 | Vault watch fingerprint polling scans all `.md` stats | `file_service_watch.dart` | CPU/IO on fallback watch | Bound fingerprint or sample; document when polling engages | Force watch failure → polling cost measured |
| S-04 | `setVaultPath` silent `ensureIndex` ×4 may full rebuild | `file_service_bootstrap.dart` | First-open hitch on large vaults | Progress UI or defer rebuild until Explore | Connect large vault; UI remains responsive |
| S-05 | Auto-archive path calls `loadAllItems` | `home_auto_archive.dart` | Slow archive when flag/path used | Presence via path index / work id | Auto-archive one work without full load |
| S-06 | Stale docs/comments (`.akasha/candidates`, personal library under `.akasha`) | `candidate_review_view.dart` comment; `home_personal_library_controller.dart` | Misleading for maintainers / dogfood | Comment-only fix | Grep for `.akasha/candidates` in active comments = 0 |
| S-07 | `catalogContributions=true` needs dogfood E2E | `feature_flags.dart` | Shipping unproven contribution loop | User dogfood checklist | STEAM_RELEASE / dogfood scenarios |
| S-08 | Timeline UI flagged off but capture/load code remains | `showTimeline=false`; loaders still present | Dead path confusion; accidental enable cost | Keep OFF; do not expand loaders until SA-05 | Confirm no Timeline entry in UI |

### S2 — Long backlog

| ID | Finding | Evidence | Notes |
|---|---|---|---|
| L-01 | Dual Work summary: `.akasha/record_index.json` vs app SQLite | `record_summary_index_service` + `local_derived_index_*` | Keep until SA domains migrate; do not merge into Universal table |
| L-02 | Journal/Timeline/Canvas list loaders are directory-wide | `*_vault_loader.dart`, `canvas_store.dart` | SA-05+ per-domain projections |
| L-03 | Legacy `.akasha/` copies left after migrate-to-`system/` | candidate/ops/draft/library migrators | Intentional non-delete; cleanup tool later |
| L-04 | Registry R1–R5 / works layout L1–L4 TODOs | LEGACY markers in registry/file bootstrap | Post-v1 removal policy |
| L-05 | `phenomenon` deprecated entity type still in UI/enum | entity models / dialogs | Removal track |
| L-06 | Entitlement Steamworks stub | `entitlement_service.dart` | Payment phase (user step 6) |
| L-07 | §7 history/aggregates | Constitution §7; UA-122 deferred | ADR only when implementing |
| L-08 | Nested YAML under owned keys may be replaced as a block | lossless patcher segment model | Edge case backlog |

---

## Constitution checklist (audit answers)

| Condition | Answer |
|---|---|
| Vault source vs derived consistent on all paths? | **Writes: yes.** Interactive Home reads: **legacy full MD still present (C-01–C-03)** |
| Save/query/index bypass P0/SA? | **P0: no.** SA-02/03: **Work Explore OK; other Home surfaces classified residual** |
| Unnecessary app/AI/DB/format lock-in? | **No hard lock-in**; Flutter app is first UI; MD remains durable; SQLite is app-local derived |
| Format/schema/query replaceable? | **Yes in principle**; blocked practically by legacy `loadAllItems` consumers |
| Work/Entity/Journal/Timeline/Canvas meanings preserved? | **Yes** — separate stores; Canvas edges presentation-default |
| Scale deficits remaining? | **C-01–C-05, S-01–S-05** |
| Dup services / dead / fallback? | Dual link index (C-05); entity/index miss fallbacks (S-02); FeatureFlag Graph mismatch (C-04) |
| Active docs match code? | Constitution/VISION/CURRENT_STATE OK; SA-02 already documents residual; stale comments (S-06) |
| Steam v1 vs research boundary? | Mostly via FeatureFlags; **Graph ON contradicts v1.1 comment (C-04)** |
| Unusable user flows despite green tests? | Large-vault Home/search/watch; Graph entry forces full load |

---

## Recommended fix order (no new abstractions)

1. ~~**C-04** Graph flag~~ **done**
2. ~~**C-02 + C-05** link index~~ **done**
3. ~~**C-01 / C-03** watch / hydrate~~ **done**
4. **S-01 / S-02 / S-05** — Search and entity open without full scans; auto-archive `loadAllItems`
5. **S-06 / S-07** — Comment hygiene + contribution dogfood
6. **Declare Architecture Closure** (after S1 Steam-blocking items)
7. **Steam M3 dogfood** (product)
8. **SA-05** as separate architecture slice
9. **S2 / UA-122** only when implementing those features

---

## Explicit non-goals (this audit)

- §7 implementation ADR  
- Behavioral raw logs / Universal Record / Relationship Assertion storage  
- New query frameworks or merging domain loaders  

---

## Verification

| Gate | Result |
|---|---|
| `flutter analyze --no-pub` | **No issues found** (post Bounded Home Read Closure) |
| `flutter test --no-pub` | **930 passed** (post Bounded Home Read Closure) |
| Interactive watch `loadAllItems` | **Absent** — precise `applyVaultChange` only |
| Interactive full link rebuild | **Absent** — `rebuildLinkIndexForRepair` / validator only |
| S0 code | Landed in Bounded Home Read Closure |
