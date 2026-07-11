# Provenance and Derived-Input Contract ADR

> **Status:** Accepted semantic ADR — no model, serializer, v3 schema change,
> migration, Gateway transport, or AI service is introduced by this document.  
> **Date:** 2026-07-11  
> **Scope:** The provenance a durable Record needs when it is created from a
> user, an external source, a tool, or one or more prior Vault records.  
> **Related:** [P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md](P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md), [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](AI_ARCHIVE_WRITE_GATEWAY_ADR.md), [P0_RECOVERABLE_VAULT_WRITE_GATE.md](P0_RECOVERABLE_VAULT_WRITE_GATE.md), [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md)
> **Cases:** [PROVENANCE_AND_DERIVED_INPUT_CASES.md](PROVENANCE_AND_DERIVED_INPUT_CASES.md)

## 1. Decision

Every AKASHA Record remains a user-owned archival object in its own right.
Provenance does not rank a user note above an import or an AI interpretation.
It preserves the distinctions that let a future human or AI understand what a
Record is, where it came from, and what it was based on.

The contract therefore separates six facts that must never be collapsed into a
single `source` string:

| Fact | Question answered | Current partial carrier | Not sufficient by itself |
| --- | --- | --- | --- |
| Record creation channel | How did this Record first enter AKASHA? | v3 `source` | It does not identify an original author or an input. |
| Actor | Which human, app, external tool, or agent requested the archive action? | `ArchiveOperation.actor` | It is not durable Record provenance today. |
| Origin / authorship | Who made the original expression or external material? | `external_ids`, `evidence` | An ID or citation does not identify the author or copied material. |
| Evidence | What supports, quotes, or locates the content or assertion? | v3 `evidence` | Free text does not name an exact input revision. |
| Derivation | Which preserved inputs were transformed into this Record, and how? | None | A wiki link is not derivation. |
| Applied operation | Which AKASHA action validated and wrote it? | `source_operation_id`, applied log | It does not replace durable input provenance. |

A Record that is a durable transformation of Vault inputs MUST preserve a
**derivation declaration** in the Record itself. A receipt under `system/` may
add execution facts, but it must not be the only place where the Record's
inputs or transformation meaning survives.

## 2. Boundaries and terms

### 2.1 `source` remains a narrow creation fact

The existing v3 `source` enum (`user`, `app`, `agent`, `importTool`, `script`)
continues to mean the channel that first created the AKASHA Record. It is
immutable after creation under the current contract.

It does **not** mean any of the following:

- the author of quoted or imported material;
- a stable identity for an external AI or tool;
- every later editor of the Record;
- the Record's truth status;
- the inputs used by an interpretation.

For example, `source: importTool` says that an importer created a Vault Record.
It does not make that importer the author of a reviewed film, a copied essay,
or the user's later comment about it.

### 2.2 Actor is a locally scoped descriptor, not an AKASHA account

An actor identifies the requester of a particular archive action. An actor may
be a user, a local app feature, a script, an external tool, or an AI agent.

The future contract MUST allow an opaque, user-scoped actor reference plus an
optional display label. It MUST NOT require an AKASHA account, a cloud identity,
a model provider, or a globally resolvable agent identity. If an actor cannot
be identified truthfully, it is recorded as unspecified rather than invented.

Actor identity is also not permission. The later Gateway permission ADR decides
whether an actor was allowed to perform an operation; this ADR only defines the
provenance fact that a declared actor requested it.

### 2.3 Origin and evidence are not the same thing

Origin preserves where an imported or captured expression came from, including
an author/creator claim when known. Evidence preserves the material or citation
that supports a statement. Both can be missing, partial, private, or disputed.

`external_ids` remains an identifier map for an external Entity; it is not a
universal citation or author field. The existing string-list `evidence` remains
useful for human-readable citations, but it does not satisfy exact revision
provenance for a derived Record.

### 2.4 Derivation is a declared causal relation, not a link or edit history

A derivation declaration says that the content of a new Record was produced by
transforming declared inputs. It forms a directed acyclic provenance graph:

```text
input Record / Artifact revisions
              ↓
declared transformation + actor + operation
              ↓
new derived Record
```

It does not turn the input into a lesser Record, replace it, or claim that the
result is objectively true. It is distinct from:

- a wiki/reference link used for navigation;
- a structured link used as an in-Record relation hint;
- a future Relationship Assertion;
- a normal later edit to the same Record;
- the complete lifecycle or version history of a Document.

The [lifecycle contract](LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md) may preserve
supersession or merge history. It must not use `derived_from` as a substitute
for those meanings.

