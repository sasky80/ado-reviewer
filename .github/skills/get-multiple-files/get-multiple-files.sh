#!/usr/bin/env bash
# Fetch multiple files from an Azure DevOps Git repository in a single invocation.
# Usage: ./get-multiple-files.sh <organization> <project> <repositoryId> <version> <versionType> '<json_paths_array>'
#
# <json_paths_array> is a JSON array of repository-relative file paths, e.g.:
#   '["/src/app.js", "/README.md"]'
#
# Output: JSON object with results array, succeeded/failed/total counts.

set -euo pipefail

if [[ $# -lt 6 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <version> <versionType> '<json_paths_array>'" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
VERSION="$4"
VERSION_TYPE="${5:-branch}"
PATHS_JSON="$6"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"
VERSION_ENC="$(urlencode "$VERSION")"

# Parse the JSON array of paths into a bash array
mapfile -t FILE_PATHS < <(echo "$PATHS_JSON" | python3 -c "import sys,json; [print(p) for p in json.load(sys.stdin)]")

if [[ ${#FILE_PATHS[@]} -eq 0 ]]; then
  echo '{"results":[],"succeeded":0,"failed":0,"total":0}'
  exit 0
fi

TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# Fetch each file in parallel using background curl jobs
for i in "${!FILE_PATHS[@]}"; do
  FILE_PATH="$(normalize_ado_file_path "${FILE_PATHS[$i]}")"
  FILE_PATH_ENC="$(urlencode "$FILE_PATH")"

  URL="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/items?path=${FILE_PATH_ENC}&includeContent=true&api-version=7.2-preview"
  URL="${URL}&versionDescriptor.version=${VERSION_ENC}&versionDescriptor.versionType=${VERSION_TYPE}"

  RESULT_FILE="${TMPDIR_WORK}/${i}.json"
  STATUS_FILE="${TMPDIR_WORK}/${i}.status"

  (
    HTTP_CODE=$(curl -s -o "$RESULT_FILE" -w "%{http_code}" --max-time 30 \
      -H "Authorization: Basic ${ADO_AUTH}" \
      -H "Accept: application/json" \
      "$URL")
    echo "$HTTP_CODE" > "$STATUS_FILE"
  ) &
done

wait

# Assemble results
python3 - "$TMPDIR_WORK" "$PATHS_JSON" <<'PYEOF'
import sys, json, os

tmpdir = sys.argv[1]
paths = json.loads(sys.argv[2])

results = []
succeeded = 0
failed = 0

for i, path in enumerate(paths):
    status_file = os.path.join(tmpdir, f"{i}.status")
    result_file = os.path.join(tmpdir, f"{i}.json")

    entry = {"path": path}

    http_code = "000"
    if os.path.exists(status_file):
        http_code = open(status_file).read().strip()

    if http_code == "200":
        try:
            with open(result_file) as f:
                data = json.load(f)
            entry["status"] = "ok"
            entry["content"] = data.get("content", "")
            entry["commitId"] = data.get("commitId", "")
            entry["objectId"] = data.get("objectId", "")
            succeeded += 1
        except Exception as e:
            entry["status"] = "error"
            entry["error"] = f"JSON parse error: {e}"
            failed += 1
    else:
        entry["status"] = "error"
        error_msg = f"HTTP {http_code}"
        if os.path.exists(result_file):
            try:
                body = open(result_file).read().strip()
                if body:
                    try:
                        err_data = json.loads(body)
                        error_msg = err_data.get("message", error_msg)
                    except Exception:
                        error_msg = body[:200]
            except Exception:
                pass
        entry["error"] = error_msg
        failed += 1

    results.append(entry)

output = {
    "results": results,
    "succeeded": succeeded,
    "failed": failed,
    "total": len(results)
}
print(json.dumps(output))
PYEOF
