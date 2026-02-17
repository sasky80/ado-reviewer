---
name: post-pr-comment
description: >
  Create a comment thread on an Azure DevOps pull request. Can post inline
  comments on a specific file and line, or general PR-level comments.
  Use after completing a code review to post findings back to the PR.
---

# Post PR Comment

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | pullRequestId | Yes | Pull request ID |
| 5 | filePath | Yes | Repository-relative file path for inline comment (canonical form like `/src/app.js`; use `-` for a general comment) |
| 6 | line | Yes | Line number for inline comment (use `0` for general comments) |
| 7 | comment | Yes | Comment text (supports Markdown) |

## Examples

```bash
# Inline comment on a specific file and line (canonical repository path)
go run ./tools/skills-go/cmd/skills-go post-pr-comment myorg MyProject MyRepo 42 /src/app.js 15 "Consider using const here."

# General PR-level comment
go run ./tools/skills-go/cmd/skills-go post-pr-comment myorg MyProject MyRepo 42 - 0 "Overall the code looks good."
```

## Formatting Note

When posting structured review findings, avoid literal `\n\n` sequences in comment text.
Use a single HTML line break (`<br/>`) between sections, for example:

```text
🟠 Major | Security<br/>Description: ...<br/>Recommendation: ...
```

## Output

Returns JSON with the created thread object including `id`, `comments`, and `status`.
