# SA-02 — Home Work Summary Boundary

> **Status:** Work-only Explore uses the bounded summary path; dashboard,
> graph, Canvas, personal-library, Entity, Journal, Timeline, and relation
> surfaces remain separate migrations.
> **Date:** 2026-07-10
> **Related:** [SCALE_ACCESS_PATH_INVENTORY.md](SCALE_ACCESS_PATH_INVENTORY.md#sa-02--home-work-summary-read-path) · [INFINITE_ARCHIVE_HARDENING_PLAN.md](../../active/INFINITE_ARCHIVE_HARDENING_PLAN.md)

## 1. Decision

The concrete Home visual and relationship audit is recorded in
[SA_02B_WORK_VISUAL_RELATION_AUDIT.md](SA_02B_WORK_VISUAL_RELATION_AUDIT.md).
It confirms that the summary projection already preserves card images and core
metadata, while review/body/provenance and connection sections remain selected
source or separate-relation reads.

SA-02 does **not** replace every Home use of `AkashaItem` with a partial
object. It introduces a separate, read-only Work summary projection for bounded
list queries. A summary is never passed to an editor, never serialized as a
Work, and never used as a fallback value for a save.

Markdown remains canonical. Any summary/index storage is disposable derived
data and must be rebuildable from the Vault without changing user files.

This distinction is mandatory: constructing an incomplete `AkashaItem` from a
summary would make absent `review`, body, quotes, provenance, or state fields
look like intentional empty values and could overwrite original archive data.

## 2. Current Evidence

| Area | Current reality | SA-02 implication |
| --- | --- | --- |
| Home load | `HomeVaultCoordinator.loadItems` calls `VaultPort.loadAllItems`, then rebuilds links. | It is not a valid interactive path for an unbounded Vault. |
| Home state | Many Dashboard, Canvas, graph, record, and picker paths receive a shared `List<AkashaItem>`. | A global type swap would flatten unrelated domain behavior and is out of scope. |
| Work Explore | The linked-Vault Work-only Explore scope uses `WorkSummaryBrowseView`, cursor-paged SQLite summaries, and selected-source hydration. | This is the first bounded consumer, not permission to feed summaries into other Home surfaces. |
| Existing summary | `VaultRecordSummary` includes ID, relative path, title, category, creator, year, rating, display statuses, tags, timestamps, and poster. | It is close to a Work browse-card projection. |
| Missing detail | The summary does not hold Work body, review, quotes, description, full v3 metadata, or editor session revision. | Open, preview-detail, edit, graph, and evidence-bearing operations must hydrate the selected source Work. |
| Existing index I/O | `.akasha/record_index.json` loads and rewrites one whole payload. | It cannot be treated as the final bounded query implementation. SA-03 owns its replacement choice. |

## 3. Work Summary Query Contract

The eventual port/storage API must provide this semantic contract, independent
of its JSON-shard or local-database implementation.

| Contract element | Required rule |
| --- | --- |
| Identity | `workId` is the durable Work identity. Relative path is a locator, not identity. |
| Page | A request takes an opaque cursor and caller-selected limit; a result returns at most that limit and an optional next cursor. It does not require a global count. |
| Ordering | Cursor ordering is deterministic and includes a stable ID tie-breaker. Timestamp ordering uses an explicit normalized instant, never host-local time. |
| Filters | Category, Work status, My status, and tag filters are evaluated by the derived query layer; they do not trigger Markdown hydration for every candidate. |
| Projection | A browse row contains only fields the list can render safely: durable ID, source locator, title, category, creator, release year, rating, display statuses, tags, poster reference, added/updated instants. |
| Hydration | Selecting a row resolves its current Markdown source by durable ID/revision and returns either a complete Work or an explicit readable error/conflict state. |
| Unreadable source | A malformed or inaccessible source is not silently absent. The query layer exposes a preserved-unreadable state with source path and recovery context. |
| Canonicality | A summary is never authoritative evidence and cannot be used to save a Work. |

`review`, body, quotes, original title/aliases, provenance, evidence, links,
and edit-session revision deliberately remain outside the list projection until a
selected Work is hydrated.

The current hydration foundation is `VaultPort.loadItemByRelativePath`: it
accepts only a Vault-relative Markdown path, rejects traversal and excluded
paths, reads exactly that canonical file, and returns its current opened
revision. It does not scan siblings or construct a partial `AkashaItem`; SA-02B
must resolve the summary locator first, then use this port for the selected
Work only.

`LocalDerivedIndexLifecycle` exposes the same separation as a read API:
`queryWorkSummaries` returns only bounded summaries from a ready cache, while
`hydrateSelectedWork(workId)` resolves the cached locator and returns either a
complete canonical item or an explicit cache-unavailable, missing-source, or
identity-mismatch state. `WorkSummaryBrowseView` consumes this only for the
linked-Vault Work Explore scope; no dashboard, graph, Canvas, personal-library,
or editor path receives a partial summary.

## 4. Change and Reconciliation Contract

SA-01 already provides `VaultChangeBatch`. SA-02 consumers must apply it with
the following rules.

| Change state | Required behavior |
| --- | --- |
| Precise upsert | Re-read/reindex only the reported source path, then update or evict the affected Work summary according to the active page cursor and filters. |
| Precise delete | Remove only the matching locator/Work summary and fill the page from its cursor when possible. |
| Move | Treat delete plus upsert as one identity-preserving relocation when their stable Work ID matches. |
| `reconciliationRequired` | Surface an explicit refresh/repair state. Do not fabricate a complete page and do not call `loadAllItems` as a silent fallback. |
| Open editor conflict | Preserve P0 expected-revision behavior. A summary refresh never grants permission to overwrite an externally changed source. |

Link, taste, and other derived indexes have their own incremental maintenance
paths. SA-02 removes the ordinary Home-triggered full link rebuild only when a
path-specific maintenance route exists for both app-originated and external
changes.

## 5. Migration Boundary

The migration is deliberately incremental.

1. Define and test the summary page contract against representative fixtures.
2. Migrate the Work browse-list entry path to summaries and hydrate on open.
3. Give Dashboard, Canvas, graph, records, pickers, and personal-library
   features their own bounded query/hydration paths; do not make them depend on
   a hidden global full-Work cache.
4. Remove `HomeVaultCoordinator.loadItems` from normal startup/change handling
   only after every current consumer has an explicit replacement.

Until step 4, the legacy full-load path remains a known compatibility path,
not evidence that SA-02 is complete.

## 6. Fixture and Measurement Profile

Before choosing storage in SA-03, exercise the same query contract with these
derived-data fixture profiles:

| Profile | Records | Required operations |
| --- | ---: | --- |
| baseline | 100 | first page, filtered page, selected Work hydration, save/delete change |
| release-scale | 10,000 | repeated page navigation, status/tag filtering, external one-path edit |
| archive-scale | 1,000,000 | cold/open page, cursor continuation, one-path upsert/delete, reconciliation signal |

For each operation, record source Markdown files read, derived bytes read and
written, result size, and elapsed time. A normal page or one-record change may
not scale with total Markdown file count. Whether the current JSON index is
sharded or replaced by a local database remains an SA-03 decision based on
these measurements.

## 7. SA-02 Completion Gate

- The migrated browse entry path reads a bounded summary page without a
  recursive Vault scan or `loadAllItems`.
- Opening/editing hydrates exactly the selected canonical Work and retains P0
  conflict protection.
- A precise Vault change updates only affected derived data; reconciliation is
  visible and non-destructive.
- No partial summary can be serialized as a Work or erase unknown YAML/v3
  fields.
- Dashboard/graph/Canvas paths not yet migrated remain explicitly listed; they
  are not silently fed incomplete Works.
