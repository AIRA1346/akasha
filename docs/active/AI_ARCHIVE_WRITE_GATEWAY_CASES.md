# AI Archive Write Gateway Cases

> **Status:** Semantic fixtures for [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](AI_ARCHIVE_WRITE_GATEWAY_ADR.md). These are not API payloads, models, serializers, or migrations.

## Case 1 — AI finds a possible Entity

An external AI reads user-authorized source records and notices a repeatedly
mentioned person.

| Input | Required result |
| --- | --- |
| Actor identity, source Record IDs/revisions, evidence snippets, proposed person title/aliases | One candidate under `system/candidates/`; no Entity journal and no canonical Record is created. |
| Same candidate submitted again | Idempotent/deduplicated candidate result, never a second canonical Entity. |
| User promotes it | A separately authorized promotion operation creates the Entity journal and closes the candidate. |

The AI did useful archival work, but it did not decide that every mention
deserves permanent archival status.

## Case 2 — AI writes an interpretation of a user Journal

Input Records:

```text
jr_2026_07_11_night @ revision A
tl_2026_07_10_concert @ revision B
```

The AI proposes: “A repeated preference for quiet nighttime performances.”

| Direct application permission | Required result |
| --- | --- |
| Not granted | Candidate/proposal only. The two source Records remain unchanged. |
| `record.derive` granted | A new derived Record is created. It retains both source IDs and revisions, actor, operation ID, and evidence references. It does not rewrite the Journal or Timeline source text. |

The exact `derived_from` schema and derived Record kind remain deferred; the
separation requirement does not.

## Case 3 — AI appends to an existing Record

The user authorizes an AI to append a clearly labelled research note to
`rec_wk_u_abc12345`.

| Gateway check | Result |
| --- | --- |
| Operation has `record.append`, target record ID, grant, and expected revision | AKASHA resolves the path, verifies the revision, applies through the P0 writer, preserves unknown YAML/body blocks, updates bounded indexes, and appends a receipt. |
| The target revision differs | The canonical Record is unchanged. The proposed content is retained as conflict evidence and the caller receives a conflict result. |
| The same operation ID is retried after success | It returns the prior applied result; it does not append twice. |

The original `source` remains its creation source. The later agent action is
identified through its operation receipt/provenance pointer, not by relabelling
the Record as if the AI created it.

## Case 4 — AI requests an unauthorized overwrite

The AI requests `record.patch` on a user-authored review but has only
`candidate.create` permission.

Expected result:

- no Vault write;
- no applied operation receipt;
- an explicit authorization failure;
- optionally a candidate/proposal if the user chose to retain suggestions.

AKASHA does not infer that a useful looking edit is safe to apply.

## Case 5 — User gives an AI raw folder access

The AI modifies `works/movie/wk_u_abc12345.md` through an ordinary editor,
outside the Gateway.

Expected result:

- the file remains the user's Vault data; AKASHA never deletes it for being an
  external write;
- watcher/index reconciliation treats it as an external source change;
- it is not marked as an authorized Gateway operation and has no fabricated
  receipt or actor provenance;
- any malformed file is preserved and diagnosed, not silently normalized away.

This preserves user ownership while making the cost of bypassing the Gateway
visible and honest.

## Case 6 — Import is not AI authority

A user imports a Markdown file made by another app, by hand, or by an AI.

Expected result:

- the generic importer can parse/import it under a user-controlled import flow;
- the importer does not claim a Gateway grant, actor identity, derived inputs,
  or user approval it did not receive;
- its provenance is `importTool` only when the importer can truthfully provide
  that fact;
- product UI must not present this as the AI collaboration contract.

