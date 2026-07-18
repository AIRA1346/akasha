Set-StrictMode -Version Latest

function Get-AkashaExecutionEnvironment {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$ExecutablePath
    )

    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        return 'unknown'
    }

    $normalized = $ExecutablePath.Trim().Trim('"').Replace('/', '\')
    $lower = $normalized.ToLowerInvariant()
    if ($lower.EndsWith('\build\windows\x64\runner\debug\akasha.exe')) {
        return 'local_debug'
    }
    if ($lower.EndsWith('\build\windows\x64\runner\profile\akasha.exe')) {
        return 'local_profile'
    }
    if ($lower.EndsWith('\build\windows\x64\runner\release\akasha.exe')) {
        return 'local_release'
    }
    if ($lower.Contains('\steamapps\common\') -and
        $lower.EndsWith('\akasha.exe')) {
        return 'steam_install'
    }
    return 'unknown'
}

function ConvertTo-AkashaSupportPath {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return 'unknown'
    }

    $normalized = $Path.Trim().Trim('"').Replace('/', '\')
    $environment = Get-AkashaExecutionEnvironment -ExecutablePath $normalized
    switch ($environment) {
        'local_debug' {
            return '<repo>\build\windows\x64\runner\Debug\akasha.exe'
        }
        'local_profile' {
            return '<repo>\build\windows\x64\runner\Profile\akasha.exe'
        }
        'local_release' {
            return '<repo>\build\windows\x64\runner\Release\akasha.exe'
        }
        'steam_install' {
            $marker = '\steamapps\common\'
            $index = $normalized.ToLowerInvariant().IndexOf($marker)
            return '<steam-library>' + $normalized.Substring($index)
        }
    }

    $windowsProfile = [Regex]::Match(
        $normalized,
        '^[A-Za-z]:\\Users\\[^\\]+',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    if ($windowsProfile.Success) {
        return '<user-profile>' + $normalized.Substring($windowsProfile.Length)
    }

    $unixProfile = [Regex]::Match(
        $normalized.Replace('\', '/'),
        '^/(Users|home)/[^/]+' ,
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    if ($unixProfile.Success) {
        $unixNormalized = $normalized.Replace('\', '/')
        return '<user-profile>' + $unixNormalized.Substring($unixProfile.Length)
    }

    $parts = @($normalized -split '\\' | Where-Object { $_.Length -gt 0 })
    if ($parts.Count -eq 0) {
        return '<redacted>'
    }
    $take = [Math]::Min(5, $parts.Count)
    $start = $parts.Count - $take
    $tail = $parts[$start..($parts.Count - 1)] -join '\'
    return "<redacted>\$tail"
}

function Test-AkashaSteamAppIdFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedAppId
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Steam development App ID file is missing: $Path"
    }
    $actual = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8).Trim()
    if ($actual -notmatch '^\d+$') {
        throw "Steam development App ID file must contain digits only: $Path"
    }
    if ($actual -ne $ExpectedAppId) {
        throw "Steam App ID mismatch at ${Path}: $actual != $ExpectedAppId"
    }
    return $actual
}

function Get-AkashaReleaseViolationCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $normalized = $RelativePath.Trim().Replace('/', '\')
    $lower = $normalized.ToLowerInvariant()
    $name = [IO.Path]::GetFileName($lower)
    $extension = [IO.Path]::GetExtension($name)

    if ($name -eq 'steam_appid.txt') { return 'development_app_id' }
    if ($extension -in @('.pdb', '.ipdb', '.iobj', '.ilk', '.exp', '.lib', '.obj')) {
        return 'debug_build_artifact'
    }
    if ($name -match '(^|[_-])debug\.dll$' -or $name -match '_d\.dll$') {
        return 'debug_only_dll'
    }
    if ($extension -eq '.log') { return 'development_log' }
    if ($extension -eq '.path' -or $name -in @(
        'flutter_sdk.path',
        'steam_content_builder.path'
    )) {
        return 'machine_path_configuration'
    }
    if ($lower -match '(^|\\)(test|tests|fixture|fixtures|testdata)(\\|$)') {
        return 'test_fixture'
    }
    if ($lower -match '(^|[_.\\-])poc([_.\\-]|$)' -or
        $lower.Contains('steam_inventory_poc')) {
        return 'internal_poc_asset'
    }
    if ($name -match 'itemdefs?.*(temp|tmp|fixture|poc)' -or
        $name -match '(temp|tmp|fixture|poc).*itemdefs?') {
        return 'temporary_itemdef'
    }
    if ($name -in @('loginusers.vdf', 'config.vdf', '.env') -or
        $name -match '^ssfn\d*$' -or
        $extension -in @('.key', '.pem', '.pfx', '.p12')) {
        return 'sensitive_or_account_file'
    }
    return $null
}

function Get-AkashaSensitiveContentCategory {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Content
    )

    if ([string]::IsNullOrEmpty($Content)) {
        return $null
    }
    if ($Content -match '(?i)[A-Za-z]:[\\/]Users[\\/][^\\/\r\n]+' -or
        $Content -match (
            '(?i)(^|file://|[\x00\s"''=])/(Users|home)/' +
            '[^/\x00\r\n]+(?:/|$)'
        )) {
        return 'personal_path_content'
    }
    if ($Content -match '(?i)RuneAtelier' -or
        $Content -match '(?i)akasha-build-identity-upload-[0-9a-f]+') {
        return 'personal_repository_path_content'
    }
    if ($Content -match (
        '(?i)(password|passwd|steam[_-]?guard(?:[_-]?code)?|' +
        'api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret)' +
        '\s*[:=]\s*["'']?[A-Za-z0-9+/_=-]{6,}'
    )) {
        return 'credential_content'
    }
    return $null
}

function Get-AkashaPayloadFileContentCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.FileInfo]$File
    )

    # Release AOT artifacts can retain source URIs in binary snapshots. Scan
    # decoded byte content instead of limiting the hygiene check to text files.
    # Neutral build roots such as C:\AKASHA_BUILD remain allowed; the category
    # matcher rejects only personal profiles, repository paths, and credentials.
    try {
        $bytes = [IO.File]::ReadAllBytes($File.FullName)
        foreach ($encoding in @(
            [Text.Encoding]::UTF8,
            [Text.Encoding]::Unicode,
            [Text.Encoding]::BigEndianUnicode
        )) {
            $category = Get-AkashaSensitiveContentCategory `
                -Content $encoding.GetString($bytes)
            if ($null -ne $category) {
                return $category
            }
        }
    } catch {
        # Filename/path rules still cover unreadable payload entries.
    }
    return $null
}

function Find-AkashaReleasePayloadViolation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PayloadPath
    )

    $root = [IO.Path]::GetFullPath($PayloadPath)
    $prefix = $root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File) {
        $relative = $file.FullName.Substring($prefix.Length)
        $category = Get-AkashaReleaseViolationCategory -RelativePath $relative
        if ($null -ne $category) {
            [pscustomobject]@{
                category = $category
                relativePath = $relative
                fullPath = $file.FullName
            }
            continue
        }

        $contentCategory = Get-AkashaPayloadFileContentCategory -File $file
        if ($null -ne $contentCategory) {
            [pscustomobject]@{
                category = $contentCategory
                relativePath = $relative
                fullPath = $file.FullName
            }
        }
    }
}

Export-ModuleMember -Function @(
    'Get-AkashaExecutionEnvironment',
    'ConvertTo-AkashaSupportPath',
    'Test-AkashaSteamAppIdFile',
    'Get-AkashaReleaseViolationCategory',
    'Get-AkashaSensitiveContentCategory',
    'Find-AkashaReleasePayloadViolation'
)
