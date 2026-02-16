#!/usr/bin/env bash
# Fetch pull request comment threads from Azure DevOps REST API
# Usage: ./get-pr-threads.sh <organization> <project> <repositoryId> <pullRequestId> [statusFilter] [excludeSystem]
#
# Optional filters (applied client-side after fetching all threads):
#   statusFilter  — keep only threads with this status (e.g. "active", "fixed", "closed"). Default: all.
#   excludeSystem — "true" to remove system-generated threads (vote changes, ref updates). Default: "false".

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <pullRequestId> [statusFilter] [excludeSystem]" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
PR_ID="$4"
STATUS_FILTER="${5:-}"
EXCLUDE_SYSTEM="${6:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

RAW_OUTPUT=$(curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/threads?api-version=7.2-preview")

# Apply client-side filters if requested
if [[ -n "$STATUS_FILTER" || "$EXCLUDE_SYSTEM" == "true" ]]; then
  echo "$RAW_OUTPUT" | python3 -c "
import sys, json

data = json.load(sys.stdin)
threads = data.get('value', [])

status_filter = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else ''
exclude_system = sys.argv[2] if len(sys.argv) > 2 else 'false'

filtered = []
for t in threads:
    # Exclude system threads (identified by CodeReviewThreadType property or system author)
    if exclude_system == 'true':
        props = t.get('properties', {}) or {}
        if any(k.startswith('CodeReview') for k in props):
            continue
        comments = t.get('comments', [])
        if comments and all(
            c.get('commentType', '') == 'system'
            or c.get('author', {}).get('displayName', '').startswith('Microsoft.')
            for c in comments
        ):
            continue

    # Filter by status
    if status_filter and t.get('status', '') != status_filter:
        continue

    filtered.append(t)

data['value'] = filtered
data['count'] = len(filtered)
print(json.dumps(data))
" "$STATUS_FILTER" "$EXCLUDE_SYSTEM"
else
  echo "$RAW_OUTPUT"
fi
