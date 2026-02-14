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

ENCODED=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

curl -s --fail-with-body \
  -H "Authorization: Basic ${ENCODED}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories?api-version=7.2-preview"
