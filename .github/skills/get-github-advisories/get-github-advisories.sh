#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <ecosystem> <package> [version] [severity] [per_page]" >&2
  echo "Example: $0 npm lodash 4.17.20 high 30" >&2
  exit 1
fi

ECOSYSTEM="$1"
PACKAGE="$2"
VERSION="${3:-}"
SEVERITY="${4:-}"
PER_PAGE="${5:-30}"

if ! [[ "$PER_PAGE" =~ ^[0-9]+$ ]] || (( PER_PAGE < 1 || PER_PAGE > 100 )); then
  echo "per_page must be an integer between 1 and 100" >&2
  exit 1
fi

GH_TOKEN="${GH_SEC_PAT:-}"
if [[ -z "$GH_TOKEN" ]]; then
  echo "Environment variable GH_SEC_PAT is not set" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but not found on PATH" >&2
  exit 1
fi

urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

AFFECTS="$PACKAGE"
if [[ -n "$VERSION" ]]; then
  AFFECTS="${PACKAGE}@${VERSION}"
fi

QUERY="ecosystem=$(urlencode "$ECOSYSTEM")&affects=$(urlencode "$AFFECTS")&per_page=$PER_PAGE"
if [[ -n "$SEVERITY" ]]; then
  QUERY+="&severity=$(urlencode "$SEVERITY")"
fi

response="$(curl -s --fail-with-body --max-time 30 \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  "https://api.github.com/advisories?${QUERY}")"

printf '%s' "$response" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(json.dumps(data if isinstance(data, list) else [], separators=(",",":")))'
