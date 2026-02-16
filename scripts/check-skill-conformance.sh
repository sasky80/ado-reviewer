#!/usr/bin/env bash
# Check skill scripts for conformance to project conventions.
# Usage: ./check-skill-conformance.sh [skills_root]
#
# Validates every skill folder under skills_root (default: .github/skills)
# against the expected structural patterns:
#   - Each skill folder has <name>.sh, <name>.ps1, and SKILL.md
#   - Bash scripts: shebang, set -euo pipefail, arg-count guard, source ado-utils.sh, ado_init
#   - PowerShell scripts: param block, dot-source AdoSkillUtils.ps1, New-AdoContext or common imports
#   - SKILL.md: skill front matter, Arguments table, Examples section
#
# Output: JSON with results per skill and overall pass/fail counts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="${1:-$(cd "$SCRIPT_DIR/../.github/skills" && pwd)}"

if [[ ! -d "$SKILLS_ROOT" ]]; then
  echo "ERROR: skills root not found: $SKILLS_ROOT" >&2
  exit 1
fi

python3 - "$SKILLS_ROOT" <<'PYEOF'
import sys, os, re, json

skills_root = sys.argv[1]

# Skip the common utilities folder
SKIP_DIRS = {'common'}

results = []
total_pass = 0
total_warn = 0
total_fail = 0

for entry in sorted(os.listdir(skills_root)):
    skill_dir = os.path.join(skills_root, entry)
    if not os.path.isdir(skill_dir) or entry in SKIP_DIRS:
        continue

    skill_name = entry
    findings = []

    sh_file = os.path.join(skill_dir, f"{skill_name}.sh")
    ps1_file = os.path.join(skill_dir, f"{skill_name}.ps1")
    skill_md = os.path.join(skill_dir, "SKILL.md")

    # --- File existence ---
    has_sh = os.path.isfile(sh_file)
    has_ps1 = os.path.isfile(ps1_file)
    has_md = os.path.isfile(skill_md)

    if not has_sh:
        findings.append({"level": "error", "check": "file-exists", "message": f"Missing {skill_name}.sh"})
    if not has_ps1:
        findings.append({"level": "error", "check": "file-exists", "message": f"Missing {skill_name}.ps1"})
    if not has_md:
        findings.append({"level": "error", "check": "file-exists", "message": f"Missing SKILL.md"})

    # --- Bash script checks ---
    if has_sh:
        with open(sh_file, 'r', encoding='utf-8', errors='replace') as f:
            sh_content = f.read()
            sh_lines = sh_content.splitlines()

        # Shebang
        if not sh_lines or not sh_lines[0].startswith('#!/'):
            findings.append({"level": "error", "check": "sh-shebang", "message": "Missing shebang line"})
        elif '#!/usr/bin/env bash' not in sh_lines[0]:
            findings.append({"level": "warn", "check": "sh-shebang", "message": f"Non-standard shebang: {sh_lines[0]}"})

        # set -euo pipefail
        if 'set -euo pipefail' not in sh_content:
            findings.append({"level": "error", "check": "sh-strict-mode", "message": "Missing 'set -euo pipefail'"})

        # Argument count guard
        if not re.search(r'if\s+\[\[?\s+\$#\s+-lt', sh_content):
            findings.append({"level": "warn", "check": "sh-arg-guard", "message": "Missing argument count guard (if [[ $# -lt ...]])"})

        # Source ado-utils.sh
        if 'ado-utils.sh' not in sh_content:
            findings.append({"level": "warn", "check": "sh-source-utils", "message": "Does not source ado-utils.sh"})

        # ado_init call
        if 'ado_init' not in sh_content:
            findings.append({"level": "warn", "check": "sh-ado-init", "message": "Missing ado_init call"})

        # curl flags
        if 'curl' in sh_content:
            if '--fail-with-body' not in sh_content and '--fail' not in sh_content:
                findings.append({"level": "warn", "check": "sh-curl-fail", "message": "curl without --fail or --fail-with-body flag"})
            if '--max-time' not in sh_content:
                findings.append({"level": "warn", "check": "sh-curl-timeout", "message": "curl without --max-time flag"})

        # Usage output to stderr
        if re.search(r'echo\s+"Usage:', sh_content) and '>&2' not in sh_content:
            findings.append({"level": "warn", "check": "sh-usage-stderr", "message": "Usage message not redirected to stderr (>&2)"})

    # --- PowerShell script checks ---
    if has_ps1:
        with open(ps1_file, 'r', encoding='utf-8', errors='replace') as f:
            ps1_content = f.read()

        # param block
        if not re.search(r'^\s*param\s*\(', ps1_content, re.MULTILINE):
            findings.append({"level": "error", "check": "ps1-param-block", "message": "Missing param() block"})

        # Dot-source AdoSkillUtils.ps1
        if 'AdoSkillUtils.ps1' not in ps1_content:
            findings.append({"level": "warn", "check": "ps1-source-utils", "message": "Does not dot-source AdoSkillUtils.ps1"})

        # New-AdoContext call
        if 'New-AdoContext' not in ps1_content:
            findings.append({"level": "warn", "check": "ps1-ado-context", "message": "Missing New-AdoContext call"})

        # Mandatory parameters
        if '[Parameter(Mandatory' not in ps1_content:
            findings.append({"level": "warn", "check": "ps1-mandatory", "message": "No [Parameter(Mandatory)] attributes found"})

    # --- SKILL.md checks ---
    if has_md:
        with open(skill_md, 'r', encoding='utf-8', errors='replace') as f:
            md_content = f.read()

        # Front matter — YAML front matter delimited by ---
        if not re.search(r'^---\s*\r?\nname:\s*\S', md_content):
            findings.append({"level": "warn", "check": "md-frontmatter", "message": "Missing YAML front matter (--- / name: ...)"})

        # Arguments table
        if '| #' not in md_content and '| Name' not in md_content:
            findings.append({"level": "warn", "check": "md-args-table", "message": "Missing Arguments table"})

        # Examples section
        if '## Examples' not in md_content and '## Example' not in md_content:
            findings.append({"level": "warn", "check": "md-examples", "message": "Missing Examples section"})

        # Platform note
        if 'Windows' not in md_content or ('macOS' not in md_content and 'Linux' not in md_content):
            findings.append({"level": "warn", "check": "md-platform-note", "message": "Missing platform note (Windows/macOS/Linux)"})

    # Tally
    errors = sum(1 for f in findings if f["level"] == "error")
    warns = sum(1 for f in findings if f["level"] == "warn")
    status = "pass" if errors == 0 and warns == 0 else ("warn" if errors == 0 else "fail")

    if status == "pass":
        total_pass += 1
    elif status == "warn":
        total_warn += 1
    else:
        total_fail += 1

    results.append({
        "skill": skill_name,
        "status": status,
        "errors": errors,
        "warnings": warns,
        "findings": findings
    })

output = {
    "results": results,
    "summary": {
        "total": len(results),
        "pass": total_pass,
        "warn": total_warn,
        "fail": total_fail
    }
}

print(json.dumps(output, indent=2))
PYEOF
