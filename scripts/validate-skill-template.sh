#!/usr/bin/env bash
set -euo pipefail

# Template validation wrapper.
# Copy this file (for example to scripts/validate-skill-local.sh)
# and replace values below with your own Azure DevOps context.
ORG="<your_org>"
PROJECT="<your_project_name_or_id>"
REPO="<your_repository_name_or_id>"
PR="<your_pr_id>"
ITERATION="<your_iteration_id>"
TESTED_FILE_PATH="</path/to/file/in/repository>"
BRANCH_BASE="<base_branch>"
BRANCH_TARGET="<target_branch>"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Validation is non-mutating by default.
# To include mutating checks (e.g. accept-pr, approve-with-suggestions,
# wait-for-author, reject-pr, reset-feedback), run with:
# ENABLE_MUTATING_CHECKS=true ./scripts/validate-skill-local.sh

bash scripts/validate-skills.sh "$ORG" "$PROJECT" "$REPO" "$PR" "$ITERATION" "$TESTED_FILE_PATH" "$BRANCH_BASE" "$BRANCH_TARGET"
