#!/usr/bin/env bash
# Shared bash utilities for ADO skills (mirrors AdoSkillUtils.ps1)
# Source this file from skill scripts:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/../common/ado-utils.sh"

# Ensure python3 is available (used for URL encoding and JSON construction)
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but not found on PATH" >&2
  exit 1
fi

# URL-encode a string (RFC 3986)
urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

# Normalize an organization name into an env-var suffix.
# Replaces non-[A-Za-z0-9_] with _, prefixes _ if it starts with a digit.
get_pat_suffix() {
  local org="$1"
  local suffix="${org//[^A-Za-z0-9_]/_}"
  if [[ "$suffix" =~ ^[0-9] ]]; then
    suffix="_${suffix}"
  fi
  printf '%s' "$suffix"
}

# Retrieve the ADO PAT from the environment for the given organization.
# Exits with an error if not set.
get_pat() {
  local org="$1"
  local suffix
  suffix="$(get_pat_suffix "$org")"
  local pat_var="ADO_PAT_${suffix}"
  local pat
  pat="$(printenv "$pat_var" || true)"
  if [[ -z "$pat" ]]; then
    echo "Environment variable $pat_var is not set" >&2
    exit 1
  fi
  printf '%s' "$pat"
}

# Build the Basic auth header value from a PAT.
build_auth() {
  local pat="$1"
  printf ":%s" "$pat" | base64 | tr -d '\n'
}

# Initialize ADO context variables for a given organization.
# Sets: ADO_PAT, ADO_AUTH, ORG_ENC
# Usage: ado_init "$ORG"
ado_init() {
  local org="$1"
  ADO_PAT="$(get_pat "$org")"
  ADO_AUTH="$(build_auth "$ADO_PAT")"
  ORG_ENC="$(urlencode "$org")"
}

# Normalize a file path to Azure DevOps canonical repository-relative format.
# - Converts backslashes to forward slashes
# - Removes leading ./ segments
# - Collapses duplicate slashes
# - Ensures a leading /
# Rejects local absolute paths (e.g. C:/..., //server/share)
normalize_ado_file_path() {
  local file_path="$1"

  if [[ "$file_path" == "-" || -z "$file_path" ]]; then
    printf '%s' "$file_path"
    return 0
  fi

  local normalized="$file_path"

  normalized="${normalized#"${normalized%%[![:space:]]*}"}"
  normalized="${normalized%"${normalized##*[![:space:]]}"}"
  normalized="${normalized//\\//}"

  if [[ "$normalized" =~ ^[A-Za-z]:/ || "$normalized" =~ ^// ]]; then
    echo "FilePath must be repository-relative (for example: /src/app.js). Received: '$file_path'" >&2
    return 1
  fi

  while [[ "$normalized" == ./* ]]; do
    normalized="${normalized#./}"
  done

  while [[ "$normalized" == *//* ]]; do
    normalized="${normalized//\/\//\/}"
  done

  if [[ "$normalized" != /* ]]; then
    normalized="/$normalized"
  fi

  printf '%s' "$normalized"
}
