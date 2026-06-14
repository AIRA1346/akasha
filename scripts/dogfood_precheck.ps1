# M1 dogfood — 자동 사전 검증 (수동 볼트 테스트 전 실행)
# Usage: .\scripts\dogfood_precheck.ps1
#        .\scripts\dogfood_precheck.ps1 -Build   # Windows release 빌드 포함

param(
  [switch]$Build
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host '==> flutter test'
& "$PSScriptRoot\flutter.ps1" test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host '==> ci_registry_check'
$SdkFile = Join-Path $Root 'tool\flutter_sdk.path'
if (Test-Path $SdkFile) {
  $FlutterRoot = (Get-Content $SdkFile -Raw).Trim()
} else {
  $FlutterRoot = 'C:\src\flutter'
}
$Dart = Join-Path $FlutterRoot 'bin\dart.bat'
& $Dart run tool/ci_registry_check.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host '==> preflight_check'
& $Dart run tool/preflight_check.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host '==> quality_gate --release'
& $Dart run tool/quality_gate.dart --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Build) {
  Write-Host ''
  Write-Host '==> windows release build'
  & "$PSScriptRoot\build_release.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ''
Write-Host 'OK: automated dogfood pre-check passed.'
Write-Host 'Manual: connect vault, search, sync, personal library filters, theme picker.'
