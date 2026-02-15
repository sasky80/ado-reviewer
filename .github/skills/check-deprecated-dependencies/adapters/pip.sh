#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <package> [version]" >&2
  exit 1
fi

PACKAGE="$1"
VERSION="${2:-}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

python3 - "$PACKAGE" "$VERSION" <<'PY'
import json,re,sys,urllib.error,urllib.parse,urllib.request

package,version=sys.argv[1:3]
base="https://pypi.org/pypi/"
if version:
    url=f"{base}{urllib.parse.quote(package)}/{urllib.parse.quote(version)}/json"
else:
    url=f"{base}{urllib.parse.quote(package)}/json"

try:
    with urllib.request.urlopen(url, timeout=20) as r:
        data=json.load(r)
except urllib.error.HTTPError as e:
    raise SystemExit(f"Failed to query PyPI metadata for {package}{('@'+version) if version else ''}: HTTP {e.code}")

info=data.get("info") or {}
summary=(info.get("summary") or "").strip()
description=(info.get("description") or "")
classifiers=info.get("classifiers") or []
urls=data.get("urls") or []

deprecated=False
message=""
replacement=""

for file_item in urls:
    if not isinstance(file_item, dict):
        continue
    if file_item.get("yanked"):
        deprecated=True
        message=(file_item.get("yanked_reason") or "Package release is yanked").strip()
        break

if not deprecated and any(isinstance(c, str) and "Development Status :: 7 - Inactive" in c for c in classifiers):
    deprecated=True
    message="Package is marked as inactive by classifier"

if not deprecated:
    haystack=(summary+"\n"+description[:8000]).lower()
    if any(k in haystack for k in ("deprecated", "unmaintained", "obsolete", "no longer maintained")):
        deprecated=True
        message="Package metadata indicates deprecation or maintenance end"

if message:
    m=re.search(r'(?:use|switch to|migrate to)\s+([@A-Za-z0-9_./-]+)', message, re.IGNORECASE)
    if m:
        replacement=m.group(1)

print(json.dumps({
  "ecosystem":"pip",
  "package":package,
  "version":version,
  "deprecated":deprecated,
  "message":message,
  "replacement":replacement
}, separators=(",",":")))
PY
