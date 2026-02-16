param(
    [Parameter(Mandatory = $true)][string]$Org,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)][string]$Pr,
    [Parameter(Mandatory = $true)][string]$Iteration,
    [string]$TestedFilePath = $env:TESTED_FILE_PATH,
    [string]$BranchBase = $env:BRANCH_BASE,
    [string]$BranchTarget = $env:BRANCH_TARGET,
    [switch]$IncludeNugetRegression
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\.github\skills\common\AdoSkillUtils.ps1')

$patSuffix = Get-PatSuffix -Organization $Org
$patVar = "ADO_PAT_$patSuffix"
$pat = [Environment]::GetEnvironmentVariable($patVar, 'Process')
if ([string]::IsNullOrWhiteSpace($pat)) { $pat = [Environment]::GetEnvironmentVariable($patVar, 'User') }
if ([string]::IsNullOrWhiteSpace($pat)) { $pat = [Environment]::GetEnvironmentVariable($patVar, 'Machine') }
if ([string]::IsNullOrWhiteSpace($pat)) {
    Write-Error "ERROR: missing PAT env var: $patVar"
    exit 1
}

function Get-OrDefault {
    param(
        [string]$Value,
        [string]$DefaultValue = '<unset>'
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $DefaultValue
    }

    return $Value
}

if (-not [string]::IsNullOrWhiteSpace($TestedFilePath) -or -not [string]::IsNullOrWhiteSpace($BranchBase) -or -not [string]::IsNullOrWhiteSpace($BranchTarget)) {
    Write-Output "Validation context: file=$(Get-OrDefault -Value $TestedFilePath), base=$(Get-OrDefault -Value $BranchBase), target=$(Get-OrDefault -Value $BranchTarget)"
}
else {
    Write-Output 'Validation context: repository-specific checks disabled (set tested_file_path + branch_base + branch_target to enable)'
}

$passCount = 0
$failCount = 0

function Test-SkillCheck {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$SkillArgs = @()
    )

    Write-Output "--- $Name ---"
    $output = & $ScriptPath @SkillArgs 2>&1 | Out-String
    $exitCodeVar = Get-Variable -Name LASTEXITCODE -ErrorAction SilentlyContinue
    $exitCode = if ($null -ne $exitCodeVar) { [int]$exitCodeVar.Value } else { 0 }
    if ($exitCode -ne 0) {
        Write-Output 'FAIL (command error)'
        $output.Trim().Split([Environment]::NewLine) | Select-Object -First 8 | ForEach-Object { Write-Output $_ }
        $script:failCount++
        return
    }

    try {
        $null = $output | ConvertFrom-Json
        Write-Output 'PASS'
        $script:passCount++
    }
    catch {
        Write-Output 'FAIL (invalid JSON)'
        $output.Trim().Split([Environment]::NewLine) | Select-Object -First 8 | ForEach-Object { Write-Output $_ }
        $script:failCount++
    }
}

$skillsRoot = Join-Path $PSScriptRoot '..\.github\skills'

