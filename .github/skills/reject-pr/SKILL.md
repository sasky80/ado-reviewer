````skill
---
name: reject-pr
description: >
  Reject an Azure DevOps pull request by casting a "Rejected" vote on behalf
  of the authenticated user. Use when blocking issues must be addressed before
  merge.
---

# Reject PR

Run the [reject-pr.sh](./reject-pr.sh) script to reject a pull request.

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

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `-10` means **Rejected**.

````