---
name: reject-pr
description: >
  Reject an Azure DevOps pull request by casting a "Rejected" vote on behalf
  of the authenticated user. Use when blocking issues must be addressed before
  merge.
---

# Reject PR

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Examples

```bash
go run ./tools/skills-go/cmd/skills-go reject-pr myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `-10` means **Rejected**.
