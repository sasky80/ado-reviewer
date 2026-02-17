---
name: approve-with-suggestions
description: >
  Approve an Azure DevOps pull request while indicating non-blocking
  suggestions by casting an "Approved with suggestions" vote.
---

# Approve PR With Suggestions

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
go run ./tools/skills-go/cmd/skills-go approve-with-suggestions myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `5` means **Approved with Suggestions**.
