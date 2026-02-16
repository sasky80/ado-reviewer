param(
    [Parameter(Mandatory = $true)][string]$SkillPath,
    [string[]]$SkillArgs = @(),
    [string]$Select,
    [switch]$Json,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$TrailingSkillArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedSkillPath = if ([System.IO.Path]::IsPathRooted($SkillPath)) {
    $SkillPath
}
else {
    Join-Path $repoRoot $SkillPath
}

if (-not (Test-Path -LiteralPath $resolvedSkillPath)) {
    Write-Error "Skill script not found: $resolvedSkillPath"
    exit 1
}

$allSkillArgs = @($SkillArgs) + @($TrailingSkillArgs)

$raw = & $resolvedSkillPath @allSkillArgs 2>&1 | Out-String
$exitCodeVar = Get-Variable -Name LASTEXITCODE -ErrorAction SilentlyContinue
$exitCode = if ($null -ne $exitCodeVar) { [int]$exitCodeVar.Value } else { 0 }
if ($exitCode -ne 0) {
    Write-Output $raw.TrimEnd()
    exit $exitCode
}

if ($Json.IsPresent -or -not [string]::IsNullOrWhiteSpace($Select)) {
    try {
        $obj = $raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Skill output is not valid JSON."
        exit 1
    }

    if (-not [string]::IsNullOrWhiteSpace($Select)) {
        $value = $obj
        foreach ($part in $Select.Split('.')) {
            if ($null -eq $value) { break }
            $prop = $value.PSObject.Properties[$part]
            if ($null -eq $prop) {
                Write-Error "Property path '$Select' not found in skill output."
                exit 1
            }
            $value = $prop.Value
        }

        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $value | ConvertTo-Json -Depth 20 -Compress
        }
        else {
            Write-Output $value
        }

        exit 0
    }

    $obj | ConvertTo-Json -Depth 20
    exit 0
}

Write-Output $raw.TrimEnd()
