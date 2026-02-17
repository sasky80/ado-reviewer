---
name: list-projects
description: >
  List all projects in an Azure DevOps organization. Use when you need to
  discover project names or IDs before fetching repository or pull request details.
---

# List Projects

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |

## Examples

```bash
go run ./tools/skills-go/cmd/skills-go list-projects myorg
```

## Output

Returns JSON with a `value` array of project objects, each containing `id`, `name`, `description`, and `state`.
