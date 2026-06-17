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
  [switch]$SkipGates
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
      $out = & $Dart run tool/discovery/wikidata_ko_trial.dart --category $cat --limit $Limit --apply 2>&1 | Out-String
      $trialExit = $LASTEXITCODE
      if ($trialExit -ne 0) {
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
    & $Dart run tool/registry_builder.dart --sync-assets --bundle-eager-only
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $now = (Get-Content akasha-db\manifest.json -Raw | ConvertFrom-Json).entryCount
    Write-Host "ROUND $round : +$roundCreated -> $now"
    Write-Host ''
  }
} else {
  Write-Host '==> registry_builder --sync-assets --bundle-eager-only'
  & $Dart run tool/registry_builder.dart --sync-assets --bundle-eager-only
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $SkipGates) {
  Write-Host '==> dedupe_linter'
  & $Dart run tool/dedupe_linter.dart
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host ''
  Write-Host '==> quality_gate --strict'
  & $Dart run tool/quality_gate.dart --strict
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host ''
  Write-Host '==> ci_registry_check'
  & $Dart run tool/ci_registry_check.dart
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host ''
  Write-Host '==> preflight_check'
  & $Dart run tool/preflight_check.dart
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host ''
  Write-Host '==> catalog_scale_baseline --strict'
  & $Dart run tool/catalog_scale_baseline.dart --strict
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$end = (Get-Content akasha-db\manifest.json -Raw | ConvertFrom-Json).entryCount
Write-Host ''
Write-Host "OK: discovery_batch $start -> $end (+$($end - $start))"
