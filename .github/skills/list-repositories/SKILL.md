---
name: list-repositories
description: >
  List all Git repositories in an Azure DevOps project. Use when you need to
  discover repository names or IDs before fetching pull request details.
---

# List Repositories

Run the [list-repositories.sh](./list-repositories.sh) script to list repositories.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |

## Example

```bash
bash .github/skills/list-repositories/list-repositories.sh default_organization MyProject
```

## Output

Returns JSON with a `value` array of repository objects, each containing `id`, `name`, `defaultBranch`, and `project` info.