## 3. Minimum derivation invariants

When a new Record is represented as derived, all of the following are required
semantically, regardless of its future YAML field names or storage shape.

1. **Separate output.** The result has its own stable Record ID and does not
   silently rewrite an input Record.
2. **Stable input anchors.** Each Vault Record input is identified by its
   stable `record_id`, never only by a filename, title, or wiki link.
3. **Exact input state.** Each Vault input includes the revision actually read:
   its SHA-256 content digest and byte length. The opaque P0 revision value and
   modified time may be retained as diagnostics, but a timestamp alone never
   identifies the semantic input state.
4. **Declared transformation.** The output states that it is derived and names
   a transformation class. At minimum it distinguishes extraction, summary,
   translation, classification, comparison, transcription, and interpretation;
   future vocabulary can be additive and namespaced.
5. **Declared actor and operation.** The output retains the actor descriptor
   supplied for the operation and its operation ID when the Gateway created it.
   A user-created derivation may truthfully have no Gateway operation ID.
6. **Evidence context.** The output retains evidence references, an input
   location within an input, or an explicit declaration that it is an
   interpretation without extractable evidence. It must not manufacture quotes,
   citations, or confidence.
7. **Input preservation boundary.** For a Vault Artifact, the input reference
   includes a vault-relative identifier and content digest. For an external
   source that was not captured into the Vault, provenance records it only as
   an external citation with its retrieval context; it cannot promise exact
   reproducibility.
8. **No hidden collection.** AKASHA never requires raw prompts, entire chats,
   private tool context, or unseen behavior traces as a condition of a
   derivation. The user decides what inputs are archived and exposed to a tool.

The smallest valid derived Record may have one input and one short explanation.
The contract must remain usable for millions of Records, so it must not require
a copy of every input body, a global graph scan, or an append-only history blob
inside every Markdown file.

## 4. Current v3 mapping and gaps

| Existing capability | What it already protects | Gap this ADR fixes before implementation |
| --- | --- | --- |
| `created_at` / `updated_at` | Vault creation and representation-update instants | Neither is an input-read or transformation time. |
| `occurred_at` | Human experienced-time semantics | It is not a technical provenance timestamp. |
| immutable `source` | Original creation channel | It cannot identify original authorship, an external actor, or derivation. |
| `external_ids` | External Entity identity | It cannot locate a quoted source or prove which material was read. |
| `evidence` | Human-readable source citations | It has no stable input ID/revision contract. |
| `source_operation_id` | Initial operation retry/recovery anchor | It is not a complete receipt or transformation history. |
| `ArchiveOperation.actor` | A request-time caller string | It is absent from durable Record and applied-log provenance. |
| `system/ops/applied.jsonl` | Successful-operation idempotency | It has no input revisions or actor descriptor and cannot be the only memory. |
| P0 `VaultFileRevision` | SHA-256 + byte-length content identity | It is not yet attached to a derived Record's declared inputs. |
| P0 lossless YAML writer | Unknown-field survival on app saves | It does not define which future provenance fields are owned. |

Existing v3 records remain valid. Absence of the future derivation declaration
means **provenance unknown or not declared**, not "user-authored," "not
derived," or "trusted." AKASHA MUST NOT retroactively infer actor, author,
inputs, or transformation type from a title, a link, `source: agent`, or a
file path.

## 5. Durable placement rules

The Record-level extension root is now fixed by
[EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md](EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md),
but inner provenance fields and a writer remain deferred. Its placement has
non-negotiable constraints:

- the derivation core belongs with the derived Record's durable Document, so a
  copied/exported Markdown file still explains its own lineage;
- a `system/ops/` receipt may contain additional application facts, but is not
  the sole provenance copy;
- rebuildable `.akasha/` indexes may accelerate reverse input/output lookup,
  but are not authority;
- a candidate under `system/candidates/` may preserve proposal provenance, but
  it is not a canonical derived Record until promotion or explicit creation;
- P0's lossless patcher preserves unknown future provenance extensions and
  must quarantine rather than overwrite a reserved-field collision;
- callers never write storage paths, runtime index details, app-owned times,
  or receipt fields directly into a Gateway operation.

The future writer uses `x_akasha.provenance` while preserving unrelated unknown
YAML verbatim where P0 can. It must not overload existing `links`, `evidence`,
or `source_operation_id` fields to avoid adding a real provenance structure.

## 6. Operation and receipt implications

For `record.derive`, the Gateway reads all declared inputs, captures their
revisions, validates the declared transformation, then writes the output
through the P0 protocol. A changed input revision is a conflict: AKASHA must
not quietly produce a result labelled as if it used newer content.

