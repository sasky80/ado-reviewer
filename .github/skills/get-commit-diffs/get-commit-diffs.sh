#!/usr/bin/env bash
# Fetch diff between two commits/branches/tags in an Azure DevOps Git repository
# Usage: ./get-commit-diffs.sh <organization> <project> <repositoryId> <baseVersion> <targetVersion> [baseVersionType] [targetVersionType]

set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <baseVersion> <targetVersion> [baseVersionType] [targetVersionType]" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
BASE_VERSION="$4"
TARGET_VERSION="$5"
BASE_VERSION_TYPE="${6:-commit}"
TARGET_VERSION_TYPE="${7:-commit}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

BASE_VERSION_ENC="$(urlencode "$BASE_VERSION")"
TARGET_VERSION_ENC="$(urlencode "$TARGET_VERSION")"

curl -s --fail-with-body --max-time 30 \
  -H "Authorization: Basic ${ADO_AUTH}" \
  -H "Accept: application/json" \
  "https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/diffs/commits?baseVersion=${BASE_VERSION_ENC}&baseVersionType=${BASE_VERSION_TYPE}&targetVersion=${TARGET_VERSION_ENC}&targetVersionType=${TARGET_VERSION_TYPE}&api-version=7.2-preview"
