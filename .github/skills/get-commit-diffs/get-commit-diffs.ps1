param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$BaseVersion,
    [Parameter(Mandatory = $true)][string]$TargetVersion,
    [ValidateSet('branch','commit','tag')][string]$BaseVersionType = 'commit',
    [ValidateSet('branch','commit','tag')][string]$TargetVersionType = 'commit'
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$baseVersionEncoded = UrlEncode -Value $BaseVersion
$targetVersionEncoded = UrlEncode -Value $TargetVersion
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/diffs/commits?baseVersion=$baseVersionEncoded&baseVersionType=$BaseVersionType&targetVersion=$targetVersionEncoded&targetVersionType=$TargetVersionType&api-version=7.2-preview"
Invoke-AdoRequest -Method GET -Url $url -Headers $ctx.Headers
