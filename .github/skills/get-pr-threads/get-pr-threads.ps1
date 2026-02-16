param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId,
    [string]$StatusFilter,
    [ValidateSet('true','false')][string]$ExcludeSystem = 'false'
)

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$url = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$PullRequestId/threads?api-version=7.2-preview"

$rawResponse = Invoke-RestMethod -Method GET -Uri $url -Headers $ctx.Headers

$applyFilter = (-not [string]::IsNullOrWhiteSpace($StatusFilter)) -or ($ExcludeSystem -eq 'true')

if ($applyFilter) {
    $threads = @($rawResponse.value)
    $filtered = [System.Collections.Generic.List[object]]::new()

    foreach ($thread in $threads) {
        # Exclude system threads
        if ($ExcludeSystem -eq 'true') {
            $props = $thread.properties
            if ($null -ne $props) {
                $propNames = @()
                if ($props -is [hashtable]) {
                    $propNames = $props.Keys
                } elseif ($props.PSObject -and $props.PSObject.Properties) {
                    $propNames = @($props.PSObject.Properties | ForEach-Object { $_.Name })
                }

                $hasCodeReview = $propNames | Where-Object { $_ -like 'CodeReview*' }
                if ($hasCodeReview) { continue }
            }

            $comments = @($thread.comments)
            if ($comments.Count -gt 0) {
                $allSystem = $true
                foreach ($c in $comments) {
                    $cType = ''
                    if ($c.commentType) { $cType = [string]$c.commentType }
                    $displayName = ''
                    if ($c.author -and $c.author.displayName) { $displayName = [string]$c.author.displayName }

                    if ($cType -ne 'system' -and -not $displayName.StartsWith('Microsoft.')) {
                        $allSystem = $false
                        break
                    }
                }

                if ($allSystem) { continue }
            }
        }

        # Filter by status
        if (-not [string]::IsNullOrWhiteSpace($StatusFilter)) {
            $threadStatus = ''
            if ($thread.status) { $threadStatus = [string]$thread.status }
            if ($threadStatus -ne $StatusFilter) { continue }
        }

        $filtered.Add($thread)
    }

    $result = [ordered]@{
        value = @($filtered)
        count = $filtered.Count
    }
    Write-Json -InputObject $result
}
else {
    Write-Json -InputObject $rawResponse
}
