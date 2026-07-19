# Steam Release Evidence (canonical archive)

> **Role:** Permanent archive for SteamPipe **upload receipts** and **pre-upload seals**.
> This directory stores original evidence bytes. It does **not** replace the
> Acceptance Matrix, and presence here does **not** mean Commerce Go or Overall Go.

## Purpose

- Keep Steam upload receipts and pre-upload seal artifacts in a trackable repo path.
- Preserve evidence files as **original bytes** (no regenerate / rewrite).
- **Binary depot stage** (`depot_windows` payload) is **not** a long-term canonical
  archive. Identity is sealed by exe SHA-256 + pre-upload manifest SHA-256 + receipt.

## Boundaries

| Claim | Status |
|---|---|
| Evidence archive present | Yes (this tree) |
| CURRENT-RC transaction acceptance | Incomplete |
| Commerce Go | **No-Go** |
| Overall Release Go | **No-Go** |
| Default branch Set Live | **Operator-confirmed** (receipt proves upload branch only) |

## Layout

```text
AKASHA_Product/release-evidence/steam/
├─ README.md                          (this index)
├─ build-24282729/                    (current live identity)
│  ├─ upload_receipts/
│  │  └─ 20260719T115647Z.json
│  └─ seal_pre_upload_5e95fefe/
│     ├─ seal.txt
│     └─ depot_windows.json           (pre-upload seal manifest)
└─ history/
   └─ build-24279586/                 (historical predecessor)
      └─ upload_receipts/
         └─ 20260719T024734Z.json
```

## BuildID 24282729 (current live)

| Field | Value |
|---|---|
| Git SHA | `5e95fefeace1f7658f7b9da7597f12fce4777593` |
| Upload branch (receipt) | `commerce-sandbox` |
| Default Set Live | **Operator-confirmed** — receipt does **not** prove the default-branch switch |
| EXE SHA-256 | `3C387A2166A965EACE5F3C555D7088721117BBA3D66BBD07ADF1508D72066069` |
| Canonical pre-upload manifest SHA-256 | `C92B7E33018B61046ED512EF7DF57CAED87F4AAED4D1D24DB9BADA939831DF85` |
| Staged files / bytes | `1756` / `70978364` |

### Archived files

| File | Relative path | File SHA-256 |
|---|---|---|
| Upload receipt | [build-24282729/upload_receipts/20260719T115647Z.json](build-24282729/upload_receipts/20260719T115647Z.json) | `88FA7975C23AF3C5188D11A44C17F761AD245FF174610AC1B11BA3FA6E659529` |
| Seal summary | [build-24282729/seal_pre_upload_5e95fefe/seal.txt](build-24282729/seal_pre_upload_5e95fefe/seal.txt) | `4C3A949AC7B9BA32EE4165E255E2F75B5E7EDB61CC5F47C2290BF1BB81C8C91E` |
| Seal manifest | [build-24282729/seal_pre_upload_5e95fefe/depot_windows.json](build-24282729/seal_pre_upload_5e95fefe/depot_windows.json) | `C92B7E33018B61046ED512EF7DF57CAED87F4AAED4D1D24DB9BADA939831DF85` |

Source class: **prod-commerce worktree** (byte-identical copy; REL-EVID-01).

`seal.txt` `manifestSha256` equals the seal `depot_windows.json` file SHA-256.
Post-upload `build/steam/manifests/depot_windows.json` variants are **not** archived here.

## BuildID 24279586 (historical)

| Field | Value |
|---|---|
| Git SHA | `c18826b96df8b92d7572b4024f4f6c8a184aa7b9` |
| Role | Historical predecessor upload — **not** current live acceptance evidence |
| Upload branch (receipt) | `commerce-sandbox` |

### Archived files

| File | Relative path | File SHA-256 |
|---|---|---|
| Upload receipt | [history/build-24279586/upload_receipts/20260719T024734Z.json](history/build-24279586/upload_receipts/20260719T024734Z.json) | `6AF3BB2EFE689EC37BFFE766681569C726AE891130B602CC1EB5057C33A076E4` |

Source class: **historical sandbox worktree** (byte-identical copy; REL-EVID-01).

## Explicitly excluded

- Full depot binary stage (`exe` / DLL / staged tree)
- SteamCMD output logs
- Absolute-path local VDF overrides
- Generated Flutter plugin noise
- Credentials / account secrets

## Related Active docs

- [STEAM_RELEASE.md](../../../docs/active/STEAM_RELEASE.md) — release ops / live identity
- [STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](../../../docs/active/STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md) — acceptance ledger
- [CURRENT_STATE.md](../../../docs/active/CURRENT_STATE.md) — implementation reality
