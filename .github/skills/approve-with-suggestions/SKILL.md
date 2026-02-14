````skill
---
name: approve-with-suggestions
description: >
  Approve an Azure DevOps pull request while indicating non-blocking
  suggestions by casting an "Approved with suggestions" vote.
---

# Approve PR With Suggestions

Run the [approve-with-suggestions.sh](./approve-with-suggestions.sh) script to approve a pull request with suggestions.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/approve-with-suggestions/approve-with-suggestions.sh default_organization MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `5` means **Approved with suggestions**.

````