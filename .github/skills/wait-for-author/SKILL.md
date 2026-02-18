---
name: wait-for-author
description: >
  Mark an Azure DevOps pull request as waiting for author feedback by casting
  a "Waiting for author" vote on behalf of the authenticated reviewer.
---

# Wait For Author

## Platform Note

- Clean-install path: use the Go command from `.github/tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Examples

```bash
go run ./.github/tools/skills-go/cmd/skills-go wait-for-author myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `-5` means **Waiting for Author**.
