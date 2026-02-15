param(
    [Parameter(Mandatory = $true)][string]$Package,
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error 'npm command is required'
    exit 1
}

$spec = if ([string]::IsNullOrWhiteSpace($Version)) { $Package } else { "$Package@$Version" }

try {
    $raw = npm view $spec deprecated --json 2>$null
}
catch {
    Write-Error "Failed to query npm metadata for $spec"
    exit 1
}

$message = ''
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try {
        $parsed = $raw | ConvertFrom-Json
        if ($parsed -is [string]) {
            $message = $parsed.Trim()
        }
    }
    catch {
        $message = [string]$raw
    }
}

$deprecated = -not [string]::IsNullOrWhiteSpace($message)
$replacement = ''
if ($deprecated) {
    $m = [System.Text.RegularExpressions.Regex]::Match($message, '(?:use|switch to|migrate to)\s+([@A-Za-z0-9_./-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m.Success) {
        $replacement = $m.Groups[1].Value
    }
}

[pscustomobject]@{
    ecosystem = 'npm'
    package = $Package
    version = [string]$Version
    deprecated = $deprecated
    message = $message
    replacement = $replacement
} | ConvertTo-Json -Depth 100 -Compress
