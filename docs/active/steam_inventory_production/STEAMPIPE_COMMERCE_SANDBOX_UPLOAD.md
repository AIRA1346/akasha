# SteamPipe Commerce Sandbox Upload

> **Status:** upload configuration prepared and locally validated
>
> **Upload executed by this task:** no
>
> **AppID:** `4677560`
>
> **Windows DepotID:** `4677561`
>
> **Private branch:** `commerce-sandbox`

## What `depot_windows.json` is

`build/steam/manifests/depot_windows.json` is an AKASHA internal verification
manifest. It records the staged file paths, byte sizes, and SHA-256 hashes.
SteamCMD does not read this JSON and it cannot upload a depot by itself.

SteamCMD reads these VDF scripts:

- `scripts/steam/app_build_4677560_commerce_sandbox.vdf`
- `scripts/steam/depot_build_4677561.vdf`

The Windows DepotID is corroborated by the successful 2026-07-02 SteamCMD
build log: AppID `4677560` built DepotID `4677561` and completed as BuildID
`24015480`. Reconfirm the depot on the Steamworks Depots page before a
production/default-branch release.

## Locked local contract

| Setting | Value |
|---|---|
| App build | `scripts/steam/app_build_4677560_commerce_sandbox.vdf` |
| Depot build | `scripts/steam/depot_build_4677561.vdf` |
| ContentRoot | `build/steam/depot_windows` |
| Current staged files | `97` |
| Exclusions | `steam_appid.txt`, `*.pdb` |
| Upload mode | `Preview 0` |
| SetLive branch | `commerce-sandbox` |
| Build output/cache | `C:\dev\steamworks\steamworks_sdk_164\sdk\tools\ContentBuilder\output` |

Both VDF files resolve `ContentRoot` relative to their location under
`scripts/steam`. The resolved absolute path is:

```text
C:\Users\rkdwl\RuneAtelier\akasha\build\steam\depot_windows
```

The files below are stale SDK-output artifacts and must not be used:

```text
C:\dev\steamworks\steamworks_sdk_164\sdk\tools\ContentBuilder\output\_akasha_app_build.vdf
C:\dev\steamworks\steamworks_sdk_164\sdk\tools\ContentBuilder\output\_akasha_depot_build.vdf
```

They point to the raw Flutter Release directory rather than the verified
Steam staging directory.

## Required Steamworks setup

Before upload, open App Admin for AppID `4677560`:

1. Confirm the Windows depot is `4677561`.
2. Create an app branch named exactly `commerce-sandbox`.
3. Give the branch a password and distribute it only to internal testers.
4. Confirm the build account has **Edit App Metadata** and
   **Publish App Changes To Steam** permissions.

`SetLive "commerce-sandbox"` makes a successful upload live on that beta
branch. It does not publish to the default branch.

## Local preflight only

This command validates the existing 97-file stage, every recorded SHA-256,
the VDF IDs and paths, and the two exclusion rules. It does not invoke
SteamCMD.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\steam\validate_steam_pipe_config.ps1
```

If the Release output changed, rebuild the stage first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\steam\prepare_steam_depot.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\steam\validate_steam_pipe_config.ps1
```

## Exact SteamCMD upload command

Do not store the account password or Steam Guard code in the repository.
Replace only the account value, then let SteamCMD use its interactive or
cached authentication flow.

```powershell
$SteamBuildAccount = 'YOUR_STEAM_BUILD_ACCOUNT'
& 'C:\dev\steamworks\steamworks_sdk_164\sdk\tools\ContentBuilder\builder\steamcmd.exe' `
  +login $SteamBuildAccount `
  +run_app_build 'C:\Users\rkdwl\RuneAtelier\akasha\scripts\steam\app_build_4677560_commerce_sandbox.vdf' `
  +quit
```

The repository wrapper performs staging and validation before invoking the
same AppBuild VDF:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\steam\upload_steam_build.ps1 `
  -SteamUsername 'YOUR_STEAM_BUILD_ACCOUNT'
```

After a future upload, verify the new BuildID in Steamworks, confirm it is live
only on `commerce-sandbox`, install that branch from the Steam client, and
launch the installed build from the Steam library.

## Valve references

- [Uploading to Steam](https://partner.steamgames.com/doc/sdk/uploading)
- [Branches (Betas)](https://partner.steamgames.com/doc/store/application/branches)
