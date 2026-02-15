#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <organization> <project> <repositoryId> <pullRequestId> [iterationId] [per_page]" >&2
  exit 1
fi

ORG="$1"
PROJECT="$2"
REPO_ID="$3"
PR_ID="$4"
ITERATION_ID="${5:-}"
PER_PAGE="${6:-20}"

if ! [[ "$PER_PAGE" =~ ^[0-9]+$ ]] || (( PER_PAGE < 1 || PER_PAGE > 100 )); then
  echo "per_page must be an integer between 1 and 100" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/ado-utils.sh"

ado_init "$ORG"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"

GH_TOKEN="${GH_SEC_PAT:-}"
if [[ -z "$GH_TOKEN" ]]; then
  echo "Environment variable GH_SEC_PAT is not set" >&2
  exit 1
fi

ORG_ENC="$(urlencode "$ORG")"
PROJECT_ENC="$(urlencode "$PROJECT")"
REPO_ID_ENC="$(urlencode "$REPO_ID")"
ADO_AUTH="$(build_auth "$ADO_PAT")"

pr_url="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}?api-version=7.2-preview"
pr_json="$(curl -s --fail-with-body --max-time 30 -H "Authorization: Basic ${ADO_AUTH}" -H "Accept: application/json" "$pr_url")"
source_branch="$(printf '%s' "$pr_json" | python3 -c 'import sys,json; s=json.load(sys.stdin).get("sourceRefName",""); print(s.replace("refs/heads/","",1))')"

if [[ -z "$ITERATION_ID" ]]; then
  iter_url="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/iterations?api-version=7.2-preview"
  iter_json="$(curl -s --fail-with-body --max-time 30 -H "Authorization: Basic ${ADO_AUTH}" -H "Accept: application/json" "$iter_url")"
  ITERATION_ID="$(printf '%s' "$iter_json" | python3 -c 'import sys,json; vals=json.load(sys.stdin).get("value",[]); print(max((int(v.get("id",0)) for v in vals), default=0))')"
fi

if [[ "$ITERATION_ID" == "0" ]]; then
  echo '{"manifestFiles":[],"dependencies":[],"advisories":[],"dependenciesChecked":0,"advisoriesFound":0,"highOrCritical":0}'
  exit 0
fi

changes_url="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/pullRequests/${PR_ID}/iterations/${ITERATION_ID}/changes?api-version=7.2-preview"
changes_json="$(curl -s --fail-with-body --max-time 30 -H "Authorization: Basic ${ADO_AUTH}" -H "Accept: application/json" "$changes_url")"

manifest_paths=()
while IFS= read -r _path; do
  [[ -n "$_path" ]] && manifest_paths+=("$_path")
