---
name: check-deprecated-dependencies
description: Check whether a dependency is deprecated across ecosystems (npm, pip, nuget) using a single normalized interface.
---

# Check Deprecated Dependencies

## Platform Note

- macOS/Linux: run `.sh` scripts
- Windows: run `.ps1` scripts via `pwsh -ExecutionPolicy Bypass -File <script.ps1> ...` with the same argument order

Run [check-deprecated-dependencies.sh](./check-deprecated-dependencies.sh) on macOS/Linux or [check-deprecated-dependencies.ps1](./check-deprecated-dependencies.ps1) on Windows.

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
bash .github/skills/check-deprecated-dependencies/check-deprecated-dependencies.sh npm request 2.88.2
```

```powershell
pwsh -ExecutionPolicy Bypass -File .github/skills/check-deprecated-dependencies/check-deprecated-dependencies.ps1 nuget Newtonsoft.Json 13.0.1
```

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
