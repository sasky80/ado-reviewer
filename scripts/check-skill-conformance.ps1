param(
    [string]$SkillsRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SkillsRoot)) {
    $SkillsRoot = Join-Path $PSScriptRoot '..\.github\skills'
}

if (-not (Test-Path $SkillsRoot -PathType Container)) {
    Write-Error "Skills root not found: $SkillsRoot"
    exit 1
}

$SKIP_DIRS = @('common')

$results = [System.Collections.Generic.List[object]]::new()
$totalPass = 0
$totalWarn = 0
$totalFail = 0

foreach ($dir in Get-ChildItem -Path $SkillsRoot -Directory | Sort-Object Name) {
    $skillName = $dir.Name
    if ($SKIP_DIRS -contains $skillName) { continue }

    $findings = [System.Collections.Generic.List[object]]::new()

    $shFile = Join-Path $dir.FullName "$skillName.sh"
    $ps1File = Join-Path $dir.FullName "$skillName.ps1"
    $skillMd = Join-Path $dir.FullName 'SKILL.md'

    $hasSh = Test-Path $shFile -PathType Leaf
    $hasPs1 = Test-Path $ps1File -PathType Leaf
    $hasMd = Test-Path $skillMd -PathType Leaf

    # --- File existence ---
    if (-not $hasSh) {
        $findings.Add([ordered]@{ level = 'error'; check = 'file-exists'; message = "Missing $skillName.sh" })
    }
    if (-not $hasPs1) {
        $findings.Add([ordered]@{ level = 'error'; check = 'file-exists'; message = "Missing $skillName.ps1" })
    }
    if (-not $hasMd) {
        $findings.Add([ordered]@{ level = 'error'; check = 'file-exists'; message = 'Missing SKILL.md' })
    }

    # --- Bash script checks ---
    if ($hasSh) {
        $shContent = Get-Content -Path $shFile -Raw -Encoding UTF8
        $shLines = $shContent -split "`n"

        # Shebang
        if ($shLines.Count -eq 0 -or -not $shLines[0].StartsWith('#!')) {
            $findings.Add([ordered]@{ level = 'error'; check = 'sh-shebang'; message = 'Missing shebang line' })
        }
        elseif ($shLines[0] -notmatch '#!/usr/bin/env bash') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'sh-shebang'; message = "Non-standard shebang: $($shLines[0])" })
        }

        # set -euo pipefail
        if ($shContent -notmatch 'set -euo pipefail') {
            $findings.Add([ordered]@{ level = 'error'; check = 'sh-strict-mode'; message = "Missing 'set -euo pipefail'" })
        }

        # Argument count guard
        if ($shContent -notmatch 'if\s+\[\[?\s+\$#\s+-lt') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'sh-arg-guard'; message = 'Missing argument count guard (if [[ $# -lt ...]])' })
        }

        # Source ado-utils.sh
        if ($shContent -notmatch 'ado-utils\.sh') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'sh-source-utils'; message = 'Does not source ado-utils.sh' })
        }

        # ado_init call
        if ($shContent -notmatch 'ado_init') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'sh-ado-init'; message = 'Missing ado_init call' })
        }

        # curl flags
        if ($shContent -match 'curl') {
            if ($shContent -notmatch '--fail-with-body' -and $shContent -notmatch '--fail') {
                $findings.Add([ordered]@{ level = 'warn'; check = 'sh-curl-fail'; message = 'curl without --fail or --fail-with-body flag' })
            }
            if ($shContent -notmatch '--max-time') {
                $findings.Add([ordered]@{ level = 'warn'; check = 'sh-curl-timeout'; message = 'curl without --max-time flag' })
            }
        }

        # Usage to stderr
        if ($shContent -match 'echo\s+"Usage:' -and $shContent -notmatch '>&2') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'sh-usage-stderr'; message = 'Usage message not redirected to stderr (>&2)' })
        }
    }

    # --- PowerShell script checks ---
    if ($hasPs1) {
        $ps1Content = Get-Content -Path $ps1File -Raw -Encoding UTF8

        # param block
        if ($ps1Content -notmatch '(?m)^\s*param\s*\(') {
            $findings.Add([ordered]@{ level = 'error'; check = 'ps1-param-block'; message = 'Missing param() block' })
        }

        # Dot-source AdoSkillUtils.ps1
        if ($ps1Content -notmatch 'AdoSkillUtils\.ps1') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'ps1-source-utils'; message = 'Does not dot-source AdoSkillUtils.ps1' })
        }

        # New-AdoContext
        if ($ps1Content -notmatch 'New-AdoContext') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'ps1-ado-context'; message = 'Missing New-AdoContext call' })
        }

        # Mandatory parameters
        if ($ps1Content -notmatch '\[Parameter\(Mandatory') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'ps1-mandatory'; message = 'No [Parameter(Mandatory)] attributes found' })
        }
    }

    # --- SKILL.md checks ---
    if ($hasMd) {
        $mdContent = Get-Content -Path $skillMd -Raw -Encoding UTF8

        # Front matter — YAML front matter delimited by ---
        if ($mdContent -notmatch '(?m)^---\s*\r?\nname:\s*\S') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'md-frontmatter'; message = 'Missing YAML front matter (--- / name: ...)' })
        }

        # Arguments table
        if ($mdContent -notmatch '\|\s*#' -and $mdContent -notmatch '\|\s*Name') {
            $findings.Add([ordered]@{ level = 'warn'; check = 'md-args-table'; message = 'Missing Arguments table' })
        }

        # Examples section
        if ($mdContent -notmatch '## Examples?' ) {
            $findings.Add([ordered]@{ level = 'warn'; check = 'md-examples'; message = 'Missing Examples section' })
        }

        # Platform note
        if ($mdContent -notmatch 'Windows' -or ($mdContent -notmatch 'macOS' -and $mdContent -notmatch 'Linux')) {
            $findings.Add([ordered]@{ level = 'warn'; check = 'md-platform-note'; message = 'Missing platform note (Windows/macOS/Linux)' })
        }
    }

    # Tally
    $errors = @($findings | Where-Object { $_.level -eq 'error' }).Count
    $warns = @($findings | Where-Object { $_.level -eq 'warn' }).Count
    $status = if ($errors -eq 0 -and $warns -eq 0) { 'pass' } elseif ($errors -eq 0) { 'warn' } else { 'fail' }

    switch ($status) {
        'pass' { $totalPass++ }
        'warn' { $totalWarn++ }
        'fail' { $totalFail++ }
    }

    $results.Add([ordered]@{
        skill    = $skillName
        status   = $status
        errors   = $errors
        warnings = $warns
        findings = @($findings)
    })
}

$output = [ordered]@{
    results = @($results)
    summary = [ordered]@{
        total = $results.Count
        pass  = $totalPass
        warn  = $totalWarn
        fail  = $totalFail
    }
}

$output | ConvertTo-Json -Depth 10
