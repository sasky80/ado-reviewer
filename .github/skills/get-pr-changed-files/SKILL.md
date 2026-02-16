---
name: get-pr-changed-files
description: >
  Fetch a compact, projected list of changed files for a specific Azure DevOps
  pull request iteration. Returns only file path metadata needed to drive
  downstream file fetching.
---

# Get PR Changed Files

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run the [get-pr-changed-files.sh](./get-pr-changed-files.sh) script on macOS/Linux or [get-pr-changed-files.ps1](./get-pr-changed-files.ps1) on Windows to retrieve a projected file list.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | iterationId | Yes | Iteration ID (from `get-pr-iterations`) |

## Examples

```bash
bash .github/skills/get-pr-changed-files/get-pr-changed-files.sh myorg MyProject MyRepo 42 3
```

```powershell
pwsh -ExecutionPolicy Bypass -File .\github\skills\get-pr-changed-files\get-pr-changed-files.ps1 myorg MyProject MyRepo 42 3
```

## Output

Returns JSON in compact projected form:

- `pullRequestId`
- `iterationId`
- `count`
- `files[]` entries with:
  - `path`
  - `changeType`
  - `changeTrackingId`
  - `isFolder`
