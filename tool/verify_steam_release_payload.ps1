[CmdletBinding()]
param(
    [string]$PayloadPath,
    [ValidateSet('Release', 'Depot', 'Fixture')]
    [string]$PayloadKind = 'Release'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot 'steam_runtime_contract.psm1') -Force

if ([string]::IsNullOrWhiteSpace($PayloadPath)) {
    $PayloadPath = Join-Path $repoRoot 'build\windows\x64\runner\Release'
}
$payloadFull = [IO.Path]::GetFullPath($PayloadPath)
if (-not (Test-Path -LiteralPath $payloadFull -PathType Container)) {
    throw "Steam $PayloadKind payload directory is missing: $payloadFull"
}

$required = @(
    (Join-Path $payloadFull 'akasha.exe'),
    (Join-Path $payloadFull 'steam_api64.dll'),
    (Join-Path $payloadFull 'data\flutter_assets')
)
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Steam $PayloadKind payload is incomplete: $path"
    }
}

$violations = @(Find-AkashaReleasePayloadViolation -PayloadPath $payloadFull)
if ($violations.Count -gt 0) {
    $details = $violations | ForEach-Object {
        "[$($_.category)] $($_.fullPath)"
    }
    throw (
        "Steam $PayloadKind payload contains forbidden development data:" +
        [Environment]::NewLine +
        ($details -join [Environment]::NewLine)
    )
}

Write-Host "Steam $PayloadKind payload verification passed."
Write-Host "  Payload: $payloadFull"
Write-Host '  Forbidden development files: none'
