#!/usr/bin/env bash
# List all projects in an Azure DevOps organization
# Usage: ./list-projects.sh [organization]

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <organization>" >&2
  exit 1
fi

ORG="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"

curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/_apis/projects?api-version=7.2-preview"
