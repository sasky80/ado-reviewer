---
name: list-repositories
description: >
  List all Git repositories in an Azure DevOps project. Use when you need to
  discover repository names or IDs before fetching pull request details.
---

# List Repositories

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run the [list-repositories.sh](./list-repositories.sh) script on macOS/Linux or [list-repositories.ps1](./list-repositories.ps1) on Windows to list repositories.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |

## Examples

```bash
bash .github/skills/list-repositories/list-repositories.sh myorg MyProject
```

```powershell
pwsh -ExecutionPolicy Bypass -File .\github\skills\list-repositories\list-repositories.ps1 myorg MyProject
```

## Output

Returns JSON with a `value` array of repository objects, each containing `id`, `name`, `defaultBranch`, and `project` info.
