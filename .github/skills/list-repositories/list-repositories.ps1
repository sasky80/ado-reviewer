param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories?api-version=7.2-preview"
Invoke-AdoRequest -Method GET -Url $url -Headers $ctx.Headers
