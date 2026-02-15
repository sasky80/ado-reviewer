#!/usr/bin/env bash
# Fetch file content from an Azure DevOps Git repository
# Usage: ./get-file-content.sh <organization> <project> <repositoryId> <path> [version] [versionType]

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <path> [version] [versionType]" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
FILE_PATH="$4"
VERSION="${5:-}"
VERSION_TYPE="${6:-branch}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"
FILE_PATH_ENC="$(urlencode "$FILE_PATH")"

URL="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/items?path=${FILE_PATH_ENC}&includeContent=true&api-version=7.2-preview"

if [[ -n "$VERSION" ]]; then
  URL="${URL}&versionDescriptor.version=$(urlencode "$VERSION")&versionDescriptor.versionType=${VERSION_TYPE}"
fi

curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "$URL"
