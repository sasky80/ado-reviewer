#!/usr/bin/env bash
# Create a comment thread on an Azure DevOps pull request
# Usage: ./post-pr-comment.sh <organization> <project> <repositoryId> <pullRequestId> <filePath> <line> <comment>
#
# Creates an inline comment on a specific file/line. If filePath is empty or "-",
# creates a general (non-file-specific) comment instead.

set -euo pipefail

if [[ $# -lt 7 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <pullRequestId> <filePath> <line> <comment>" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
PR_ID="$4"
FILE_PATH="${5:--}"
LINE="${6:-0}"
COMMENT="$7"

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

# Build the entire JSON body safely using Python to avoid injection
if [[ "$FILE_PATH" == "-" || -z "$FILE_PATH" ]]; then
  BODY=$(python3 -c "
import json, sys
comment = sys.argv[1]
print(json.dumps({
    'comments': [{'parentCommentId': 0, 'content': comment, 'commentType': 'text'}],
    'status': 'active'
}))
" "$COMMENT")
else
  LINE_NUM=${LINE:-1}
  BODY=$(python3 -c "
import json, sys
comment, fpath, line_num = sys.argv[1], sys.argv[2], int(sys.argv[3])
print(json.dumps({
    'comments': [{'parentCommentId': 0, 'content': comment, 'commentType': 'text'}],
    'status': 'active',
    'threadContext': {
        'filePath': fpath,
        'rightFileStart': {'line': line_num, 'offset': 1},
        'rightFileEnd': {'line': line_num, 'offset': 1}
    }
}))
" "$COMMENT" "$FILE_PATH" "$LINE_NUM")
fi

curl -s --fail-with-body \
  -X POST \
  -H "Authorization: Basic ${ENCODED}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$BODY" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/threads?api-version=7.2-preview"
