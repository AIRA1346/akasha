# Local Agent Command Protocol — Candidate Intake v1

> **Status:** Implemented local CLI entry for `candidate propose`.
> **Scope:** A command-capable AI or external tool can submit exactly one
> non-canonical candidate through AKASHA's Gateway. This is not an AI service,
> MCP server, generic Vault shell, or canonical Record-write API.

## 1. What the command does

The local command is the first concrete external write entrance:

```text
user asks an agent to archive a proposal
  -> agent invokes `akasha candidate propose`
  -> Gateway validates actor, one source Record, observed revision, and body
  -> recoverable candidate write + durable applied receipt
  -> candidate appears in AKASHA's existing candidate review surface
```

When the candidate review tab is already open, it watches only
`system/candidates` changes and reloads the proposal list automatically. Manual
refresh remains a fallback for filesystems that cannot provide directory-watch
events.

The command can create a candidate only. It cannot promote, dismiss, merge,
edit Markdown, create a Record, derive an interpretation, assert a
relationship, transition lifecycle state, or delete anything.

## 2. Invocation

The AKASHA desktop executable itself owns the command mode:

```powershell
akasha.exe candidate propose --vault "C:\Path\To\Vault" --request "C:\Temp\candidate.json" --result "C:\Temp\candidate-result.json"
```

The release/Steam wrapper must expose this executable to a user-chosen local
agent environment. The request is one JSON object in the explicit `--request`
file. This avoids depending on Windows GUI-process pipe behavior. The command
writes one JSON response to the explicit `--result` path and never overwrites
an existing result file. Both request and result paths are temporary protocol
files outside the Vault; the exit code is also a reliable success/failure
signal.

```json
{
  "operationId": "gwc_codex_20260712_001",
  "actorBindingId": "codex_local",
  "actorLabel": "Codex local task",
  "sourceRecordId": "rec_source_001",
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
deterministically from `operationId`; this preserves idempotency across a
command retry or an interruption before its receipt append.

The response includes `ok`, `applied`, `alreadyApplied`, candidate/receipt IDs,
and an explicit error code when no write occurred.

## 3. Source revision rule

The agent must supply the revision of the **exact source bytes it actually
read**. Its form is `v2:sha256:<digest>;bytes:<length>`. AKASHA recomputes that
revision immediately before persistence. If the source changed, the command
returns `source_revision_conflict` and writes no candidate or applied receipt.

The first command protocol intentionally has no broad Record-read command.
The Vault remains user-owned and an agent may read source files only through a
user-chosen read path. A later scoped read/query surface must return bounded
content and its revision together, rather than encouraging whole-Vault scans.

## 4. Authority and provenance

The local command represents an explicit agent invocation made within the
user's task. It records a supplied local actor descriptor, source Record ID,
observed revision, operation ID, candidate ID, and the Gateway authority route.

It does **not** prove the real-world identity of the agent, model, provider, or
human who launched the process. AKASHA is an archival substrate, not an agent
monitor or identity service. A process with normal local filesystem authority
can still edit Markdown directly; such edits remain external edits and never
receive a Gateway receipt.

For background or repeated automation, this command-session path is not
sufficient. That later mode requires a separately configured revocable durable
grant and its own limits.

## 5. Input preservation rule

The v1 command accepts only its documented fields. Unknown request or candidate
fields are rejected rather than silently discarded. Gateway-owned fields
(`sourceOperationId`, timestamps, actor/provenance fields, status, authority,
and source revision) are assigned by AKASHA only.

This protocol is implemented by
[`archive_gateway_candidate_command.dart`](../../lib/services/archive_gateway_candidate_command.dart)
and the desktop command entry
[`akasha_command_runner.dart`](../../lib/services/akasha_command_runner.dart).
