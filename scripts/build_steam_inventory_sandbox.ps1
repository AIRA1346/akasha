# Windows production-ItemDef Steam Inventory sandbox build.
# Usage: .\scripts\build_steam_inventory_sandbox.ps1
#
# This internal build enables guarded transaction UI for Steamworks partner
# testing. It does not change FeatureFlags.steamInAppPurchasesEnabled.

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host '==> Building Windows Release with production ItemDef sandbox transactions'
Write-Host '    Requires ItemDefs 40001-41103 to be published in the partner sandbox.'

& "$PSScriptRoot\flutter.ps1" build windows --release `
  --dart-define=AKASHA_STEAM_SANDBOX_TRANSACTIONS=true `
  --dart-define=AKASHA_STEAM_PLAYTIME_REWARDS=true
if ($LASTEXITCODE -ne 0) {
  throw "flutter build failed (exit $LASTEXITCODE). Close akasha.exe if the linker cannot overwrite it."
}

$Out = Join-Path $Root 'build\windows\x64\runner\Release'
$Exe = Join-Path $Out 'akasha.exe'
$Dll = Join-Path $Out 'steam_api64.dll'
$AppId = Join-Path $Out 'steam_appid.txt'

if (-not (Test-Path $Exe)) { throw "Missing $Exe" }
if (-not (Test-Path $Dll)) { throw "Missing $Dll" }
if (Test-Path $AppId) {
  throw "Release contract violation: development App ID file exists at $AppId"
}

& (Join-Path $Root 'tool\verify_steam_release_payload.ps1') `
  -PayloadPath $Out `
  -PayloadKind Release

Write-Host ''
Write-Host 'OK Steam Inventory production sandbox build:'
Write-Host "  $Exe"
Write-Host "  $Dll"
Write-Host '  steam_appid.txt: absent (required)'
Write-Host ''
Write-Host 'Stage and upload only to the password-protected internal branch.'
Write-Host 'Do not launch this raw Release output as local release evidence.'
Write-Host 'Use scripts\steam\prepare_steam_depot.ps1 before SteamPipe upload.'
Write-Host 'Store transactions and Echo reward checks are sandbox-only. Live IAP is enabled, but production commerce acceptance remains incomplete.'
