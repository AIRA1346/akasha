[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$AllowSteamOffline,
    [switch]$ExitAfterValidation
)

$ErrorActionPreference = 'Stop'
$expectedAppId = '4677560'
$repoRoot = Split-Path $PSScriptRoot -Parent
$modulePath = Join-Path $PSScriptRoot 'steam_runtime_contract.psm1'
$flutter = Join-Path $repoRoot 'scripts\flutter.ps1'
$debugDir = Join-Path $repoRoot 'build\windows\x64\runner\Debug'
$debugExe = Join-Path $debugDir 'akasha.exe'
$sourceAppId = Join-Path $repoRoot 'windows\runner\steam_appid.txt'
$runtimeAppId = Join-Path $debugDir 'steam_appid.txt'

Import-Module $modulePath -Force

$existing = @(Get-CimInstance Win32_Process -Filter "Name = 'akasha.exe'")
if ($existing.Count -gt 0) {
    $paths = $existing | ForEach-Object { "PID $($_.ProcessId): $($_.ExecutablePath)" }
    throw (
        'Stop every running AKASHA process before local Steam development:' +
        [Environment]::NewLine +
        ($paths -join [Environment]::NewLine)
    )
}

$sourceValue = Test-AkashaSteamAppIdFile `
    -Path $sourceAppId `
    -ExpectedAppId $expectedAppId

if (-not $SkipBuild) {
    Write-Host 'Building the Windows Debug bundle...'
    & $flutter build windows --debug
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Debug build failed with exit code $LASTEXITCODE."
    }
}
if (-not (Test-Path -LiteralPath $debugExe -PathType Leaf)) {
    throw "Windows Debug executable is missing: $debugExe"
}

$ownsRuntimeAppId = $false
if (Test-Path -LiteralPath $runtimeAppId -PathType Leaf) {
    Test-AkashaSteamAppIdFile `
        -Path $runtimeAppId `
        -ExpectedAppId $expectedAppId | Out-Null
} else {
    Copy-Item -LiteralPath $sourceAppId -Destination $runtimeAppId
    $ownsRuntimeAppId = $true
}

$steam = Get-Process -Name steam -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $steam) {
    if (-not $AllowSteamOffline) {
        throw (
            'Steam client is not running. Start Steam and sign in, or use ' +
            '-AllowSteamOffline for UI-only development.'
        )
    }
    Write-Warning 'Steam is not running; SteamAPI_Init is expected to fail and AKASHA will continue without Steam.'
} else {
    Write-Host "Steam client detected (PID $($steam.Id))."
}

Write-Host "Repository: $repoRoot"
Write-Host "App ID:     $sourceValue"
Write-Host "Executable: $debugExe"
Write-Host "Working dir:$debugDir"
Write-Host 'Environment: local_steam_development'

$process = $null
try {
    $process = Start-Process `
        -FilePath $debugExe `
        -WorkingDirectory $debugDir `
        -PassThru
    Start-Sleep -Seconds 2
    $process.Refresh()
    if ($process.HasExited) {
        throw "AKASHA exited during startup with code $($process.ExitCode)."
    }

    $native = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)"
    if ($null -eq $native -or [string]::IsNullOrWhiteSpace($native.ExecutablePath)) {
        throw "Unable to inspect the launched AKASHA process: PID $($process.Id)"
    }
    $actual = [IO.Path]::GetFullPath($native.ExecutablePath)
    $expected = [IO.Path]::GetFullPath($debugExe)
    if (-not $actual.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "Wrong AKASHA executable launched: $actual (expected $expected)"
    }

    $kind = Get-AkashaExecutionEnvironment -ExecutablePath $actual
    if ($kind -ne 'local_debug') {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "Unexpected execution environment: $kind ($actual)"
    }

    Write-Host 'Local Steam development launch verified.'
    Write-Host "  PID:        $($process.Id)"
    Write-Host "  Actual EXE: $actual"
    Write-Host "  Type:       $kind"

    if ($ExitAfterValidation) {
        Stop-Process -Id $process.Id -Force
        Wait-Process -Id $process.Id -ErrorAction SilentlyContinue
        Write-Host 'Validation process stopped by -ExitAfterValidation.'
    } else {
        Write-Host 'Close AKASHA to finish this script.'
        Wait-Process -Id $process.Id
        $process.Refresh()
        if ($process.ExitCode -ne 0) {
            throw "AKASHA exited with code $($process.ExitCode)."
        }
    }
} finally {
    if ($ownsRuntimeAppId) {
        $stillRunning = $null -ne $process -and -not $process.HasExited
        if ($stillRunning) {
            Write-Warning "Owned App ID file retained while AKASHA is running: $runtimeAppId"
        } elseif (Test-Path -LiteralPath $runtimeAppId -PathType Leaf) {
            $currentValue = (Get-Content -LiteralPath $runtimeAppId -Raw -Encoding UTF8).Trim()
            if ($currentValue -eq $expectedAppId) {
                Remove-Item -LiteralPath $runtimeAppId -Force
                Write-Host "Removed script-owned App ID file: $runtimeAppId"
            } else {
                Write-Warning "App ID file changed during execution and was not removed: $runtimeAppId"
            }
        }
    }
}
