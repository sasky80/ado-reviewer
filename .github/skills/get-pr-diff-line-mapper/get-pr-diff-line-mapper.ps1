param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId,
    [Parameter(Mandatory = $true)][string]$IterationId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId
$authHeader = [string]$ctx.Headers.Authorization
$authBasic = $authHeader -replace '^Basic\s+', ''

$pythonCommand = $null
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCommand = 'python3'
}
elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCommand = 'python'
}
else {
    Write-Error 'python3 (or python) is required for get-pr-diff-line-mapper.ps1'
    exit 1
}

$pyScript = Join-Path $PSScriptRoot 'pr-diff-line-mapper.py'

& $pythonCommand $pyScript `
    --org-enc $ctx.OrganizationEncoded `
    --project-enc $ctx.ProjectEncoded `
    --repo-enc $ctx.RepositoryEncoded `
    --pull-request-id $PullRequestId `
    --iteration-id $IterationId `
    --auth-basic $authBasic

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
