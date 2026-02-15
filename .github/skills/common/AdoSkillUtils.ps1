Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PatSuffix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Organization
    )

    $normalized = [System.Text.RegularExpressions.Regex]::Replace($Organization, '[^A-Za-z0-9_]', '_')
    if ($normalized -match '^[0-9]') {
        return "_$normalized"
    }

    return $normalized
}

function Get-Pat {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Organization
    )

    $suffix = Get-PatSuffix -Organization $Organization
    $patVar = "ADO_PAT_$suffix"
    $pat = [Environment]::GetEnvironmentVariable($patVar, 'Process')

    if ([string]::IsNullOrWhiteSpace($pat)) {
        $pat = [Environment]::GetEnvironmentVariable($patVar, 'User')
    }

    if ([string]::IsNullOrWhiteSpace($pat)) {
        $pat = [Environment]::GetEnvironmentVariable($patVar, 'Machine')
    }

    if ([string]::IsNullOrWhiteSpace($pat)) {
        throw "Environment variable $patVar is not set"
    }

    return $pat
}

function UrlEncode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return [System.Uri]::EscapeDataString($Value)
}

function New-AdoHeaders {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pat
    )

    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $Pat))
    return @{
        Authorization = "Basic $token"
        Accept        = 'application/json'
    }
}

function New-AdoContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [string]$Project,

        [string]$RepositoryId
    )

    $pat = Get-Pat -Organization $Organization
    $headers = New-AdoHeaders -Pat $pat

    $context = [ordered]@{
        Organization        = $Organization
        OrganizationEncoded = UrlEncode -Value $Organization
        Headers             = $headers
    }

    if (-not [string]::IsNullOrWhiteSpace($Project)) {
        $context.Project = $Project
        $context.ProjectEncoded = UrlEncode -Value $Project
    }

    if (-not [string]::IsNullOrWhiteSpace($RepositoryId)) {
        $context.RepositoryId = $RepositoryId
        $context.RepositoryEncoded = UrlEncode -Value $RepositoryId
    }

    return [pscustomobject]$context
}

function Write-Json {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    $InputObject | ConvertTo-Json -Depth 100 -Compress
}

function ConvertTo-AdoFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if ($FilePath -eq '-' -or [string]::IsNullOrWhiteSpace($FilePath)) {
        return $FilePath
    }

    $normalized = $FilePath.Trim() -replace '\\', '/'

    if ($normalized -match '^[A-Za-z]:/' -or $normalized.StartsWith('//')) {
        throw "FilePath must be repository-relative (for example: /src/app.js). Received: '$FilePath'"
    }

    while ($normalized.StartsWith('./')) {
        $normalized = $normalized.Substring(2)
    }

    while ($normalized.Contains('//')) {
        $normalized = $normalized -replace '//', '/'
    }

    if (-not $normalized.StartsWith('/')) {
        $normalized = "/$normalized"
    }

    return $normalized
}

function Invoke-AdoRequest {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH')]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,

        [object]$Body
    )

    try {
        if ($PSBoundParameters.ContainsKey('Body')) {
            $jsonBody = $Body | ConvertTo-Json -Depth 50 -Compress
            $response = Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers -ContentType 'application/json' -Body $jsonBody
        }
        else {
            $response = Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers
        }

        Write-Json -InputObject $response
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
            $errorMessage = $_.ErrorDetails.Message
        }

        Write-Error $errorMessage
        exit 1
    }
}

function Get-AuthenticatedUserId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationEncoded,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers
    )

    $url = "https://dev.azure.com/$OrganizationEncoded/_apis/connectionData"

    try {
        $response = Invoke-RestMethod -Method GET -Uri $url -Headers $Headers
        return $response.authenticatedUser.id
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
            $errorMessage = $_.ErrorDetails.Message
        }

        Write-Error $errorMessage
        exit 1
    }
}
