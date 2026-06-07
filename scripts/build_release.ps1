# AKASHA Windows release 빌드
# Usage: .\scripts\build_release.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

& "$PSScriptRoot\flutter.ps1" build windows --release

$exe = Join-Path $Root 'build\windows\x64\runner\Release\akasha.exe'
if (Test-Path $exe) {
  Write-Host ""
  Write-Host "OK: $exe"
} else {
  throw "Build finished but akasha.exe not found"
}
