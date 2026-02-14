---
name: get-commit-diffs
description: >
  Fetch a summary of differences between two commits, branches, or tags in an
  Azure DevOps Git repository. Returns the list of added, edited, and deleted
  files. Use to get a high-level change overview for a pull request.
---

# Get Commit Diffs

Run the [get-commit-diffs.sh](./get-commit-diffs.sh) script to get a diff summary.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | baseVersion | Yes | Base version (commit SHA, branch, or tag) |
| 5 | targetVersion | Yes | Target version (commit SHA, branch, or tag) |
| 6 | baseVersionType | No | Base version type: `branch`, `commit`, or `tag` (default: `commit`) |
| 7 | targetVersionType | No | Target version type: `branch`, `commit`, or `tag` (default: `commit`) |

## Example

```bash
# Compare two branches
bash .github/skills/get-commit-diffs/get-commit-diffs.sh default_organization MyProject MyRepo main feature/login branch branch
```

## Output

Returns JSON with `changes` array listing files with `changeType` and `item.path`, plus `changeCounts` summary.
