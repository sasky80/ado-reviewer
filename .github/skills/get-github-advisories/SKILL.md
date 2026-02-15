---
name: get-github-advisories
description: Query the GitHub Advisory Database for vulnerabilities affecting a package in a specific ecosystem, optionally narrowed by version and severity.
---

# Get GitHub Advisories

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [get-github-advisories.sh](./get-github-advisories.sh) script on macOS/Linux or [get-github-advisories.ps1](./get-github-advisories.ps1) on Windows to list global security advisories.

## Authentication

Set `GH_SEC_PAT` to a GitHub Personal Access Token.

- Fine-grained PATs work and do not require extra permissions for this endpoint.
- Public unauthenticated calls are possible, but this skill intentionally requires `GH_SEC_PAT` to avoid stricter anonymous rate limits.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | ecosystem | Yes | Package ecosystem (`npm`, `pip`, `maven`, `nuget`, `go`, `rust`, etc.) |
| 2 | package | Yes | Package name in the selected ecosystem |
| 3 | version | No | Package version to check (`affects=package@version`) |
| 4 | severity | No | Advisory severity filter (`low`, `medium`, `high`, `critical`, `unknown`) |
| 5 | per_page | No | Max advisories to return (1..100, default: 30) |

## Example

```bash
bash .github/skills/get-github-advisories/get-github-advisories.sh npm lodash 4.17.20 high 20
```

```powershell
.\github\skills\get-github-advisories\get-github-advisories.ps1 npm lodash 4.17.20 high 20
```

## Output

Returns a JSON array of advisory objects from `https://api.github.com/advisories`, including fields like `ghsa_id`, `cve_id`, `severity`, `summary`, and `vulnerabilities`.
