param(
    [Parameter(Mandatory = $true)][string]$Ecosystem,
    [Parameter(Mandatory = $true)][string]$Package,
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ecosystemNormalized = $Ecosystem.ToLowerInvariant()
if ($ecosystemNormalized -eq 'pypi') {
    $ecosystemNormalized = 'pip'
}

$adapterPath = Join-Path $PSScriptRoot ("adapters\$ecosystemNormalized.ps1")
if (-not (Test-Path -LiteralPath $adapterPath)) {
    Write-Error "Unsupported ecosystem: $Ecosystem (supported: npm, pip|pypi, nuget)"
    exit 1
}

& $adapterPath $Package $Version
