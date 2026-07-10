# Scale Access-Path Inventory

> **Status:** SA-01 implemented — SA-02 through SA-04 pending
> **Date:** 2026-07-10
> **Scope:** Current Vault read, change-notification, and derived-index paths.
> This is an architecture-cleanup inventory. It introduces no schema, storage
> engine, migration, or Universal Record model.
> **Related:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md#421-current-scale-gap-and-readiness-gate) · [ADR-014](../history/adr/ADR-014-core-archive-ontology.md)

## 1. Decision

Markdown remains a valid user-owned source format. The current scale failure is
not Markdown itself; it is that interactive flows still treat the Vault as a
small collection that can be completely parsed and rewritten on demand.

The next implementation work must first separate:

- bounded interactive reads and writes;
- path-specific incremental maintenance; and
- explicit full rebuild, validation, import, and repair operations.

No UI entry, ordinary save, or ordinary delete may rely on a complete Vault
scan once the scale readiness gate is enforced.

## 2. Call-Site Classification

| Priority | Current path | Current behavior | Why it fails unbounded archiving |
| --- | --- | --- | --- |
| S0 | Home load/reload | `HomeVaultCoordinator.loadItems` calls `HomeVaultLoader.loadItems`, which calls `VaultPort.loadAllItems`; it then always rebuilds the link index. | Every normal home reload parses all Markdown and scans all links before rendering. Many save/import/dialog flows call this reload. |
| S0 | Home change consumption | `VaultPort.onVaultChanges` now preserves typed, Vault-relative path batches, but Home still listens to legacy `onVaultUpdated`. | The changed path reaches the application boundary but is not yet used to replace the full Home reload. |
| S0 | Watch/fingerprint lifecycle | Normal app writes and native watch events now emit path batches without a fingerprint scan. Vault selection and polling fallback still use a full fingerprint. | The remaining scans are explicit bootstrap/fallback behavior; they must not become an ordinary interactive path. |
| S0 | Record port list/get | `VaultArchiveRecordAdapter.listRecords` and `getById` load Work, Journal, and Timeline collections before filtering. | A single stable-ID lookup is O(all records), defeating stable IDs as an access boundary. |
| S0 | Save/delete index fan-out | `ArchiveIndexManager.updateChangedRecord` and `removeRecord` update record, entity-path, title/alias, link, and taste surfaces. Several of those services load and rewrite their complete JSON payload. | A one-record edit has O(all index entries) reads/writes even though source parsing is incremental. |
| S1 | Journal/Timeline/Entity views | Each view loads and deserializes its whole domain folder, then sorts in memory. | Recent-list, pagination, and timeline use cannot grow beyond the currently loaded set. |
| S1 | Discovery helpers | Canvas entity picker, catalog entity browse, fusion search, same-day records, and entity-related-work discovery use whole-domain loaders. | User-facing discovery repeats scans that derived indexes should answer. |
| M | Rebuild/validation | `ArchiveIndexManager.rebuildAll` and `ArchiveIndexValidatorService.validate` recursively scan Markdown. | This is correct only as an explicit maintenance, import, repair, or validation operation with visible progress. |

### 2.1 Home Reload Is the First Blocking Chain

```text
normal save / external file event
  -> VaultPort.onVaultChanges (typed relative path batch)
  -> VaultPort.onVaultUpdated (legacy compatibility notification)
  -> HomeVaultCoordinator.loadItems
  -> VaultPort.loadAllItems (recursive Markdown parse)
  -> RecordLinkIndexService.rebuildIndex (recursive Markdown scan)
  -> home state replacement
```

The application already updates several derived indexes on its own save paths.
The unconditional home link rebuild duplicates that work for app-originated
changes and remains the current external-change fallback because Home has not
yet consumed the detailed event.

### 2.2 “Incremental” Indexing Is Not Yet Bounded

The current index manager passes one changed Markdown path to each index
service, which avoids a source-Vault scan. However, the following payloads are
currently loaded and persisted as whole JSON documents during normal updates:

