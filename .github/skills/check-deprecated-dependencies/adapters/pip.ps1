param(
    [Parameter(Mandatory = $true)][string]$Package,
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-ContainsAny {
    param(
        [string]$Text,
        [string[]]$Terms
    )

    $value = ($Text ?? '').ToLowerInvariant()
    foreach ($t in $Terms) {
        if ($value.Contains($t.ToLowerInvariant())) {
            return $true
        }
    }

    return $false
}

$encodedName = [System.Uri]::EscapeDataString($Package)
$url = if ([string]::IsNullOrWhiteSpace($Version)) {
    "https://pypi.org/pypi/$encodedName/json"
}
else {
    "https://pypi.org/pypi/$encodedName/$([System.Uri]::EscapeDataString($Version))/json"
}

try {
    $payload = Invoke-RestMethod -Method GET -Uri $url
}
catch {
    $spec = if ([string]::IsNullOrWhiteSpace($Version)) { $Package } else { "$Package@$Version" }
    Write-Error "Failed to query PyPI metadata for $spec"
    exit 1
}

$deprecated = $false
$message = ''
$replacement = ''

$urls = @($payload.urls)
foreach ($u in $urls) {
    if ($u -and $u.yanked -eq $true) {
        $deprecated = $true
        $message = [string]$u.yanked_reason
        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = 'Package release is yanked'
        }
        break
    }
}

if (-not $deprecated) {
    $classifiers = @($payload.info.classifiers)
    foreach ($c in $classifiers) {
        if ([string]$c -like '*Development Status :: 7 - Inactive*') {
            $deprecated = $true
            $message = 'Package is marked as inactive by classifier'
            break
        }
    }
}

if (-not $deprecated) {
    $summary = [string]$payload.info.summary
    $description = [string]$payload.info.description
    if ($description.Length -gt 8000) {
        $description = $description.Substring(0, 8000)
    }

    if (Test-ContainsAny -Text ($summary + "`n" + $description) -Terms @('deprecated', 'unmaintained', 'obsolete', 'no longer maintained')) {
        $deprecated = $true
        $message = 'Package metadata indicates deprecation or maintenance end'
    }
}

if (-not [string]::IsNullOrWhiteSpace($message)) {
    $m = [System.Text.RegularExpressions.Regex]::Match($message, '(?:use|switch to|migrate to)\s+([@A-Za-z0-9_./-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m.Success) {
        $replacement = $m.Groups[1].Value
    }
}

[pscustomobject]@{
    ecosystem = 'pip'
    package = $Package
    version = [string]$Version
    deprecated = $deprecated
    message = $message
    replacement = $replacement
} | ConvertTo-Json -Depth 100 -Compress
