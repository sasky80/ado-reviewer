````skill
---
name: reject-pr
description: >
  Reject an Azure DevOps pull request by casting a "Rejected" vote on behalf
  of the authenticated user. Use when blocking issues must be addressed before
  merge.
---

# Reject PR

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [reject-pr.sh](./reject-pr.sh) script on macOS/Linux or [reject-pr.ps1](./reject-pr.ps1) on Windows to reject a pull request.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/reject-pr/reject-pr.sh default_organization MyProject MyRepo 42
```

```powershell
.\github\skills\reject-pr\reject-pr.ps1 default_organization MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `-10` means **Rejected**.

````