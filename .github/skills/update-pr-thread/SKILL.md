---
name: update-pr-thread
description: >
  Reply to a comment thread and/or update its status on an Azure DevOps pull
  request. Use after fixing review findings to respond with a fix description
  and mark threads as resolved (fixed).
---

# Update PR Thread

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [update-pr-thread.sh](./update-pr-thread.sh) script on macOS/Linux or [update-pr-thread.ps1](./update-pr-thread.ps1) on Windows to reply to and/or resolve a PR comment thread.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
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
bash .github/skills/update-pr-thread/update-pr-thread.sh default_organization MyProject MyRepo 42 7 "Fixed: refactored to use parameterized queries." fixed

# Reply only (keep thread active)
bash .github/skills/update-pr-thread/update-pr-thread.sh default_organization MyProject MyRepo 42 7 "Working on this, will push a fix shortly."

# Update status only (no reply)
bash .github/skills/update-pr-thread/update-pr-thread.sh default_organization MyProject MyRepo 42 7 - fixed
```

```powershell
# Reply and mark as fixed (Windows)
.\github\skills\update-pr-thread\update-pr-thread.ps1 default_organization MyProject MyRepo 42 7 "Fixed: refactored to use parameterized queries." fixed

# Reply only (keep thread active) (Windows)
.\github\skills\update-pr-thread\update-pr-thread.ps1 default_organization MyProject MyRepo 42 7 "Working on this, will push a fix shortly."

# Update status only (no reply) (Windows)
.\github\skills\update-pr-thread\update-pr-thread.ps1 default_organization MyProject MyRepo 42 7 - fixed
```

## Output

When a reply is posted, returns JSON with the created comment object.
When status is updated, returns JSON with the updated thread object including `id`, `status`, and `comments`.