- `record_index.json` — all summaries plus tag index
- `link_index.json` — all outgoing and incoming links
- `taste_index.json` — all derived taste signals
- entity path map — all entity IDs and paths

The title/alias index is sharded, but removal still examines the existing shard
set. Therefore “incremental” currently means *incremental source parsing*, not
bounded index I/O.

### 2.3 Whole-Domain Loaders Also Hide Parse Failures

Entity, Journal, and Timeline loaders catch parsing errors and omit those files
from their returned collection. P0 preserves the source file, but a scale-ready
read layer must expose it as a preserved unreadable source item rather than
silently treating it as absent.

## 3. Required Boundaries

| Boundary | Required rule |
| --- | --- |
| Interactive query | Read summaries or a bounded page from a derived store; hydrate Markdown only for the selected record/document. |
| App-originated mutation | Update only the changed source path and bounded affected index data; then notify consumers with that path or a typed batch. |
| External change | Preserve the concrete changed paths when the file watcher can provide them. If the watcher overflows, loses detail, or receives a bulk change, explicitly mark a repair/reconciliation state instead of pretending a path-specific update occurred. |
| Rebuild/validation/import | A full scan is allowed, but must be deliberate, cancellable/progress-visible where user-facing, and report unreadable source items. |
| Canonical evidence | Markdown, assets, and durable `system/` data remain authoritative. A derived store is replaceable and never hides a source conflict or parse failure. |

## 4. Recommended Implementation Sequence

### SA-01 — Vault Change Detail Contract

**Implemented.** `VaultPort.onVaultChanges` adds a typed change batch with
normalized relative paths, change kind, and a `reconciliationRequired` state.
The existing `onVaultUpdated` stream remains as a compatibility notification
for current UI consumers.

App-originated Work, Entity, Journal, and Timeline writes emit their changed
path directly. Native watch events preserve Markdown paths and Canvas
`layout.json` artifacts; move events are delete plus upsert. Polling/watch
failure emits explicit reconciliation rather than an invented path batch.
This does not choose SQLite, shards, a new record schema, or a Home query
implementation.

### SA-02 — Home Work Summary Read Path (next)

Move the Home Work list off `loadAllItems`. It should read a bounded Work
summary page, then hydrate a Markdown Work only when a user opens or edits it.
Before implementation, verify whether `VaultRecordSummary` contains every
field needed by the current Home cards; add only a derived projection field if
necessary.

### SA-03 — Bounded Index Persistence

Use measured fixtures and the SA-01/SA-02 query profile to choose a sharded or
local database implementation for Record, Link, and Taste indexes. Do not make
this choice before the actual read/write profile is defined.

### SA-04 — Domain Pages and Record Port

Replace whole-domain Journal/Timeline/Entity page loads and the scanning
`ArchiveRecordPort` fallback with paged summary queries and direct stable-ID
resolution. Canvas remains a composite Document and must not be flattened into
this work.

## 5. Acceptance Criteria for SA-01

- A native file-watch event exposes one or more Vault-relative paths to the
  application boundary without exposing paths outside the Vault.
- An app-originated Work, Entity, Journal, Timeline, or Canvas change can be
  represented without forcing a full Vault reload.
- A bulk/unknown watch state is explicit and triggers reconciliation rather
  than an unlabelled fallback scan.
- Existing `Stream<void>` consumers remain compatible during the transition.
- P0 recoverable writes, conflict preservation, and unknown YAML preservation
  remain unchanged.

## 6. Explicit Non-Decisions

- Do not replace Markdown or migrate existing Vault paths.
- Do not create Universal Record, Relationship Assertion storage, or a global
  sharing layer.
- Do not treat Canvas layout edges as relation assertions.
- Do not make the derived index a canonical copy of user records.
- Do not optimize by silently dropping malformed, unknown, or unsupported
  source files from the user-visible archive.
