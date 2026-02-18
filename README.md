# Azure DevOps Copilot Skills

Copilot prompts (`/pr-review` and `/sec-review`) and Go-based skill tooling for Azure DevOps pull request workflows, including review voting, thread actions, and dependency security advisory checks.

For teams using GitHub Copilot Chat to review Azure DevOps pull requests from macOS/Linux or Windows.

The setup uses:

- Prompt files: [.github/prompts/pr-review.prompt.md](.github/prompts/pr-review.prompt.md), [.github/prompts/sec-review.prompt.md](.github/prompts/sec-review.prompt.md)
- Go runner (recommended for clean installs): [.github/tools/skills-go](.github/tools/skills-go)
- Skill docs: [.github/skills/](.github/skills/)

## Contents

- [Go Quick Start](#go-quick-start)
- [Quick Start](#quick-start)
- [Prompt Commands](#prompt-commands)
- [Requirements](#requirements)
- [Setup Instructions](#setup-instructions)
- [Prompt Examples (Voting)](#prompt-examples-voting)
- [Security Audit Prompt](#security-audit-prompt)
- [Environment Variables (OS-specific)](#environment-variables-os-specific)
- [Copying Files to Another Repository](#copying-files-to-another-repository)
- [Skills Description](#skills-description)
- [Before First Review](#before-first-review)
- [Typical Review Flow](#typical-review-flow)
- [Validation (Optional)](#validation-optional)
- [Where to Find Values](#where-to-find-values)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Go Quick Start

Recommended for clean installs:

```bash
go version
cd .github/tools/skills-go
go install ./cmd/skills-go

# Example command
skills-go check-deprecated-dependencies npm request 2.88.2
```

If your Go bin directory is not on PATH, run directly from source:

```bash
cd .github/tools/skills-go
go run ./cmd/skills-go check-deprecated-dependencies npm request 2.88.2
```

## Quick Start

Go-based quick start:

```bash
ORG="<your_org>"
PROJECT="<your_project>"
REPO="<your_repo>"
PR="<your_pr_id>"
ITERATION="<your_iteration_id>"

# Set PAT env var as ADO_PAT_<normalized_org>
# Normalization: replace non-[A-Za-z0-9_] with _, then prefix _ if it starts with a digit
# Examples: my-org -> ADO_PAT_my_org, 123-org -> ADO_PAT__123_org
export ADO_PAT_<your_normalized_org>="<your_pat>"
# Optional but recommended for dependency vulnerability checks:
export GH_SEC_PAT="<your_github_pat>"
cd .github/tools/skills-go
go run ./cmd/skills-go get-pr-details "$ORG" "$PROJECT" "$REPO" "$PR"
```

Windows PowerShell quick start:

```powershell
$Org = "<your_org>"
$Project = "<your_project>"
$Repo = "<your_repo>"
$Pr = "<your_pr_id>"

# Example: my-org -> ADO_PAT_my_org
$env:ADO_PAT_my_org = "<your_pat>"
# Optional but recommended for dependency vulnerability checks:
$env:GH_SEC_PAT = "<your_github_pat>"

Set-Location .github/tools/skills-go
go run ./cmd/skills-go get-pr-details $Org $Project $Repo $Pr
```

Use this for a fast smoke test. For full setup (including validation and command examples),
follow [Setup Instructions](#setup-instructions).

## Prompt Commands

Use these slash prompts in GitHub Copilot Chat:

```text
/pr-review review pr 1
/sec-review
```

Scoped security audit examples:

```text
/sec-review src/
/sec-review focus on auth
```

## Requirements

- Go 1.22+ (required for clean installs)
- Azure DevOps Personal Access Token (PAT) with **Code** scope (read/write as needed)
- GitHub Personal Access Token (PAT) for advisory checks via `get-github-advisories` (stored in `GH_SEC_PAT`)

Go quick check:

```bash
go version
```

## Setup Instructions

1. Clone this repository (or copy the skill files into your existing repo).
1. Set the Azure DevOps PAT environment variable (`ADO_PAT_<normalized_org>`) — see
  [Environment Variables](#environment-variables-os-specific) below.
1. If you use placeholder examples in prompts/commands, replace
  `organization`, `project`, and
  `repository` with your real values.
1. *(Optional)* Validate Go-based skill connectivity/authentication:

   ```bash
  cd .github/tools/skills-go
   go test -short ./...
   ```

   If you configured integration-test secrets locally, run:

   ```bash
  cd .github/tools/skills-go
   go test ./...
   ```

   The live integration tests are env-gated and skip automatically if variables are missing.

1. Start reviewing — open GitHub Copilot Chat and use the reviewer prompt command:

    ```text
    /pr-review review pr 1
    ```

    Using the command form helps force the agent to use the predefined prompt and skills.
    If the agent cannot determine the organization, project, or repository from context
    (e.g., from the git remote of the cloned repo or prompt defaults), it will ask.
    You can also be explicit:

    ```text
    /pr-review review pr 1 in myorg/myproject/myrepo
    ```

## Prompt Examples (Voting)

Use these prompt examples in GitHub Copilot Chat:

```text
/pr-review approve pr 1
/pr-review approve with suggestions pr 1
/pr-review wait for author pr 1
/pr-review reject pr 1
/pr-review reset feedback pr 1
```

Legend: `approve=10`, `approve with suggestions=5`, `wait for author=-5`, `reject=-10`, `reset feedback=0`.

Explicit org/project/repo form:

```text
/pr-review approve pr 1 in myorg/myproject/myrepo
/pr-review approve with suggestions pr 1 in myorg/myproject/myrepo
/pr-review wait for author pr 1 in myorg/myproject/myrepo
/pr-review reject pr 1 in myorg/myproject/myrepo
/pr-review reset feedback pr 1 in myorg/myproject/myrepo
```

## Security Audit Prompt

Use this prompt in GitHub Copilot Chat to run a security-focused audit of the current workspace:

```text
/sec-review
```

For scoped forms and examples, see [Prompt Commands](#prompt-commands).

## Environment Variables (OS-specific)

Each skill reads the Azure DevOps PAT from an environment variable named
`ADO_PAT_<normalized_org>`.

The GitHub advisory skill reads a GitHub PAT from `GH_SEC_PAT`.

Normalization rule (must match scripts):

1. Replace every character not in `[A-Za-z0-9_]` with `_`.
2. If the normalized value starts with a digit, prefix it with `_`.

Examples:

- organization `my-org` => `ADO_PAT_my_org`
- organization `my org` => `ADO_PAT_my_org`
- organization `123-org` => `ADO_PAT__123_org`

### PAT Lookup Scope Differences

The Go runner reads environment variables from the current process.
Set variables in the same shell session used to run `go run`/`go test`.

### macOS / Linux (zsh/bash)

Current terminal session:

```bash
export ADO_PAT_my_org="<your_pat>"
```

Persist for future sessions (zsh):

```bash
echo 'export ADO_PAT_my_org="<your_pat>"' >> ~/.zshrc
source ~/.zshrc
```

Persist for future sessions (bash):

```bash
echo 'export ADO_PAT_my_org="<your_pat>"' >> ~/.bashrc
source ~/.bashrc
```

### Windows

Use the shell where you run the scripts:

- If you run skills in **Git Bash**, you can set `ADO_PAT_*` in PowerShell/CMD (or directly in Git Bash).
- If you run skills in **WSL bash**, set `ADO_PAT_*` inside WSL (`~/.bashrc` / `~/.zshrc`), because WSL sessions do not reliably inherit PowerShell session variables.

PowerShell — current session (works for PowerShell-launched tools and typically Git Bash):

```powershell
$env:ADO_PAT_my_org = "<your_pat>"
```

PowerShell — persist for current user:

```powershell
[Environment]::SetEnvironmentVariable("ADO_PAT_my_org", "<your_pat>", "User")
```

CMD — current session:

```cmd
set ADO_PAT_my_org=<your_pat>
```

CMD — persist for current user:

```cmd
setx ADO_PAT_my_org "<your_pat>"
```

WSL bash — current session:

```bash
export ADO_PAT_my_org="<your_pat>"
```

WSL bash — persist for future sessions:

```bash
echo 'export ADO_PAT_my_org="<your_pat>"' >> ~/.bashrc
source ~/.bashrc
```

GitHub PAT for advisory checks (current session):

```bash
export GH_SEC_PAT="<your_github_pat>"
```

```powershell
$env:GH_SEC_PAT = "<your_github_pat>"
```

## Copying Files to Another Repository

If you want to reuse these skills in another repository, copy the following paths:

- `.github/prompts/pr-review.prompt.md`
- `.github/prompts/sec-review.prompt.md`
- `.github/skills/` (entire folder, including all `SKILL.md` files)
- `.github/tools/skills-go/`

Example from this repo root:

```bash
TARGET_REPO=/path/to/your-repo

mkdir -p "$TARGET_REPO/.github/prompts" "$TARGET_REPO/.github/skills" "$TARGET_REPO/.github/tools"
cp .github/prompts/pr-review.prompt.md "$TARGET_REPO/.github/prompts/"
cp .github/prompts/sec-review.prompt.md "$TARGET_REPO/.github/prompts/"
cp -R .github/skills/* "$TARGET_REPO/.github/skills/"
cp -R .github/tools/skills-go "$TARGET_REPO/.github/tools/"
```

Then, in the target repo:

```bash
cd /path/to/your-repo
cd .github/tools/skills-go
go test -short ./...
```

On Windows/PowerShell:

```powershell
Set-Location C:\path\to\your-repo
Set-Location .github\tools\skills-go
go test -short ./...
```

## Skills Description

Most skills call Azure DevOps REST API (`api-version=7.2-preview`).

Run all skills through `skills-go` from `.github/tools/skills-go`.

| Skill | Description |
| --- | --- |
| `get-pr-details` | Gets PR metadata (title, status, branches, reviewers, merge info). |
| `get-pr-threads` | Gets PR comment threads, including inline and system comments. |
| `get-pr-iterations` | Lists PR iterations (push updates). |
| `get-pr-changes` | Lists changed files for a PR iteration. |
| `get-pr-changed-files` | Returns projected changed files (`path`, `changeType`, `changeTrackingId`, `isFolder`). |
| `get-pr-diff-line-mapper` | Maps changed files to line-level diff hunks (`old/new` ranges and per-hunk counts). |
| `get-file-content` | Gets file content at a path/version (branch/commit/tag). |
| `get-commit-diffs` | Gets a diff summary between two versions. |
| `list-repositories` | Lists repositories in a project. |
| `list-projects` | Lists projects in an organization. |
| `get-github-advisories` | Queries GitHub advisories for `package` or `package@version` in an ecosystem. |
| `get-pr-dependency-advisories` | Scans changed dependency manifests and queries GitHub advisories. |
| `post-pr-comment` | Posts an inline or general PR comment thread. |
| `update-pr-thread` | Replies to a comment thread and/or updates its status. |
| `accept-pr` | Casts an Approve vote on a pull request. |
| `approve-with-suggestions` | Casts an Approve with Suggestions vote on a pull request. |
| `wait-for-author` | Casts a Waiting for Author vote on a pull request. |
| `reject-pr` | Casts a Rejected vote on a pull request. |
| `reset-feedback` | Resets reviewer vote to No Vote. |
| `check-deprecated-dependencies` | Checks whether a dependency is deprecated across ecosystems (npm, pip, nuget). |

## Before First Review

Before the first review in a repository, tell the reviewer where your standards/guides live (if you use custom paths).

Example:

```text
/pr-review review pr 1 in myorg/myproject/myrepo.
Standards/guides are in docs/engineering/standards.md and docs/guides/.
```

If you do not specify paths, the reviewer checks common defaults (`README*`,
`CONTRIBUTING.md`, `.editorconfig`, `docs/`, linter/formatter configs).

**Recommended:** update `.github/prompts/pr-review.prompt.md` with
repository-specific standards paths so they apply by default.

> Source alignment note: reviewer behavior and decision rules in the prompt file are
> aligned with [Google Engineering Practices — Reviewer Guide](https://google.github.io/eng-practices/review/reviewer/).

## Typical Review Flow

1. `get-pr-details` to identify source and target branches.
2. Resolve standards/guides locations (user-provided or default paths).
3. `get-pr-iterations` to find the latest iteration.
4. `get-pr-changed-files` (or `get-pr-changes`) to list modified files.
5. `get-file-content` / `get-multiple-files` to compare file versions (target branch and source branch).
6. Optional: `get-pr-diff-line-mapper` to derive precise line-hunk ranges for inline comment targeting.
7. `get-pr-threads` to avoid duplicate comments.
8. Optional: `get-commit-diffs` for a high-level diff summary.
9. Optional (dependency changes): `get-pr-dependency-advisories` to automatically scan changed manifests and query advisories.
10. `post-pr-comment` to publish selected findings.
11. `update-pr-thread` to reply and resolve threads.

Dependency advisory example:

```bash
go run ./.github/tools/skills-go/cmd/skills-go get-pr-dependency-advisories "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION"
```

## Validation (Optional)

Run Go tests to confirm local behavior and wiring:

```bash
cd .github/tools/skills-go
go test -short ./...
```

Run live integration tests (only when required env vars are present):

```bash
cd .github/tools/skills-go
go test ./...
```

Live tests are skipped automatically unless all required variables are set:

- `ADO_IT_ORG`
- `ADO_IT_PROJECT`
- `ADO_IT_REPO`
- `ADO_IT_PR`
- `ADO_PAT_<normalized_org>`
- `GH_SEC_PAT`

Optional:

- `ADO_IT_ITERATION`

CI behavior in this repository:

```text
PR workflow always runs: go test -short ./...
Live integration job runs only when required secrets are present
```

## Where to Find Values

Use these sources for the variables used in examples (`ORG`, `PROJECT`, `REPO`, `PR`, `ITERATION`, `THREAD_ID`):

- `ORG` (organization): the first segment in your Azure DevOps URL, e.g. `https://dev.azure.com/<org>/...`
- `PROJECT`: project name (or ID) from Azure DevOps Project list, or run
  `go run ./.github/tools/skills-go/cmd/skills-go list-projects "$ORG"`.
- `REPO`: repository name (or ID) from Repos > Files, or run
  `go run ./.github/tools/skills-go/cmd/skills-go list-repositories "$ORG" "$PROJECT"`.
- `PR`: pull request number from the PR URL and title bar (example: `.../pullrequest/123` => `PR=123`).
- `ITERATION`: latest push iteration from
  `go run ./.github/tools/skills-go/cmd/skills-go get-pr-iterations "$ORG" "$PROJECT" "$REPO" "$PR"`;
  use the highest `id` in `value[]`.
- `THREAD_ID`: thread `id` from
  `go run ./.github/tools/skills-go/cmd/skills-go get-pr-threads "$ORG" "$PROJECT" "$REPO" "$PR"`
  for reply/resolve actions.

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `401 Unauthorized` | PAT is missing, expired, or wrong org name in env var | Verify `ADO_PAT_<normalized_org>` is set using the normalization rule above and that the PAT is valid (example: `123-org` => `ADO_PAT__123_org`) |
| Validation fails but skills work | PR or iteration ID is stale/invalid | Re-check `PR` and `ITERATION` values (see [Where to Find Values](#where-to-find-values)) |
| Script path not found under `scripts/` | Legacy root scripts were removed | Use Go commands from `.github/tools/skills-go` (examples in [Go Quick Start](#go-quick-start)) |

## Contributing

Contributions are welcome. Please open an issue or pull request.

---

*This project is not affiliated with or endorsed by Microsoft or Google.*
