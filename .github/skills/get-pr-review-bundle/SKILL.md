---
name: get-pr-review-bundle
description: >
  Fetch a paged review bundle for an Azure DevOps pull request in one call:
  PR metadata, latest/selected iteration, projected changed files, and filtered
  PR threads. Designed to stay safe on large PRs with offset/limit pagination
  and hard caps.
---

# Get PR Review Bundle

## Platform Note

- Clean-install path: use the Go command from `.github/tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | iterationId | No | Explicit iteration ID. If omitted, latest iteration is used |
| 6 | fileOffset | No | Zero-based changed-file page offset (default: `0`) |
| 7 | fileLimit | No | Changed-file page size (default: `100`, max: `500`) |
| 8 | threadOffset | No | Zero-based thread page offset (default: `0`) |
| 9 | threadLimit | No | Thread page size (default: `100`, max: `500`) |
| 10 | statusFilter | No | Thread status filter (for example: `active`) |
| 11 | excludeSystem | No | `true`/`false` to exclude system threads (default: `true`) |
| 12 | includeLineMap | No | `true`/`false` to include simple line-map estimates for returned file page |

## Examples

```bash
# Summary-first bundle for a large PR
go run ./.github/tools/skills-go/cmd/skills-go get-pr-review-bundle myorg MyProject MyRepo 42

# Fetch next page of files while keeping thread page at start
go run ./.github/tools/skills-go/cmd/skills-go get-pr-review-bundle myorg MyProject MyRepo 42 "" 100 100 0 100 active true false
```

## Output

Returns JSON with:

- `pullRequest`: full PR metadata
- `iterationId`, `sourceBranch`, `targetBranch`
- `summary`: totals and `hasMore` flags
- `files` and `threads` page objects (`offset`, `limit`, `total`, `hasMore`, `items`)
- `nextFileOffset` / `nextThreadOffset` when additional pages exist
- `warnings` when requested limits are capped

````