Test-SkillCheck -Name 'list-projects' -ScriptPath (Join-Path $skillsRoot 'list-projects\list-projects.ps1') -SkillArgs @($Org)
Test-SkillCheck -Name 'list-repositories' -ScriptPath (Join-Path $skillsRoot 'list-repositories\list-repositories.ps1') -SkillArgs @($Org, $Project)
Test-SkillCheck -Name 'get-pr-details' -ScriptPath (Join-Path $skillsRoot 'get-pr-details\get-pr-details.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
Test-SkillCheck -Name 'get-pr-iterations' -ScriptPath (Join-Path $skillsRoot 'get-pr-iterations\get-pr-iterations.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
Test-SkillCheck -Name 'get-pr-changes' -ScriptPath (Join-Path $skillsRoot 'get-pr-changes\get-pr-changes.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr, $Iteration)
Test-SkillCheck -Name 'get-pr-changed-files' -ScriptPath (Join-Path $skillsRoot 'get-pr-changed-files\get-pr-changed-files.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr, $Iteration)
Test-SkillCheck -Name 'get-pr-threads' -ScriptPath (Join-Path $skillsRoot 'get-pr-threads\get-pr-threads.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
Test-SkillCheck -Name 'get-pr-threads (filtered)' -ScriptPath (Join-Path $skillsRoot 'get-pr-threads\get-pr-threads.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr, 'active', 'true')
$previousStrictSetting = $env:URL_ENCODING_LINT_STRICT
$env:URL_ENCODING_LINT_STRICT = 'true'
try {
    Test-SkillCheck -Name 'check-url-encoding' -ScriptPath (Join-Path $PSScriptRoot 'check-url-encoding.ps1') -SkillArgs @()
}
finally {
    if ($null -eq $previousStrictSetting) {
        Remove-Item Env:URL_ENCODING_LINT_STRICT -ErrorAction SilentlyContinue
    }
    else {
        $env:URL_ENCODING_LINT_STRICT = $previousStrictSetting
    }
}

$ghToken = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'Process')
if ([string]::IsNullOrWhiteSpace($ghToken)) { $ghToken = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'User') }
if ([string]::IsNullOrWhiteSpace($ghToken)) { $ghToken = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'Machine') }
if (-not [string]::IsNullOrWhiteSpace($ghToken)) {
    Test-SkillCheck -Name 'get-github-advisories' -ScriptPath (Join-Path $skillsRoot 'get-github-advisories\get-github-advisories.ps1') -SkillArgs @('npm', 'lodash', '4.17.20', 'high', '10')
    Test-SkillCheck -Name 'get-pr-dependency-advisories' -ScriptPath (Join-Path $skillsRoot 'get-pr-dependency-advisories\get-pr-dependency-advisories.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr, $Iteration)
}
else {
    Write-Output '--- get-github-advisories ---'
    Write-Output 'SKIP (GH_SEC_PAT is not set)'
    Write-Output '--- get-pr-dependency-advisories ---'
    Write-Output 'SKIP (GH_SEC_PAT is not set)'
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    Test-SkillCheck -Name 'check-deprecated-dependencies (npm)' -ScriptPath (Join-Path $skillsRoot 'check-deprecated-dependencies\check-deprecated-dependencies.ps1') -SkillArgs @('npm', 'lodash', '4.17.21')
}
else {
    Write-Output '--- check-deprecated-dependencies (npm) ---'
    Write-Output 'SKIP (npm is not available)'
}

Test-SkillCheck -Name 'check-deprecated-dependencies (pip)' -ScriptPath (Join-Path $skillsRoot 'check-deprecated-dependencies\check-deprecated-dependencies.ps1') -SkillArgs @('pip', 'requests', '2.31.0')
Test-SkillCheck -Name 'check-deprecated-dependencies (nuget)' -ScriptPath (Join-Path $skillsRoot 'check-deprecated-dependencies\check-deprecated-dependencies.ps1') -SkillArgs @('nuget', 'Newtonsoft.Json', '13.0.3')

if (-not [string]::IsNullOrWhiteSpace($TestedFilePath) -and -not [string]::IsNullOrWhiteSpace($BranchBase) -and -not [string]::IsNullOrWhiteSpace($BranchTarget)) {
    Test-SkillCheck -Name 'get-file-content' -ScriptPath (Join-Path $skillsRoot 'get-file-content\get-file-content.ps1') -SkillArgs @($Org, $Project, $Repo, $TestedFilePath, $BranchTarget, 'branch')
    Test-SkillCheck -Name 'get-multiple-files' -ScriptPath (Join-Path $skillsRoot 'get-multiple-files\get-multiple-files.ps1') -SkillArgs @($Org, $Project, $Repo, $BranchTarget, 'branch', "[`"$TestedFilePath`"]")
    Test-SkillCheck -Name 'get-commit-diffs' -ScriptPath (Join-Path $skillsRoot 'get-commit-diffs\get-commit-diffs.ps1') -SkillArgs @($Org, $Project, $Repo, $BranchBase, $BranchTarget, 'branch', 'branch')
}
else {
    Write-Output '--- get-file-content ---'
    Write-Output 'SKIP (repository-specific inputs missing; provide tested_file_path + branch_base + branch_target)'
    Write-Output '--- get-multiple-files ---'
    Write-Output 'SKIP (repository-specific inputs missing; provide tested_file_path + branch_base + branch_target)'
    Write-Output '--- get-commit-diffs ---'
    Write-Output 'SKIP (repository-specific inputs missing; provide branch_base + branch_target)'
}

if ($env:ENABLE_MUTATING_CHECKS -eq 'true') {
    Test-SkillCheck -Name 'post-pr-comment' -ScriptPath (Join-Path $skillsRoot 'post-pr-comment\post-pr-comment.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr, '-', '0', '[validate-skills] smoke test comment')
    Test-SkillCheck -Name 'approve-with-suggestions' -ScriptPath (Join-Path $skillsRoot 'approve-with-suggestions\approve-with-suggestions.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
    Test-SkillCheck -Name 'wait-for-author' -ScriptPath (Join-Path $skillsRoot 'wait-for-author\wait-for-author.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
    Test-SkillCheck -Name 'reject-pr' -ScriptPath (Join-Path $skillsRoot 'reject-pr\reject-pr.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
    Test-SkillCheck -Name 'reset-feedback' -ScriptPath (Join-Path $skillsRoot 'reset-feedback\reset-feedback.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
    Test-SkillCheck -Name 'accept-pr' -ScriptPath (Join-Path $skillsRoot 'accept-pr\accept-pr.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr)
}
else {
    Write-Output '--- post-pr-comment ---'
    Write-Output 'SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)'
    Write-Output '--- approve-with-suggestions ---'
    Write-Output 'SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)'
    Write-Output '--- wait-for-author ---'
    Write-Output 'SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)'
    Write-Output '--- reject-pr ---'
    Write-Output 'SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)'
    Write-Output '--- reset-feedback ---'
    Write-Output 'SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)'
    Write-Output '--- accept-pr ---'
    Write-Output 'SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)'
}

$threadsRaw = & (Join-Path $skillsRoot 'get-pr-threads\get-pr-threads.ps1') $Org $Project $Repo $Pr
$threadId = ''
try {
    $threadsObj = $threadsRaw | ConvertFrom-Json
    foreach ($thread in $threadsObj.value) {
        $isSystem = $false
        foreach ($comment in $thread.comments) {
            $displayName = ''
            if ($comment.author -and $comment.author.displayName) {
                $displayName = [string]$comment.author.displayName
            }

            if ($displayName -like 'Microsoft.*') {
                $isSystem = $true
                break
            }
        }

        if (-not $isSystem) {
            $threadId = [string]$thread.id
            break
        }
    }
}
catch {
    $threadId = ''
}

if (-not [string]::IsNullOrWhiteSpace($threadId)) {
    Test-SkillCheck -Name 'update-pr-thread' -ScriptPath (Join-Path $skillsRoot 'update-pr-thread\update-pr-thread.ps1') -SkillArgs @($Org, $Project, $Repo, $Pr, $threadId, '-', 'active')
}
else {
    Write-Output '--- update-pr-thread ---'
    Write-Output 'SKIP (no comment threads found to test against)'
}

if ($IncludeNugetRegression.IsPresent) {
    Test-SkillCheck -Name 'nuget-regression' -ScriptPath (Join-Path $PSScriptRoot 'regression-check-deprecated-nuget.ps1') -SkillArgs @()
}
else {
    Write-Output '--- nuget-regression ---'
    Write-Output 'SKIP (optional; pass -IncludeNugetRegression to enable)'
}

Write-Output ''
if ($failCount -eq 0) {
    Write-Output "Result: $passCount passed, 0 failed"
    exit 0
}

Write-Output "Result: $passCount passed, $failCount failed"
exit 1
