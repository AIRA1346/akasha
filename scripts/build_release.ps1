# AKASHA Windows release build
# Usage: .\scripts\build_release.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

$SdkFile = Join-Path $Root 'tool\flutter_sdk.path'
if (Test-Path $SdkFile) {
  $Dart = Join-Path (Get-Content $SdkFile -Raw).Trim() 'bin\dart.bat'
} else {
  $Dart = 'C:\src\flutter\bin\dart.bat'
}

function Get-TrackedState {
  $lines = & git status --porcelain=v1 --untracked-files=all
  if ($LASTEXITCODE -ne 0) { throw 'git status failed' }
  return ($lines -join "`n")
}

$SourceStatus = (& git status --porcelain=v1 --untracked-files=all -- akasha-db) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'git source status failed' }
if ($SourceStatus) {
  throw "akasha-db must be clean before a release build:`n$SourceStatus"
}
$BundleStatus = (& git status --porcelain=v1 --untracked-files=all -- assets/registry) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'git bundle status failed' }
if ($BundleStatus) {
  throw "assets/registry must be clean before a release build:`n$BundleStatus"
}

# Provenance must match registry_bundle_ci.dart: data inputs only (not *.md).
$SourceRevision = (& $Dart run tool/registry_source_revision.dart).Trim()
if ($LASTEXITCODE -ne 0 -or -not $SourceRevision) {
  throw 'Could not resolve the committed akasha-db registry data source revision'
}

Write-Host '==> verify deterministic full registry bundle'
& $Dart run tool/registry_bundle_builder.dart `
  --source akasha-db `
  --output assets/registry `
  --bundle-all `
  --source-revision $SourceRevision `
  --verify-only
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Before = Get-TrackedState
& "$PSScriptRoot\flutter.ps1" pub get | Out-Null
& "$PSScriptRoot\flutter.ps1" build windows --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$After = Get-TrackedState
if ($After -ne $Before) {
  throw "Release build changed the repository working tree unexpectedly.`nBefore:`n$Before`nAfter:`n$After"
}

$exe = Join-Path $Root 'build\windows\x64\runner\Release\akasha.exe'
if (Test-Path $exe) {
  & (Join-Path $Root 'tool\verify_steam_release_payload.ps1') `
    -PayloadPath (Split-Path $exe -Parent) `
    -PayloadKind Release
  Write-Host ''
  Write-Host "OK: $exe"
} else {
  throw 'Build finished but akasha.exe was not found'
}
