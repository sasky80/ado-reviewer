---
name: list-projects
description: >
  List all projects in an Azure DevOps organization. Use when you need to
  discover project names or IDs before fetching repository or pull request details.
---

# List Projects

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [list-projects.sh](./list-projects.sh) script on macOS/Linux or [list-projects.ps1](./list-projects.ps1) on Windows to list projects.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |

## Example

```bash
bash .github/skills/list-projects/list-projects.sh default_organization
```

```powershell
.\github\skills\list-projects\list-projects.ps1 default_organization
```

## Output

Returns JSON with a `value` array of project objects, each containing `id`, `name`, `description`, and `state`.
