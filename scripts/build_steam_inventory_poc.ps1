# Windows Steam Inventory POC build (Release + dart-define)
# Usage: .\scripts\build_steam_inventory_poc.ps1
#
# Does NOT enable steamInAppPurchasesEnabled.
# POC UI: debug menu always; Release needs --dart-define for optional internal gate later.

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host '==> flutter build windows --release (Steam Inventory native bridge)'
& "$PSScriptRoot\flutter.ps1" build windows --release `
  --dart-define=AKASHA_STEAM_INVENTORY_POC=true

$out = Join-Path $Root 'build\windows\x64\runner\Release'
$exe = Join-Path $out 'akasha.exe'
$dll = Join-Path $out 'steam_api64.dll'
$appid = Join-Path $out 'steam_appid.txt'

if (-not (Test-Path $exe)) { throw "Missing $exe" }
if (-not (Test-Path $dll)) { throw "Missing steam_api64.dll — check STEAMWORKS_SDK_ROOT CMake path" }
if (-not (Test-Path $appid)) {
  Copy-Item (Join-Path $Root 'windows\runner\steam_appid.txt') $appid -Force
}

Write-Host ""
Write-Host "OK Steam Inventory POC build:"
Write-Host "  $exe"
Write-Host "  $dll"
Write-Host "  $appid"
Write-Host ""
Write-Host "Launch with Steam running. App Preferences → Steam Inventory POC"
Write-Host "(dialog opens with this dart-define; IAP flag stays false)."
Write-Host "steamInAppPurchasesEnabled remains false."
