# AKASHA → SteamPipe 업로드
# Usage:
#   1) scripts\steam\steam_upload_config.ps1 에 Depot ID 입력
#   2) .\scripts\steam\upload_steam_build.ps1 -SteamUsername YOUR_STEAM_LOGIN

param(
    [Parameter(Mandatory = $true)]
    [string]$SteamUsername
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\steam_upload_config.ps1"

if ($SteamDepotId -eq 'REPLACE_WITH_YOUR_DEPOT_ID') {
    throw @"
Depot ID가 설정되지 않았습니다.
Steamworks → AKASHA (4677560) → SteamPipe → Depots → Windows depot 번호를
scripts\steam\steam_upload_config.ps1 의 `$SteamDepotId 에 넣으세요.
"@
}

if (-not (Test-Path $SteamCmd)) {
    throw "steamcmd 없음: $SteamCmd"
}

if (-not (Test-Path (Join-Path $ReleaseDir 'akasha.exe'))) {
    Write-Host "Release 빌드 없음 — 빌드 실행 중..."
    & (Join-Path (Split-Path $PSScriptRoot -Parent) 'build_release.ps1')
}

& "$PSScriptRoot\prepare_steam_depot.ps1"

$releaseEscaped = $DepotStageDir -replace '\\', '\\'
$outputEscaped = $BuildOutput -replace '\\', '\\'

$depotVdf = Join-Path $SteamSdkRoot 'output\_akasha_depot_build.vdf'
$appVdf = Join-Path $SteamSdkRoot 'output\_akasha_app_build.vdf'

@'
"DepotBuild"
{
	"DepotID" "{DEPOT_ID}"
	"ContentRoot" "{RELEASE_DIR}"
	"FileMapping"
	{
		"LocalPath" "*"
		"DepotPath" "."
		"Recursive" "1"
	}
	"FileExclusion" "*.pdb"
	"FileExclusion" "steam_appid.txt"
}
'@ -replace '\{DEPOT_ID\}', $SteamDepotId -replace '\{RELEASE_DIR\}', $releaseEscaped |
    Set-Content $depotVdf -Encoding UTF8

$depotFileName = Split-Path $depotVdf -Leaf
@'
"AppBuild"
{
	"AppID" "{APP_ID}"
	"Desc" "AKASHA Windows release"
	"Preview" "0"
	"ContentRoot" "{RELEASE_DIR}"
	"BuildOutput" "{BUILD_OUTPUT}"
	"Depots"
	{
		"{DEPOT_ID}" "{DEPOT_VDF_NAME}"
	}
}
'@ -replace '\{APP_ID\}', $SteamAppId `
   -replace '\{RELEASE_DIR\}', $releaseEscaped `
   -replace '\{BUILD_OUTPUT\}', $outputEscaped `
   -replace '\{DEPOT_ID\}', $SteamDepotId `
   -replace '\{DEPOT_VDF_NAME\}', $depotFileName |
    Set-Content $appVdf -Encoding UTF8

Write-Host ""
Write-Host "App ID:   $SteamAppId"
Write-Host "Depot ID: $SteamDepotId"
Write-Host "Content:  $DepotStageDir"
Write-Host "Manifest: $DepotManifestPath"
Write-Host "VDF:      $appVdf"
Write-Host ""
Write-Host "Steam 로그인 + Steam Guard 입력이 필요합니다."
Write-Host ""

Push-Location (Split-Path $SteamCmd -Parent)
try {
    & $SteamCmd +login $SteamUsername +run_app_build $appVdf +quit
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "완료 후 Steamworks → SteamPipe → Your Builds 새로고침"
Write-Host "→ branch default 에 Build ID Set Live → Publish 탭 Publish"
