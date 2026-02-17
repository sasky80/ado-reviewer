---
name: get-pr-diff-line-mapper
description: >
  Build line-level diff mappings (hunks and line ranges) for files changed in a
  specific Azure DevOps pull request iteration. Useful for precise inline
  comment placement and evidence-based review findings.
---

# Get PR Diff-to-Line Mapper

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

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
go run ./tools/skills-go/cmd/skills-go get-pr-diff-line-mapper myorg MyProject MyRepo 42 3
```

## Output

Returns JSON with:

- `pullRequestId`, `iterationId`
- `sourceBranch`, `targetBranch`
- `count`
- `files[]` entries containing:
  - `path`, `changeType`, `changeTrackingId`, `isFolder`
  - `baseExists`, `prExists`
  - `lineMap`:
    - `hunkCount`, `totalAdded`, `totalDeleted`, `totalContext`
    - `hunks[]` with `oldStart`, `oldLines`, `newStart`, `newLines`, and per-hunk line totals

````
