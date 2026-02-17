---
name: accept-pr
description: >
  Approve (accept) an Azure DevOps pull request by casting an "Approve" vote
  on behalf of the authenticated user. Use after a successful code review
  when all findings are resolved and the PR is ready to merge.
---

# Accept PR

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
# Approve PR 42
go run ./tools/skills-go/cmd/skills-go accept-pr myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object including `id`, `vote`, and `displayName`.
A `vote` value of `10` means **Approved**.
