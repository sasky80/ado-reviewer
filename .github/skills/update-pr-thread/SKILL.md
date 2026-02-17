---
name: update-pr-thread
description: >
  Reply to a comment thread and/or update its status on an Azure DevOps pull
  request. Use after fixing review findings to respond with a fix description
  and mark threads as resolved (fixed).
---

# Update PR Thread

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | threadId | Yes | Comment thread ID |
| 6 | reply | No | Reply text (use `-` to skip and only update status) |
| 7 | status | No | Thread status: `active`, `fixed`, `closed`, `byDesign`, `pending`, `wontFix` |

At least one of `reply` or `status` must be provided.

## Examples

```bash
# Reply and mark as fixed
go run ./tools/skills-go/cmd/skills-go update-pr-thread myorg MyProject MyRepo 42 7 "Fixed: refactored to use parameterized queries." fixed

# Reply only (keep thread active)
go run ./tools/skills-go/cmd/skills-go update-pr-thread myorg MyProject MyRepo 42 7 "Working on this, will push a fix shortly."

# Update status only (no reply)
go run ./tools/skills-go/cmd/skills-go update-pr-thread myorg MyProject MyRepo 42 7 - fixed
```

## Output

When a reply is posted, returns JSON with the created comment object.
When status is updated, returns JSON with the updated thread object including `id`, `status`, and `comments`.
