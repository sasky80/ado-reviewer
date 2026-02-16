param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$Version,
    [ValidateSet('branch','commit','tag')][string]$VersionType = 'branch',
    [Parameter(Mandatory = $true)][string]$PathsJson
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$versionEncoded = UrlEncode -Value $Version

$paths = @($PathsJson | ConvertFrom-Json)

if ($paths.Count -eq 0) {
    Write-Json -InputObject ([ordered]@{ results = @(); succeeded = 0; failed = 0; total = 0 })
    return
}

$results = [System.Collections.Generic.List[object]]::new()
$succeeded = 0
$failed = 0

foreach ($filePath in $paths) {
    $canonicalPath = ConvertTo-AdoFilePath -FilePath $filePath
    $pathEncoded = UrlEncode -Value $canonicalPath

    $url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/items?path=$pathEncoded&includeContent=true&api-version=7.2-preview"
    $url = "$url&versionDescriptor.version=$versionEncoded&versionDescriptor.versionType=$VersionType"

    $entry = [ordered]@{ path = $filePath }

    try {
        $response = Invoke-RestMethod -Method GET -Uri $url -Headers $ctx.Headers
        $entry.status = 'ok'
        $entry.content = if ($null -ne $response.content) { $response.content } else { '' }
        $entry.commitId = if ($null -ne $response.commitId) { $response.commitId } else { '' }
        $entry.objectId = if ($null -ne $response.objectId) { $response.objectId } else { '' }
        $succeeded++
    }
    catch {
        $entry.status = 'error'
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
            $errorMessage = $_.ErrorDetails.Message
        }
        $entry.error = $errorMessage
        $failed++
    }

    $results.Add([pscustomobject]$entry)
}

$output = [ordered]@{
    results   = @($results)
    succeeded = $succeeded
    failed    = $failed
    total     = $results.Count
}

Write-Json -InputObject $output
