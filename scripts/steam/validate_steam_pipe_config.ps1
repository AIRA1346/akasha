# Validate the AKASHA SteamPipe payload and VDF contract without invoking
# SteamCMD or changing any Steamworks state.

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\steam_upload_config.ps1"

if ([string]::IsNullOrWhiteSpace($SteamCmd)) {
    throw @"
Steamworks ContentBuilder 경로가 설정되지 않았습니다.
AKASHA_STEAM_CONTENT_BUILDER 환경 변수 또는 추적되지 않는
scripts\steam\steam_content_builder.path 파일을 사용하세요.
"@
}

function Get-VdfValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $pattern = '"' + [Regex]::Escape($Key) + '"\s+"([^"]+)"'
    $match = [Regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        throw "Missing VDF key: $Key"
    }
    return $match.Groups[1].Value
}

function Resolve-VdfPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VdfPath,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Replace('\\', '\')
    if ([System.IO.Path]::IsPathRooted($normalized)) {
        return [System.IO.Path]::GetFullPath($normalized)
    }
    return [System.IO.Path]::GetFullPath(
        (Join-Path (Split-Path $VdfPath -Parent) $normalized)
    )
}

foreach ($required in @(
    $SteamCmd,
    $AppBuildVdf,
    $DepotBuildVdf,
    $DepotStageDir,
    $DepotManifestPath
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing SteamPipe input: $required"
    }
}

$manifest = Get-Content -Raw -Encoding UTF8 $DepotManifestPath |
    ConvertFrom-Json
$stageFull = [System.IO.Path]::GetFullPath($DepotStageDir)
$manifestStage = [System.IO.Path]::GetFullPath([string]$manifest.stage)

if ([string]$manifest.appId -ne $SteamAppId) {
    throw "Manifest AppID mismatch: $($manifest.appId) != $SteamAppId"
}
if ([string]$manifest.depotId -ne $SteamDepotId) {
    throw "Manifest DepotID mismatch: $($manifest.depotId) != $SteamDepotId"
}
if ($manifestStage -ne $stageFull) {
    throw "Manifest stage mismatch: $manifestStage != $stageFull"
}

$manifestEntries = @{}
foreach ($entry in $manifest.files) {
    $relative = ([string]$entry.path).Replace('\', '/')
    if ($manifestEntries.ContainsKey($relative)) {
        throw "Duplicate manifest path: $relative"
    }
    $manifestEntries[$relative] = $entry
}

$actualFiles = Get-ChildItem -LiteralPath $stageFull -Recurse -File
if ($actualFiles.Count -ne [int]$manifest.fileCount) {
    throw "Stage file count mismatch: $($actualFiles.Count) != $($manifest.fileCount)"
}
if ($manifestEntries.Count -ne [int]$manifest.fileCount) {
    throw "Manifest entry count mismatch: $($manifestEntries.Count) != $($manifest.fileCount)"
}

$relativeStart = $stageFull.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
).Length + 1
foreach ($file in $actualFiles) {
    $relative = $file.FullName.Substring($relativeStart).Replace('\', '/')
    if (-not $manifestEntries.ContainsKey($relative)) {
        throw "Stage file missing from manifest: $relative"
    }
    $entry = $manifestEntries[$relative]
    if ($file.Length -ne [int64]$entry.bytes) {
        throw "Stage size mismatch: $relative"
    }
    $fileHash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    $actualHash = $fileHash.Hash.ToLowerInvariant()
    if ($actualHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
        throw "Stage hash mismatch: $relative"
    }
}

$forbidden = Get-ChildItem -LiteralPath $stageFull -Recurse -File |
    Where-Object {
        $_.Name -ieq 'steam_appid.txt' -or $_.Extension -ieq '.pdb'
    }
if ($forbidden) {
    throw "Forbidden depot file found: $($forbidden.FullName -join ', ')"
}

$appVdfText = Get-Content -Raw -Encoding UTF8 $AppBuildVdf
$depotVdfText = Get-Content -Raw -Encoding UTF8 $DepotBuildVdf

if ((Get-VdfValue $appVdfText 'AppID') -ne $SteamAppId) {
    throw 'App build VDF AppID mismatch.'
}
if ((Get-VdfValue $appVdfText 'Preview') -ne '0') {
    throw 'App build VDF must use Preview 0 for the real upload command.'
}
if ((Get-VdfValue $appVdfText 'SetLive') -ne $SteamBranchName) {
    throw 'App build VDF SetLive branch mismatch.'
}
if ((Get-VdfValue $depotVdfText 'DepotID') -ne $SteamDepotId) {
    throw 'Depot build VDF DepotID mismatch.'
}
if ((Get-VdfValue $depotVdfText 'LocalPath') -ne '*') {
    throw 'Depot build VDF must map the entire staged ContentRoot.'
}
if ((Get-VdfValue $depotVdfText 'DepotPath') -ne '.') {
    throw 'Depot build VDF must map files to the depot root.'
}
if ((Get-VdfValue $depotVdfText 'Recursive') -ne '1') {
    throw 'Depot build VDF must include staged subdirectories recursively.'
}

$appContentRoot = Resolve-VdfPath $AppBuildVdf (
    Get-VdfValue $appVdfText 'ContentRoot'
)
$depotContentRoot = Resolve-VdfPath $DepotBuildVdf (
    Get-VdfValue $depotVdfText 'ContentRoot'
)
if ($appContentRoot -ne $stageFull) {
    throw "App VDF ContentRoot mismatch: $appContentRoot != $stageFull"
}
if ($depotContentRoot -ne $stageFull) {
    throw "Depot VDF ContentRoot mismatch: $depotContentRoot != $stageFull"
}

$buildOutputFromVdf = Resolve-VdfPath $AppBuildVdf (
    Get-VdfValue $appVdfText 'BuildOutput'
)
if ($buildOutputFromVdf -ne [System.IO.Path]::GetFullPath($BuildOutput)) {
    throw 'App build VDF BuildOutput mismatch.'
}

$depotReferencePattern =
    '"' + [Regex]::Escape($SteamDepotId) + '"\s+"' +
    [Regex]::Escape((Split-Path $DepotBuildVdf -Leaf)) + '"'
if (-not [Regex]::IsMatch($appVdfText, $depotReferencePattern)) {
    throw 'App build VDF does not reference the expected depot VDF.'
}
if ($depotVdfText -notmatch '"FileExclusion"\s+"\*\.pdb"') {
    throw 'Depot VDF is missing the PDB exclusion.'
}
if ($depotVdfText -notmatch '"FileExclusion"\s+"steam_appid\.txt"') {
    throw 'Depot VDF is missing the steam_appid.txt exclusion.'
}

$command =
    '& "' + $SteamCmd + '" +login <STEAM_BUILD_ACCOUNT> ' +
    '+run_app_build "' + $AppBuildVdf + '" +quit'

Write-Host ''
Write-Host 'SteamPipe local configuration validation passed.'
Write-Host "  AppID:       $SteamAppId"
Write-Host "  DepotID:     $SteamDepotId"
Write-Host "  Branch:      $SteamBranchName"
Write-Host "  App VDF:     $AppBuildVdf"
Write-Host "  Depot VDF:   $DepotBuildVdf"
Write-Host "  ContentRoot: $stageFull"
Write-Host "  Files:       $($actualFiles.Count)"
Write-Host '  Exclusions:  steam_appid.txt, *.pdb'
Write-Host ''
Write-Host 'SteamCMD upload command (NOT executed):'
Write-Host $command
Write-Host ''
Write-Host "Remote check still required: create a password-protected '$SteamBranchName' branch in Steamworks before upload."
