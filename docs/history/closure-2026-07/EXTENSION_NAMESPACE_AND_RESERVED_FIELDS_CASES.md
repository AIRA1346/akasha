# Extension Namespace and Reserved-Field Cases

> **Status:** Semantic regression fixtures for
> [EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md](../../active/EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md).
> They are not parser fixtures, serializer tests, migration instructions, or
> authorization payloads.

## Case 1 — A normal existing Record has no extension root

```yaml
schema_version: 3
record_id: "rec_wk_u_abc12345"
title: "A work"
source: "user"
```

Required result:

- the Record remains valid and fully usable;
- absence of `x_akasha` does not imply not-derived, not-retracted, or trusted;
- a later approved feature may add a valid extension root additively;
- no migration or empty map is written merely by opening/saving the Record.

## Case 2 — An external tool's YAML remains external

```yaml
x_external:
  source: "future tool"
  values: [1, 2, 3]
```

Required result:

- normal AKASHA saves preserve the key, nested values, and meaning;
- AKASHA never moves this content under `x_akasha` or treats it as app-owned;
- the external tool remains responsible for its own field contract.

## Case 3 — A valid AKASHA root preserves unknown siblings

```yaml
x_akasha:
  extension_schema_version: 1
  provenance:
    future_field: "preserve me"
  foreign_future_child:
    enabled: true
```

A future provenance writer changes only a documented provenance field.

Required result:

- the writer patches only `x_akasha.provenance`;
- `foreign_future_child` is untouched;
- unknown data is not dropped because an older app does not understand it;
- if safe source patching cannot be proved, the original remains and the
  proposed content is quarantined under P0.

## Case 4 — A user already owns `x_akasha`

```yaml
x_akasha: "my private notes"
```

An AKASHA feature later wants to write provenance.

Required result:

- the feature rejects the reserved-root collision instead of replacing the
  scalar with a map;
- base Record reading still works where the surrounding YAML is valid;
- the original and proposed contents remain recoverable for a user-directed
  repair or migration;
- no automatic rename or silent data loss occurs.

## Case 5 — A future extension version is read safely

```yaml
x_akasha:
  extension_schema_version: 7
  provenance:
    future_shape: true
```

An older AKASHA build edits only the Record title.

Required result:

- it may save only if it can leave the complete `x_akasha` source segment
  untouched;
- it never attempts to reinterpret or rewrite version 7 as version 1;
- an operation that needs to write provenance/lifecycle is rejected with
  recoverable proposed content rather than downgraded.

## Case 6 — Provenance never appears as a surprise top-level field

A future derived-record writer needs input revisions and actor metadata.

Required result:

- it uses the documented `x_akasha.provenance` child after its implementation
  contract is complete;
- it does not add ad hoc root keys such as `derived_from`, `actor`, or
  `input_revision`;
- existing `source`, `evidence`, and `source_operation_id` keep their narrow
  established meanings.

## Case 7 — Lifecycle does not hide inside a link or Candidate

A user retracts a future Relationship Assertion.

Required result:

- its lifecycle meaning eventually belongs in the documented lifecycle
  extension/transition representation;
- the application does not mutate `links[]`, Canvas layout, or a Candidate's
  `dismissed` status to simulate retraction;
- the original relation evidence and separate transition remain distinguishable.

## Case 8 — Operation receipts remain system data

An authorized future Gateway operation creates a derived Record.

Required result:

- the Record carries its portable provenance core through `x_akasha` once
  implemented;
- `system/ops/` contains the operation receipt/idempotency evidence;
- deleting a rebuildable `.akasha/` index does not erase either meaning;
- neither store is substituted for the other.

## Case 9 — Malformed YAML is never normalized into an extension

```yaml
x_akasha:
  extension_schema_version: [broken
```

Required result:

- AKASHA does not repair or replace it silently while saving unrelated fields;
- P0 preserves the source and proposed content in quarantine/recovery when a
  safe patch is impossible;
- the user chooses how to repair the original data.

## Case 10 — `u:` relation vocabulary is unrelated to YAML ownership

A structured link uses `relation: "u:rival_of"` and the Record also contains
`x_vendor:` metadata.

Required result:

- `u:rival_of` remains a user-defined relation token;
- it grants no ownership of `x_vendor`, `x_akasha`, or any other YAML key;
- relationship assertion promotion still requires the separate relation,
  provenance, lifecycle, and future Gateway contracts.
