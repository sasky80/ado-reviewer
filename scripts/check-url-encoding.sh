#!/usr/bin/env bash
# Check skill scripts for likely unencoded URL path interpolation.
# Usage: ./check-url-encoding.sh [--strict] [skills_root]

set -euo pipefail

STRICT=false
SKILLS_ROOT=""

for arg in "$@"; do
  case "$arg" in
    --strict)
      STRICT=true
      ;;
    *)
      SKILLS_ROOT="$arg"
      ;;
  esac
done

if [[ -z "$SKILLS_ROOT" ]]; then
  SKILLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.github/skills" && pwd)"
fi

if [[ ! -d "$SKILLS_ROOT" ]]; then
  echo "ERROR: skills root not found: $SKILLS_ROOT" >&2
  exit 1
fi

if [[ "${URL_ENCODING_LINT_STRICT:-}" == "true" ]]; then
  STRICT=true
fi

python3 - "$SKILLS_ROOT" "$STRICT" <<'PYEOF'
import json
import os
import re
import sys

skills_root = sys.argv[1]
strict = sys.argv[2].lower() == "true"

skip_dirs = {"common"}
target_ext = {".sh", ".ps1"}

raw_var_names = {
    "ORG",
    "ORGANIZATION",
    "PROJECT",
    "REPO",
    "REPO_ID",
    "REPOSITORY",
    "REPOSITORYID",
}

findings = []
scanned_files = 0

def relpath(path: str) -> str:
    return os.path.relpath(path, os.getcwd()).replace("\\", "/")

for root, dirs, files in os.walk(skills_root):
    dirs[:] = [d for d in dirs if d not in skip_dirs]

    for name in files:
        ext = os.path.splitext(name)[1].lower()
        if ext not in target_ext:
            continue

        file_path = os.path.join(root, name)
        scanned_files += 1

        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
        except Exception:
            continue

        for idx, line in enumerate(lines, start=1):
            if "lint:allow-unencoded-url" in line:
                continue
            if "https://dev.azure.com/" not in line:
                continue

            # Bash-style ${VAR}
            for var in re.findall(r"\$\{([A-Za-z0-9_]+)\}", line):
                normalized = var.upper()
                if normalized in raw_var_names and not normalized.endswith("_ENC") and "ENCODED" not in normalized:
                    findings.append(
                        {
                            "file": relpath(file_path),
                            "line": idx,
                            "rule": "unencoded-url-component",
                            "severity": "warning",
                            "message": f"URL interpolates raw variable '{{{var}}}' without encoded variant.",
                        }
                    )

            # PowerShell-style $Var or $ctx.Property
            for match in re.finditer(r"\$([A-Za-z_][A-Za-z0-9_]*)(?:\.([A-Za-z_][A-Za-z0-9_]*))?", line):
                var = match.group(1)
                prop = match.group(2)

                if prop and "Encoded" in prop:
                    continue

                normalized = var.upper()
                if normalized in raw_var_names:
                    findings.append(
                        {
                            "file": relpath(file_path),
                            "line": idx,
                            "rule": "unencoded-url-component",
                            "severity": "warning",
                            "message": f"URL interpolates raw variable '${var}' without encoded variant.",
                        }
                    )

if findings:
    seen = set()
    deduped = []
    for finding in findings:
        key = (finding["file"], finding["line"], finding["message"])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(finding)
    findings = deduped

status = "pass" if not findings else ("fail" if strict else "warn")

result = {
    "status": status,
    "strict": strict,
    "summary": {
        "scannedFiles": scanned_files,
        "findings": len(findings),
    },
    "findings": findings,
}

print(json.dumps(result))
sys.exit(1 if strict and findings else 0)
PYEOF
