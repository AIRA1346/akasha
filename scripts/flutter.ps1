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

# Some Windows workspace providers mark every directory ReadOnly even though
# the ACL grants Modify. Flutter gen-l10n treats that attribute as unwritable,
# so normalize only the source/output localization directories before running
# commands that may invoke localization generation.
foreach ($RelativePath in @('l10n', 'lib\generated\l10n')) {
  $Path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $Path)) { continue }
  $Directory = Get-Item -LiteralPath $Path
  if (($Directory.Attributes -band [IO.FileAttributes]::ReadOnly) -ne 0) {
    $Directory.Attributes = $Directory.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
  }
}

Set-Location $Root
& $Flutter @args
