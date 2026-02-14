# Template validation wrapper for Windows/PowerShell.
# Copy this file (for example to scripts/validate-skill-local.ps1)
# and replace values below with your own Azure DevOps context.

$Org = '<your_org>'
$Project = '<your_project_name_or_id>'
$Repo = '<your_repository_name_or_id>'
$Pr = '<your_pr_id>'
$Iteration = '<your_iteration_id>'
$TestedFilePath = '</path/to/file/in/repository>'
$BranchBase = '<base_branch>'
$BranchTarget = '<target_branch>'

$rootDir = Split-Path -Parent $PSScriptRoot
Set-Location $rootDir

# Validation is non-mutating by default.
# To include mutating checks (e.g. accept-pr, approve-with-suggestions,
# wait-for-author, reject-pr, reset-feedback), run with:
# $env:ENABLE_MUTATING_CHECKS='true'; .\scripts\validate-skill-local.ps1

& "$rootDir\scripts\validate-skills.ps1" $Org $Project $Repo $Pr $Iteration $TestedFilePath $BranchBase $BranchTarget
