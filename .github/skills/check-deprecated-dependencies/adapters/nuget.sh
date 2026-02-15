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
import json,sys,urllib.error,urllib.parse,urllib.request

package,version=sys.argv[1:3]
package_lower=package.lower()
index_url=f"https://api.nuget.org/v3/registration5-semver1/{urllib.parse.quote(package_lower)}/index.json"

def get_json(url):
    with urllib.request.urlopen(url, timeout=25) as r:
        return json.load(r)

try:
    root=get_json(index_url)
except urllib.error.HTTPError as e:
    raise SystemExit(f"Failed to query NuGet metadata for {package}{('@'+version) if version else ''}: HTTP {e.code}")

entries=[]
for page in root.get("items") or []:
    if isinstance(page, dict) and page.get("items"):
        for item in page.get("items") or []:
            if isinstance(item, dict):
                entries.append(item)
    elif isinstance(page, dict) and page.get("@id"):
        try:
            page_json=get_json(page.get("@id"))
            for item in page_json.get("items") or []:
                if isinstance(item, dict):
                    entries.append(item)
        except Exception:
            continue

if not entries:
    raise SystemExit(f"No NuGet versions found for {package}")

selected=None
if version:
    for item in entries:
        catalog=item.get("catalogEntry") or {}
        if str(catalog.get("version", "")).lower()==version.lower():
            selected=item
            break
    if selected is None:
        raise SystemExit(f"Version {version} not found for NuGet package {package}")
else:
    selected=entries[-1]
    catalog=selected.get("catalogEntry") or {}
    version=str(catalog.get("version") or "")

catalog=selected.get("catalogEntry") or {}
dep_info=catalog.get("deprecation")
deprecated=isinstance(dep_info, dict) and bool(dep_info)
message=""
replacement=""

if deprecated:
    reasons=dep_info.get("reasons")
    if isinstance(reasons, list) and reasons:
        message="; ".join([str(r) for r in reasons if str(r).strip()])
    alt=dep_info.get("alternatePackage")
    if isinstance(alt, dict):
        alt_id=str(alt.get("id") or "").strip()
        alt_range=str(alt.get("range") or "").strip()
        if alt_id and alt_range:
            replacement=f"{alt_id} {alt_range}"
        elif alt_id:
            replacement=alt_id
    if not message:
        message="Package version is marked as deprecated in NuGet metadata"

print(json.dumps({
  "ecosystem":"nuget",
  "package":package,
  "version":version,
  "deprecated":deprecated,
  "message":message,
  "replacement":replacement
}, separators=(",",":")))
PY
