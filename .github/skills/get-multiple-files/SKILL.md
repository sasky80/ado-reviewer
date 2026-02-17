---
name: get-multiple-files
description: Fetch the content of multiple files from an Azure DevOps Git repository in a single invocation to reduce round-trips.
---

# Get Multiple Files

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | Yes | Azure DevOps organization |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | version | Yes | Version string – commit SHA, branch name, or tag |
| 5 | versionType | Yes | Version type: `branch`, `commit`, or `tag` (default: `branch`) |
| 6 | pathsJson | Yes | JSON array of repository-relative file paths (e.g. `'["/src/app.js", "/README.md"]'`) |

## Examples

```bash
# Fetch two files from the main branch
go run ./tools/skills-go/cmd/skills-go get-multiple-files myorg MyProject MyRepo main branch '["/src/app.js", "/README.md"]'

# Fetch files from a specific commit
go run ./tools/skills-go/cmd/skills-go get-multiple-files myorg MyProject MyRepo abc123 commit '["/src/app.js", "/docs/guide.md"]'
```

## Output

Returns a JSON object with:

```json
{
  "results": [
    {
      "path": "/src/app.js",
      "status": "ok",
      "content": "...file content...",
      "commitId": "abc123",
      "objectId": "def456"
    },
    {
      "path": "/missing.txt",
      "status": "error",
      "error": "HTTP 404"
    }
  ],
  "succeeded": 1,
  "failed": 1,
  "total": 2
}
```

- `status` is `"ok"` for successfully retrieved files or `"error"` for failures.
- Failed files include an `error` field with the failure reason; they do **not** cause the command to exit with a non-zero code.
- `succeeded`, `failed`, and `total` provide summary counts.
```
