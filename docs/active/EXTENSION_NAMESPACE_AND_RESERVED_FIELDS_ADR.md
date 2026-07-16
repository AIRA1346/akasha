# Extension Namespace and Reserved-Field ADR

> **Status:** Accepted extension contract — no v3 writer, parser, serializer,
> migration, formal specification update, or new frontmatter field is emitted
> by this ADR.  
> **Date:** 2026-07-12  
> **Scope:** Additive Record-level metadata for future AKASHA provenance,
> lifecycle, and Relationship Assertion implementations without taking over
> user or third-party YAML.  
> **Related:** [P0_RECOVERABLE_VAULT_WRITE_GATE.md](../history/closure-2026-07/P0_RECOVERABLE_VAULT_WRITE_GATE.md), [PROVENANCE_AND_DERIVED_INPUT_ADR.md](PROVENANCE_AND_DERIVED_INPUT_ADR.md), [RELATION_TIERS_AND_ASSERTIONS_ADR.md](RELATION_TIERS_AND_ASSERTIONS_ADR.md), [LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md](LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md), [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md)
> **Cases:** [EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_CASES.md](../history/closure-2026-07/EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_CASES.md)

## 1. Decision

Future AKASHA-owned additive Record metadata lives under exactly one optional
top-level YAML map: **`x_akasha`**.

```yaml
x_akasha:
  extension_schema_version: 1
  provenance:
    # future contract-owned fields
  lifecycle:
    # future contract-owned fields
  relationship_assertion:
    # only on a future canonical Assertion representation
```

This root is deliberately optional. An existing Record without `x_akasha`
remains fully valid. Current application code does not emit, parse as owned, or
rewrite this map; until an implementation slice adds it safely, P0 treats it as
unknown YAML and preserves it.

`x_akasha` is an extension container, not a new universal Record model and not
a generic dumping ground. It is the only future home for **new AKASHA-owned
Record-level** fields that implement the already accepted provenance,
lifecycle, or independent-assertion contracts. New top-level fields such as
`derived_from`, `tombstone`, `assertion_status`, or `actor` must not be added
ad hoc.

## 2. Why one explicit root

AKASHA already has a v3 set of top-level fields and domain-specific fields.
The lossless writer patches only known owned keys and preserves everything
else. Adding every new concept as another top-level key would eventually make
ownership ambiguous and increase the chance that a future app overwrites a
user/tool field it does not understand.

The chosen name follows the existing Vault convention demonstrated by fields
such as `x_external`: an `x_` prefix visibly signals extension data without
claiming that all extensions belong to AKASHA.

| Alternative | Decision | Reason |
| --- | --- | --- |
| New top-level field for each feature | Rejected | Ownership/collision surface grows forever and obscures the stable v3 core. |
| Generic top-level `extensions` | Rejected | It is ambiguous, already used with different meaning in registry JSON, and does not say who owns a child. |
| Top-level `akasha` | Rejected | It looks like ordinary user content and does not visibly signal an extension boundary. |
| One `x_akasha` map with versioned child domains | Accepted | Human-readable, additive, owned by one contract, and compatible with P0 lossless patching. |
| Hidden `system/` or SQLite metadata as the sole extension store | Rejected | Exported Markdown would lose durable Record meaning. |

## 3. Namespace ownership matrix

| YAML surface | Owner | Writer rule |
| --- | --- | --- |
| Existing v3 and record-family fields | AKASHA only where current serializers explicitly own them | Patch only the documented owned keys; preserve all other source segments. |
| `x_akasha` root | AKASHA extension contract | Create/change only after a feature implements this ADR's collision and P0 tests. |
| Recognized children of `x_akasha` | Their named AKASHA sub-contract | A writer patches only the child it owns; it never reconstructs the whole map. |
| Unknown children of `x_akasha` | Future/foreign extension data | Preserve unchanged. Do not reinterpret or delete. |
| Other `x_*` roots (`x_external`, `x_user`, `x_vendor`) | User or named external tool | Preserve unchanged; AKASHA has no write authority. |
| Other unknown top-level YAML and body Markdown | User/external tool | Preserve unchanged under P0. |
| `system/` operation receipts, candidates, recovery data | AKASHA durable operational state | Not a replacement for Record-level `x_akasha` meaning. |
| `.akasha/` indexes | Rebuildable derived state | Never the only copy of extension meaning. |

`u:` relation vocabulary is separate from YAML namespaces: it is only a token
namespace for user-defined relation predicates. It grants no ownership over a
frontmatter key.

## 4. Reserved root shape

When present, `x_akasha` MUST be a YAML map with:

```yaml
x_akasha:
  extension_schema_version: 1
```

`extension_schema_version` is an integer describing only this container. It is
not the Record's existing `schema_version` and does not upgrade v3 to a new
Record format.

Version 1 reserves these direct child names:

| Child | Intended semantic home | Not a decision about |
| --- | --- | --- |
| `provenance` | Derived inputs, actor/origin descriptors, and transformation declaration. | The final inner field list or serializer. |
| `lifecycle` | Explicit retraction, supersession, merge, tombstone, and redaction references. | Status enum, transition storage, retention, or purge behavior. |
| `relationship_assertion` | A future canonical Tier 3 assertion's claim/provenance anchor. | Assertion Document layout, graph storage, predicate vocabulary, or UI. |

