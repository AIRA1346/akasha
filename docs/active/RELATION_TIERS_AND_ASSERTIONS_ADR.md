# Relation Tiers and Relationship Assertion ADR

> **Status:** Accepted semantic ADR — no relation model, serializer, storage
> layout, migration, graph service, or UI is introduced by this document.  
> **Date:** 2026-07-12  
> **Scope:** The boundary between mentions, references, record-scoped links,
> Canvas edges, and independently preserved relationship claims.  
> **Related:** [P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md](P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md), [PROVENANCE_AND_DERIVED_INPUT_ADR.md](PROVENANCE_AND_DERIVED_INPUT_ADR.md), [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](AI_ARCHIVE_WRITE_GATEWAY_ADR.md), [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md)
> **Cases:** [RELATION_TIERS_AND_ASSERTIONS_CASES.md](RELATION_TIERS_AND_ASSERTIONS_CASES.md)

## 1. Decision

AKASHA preserves many kinds of connection. They have different archival
strength and must not be flattened into one graph edge type.

| Tier | Meaning | Current form | Independent semantic claim? |
| --- | --- | --- | --- |
| 0 — Mention | Text happens to name or allude to something. | Plain Markdown text | No |
| 1 — Reference | An author intentionally connects a Record to an ID or title for navigation. | `[[wiki link]]` | No |
| 2 — Structured link | A Record gives a directed, vocabulary-controlled link to a target in that Record's context. | v3 `links[]` | No |
| 3 — Relationship Assertion | A separately identified claim that one stable endpoint bears a predicate to another, with provenance and lifecycle. | Not implemented | Yes |

A **Relationship Assertion** is not a universal truth and does not outrank a
user's source Record. It is a durable, independently addressable claim such
as "this Work was created by this Person" or "this Record asserts that A
influenced B." It may be supported, disputed, qualified, withdrawn, or
superseded without editing the input Record or deleting a competing claim.

The same relation token may appear in a Tier 2 structured link and a Tier 3
assertion. The token does not make their commitment equal:

```text
Record `links[].relation: created_by`
    = this Record's structured context / navigation hint

Relationship Assertion `created_by`
    = a separately preserved claim with endpoints, claimant, evidence, time,
      and eventual lifecycle
```

No existing wiki link, structured link, Canvas edge, or derived index is
automatically promoted to a Relationship Assertion.

## 2. Current boundary audit

| Existing capability | What it currently preserves | What it does not preserve |
| --- | --- | --- |
| Markdown wiki link | A Record body connects to an explicit ID or title. `RecordLinkIndexService` provides navigation/backlinks. | Predicate, claimant, evidence, time, lifecycle, or a stable link identity. Its current source key is a file path, not a durable relation ID. |
| v3 `links[]` | Record-scoped `target_id`/`target_title`, `relation`, and label with a controlled vocabulary. | Who asserted a global claim, source revision/evidence, validity period, conflict, withdrawal, or separate lifecycle. |
| `RelationVocabulary` | Directional tokens and `u:` user extension vocabulary. | Inverse semantics, assertion truth, temporal validity, or independent relation storage. |
| Canvas edge | A visual/navigation connection between Canvas node IDs; optionally a display relation or `link_ref`. | Stable semantic endpoints, provenance, evidence, or relation lifecycle. |
| Candidate store | A non-canonical proposal and its current candidate lifecycle. | A canonical relationship claim. |
| P0/revision/provenance contracts | Recoverable writes and durable source/input evidence. | A relation's subject, object, predicate, or assertion lifecycle. |

The current `RecordLinkIndexService` indexes Markdown body links, not a global
assertion graph. Its file-path source key is suitable for the existing
navigation index, but cannot be reused as an assertion identity because files
may move while a relationship claim must remain addressable.

## 3. When a link must be promoted

A link remains at Tier 0–2 unless someone intentionally needs at least one of
the following:

- the claim to remain independently queryable after the source Record is moved,
  split, or no longer the only useful context;
