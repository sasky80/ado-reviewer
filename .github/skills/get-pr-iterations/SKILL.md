---
name: get-pr-iterations
description: >
  Fetch all iterations (push updates) of an Azure DevOps pull request.
  Use the latest iteration ID with the get-pr-changes skill to discover
  which files were modified.
---

# Get PR Iterations

## Platform Note

- Clean-install path: use the Go command from `.github/tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Examples

```bash
go run ./.github/tools/skills-go/cmd/skills-go get-pr-iterations myorg MyProject MyRepo 42
```

## Output

Returns JSON with a `value` array of iteration objects. Each has an `id` field. Use the highest `id` to call `get-pr-changes`.
