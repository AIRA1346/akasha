# Local Agent Command Protocol v1

> **Status:** Implemented local CLI entry for bounded Record lookup/read and
> `candidate propose`.
> **Scope:** A command-capable AI or external tool can discover one exact
> title/alias, read one bounded Markdown Record with its exact revision, then
> submit exactly one non-canonical candidate through AKASHA's Gateway. This is
> not an AI service, MCP server, generic Vault shell, or canonical Record-write
> API.

## 1. What the command does

```text
user asks a local agent to archive something
  -> agent invokes `akasha record lookup` for one exact title/alias
  -> agent invokes `akasha record read` for one stable Record id
  -> response contains the exact Markdown bytes as text + their revision
  -> agent invokes `akasha candidate propose` with that revision
  -> Gateway validates the candidate and writes it recoverably
  -> candidate appears in AKASHA's existing review surface
```

The command deliberately has only three verbs:

| Verb | Effect | Does not do |
| --- | --- | --- |
| `record lookup` | Returns at most 20 exact title/alias matches and stable IDs. | Full-text search, Vault-wide scans, raw file paths, or writes. |
| `record read` | Returns one indexed Markdown Record, its stable ID, and the revision of the returned bytes. | Arbitrary-path reads, partial/truncated content, or writes. |
| `candidate propose` | Creates one reviewable, non-canonical candidate. | Promotion, Markdown edits, canonical Record creation, relationships, lifecycle changes, or deletion. |

When the candidate review tab is already open, it watches only
`system/candidates` changes and reloads the proposal list automatically. Manual
refresh remains only a filesystem-watch fallback.

## 2. Invocation and transport

The AKASHA desktop executable owns command mode:

```powershell
akasha.exe record lookup --vault "C:\Path\To\Vault" --request "C:\Temp\lookup.json" --result "C:\Temp\lookup-result.json"
akasha.exe record read --vault "C:\Path\To\Vault" --request "C:\Temp\read.json" --result "C:\Temp\read-result.json"
akasha.exe candidate propose --vault "C:\Path\To\Vault" --request "C:\Temp\candidate.json" --result "C:\Temp\candidate-result.json"
```

Each request is one JSON object in the explicit `--request` file. Each result
is one JSON object at a new `--result` path; AKASHA never overwrites an existing
result file. Request/result files are temporary protocol data outside the Vault.
This avoids depending on Windows GUI-process stdin/stdout behavior. Exit code
`0` means success, `2` means a valid request was rejected without an archive
write, and `64` means command or JSON usage is invalid.

### 2.1 Exact title/alias lookup

```json
{
  "name": "Cyber Action",
  "limit": 5,
  "entityType": "work"
}
```

`entityType` and `recordKind` are optional filters. Lookup is an exact
normalized title/alias lookup, not a broad keyword search. A successful result
contains only logical match information, never a physical Vault path:

```json
{
  "ok": true,
  "matches": [
    {
      "recordId": "rec_wk_u_abc123",
      "targetId": "wk_u_abc123",
      "recordKind": "workJournal",
      "entityType": "work",
      "title": "Cyber Action",
      "matchedFields": ["title", "alias"]
    }
  ]
}
```

`recordId` is the physical v3 `record_id` of the matched Markdown Document.
`targetId` is optional context for the Entity or Work discovered by its title;
it is not interchangeable with `recordId` and cannot be used as a provenance
source or a `record read` input. A matching legacy document without a physical
`record_id` returns `record_id_required` rather than inventing one.

### 2.2 One stable-id Record read

```json
{
  "recordId": "rec_wk_u_abc123",
  "maxBytes": 262144
}
```

`maxBytes` defaults to 256 KiB and cannot exceed 1 MiB. AKASHA returns either
the complete Record or `record_too_large`; it never silently truncates a source
and labels it as a complete read.

```json
{
  "ok": true,
  "record": {
    "recordId": "rec_wk_u_abc123",
    "targetId": "wk_u_abc123",
    "recordKind": "workJournal",
    "entityType": "work",
    "title": "Cyber Action",
    "revision": "v2:sha256:...;bytes:1234",
    "byteLength": 1234,
    "markdown": "---\n..."
  }
}
```

The read endpoint uses derived `.akasha/title_alias_index/` and
`.akasha/record_path_index/` data. If either is unavailable, stale, or the
stable ID is duplicated, it returns an explicit error and does **not** start a
Vault-wide Markdown scan or choose an arbitrary file. These indexes are
rebuildable; Markdown stays canonical.

### 2.3 Candidate proposal

```json
{
  "operationId": "gwc_codex_20260712_001",
  "actorBindingId": "codex_local",
  "actorLabel": "Codex local task",
  "sourceRecordId": "rec_wk_u_abc123",
  "expectedSourceRevision": "v2:sha256:...;bytes:1234",
  "candidate": {
    "candidateId": "cand_person_001",
    "entityType": "person",
    "title": "Example person",
    "evidence": "The source explicitly identifies this person.",
    "confidence": 0.82,
    "aliases": ["Example"],
    "tags": ["extracted"],
    "source": "agent"
  }
}
```

`operationId` and `candidateId` must remain the same when retrying the same
proposal. The Gateway turns the command invocation into a short-lived,
source-bounded user-initiated candidate session whose authority ID is derived
deterministically from `operationId`; this preserves idempotency across a retry
or an interruption before its receipt append.

`sourceRecordId` must be the physical `recordId` returned by `record lookup`
or `record read`, never its `targetId`. This lets several independently
archived Records about the same Entity remain distinct sources.

## 3. Revision and conflict rule

The `record read` response's revision belongs to the **exact bytes returned**.
The agent echoes it as `expectedSourceRevision` in `candidate propose`.
AKASHA recomputes the current revision immediately before persistence. If the
source changed, it returns `source_revision_conflict` and writes no candidate
or applied receipt.

An agent can still read files directly when the user grants ordinary filesystem
access. That is an external-editor compatibility path, not a Gateway read or
write, and AKASHA does not pretend it has the same provenance guarantees.

## 4. Authority, privacy, and provenance

The command represents an explicit local task started by the user. `record`
verbs neither mutate Vault state nor create a receipt. `candidate propose`
records the supplied local actor descriptor, source Record ID, observed
revision, operation ID, candidate ID, and Gateway authority route.

This is a deliberately bounded integration interface, not proof of the
real-world identity of a model, provider, agent, or human. A process with
ordinary local filesystem authority can still edit Markdown directly; those
edits remain external and never receive a Gateway receipt.

For background or repeated automation, the command-session path is not enough.
That future mode requires separately configured, revocable durable grants and
its own limits.

## 5. Input preservation rule

Every verb accepts only its documented fields. Unknown request fields are
rejected rather than silently discarded. Gateway-owned candidate fields
(`sourceOperationId`, timestamps, actor/provenance fields, status, authority,
and source revision) are assigned by AKASHA only.

The implementation is in
[`archive_gateway_record_read_command.dart`](../../lib/services/archive_gateway_record_read_command.dart),
[`archive_gateway_candidate_command.dart`](../../lib/services/archive_gateway_candidate_command.dart),
and the desktop entry
[`akasha_command_runner.dart`](../../lib/services/akasha_command_runner.dart).
