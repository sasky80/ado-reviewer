#!/usr/bin/env bash
# List all Git repositories in an Azure DevOps project
# Usage: ./list-repositories.sh <organization> <project>

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <organization> <project>" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"

curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories?api-version=7.2-preview"
