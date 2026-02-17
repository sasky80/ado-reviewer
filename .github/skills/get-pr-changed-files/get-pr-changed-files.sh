#!/usr/bin/env bash
# Fetch a projected list of changed files for a PR iteration (path + change type)
# Usage: ./get-pr-changed-files.sh <organization> <project> <repositoryId> <pullRequestId> <iterationId>

set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <pullRequestId> <iterationId>" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
PR_ID="$4"
ITERATION_ID="$5"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

RAW_JSON="$(curl -s --fail-with-body --max-time 30 \
    -H "Authorization: Basic ${ADO_AUTH}" \
    -H "Accept: application/json" \
    "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/iterations/${ITERATION_ID}/changes?api-version=7.2-preview")"

printf '%s' "$RAW_JSON" | python3 - "$PR_ID" "$ITERATION_ID" <<'PYEOF'
import json
import sys

payload = json.load(sys.stdin)
pr_id = sys.argv[1]
iteration_id = sys.argv[2]

files = []
for entry in payload.get("changeEntries", []):
    item = entry.get("item") or {}
    path = item.get("path") or entry.get("originalPath")
    if not path:
        continue

    files.append(
        {
            "path": path,
            "changeType": entry.get("changeType"),
            "changeTrackingId": entry.get("changeTrackingId"),
            "isFolder": bool(item.get("isFolder", False)),
        }
    )

result = {
    "pullRequestId": pr_id,
    "iterationId": iteration_id,
    "count": len(files),
    "files": files,
}

print(json.dumps(result))
PYEOF
