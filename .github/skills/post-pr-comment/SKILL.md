---
name: post-pr-comment
description: >
  Create a comment thread on an Azure DevOps pull request. Can post inline
  comments on a specific file and line, or general PR-level comments.
  Use after completing a code review to post findings back to the PR.
---

# Post PR Comment

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts with the same argument order

Run the [post-pr-comment.sh](./post-pr-comment.sh) script on macOS/Linux or [post-pr-comment.ps1](./post-pr-comment.ps1) on Windows to create a comment thread on a pull request.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | filePath | No | File path for inline comment (use `-` for a general comment) |
| 6 | line | No | Line number for inline comment (ignored for general comments) |
| 7 | comment | Yes | Comment text (supports Markdown) |

## Examples

```bash
# Inline comment on a specific file and line
bash .github/skills/post-pr-comment/post-pr-comment.sh default_organization MyProject MyRepo 42 /src/app.js 15 "Consider using const here."

# General PR-level comment
bash .github/skills/post-pr-comment/post-pr-comment.sh default_organization MyProject MyRepo 42 - 0 "Overall the code looks good."
```

```powershell
# Inline comment on a specific file and line (Windows)
.\github\skills\post-pr-comment\post-pr-comment.ps1 default_organization MyProject MyRepo 42 /src/app.js 15 "Consider using const here."

# General PR-level comment (Windows)
.\github\skills\post-pr-comment\post-pr-comment.ps1 default_organization MyProject MyRepo 42 - 0 "Overall the code looks good."
```

## Formatting Note

When posting structured review findings, avoid literal `\n\n` sequences in comment text.
Use a single HTML line break (`<br/>`) between sections, for example:

```text
🟠 Major | Security<br/>Description: ...<br/>Recommendation: ...
```

## Output

Returns JSON with the created thread object including `id`, `comments`, and `status`.
