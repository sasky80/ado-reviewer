---
name: get-pr-threads
description: >
  Fetch all comment threads on an Azure DevOps pull request (review comments,
  discussions, system messages). Use to see existing reviewer feedback before
  writing your own review.
---

# Get PR Threads

Run the [get-pr-threads.sh](./get-pr-threads.sh) script to retrieve comment threads.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/get-pr-threads/get-pr-threads.sh default_organization MyProject MyRepo 42
```

## Output

Returns JSON with a `value` array of thread objects, each containing `comments`, `threadContext` (file path and line range), and `status`.