- a named claimant, actor, source Record, or operation provenance;
- evidence with exact input revision(s) or an explicit statement of uncertainty;
- a validity period, assertion time, withdrawal, supersession, or conflict;
- multiple competing claims about the same endpoints and predicate to coexist;
- a relation to be shared, compared, or reused independently of one Document.

This is a **user or authorized-tool decision**, never an indexer heuristic. A
future UI may offer "preserve as assertion," but merely rendering a card,
following a link, placing a Canvas edge, or detecting repeated links must not
create a Tier 3 object.

## 4. Relationship Assertion invariants

The future physical form is deferred, but every canonical Relationship
Assertion must satisfy these semantic invariants.

1. **Stable assertion identity.** It has an ID independent of file path,
   Canvas edge ID, source Record ID, and derived-index entry.
2. **Stable endpoints.** Subject and object are typed, stable references to a
   Vault Entity, Record, or Artifact. A title-only reference is not enough.
   An uncaptured external endpoint must be represented as a truthful external
   identifier/citation, never guessed from display text.
3. **Directed predicate.** Subject → predicate → object is explicit. The
   predicate uses the core or `u:` vocabulary until a later assertion vocabulary
   decision extends it. Readers may show a convenient inverse, but must not
   silently persist a second inverse assertion.
4. **Claimant and provenance.** It identifies the Record, human, external
   tool, or AI that made the claim when known. It follows the provenance ADR:
   an actor is locally scoped, `source` is only creation channel, and unknown
   provenance remains unknown.
5. **Evidence and revision.** It preserves supporting Record/Artifact
   references and exact revisions when the evidence is in the Vault. A bare
   wiki link, relation label, or Canvas edge is not evidence.
6. **Two kinds of time.** `asserted_at` means when the claim entered the
   archive; optional validity time means when the claimed relation held. Neither
   can be inferred from a Document's `created_at` or `occurred_at`.
7. **Independent coexistence.** Different assertions may agree, disagree, or
   qualify one another. No save path may overwrite a competing assertion merely
   because subject, predicate, and object are the same.
8. **Non-destructive lifecycle readiness.** Retraction, correction, merge,
   or supersession must preserve the old claim and its evidence. Exact states
   and physical fields belong to the lifecycle ADR.
9. **No hidden global scan.** Future lookups must be bounded by stable subject,
   object, predicate, and lifecycle filters. Rebuildable reverse indexes may
   accelerate them but cannot become the only canonical copy.

For an intentionally broad predicate such as `related`, Tier 3 additionally
needs a human-readable scope or rationale. Otherwise it is normally better as
a Tier 1 or Tier 2 connection than as an independent claim.

## 5. Canvas is a projection, not relation authority

Canvas is a composite Document (`canvas.md` + `layout.json`). Its nodes are
presentation handles and its edges connect node IDs, not necessarily stable
semantic endpoints.

| Canvas form | Meaning under this ADR |
| --- | --- |
| `canvas_only` edge | Tier 0–2 visual/navigational connection only. Moving, hiding, editing, or deleting it changes no assertion. |
| `canonical_view` edge with `link_ref` | A persisted view of an existing Record-scoped structured link; the implementation name does not make it a global fact. |
| `candidate` edge | A visual proposal. It remains non-canonical unless separately promoted. |
| Future assertion reference | A view may point to an existing Tier 3 assertion, but cannot be its only copy or lifecycle owner. |

Promotion from Canvas must resolve both endpoint nodes to stable references,
collect the claimant/evidence/time required by §4, and create a separate
assertion through the future Gateway. Deleting the Canvas edge afterward does
not retract the assertion; retracting an assertion does not silently destroy a
user's layout.

## 6. Scalable representation direction

The architectural decision is **logical separation now, physical storage later**.
A Relationship Assertion cannot remain only in a parent Record's `links[]`, but
AKASHA must not prematurely choose one Markdown file per edge, one giant JSON
ledger, or a database-only graph merely because it is convenient today.

