param(
  [string]$Schema = "docs\active\steam_inventory_production\itemdefs_steamworks_upload.json"
)

$ErrorActionPreference = "Stop"

$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$schemaPath = (Resolve-Path -LiteralPath (Join-Path $workspace $Schema)).Path
if (-not $schemaPath.StartsWith($workspace + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
  throw "Schema must stay inside the AKASHA workspace: $schemaPath"
}

$document = Get-Content -Raw -Encoding utf8 -LiteralPath $schemaPath | ConvertFrom-Json
if ($document.appid -ne "4677560") {
  throw "Unexpected AppID: $($document.appid)"
}
if ($document.items.Count -eq 0) {
  throw "ItemDef schema contains no items."
}

$ids = @($document.items | ForEach-Object { [string]$_.itemdefid })
if (($ids | Select-Object -Unique).Count -ne $ids.Count) {
  throw "ItemDef schema contains duplicate IDs."
}

Write-Output "==> JSON parsed: AppID $($document.appid), $($document.items.Count) ItemDefs"
Write-Output "==> Running semantic and catalog contract tests"
& "$PSScriptRoot\flutter.ps1" test test\steam_inventory_production_itemdefs_test.dart
if ($LASTEXITCODE -ne 0) {
  throw "Steam Inventory ItemDef tests failed."
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $schemaPath).Hash.ToLowerInvariant()
Write-Output ""
Write-Output "OK Steamworks ItemDef upload candidate"
Write-Output "  File:   $schemaPath"
Write-Output "  SHA256: $hash"
Write-Output ""
Write-Output "Steamworks remains the final schema validator. Publish to the private partner sandbox first."