done < <(printf '%s' "$changes_json" | python3 -c '
import sys,json
data=json.load(sys.stdin)
paths=[]
for entry in data.get("changeEntries",[]):
    item=entry.get("item") or {}
    p=item.get("path")
    if not p:
        continue
    lp=p.lower()
    if (
      lp.endswith("/package.json")
      or lp.endswith("/package-lock.json")
      or lp.endswith("requirements.txt")
      or lp.endswith("requirements-dev.txt")
      or lp.endswith("poetry.lock")
      or lp.endswith("go.mod")
      or lp.endswith("cargo.lock")
    ):
        paths.append(p)
for p in sorted(set(paths)):
    print(p)
')

if [[ ${#manifest_paths[@]} -eq 0 ]]; then
  echo '{"manifestFiles":[],"dependencies":[],"advisories":[],"dependenciesChecked":0,"advisoriesFound":0,"highOrCritical":0}'
  exit 0
fi

tmp_deps="$(mktemp)"
tmp_adv="$(mktemp)"
trap 'rm -f "$tmp_deps" "$tmp_adv" "$tmp_seen"' EXIT

for file_path in "${manifest_paths[@]}"; do
  file_path_enc="$(urlencode "$file_path")"
  branch_enc="$(urlencode "$source_branch")"
  item_url="https://dev.azure.com/${ORG_ENC}/${PROJECT_ENC}/_apis/git/repositories/${REPO_ID_ENC}/items?path=${file_path_enc}&includeContent=true&versionDescriptor.version=${branch_enc}&versionDescriptor.versionType=branch&api-version=7.2-preview"
  item_json="$(curl -s --fail-with-body --max-time 30 -H "Authorization: Basic ${ADO_AUTH}" -H "Accept: application/json" "$item_url")"

  content="$(printf '%s' "$item_json" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("content", ""), end="")')"
  if [[ -z "$content" ]]; then
    continue
  fi

  if [[ "${file_path,,}" == */package.json ]]; then
    printf '%s' "$content" | python3 - "$file_path" >> "$tmp_deps" <<'PY'
import json,sys
path=sys.argv[1]
text=sys.stdin.read()
try:
    data=json.loads(text)
except Exception:
    raise SystemExit(0)
for section in ("dependencies","devDependencies","optionalDependencies","peerDependencies"):
    deps=data.get(section)
    if not isinstance(deps, dict):
        continue
    for name, version in deps.items():
        if isinstance(name, str):
            v=version if isinstance(version, str) else ""
            print(f"npm\t{name}\t{v}\t{path}")
PY
  elif [[ "${file_path,,}" == */package-lock.json ]]; then
    printf '%s' "$content" | python3 - "$file_path" >> "$tmp_deps" <<'PY'
import json,sys
path=sys.argv[1]
text=sys.stdin.read()
try:
    data=json.loads(text)
except Exception:
    raise SystemExit(0)

def emit(name, version):
    if isinstance(name, str) and name:
        v=version if isinstance(version, str) else ""
        print(f"npm\t{name}\t{v}\t{path}")

packages=data.get("packages")
if isinstance(packages, dict):
    for pkg_path, node in packages.items():
        if not isinstance(node, dict):
            continue
        name=node.get("name")
        version=node.get("version")
        if (not isinstance(name, str) or not name) and isinstance(pkg_path, str) and "node_modules/" in pkg_path:
            name=pkg_path.split("node_modules/")[-1]
        emit(name, version)

deps=data.get("dependencies")
if isinstance(deps, dict):
    for name, node in deps.items():
        version=(node or {}).get("version") if isinstance(node, dict) else None
        emit(name, version)
PY
  elif [[ "${file_path,,}" == *requirements.txt || "${file_path,,}" == *requirements-dev.txt ]]; then
    while IFS= read -r line; do
      trimmed="$(printf '%s' "$line" | sed 's/#.*$//' | xargs || true)"
      if [[ -z "$trimmed" || "$trimmed" == -* ]]; then
        continue
      fi
      pkg="$(printf '%s' "$trimmed" | sed -E 's/^([A-Za-z0-9_.-]+).*/\1/')"
      ver="$(printf '%s' "$trimmed" | sed -nE 's/^[A-Za-z0-9_.-]+[[:space:]]*(==|~=|>=|<=|!=|>|<)[[:space:]]*([^;[:space:]]+).*/\2/p')"
      if [[ -n "$pkg" ]]; then
        printf 'pip\t%s\t%s\t%s\n' "$pkg" "$ver" "$file_path" >> "$tmp_deps"
      fi
    done <<< "$content"
  elif [[ "${file_path,,}" == *poetry.lock ]]; then
    printf '%s' "$content" | python3 - "$file_path" >> "$tmp_deps" <<'PY'
import re,sys
path=sys.argv[1]
name=None
version=""
for raw in sys.stdin.read().splitlines():
    line=raw.strip()
    if line=="[[package]]":
        if name:
            print(f"pip\t{name}\t{version}\t{path}")
        name=None
        version=""
        continue
    m=re.match(r'^name\s*=\s*"([^"]+)"$', line)
    if m:
        name=m.group(1)
        continue
    m=re.match(r'^version\s*=\s*"([^"]+)"$', line)
    if m:
        version=m.group(1)
if name:
    print(f"pip\t{name}\t{version}\t{path}")
PY
  elif [[ "${file_path,,}" == *go.mod ]]; then
    printf '%s' "$content" | python3 - "$file_path" >> "$tmp_deps" <<'PY'
import re,sys
path=sys.argv[1]
in_require=False
for raw in sys.stdin.read().splitlines():
    line=raw.split('//',1)[0].strip()
    if not line:
        continue
    if line.startswith('require ('):
        in_require=True
        continue
    if in_require and line==')':
        in_require=False
        continue
    if line.startswith('replace ') or line.startswith('exclude '):
        continue
    m=re.match(r'^require\s+([^\s]+)\s+([^\s]+)$', line)
    if m:
        print(f"go\t{m.group(1)}\t{m.group(2)}\t{path}")
        continue
    if in_require:
        m=re.match(r'^([^\s]+)\s+([^\s]+)$', line)
        if m:
            print(f"go\t{m.group(1)}\t{m.group(2)}\t{path}")
PY
  elif [[ "${file_path,,}" == *cargo.lock ]]; then
    printf '%s' "$content" | python3 - "$file_path" >> "$tmp_deps" <<'PY'
import re,sys
path=sys.argv[1]
name=None
version=""
for raw in sys.stdin.read().splitlines():
    line=raw.strip()
    if line=="[[package]]":
        if name:
            print(f"rust\t{name}\t{version}\t{path}")
        name=None
        version=""
        continue
    m=re.match(r'^name\s*=\s*"([^"]+)"$', line)
    if m:
        name=m.group(1)
        continue
    m=re.match(r'^version\s*=\s*"([^"]+)"$', line)
    if m:
        version=m.group(1)
if name:
    print(f"rust\t{name}\t{version}\t{path}")
PY
  fi
done

if [[ ! -s "$tmp_deps" ]]; then
  printf '{"manifestFiles":%s,"dependencies":[],"advisories":[],"dependenciesChecked":0,"advisoriesFound":0,"highOrCritical":0}' "$(printf '%s\n' "${manifest_paths[@]}" | python3 -c 'import json,sys; print(json.dumps([l.rstrip("\n") for l in sys.stdin if l.rstrip("\n")]))')"
  exit 0
fi

tmp_seen="$(mktemp)"
while IFS=$'\t' read -r ecosystem package version file_path; do
  key="${ecosystem}|${package}|${version}"
  if grep -qxF "$key" "$tmp_seen" 2>/dev/null; then
    continue
  fi
  printf '%s\n' "$key" >> "$tmp_seen"

  affects="$package"
  if [[ -n "$version" ]]; then
    affects="${package}@${version}"
  fi

  eco_enc="$(urlencode "$ecosystem")"
  aff_enc="$(urlencode "$affects")"
  gh_url="https://api.github.com/advisories?ecosystem=${eco_enc}&affects=${aff_enc}&per_page=${PER_PAGE}"
  gh_json="$(curl -s --fail-with-body --max-time 30 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "Authorization: Bearer ${GH_TOKEN}" "$gh_url")"

  printf '%s' "$gh_json" | python3 - "$ecosystem" "$package" "$version" "$file_path" >> "$tmp_adv" <<'PY'
import json,sys
ecosystem,package,version,file_path=sys.argv[1:5]
try:
    advisories=json.load(sys.stdin)
except Exception:
    advisories=[]
if not isinstance(advisories, list):
    advisories=[]
for adv in advisories:
    if not isinstance(adv, dict):
        continue
    out={
      "filePath": file_path,
      "ecosystem": ecosystem,
      "package": package,
      "version": version,
      "ghsa_id": adv.get("ghsa_id"),
      "cve_id": adv.get("cve_id"),
      "severity": adv.get("severity"),
      "summary": adv.get("summary"),
      "html_url": adv.get("html_url"),
    }
    vulns=adv.get("vulnerabilities")
    if isinstance(vulns, list):
        for v in vulns:
            pkg=(v or {}).get("package") or {}
            if pkg.get("name")==package and pkg.get("ecosystem","" ).lower()==ecosystem.lower():
                out["vulnerable_version_range"]=v.get("vulnerable_version_range")
                out["first_patched_version"]=v.get("first_patched_version")
                break
    print(json.dumps(out, separators=(",",":")))
PY
done < "$tmp_deps"

python3 - "$tmp_deps" "$tmp_adv" <<'PY'
import json,sys
deps_path,adv_path=sys.argv[1:3]
deps=[]
seen=set()
with open(deps_path, encoding='utf-8') as f:
    for line in f:
        line=line.rstrip('\n')
        if not line:
            continue
        eco,pkg,ver,file_path=(line.split('\t')+['','','',''])[:4]
        key=(eco,pkg,ver)
        if key in seen:
            continue
        seen.add(key)
        deps.append({"ecosystem":eco,"package":pkg,"version":ver,"filePath":file_path})

advisories=[]
with open(adv_path, encoding='utf-8') as f:
    for line in f:
        line=line.strip()
        if not line:
            continue
        try:
            advisories.append(json.loads(line))
        except Exception:
            pass

manifest_files=sorted({d["filePath"] for d in deps})
high_critical=sum(1 for a in advisories if (a.get("severity") or "").lower() in {"high","critical"})

print(json.dumps({
  "manifestFiles": manifest_files,
  "dependencies": deps,
  "advisories": advisories,
  "dependenciesChecked": len(deps),
  "advisoriesFound": len(advisories),
  "highOrCritical": high_critical,
}, separators=(",",":")))
PY
