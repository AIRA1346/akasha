# wikidata_ko discovery batch — eager-only app bundle (ADR-010 Option A)
# Usage:
#   .\scripts\discovery_batch.ps1
#   .\scripts\discovery_batch.ps1 -Rounds 6 -Limit 20
#   .\scripts\discovery_batch.ps1 -SkipDiscovery   # sync + gates only

param(
  [int]$Rounds = 4,
  [int]$Limit = 20,
  [string[]]$Categories = @('manga', 'animation', 'game', 'book', 'movie', 'drama'),
  [switch]$SkipDiscovery,
  [switch]$SkipGates,
  [switch]$ContinueOnError
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

$SdkFile = Join-Path $Root 'tool\flutter_sdk.path'
if (Test-Path $SdkFile) {
  $Dart = Join-Path (Get-Content $SdkFile -Raw).Trim() 'bin\dart.bat'
} else {
  $Dart = 'C:\src\flutter\bin\dart.bat'
}

$start = (Get-Content akasha-db\manifest.json -Raw | ConvertFrom-Json).entryCount
Write-Host "discovery_batch — start: $start works"
Write-Host "  rounds=$Rounds limit=$Limit categories=$($Categories -join ',')"
Write-Host ''

if (-not $SkipDiscovery) {
  for ($round = 1; $round -le $Rounds; $round++) {
    Write-Host "===== ROUND $round ====="
    $roundCreated = 0
    foreach ($cat in $Categories) {
      $prevEap = $ErrorActionPreference
      $ErrorActionPreference = 'Continue'
      $out = & $Dart run tool/discovery/wikidata_ko_trial.dart --category $cat --limit $Limit --apply 2>&1 | Out-String
      $trialExit = $LASTEXITCODE
      $ErrorActionPreference = $prevEap
      if ($trialExit -ne 0) {
        if ($ContinueOnError) {
          Write-Host "WARN: $cat exited $trialExit (continuing)"
          continue
        }
        Write-Host "FAIL: $cat exited $trialExit"
        if ($out.Trim().Length -gt 0) { Write-Host $out }
        exit $trialExit
      }
      if ($out -match 'Done: (\d+) created') {
        $n = [int]$Matches[1]
        $roundCreated += $n
        Write-Host "$cat : $n"
      } else {
        Write-Host "$cat : 0 (no match in output)"
      }
    }
    Write-Host "==> registry_builder --sync-assets --bundle-eager-only"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Dart run tool/registry_builder.dart --sync-assets --bundle-eager-only 2>&1 | Out-Null
    $buildExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($buildExit -ne 0) { exit $buildExit }
    $now = (Get-Content akasha-db\manifest.json -Raw | ConvertFrom-Json).entryCount
    Write-Host "ROUND $round : +$roundCreated -> $now"
    Write-Host ''
  }
} else {
  Write-Host '==> registry_builder --sync-assets --bundle-eager-only'
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $Dart run tool/registry_builder.dart --sync-assets --bundle-eager-only 2>&1 | Out-Null
  $buildExit = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
  if ($buildExit -ne 0) { exit $buildExit }
}

function Invoke-DartTool {
  param([string[]]$ToolArgs)
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $Dart @ToolArgs 2>&1 | Out-Null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
  return $code
}

if (-not $SkipGates) {
  Write-Host '==> ci_registry_check'
  $code = Invoke-DartTool @('run', 'tool/ci_registry_check.dart', '--skip-builder')
  if ($code -ne 0) { exit $code }

  Write-Host ''
  Write-Host '==> preflight_check'
  $code = Invoke-DartTool @(
    'run',
    'tool/preflight_check.dart',
    '--skip-builder',
    '--skip-dedupe'
  )
  if ($code -ne 0) { exit $code }

  Write-Host ''
  Write-Host '==> catalog_scale_baseline --strict'
  $code = Invoke-DartTool @('run', 'tool/catalog_scale_baseline.dart', '--strict')
  if ($code -ne 0) { exit $code }
}

$end = (Get-Content akasha-db\manifest.json -Raw | ConvertFrom-Json).entryCount
Write-Host ''
Write-Host "OK: discovery_batch $start -> $end (+$($end - $start))"
