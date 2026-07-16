# Prepare and verify the Windows Steam depot payload.
#
# The raw Flutter Release directory intentionally contains steam_appid.txt for
# local development. Steam's depot must be staged separately so that file can
# never be shipped.

param(
    [string]$SourceDir,
    [string]$DestinationDir,
    [string]$ManifestPath
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\steam_upload_config.ps1"

if ([string]::IsNullOrWhiteSpace($SourceDir)) {
    $SourceDir = $ReleaseDir
}
if ([string]::IsNullOrWhiteSpace($DestinationDir)) {
    $DestinationDir = $DepotStageDir
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = $DepotManifestPath
}

$sourceFull = [System.IO.Path]::GetFullPath($SourceDir)
$destinationFull = [System.IO.Path]::GetFullPath($DestinationDir)
$allowedStageRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $AkashaRoot 'build\steam')
)
$allowedPrefix = $allowedStageRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $destinationFull.StartsWith(
    $allowedPrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Depot stage must stay under $allowedStageRoot. Actual: $destinationFull"
}
if ($sourceFull -eq $destinationFull) {
    throw 'Release source and depot stage must be different directories.'
}

$requiredSource = @(
    (Join-Path $sourceFull 'akasha.exe'),
    (Join-Path $sourceFull 'steam_api64.dll'),
    (Join-Path $sourceFull 'data')
)
foreach ($required in $requiredSource) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing release payload: $required"
    }
}

if (Test-Path -LiteralPath $destinationFull) {
    Remove-Item -LiteralPath $destinationFull -Recurse -Force
}
New-Item -ItemType Directory -Path $destinationFull -Force | Out-Null

& robocopy $sourceFull $destinationFull /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 `
    /XF steam_appid.txt *.pdb | Out-Host
$robocopyExit = $LASTEXITCODE
if ($robocopyExit -ge 8) {
    throw "robocopy failed with exit code $robocopyExit"
}

$forbidden = Get-ChildItem -LiteralPath $destinationFull -Recurse -File |
    Where-Object {
        $_.Name -ieq 'steam_appid.txt' -or $_.Extension -ieq '.pdb'
    }
if ($forbidden) {
    $paths = ($forbidden.FullName -join [Environment]::NewLine)
    throw "Forbidden files entered the depot stage:$([Environment]::NewLine)$paths"
}

$requiredStage = @(
    (Join-Path $destinationFull 'akasha.exe'),
    (Join-Path $destinationFull 'steam_api64.dll'),
    (Join-Path $destinationFull 'data\flutter_assets')
)
foreach ($required in $requiredStage) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Incomplete depot stage: $required"
    }
}

$files = Get-ChildItem -LiteralPath $destinationFull -Recurse -File |
    Sort-Object FullName
$relativeStart = $destinationFull.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
).Length + 1
$entries = foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($relativeStart).Replace('\', '/')
    $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    [ordered]@{
        path = $relativePath
        bytes = $file.Length
        sha256 = $hash.Hash.ToLowerInvariant()
    }
}

$manifestFull = [System.IO.Path]::GetFullPath($ManifestPath)
$manifestDirectory = Split-Path $manifestFull -Parent
New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
[ordered]@{
    appId = $SteamAppId
    depotId = $SteamDepotId
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    source = $sourceFull
    stage = $destinationFull
    fileCount = $files.Count
    files = $entries
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestFull -Encoding UTF8

Write-Host ''
Write-Host 'Steam depot preflight passed.'
Write-Host "  Stage:    $destinationFull"
Write-Host "  Files:    $($files.Count)"
Write-Host "  Manifest: $manifestFull"
Write-Host '  Excluded: steam_appid.txt, *.pdb'
