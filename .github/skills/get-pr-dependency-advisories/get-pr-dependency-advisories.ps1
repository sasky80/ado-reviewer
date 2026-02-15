param(
    [Parameter(Mandatory = $true)][string]$Organization,
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$RepositoryId,
    [Parameter(Mandatory = $true)][string]$PullRequestId,
    [string]$IterationId,
    [int]$PerPage = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PerPage -lt 1 -or $PerPage -gt 100) {
    Write-Error 'PerPage must be between 1 and 100'
    exit 1
}

. (Join-Path $PSScriptRoot '..\common\AdoSkillUtils.ps1')

$ghToken = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'Process')
if ([string]::IsNullOrWhiteSpace($ghToken)) { $ghToken = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'User') }
if ([string]::IsNullOrWhiteSpace($ghToken)) { $ghToken = [Environment]::GetEnvironmentVariable('GH_SEC_PAT', 'Machine') }
if ([string]::IsNullOrWhiteSpace($ghToken)) {
    Write-Error 'Environment variable GH_SEC_PAT is not set'
    exit 1
}

$ctx = New-AdoContext -Organization $Organization -Project $Project -RepositoryId $RepositoryId

$prUrl = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$($PullRequestId)?api-version=7.2-preview"
$pr = Invoke-RestMethod -Method GET -Uri $prUrl -Headers $ctx.Headers
$sourceBranch = [string]$pr.sourceRefName
if ($sourceBranch.StartsWith('refs/heads/')) {
    $sourceBranch = $sourceBranch.Substring(11)
}

if ([string]::IsNullOrWhiteSpace($IterationId)) {
    $iterationsUrl = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$($PullRequestId)/iterations?api-version=7.2-preview"
    $iterations = Invoke-RestMethod -Method GET -Uri $iterationsUrl -Headers $ctx.Headers
    $maxId = 0
    foreach ($it in $iterations.value) {
        $id = [int]$it.id
        if ($id -gt $maxId) { $maxId = $id }
    }
    $IterationId = [string]$maxId
}

if ([string]::IsNullOrWhiteSpace($IterationId) -or $IterationId -eq '0') {
    [pscustomobject]@{
        manifestFiles = @()
        dependencies = @()
        advisories = @()
        dependenciesChecked = 0
        advisoriesFound = 0
        highOrCritical = 0
    } | ConvertTo-Json -Depth 100 -Compress
    exit 0
}

$changesUrl = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/pullRequests/$($PullRequestId)/iterations/$($IterationId)/changes?api-version=7.2-preview"
$changes = Invoke-RestMethod -Method GET -Uri $changesUrl -Headers $ctx.Headers

$manifestPaths = New-Object System.Collections.Generic.List[string]
foreach ($entry in $changes.changeEntries) {
    $path = [string]$entry.item.path
    if ([string]::IsNullOrWhiteSpace($path)) { continue }
    $leaf = [System.IO.Path]::GetFileName($path).ToLowerInvariant()
    if (
        $leaf -eq 'package.json' -or
        $leaf -eq 'package-lock.json' -or
        $leaf -eq 'requirements.txt' -or
        $leaf -eq 'requirements-dev.txt' -or
        $leaf -eq 'poetry.lock' -or
        $leaf -eq 'go.mod' -or
        $leaf -eq 'cargo.lock'
    ) {
        if (-not $manifestPaths.Contains($path)) {
            $manifestPaths.Add($path)
        }
    }
}

if ($manifestPaths.Count -eq 0) {
    [pscustomobject]@{
        manifestFiles = @()
        dependencies = @()
        advisories = @()
        dependenciesChecked = 0
        advisoriesFound = 0
        highOrCritical = 0
    } | ConvertTo-Json -Depth 100 -Compress
    exit 0
}

$dependencies = New-Object System.Collections.Generic.List[object]
$depKeys = New-Object System.Collections.Generic.HashSet[string]

