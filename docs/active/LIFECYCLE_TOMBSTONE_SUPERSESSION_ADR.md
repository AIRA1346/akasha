# Lifecycle, Tombstone, and Supersession ADR

> **Status:** Accepted semantic ADR — no lifecycle model, serializer,
> tombstone storage, migration, purge feature, or Gateway executor is
> introduced by this document.  
> **Date:** 2026-07-12  
> **Scope:** The distinction between physical file availability and the
> semantic standing of Records, Documents, candidates, and future Relationship
> Assertions.  
> **Related:** [P0_RECOVERABLE_VAULT_WRITE_GATE.md](../history/closure-2026-07/P0_RECOVERABLE_VAULT_WRITE_GATE.md), [P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md](../history/closure-2026-07/P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md), [PROVENANCE_AND_DERIVED_INPUT_ADR.md](PROVENANCE_AND_DERIVED_INPUT_ADR.md), [RELATION_TIERS_AND_ASSERTIONS_ADR.md](RELATION_TIERS_AND_ASSERTIONS_ADR.md), [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](AI_ARCHIVE_WRITE_GATEWAY_ADR.md)
> **Cases:** [LIFECYCLE_TOMBSTONE_SUPERSESSION_CASES.md](../history/closure-2026-07/LIFECYCLE_TOMBSTONE_SUPERSESSION_CASES.md)

## 1. Decision

AKASHA must preserve the difference between a file's location and a record's
meaning. A file moved to `.trash` is recoverable storage state; it is not a
claim that its Record is false, obsolete, merged, or intentionally forgotten.

Lifecycle therefore has three independent axes:

| Axis | Question | Examples | Must not be confused with |
| --- | --- | --- | --- |
| Physical availability | Where are the bytes now? | canonical path, `.trash`, recovery backup, permanently purged | truth or semantic retirement |
| Document representation | Is the same Document content edited, moved, split, or redacted? | updated revision, rename, file move | a different Record or a lifecycle claim |
| Semantic standing | How should this archival object be understood now? | current, retracted, superseded, merged, tombstoned | a filesystem operation |

All user records are already part of an archive. This ADR deliberately does
not use **archived** as a semantic inactive state.

The normal state of a Record or Relationship Assertion is **current**. A
semantic lifecycle transition is created only by an explicit user action or a
later authorized operation. It is never inferred from a file move, revision
change, repeated title, Canvas edge, index rebuild, raw external edit, or
missing file.

## 2. Terms and boundaries

| Term | Meaning | Required preservation |
| --- | --- | --- |
| Edit | Change to the same Document/Record representation. | P0 revision history/recovery evidence as applicable; no automatic lifecycle transition. |
| Move / rename | Physical Document location change. | Stable semantic ID remains; no semantic transition. |
| Trash | Reversible physical quarantine under `.trash`. | Original file and trash manifest until restore or explicit permanent deletion. |
| Permanent purge | Explicit removal of bytes from the active Vault/trash surface. | No automatic semantic tombstone; privacy-sensitive cleanup is a separate explicit process. |
| Retract | Claimant says a Record or Assertion should no longer be relied upon as its prior claim. | Original object, claimant/provenance, transition reason/time; no silent overwrite. |
| Supersede | A stable successor is intended to be preferred over a prior object for a stated purpose. | Both IDs and the directional predecessor → successor reference. |
| Merge | Explicitly consolidate duplicate semantic identity around a surviving canonical target. | Old ID remains resolvable as merged; no automatic content deletion. |
| Tombstone | Minimal durable marker that a stable ID was intentionally retired/unavailable. | Only the minimal user-approved locator/status/reason needed; never automatic. |
| Redaction | Intentional removal or replacement of part of accessible content. | Explicit user decision; it is not automatically a retract, supersession, or purge. |

`retract`, `supersede`, `merge`, and `tombstone` have different meanings and
must not be represented by the same generic `deleted: true` flag.

## 3. Non-negotiable lifecycle invariants

Every future semantic lifecycle transition must satisfy these rules.

1. **Explicit target.** It names the stable Record, Entity, Candidate, or
   Relationship Assertion being changed. A file path or title alone is not a
   lifecycle target.
2. **Explicit action.** The operation states whether it retracts, supersedes,
   merges, tombstones, or redacts. Readers never infer this from absence.
3. **Preserved predecessor.** Retraction, supersession, and merge do not erase
   the prior semantic object. A successor/canonical target, when required, has
   its own stable ID.
4. **Transition provenance.** It records the actor, operation, creation channel,
   decision time, and optional user-controlled reason. `updated_at` alone is
   not a lifecycle decision.
5. **Two time meanings.** The time AKASHA records the transition is distinct
   from when the transition became semantically effective. Neither replaces an
   event's `occurred_at` or the original `created_at`.
