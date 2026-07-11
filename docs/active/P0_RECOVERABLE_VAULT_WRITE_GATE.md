# P0 — Recoverable Vault Write Gate

> **Status:** Passed on 2026-07-10
> **Date:** 2026-07-10
> **Scope:** Every durable write to a user Vault. The P0 feature freeze is lifted; future changes must retain these invariants.
> **Related:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md)

---

## 1. Decision

AKASHA does not promise filesystem-level atomicity across Windows filesystems,
cloud-synced folders, removable drives, and process interruption. It promises
**recoverable writes** instead.

> A write may be interrupted, but AKASHA must never silently lose the last
> verified user record or silently erase data it does not understand.

This gate applies before Universal Record, behavior evidence, or any new
product feature work.

## 2. Non-Negotiable Completion Criteria

P0 passes only when every durable write path proves all three conditions:

1. **At least one verified normal copy survives.** At every interruption
   point, either the prior verified content or the verified new content remains
   recoverable.
2. **Conflicts are non-destructive.** An external revision mismatch never
   silently overwrites the on-disk source. AKASHA preserves the original,
   proposed content, and conflict evidence.
3. **Unknown user data survives.** A save never silently removes frontmatter
   fields, nested values, or body content that AKASHA does not own.

## 3. Required Shared Protocol

Every replace-style durable write must use one shared protocol:

```text
read revision
  -> lossless source patch / validation
  -> sibling staging file + SHA-256 verification
  -> preserve existing verified copy
  -> promote staged copy
  -> verify promoted content
  -> retain recovery or conflict evidence when required
```

The concrete protocol creates an immutable per-transaction manifest before any
existing normal file is moved. A manifest names every target, sibling stage,
backup, expected revision, previous revision, and proposed content revision.
Single-file writes are the one-item form of the same transaction; Canvas uses
the multi-file form. Recovery reads the manifest and restores one complete set,
never a mixture of prior and proposed Canvas files.

Revisions identify ordinary change and accidental corruption with all of:

- SHA-256 content digest
- byte length
- UTC modification timestamp

SHA-256 is the final content-equality decision. A changed modification time or
filesystem metadata alone must not create a substantive conflict when the
content digest is unchanged. Size and modification time remain useful for fast
diagnosis and recovery evidence.

They do **not** prove malicious tampering. Signatures, MACs, and chained audit
proof are a separate future security track.

Recovery and conflict artifacts must record a reason, original relative path,
expected/current/new revisions, and creation timestamp. They belong under the
durable `system/recovery/` boundary, never under disposable `.akasha/`.

`transactions.jsonl` is diagnostic evidence and an acceleration mechanism, not
the sole recovery authority. Recovery must still be able to inspect staged
siblings, preserved backups, and transaction manifests/artifact names when a
JSONL append is missing, truncated, or unreadable.

## 4. Lossless Frontmatter Rule

Known AKASHA fields are patched, not reconstructed from a reduced in-memory
model. Unknown YAML must remain in place whenever valid source frontmatter can
be read.

If frontmatter is malformed, contains a reserved-field conflict, or cannot be
patched safely:

- do not overwrite the original;
- preserve the source and the proposed content in recovery/quarantine;
- show a reason that lets the user repair or choose a version.

The preservation levels are intentionally distinct:

| Level | P0 guarantee |
| --- | --- |
| **Semantic** | Required. Unknown YAML keys, nested values, and Markdown body content remain usable with the same meaning. |
| **Source-form** | Best effort. Untouched segments should retain comments, ordering, and line form whenever the patcher can leave them in place. |
| **Byte-for-byte** | Not claimed by P0. It requires a fully raw/AST-aware editing model, including anchors and representation details. |

AKASHA must never represent semantic preservation as byte-for-byte source
preservation. Future work may strengthen the source-form guarantee without
weakening the semantic one.

## 5. Durable Writer Inventory

The gate covers, at minimum:

| Surface | Examples |
| --- | --- |
| Record Markdown | Work, Entity, Journal, Timeline |
| Composite user records | Canvas Markdown and layout |
| Durable system data | candidates, collections, personal libraries, operation logs, recovery drafts |
| User-owned assets | imported images and attachments |

Derived `.akasha/` indexes are rebuildable and are not evidence of a passed
gate. They must not be the sole copy of user-owned information.

## 6. Required Tests

- Fault injection before and after each protocol phase.
- Recovery after a missing target, stranded staging file, and preserved backup.
- Recovery when `transactions.jsonl` is missing, truncated, or malformed.
- Revision conflict preserves both source and proposed content.
- Valid unknown YAML scalar, list, map, and nested fields survive app save.
- Malformed YAML and reserved-field conflicts leave the original untouched and
  create recoverable evidence.
- Every durable writer is covered by the shared protocol or an explicitly
  documented append-only equivalent.

## 7. Direct Filesystem Call Audit

This audit is intentionally based on direct `writeAsString`, `writeAsBytes`,
`openWrite`, `rename`, `copy`, and `delete` calls under `lib/`. A direct call
does not automatically fail P0; it must have one of the classifications below.

| Classification | Paths/services | P0 treatment |
| --- | --- | --- |
| Shared protocol internals | `VaultRecoveryWriteService` stage, backup, manifest, conflict, and JSONL operations | Allowed only inside the service; manifest-first recovery and fault tests cover it. |
| Explicit lifecycle move | `VaultTrashService`, recovery-draft removal | A move never overwrites a normal record; a trash manifest is written first. Permanent deletion is an explicit user lifecycle action, not a save fallback. |
| Append-only durable system log | `ArchiveOperationAppliedLog`, `ArchiveGatewayReceiptStore`, `EventLedgerService` | `appendJsonLine`; torn final lines are ignored without hiding earlier entries. Legacy migrations use the shared writer and retain the legacy source. |
| Recoverable durable system state | `ArchiveGatewayGrantStore` | `VaultRecoveryWriteService.writeText`; malformed grant state is rejected rather than replaced with an empty authority list. |
| Rebuildable derived index | `.akasha/` entity-path, record-link, record-summary, taste, title-alias indexes; `VaultSpecWriter`; candidate name index | Out of canonical evidence scope. These may be regenerated from Vault records or canonical candidate shards. |
| Generated/export output | Sanctum HTML and backup ZIP exports | Regenerable output; never the sole record source. |
| Application cache outside the Vault | catalog contribution queue/export and registry cache/sync services | Outside the user Vault boundary; separately reviewable, but not evidence for this gate. |

Any newly introduced direct filesystem operation must be added to this table or
converted to the shared protocol before P0 can pass.

## 8. Validation Evidence

The gate passed with the following evidence on 2026-07-10:

- `flutter analyze lib --no-pub` completed with no issues.
- The full `flutter test` suite completed with **859 passing tests**.
- Fault injection covers every shared checkpoint for single-file and
  interdependent two-file writes.
- Recovery proves a Canvas-like pair resolves as one all-old or all-new set,
  including when `system/recovery/transactions.jsonl` is missing.
- Recovery also succeeds with a malformed JSONL log when the transaction
  manifest and artifacts remain, and covers a new binary asset without JSONL.
- Focused persistence tests cover revision conflict preservation, timestamp-
  only equality, unknown YAML preservation, malformed YAML quarantine, and
  Work/Entity/Journal/Timeline/Canvas storage paths.

## 9. Continuing Rule

This gate must be reopened if any Work, Entity, Journal, Timeline, Canvas, or
durable `system/` writer bypasses the shared protocol, or if any error fallback
can silently discard user data.
