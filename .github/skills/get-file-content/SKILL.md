---
name: get-file-content
description: >
  Fetch the content of a file from an Azure DevOps Git repository at a given
  version (branch, commit, or tag). Use to retrieve the before/after state of
  files changed in a pull request.
---

# Get File Content

Run the [get-file-content.sh](./get-file-content.sh) script to retrieve file content.

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | organization | No | Azure DevOps organization (default: `default_organization`) |
| 2 | project | Yes | Project name or ID |
| 3 | repositoryId | Yes | Repository name or ID |
| 4 | path | Yes | File path in the repo (e.g. `/src/app.js`) |
| 5 | version | No | Version string – commit SHA, branch name, or tag |
| 6 | versionType | No | Version type: `branch`, `commit`, or `tag` (default: `branch`) |

## Example

```bash
# Get file from a specific branch
bash .github/skills/get-file-content/get-file-content.sh default_organization MyProject MyRepo /src/app.js main branch

# Get file from a specific commit
bash .github/skills/get-file-content/get-file-content.sh default_organization MyProject MyRepo /src/app.js abc123 commit
```

## Output

Returns JSON with `content` containing the file's text content, plus metadata like `path`, `commitId`, and `objectId`.
