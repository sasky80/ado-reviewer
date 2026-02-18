---
name: get-commit-diffs
description: >
  Fetch a summary of differences between two commits, branches, or tags in an
  Azure DevOps Git repository. Returns the list of added, edited, and deleted
  files. Use to get a high-level change overview for a pull request.
---

# Get Commit Diffs

## Platform Note

- Clean-install path: use the Go command from `.github/tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | baseVersion | Yes | Base version (commit SHA, branch, or tag) |
| 5 | targetVersion | Yes | Target version (commit SHA, branch, or tag) |
| 6 | baseVersionType | No | Base version type: `branch`, `commit`, or `tag` (default: `commit`) |
| 7 | targetVersionType | No | Target version type: `branch`, `commit`, or `tag` (default: `commit`) |

## Examples

```bash
# Compare two branches
go run ./.github/tools/skills-go/cmd/skills-go get-commit-diffs myorg MyProject MyRepo main feature/login branch branch
```

## Output

Returns JSON with `changes` array listing files with `changeType` and `item.path`, plus `changeCounts` summary.
