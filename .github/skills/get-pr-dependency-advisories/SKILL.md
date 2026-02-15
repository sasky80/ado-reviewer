---
name: get-pr-dependency-advisories
description: Scan changed dependency manifests in a PR and query GitHub Advisory Database for discovered dependencies automatically.
---

# Get PR Dependency Advisories

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run [get-pr-dependency-advisories.sh](./get-pr-dependency-advisories.sh) on macOS/Linux or [get-pr-dependency-advisories.ps1](./get-pr-dependency-advisories.ps1) on Windows.

## Authentication

- Azure DevOps PAT: `ADO_PAT_<normalized_org>`
- GitHub PAT: `GH_SEC_PAT`

## What it does

1. Resolves source branch from PR metadata.
2. Finds changed dependency manifest files in the selected PR iteration.
3. Extracts dependencies from supported manifests.
4. Queries `https://api.github.com/advisories` for each dependency.
5. Returns one consolidated JSON report.

## Supported changed manifests

- `package.json` (`dependencies`, `devDependencies`, `optionalDependencies`, `peerDependencies`)
- `package-lock.json`
- `requirements.txt`
- `requirements-dev.txt`
- `poetry.lock`
- `go.mod`
- `Cargo.lock`

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | iterationId | No | PR iteration ID (defaults to latest) |
| 6 | per_page | No | Max advisories per dependency query (1..100, default: 20) |

## Examples

```bash
bash .github/skills/get-pr-dependency-advisories/get-pr-dependency-advisories.sh myorg MyProject MyRepo 42
```

```powershell
pwsh -ExecutionPolicy Bypass -File .\github\skills\get-pr-dependency-advisories\get-pr-dependency-advisories.ps1 myorg MyProject MyRepo 42
```

## Output

Returns compact JSON with:

- `manifestFiles`
- `dependencies`
- `advisories`
- `dependenciesChecked`
- `advisoriesFound`
- `highOrCritical`
