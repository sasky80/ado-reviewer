param(
    [Parameter(Mandatory = $true)][string]$Package,
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Json {
    param([Parameter(Mandatory = $true)][string]$Url)
    return Invoke-RestMethod -Method GET -Uri $Url
}

$lowerName = $Package.ToLowerInvariant()
$indexUrl = "https://api.nuget.org/v3/registration5-semver1/$([System.Uri]::EscapeDataString($lowerName))/index.json"

try {
    $root = Get-Json -Url $indexUrl
}
catch {
    Write-Error "Failed to query NuGet metadata for $Package"
    exit 1
}

$entries = New-Object System.Collections.Generic.List[object]
foreach ($page in @($root.items)) {
    if ($page -and $page.items) {
        foreach ($item in @($page.items)) {
            if ($item) { $entries.Add($item) }
        }
    }
    elseif ($page -and $page.'@id') {
        try {
            $pageObj = Get-Json -Url ([string]$page.'@id')
            foreach ($item in @($pageObj.items)) {
                if ($item) { $entries.Add($item) }
            }
        }
        catch {
            continue
        }
    }
}

if ($entries.Count -eq 0) {
    Write-Error "No NuGet versions found for $Package"
    exit 1
}

$selected = $null
if (-not [string]::IsNullOrWhiteSpace($Version)) {
    foreach ($entry in $entries) {
        $entryVersion = [string]$entry.catalogEntry.version
        if ($entryVersion.ToLowerInvariant() -eq $Version.ToLowerInvariant()) {
            $selected = $entry
            break
        }
    }

    if ($null -eq $selected) {
        Write-Error "Version $Version not found for NuGet package $Package"
        exit 1
    }
}
else {
    $selected = $entries[$entries.Count - 1]
    $Version = [string]$selected.catalogEntry.version
}

$deprecation = $selected.catalogEntry.deprecation
$deprecated = $false
$message = ''
$replacement = ''

if ($deprecation) {
    $deprecated = $true

    $reasons = @($deprecation.reasons)
    if ($reasons.Count -gt 0) {
        $message = ($reasons | ForEach-Object { [string]$_ }) -join '; '
    }

    $alternate = $deprecation.alternatePackage
    if ($alternate) {
        $altId = [string]$alternate.id
        $altRange = [string]$alternate.range
        if (-not [string]::IsNullOrWhiteSpace($altId) -and -not [string]::IsNullOrWhiteSpace($altRange)) {
            $replacement = "$altId $altRange"
        }
        elseif (-not [string]::IsNullOrWhiteSpace($altId)) {
            $replacement = $altId
        }
    }

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = 'Package version is marked as deprecated in NuGet metadata'
    }
}

[pscustomobject]@{
    ecosystem = 'nuget'
    package = $Package
    version = [string]$Version
    deprecated = $deprecated
    message = $message
    replacement = $replacement
} | ConvertTo-Json -Depth 100 -Compress
