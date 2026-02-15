param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Version,
    [ValidateSet('branch','commit','tag')][string]$VersionType = 'branch'
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$canonicalPath = ConvertTo-AdoFilePath -FilePath $Path
$pathEncoded = UrlEncode -Value $canonicalPath
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/items?path=$pathEncoded&includeContent=true&api-version=7.2-preview"

if (-not [string]::IsNullOrWhiteSpace($Version)) {
    $versionEncoded = UrlEncode -Value $Version
    $url = "$url&versionDescriptor.version=$versionEncoded&versionDescriptor.versionType=$VersionType"
}

Invoke-AdoRequest -Method GET -Url $url -Headers $ctx.Headers
