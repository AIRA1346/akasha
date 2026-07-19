# Steam Runtime and Execution Environment Contract

> Status: SR-1 Windows contract
>
> App ID: `4677560`
>
> Scope: process launch, Steam initialization, development identity files,
> diagnostics, and release payload boundaries. Commerce products, ItemDefs,
> prices, and transaction semantics are out of scope.
>
> Related (release/commerce, not this file): [STEAM_SERVICE_RELEASE_READINESS.md](../active/STEAM_SERVICE_RELEASE_READINESS.md) · [STEAM_RELEASE.md](../active/STEAM_RELEASE.md) · [steam_inventory_production](../active/steam_inventory_production/README.md) · [Windows Steam Development](WINDOWS_STEAM_DEVELOPMENT.md)

## Official Steamworks findings

This contract is based on Valve's official documentation:

- [Steamworks API Overview](https://partner.steamgames.com/doc/sdk/api)
- [Steam Overlay](https://partner.steamgames.com/doc/features/overlay)
- [Uploading to Steam](https://partner.steamgames.com/doc/sdk/uploading)

`SteamAPI_RestartAppIfNecessary(appId)` checks whether the process was launched
through Steam. If it returns `true`, it starts Steam if needed, requests
`steam://run/<AppID>`, and the caller must exit promptly. Valve explicitly notes
that the relaunched executable may be the Steam-library installation rather
than the executable that made the call.

The function is optional but recommended for release and must be the first
Steamworks call, before `SteamAPI_Init`. If `steam_appid.txt` is present for a
development run, `RestartAppIfNecessary` returns `false`. `SteamAPI_Init`
requires a running Steam client, the same OS user/elevation context, a valid
license/package, and a known App ID. Valve documents the development file next
to the executable and also notes that direct/debug launches search the current
working directory, so AKASHA launches with both locations equal.

`steam_appid.txt` contains only the App ID. It is a development override and
must not be uploaded to a Steam depot. Steam supplies the App ID to a real
Steam-launched build.

During debugger-based development the Overlay is loaded when `SteamAPI_Init`
runs. It must run before Direct3D/OpenGL device initialization. For an installed
test, launch through the Steam client and confirm Shift+Tab plus
`ISteamUtils::IsOverlayEnabled()`; a local direct launch is not release-path
evidence.

## Environment contract

| Environment | Trusted launcher and executable | App ID source | Required evidence |
|---|---|---|---|
| Local UI Development | `tool/run_windows_steam_dev.ps1 -AllowSteamOffline`; worktree `Debug\akasha.exe` | Debug-only `steam_appid.txt`; Steam may be absent | Actual process path is the worktree Debug executable; a Steam install process is failure |
| Local Steam Integration Development | `tool/run_windows_steam_dev.ps1`; worktree `Debug\akasha.exe` | Debug-only `steam_appid.txt`, with CWD equal to the Debug directory | Steam client detected, exact process path, API/Overlay/Inventory diagnostics |
| Steam Beta/Test Branch | Steam client installation from a private branch | Steam launch context; no App ID file | Installed path, restart behavior, launch options, Overlay, Inventory, update/install lifecycle |
| Steam Production Release | Steam default branch | Steam launch context; no override file or bypass | Clean verified depot, installed path, published configuration, production smoke evidence |

`local_debug`, `local_profile`, `local_release`, `steam_install`, and `unknown`
are diagnostic classifications. `local_release` is a build output, not proof of
a Steam release. Only a Steam-installed beta/default build is release-path
evidence.

## Allowed and forbidden files

| Location | `steam_api64.dll` | `steam_appid.txt` | PDB/debug artifacts |
|---|---:|---:|---:|
| Worktree Debug bundle | required | allowed, exactly `4677560` | allowed |
| Worktree Profile/Release bundle | required | forbidden | forbidden in a release candidate |
| `build/steam/depot_windows` | required | forbidden | forbidden |
| Steam-installed beta/default build | required | forbidden | forbidden |

The tracked source file is `windows/runner/steam_appid.txt`. CMake installs it
only for Debug. The local launcher validates an existing runtime copy and never
overwrites a mismatched file. If the launcher must create a missing copy, it
records ownership and removes it only after the launched process exits. A file
created by the Debug build is a normal ignored build artifact and is removed by
`flutter clean`.

`tool/verify_steam_release_payload.ps1` rejects development App ID files
case-insensitively, debug symbols/build intermediates, debug-only DLL names,
logs, machine path configuration, POC/test fixtures, temporary ItemDefs,
credential-like files, and text configuration containing personal home paths.
The existing staged-depot manifest, hashes, VDF exclusions, and SteamPipe upload
flow remain authoritative and unchanged.

## Bootstrap policy

`windows/runner/steam_runtime.cpp` keeps the release behavior:

1. call `SteamAPI_RestartAppIfNecessary` before Flutter/D3D;
2. exit when Steam requests a relaunch;
3. otherwise call `SteamAPI_Init`;
4. continue without Steam when initialization fails;
5. keep the existing Overlay callback pump and Inventory initialization order.

SR-1 does not add a Debug-wide bypass or modify this C++ flow. The official
development file and a launcher-controlled working directory solve the local
execution problem without weakening Steam beta or production behavior.

## Diagnostics and privacy

The native bridge already reports executable path, working directory, build
mode, initialization attempt/result, restart request, App ID, Overlay state,
callback counters, and Inventory capability. Dart retains those fields and the
copyable support report adds an execution classification.

Full paths may appear in local developer console output. Copyable support text
uses `<repo>`, `<steam-library>`, `<user-profile>`, or `<redacted>` markers and
must not expose a user name, Steam ID, persona, authentication token, or full
personal path. Runtime build identity contains only public package metadata,
Steam BuildID, Git commit, build mode, and the sanitized execution
classification.

Overlay readiness is sampled at most once per second after Steam initializes.
Diagnostics retain process uptime, the first Overlay value, first true time,
enabled transitions, and `GameOverlayActivated_t` active/inactive callback
counts. The app performs only the finite readiness refresh schedule documented
in the development guide; it does not poll per frame or indefinitely. Depot
manifests record the exact Git SHA, and successful upload tooling writes an
ignored local receipt that pairs that SHA with the Steam BuildID when SteamCMD
prints it.

## Runtime build identity

The identifiers shown in the bottom dock and Preferences > App information have
separate sources of truth:

| Identifier | Source of truth | Runtime path |
|---|---|---|
| App version | `pubspec.yaml` `version` name | `package_info_plus`, loaded once at startup |
| App build number | `pubspec.yaml` `version` suffix | `package_info_plus`, loaded once at startup |
| Steam BuildID | SteamPipe publication assigned by Steam | guarded `SteamApps()->GetAppBuildId()` after successful Steam initialization |
| Git SHA | source commit used by the Windows build | CMake build-time `git rev-parse HEAD`, injected as `AKASHA_GIT_COMMIT` |

The running app never invokes Git and never calls a Steam Web API. CMake tracks
Git `HEAD` and its current ref as configure dependencies so an incremental build
does not silently retain an older commit. A missing Steam runtime is a normal
local fallback, and a missing/zero BuildID is displayed as unavailable rather
than `Steam 0`. Build identity lookup cannot change Commerce or Inventory
authority, callback pumping, purchase recovery, or restart behavior.

The compact dock may show only app version/build or omit identity when space is
tight. Preferences always retains the complete field list and a copy action.
The copied value never includes user name, Steam ID, persona, credentials, or
installation paths.

## Failure response

- `steam_appid.txt` missing or mismatched in local integration development:
  stop before launch and report the exact file.
- Steam client absent: fail integration launch, or continue only when
  `-AllowSteamOffline` was explicitly selected for UI work.
- Launched process is not the expected worktree Debug executable: stop it and
  fail; do not accept a Steam-installed process as local evidence.
- Release/depot payload violation: fail with category and exact file path.
- Steam beta/default launch lacks Overlay or Inventory: retain diagnostics and
  investigate Steam configuration/account/package state; do not add a release
  bypass.
