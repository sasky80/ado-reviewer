# Azure DevOps Copilot Skills

Bash-based Copilot agent skills for Azure DevOps — includes a code-reviewer prompt and
skills for pull request analysis, repository browsing, and project discovery.

The setup uses:

- Prompt file: [.github/copilot/code-reviewer.prompt.md](.github/copilot/code-reviewer.prompt.md)
- Skills: [.github/skills/](.github/skills/)
- Validation script: [scripts/validate-skills.sh](scripts/validate-skills.sh)

## Contents

- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Setup Instructions](#setup-instructions)
- [Prompt Examples (Voting)](#prompt-examples-voting)
- [Environment Variables (OS-specific)](#environment-variables-os-specific)
- [Copying Files to Another Repository](#copying-files-to-another-repository)
- [Skills Description](#skills-description)
- [Before First Review](#before-first-review)
- [Typical Review Flow](#typical-review-flow)
- [Validation (Optional)](#validation-optional)
- [Where to Find Values](#where-to-find-values)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Quick Start

```bash
ORG="<your_org>"
PROJECT="<your_project>"
REPO="<your_repo>"
PR="<your_pr_id>"
ITERATION="<your_iteration_id>"

# Set PAT env var as ADO_PAT_<org_with_dashes_replaced_by_underscores>
# Example: my-org -> ADO_PAT_my_org
export ADO_PAT_<your_org_with_dashes_replaced_by_underscores>="<your_pat>"
bash .github/skills/get-pr-details/get-pr-details.sh "$ORG" "$PROJECT" "$REPO" "$PR"
```

Use this for a fast smoke test. For full setup (including validation and command examples),
follow [Setup Instructions](#setup-instructions).

## Requirements

- Bash shell (macOS/Linux natively; on Windows use **Git Bash** or **WSL** — CMD and
  PowerShell are only supported for setting environment variables, not for running the
  skill scripts)
- `curl`
- `python3`
- `base64` utility (standard on macOS/Linux and Git Bash)
- Azure DevOps Personal Access Token (PAT) with **Code** scope (read/write as needed)

Quick check:

```bash
bash --version
curl --version
python3 --version
```

## Setup Instructions

1. Clone this repository (or copy the skill files into your existing repo).
2. Set the Azure DevOps PAT environment variable (`ADO_PAT_<org_with_dashes_replaced_by_underscores>`) — see
  [Environment Variables](#environment-variables-os-specific) below.
3. If you use placeholder examples in prompts/commands, replace
  `default_organization`, `project`, and
  `repository` with your real values.
4. *(Optional)* Validate skill connectivity/authentication:
   ```bash
   ./scripts/validate-skills.sh "<org>" "<project>" "<repo>" "<pr_id>" "<iteration_id>"
   ```
   Advanced options and reusable wrappers are in [Validation (Optional)](#validation-optional).
5. Start reviewing — open the Copilot chat and use the reviewer prompt command:
    ```text
    /code-reviewer review pr 1
    ```
    Using the command form helps force the agent to use the predefined prompt and skills.
    If the agent cannot determine the organization, project, or repository from context
    (e.g., from the git remote of the cloned repo or prompt defaults), it will ask.
    You can also be explicit:
    ```text
    /code-reviewer review pr 1 in myorg/myproject/myrepo
    ```

## Prompt Examples (Voting)

Use these prompt examples in Copilot chat:

```text
/code-reviewer approve pr 1
/code-reviewer approve with suggestions pr 1
/code-reviewer wait for author pr 1
/code-reviewer reject pr 1
/code-reviewer reset feedback pr 1
```

Legend: `approve=10`, `approve with suggestions=5`, `wait for author=-5`, `reject=-10`, `reset feedback=0`.

Explicit org/project/repo form:

```text
/code-reviewer approve pr 1 in myorg/myproject/myrepo
/code-reviewer approve with suggestions pr 1 in myorg/myproject/myrepo
/code-reviewer wait for author pr 1 in myorg/myproject/myrepo
/code-reviewer reject pr 1 in myorg/myproject/myrepo
/code-reviewer reset feedback pr 1 in myorg/myproject/myrepo
```

## Environment Variables (OS-specific)

Each skill reads the Azure DevOps PAT from an environment variable named
`ADO_PAT_<org_with_dashes_replaced_by_underscores>`.

Rule: take your Azure DevOps organization from the URL and replace `-` with `_`.

Example: organization `my-org` => env var `ADO_PAT_my_org`.

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

### Windows (for setting PAT only — run scripts in Git Bash or WSL)

PowerShell — current session:

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

## Copying Files to Another Repository

If you want to reuse these skills in another repository, copy the following paths:

- `.github/copilot/code-reviewer.prompt.md`
- `.github/skills/` (entire folder, including all `SKILL.md` and `.sh` files)
- `scripts/validate-skills.sh`

Example from this repo root:

```bash
TARGET_REPO=/path/to/your-repo

mkdir -p "$TARGET_REPO/.github/copilot" "$TARGET_REPO/.github/skills" "$TARGET_REPO/scripts"
cp .github/copilot/code-reviewer.prompt.md "$TARGET_REPO/.github/copilot/"
cp -R .github/skills/* "$TARGET_REPO/.github/skills/"
cp scripts/validate-skills.sh "$TARGET_REPO/scripts/"
```

Then, in the target repo:

```bash
cd /path/to/your-repo
chmod +x .github/skills/*/*.sh scripts/validate-skills.sh
# optional: validate the setup
./scripts/validate-skills.sh "<org>" "<project>" "<repo>" "<pr_id>" "<iteration_id>"
```

## Skills Description

All skills are bash scripts that call Azure DevOps REST API (`api-version=7.2-preview`).

| Skill | Script | Description |
|---|---|---|
| `get-pr-details` | `.github/skills/get-pr-details/get-pr-details.sh` | Fetches PR metadata: title, status, source/target branches, reviewers, merge data. |
| `get-pr-threads` | `.github/skills/get-pr-threads/get-pr-threads.sh` | Fetches PR discussion/comment threads, including inline comments and system messages. |
| `get-pr-iterations` | `.github/skills/get-pr-iterations/get-pr-iterations.sh` | Lists PR iterations (push updates). |
| `get-pr-changes` | `.github/skills/get-pr-changes/get-pr-changes.sh` | Lists changed files for a specific PR iteration. |
| `get-file-content` | `.github/skills/get-file-content/get-file-content.sh` | Gets file content for a specific path and version (branch/commit/tag). |
| `get-commit-diffs` | `.github/skills/get-commit-diffs/get-commit-diffs.sh` | Returns diff summary between two versions. |
| `list-repositories` | `.github/skills/list-repositories/list-repositories.sh` | Lists repositories in a project. |
| `list-projects` | `.github/skills/list-projects/list-projects.sh` | Lists projects in an organization. |
| `post-pr-comment` | `.github/skills/post-pr-comment/post-pr-comment.sh` | Posts a comment thread on a PR (inline or general). |
| `update-pr-thread` | `.github/skills/update-pr-thread/update-pr-thread.sh` | Replies to a comment thread and/or updates its status (fixed, closed, etc.). |
| `accept-pr` | `.github/skills/accept-pr/accept-pr.sh` | Approves (accepts) a pull request by casting an Approve vote. |
| `approve-with-suggestions` | `.github/skills/approve-with-suggestions/approve-with-suggestions.sh` | Casts an Approve with suggestions vote on a pull request. |
| `wait-for-author` | `.github/skills/wait-for-author/wait-for-author.sh` | Casts a Waiting for author vote on a pull request. |
| `reject-pr` | `.github/skills/reject-pr/reject-pr.sh` | Casts a Rejected vote on a pull request. |
| `reset-feedback` | `.github/skills/reset-feedback/reset-feedback.sh` | Resets reviewer vote to No vote on a pull request. |

## Before First Review

Before the first review in a repository, tell the reviewer where your standards/guides live (if you use custom paths).

Example:

```text
/code-reviewer review pr 1 in myorg/myproject/myrepo.
Standards/guides are in docs/engineering/standards.md and docs/guides/.
```

If you do not specify paths, the reviewer checks common defaults (`README*`,
`CONTRIBUTING.md`, `.editorconfig`, `docs/`, linter/formatter configs).

**Recommended:** update `.github/copilot/code-reviewer.prompt.md` with
repository-specific standards paths so they apply by default.

> Source alignment note: reviewer behavior and decision rules in the prompt file are
> aligned with [Google Engineering Practices — Reviewer Guide](https://google.github.io/eng-practices/review/reviewer/).

## Typical Review Flow

1. `get-pr-details` to identify source and target branches.
2. Resolve standards/guides locations (user-provided or default paths).
3. `get-pr-iterations` to find the latest iteration.
4. `get-pr-changes` to list modified files.
5. `get-file-content` to compare file versions (target branch and source branch).
6. `get-pr-threads` to avoid duplicate comments.
7. Optional: `get-commit-diffs` for a high-level diff summary.
8. `post-pr-comment` to publish selected findings.
9. `update-pr-thread` to reply and resolve threads.

## Validation (Optional)

Run all skill checks to confirm authentication and connectivity:

```bash
./scripts/validate-skills.sh "<org>" "<project>" "<repo>" "<pr_id>" "<iteration_id>"
```

Reusable wrappers:

- Generic template for local customization:
  ```bash
  cp scripts/validate-skill-template.sh scripts/validate-skill-local.sh
  # edit scripts/validate-skill-local.sh with your values, then:
  ./scripts/validate-skill-local.sh
  ```

Optional repository-specific validation inputs:

- `tested_file_path` — file path used by `get-file-content` check (example: `/README.md`)
- `branch_base` and `branch_target` — versions used by `get-commit-diffs` and
  file-version checks (examples: `main`, `feature/my-change`)

Pass them as extra args:

```bash
./scripts/validate-skills.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION" "/README.md" "main" "feature/my-change"
```

Or set environment variables before running validation:

```bash
export TESTED_FILE_PATH="/README.md"
export BRANCH_BASE="main"
export BRANCH_TARGET="feature/my-change"
./scripts/validate-skills.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION"
```

Validation is non-mutating by default. Mutating checks (such as `accept-pr`,
`approve-with-suggestions`, `wait-for-author`, `reject-pr`, and `reset-feedback`) are
skipped unless explicitly enabled:

```bash
ENABLE_MUTATING_CHECKS=true ./scripts/validate-skills.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION"
```

## Where to Find Values

Use these sources for the variables used in examples (`ORG`, `PROJECT`, `REPO`, `PR`, `ITERATION`, `THREAD_ID`):

- `ORG` (organization): the first segment in your Azure DevOps URL, e.g. `https://dev.azure.com/<org>/...`
- `PROJECT`: project name (or ID) from Azure DevOps Project list, or run
  `bash .github/skills/list-projects/list-projects.sh "$ORG"`.
- `REPO`: repository name (or ID) from Repos > Files, or run
  `bash .github/skills/list-repositories/list-repositories.sh "$ORG" "$PROJECT"`.
- `PR`: pull request number from the PR URL and title bar (example: `.../pullrequest/123` => `PR=123`).
- `ITERATION`: latest push iteration from
  `bash .github/skills/get-pr-iterations/get-pr-iterations.sh "$ORG" "$PROJECT" "$REPO" "$PR"`;
  use the highest `id` in `value[]`.
- `THREAD_ID`: thread `id` from
  `bash .github/skills/get-pr-threads/get-pr-threads.sh "$ORG" "$PROJECT" "$REPO" "$PR"`
  for reply/resolve actions.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `401 Unauthorized` | PAT is missing, expired, or wrong org name in env var | Verify `ADO_PAT_<org_with_dashes_replaced_by_underscores>` is set and the PAT is valid (example: `my-org` => `ADO_PAT_my_org`) |
| `command not found: python3` | Python 3 not installed or not on PATH | Install Python 3 and ensure `python3` is available |
| `base64: invalid option` | GNU vs BSD flag mismatch | Scripts already handle this — ensure you're using the repo version |
| `Permission denied` on `.sh` files | Scripts not marked executable | Run `chmod +x .github/skills/*/*.sh scripts/*.sh` |
| Validation fails but skills work | PR or iteration ID is stale/invalid | Re-check `PR` and `ITERATION` values (see [Where to Find Values](#where-to-find-values)) |
| Scripts fail on Windows CMD/PowerShell | Bash required | Use **Git Bash** or **WSL** to run scripts |

## Contributing

Contributions are welcome. Please open an issue or pull request.

---

*This project is not affiliated with or endorsed by Microsoft or Google.*