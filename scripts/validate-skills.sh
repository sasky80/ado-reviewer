#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <org> <project> <repo> <pr> <iteration> [tested_file_path] [branch_base] [branch_target]" >&2
  echo "No default values are used. Provide all values explicitly." >&2
  echo "For repository-specific checks, pass tested file and branches, or set TESTED_FILE_PATH/BRANCH_BASE/BRANCH_TARGET." >&2
  echo "Before first run, set values manually or use a dedicated wrapper (for example: scripts/validate-skill-template.sh)." >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO="$3"
PR="$4"
ITERATION="$5"
TESTED_FILE_PATH="${6:-${TESTED_FILE_PATH:-}}"
BRANCH_BASE="${7:-${BRANCH_BASE:-}}"
BRANCH_TARGET="${8:-${BRANCH_TARGET:-}}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PAT_SUFFIX="${ORG//[^A-Za-z0-9_]/_}"
if [[ "$PAT_SUFFIX" =~ ^[0-9] ]]; then
  PAT_SUFFIX="_${PAT_SUFFIX}"
fi
PAT_VAR="ADO_PAT_${PAT_SUFFIX}"
if [[ -z "$(printenv "$PAT_VAR" || true)" ]]; then
  echo "ERROR: missing PAT env var: ${PAT_VAR}" >&2
  echo "Set it first, e.g. export ${PAT_VAR}=<your_pat>" >&2
  exit 1
fi

if [[ -n "$TESTED_FILE_PATH" || -n "$BRANCH_BASE" || -n "$BRANCH_TARGET" ]]; then
  echo "Validation context: file=${TESTED_FILE_PATH:-<unset>}, base=${BRANCH_BASE:-<unset>}, target=${BRANCH_TARGET:-<unset>}"
else
  echo "Validation context: repository-specific checks disabled (set tested_file_path + branch_base + branch_target to enable)"
fi

PASS_COUNT=0
FAIL_COUNT=0

run_check() {
  local name="$1"
  shift

  echo "--- ${name} ---"

  local output
  if ! output="$("$@" 2>&1)"; then
    echo "FAIL (command error)"
    echo "$output" | head -n 8
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  if echo "$output" | python3 -c 'import sys,json; json.load(sys.stdin)' >/dev/null 2>&1; then
    echo "PASS"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL (invalid JSON)"
    echo "$output" | head -n 8
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

run_check "list-projects" \
  bash .github/skills/list-projects/list-projects.sh "$ORG"

run_check "list-repositories" \
  bash .github/skills/list-repositories/list-repositories.sh "$ORG" "$PROJECT"

run_check "get-pr-details" \
  bash .github/skills/get-pr-details/get-pr-details.sh "$ORG" "$PROJECT" "$REPO" "$PR"

run_check "get-pr-iterations" \
  bash .github/skills/get-pr-iterations/get-pr-iterations.sh "$ORG" "$PROJECT" "$REPO" "$PR"

run_check "get-pr-changes" \
  bash .github/skills/get-pr-changes/get-pr-changes.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION"

run_check "get-pr-threads" \
  bash .github/skills/get-pr-threads/get-pr-threads.sh "$ORG" "$PROJECT" "$REPO" "$PR"

if [[ -n "${GH_SEC_PAT:-}" ]]; then
  run_check "get-github-advisories" \
    bash .github/skills/get-github-advisories/get-github-advisories.sh npm lodash 4.17.20 high 10

  run_check "get-pr-dependency-advisories" \
    bash .github/skills/get-pr-dependency-advisories/get-pr-dependency-advisories.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION"
else
  echo "--- get-github-advisories ---"
  echo "SKIP (GH_SEC_PAT is not set)"
  echo "--- get-pr-dependency-advisories ---"
  echo "SKIP (GH_SEC_PAT is not set)"
fi

if command -v npm >/dev/null 2>&1; then
  run_check "check-deprecated-dependencies (npm)" \
    bash .github/skills/check-deprecated-dependencies/check-deprecated-dependencies.sh npm lodash 4.17.21
else
  echo "--- check-deprecated-dependencies (npm) ---"
  echo "SKIP (npm is not available)"
fi

if command -v python3 >/dev/null 2>&1; then
  run_check "check-deprecated-dependencies (pip)" \
    bash .github/skills/check-deprecated-dependencies/check-deprecated-dependencies.sh pip requests 2.31.0

  run_check "check-deprecated-dependencies (nuget)" \
    bash .github/skills/check-deprecated-dependencies/check-deprecated-dependencies.sh nuget Newtonsoft.Json 13.0.3
else
  echo "--- check-deprecated-dependencies (pip) ---"
  echo "SKIP (python3 is not available)"
  echo "--- check-deprecated-dependencies (nuget) ---"
  echo "SKIP (python3 is not available)"
fi

if [[ -n "$TESTED_FILE_PATH" && -n "$BRANCH_BASE" && -n "$BRANCH_TARGET" ]]; then
  run_check "get-file-content" \
    bash .github/skills/get-file-content/get-file-content.sh "$ORG" "$PROJECT" "$REPO" "$TESTED_FILE_PATH" "$BRANCH_TARGET" branch

  run_check "get-commit-diffs" \
    bash .github/skills/get-commit-diffs/get-commit-diffs.sh "$ORG" "$PROJECT" "$REPO" "$BRANCH_BASE" "$BRANCH_TARGET" branch branch
else
  echo "--- get-file-content ---"
  echo "SKIP (repository-specific inputs missing; provide tested_file_path + branch_base + branch_target)"
  echo "--- get-commit-diffs ---"
  echo "SKIP (repository-specific inputs missing; provide branch_base + branch_target)"
fi

if [[ "${ENABLE_MUTATING_CHECKS:-false}" == "true" ]]; then
  run_check "approve-with-suggestions" \
    bash .github/skills/approve-with-suggestions/approve-with-suggestions.sh "$ORG" "$PROJECT" "$REPO" "$PR"

  run_check "wait-for-author" \
    bash .github/skills/wait-for-author/wait-for-author.sh "$ORG" "$PROJECT" "$REPO" "$PR"

  run_check "reject-pr" \
    bash .github/skills/reject-pr/reject-pr.sh "$ORG" "$PROJECT" "$REPO" "$PR"

  run_check "reset-feedback" \
    bash .github/skills/reset-feedback/reset-feedback.sh "$ORG" "$PROJECT" "$REPO" "$PR"

  run_check "accept-pr" \
    bash .github/skills/accept-pr/accept-pr.sh "$ORG" "$PROJECT" "$REPO" "$PR"
else
  echo "--- approve-with-suggestions ---"
  echo "SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)"
  echo "--- wait-for-author ---"
  echo "SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)"
  echo "--- reject-pr ---"
  echo "SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)"
  echo "--- reset-feedback ---"
  echo "SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)"
  echo "--- accept-pr ---"
  echo "SKIP (mutating check disabled; set ENABLE_MUTATING_CHECKS=true to enable)"
fi

# get the first non-system thread ID for update-pr-thread test
THREAD_ID=$(bash .github/skills/get-pr-threads/get-pr-threads.sh "$ORG" "$PROJECT" "$REPO" "$PR" 2>/dev/null \
  | python3 -c "import sys,json; threads=[t for t in json.load(sys.stdin).get('value',[]) if not any(c.get('author',{}).get('displayName','').startswith('Microsoft.') for c in t.get('comments',[]))]; print(threads[0]['id'] if threads else '')" 2>/dev/null || echo "")

if [[ -n "$THREAD_ID" ]]; then
  run_check "update-pr-thread" \
    bash .github/skills/update-pr-thread/update-pr-thread.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$THREAD_ID" - active
else
  echo "--- update-pr-thread ---"
  echo "SKIP (no comment threads found to test against)"
fi

echo
if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo "Result: ${PASS_COUNT} passed, 0 failed"
  exit 0
else
  echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  exit 1
fi
