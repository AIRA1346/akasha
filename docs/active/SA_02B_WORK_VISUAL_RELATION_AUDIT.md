# SA-02B - Work Visual and Relationship Surface Audit

> **Status:** Boundary audited; no Home UI migration yet
> **Date:** 2026-07-11
> **Related:** [SA-02 Work Summary Boundary](SA_02_HOME_WORK_SUMMARY_BOUNDARY.md), [SA-03 Derived Index Decision](SA_03_DERIVED_INDEX_PERSISTENCE_DECISION.md), [Scale Access-Path Inventory](SCALE_ACCESS_PATH_INVENTORY.md)

## 1. Decision

AKASHA's scalable Work path must retain visual information and meaningful
connections. It must not reduce the archive to a title list in exchange for
performance.

The safe boundary is three distinct reads:

1. **Browse projection:** a bounded list of visual Work summaries.
2. **Selected source hydration:** one canonical Markdown Work, read only after
   the user selects it.
3. **Relationship query:** bounded incoming, outgoing, and discovery results
   for a selected identity.

These are intentionally separate. A list projection cannot stand in for a
complete Work, and a wiki-link lookup cannot silently become a durable semantic
Relationship Assertion.

## 2. Current Home Surfaces

| Surface | What the user can see or do today | Current dependency | Safe future source |
| --- | --- | --- | --- |
| Explore Work grid | category, title, creator, personal status, rating, franchise-format slots, library actions, and open actions | complete `List<AkashaItem>` through `BrowsePipeline` and `FranchiseFusionService` | bounded summary page plus targeted franchise and library-membership lookup |
| Personal library grid | poster image, title, creator, status, rating, format slots, library count, drag/menu actions | complete Work list plus membership configuration | bounded membership-ID query and Work summaries; do not infer membership from a partial Work |
| Preview rail | poster, alternate title, year/category/status, creator, registry metadata, rating, personal reflection/body/wiki links, suggested and discovered connections | selected `AkashaItem`, registry, catalog, link index, and the current full Work list | hydrate exactly one canonical Work, then request bounded relationship/discovery sections |
| Workbench detail | editable poster, title, tags, status, rating, reflection/body, quotes, provenance metadata, incoming links, same-day records, and graph navigation | complete `AkashaItem` plus full-list-dependent link helpers | canonical selected source and dedicated bounded detail/relation queries |
| Home dashboard | recent and discovery sections, preview hand-off, and related Work suggestions | shared complete Work list | each section needs its own bounded contract; not part of the first Work-grid migration |
| Knowledge graph / Canvas / entity discovery | graph nodes, incoming/outgoing navigation, Canvas presentation, entity-related Work discovery | complete Work list, entity scans, and the legacy link index | dedicated graph/relation and domain projections; not part of the first Work-grid migration |

The present Explore grid uses a fact-card layout, while the personal library
and preview rail use the stored poster image. Both are user-visible archive
information and must remain available after the migration.

## 3. What the Existing Summary Already Preserves

`VaultRecordSummary` and the derived `work_summaries` projection already carry:

- durable Work ID and current Vault-relative source locator;
- title, category, creator, release year, rating, Work/My status, and tags;
- added/updated timestamps; and
- poster reference.

That is sufficient to render the visual identity of a Work card, including an
image card, without parsing its body. It is deliberately insufficient for the
following fields:

| Must remain on the hydrated canonical Work | Why it must not be represented as an empty summary value |
| --- | --- |
| reflection/review, body, description, quotes | absence in a card projection is not evidence that the user wrote nothing |
| aliases, original title, external IDs, source/provenance, evidence, structured links | these are durable archive meaning, not list decoration |
| unknown YAML fields and source revision | they are required for P0 lossless preservation and conflict-safe editing |
| complete relation context | it can be large, change independently, and needs its own query semantics |

No implementation may construct a writable `AkashaItem` from a summary. A
selection must use `LocalDerivedIndexLifecycle.hydrateSelectedWork(workId)`,
verify the cached locator against the canonical source ID, and surface an
explicit unavailable/missing/mismatch state instead of opening a partial item.

## 4. Relationship Semantics and Current Limits

The current `RecordLinkIndexService` indexes Markdown `[[wiki links]]` into
outgoing source-path and incoming target-ID lookups. It supports navigation and
backlinks, but a wiki link only says that an author connected two pieces of
text. It does **not** by itself assert a durable fact such as `created_by`,
`influenced`, or `occurred_at`.

`ArchiveRecordMetadata.links` additionally stores a controlled relation token,
target, and label. This is useful structured-link metadata, but the current
read path still combines it with wiki links, catalog resolution, and whole-list
or entity-journal scans to create neighbour panels. It does not yet provide an
independent Relationship Assertion with provenance, evidence, author/agent,
time, lifecycle, or conflict semantics.

Consequences:

- relationship results must not be copied into the Work summary table merely
  to make cards look connected;
- a selected Work may request bounded relationship sections after hydration;
- graph/Canvas edges remain presentation or navigation data unless an explicit
  assertion is later created under the ontology ADR; and
