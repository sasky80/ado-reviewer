param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$($PullRequestId)?api-version=7.2-preview"
Invoke-AdoRequest -Method GET -Url $url -Headers $ctx.Headers
