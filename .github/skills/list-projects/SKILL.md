---
name: list-projects
description: >
  List all projects in an Azure DevOps organization. Use when you need to
  discover project names or IDs before fetching repository or pull request details.
---

# List Projects

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run the [list-projects.sh](./list-projects.sh) script on macOS/Linux or [list-projects.ps1](./list-projects.ps1) on Windows to list projects.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |

## Examples

```bash
bash .github/skills/list-projects/list-projects.sh myorg
```

```powershell
pwsh -ExecutionPolicy Bypass -File .\.github\skills\list-projects\list-projects.ps1 myorg
```

## Output

Returns JSON with a `value` array of project objects, each containing `id`, `name`, `description`, and `state`.
