#!/usr/bin/env bash
# Reply to a comment thread and/or update its status on an Azure DevOps pull request
# Usage: ./update-pr-thread.sh <organization> <project> <repositoryId> <pullRequestId> <threadId> [reply] [status]
#
# If reply is provided (and not "-"), posts it as a reply to the thread.
# If status is provided, updates the thread status (active, fixed, closed, byDesign, pending, wontFix).
# At least one of reply or status must be provided.

set -euo pipefail

if [[ $# -lt 6 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <pullRequestId> <threadId> [reply] [status]" >&2
  echo "  reply  - Reply text (use \"-\" to skip)" >&2
  echo "  status - Thread status: active, fixed, closed, byDesign, pending, wontFix" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
PR_ID="$4"
THREAD_ID="$5"
REPLY="${6:--}"
STATUS="${7:-}"

if [[ "$REPLY" == "-" && -z "$STATUS" ]]; then
  echo "Error: at least one of reply or status must be provided." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

ENCODED="${ADO_AUTH}"

THREAD_URL="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/threads/${THREAD_ID}"

# Post reply if provided
if [[ "$REPLY" != "-" && -n "$REPLY" ]]; then
  COMMENT_BODY=$(python3 -c "
import json, sys
print(json.dumps({
    'content': sys.argv[1],
    'parentCommentId': 1,
    'commentType': 'text'
}))
" "$REPLY")

  curl -s --fail-with-body --max-time 30 \
    -X POST \
    -H "Authorization: Basic ${ENCODED}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$COMMENT_BODY" \
    "${THREAD_URL}/comments?api-version=7.2-preview"
fi

# Update thread status if provided
if [[ -n "$STATUS" ]]; then
  STATUS_BODY=$(python3 -c "
import json, sys
print(json.dumps({'status': sys.argv[1]}))
" "$STATUS")

  curl -s --fail-with-body --max-time 30 \
    -X PATCH \
    -H "Authorization: Basic ${ENCODED}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$STATUS_BODY" \
    "${THREAD_URL}?api-version=7.2-preview"
fi
