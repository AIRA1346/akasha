# Gateway Permission and Receipt Cases

> **Status:** Semantic regression fixtures for
> [GATEWAY_PERMISSION_AND_RECEIPT_ADR.md](../../active/GATEWAY_PERMISSION_AND_RECEIPT_ADR.md).
> They are not API payloads, credential formats, permission UI mocks, or
> implementation tests.

## Case 1 — No authority context means no candidate write

An external AI submits a valid-looking Person candidate with an actor label and
evidence from a user Journal.

Required result:

- the actor label alone grants nothing;
- no candidate file, canonical Record, index update, or applied receipt is
  created;
- AKASHA returns an explicit authorization failure without retaining the full
  proposed content as a success record;
- the user may later start a bounded AI archive task or configure a durable
  candidate-intake grant.

## Case 2 — A user-started task admits candidates without a second prompt

The user starts an AI-assisted archive task from one or more declared source
Records. The local task session is bound to its actor, allowed source IDs,
expiry, and byte limit. The AI submits one candidate request from an allowed
source.

Required result:

- AKASHA creates exactly one candidate through the durable candidate/P0 path;
- no second per-candidate approval prompt is required;
- the applied receipt records the actor binding, user-started session reference, input
  revision, candidate ID, resulting candidate revision, and intent fingerprint;
- retrying the identical operation returns the prior receipt-derived result;
- a source outside the task boundary, a mismatched actor, or an expired session
  is denied without writing a candidate or receipt.

## Case 3 — Operation-ID reuse with changed content is rejected

An actor retries `op_42` but changes the candidate title or source revision.

Required result:

- the normalized intent fingerprint differs from the existing receipt;
- AKASHA rejects the request as operation-ID reuse conflict;
- it neither mutates the prior candidate nor appends a second success receipt;
- the caller must issue a new operation ID within a still-valid authority
  context; a future high-impact operation may require a fresh one-shot approval.

## Case 4 — Revocation stops future writes, not history

The user grants a local tool `candidate.create` for one day, then revokes it
after two candidates were applied.

Required result:

- later requests from that actor binding are denied;
- the two prior candidates and receipts remain truthful historical evidence;
- revocation does not automatically dismiss candidates, retract Records, or
  purge data;
- the user may separately review/dismiss candidates or perform lifecycle work.

## Case 5 — Candidate authority cannot create a derived Record

An actor has only `candidate.create` authority and asks to write an AI summary
as a canonical Record.

Required result:

- AKASHA denies `record.derive` because scopes never escalate;
- it may accept a non-canonical proposal only if the user grant allows that
  proposal shape;
- no `x_akasha.provenance` Record data is written until the derived-record
  implementation exists and has its own authorization.

## Case 6 — Stale target produces conflict, not an applied receipt

An authorized `record.append` request names a target Record revision. The user
edits the target before application.

Required result:

- revision validation fails and canonical target content is not overwritten;
- P0 preserves proposed conflict evidence where a write boundary is reached;
- no applied receipt is appended because nothing applied;
- retry requires an explicit new/freshly authorized intent, never automatic
  merge against the user's newer content.

## Case 7 — Raw folder access is still external editing

The user gives a local AI ordinary access to the Vault folder. It creates a
Markdown file directly.

Required result:

- AKASHA preserves/reconciles the user-owned external file where possible;
- it does not fabricate a grant reference, actor binding, intent fingerprint,
  or receipt;
- raw folder permission is not silently upgraded into Gateway authority.

## Case 8 — Receipts do not archive unseen chats or secrets

A Gateway request is accepted after the external AI used a large private prompt
and provider credential outside AKASHA.

Required result:

- the receipt retains only bounded operation identity, authority reference,
  target/input revisions, and resulting revisions;
- it does not store the provider key, bearer token, full prompt, or unrelated
  conversation transcript;
- user-chosen source Records remain the only archived input context unless the
  user separately archives more.

## Case 9 — Relationship and lifecycle actions stay high-risk

An actor with `record.patch` asks to retract a Relationship Assertion and purge
the source Record.

Required result:

- `record.patch` does not cover `lifecycle.transition` or `record.purge`;
- lifecycle transition requires its own explicit authority and exact target;
- purge is user-only in the first Gateway;
- no Canvas edge, `links[]`, or Candidate status is mutated as a shortcut.

## Case 10 — First implementation refuses batch escalation

An external tool submits 10,000 candidate requests as one batch.

Required result:

- the first Gateway slice rejects unsupported batch semantics rather than
  partially applying an unbounded set;
- it does not create a broad durable grant by accident;
- later batching requires a separately designed limit, transaction, review,
  and receipt policy.