No conforming writer emits empty child maps merely to reserve space. A child is
created only by the feature that has a finalized semantic contract and a tested
writer. Future child names are additive. They must be lower `snake_case` and
must be documented before a writer owns them.

The `relationship_assertion` child is forbidden on ordinary Work, Entity,
Journal, Timeline, and Canvas Records unless a later implementation defines
that Record as the canonical representation of an Assertion. It must never be
used to silently elevate `links[]` or Canvas layout edges.

## 5. Collision and forward-compatibility protocol

The namespace is valuable only if AKASHA refuses to guess when it encounters
data it cannot safely own.

| Existing `x_akasha` state | Base Record read | Operation that does not touch extension | Operation that needs to write extension |
| --- | --- | --- | --- |
| Absent | Read normally. | Normal P0 save. | Create valid v1 root and required child. |
| Valid v1 map | Read normally. | Preserve map source unchanged. | Patch only the owned v1 child. |
| Valid future version | Read normally as opaque extension data. | Allowed only if the patcher can leave the entire root untouched. | Reject as unsupported; preserve original and proposed content. |
| Scalar/list/invalid root | Read base Record when possible. | Allowed only if root remains untouched safely. | Reject as reserved-root collision; preserve original and proposed content. |
| Duplicate key, malformed YAML, or unsafe patch | Do not normalize it away. | Reject if safe patching is impossible. | Reject; P0 quarantine/recovery evidence is required. |

An extension writer must first parse/validate the exact existing root and
version, then patch only its declared child source segment. It must never parse
the YAML into a reduced map and serialize a replacement `x_akasha` tree.

If a user or tool previously used the literal key `x_akasha` for unrelated
content, that data wins. AKASHA does not rename, migrate, or overwrite it
silently; a future user-facing repair/migration may offer a choice with the
original preserved.

## 6. Separation from operations and runtime state

`x_akasha` stores durable Record meaning. It does not store:

- Gateway authority grants, access tokens, approval UI state, or secrets;
- mutable indexes, caches, search projections, or Canvas layout state;
- the sole operation receipt or idempotency log;
- raw prompts, unseen chats, or behavior traces the user did not choose to
  archive;
- a tool's arbitrary private configuration.

Gateway receipts stay under user-owned `system/ops/` and must refer to the
affected Record/provenance state without replacing it. External tools use their
own `x_<tool>` root or a separate Artifact/Document, which AKASHA preserves but
does not own.

## 7. Migration and compatibility rules

This ADR changes no existing file and requires no migration:

- a missing `x_akasha` means the extension data is absent/unknown, never a
  negative claim such as "not derived" or "not retracted";
- existing `source`, `evidence`, `links`, `source_operation_id`, Candidate
  status, and Canvas data retain their current meanings;
- no existing top-level field is moved into `x_akasha` automatically;
- a future implementation may add the root to a v3 Record as an optional,
  additive field only after updating the formal specification and its bundled
  self-describing copy together;
- readers that do not understand `x_akasha` still retain a useful Markdown
  Record and must preserve the map when rewriting.

The formal [v3 specification](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) is not
modified by this ADR because no current writer emits the namespace. The first
implementation slice must update the formal specification, bundled Vault spec,
ownership table, parser, serializer, fixtures, and P0 fault tests together.

## 8. Current code impact and implementation gate

`VaultFrontmatterOwnership` currently does **not** list `x_akasha` among owned
keys. This is intentional until a feature owns a tested child. The current
`VaultLosslessRecordWriter` therefore preserves `x_akasha`, `x_external`, and
other unknown YAML as source material on ordinary saves.

Before any code starts writing a child, all of the following are required:

1. the child contract has an approved ADR and semantic fixtures;
2. the writer can source-patch the root and child without rebuilding unknown
   siblings, comments, ordering, or nested data it does not own where P0 can
   preserve them;
3. valid v1, absent root, foreign root collision, future-version root,
   malformed YAML, and unknown-child fixtures pass;
4. the formal v3 spec and self-describing Vault copy are updated atomically
   with parser/serializer ownership;
5. the shared P0 writer covers normal, stale-revision, crash, conflict, and
   restart behavior for the extension write.

## 9. Alternatives rejected

| Alternative | Decision | Reason |
| --- | --- | --- |
| Treat every unknown YAML field as a future AKASHA field | Rejected | It breaks user ownership and makes external tools unsafe. |
| Let AI choose new top-level metadata names | Rejected | It creates unbounded schema drift and collision risk. |
| Rewrite all unknown YAML into one normalized extension map | Rejected | It destroys source form and possibly meaning. |
| Put provenance only in `system/ops/` | Rejected | A Record copied from the Vault would lose its own lineage. |
| Use `links[]` / Candidate state for lifecycle or assertions | Rejected | They have deliberately narrower, incompatible meanings. |
| Make `x_akasha` mandatory for every Record now | Rejected | Existing and manual Records must remain simple, portable, and valid. |

## 10. Next gate

The Gateway authority decision is fixed by
[GATEWAY_PERMISSION_AND_RECEIPT_ADR.md](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md).
It defines user grants, actor binding, approval/revocation, idempotency receipt
fields, and conflict outcomes while respecting this namespace and P0.

Implementation may now begin with one small `candidate.create` intake slice.
It must not begin with a derived-record writer, universal Record migration,
global relation graph, or AI chat service.
