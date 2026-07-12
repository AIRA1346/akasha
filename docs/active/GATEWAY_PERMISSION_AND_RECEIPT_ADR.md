# Gateway Permission and Receipt ADR

> **Status:** Accepted semantic ADR. The first local `candidate.create`
> implementation supports a user-initiated intake session and a durable local
> grant; no account system, credential store, external transport, permission
> UI, or AI service is introduced.
> **Date:** 2026-07-12  
> **Scope:** User-controlled authorization and durable applied-operation
> evidence for external tools using the AKASHA Write Gateway.  
> **Related:** [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](AI_ARCHIVE_WRITE_GATEWAY_ADR.md), [PROVENANCE_AND_DERIVED_INPUT_ADR.md](PROVENANCE_AND_DERIVED_INPUT_ADR.md), [RELATION_TIERS_AND_ASSERTIONS_ADR.md](RELATION_TIERS_AND_ASSERTIONS_ADR.md), [LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md](LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md), [EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md](EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md), [P0_RECOVERABLE_VAULT_WRITE_GATE.md](P0_RECOVERABLE_VAULT_WRITE_GATE.md)
> **Cases:** [GATEWAY_PERMISSION_AND_RECEIPT_CASES.md](GATEWAY_PERMISSION_AND_RECEIPT_CASES.md)

## 1. Decision

An external AI, script, or tool receives no AKASHA write authority by default.
For the first candidate-intake boundary, the user may authorize a bounded
archive intent through either:

1. a short-lived **user-initiated candidate-intake session**, created because
   the user started an AI-assisted archive task; or
2. a **revocable local grant** bound to one declared external actor and a
   narrow scope.

Starting an AI task is sufficient authorization for candidate intake within
that task's source, actor, byte, and expiry boundary. AKASHA must not interrupt
the user with a second per-candidate approval merely because the AI is
archiving its proposal. A one-shot, exact-intent approval remains the preferred
future rule for high-impact canonical changes, not the normal candidate flow.

The Gateway applies an operation only when all independent checks pass:

```text
user-started session / durable grant / future one-shot approval
  + actor binding
  + operation scope and target constraints
  + input / target revision checks
  + validation and P0 recoverable write
  + immutable applied receipt
```

This is not an AI identity service. An actor descriptor is a user-local label
for a chosen external integration. AKASHA proves only that the request arrived
through the locally authorized integration context; it does not claim to prove
the real-world identity of a model provider, person, or executable unless a
future transport can do so truthfully.

Raw filesystem access remains separate. A tool with ordinary folder permission
can edit user files, but that edit is never fabricated as a Gateway-authorized
operation, grant use, or receipt.

## 2. Roles and authority boundaries

| Role | Responsibility | Must not be confused with |
| --- | --- | --- |
| User / Vault owner | Grants, narrows, revokes, reviews, and chooses whether source material is archived. | An app administrator, cloud account, or AI provider. |
| External actor | Requests a structured archive intent. | A trusted identity merely because it supplied an `actor` string. |
| Gateway | Matches request to authority, validates, resolves stable IDs, uses P0, and emits receipts. | An AI host, chat service, or automatic curator. |
| Candidate review | Lets the user promote/dismiss non-canonical proposals. | Authority to mutate canonical Records. |
| Receipt | Durable evidence that one exact authorized intent applied. | The only copy of Record provenance or user content. |

`ArchiveOperation.source` remains the broad request/creation channel and
`ArchiveOperation.actor` is only a current concise caller hint. Neither field
alone is authority. A future actor binding must be a locally scoped reference
to the specific integration context the user authorized; it must not store API
keys, bearer credentials, raw prompts, or hidden conversation data in the
Vault.

## 3. Default-deny permission model

All scopes are independently granted. A grant never implies a neighboring
scope, broader target, longer lifetime, or permission to read more data.

| Semantic scope | Permits | Required constraint | Default |
| --- | --- | --- | --- |
| `candidate.create` | Create one non-canonical proposal per request in `system/candidates/`. | Declared source Record IDs/revisions/evidence and a user-started task session or durable grant. | Denied outside a bounded authority context. |
| `record.create` | Create one new canonical Record. | Record kind, target/entity scope, size/count limit, and explicit authorization. | Denied. |
| `record.derive` | Create a separate Record from declared inputs. | Provenance inputs/revisions, transformation class, and explicit authorization. | Denied. |
| `record.append` | Add a bounded labelled section to one Record. | Exact stable Record ID, expected revision, allowed section/size. | Denied. |
| `record.patch` | Change an explicitly allowed field/section of one Record. | Exact stable Record ID, expected revision, allowed field set. | Denied. |
| `candidate.promote` | Promote a reviewed candidate. | Exact candidate and target Entity scope. | User/app only unless explicitly delegated. |
| `relationship.assert` | Create a Tier 3 Relationship Assertion. | Stable endpoints, predicate, evidence/revisions, and explicit authorization. | Denied. |
| `lifecycle.transition` | Retract, supersede, merge, tombstone, or redact a semantic object. | Exact target/action and one-shot user approval in the first implementation. | Denied. |
| `record.purge` | Permanently remove user content. | Not delegable in the first Gateway. | Always user-only. |

