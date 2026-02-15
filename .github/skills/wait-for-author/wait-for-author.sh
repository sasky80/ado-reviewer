#!/usr/bin/env bash
# Mark an Azure DevOps pull request vote as "Waiting for author".
# Usage: ./wait-for-author.sh <organization> <project> <repositoryId> <pullRequestId>

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <pullRequestId>" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
PR_ID="$4"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

REVIEWER_ID=$(curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/_apis/connectionData" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['authenticatedUser']['id'])")

VOTE_BODY='{"vote":-5}'

curl -s --fail-with-body --max-time 30 \
  -X PUT \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$VOTE_BODY" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/reviewers/${REVIEWER_ID}?api-version=7.2-preview"
