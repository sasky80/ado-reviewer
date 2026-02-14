---
name: list-projects
description: >
  List all projects in an Azure DevOps organization. Use when you need to
  discover project names or IDs before fetching repository or pull request details.
---

# List Projects

Run the [list-projects.sh](./list-projects.sh) script to list projects.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |

## Example

```bash
bash .github/skills/list-projects/list-projects.sh default_organization
```

## Output

Returns JSON with a `value` array of project objects, each containing `id`, `name`, `description`, and `state`.
