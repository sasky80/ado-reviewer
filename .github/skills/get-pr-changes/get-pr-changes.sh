#!/usr/bin/env bash
# Fetch file changes for a specific iteration of a pull request
# Usage: ./get-pr-changes.sh <organization> <project> <repositoryId> <pullRequestId> <iterationId>

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

curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/iterations/${ITERATION_ID}/changes?api-version=7.2-preview"
