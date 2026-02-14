---
name: get-pr-details
description: >
  Fetch pull request metadata from Azure DevOps (title, description, status,
  source/target branches, reviewers, merge status). Use when the user provides
  a pull request ID and you need to understand the PR context.
---

# Get PR Details

Run the [get-pr-details.sh](./get-pr-details.sh) script to retrieve pull request metadata.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/get-pr-details/get-pr-details.sh default_organization MyProject MyRepo 42
```

## Output

Returns JSON with fields including `title`, `description`, `status`, `sourceRefName`, `targetRefName`, `reviewers`, `mergeStatus`, `createdBy`, etc.
