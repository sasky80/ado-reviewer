# skills-go

Go-based skill runner for clean installations.

## Current command

- `check-deprecated-dependencies <ecosystem> <package> [version]`
- `list-projects <organization>`
- `list-repositories <organization> <project>`
- `get-pr-details <organization> <project> <repositoryId> <pullRequestId>`
- `get-pr-iterations <organization> <project> <repositoryId> <pullRequestId>`
- `get-pr-changes <organization> <project> <repositoryId> <pullRequestId> <iterationId>`
- `get-pr-changed-files <organization> <project> <repositoryId> <pullRequestId> <iterationId>`
- `get-pr-threads <organization> <project> <repositoryId> <pullRequestId> [statusFilter] [excludeSystem]`
- `post-pr-comment <organization> <project> <repositoryId> <pullRequestId> <filePath> <line> <comment>`
- `update-pr-thread <organization> <project> <repositoryId> <pullRequestId> <threadId> [reply] [status]`
- `get-file-content <organization> <project> <repositoryId> <path> [version] [versionType]`
- `get-multiple-files <organization> <project> <repositoryId> <version> <versionType> '<json_paths_array>'`
- `get-commit-diffs <organization> <project> <repositoryId> <baseVersion> <targetVersion> [baseVersionType] [targetVersionType]`
- `get-github-advisories <ecosystem> <package> [version] [severity] [per_page]`
- `get-pr-dependency-advisories <organization> <project> <repositoryId> <pullRequestId> [iterationId] [per_page]`
- `get-pr-diff-line-mapper <organization> <project> <repositoryId> <pullRequestId> <iterationId>`
- `accept-pr <organization> <project> <repositoryId> <pullRequestId>`
- `approve-with-suggestions <organization> <project> <repositoryId> <pullRequestId>`
- `wait-for-author <organization> <project> <repositoryId> <pullRequestId>`
- `reject-pr <organization> <project> <repositoryId> <pullRequestId>`
- `reset-feedback <organization> <project> <repositoryId> <pullRequestId>`

Supported ecosystems:

- `npm`
- `pip` (alias supported by caller: `pypi`)
- `nuget`

## Build

```bash
go build ./cmd/skills-go
```

Or install directly:

```bash
go install ./cmd/skills-go
```

## Run

```bash
go run ./cmd/skills-go check-deprecated-dependencies npm request 2.88.2
```

```bash
go run ./cmd/skills-go list-projects myorg
```

```bash
go run ./cmd/skills-go list-repositories myorg MyProject
```

```bash
go run ./cmd/skills-go get-pr-details myorg MyProject MyRepo 42
```

```bash
go run ./cmd/skills-go get-pr-iterations myorg MyProject MyRepo 42
```

```bash
go run ./cmd/skills-go get-pr-changed-files myorg MyProject MyRepo 42 13
```

Output is normalized compact JSON:

```json
{"ecosystem":"npm","package":"request","version":"2.88.2","deprecated":true,"message":"...","replacement":"..."}
```

## Integration tests (optional)

Live integration tests are env-gated and skip automatically unless configured.

Required:

- `ADO_IT_ORG`
- `ADO_IT_PROJECT`
- `ADO_IT_REPO`
- `ADO_IT_PR`
- `ADO_PAT_<normalized_org>` (same normalization rules as runtime)

For advisory integration tests:

- `GH_SEC_PAT`

Optional:

- `ADO_IT_ITERATION` (if omitted, tests use latest iteration)

Run:

```bash
go test ./...
```

Skip live tests explicitly:

```bash
go test -short ./...
```
