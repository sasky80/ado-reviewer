param(
    [string]$Package = 'Newtonsoft.Json',
    [string]$Version = '13.0.3'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillPath = Join-Path $PSScriptRoot '..\.github\skills\check-deprecated-dependencies\check-deprecated-dependencies.ps1'
if (-not (Test-Path -LiteralPath $skillPath)) {
    Write-Error "Skill script not found: $skillPath"
    exit 1
}

$output = & $skillPath nuget $Package $Version 2>&1 | Out-String
$exitCodeVar = Get-Variable -Name LASTEXITCODE -ErrorAction SilentlyContinue
$exitCode = if ($null -ne $exitCodeVar) { [int]$exitCodeVar.Value } else { 0 }

if ($exitCode -ne 0) {
    Write-Error "NuGet deprecation check failed for $Package@$Version`n$output"
    exit 1
}

try {
    $json = $output | ConvertFrom-Json
}
catch {
    Write-Error "NuGet deprecation check did not return valid JSON.`n$output"
    exit 1
}

$required = @('ecosystem', 'package', 'version', 'deprecated', 'message', 'replacement')
foreach ($name in $required) {
    if ($json.PSObject.Properties.Name -notcontains $name) {
        Write-Error "Missing required field '$name' in output JSON."
        exit 1
    }
}

if ($json.ecosystem -ne 'nuget') {
    Write-Error "Unexpected ecosystem value: $($json.ecosystem)"
    exit 1
}

if ($json.package -ne $Package) {
    Write-Error "Unexpected package value: $($json.package)"
    exit 1
}

if ($json.version -ne $Version) {
    Write-Error "Unexpected version value: $($json.version)"
    exit 1
}

if ($json.deprecated -isnot [bool]) {
    Write-Error "Field 'deprecated' is not boolean."
    exit 1
}

if (($json.message -isnot [string]) -or ($json.replacement -isnot [string])) {
    Write-Error "Fields 'message' and 'replacement' must be strings."
    exit 1
}

[pscustomobject]@{
    status = 'pass'
    check = 'nuget-deprecation-regression'
    package = $Package
    version = $Version
    deprecated = $json.deprecated
} | ConvertTo-Json -Depth 10 -Compress