These are semantic scopes, not a decision to add enum values or a public API
now. Existing `ArchiveOperationType` is an incomplete implementation starting
point and must not claim support for a scope simply because a similarly named
validator exists.

## 4. An authority context is bounded

Every durable grant, user-initiated session, or future one-shot approval must
carry, at minimum:

- a stable local grant/approval ID;
- a locally bound actor reference and optional human-readable label;
- permitted semantic scope(s);
- the Vault boundary and stable target selector(s), never arbitrary paths;
- operation constraints: record kinds, allowed fields/sections, entity types,
  source/input selectors, and maximum count/byte limits where applicable;
- issue time and expiry/revocation semantics appropriate to its lifetime;
- the user decision that created it, without a secret credential or raw prompt.

A user-initiated candidate session is in-memory operational context, not Vault
data and not a transferable credential. It binds the current actor and allowed
source Record IDs, has a short expiry and byte limit, and is discarded when the
user task ends. A future ingress must prove the caller is attached to that
trusted local context; a caller-supplied session ID is never enough.

A future one-shot approval binds an **intent fingerprint** for one exact
high-impact request. It is consumed only after a successful application and
cannot be reused for a changed body, target, input revision, or operation type.

A durable grant is still bounded and revocable. Revocation blocks future
applications; it does not rewrite a past Record, erase a truthful receipt, or
retroactively turn an applied operation into an unauthorized raw edit. A user
who wants to change past Record meaning uses the separate lifecycle/redaction/
purge process.

The exact local storage path, UI, transport authentication, and secure
credential exchange are deliberately deferred. Any implementation must keep
grant metadata under user-owned durable `system/` data, never in `.akasha/` or
as a hidden remote account dependency.

## 5. Intent fingerprint and idempotency

`operationId` prevents accidental retry duplication only when it identifies the
same intent. A future Gateway receipt therefore binds it to a deterministic
**intent fingerprint** over the normalized, permitted operation meaning:

- operation ID, semantic scope/type, source channel, and actor binding;
- authorization reference (durable grant, user-started session, or future
  one-shot approval);
- stable target IDs and declared input IDs/revisions;
- bounded requested payload and transformation/predicate/lifecycle action;
- no runtime path, index, secret, or irrelevant transport fields.

The exact canonical JSON/digest algorithm is an implementation detail, but it
must produce the same fingerprint for the same normalized request and a
different fingerprint when a meaningful input changes.

| Request outcome | Gateway result | Applied receipt |
| --- | --- | --- |
| New valid request | Apply once through P0. | Append immutable `applied` receipt. |
| Retry with same operation ID and fingerprint | Return prior recorded outcome. | Do not apply or append again. |
| Same operation ID with different fingerprint | Reject as operation-ID reuse conflict. | Do not apply or append as success. |
| Denied, invalid, or revoked request | Return explicit failure. | No applied receipt. |
| Stale revision / P0 conflict | Preserve proposed conflict evidence when P0 reaches a write boundary. | No applied receipt. |

The current `ArchiveOperationAppliedLog` records only enough information for
the first idempotency guard. It does not yet retain an intent fingerprint, actor
binding, grant, input revisions, or resulting revisions. It must not be called
a complete Gateway receipt until an additive implementation supplies these
facts.

## 6. Receipt contract

An applied receipt is append-only, user-owned operational evidence under
`system/ops/`. It records that AKASHA applied one exact operation; it does not
duplicate the full body or replace Record-level provenance under `x_akasha`.

Every future applied receipt needs, at minimum:

| Category | Required fact |
| --- | --- |
| Identity | Receipt schema version, operation ID, intent fingerprint, operation vocabulary, and source channel. |
| Authority | Actor binding/reference, durable grant, user-started session, or future one-shot reference, and the local authorization outcome. |
| Request boundary | Stable requested target IDs, declared input Record/Artifact IDs and revisions, and bounded payload digest/summary. |
| Result | Candidate/Record/Assertion IDs created or changed; prior and resulting content revisions; applied timestamp; `applied` outcome. |
| Provenance linkage | Operation ID/reference that the affected Record-level extension may point to, without making the receipt the only provenance. |

The receipt must exclude by default:

- raw prompts, unseen chat history, API keys, bearer tokens, or transport
  credentials;
- complete Record bodies already preserved in the canonical Document;
- private input text not needed to identify revisions/evidence;
- speculative confidence or an invented actor identity.

Candidate creation receives an applied receipt too: it changes durable
`system/candidates/` state even though it does not create a canonical Record.
The receipt lists candidate result IDs rather than pretending a candidate is an
archived Record.