- a future relation index must support bounded lookup by source and target,
  not rebuild or load every Work to answer one selected-Work request.

## 5. Scale Blockers Found

The derived Work-summary cache is now capable of bounded pages and selected
source hydration, but Home does not consume it. The normal startup and change
path remains:

```text
Home init or Vault update
  -> HomeVaultCoordinator.loadItems
  -> VaultPort.loadAllItems (recursive Markdown parse)
  -> RecordLinkIndexService.rebuildIndex (recursive Markdown scan)
  -> shared List<AkashaItem> for Home, dashboard, graph, and pickers
```

This has four implications.

1. Replacing only the visible Work grid would not make the application
   scale-safe while startup still performs the full parse.
2. The legacy `onVaultUpdated` subscriber discards SA-01's precise path batch
   and invokes that complete reload again.
3. Franchise format slots currently derive their tracked IDs from all Works;
   visual parity therefore requires a small targeted membership query, not a
   hidden full list.
4. Entity-related Work discovery currently scans incoming targets, Works, and
   entity journals. It is a separate relation-scale problem, not a reason to
   place relations in the Work card projection.

The legacy `.akasha/link_index.json` is rebuildable derived data, not archive
evidence. Its whole-file scan/rewrite makes it unsuitable as the long-term
relationship-query engine; this audit does not change its compatibility role.

## 6. Required Migration Shape

The first production migration may cover only the explicit Work-browse entry
path. It must not silently change Dashboard, graph, Canvas, detail editors, or
personal libraries to partial objects.

| Step | Required result |
| --- | --- |
| 1. Startup boundary | Normal scalable startup must bind the derived index without unconditionally calling `loadAllItems`. A repair/bootstrap scan is explicit preparation work, not a hidden fallback. |
| 2. Visual browse adapter | Render title, poster, creator, status, rating, category, and tags directly from a bounded Work summary. The adapter is read-only and cannot enter an editor/save path. |
| 3. Targeted card enrichments | Replace all-Work franchise-format and library-membership checks with bounded ID/membership queries before preserving those badges/actions. Do not omit them or compute them from a global list without an explicit compatibility mode. |
| 4. Open action | Single click, double click, drag-to-detail, and context actions resolve stable Work ID to one canonical hydrated Work before preview or editing. |
| 5. Relationship hand-off | Preview/detail requests its bounded connection sections after the canonical Work is available. It never treats an unloaded relation list as "no connections". |
| 6. Other surfaces | Dashboard, graph, Canvas, entity discovery, record pages, and personal libraries each receive an explicit query design before the global full-item state is removed. |

The derived index now provides the first targeted enrichment primitive:
`findWorkSummariesByIds` accepts at most 250 distinct IDs, preserves requested
order, omits unknown IDs, and reads only those derived rows and their tags. It
is suitable for a small franchise group or curated-library membership set; it
does not yet migrate a Home surface or authorize a full-list fallback.

The first Home consumer is now the Work-only Explore scope. It renders a
cursor-paged visual summary card with poster, title, creator, status, rating,
and tags; selecting it hydrates the one canonical source before opening preview
or detail. This is intentionally not yet a SA-02B gate pass: the existing Home
startup path still loads all items, and franchise/library card affordances still
need their targeted queries.

During initial preparation or repair, the user-facing state should describe the
archive being prepared or repaired. It must not expose cache vocabulary or ask
the user to manually reload an implementation detail.

`LocalDerivedIndexLifecycle.ensureWorkSummariesReady` is the app-owned entry
point for that preparation: concurrent callers share one rebuild, a ready
projection is a no-op, and a currently rebuilding projection is not scanned a
second time. Home status presentation and the removal of its legacy full load
remain the next migration step.

## 7. SA-02B Gate

The Work-grid path is ready only when all of the following are true:

- its normal page/filter/cursor reads do not call `loadAllItems` or recursively
  scan Markdown;
- poster and the listed Work metadata have visual parity with the current card
  surface;
- opening a Work reads and verifies only the selected canonical source before
  showing review, body, provenance, or editing controls;
- card affordances that depend on other Works use targeted bounded lookups;
- relationship sections are explicitly loading, available, unavailable, or
  empty -- never inferred from a partial summary;
- a precise Vault change touches only affected derived records, while an
  uncertain external change enters a visible repair/preparation state; and
- legacy full-list consumers remain named and isolated until they have their
  own migration, rather than being fed lossy values.

## 8. Recommended Next Work

1. Make the Home startup/change boundary capable of entering a bounded
   Work-browse mode without first hydrating every Markdown file.
2. Add the read-only visual Work-card projection and its selected-source open
   hand-off.
3. Add the two targeted enrichments required for card parity: franchise member
   presence and personal-library membership.
4. Design the bounded relation query contract before migrating preview
   connection panels, graph, Canvas, or entity discovery.
5. Measure the complete source scan and selected-source hydration on the
   packaged Windows Steam target before declaring this a shipped million-record
   path.
