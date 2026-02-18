---
name: get-pr-threads
description: Fetch all comment threads on an Azure DevOps pull request (review comments, discussions, system messages) and use it to see existing reviewer feedback before writing your own review.
---

# Get PR Threads

## Platform Note

- Clean-install path: use the Go command from `.github/tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | statusFilter | No | Keep only threads with this status (e.g. `active`, `fixed`, `closed`). Default: all statuses. |
| 6 | excludeSystem | No | `true` to remove system-generated threads (vote changes, ref updates). Default: `false`. |

## Examples

```bash
# All threads (default)
go run ./.github/tools/skills-go/cmd/skills-go get-pr-threads myorg MyProject MyRepo 42

# Only active, non-system threads
go run ./.github/tools/skills-go/cmd/skills-go get-pr-threads myorg MyProject MyRepo 42 active true

# All statuses but exclude system threads
go run ./.github/tools/skills-go/cmd/skills-go get-pr-threads myorg MyProject MyRepo 42 "" true
```

## Output

Returns JSON with a `value` array of thread objects, each containing `comments`, `threadContext` (file path and line range), and `status`.
