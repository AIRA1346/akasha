# AKASHA → SteamPipe 업로드
# Usage:
#   1) Steamworks에 password-protected commerce-sandbox branch 생성
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

if ([string]::IsNullOrWhiteSpace($SteamCmd)) {
    throw @"
Steamworks ContentBuilder 경로가 설정되지 않았습니다.
AKASHA_STEAM_CONTENT_BUILDER 환경 변수 또는 추적되지 않는
scripts\steam\steam_content_builder.path 파일을 사용하세요.
"@
}
if (-not (Test-Path -LiteralPath $SteamCmd)) {
    throw "steamcmd 없음: $SteamCmd"
}

if (-not (Test-Path (Join-Path $ReleaseDir 'akasha.exe'))) {
    Write-Host "Release 빌드 없음 — 빌드 실행 중..."
    & (Join-Path (Split-Path $PSScriptRoot -Parent) 'build_release.ps1')
}

& "$PSScriptRoot\prepare_steam_depot.ps1"
& "$PSScriptRoot\validate_steam_pipe_config.ps1"

Write-Host ""
Write-Host "App ID:   $SteamAppId"
Write-Host "Depot ID: $SteamDepotId"
Write-Host "Branch:   $SteamBranchName"
Write-Host "Content:  $DepotStageDir"
Write-Host "Manifest: $DepotManifestPath"
Write-Host "App VDF:  $AppBuildVdf"
Write-Host "Depot VDF: $DepotBuildVdf"
$manifest = Get-Content -Raw -Encoding UTF8 $DepotManifestPath |
    ConvertFrom-Json
Write-Host "Git SHA:   $($manifest.gitSha)"
Write-Host ""
Write-Host "Steam 로그인 + Steam Guard 입력이 필요합니다."
Write-Host ""

Push-Location (Split-Path $SteamCmd -Parent)
try {
    & $SteamCmd +login $SteamUsername +run_app_build $AppBuildVdf +quit 2>&1 |
        Tee-Object -Variable steamOutput |
        Out-Host
    $steamExit = $LASTEXITCODE
} finally {
    Pop-Location
}
if ($steamExit -ne 0) {
    throw "SteamCMD upload failed with exit code $steamExit."
}

$outputText = @($steamOutput) -join [Environment]::NewLine
$buildMatches = [Regex]::Matches(
    $outputText,
    '(?i)(?:BuildID|App build)[^0-9]+([0-9]+)'
)
$buildId = if ($buildMatches.Count -gt 0) {
    $buildMatches[$buildMatches.Count - 1].Groups[1].Value
} else {
    $null
}
$receiptDir = Join-Path $AkashaRoot 'build\steam\upload_receipts'
New-Item -ItemType Directory -Path $receiptDir -Force | Out-Null
$receiptPath = Join-Path $receiptDir (
    [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '.json'
)
[ordered]@{
    appId = $SteamAppId
    depotId = $SteamDepotId
    branch = $SteamBranchName
    gitSha = [string]$manifest.gitSha
    buildId = $buildId
    uploadedAtUtc = [DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath $receiptPath -Encoding UTF8

Write-Host ""
Write-Host "Upload receipt: $receiptPath"
Write-Host "BuildID: $(if ($buildId) { $buildId } else { 'not parsed; confirm in Steamworks' })"
Write-Host "완료 후 Steamworks → SteamPipe → Your Builds 새로고침"
Write-Host "→ '$SteamBranchName' branch에 SetLive 되었는지 확인"
