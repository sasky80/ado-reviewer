---
name: get-pr-threads
description: Fetch all comment threads on an Azure DevOps pull request (review comments, discussions, system messages) and use it to see existing reviewer feedback before writing your own review.
---

# Get PR Threads

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run the [get-pr-threads.sh](./get-pr-threads.sh) script on macOS/Linux or [get-pr-threads.ps1](./get-pr-threads.ps1) on Windows to retrieve comment threads.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | statusFilter | No | Keep only threads with this status (e.g. `active`, `fixed`, `closed`). Default: all statuses. |
| 6 | excludeSystem | No | `true` to remove system-generated threads (vote changes, ref updates). Default: `false`. |

## Examples

```bash
# All threads (default)
bash .github/skills/get-pr-threads/get-pr-threads.sh myorg MyProject MyRepo 42

# Only active, non-system threads
bash .github/skills/get-pr-threads/get-pr-threads.sh myorg MyProject MyRepo 42 active true

# All statuses but exclude system threads
bash .github/skills/get-pr-threads/get-pr-threads.sh myorg MyProject MyRepo 42 "" true
```

```powershell
# All threads (default)
pwsh -ExecutionPolicy Bypass -File .\.github\skills\get-pr-threads\get-pr-threads.ps1 myorg MyProject MyRepo 42

# Only active, non-system threads
pwsh -ExecutionPolicy Bypass -File .\.github\skills\get-pr-threads\get-pr-threads.ps1 myorg MyProject MyRepo 42 active true
```

## Output

Returns JSON with a `value` array of thread objects, each containing `comments`, `threadContext` (file path and line range), and `status`.