6. **No silent propagation.** A transition on one Record does not rewrite or
   delete linked Records, Entity Documents, Canvas edges, or assertions. A
   future UI may show consequences, but each affected semantic object needs its
   own explicit transition.
7. **P0 remains below lifecycle.** Every write uses recoverable storage and
   preserves unknown fields/conflict evidence. A recovery manifest or backup
   is not lifecycle history.
8. **Tombstones are opt-in.** Physical deletion, `.trash`, raw external file
   deletion, or a failed parse never automatically creates one. A tombstone may
   be undesirable because even a stable ID can be sensitive information.
9. **No accidental convergence.** Duplicate-looking content, matching titles,
   or equal relationship endpoints may produce a review suggestion but never a
   merge, supersession, or tombstone by themselves.

## 4. Current implementation mapping

| Current capability | What it does | What it must not be treated as |
| --- | --- | --- |
| `VaultTrashService.moveFileToTrash` | Moves a file into `.trash` after a recoverable manifest write. | Record/Entity/Assertion tombstone or retraction. |
| Restore from `.trash` | Moves bytes back to their original path. | Revival of a semantically retracted or superseded claim. |
| `deleteEntryPermanently` | Deletes the physical trash entry after explicit user action. | A guarantee that all recovery, backup, export, or sync copies are erased. |
| P0 recovery backup/conflict/manifest | Preserves normal and proposed file states after interruption/conflict. | User-visible version history or an approval to retain erased content forever. |
| `created_at` / `updated_at` | Creation and representation-update timestamps. | Retraction, validity, or succession time. |
| Candidate `candidate/promoted/dismissed/merged` | Operational state of a non-canonical proposal. | Generic Record or Relationship Assertion lifecycle. |
| `source_operation_id` / applied log | Idempotency and write trace for an operation. | The full semantic lifecycle of a Record. |
| Canvas edge deletion | Changes a layout connection. | Relationship Assertion retraction. |

Existing `ArchiveCandidateStatus` remains valid with its narrow meaning:

- **promoted** creates/points to an archived Entity; the candidate does not
  become that Entity;
- **dismissed** declines a proposal; it does not retract an existing Record;
- **merged** points a duplicate candidate at an Entity; it is not a generic
  merge of all Documents that mention the candidate.

## 5. Semantic transition rules

### 5.1 Retraction

Retraction says, "the claimant no longer stands behind this claim as previously
presented." It is appropriate for a Relationship Assertion, an imported claim,
or a user-authored assertion that the user explicitly withdraws.

It does not mean that the original bytes were wrongfully stored, that a diary
entry never happened, or that the user must delete their past self. A retracted
object remains readable unless a separate user-controlled redaction or purge
action changes physical availability.

### 5.2 Supersession

Supersession says, "use this later object instead for this defined purpose."
It requires a predecessor ID, successor ID, explicit direction, and optional
scope/reason. The predecessor remains addressable and its provenance stays
intact.

Creating another Journal, AI summary, imported edition, or Canvas layout does
not automatically supersede the earlier one. Supersession is especially useful
when a corrected interpretation or updated external capture should be preferred
without pretending the original never existed.

### 5.3 Merge

Merge says, "these semantic identities are being intentionally consolidated."
It is stronger than linking or superseding and must name a canonical surviving
target. It never follows only from textual equality or an AI duplicate score.

The detailed merge model is intentionally deferred: Entity identity merges,
Record-content merges, Candidate duplicate closure, and Assertion deduplication
have different risks. Until those models exist, the app may preserve a duplicate
suggestion but must not perform a generic merge.

### 5.4 Tombstone

A tombstone is a minimal, explicit semantic marker for a stable ID that should
continue to resolve as intentionally retired or unavailable. It can prevent a
future importer, synchronizer, or collaborator from silently recreating a
removed identity.

It is **not** mandatory after deletion. A user may choose complete local
removal, including absence of the former ID, rather than leave a durable
marker. A future tombstone flow must show exactly what remains and why.

### 5.5 Redaction and purge

Redaction changes accessible content while preserving a deliberately chosen
semantic object/locator. Permanent purge removes bytes. Either may coexist with
a tombstone, retraction, or supersession only when the user explicitly asks
for both meanings.

AKASHA must not claim secure erasure merely because a source file is purged.
An eventual privacy-purge feature must disclose and explicitly handle related
`.trash`, `system/recovery`, conflict, draft, export, and user-managed sync
copies. Filesystem recovery and third-party synchronization guarantees are a
separate security problem.

## 6. Record, Document, Assertion, and Canvas consequences