Rejected/denied/conflicted attempts are not success receipts. An optional
future diagnostic audit may exist, but it must be opt-in, separate from the
applied ledger, bounded in retention, and never required to reconstruct a
user's archive.

## 7. Authorization and P0 sequence

```text
external intent
  -> bind local actor context
  -> locate active user-started session / durable grant / future one-shot approval
  -> validate scope, target selectors, constraints, and intent fingerprint
  -> read declared input and target revisions
  -> validate semantic operation
  -> P0 recoverable write / candidate update
  -> verify result revision
  -> append immutable applied receipt
  -> return receipt-derived result
```

No receipt is written before the canonical/durable operation is verified. If a
write succeeds but receipt append is interrupted, recovery must use the
operation ID, resulting Record provenance marker where applicable, and P0
evidence to roll forward safely. It must never repeat an operation merely
because a receipt line is absent. This extends the existing `promoteCandidate`
roll-forward principle; the exact recovery algorithm is implementation work.

## 8. First implementation boundary

The first Gateway implementation must be deliberately smaller than the full
contract:

1. support only `candidate.create`;
2. one candidate per operation, with a small explicit count/size limit;
3. require an active local actor binding and either a user-started candidate
   task session or a durable candidate-intake grant;
4. require source Record IDs/revisions and evidence for candidate provenance;
5. write through the existing candidate store/P0 path and append a complete
   receipt;
6. provide review/promotion separately; candidate intake never promotes or
   edits a Record.

No direct canonical Record creation, derived Record, patch/append, relationship
assertion, lifecycle transition, batch application, or delete/purge delegation
belongs in this first slice.

## 9. Current implementation mapping

| Current capability | Useful foundation | Missing before Gateway use |
| --- | --- | --- |
| `ArchiveOperation` | Stable operation ID, type/source/actor hint, target, expected revision, payload. | Grant/approval reference, actor binding, input revisions, semantic scopes, and fingerprint. |
| `ArchiveOperationValidator` | Path/identity/provenance-field mutation guards. | Authorization and scope/constraint validation. |
| `ArchiveOperationExecutor` | Safe `promoteCandidate` execution. | Candidate intake and all general Gateway operations. |
| `ArchiveOperationAppliedLog` | Successful operation ID lookup and append-only durable location. | Complete receipt fields and ID-reuse fingerprint defense. |
| Candidate store | Durable non-canonical candidate lifecycle. | Gateway-created candidates now retain actor, source revision, and authorization route; high-volume review policy remains open. |
| P0 writer | Recoverable writes, conflict evidence, unknown YAML preservation. | Gateway-specific operation wiring and fault fixtures. |
| `x_akasha` contract | Future portable Record-level provenance location. | Parser/writer/spec implementation. |

## 10. Alternatives rejected

| Alternative | Decision | Reason |
| --- | --- | --- |
| Trust `actor: "agent"` as authority | Rejected | A caller-supplied label is not a user grant or local integration binding. |
| Give all tools default candidate access | Rejected | Candidates are durable user-owned data and can create noise at scale. |
| Let `candidate.create` imply record creation/promotion | Rejected | Candidate review is the boundary that protects canonical archive quality. |
| Treat raw folder permission as Gateway permission | Rejected | It bypasses authority, revision, receipt, and P0 operation semantics. |
| Write denial/conflict payloads into the applied ledger | Rejected | It confuses success evidence with diagnostics and can retain unnecessary private data. |
| Store API credentials or raw prompts in receipts | Rejected | The receipt needs archival accountability, not secret/context collection. |
| Allow delegated purge in the first Gateway | Rejected | Permanent content removal requires direct user control and separate privacy guarantees. |

## 11. Explicitly deferred

This ADR does not decide:

- local grant storage schema/path, UI wording, approval interaction, or actor
  binding mechanism;
- MCP, CLI, local socket, SDK, HTTP, filesystem drop, or any transport;
- cryptographic identity proof, signatures, shared accounts, or cloud sync;
- secure credential storage and external-tool authentication protocol;
- batch transaction grouping, rate limits beyond first-slice bounds, or a
  complete audit-log retention policy;
- actual `ArchiveOperation` enum/model/parser/validator/receipt changes;
- a user-facing candidate review UI, Relationship Assertion storage, or
  lifecycle writer.

## 12. Completion gate and next step

The semantic design chain is complete only when this ADR is paired with the
prior provenance, relation, lifecycle, and extension contracts. The next work
is implementation, not another broad ontology: a small `candidate.create`
Gateway slice with contract fixtures, P0 fault/conflict tests, targeted
analysis, and full test validation.

That slice must update the formal Vault specification and bundled self-
describing copy only if it begins writing `x_akasha` Record data. If it stores
only candidate/receipt operational data, it must still preserve all existing
unknown YAML and cannot claim derived Record provenance.
