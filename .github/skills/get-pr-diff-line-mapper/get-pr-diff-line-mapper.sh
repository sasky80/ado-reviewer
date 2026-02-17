#!/usr/bin/env bash
# Map PR changes to line-level diff hunks for a specific iteration.
# Usage: ./get-pr-diff-line-mapper.sh <organization> <project> <repositoryId> <pullRequestId> <iterationId>

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

python3 "$SCRIPT_DIR/pr-diff-line-mapper.py" \
  --org-enc "$ORG_ENC" \
  --project-enc "$PROJECT_ENC" \
  --repo-enc "$REPO_ID_ENC" \
  --pull-request-id "$PR_ID" \
  --iteration-id "$ITERATION_ID" \
  --auth-basic "$ADO_AUTH"
