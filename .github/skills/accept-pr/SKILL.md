---
name: accept-pr
description: >
  Approve (accept) an Azure DevOps pull request by casting an "Approve" vote
  on behalf of the authenticated user. Use after a successful code review
  when all findings are resolved and the PR is ready to merge.
---

# Accept PR

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [accept-pr.sh](./accept-pr.sh) script on macOS/Linux or [accept-pr.ps1](./accept-pr.ps1) on Windows to approve a pull request.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Examples

```bash
# Approve PR 42
bash .github/skills/accept-pr/accept-pr.sh myorg MyProject MyRepo 42
```

```powershell
# Approve PR 42 (Windows)
.\github\skills\accept-pr\accept-pr.ps1 myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object including `id`, `vote`, and `displayName`.
A `vote` value of `10` means **Approved**.
