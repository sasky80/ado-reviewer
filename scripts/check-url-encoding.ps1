param(
    [switch]$Strict,
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

if ($env:URL_ENCODING_LINT_STRICT -eq 'true') {
    $Strict = $true
}

$skipDirs = @('common')
$rawVarNames = @('ORG', 'ORGANIZATION', 'PROJECT', 'REPO', 'REPO_ID', 'REPOSITORY', 'REPOSITORYID')

$findings = [System.Collections.Generic.List[object]]::new()
$scannedFiles = 0

$files = Get-ChildItem -Path $SkillsRoot -Recurse -File | Where-Object {
    ($_.Extension -in @('.sh', '.ps1')) -and ($skipDirs -notcontains $_.Directory.Name)
}

foreach ($file in $files) {
    $scannedFiles++
    $lines = Get-Content -Path $file.FullName -Encoding UTF8

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNo = $i + 1
        $line = [string]$lines[$i]

        if ($line -match 'lint:allow-unencoded-url') { continue }
        if ($line -notmatch 'https://dev\.azure\.com/') { continue }

        $bashVarMatches = [System.Text.RegularExpressions.Regex]::Matches($line, '\$\{([A-Za-z0-9_]+)\}')
        foreach ($match in $bashVarMatches) {
            $var = [string]$match.Groups[1].Value
            $normalized = $var.ToUpperInvariant()

            if (($rawVarNames -contains $normalized) -and -not $normalized.EndsWith('_ENC') -and -not $normalized.Contains('ENCODED')) {
                $findings.Add([ordered]@{
                    file = [System.IO.Path]::GetRelativePath((Get-Location).Path, $file.FullName).Replace('\\', '/')
                    line = $lineNo
                    rule = 'unencoded-url-component'
                    severity = 'warning'
                    message = "URL interpolates raw variable '{$var}' without encoded variant."
                })
            }
        }

        $psVarMatches = [System.Text.RegularExpressions.Regex]::Matches($line, '\$([A-Za-z_][A-Za-z0-9_]*)(?:\.([A-Za-z_][A-Za-z0-9_]*))?')
        foreach ($match in $psVarMatches) {
            $var = [string]$match.Groups[1].Value
            $prop = [string]$match.Groups[2].Value
            if (-not [string]::IsNullOrWhiteSpace($prop) -and $prop.Contains('Encoded')) { continue }

            $normalized = $var.ToUpperInvariant()
            if ($rawVarNames -contains $normalized) {
                $findings.Add([ordered]@{
                    file = [System.IO.Path]::GetRelativePath((Get-Location).Path, $file.FullName).Replace('\\', '/')
                    line = $lineNo
                    rule = 'unencoded-url-component'
                    severity = 'warning'
                    message = "URL interpolates raw variable '$$var' without encoded variant."
                })
            }
        }
    }
}

$dedup = [System.Collections.Generic.List[object]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new()
foreach ($finding in $findings) {
    $key = "$($finding.file)|$($finding.line)|$($finding.message)"
    if ($seen.Add($key)) {
        $dedup.Add($finding)
    }
}

$status = if ($dedup.Count -eq 0) { 'pass' } elseif ($Strict) { 'fail' } else { 'warn' }

$result = [ordered]@{
    status = $status
    strict = [bool]$Strict
    summary = [ordered]@{
        scannedFiles = $scannedFiles
        findings = $dedup.Count
    }
    findings = @($dedup)
}

$result | ConvertTo-Json -Depth 10 -Compress

if ($Strict -and $dedup.Count -gt 0) {
    exit 1
}
