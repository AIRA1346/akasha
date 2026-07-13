# P1 English UI visual capture against Steam Release akasha.exe
param(
  [string]$Exe = (Join-Path $PSScriptRoot '..\build\windows\x64\runner\Release\akasha.exe' | Resolve-Path),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\docs\active\evidence\p1-english-ui-2026-07-12' | Resolve-Path),
  [string]$PrefsPath = "$env:APPDATA\Rune Atelier\AKASHA\shared_preferences.json"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win32Cap {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@

function Set-EnglishLocale {
  if (-not (Test-Path $PrefsPath)) { throw "prefs missing: $PrefsPath" }
  $json = Get-Content -Raw -Path $PrefsPath | ConvertFrom-Json
  $json | Add-Member -NotePropertyName 'flutter.akasha_catalog_locale' -NotePropertyValue 'en' -Force
  ($json | ConvertTo-Json -Compress) | Set-Content -Path $PrefsPath -Encoding UTF8
  Write-Host "locale seeded en in $PrefsPath"
}

function Find-AkashaHwnd([int]$ProcessId) {
  $script:foundHwnd = [IntPtr]::Zero
  $cb = [Win32Cap+EnumWindowsProc]{
    param([IntPtr]$h, [IntPtr]$l)
    [uint32]$wpid = 0
    [void][Win32Cap]::GetWindowThreadProcessId($h, [ref]$wpid)
    if ($wpid -eq $ProcessId -and [Win32Cap]::IsWindowVisible($h)) {
      $sb = New-Object System.Text.StringBuilder 256
      [void][Win32Cap]::GetWindowText($h, $sb, $sb.Capacity)
      $title = $sb.ToString()
      if ($title -match 'akasha|AKASHA' -or $title.Length -gt 0) {
        $script:foundHwnd = $h
        return $false
      }
    }
    return $true
  }
  [void][Win32Cap]::EnumWindows($cb, [IntPtr]::Zero)
  return $script:foundHwnd
}

function Capture-Window([IntPtr]$Hwnd, [string]$Path) {
  [void][Win32Cap]::ShowWindow($Hwnd, 9)
  [void][Win32Cap]::SetForegroundWindow($Hwnd)
  Start-Sleep -Milliseconds 400
  $rect = New-Object Win32Cap+RECT
  [void][Win32Cap]::GetWindowRect($Hwnd, [ref]$rect)
  $w = [Math]::Max(1, $rect.Right - $rect.Left)
  $h = [Math]::Max(1, $rect.Bottom - $rect.Top)
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size($w, $h)))
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Host "saved $Path ($w x $h)"
}

# Stop prior instances of release exe to avoid prefs races
Get-Process -Name akasha -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Set-EnglishLocale

$proc = Start-Process -FilePath $Exe -PassThru
Write-Host "started pid=$($proc.Id)"
$hwnd = [IntPtr]::Zero
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 500
  $hwnd = Find-AkashaHwnd $proc.Id
  if ($hwnd -ne [IntPtr]::Zero) { break }
}
if ($hwnd -eq [IntPtr]::Zero) { throw "AKASHA window not found" }
Write-Host "hwnd=$hwnd"
Start-Sleep -Seconds 4

Capture-Window $hwnd (Join-Path $OutDir '01-home-english-seed.png')

[Win32Cap]::SetForegroundWindow($hwnd) | Out-Null
[System.Windows.Forms.SendKeys]::SendWait('{ESC}')
Start-Sleep -Seconds 2
Capture-Window $hwnd (Join-Path $OutDir '02-preferences-esc.png')

[System.Windows.Forms.SendKeys]::SendWait('{ESC}')
Start-Sleep -Seconds 1
Capture-Window $hwnd (Join-Path $OutDir '03-home-after-prefs-close.png')

# Restart persistence check
Stop-Process -Id $proc.Id -Force
Start-Sleep -Seconds 2
$proc2 = Start-Process -FilePath $Exe -PassThru
$hwnd2 = [IntPtr]::Zero
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 500
  $hwnd2 = Find-AkashaHwnd $proc2.Id
  if ($hwnd2 -ne [IntPtr]::Zero) { break }
}
Start-Sleep -Seconds 4
Capture-Window $hwnd2 (Join-Path $OutDir '04-restart-english-persisted.png')
[Win32Cap]::SetForegroundWindow($hwnd2) | Out-Null
[System.Windows.Forms.SendKeys]::SendWait('{ESC}')
Start-Sleep -Seconds 2
Capture-Window $hwnd2 (Join-Path $OutDir '05-restart-preferences.png')

# Leave app running for further manual/agent captures if needed
Write-Host "DONE pid=$($proc2.Id) hwnd=$hwnd2"
Write-Host "PROCESS_ID=$($proc2.Id)"
Write-Host "HWND=$hwnd2"
