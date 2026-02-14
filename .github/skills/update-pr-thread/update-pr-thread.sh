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

urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

PAT_SUFFIX="${ORG//[^A-Za-z0-9_]/_}"
if [[ "$PAT_SUFFIX" =~ ^[0-9] ]]; then
  PAT_SUFFIX="_${PAT_SUFFIX}"
fi
PAT_VAR="ADO_PAT_${PAT_SUFFIX}"
PAT="$(printenv "$PAT_VAR" || true)"
if [[ -z "$PAT" ]]; then
  echo "Environment variable $PAT_VAR is not set" >&2
  exit 1
fi

ORG_ENC="$(urlencode "$ORG")"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

ENCODED=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

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

  curl -s --fail-with-body \
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

  curl -s --fail-with-body \
    -X PATCH \
    -H "Authorization: Basic ${ENCODED}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$STATUS_BODY" \
    "${THREAD_URL}?api-version=7.2-preview"
fi
