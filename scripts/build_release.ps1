# AKASHA Windows release 빌드
# Usage: .\scripts\build_release.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

# Phase 2.3 (ADR-010): G1+ catalog → eager-only app bundle before release
Write-Host '==> registry_builder --sync-assets --bundle-eager-only'
& "$PSScriptRoot\flutter.ps1" pub get | Out-Null
$SdkFile = Join-Path $Root 'tool\flutter_sdk.path'
if (Test-Path $SdkFile) {
  $Dart = Join-Path (Get-Content $SdkFile -Raw).Trim() 'bin\dart.bat'
} else {
  $Dart = 'C:\src\flutter\bin\dart.bat'
}
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $Dart run tool/registry_builder.dart --sync-assets --bundle-eager-only 2>&1 | Out-Null
$registryExit = $LASTEXITCODE
$ErrorActionPreference = $prevEap
if ($registryExit -ne 0) { exit $registryExit }

& "$PSScriptRoot\flutter.ps1" build windows --release

$exe = Join-Path $Root 'build\windows\x64\runner\Release\akasha.exe'
if (Test-Path $exe) {
  Write-Host ""
  Write-Host "OK: $exe"
} else {
  throw "Build finished but akasha.exe not found"
}
