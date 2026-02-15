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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

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
  FILE_PATH="$(normalize_ado_file_path "$FILE_PATH")"
  LINE_NUM=${LINE:-1}
  if [[ "$LINE_NUM" -lt 1 ]]; then
    LINE_NUM=1
  fi
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

curl -s --fail-with-body --max-time 30 \
  -X POST \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$BODY" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/threads?api-version=7.2-preview"
