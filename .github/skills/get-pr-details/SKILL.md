---
name: get-pr-details
description: >
  Fetch pull request metadata from Azure DevOps (title, description, status,
  source/target branches, reviewers, merge status). Use when the user provides
  a pull request ID and you need to understand the PR context.
---

# Get PR Details

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
go run ./.github/tools/skills-go/cmd/skills-go get-pr-details myorg MyProject MyRepo 42
```

## Output

Returns JSON with fields including `title`, `description`, `status`, `sourceRefName`, `targetRefName`, `reviewers`, `mergeStatus`, `createdBy`, etc.
