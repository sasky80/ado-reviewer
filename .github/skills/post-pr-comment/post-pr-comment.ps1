param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][int]$Line,
    [Parameter(Mandatory = $true)][string]$Comment
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$PullRequestId/threads?api-version=7.2-preview"

if ($FilePath -eq '-' -or [string]::IsNullOrWhiteSpace($FilePath)) {
    $body = @{
        comments = @(@{ parentCommentId = 0; content = $Comment; commentType = 'text' })
        status = 'active'
    }
}
else {
    $canonicalFilePath = ConvertTo-AdoFilePath -FilePath $FilePath
    $lineNum = if ($Line -gt 0) { $Line } else { 1 }
    $body = @{
        comments = @(@{ parentCommentId = 0; content = $Comment; commentType = 'text' })
        status = 'active'
        threadContext = @{
            filePath = $canonicalFilePath
            rightFileStart = @{ line = $lineNum; offset = 1 }
            rightFileEnd   = @{ line = $lineNum; offset = 1 }
        }
    }
}

Invoke-AdoRequest -Method POST -Url $url -Headers $ctx.Headers -Body $body
