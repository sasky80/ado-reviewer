---
name: list-repositories
description: >
  List all Git repositories in an Azure DevOps project. Use when you need to
  discover repository names or IDs before fetching pull request details.
---

# List Repositories

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |

## Examples

```bash
go run ./tools/skills-go/cmd/skills-go list-repositories myorg MyProject
```

## Output

Returns JSON with a `value` array of repository objects, each containing `id`, `name`, `defaultBranch`, and `project` info.