For `record.append` or `record.patch`, the operation receipt needs the target
revision it read and the resulting revision. It does **not** make every patch a
new derived Record. A patch becomes a separate Record only when the user/tool
asks to preserve a distinct interpretation, summary, translation, or other
output rather than alter an existing Document.

An applied receipt eventually needs, at minimum:

- operation ID and operation vocabulary;
- declared actor descriptor and creation source;
- affected stable Record IDs;
- input Record/Artifact revisions where applicable;
- target previous and resulting revisions;
- applied timestamp and outcome.

Rejected, unauthorized, and stale-revision operations are never applied
receipts. P0 conflict evidence remains separate from canonical provenance.

## 7. Cases that must remain distinguishable

| Situation | Correct meaning |
| --- | --- |
| User writes a Journal directly | A primary user Record; no derivation is implied. |
| User imports an exported review | An imported Record with external origin/evidence where known; `importTool` is not the review's author. |
| AI summarizes two journals | A separate derived Record with both IDs and exact input revisions. |
| AI asserts a repeated preference | An interpretation, not a rewrite or a fact silently added to the journals. |
| Human writes a response after reading an import | A new human Record; it may cite the import but is not automatically an AI-style derivation. |
| Two tools make different summaries from identical inputs | Two coexisting Records with separate actors/operations; textual similarity does not erase provenance. |
| AI writes directly to a folder | An external edit that may be preserved/reindexed, but has no fabricated Gateway actor, receipt, or input lineage. |

The detailed regression fixtures are in
[PROVENANCE_AND_DERIVED_INPUT_CASES.md](PROVENANCE_AND_DERIVED_INPUT_CASES.md).

## 8. Alternatives rejected

| Alternative | Decision | Reason |
| --- | --- | --- |
| Use only `source: agent` for AI provenance | Rejected | It loses the particular actor, inputs, revisions, and transformation. |
| Put derivation in wiki links | Rejected | Navigation links have no revision, actor, evidence, or transformation semantics. |
| Put all provenance only in `system/ops/applied.jsonl` | Rejected | Exported Markdown would lose its own lineage; receipts are technical evidence, not the only memory. |
| Automatically record AI chats/prompts as provenance | Rejected | The user, not AKASHA, decides what source material is archived. |
| Rewrite an input Record with an AI interpretation | Rejected | It confuses original expression with later analysis and loses coexistence. |
| Backfill provenance from existing titles, links, or `source` | Rejected | Inference would falsely represent unknown history as fact. |

## 9. Explicitly deferred

This ADR does not decide:

- inner YAML field names/nesting, serializer/model types, or v3/v4 migration;
- the actor descriptor's storage, redaction, revocation, or sharing policy;
- a global author/entity identity model;
- the full transformation vocabulary, confidence model, or truth/claim model;
- physical Relationship Assertion serialization and version-history retention
  (semantic relation tiers:
  [RELATION_TIERS_AND_ASSERTIONS_ADR.md](RELATION_TIERS_AND_ASSERTIONS_ADR.md),
  lifecycle: [LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md](LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md));
- physical Gateway grant storage, approval UI, batching, or transport (semantic
  authority and receipt contract:
  [GATEWAY_PERMISSION_AND_RECEIPT_ADR.md](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md)).

## 10. Implementation gate and next ADR

No `record.derive` executor, derived-record serializer, or AI-specific import
surface may be implemented until all of the following are decided and tested:

1. a writer maps this semantic contract into the approved
   `x_akasha.provenance` namespace with P0-safe source patching;
2. the Gateway implements the authorization and durable receipt contract from
   [GATEWAY_PERMISSION_AND_RECEIPT_ADR.md](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md)
   without making `system/` the sole provenance copy;
3. stable Record and Artifact revision reads are bounded and available to the
   writer;
4. P0 conflict/fault tests cover every declared input and the output write;
5. fixtures cover missing/legacy provenance, multi-input derivation, stale
   inputs, external citations, and unknown provenance extensions.

The required semantic ADR sequence is complete:

1. [relation tiers and Relationship Assertion contract](RELATION_TIERS_AND_ASSERTIONS_ADR.md);
2. [lifecycle/tombstone/supersede contract](LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md);
3. [extension namespace and reserved-field contract](EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md);
4. [Gateway permission and receipt contract](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md);
5. **next implementation:** first `candidate.create` Gateway slice; a
   derived-record writer remains blocked by its own P0/namespace fixtures.
