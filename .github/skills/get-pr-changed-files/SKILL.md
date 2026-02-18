---
name: get-pr-changed-files
description: >
  Fetch a compact, projected list of changed files for a specific Azure DevOps
  pull request iteration. Returns only file path metadata needed to drive
  downstream file fetching.
---

# Get PR Changed Files

## Platform Note

- Clean-install path: use the Go command from `.github/tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | iterationId | Yes | Iteration ID (from `get-pr-iterations`) |

## Examples

```bash
go run ./.github/tools/skills-go/cmd/skills-go get-pr-changed-files myorg MyProject MyRepo 42 3
```

## Output

Returns JSON in compact projected form:

- `pullRequestId`
- `iterationId`
- `count`
- `files[]` entries with:
  - `path`
  - `changeType`
  - `changeTrackingId`
  - `isFolder`
