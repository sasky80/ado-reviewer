param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId,
    [Parameter(Mandatory = $true)][string]$IterationId
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$PullRequestId/iterations/$IterationId/changes?api-version=7.2-preview"

$raw = Invoke-AdoRequest -Method GET -Url $url -Headers $ctx.Headers
$payload = $raw | ConvertFrom-Json

$files = @()
foreach ($entry in $payload.changeEntries) {
    $item = $entry.item
    $itemPath = $null
    if ($item -and $item.PSObject.Properties.Name -contains 'path') {
        $itemPath = $item.path
    }
    $path = if ($itemPath) { [string]$itemPath } else { [string]$entry.originalPath }
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    $isFolder = $false
    if ($item -and $item.PSObject.Properties.Name -contains 'isFolder' -and $null -ne $item.isFolder) {
        $isFolder = [bool]$item.isFolder
    }

    $files += [pscustomobject]@{
        path             = $path
        changeType       = $entry.changeType
        changeTrackingId = $entry.changeTrackingId
        isFolder         = $isFolder
    }
}

$result = [pscustomobject]@{
    pullRequestId = $PullRequestId
    iterationId   = $IterationId
    count         = $files.Count
    files         = $files
}

Write-Json -InputObject $result
