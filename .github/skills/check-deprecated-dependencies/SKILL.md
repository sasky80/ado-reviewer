---
name: check-deprecated-dependencies
description: Check whether a dependency is deprecated across ecosystems (npm, pip, nuget) using a single normalized interface.
---

# Check Deprecated Dependencies

## Platform Note

- Clean-install path: use the Go command from `tools/skills-go`.

## What it does

1. Accepts a single normalized input: `ecosystem`, `package`, optional `version`.
2. Routes to an ecosystem-specific adapter (`npm`, `pip`, or `nuget`).
3. Returns normalized JSON for consistent downstream review logic.

## Supported ecosystems

- `npm`
- `pip` (alias: `pypi`)
- `nuget`

## Arguments

| # | Name | Required | Description |
|---|------|----------|-------------|
| 1 | ecosystem | Yes | `npm`, `pip`/`pypi`, or `nuget` |
| 2 | package | Yes | Package name |
| 3 | version | No | Package version to inspect |

## Examples

```bash
go run ./tools/skills-go/cmd/skills-go check-deprecated-dependencies pip requests
```

## Go implementation

- A Go implementation is available at `tools/skills-go`.
- The Go command `check-deprecated-dependencies` returns the same normalized JSON contract.

## Output

Returns compact JSON:

```json
{
  "ecosystem": "npm",
  "package": "request",
  "version": "2.88.2",
  "deprecated": true,
  "message": "request has been deprecated...",
  "replacement": "undici"
}
```

Notes:
- `deprecated=true` indicates explicit registry/package metadata signals deprecation (or yanked/explicitly inactive indicators where applicable).
- `replacement` is best-effort and may be empty.
