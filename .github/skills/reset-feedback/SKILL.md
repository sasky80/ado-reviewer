---
name: reset-feedback
description: >
  Reset your Azure DevOps pull request reviewer feedback by setting the vote to
  "No vote".
---

# Reset Feedback

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [reset-feedback.sh](./reset-feedback.sh) script on macOS/Linux or [reset-feedback.ps1](./reset-feedback.ps1) on Windows to clear reviewer vote feedback.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/reset-feedback/reset-feedback.sh myorg MyProject MyRepo 42
```

```powershell
.\github\skills\reset-feedback\reset-feedback.ps1 myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `0` means **No vote** (feedback reset).
