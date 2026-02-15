param(
    [Parameter(Mandatory = $true)][string]$Ecosystem,
    [Parameter(Mandatory = $true)][string]$Package,
    [string]$Version,
    [ValidateSet('unknown', 'low', 'medium', 'high', 'critical')][string]$Severity,
    [int]$PerPage = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PerPage -lt 1 -or $PerPage -gt 100) {
    Write-Error 'PerPage must be between 1 and 100'
    exit 1
}

$token = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'Process')
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'User')
}
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'Machine')
}
if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error 'Environment variable GH_SEC_PAT is not set'
    exit 1
}

$affects = $Package
if (-not [string]::IsNullOrWhiteSpace($Version)) {
    $affects = "$Package@$Version"
}

$query = @(
    "ecosystem=$([System.Uri]::EscapeDataString($Ecosystem))"
    "affects=$([System.Uri]::EscapeDataString($affects))"
    "per_page=$PerPage"
)

if (-not [string]::IsNullOrWhiteSpace($Severity)) {
    $query += "severity=$([System.Uri]::EscapeDataString($Severity))"
}

$url = "https://api.github.com/advisories?$($query -join '&')"
$headers = @{
    Authorization        = "Bearer $token"
    Accept               = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

try {
    $response = Invoke-RestMethod -Method GET -Uri $url -Headers $headers
    if ($null -eq $response) {
        $advisories = @()
    }
    else {
        $advisories = @($response)
    }
    ConvertTo-Json -InputObject $advisories -Depth 100 -Compress
}
catch {
    $errorMessage = $_.Exception.Message
    if ($_.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
        $errorMessage = $_.ErrorDetails.Message
    }

    Write-Error $errorMessage
    exit 1
}
