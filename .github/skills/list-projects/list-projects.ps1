param(
    [Parameter(Mandatory = $true)][string]$Organization
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/_apis/projects?api-version=7.2-preview"
Invoke-AdoRequest -Method GET -Url $url -Headers $ctx.Headers
