---
name: wait-for-author
description: >
  Mark an Azure DevOps pull request as waiting for author feedback by casting
  a "Waiting for author" vote on behalf of the authenticated reviewer.
---

# Wait For Author

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [wait-for-author.sh](./wait-for-author.sh) script on macOS/Linux or [wait-for-author.ps1](./wait-for-author.ps1) on Windows to set the reviewer vote to waiting for author.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |

## Example

```bash
bash .github/skills/wait-for-author/wait-for-author.sh myorg MyProject MyRepo 42
```

```powershell
.\github\skills\wait-for-author\wait-for-author.ps1 myorg MyProject MyRepo 42
```

## Output

Returns JSON with the reviewer vote object.
A `vote` value of `-5` means **Waiting for author**.
