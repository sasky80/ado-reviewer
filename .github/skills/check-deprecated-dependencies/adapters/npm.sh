#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <package> [version]" >&2
  exit 1
fi

PACKAGE="$1"
VERSION="${2:-}"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm command is required" >&2
  exit 1
fi

SPEC="$PACKAGE"
if [[ -n "$VERSION" ]]; then
  SPEC="${PACKAGE}@${VERSION}"
fi

RAW=""
if ! RAW="$(npm view "$SPEC" deprecated --json 2>/dev/null)"; then
  echo "Failed to query npm metadata for $SPEC" >&2
  exit 1
fi

RAW_VALUE="$RAW" python3 - "$PACKAGE" "$VERSION" <<'PY'
import json,re,sys
import os
package,version=sys.argv[1:3]
raw=(os.environ.get("RAW_VALUE") or "").strip()
if not raw:
    value=None
else:
    try:
        value=json.loads(raw)
    except Exception:
        value=raw

message=""
if isinstance(value, str):
    message=value.strip()

deprecated=bool(message)
replacement=""
if message:
    m=re.search(r'(?:use|switch to|migrate to)\s+([@A-Za-z0-9_./-]+)', message, re.IGNORECASE)
    if m:
        replacement=m.group(1)

print(json.dumps({
  "ecosystem":"npm",
  "package":package,
  "version":version,
  "deprecated":deprecated,
  "message":message,
  "replacement":replacement
}, separators=(",",":")))
PY
