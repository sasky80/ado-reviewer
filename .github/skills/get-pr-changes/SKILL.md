---
name: get-pr-changes
description: >
  Fetch the list of file changes for a specific iteration of an Azure DevOps
  pull request. Shows which files were added, edited, or deleted. Requires an
  iteration ID obtained from get-pr-iterations.
---

# Get PR Changes

Run the [get-pr-changes.sh](./get-pr-changes.sh) script to list changed files.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | iterationId | Yes | Iteration ID (from `get-pr-iterations`) |

## Example

```bash
bash .github/skills/get-pr-changes/get-pr-changes.sh default_organization MyProject MyRepo 42 3
```

## Output

Returns JSON with `changeEntries` listing files with their `changeType` (add, edit, delete) and `item.path`.
