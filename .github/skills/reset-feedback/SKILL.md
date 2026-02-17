---
name: reset-feedback
description: >
  Reset your Azure DevOps pull request reviewer feedback by setting the vote to
  "No vote".
---

# Reset Feedback

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
go run ./tools/skills-go/cmd/skills-go reset-feedback myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `0` means **No Vote** (feedback reset).
