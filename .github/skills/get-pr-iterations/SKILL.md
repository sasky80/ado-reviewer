---
name: get-pr-iterations
description: >
  Fetch all iterations (push updates) of an Azure DevOps pull request.
  Use the latest iteration ID with the get-pr-changes skill to discover
  which files were modified.
---

# Get PR Iterations

Run the [get-pr-iterations.sh](./get-pr-iterations.sh) script to list iterations.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/get-pr-iterations/get-pr-iterations.sh default_organization MyProject MyRepo 42
```

## Output

Returns JSON with a `value` array of iteration objects. Each has an `id` field. Use the highest `id` to call `get-pr-changes`.
