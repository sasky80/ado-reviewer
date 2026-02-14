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

REVIEWER_ID=$(curl -s --fail-with-body \
  -H "Authorization: Basic ${ENCODED}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/_apis/connectionData" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['authenticatedUser']['id'])")

VOTE_BODY='{"vote":-5}'

curl -s --fail-with-body \
  -X PUT \
  -H "Authorization: Basic ${ENCODED}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$VOTE_BODY" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/reviewers/${REVIEWER_ID}?api-version=7.2-preview"
