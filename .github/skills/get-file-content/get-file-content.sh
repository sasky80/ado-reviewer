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
FILE_PATH_ENC="$(urlencode "$FILE_PATH")"

ENCODED=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

URL="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/items?path=${FILE_PATH_ENC}&includeContent=true&api-version=7.2-preview"

if [[ -n "$VERSION" ]]; then
  URL="${URL}&versionDescriptor.version=$(urlencode "$VERSION")&versionDescriptor.versionType=${VERSION_TYPE}"
fi

curl -s --fail-with-body \
  -H "Authorization: Basic ${ENCODED}" \
  -H "Accept: application/json" \
  "$URL"
