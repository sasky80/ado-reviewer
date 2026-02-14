param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId,
    [Parameter(Mandatory = $true)][string]$ThreadId,
    [string]$Reply = '-',
    [string]$Status = ''
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

if (($Reply -eq '-' -or [string]::IsNullOrWhiteSpace($Reply)) -and [string]::IsNullOrWhiteSpace($Status)) {
    Write-Error 'At least one of reply or status must be provided.'
    exit 1
}

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$baseUrl = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$PullRequestId/threads/$ThreadId"

if ($Reply -ne '-' -and -not [string]::IsNullOrWhiteSpace($Reply)) {
    $commentBody = @{
        content = $Reply
        parentCommentId = 1
        commentType = 'text'
    }

    Invoke-AdoRequest -Method POST -Url "$baseUrl/comments?api-version=7.2-preview" -Headers $ctx.Headers -Body $commentBody
}

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $statusBody = @{ status = $Status }
    Invoke-AdoRequest -Method PATCH -Url "$($baseUrl)?api-version=7.2-preview" -Headers $ctx.Headers -Body $statusBody
}
