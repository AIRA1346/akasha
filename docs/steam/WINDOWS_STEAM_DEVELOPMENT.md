# Windows Steam Development Guide

This guide implements the boundaries in
[`STEAM_RUNTIME_EXECUTION_CONTRACT.md`](STEAM_RUNTIME_EXECUTION_CONTRACT.md).
It does not enable release commerce or alter ItemDefs.

Release/commerce docs: [STEAM_SERVICE_RELEASE_READINESS.md](../active/STEAM_SERVICE_RELEASE_READINESS.md) · [STEAM_RELEASE.md](../active/STEAM_RELEASE.md) · [steam_inventory_production](../active/steam_inventory_production/README.md).

## Local UI development

To build and launch the current worktree while allowing Steam to be absent:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows_steam_dev.ps1 `
  -AllowSteamOffline
```

The script builds Debug, launches
`build\windows\x64\runner\Debug\akasha.exe` with that directory as its current
working directory, and verifies the actual process path. Reuse an existing
Debug build with `-SkipBuild`.

`flutter run -d windows` launches from the repository working directory.
Steamworks officially searches the current working directory for the
development App ID, so an App ID file only beside the Debug executable may not
protect a plain Flutter run from `RestartAppIfNecessary`. That command can
therefore open the Steam-installed build and is not accepted as local runtime
evidence. Use the launcher above for deterministic execution; do not add a
repository-root App ID file by hand.

## Local Steam integration development

Start Steam, sign in with an account that owns App ID `4677560`, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows_steam_dev.ps1
```

For reviewed Inventory Sandbox purchase testing, build and launch the same
Debug path with the internal transaction gates:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows_steam_dev.ps1 `
  -EnableSandboxCommerce
```

The launcher refuses to overwrite a mismatched App ID file and refuses to run
while another AKASHA process exists. It prints the expected and actual EXE,
PID, working directory, and environment. Close AKASHA to complete the command.
For an automated process-path smoke check:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows_steam_dev.ps1 `
  -SkipBuild -ExitAfterValidation
```

After launch, verify in the Commerce diagnostics:

- `appId=4677560`
- `initializationAttempted=true`
- `initialized=true`
- `loggedOn=true`
- `subscribedApp=true`
- `executionEnvironment=localDebug`
- `overlayEnabled=true` after Steam has had time to hook
- `overlayFirstSampleEnabled`, `overlayFirstTrueElapsedMs`, and
  `overlayEnabledTransitionCount`
- `overlayActivatedCallbackCount` and `overlayDeactivatedCallbackCount`
- Inventory authority and expected item definition count

The manual Overlay check uses the shortcut configured in the Steam client. The
default is Shift+Tab, but a user override such as Shift+O is authoritative and
must be recorded with the test evidence. A false initial Overlay value can
become true after injection. AKASHA retries readiness only after 2, 5, 10, 20,
and 30 seconds and stops once enabled or after the final attempt.

## Inspect the currently running executable

Developer-local full-path inspection is allowed:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'akasha.exe'" |
  Select-Object ProcessId, ParentProcessId, ExecutablePath, CommandLine
```

Expected local suffix:

```text
build\windows\x64\runner\Debug\akasha.exe
```

If the path contains `steamapps\common`, stop the process. Steam relaunched the
installed build; it is not the current worktree.

## Steam beta/test branch

Prepare and validate only the staged depot:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_steam_inventory_sandbox.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\steam\prepare_steam_depot.ps1
powershell -ExecutionPolicy Bypass -File .\tool\verify_steam_release_payload.ps1 `
  -PayloadPath .\build\steam\depot_windows -PayloadKind Depot
powershell -ExecutionPolicy Bypass -File .\scripts\steam\validate_steam_pipe_config.ps1
```

Upload remains an explicit operator action through the existing SteamPipe
script. Install the private branch from Steam, launch from the Library, and
test restart behavior, launch options, Overlay, Inventory, prices, callbacks,
updates, uninstall, and reinstall. A directly launched local Release executable
does not replace this check.

The existing internal branch is `commerce-sandbox`. Confirm that it is
password-protected before upload. The depot manifest records `gitSha`; after a
successful upload, `build\steam\upload_receipts` records the branch, Git SHA,
and parsed BuildID. Never use or change the default branch in this workflow.

## Production release

Build and verify Release:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1
powershell -ExecutionPolicy Bypass -File .\tool\verify_steam_release_payload.ps1
```

The raw Release output and staged depot must both be free of
`steam_appid.txt`. Never copy a Debug bundle, repository-root development file,
PDB, log, POC asset, fixture, credential, or machine-local `.path` file into a
depot. Do not set the default branch live until the private-branch runtime and
release checklist pass.

## App ID lifecycle

- Tracked source: `windows\runner\steam_appid.txt`, digits only.
- Debug build: installed beside `akasha.exe`.
- Local launch: CWD is the same Debug directory.
- Existing runtime file: validated, never overwritten blindly.
- Script-created missing runtime file: removed after the app exits.
- Build-owned runtime file: retained as an ignored Debug artifact until clean.
- Profile, Release, depot staging, Steam beta, production: forbidden.

If a local launch exits and Steam opens an older build, confirm the CWD and App
ID file first. Do not remove `SteamAPI_RestartAppIfNecessary`; that relaunch is
the correct production behavior when a user starts the installed EXE outside
Steam.
