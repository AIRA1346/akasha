# AKASHA SteamPipe commerce-sandbox upload contract.
# Depot 4677561 is corroborated by the successful 2026-07-02 SteamCMD build
# for AppID 4677560. Reconfirm it on Steamworks > SteamPipe > Depots before
# a production/default-branch release.

$SteamAppId = '4677560'
$SteamDepotId = '4677561'
$SteamBranchName = 'commerce-sandbox'

$AkashaRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ReleaseDir = Join-Path $AkashaRoot 'build\windows\x64\runner\Release'
$DepotStageDir = Join-Path $AkashaRoot 'build\steam\depot_windows'
$DepotManifestPath = Join-Path $AkashaRoot 'build\steam\manifests\depot_windows.json'
$AppBuildVdf = Join-Path $PSScriptRoot 'app_build_4677560_commerce_sandbox.vdf'
$DepotBuildVdf = Join-Path $PSScriptRoot 'depot_build_4677561.vdf'

$SteamContentBuilderPathFile = Join-Path $PSScriptRoot 'steam_content_builder.path'
$SteamSdkRoot = $env:AKASHA_STEAM_CONTENT_BUILDER
if ([string]::IsNullOrWhiteSpace($SteamSdkRoot) -and
    (Test-Path -LiteralPath $SteamContentBuilderPathFile)) {
    $SteamSdkRoot = (
        Get-Content -Raw -Encoding UTF8 $SteamContentBuilderPathFile
    ).Trim()
}
if ([string]::IsNullOrWhiteSpace($SteamSdkRoot)) {
    $SteamSdkRoot = $null
    $SteamCmd = $null
} else {
    $SteamSdkRoot = [System.IO.Path]::GetFullPath($SteamSdkRoot)
    $SteamCmd = Join-Path $SteamSdkRoot 'builder\steamcmd.exe'
}
$BuildOutput = Join-Path $AkashaRoot 'build\steam\steamcmd_output'
