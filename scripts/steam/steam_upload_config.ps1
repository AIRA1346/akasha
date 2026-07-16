# SteamPipe 업로드 설정 — Depot ID만 Steamworks에서 확인 후 수정
# Steamworks → AKASHA → SteamPipe → Depots → Windows depot 숫자

$SteamAppId = '4677560'
$SteamDepotId = '4677561'

$AkashaRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ReleaseDir = Join-Path $AkashaRoot 'build\windows\x64\runner\Release'
$DepotStageDir = Join-Path $AkashaRoot 'build\steam\depot_windows'
$DepotManifestPath = Join-Path $AkashaRoot 'build\steam\manifests\depot_windows.json'

$SteamSdkRoot = 'C:\dev\steamworks\steamworks_sdk_164\sdk\tools\ContentBuilder'
$SteamCmd = Join-Path $SteamSdkRoot 'builder\steamcmd.exe'
$BuildOutput = Join-Path $SteamSdkRoot 'output'
$VdfPath = Join-Path $PSScriptRoot 'app_build_akasha.vdf'