| Alternative | Decision | Why |
| --- | --- | --- |
| Only embed all relations in `links[]` | Rejected | Cannot carry independent provenance, evidence, time, conflicts, or lifecycle. |
| One Markdown file per assertion immediately | Deferred | Human-readable, but its million-file behavior, compaction, and recovery costs need a scale decision. |
| One `system/` JSON/SQLite relation ledger as sole truth | Rejected | It weakens portable, inspectable archival meaning and would make a database the only copy. |
| Logical canonical assertion + rebuildable bounded indexes | Recommended | Preserves semantics first while allowing a later physical representation proven to scale. |

The future storage decision must satisfy all of these:

- canonical assertion content remains user-owned and exportable with its
  provenance/evidence;
- physical paths and index shards are not semantic identity;
- lookups by subject, object, predicate, and assertion status do not require a
  whole-Vault scan;
- a million assertions do not force a million visible UI items or a global
  graph load;
- P0 recoverable writes and unknown-field preservation cover the canonical
  representation;
- importing or exporting an assertion does not silently promote a loose link.

## 7. Additive migration rules

Existing v3 Vaults need no migration for this ADR:

- all existing plain text, wiki links, `links[]`, Canvas edges, and user `u:`
  relation tokens remain valid at their current tier;
- no existing relation is backfilled, deduplicated, inverted, or promoted by
  inference;
- a future assertion may cite an existing Record/link as evidence while leaving
  it unchanged;
- unknown YAML relation extensions survive saves through P0; a reserved-field
  collision is quarantined rather than normalized away;
- an assertion's own future schema must be additive and must not repurpose
  `links[]` or Canvas `layout.json` as its canonical storage.

## 8. Gateway implications

An external AI/tool may propose a relationship assertion as a candidate, with
claimed endpoints, predicate, evidence, and input revisions. It cannot turn a
link or Canvas edge into a canonical assertion merely by calling it meaningful.

Direct application requires a later scoped Gateway operation that verifies:

1. user authorization for assertion creation;
2. stable endpoint resolution;
3. the provenance/derived-input requirements where an AI made the claim;
4. P0 recoverable write and conflict preservation; and
5. a duplicate/conflict policy that preserves distinct claims rather than
   collapsing them by endpoint tuple.

The Gateway and candidate paths remain external-AI-neutral. AKASHA does not
host the AI or infer its relationship claims on the user's behalf.

## 9. Alternatives rejected

| Alternative | Decision | Reason |
| --- | --- | --- |
| Treat every wiki link as a fact edge | Rejected | Links express navigation and author context, not necessarily a relation claim. |
| Treat every controlled `links[].relation` as a global assertion | Rejected | It lacks independent provenance, evidence, time, conflict, and lifecycle. |
| Treat every Canvas edge as canonical | Rejected | Layout is presentation and may be freely rearranged. |
| Automatically infer inverse edges | Rejected | Direction, scope, and inverse semantics can be contested or context-specific. |
| Resolve a title-only link into a permanent relation | Rejected | Title resolution can be ambiguous and is not a stable endpoint identity. |
| Merge equal endpoint tuples automatically | Rejected | Different claimants, evidence, periods, and confidence may be meaningful. |

## 10. Explicitly deferred and next gate

This ADR does not decide:

- assertion YAML/Markdown/JSON field names, serializers, IDs, directory, or
  database representation;
- lifecycle states and semantics for retract, supersede, merge, archive, and
  tombstone;
- the final predicate and inverse vocabulary for assertions;
- confidence, ranking, truth adjudication, or consensus algorithms;
- sharing, collaboration, public graph visibility, or remote synchronization;
- Gateway permission, approval UI, batch behavior, and receipt schema.

No canonical assertion writer or relation graph UI may be implemented until:

1. the lifecycle ADR fixes non-destructive status/supersession semantics;
2. the extension-namespace ADR maps the semantic contract to additive fields;
3. a physical storage/index design demonstrates bounded queries at archive
   scale;
4. P0 fault/conflict/unknown-data tests cover assertion writes; and
5. fixtures cover disputed, temporal, Canvas-promoted, stale-evidence, and
   legacy-link cases.

The next ADR is **lifecycle/tombstone/supersede**. It must apply to Records,
Documents, candidates, and future assertions without confusing a physical file
move or `.trash` safety state with an archival semantic retraction.