One physical Markdown file may represent an Entity and a principal Record, so
physical removal cannot by itself determine which semantic object, if any, was
retired. The future lifecycle operation must name each intended target rather
than assume a permanent file ↔ Record ↔ Entity 1:1 mapping.

| Object | Lifecycle consequence |
| --- | --- |
| User Journal / Timeline | A later reflection is normally a new Record, not a supersession. The user may explicitly retract/redact/purge it. |
| Imported Record | A newer capture may supersede an older capture only when declared; external source correction is evidence, not automatic replacement. |
| AI-derived Record | A regenerated interpretation is a new Record. It supersedes an older one only by explicit decision and retains distinct input revisions. |
| Relationship Assertion | Retraction/supersession/merge applies to the independent claim; source Records and Canvas views are unchanged. |
| Candidate | Uses its existing proposal lifecycle, not generic Record retraction. |
| Canvas | Deleting an edge/layout changes presentation only. A Canvas may later display lifecycle state but cannot own it. |

## 7. Scale and storage direction

Lifecycle is a semantic graph of targeted transitions, not a full copy of every
Document on every edit. Future storage must support bounded lookup of an object
by stable ID and its direct predecessor/successor/canonical target without a
whole-Vault scan.

The canonical physical form is deferred to implementation design under the
approved [extension namespace](EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md).
It must provide:

- a portable, user-owned representation for each semantic transition;
- bounded derived indexes for current/retired and predecessor/successor views;
- non-destructive conflict handling and unknown-field survival under P0;
- no requirement to retain a tombstone or sensitive reason after a user chose
  full local removal;
- no database-only status that makes an exported Record uninterpretable.

## 8. Additive migration rules

Existing Vault records remain **current/unknown lifecycle** unless a user adds
an explicit transition. AKASHA must not backfill retraction, supersession,
merge, or tombstone state from `.trash`, missing paths, changed titles,
`updated_at`, duplicate detectors, or legacy `source_operation_id` values.

The future lifecycle extension must be additive. It cannot repurpose `source`,
`evidence`, `links[]`, `derived_from`, Candidate status, or Canvas layout as a
generic lifecycle field. P0 must preserve unknown lifecycle extensions during
all ordinary saves.

## 9. Gateway implications

An external AI/tool may propose a lifecycle transition as a non-canonical
candidate, explaining target, action, evidence, and reason. It must not apply a
retraction, supersession, merge, tombstone, redaction, or purge without a later
explicit scope and approval.

For a future authorized transition, the Gateway must verify target IDs and
expected revisions, preserve old/new/conflict content through P0, emit a
durable receipt, and keep the semantic transition separate from a physical
move. An external raw deletion is an observed filesystem change, not an
authorized tombstone.

## 10. Alternatives rejected

| Alternative | Decision | Reason |
| --- | --- | --- |
| Treat `.trash` as a tombstone | Rejected | Reversible storage quarantine is not a semantic claim. |
| Treat every edit as a version/supersession | Rejected | It turns ordinary writing into noisy artificial history. |
| Automatically tombstone deleted files | Rejected | It violates user control and can retain sensitive identifiers. |
| Delete old records when a successor exists | Rejected | It destroys provenance, evidence, and the user's historical expression. |
| Use Candidate statuses as a universal lifecycle enum | Rejected | Candidate review is operational and not Record/Assertion semantics. |
| Make AI duplicate detection merge records | Rejected | Similarity cannot decide user meaning or canonical identity. |
| Store lifecycle only in a hidden database/log | Rejected | Exported user records would lose their semantic standing. |

## 11. Explicitly deferred and next gate

This ADR does not decide:

- YAML/Markdown/JSON field names, status enums, serializers, storage paths,
  compaction, or migration commands;
- retention periods, default deletion policy, secure erase guarantees, backup
  retention, or third-party sync cleanup;
- detailed merge algorithms for Entities, Records, Candidates, or Assertions;
- sharing/collaboration conflict policy;
- physical Gateway grant storage, approval UI, or receipt serializer (semantic
  authority contract:
  [GATEWAY_PERMISSION_AND_RECEIPT_ADR.md](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md)).

No lifecycle writer, Assertion writer, or AI lifecycle operation may be
implemented until a P0-safe writer maps these distinctions into the approved
extension namespace and the
[Gateway authority contract](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md) is
implemented with its authority and audit rules.
Each implementation must have P0 fault/conflict tests and fixtures for trash,
restore, purge-without-tombstone, retraction, supersession, merge, redaction,
and legacy unknown lifecycle state.

The next work is the first minimal **candidate.create Gateway** implementation.
It must prove local actor binding, candidate-intake authorization, idempotent
receipts, P0-safe writes, and review separation before any direct Record,
relationship, or lifecycle mutation is attempted.
