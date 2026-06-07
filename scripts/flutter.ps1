# AKASHA — Flutter/Dart 래퍼 (로컬 SDK 경로 고정)
# Usage: .\scripts\flutter.ps1 test
#        .\scripts\flutter.ps1 build windows

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$SdkFile = Join-Path $Root 'tool\flutter_sdk.path'

if (Test-Path $SdkFile) {
  $FlutterRoot = (Get-Content $SdkFile -Raw).Trim()
} else {
  $FlutterRoot = 'C:\src\flutter'
}

$Flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
if (-not (Test-Path $Flutter)) {
  throw "Flutter not found at $Flutter — update tool/flutter_sdk.path"
}

Set-Location $Root
& $Flutter @args
