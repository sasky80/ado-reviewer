````skill
---
name: reset-feedback
description: >
  Reset your Azure DevOps pull request reviewer feedback by setting the vote to
  "No vote".
---

# Reset Feedback

Run the [reset-feedback.sh](./reset-feedback.sh) script to clear reviewer vote feedback.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/reset-feedback/reset-feedback.sh default_organization MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `0` means **No vote** (feedback reset).

````