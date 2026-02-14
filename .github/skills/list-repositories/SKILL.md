---
name: list-repositories
description: >
  List all Git repositories in an Azure DevOps project. Use when you need to
  discover repository names or IDs before fetching pull request details.
---

# List Repositories

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [list-repositories.sh](./list-repositories.sh) script on macOS/Linux or [list-repositories.ps1](./list-repositories.ps1) on Windows to list repositories.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |

## Example

```bash
bash .github/skills/list-repositories/list-repositories.sh default_organization MyProject
```

```powershell
.\github\skills\list-repositories\list-repositories.ps1 default_organization MyProject
```

## Output

Returns JSON with a `value` array of repository objects, each containing `id`, `name`, `defaultBranch`, and `project` info.
