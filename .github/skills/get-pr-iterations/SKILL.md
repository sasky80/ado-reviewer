---
name: get-pr-iterations
description: >
  Fetch all iterations (push updates) of an Azure DevOps pull request.
  Use the latest iteration ID with the get-pr-changes skill to discover
  which files were modified.
---

# Get PR Iterations

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run the [get-pr-iterations.sh](./get-pr-iterations.sh) script on macOS/Linux or [get-pr-iterations.ps1](./get-pr-iterations.ps1) on Windows to list iterations.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Examples

```bash
bash .github/skills/get-pr-iterations/get-pr-iterations.sh myorg MyProject MyRepo 42
```

```powershell
pwsh -ExecutionPolicy Bypass -File .\.github\skills\get-pr-iterations\get-pr-iterations.ps1 myorg MyProject MyRepo 42
```

## Output

Returns JSON with a `value` array of iteration objects. Each has an `id` field. Use the highest `id` to call `get-pr-changes`.