foreach ($path in $manifestPaths) {
    $pathEncoded = UrlEncode -Value $path
    $branchEncoded = UrlEncode -Value $sourceBranch
    $fileUrl = "https://dev.azure.com/$($ctx.OrganizationEncoded)/$($ctx.ProjectEncoded)/_apis/git/repositories/$($ctx.RepositoryEncoded)/items?path=$pathEncoded&includeContent=true&versionDescriptor.version=$branchEncoded&versionDescriptor.versionType=branch&api-version=7.2-preview"
    try {
        $fileObj = Invoke-RestMethod -Method GET -Uri $fileUrl -Headers $ctx.Headers
    }
    catch {
        continue
    }

    $content = [string]$fileObj.content
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    $leaf = [System.IO.Path]::GetFileName($path).ToLowerInvariant()
    if ($leaf -eq 'package.json') {
        try {
            $pkg = $content | ConvertFrom-Json
        }
        catch {
            continue
        }

        foreach ($section in @('dependencies', 'devDependencies', 'optionalDependencies', 'peerDependencies')) {
            $dict = $pkg.$section
            if (-not $dict) { continue }
            foreach ($prop in $dict.PSObject.Properties) {
                $name = [string]$prop.Name
                $version = [string]$prop.Value
                $key = "npm|$name|$version"
                if ($depKeys.Add($key)) {
                    $dependencies.Add([pscustomobject]@{ ecosystem = 'npm'; package = $name; version = $version; filePath = $path })
                }
            }
        }
    }
    elseif ($leaf -eq 'package-lock.json') {
        try {
            $lock = $content | ConvertFrom-Json
        }
        catch {
            continue
        }

        if ($lock.packages) {
            foreach ($prop in $lock.packages.PSObject.Properties) {
                $pkgPath = [string]$prop.Name
                $node = $prop.Value
                if ($null -eq $node) { continue }

                $name = [string]$node.name
                if ([string]::IsNullOrWhiteSpace($name) -and $pkgPath -like '*node_modules/*') {
                    $name = $pkgPath.Substring($pkgPath.LastIndexOf('node_modules/') + 13)
                }
                if ([string]::IsNullOrWhiteSpace($name)) { continue }

                $version = [string]$node.version
                $key = "npm|$name|$version"
                if ($depKeys.Add($key)) {
                    $dependencies.Add([pscustomobject]@{ ecosystem = 'npm'; package = $name; version = $version; filePath = $path })
                }
            }
        }

        if ($lock.dependencies) {
            foreach ($prop in $lock.dependencies.PSObject.Properties) {
                $name = [string]$prop.Name
                $node = $prop.Value
                $version = ''
                if ($node -and $node.PSObject.Properties['version']) {
                    $version = [string]$node.version
                }
                $key = "npm|$name|$version"
                if ($depKeys.Add($key)) {
                    $dependencies.Add([pscustomobject]@{ ecosystem = 'npm'; package = $name; version = $version; filePath = $path })
                }
            }
        }
    }
    else {
        if ($leaf -eq 'requirements.txt' -or $leaf -eq 'requirements-dev.txt') {
            foreach ($line in ($content -split "`r?`n")) {
                $trim = $line -replace '#.*$', ''
                $trim = $trim.Trim()
                if ([string]::IsNullOrWhiteSpace($trim) -or $trim.StartsWith('-')) { continue }

                $match = [System.Text.RegularExpressions.Regex]::Match($trim, '^(?<name>[A-Za-z0-9_.-]+)\s*(?:(==|~=|>=|<=|!=|>|<)\s*(?<ver>[^;\s]+))?')
                if (-not $match.Success) { continue }

                $name = $match.Groups['name'].Value
                $version = $match.Groups['ver'].Value
                $key = "pip|$name|$version"
                if ($depKeys.Add($key)) {
                    $dependencies.Add([pscustomobject]@{ ecosystem = 'pip'; package = $name; version = $version; filePath = $path })
                }
            }
        }
        elseif ($leaf -eq 'poetry.lock') {
            $name = ''
            $version = ''
            foreach ($line in ($content -split "`r?`n")) {
                $trim = $line.Trim()
                if ($trim -eq '[[package]]') {
                    if (-not [string]::IsNullOrWhiteSpace($name)) {
                        $key = "pip|$name|$version"
                        if ($depKeys.Add($key)) {
                            $dependencies.Add([pscustomobject]@{ ecosystem = 'pip'; package = $name; version = $version; filePath = $path })
                        }
                    }
                    $name = ''
                    $version = ''
                    continue
                }

                $mName = [System.Text.RegularExpressions.Regex]::Match($trim, '^name\s*=\s*"([^"]+)"$')
                if ($mName.Success) {
                    $name = $mName.Groups[1].Value
                    continue
                }

                $mVersion = [System.Text.RegularExpressions.Regex]::Match($trim, '^version\s*=\s*"([^"]+)"$')
                if ($mVersion.Success) {
                    $version = $mVersion.Groups[1].Value
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($name)) {
                $key = "pip|$name|$version"
                if ($depKeys.Add($key)) {
                    $dependencies.Add([pscustomobject]@{ ecosystem = 'pip'; package = $name; version = $version; filePath = $path })
                }
            }
        }
        elseif ($leaf -eq 'go.mod') {
            $inRequire = $false
            foreach ($line in ($content -split "`r?`n")) {
                $trim = ($line -replace '//.*$', '').Trim()
                if ([string]::IsNullOrWhiteSpace($trim)) { continue }

                if ($trim -eq 'require (') { $inRequire = $true; continue }
                if ($inRequire -and $trim -eq ')') { $inRequire = $false; continue }
                if ($trim.StartsWith('replace ') -or $trim.StartsWith('exclude ')) { continue }

                $matchRequire = [System.Text.RegularExpressions.Regex]::Match($trim, '^require\s+([^\s]+)\s+([^\s]+)$')
                if ($matchRequire.Success) {
                    $name = $matchRequire.Groups[1].Value
                    $version = $matchRequire.Groups[2].Value
                    $key = "go|$name|$version"
                    if ($depKeys.Add($key)) {
                        $dependencies.Add([pscustomobject]@{ ecosystem = 'go'; package = $name; version = $version; filePath = $path })
                    }
                    continue
                }

                if ($inRequire) {
                    $matchBlock = [System.Text.RegularExpressions.Regex]::Match($trim, '^([^\s]+)\s+([^\s]+)$')
                    if ($matchBlock.Success) {
                        $name = $matchBlock.Groups[1].Value
                        $version = $matchBlock.Groups[2].Value
                        $key = "go|$name|$version"
                        if ($depKeys.Add($key)) {
                            $dependencies.Add([pscustomobject]@{ ecosystem = 'go'; package = $name; version = $version; filePath = $path })
                        }
                    }
                }
            }
        }
        elseif ($leaf -eq 'cargo.lock') {
            $name = ''
            $version = ''
            foreach ($line in ($content -split "`r?`n")) {
                $trim = $line.Trim()
                if ($trim -eq '[[package]]') {
                    if (-not [string]::IsNullOrWhiteSpace($name)) {
                        $key = "rust|$name|$version"
                        if ($depKeys.Add($key)) {
                            $dependencies.Add([pscustomobject]@{ ecosystem = 'rust'; package = $name; version = $version; filePath = $path })
                        }
                    }
                    $name = ''
                    $version = ''
                    continue
                }

                $mName = [System.Text.RegularExpressions.Regex]::Match($trim, '^name\s*=\s*"([^"]+)"$')
                if ($mName.Success) {
                    $name = $mName.Groups[1].Value
                    continue
                }

                $mVersion = [System.Text.RegularExpressions.Regex]::Match($trim, '^version\s*=\s*"([^"]+)"$')
                if ($mVersion.Success) {
                    $version = $mVersion.Groups[1].Value
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($name)) {
                $key = "rust|$name|$version"
                if ($depKeys.Add($key)) {
                    $dependencies.Add([pscustomobject]@{ ecosystem = 'rust'; package = $name; version = $version; filePath = $path })
                }
            }
        }
    }
}

$ghHeaders = @{
    Authorization = "Bearer $ghToken"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

$advisories = New-Object System.Collections.Generic.List[object]

foreach ($dep in $dependencies) {
    $affects = if ([string]::IsNullOrWhiteSpace($dep.version)) { $dep.package } else { "$($dep.package)@$($dep.version)" }
    $ghUrl = "https://api.github.com/advisories?ecosystem=$([System.Uri]::EscapeDataString($dep.ecosystem))&affects=$([System.Uri]::EscapeDataString($affects))&per_page=$PerPage"

    try {
        $response = Invoke-RestMethod -Method GET -Uri $ghUrl -Headers $ghHeaders
    }
    catch {
        continue
    }

    foreach ($adv in $response) {
        $vulnerableVersionRange = $null
        $firstPatchedVersion = $null
        foreach ($v in $adv.vulnerabilities) {
            if ($null -eq $v.package) { continue }
            if ([string]$v.package.name -eq [string]$dep.package -and [string]$v.package.ecosystem -eq [string]$dep.ecosystem) {
                $vulnerableVersionRange = [string]$v.vulnerable_version_range
                $firstPatchedVersion = [string]$v.first_patched_version
                break
            }
        }

        $advisories.Add([pscustomobject]@{
            filePath = $dep.filePath
            ecosystem = $dep.ecosystem
            package = $dep.package
            version = $dep.version
            ghsa_id = [string]$adv.ghsa_id
            cve_id = [string]$adv.cve_id
            severity = [string]$adv.severity
            summary = [string]$adv.summary
            html_url = [string]$adv.html_url
            vulnerable_version_range = $vulnerableVersionRange
            first_patched_version = $firstPatchedVersion
        })
    }
}

$highOrCritical = 0
foreach ($a in $advisories) {
    $sev = [string]$a.severity
    if ($sev -eq 'high' -or $sev -eq 'critical') {
        $highOrCritical++
    }
}

[pscustomobject]@{
    manifestFiles = @($manifestPaths)
    dependencies = @($dependencies)
    advisories = @($advisories)
    dependenciesChecked = $dependencies.Count
    advisoriesFound = $advisories.Count
    highOrCritical = $highOrCritical
} | ConvertTo-Json -Depth 100 -Compress
