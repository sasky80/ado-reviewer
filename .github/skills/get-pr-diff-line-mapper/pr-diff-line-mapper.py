#!/usr/bin/env python3
import argparse
import difflib
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request


HUNK_RE = re.compile(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Map PR file diffs to line-level hunks for a PR iteration.')
    parser.add_argument('--org-enc', required=True)
    parser.add_argument('--project-enc', required=True)
    parser.add_argument('--repo-enc', required=True)
    parser.add_argument('--pull-request-id', required=True)
    parser.add_argument('--iteration-id', required=True)
    parser.add_argument('--auth-basic', required=True)
    return parser.parse_args()


def request_json(url: str, auth_basic: str) -> dict:
    request = urllib.request.Request(
        url,
        headers={
            'Authorization': f'Basic {auth_basic}',
            'Accept': 'application/json',
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as error:
        body = error.read().decode('utf-8', errors='replace') if error.fp else ''
        message = body.strip() or str(error)
        raise RuntimeError(message) from error


def request_item_content(
    org_enc: str,
    project_enc: str,
    repo_enc: str,
    path: str,
    branch: str,
    auth_basic: str,
) -> tuple[str, bool]:
    path_enc = urllib.parse.quote(path, safe='')
    branch_enc = urllib.parse.quote(branch, safe='')
    url = (
        f'https://dev.azure.com/{org_enc}/{project_enc}/_apis/git/repositories/{repo_enc}/items'
        f'?path={path_enc}&includeContent=true&api-version=7.2-preview'
        f'&versionDescriptor.version={branch_enc}&versionDescriptor.versionType=branch'
    )

    request = urllib.request.Request(
        url,
        headers={
            'Authorization': f'Basic {auth_basic}',
            'Accept': 'application/json',
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode('utf-8'))
            return payload.get('content', '') or '', True
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return '', False

        body = error.read().decode('utf-8', errors='replace') if error.fp else ''
        message = body.strip() or str(error)
        raise RuntimeError(message) from error


def parse_branch(ref_name: str) -> str:
    prefix = 'refs/heads/'
    if ref_name.startswith(prefix):
        return ref_name[len(prefix):]
    return ref_name


def build_line_map(old_content: str, new_content: str) -> dict:
    old_lines = old_content.splitlines()
    new_lines = new_content.splitlines()

    diff_lines = list(
        difflib.unified_diff(
            old_lines,
            new_lines,
            fromfile='a',
            tofile='b',
            lineterm='',
        )
    )

    hunks: list[dict] = []
    current_hunk: dict | None = None

    for line in diff_lines:
        hunk_match = HUNK_RE.match(line)
        if hunk_match:
            if current_hunk is not None:
                hunks.append(current_hunk)

            old_start = int(hunk_match.group(1))
            old_count = int(hunk_match.group(2) or '1')
            new_start = int(hunk_match.group(3))
            new_count = int(hunk_match.group(4) or '1')

            current_hunk = {
                'index': len(hunks) + 1,
                'oldStart': old_start,
                'oldLines': old_count,
                'newStart': new_start,
                'newLines': new_count,
                'addedLines': 0,
                'deletedLines': 0,
                'contextLines': 0,
            }
            continue

        if current_hunk is None:
            continue

        if line.startswith('+') and not line.startswith('+++'):
            current_hunk['addedLines'] += 1
        elif line.startswith('-') and not line.startswith('---'):
            current_hunk['deletedLines'] += 1
        elif line.startswith(' '):
            current_hunk['contextLines'] += 1

    if current_hunk is not None:
        hunks.append(current_hunk)

    return {
        'hunkCount': len(hunks),
        'totalAdded': sum(h['addedLines'] for h in hunks),
        'totalDeleted': sum(h['deletedLines'] for h in hunks),
        'totalContext': sum(h['contextLines'] for h in hunks),
        'hunks': hunks,
    }


def main() -> int:
    args = parse_args()

    pr_url = (
        f'https://dev.azure.com/{args.org_enc}/{args.project_enc}/_apis/git/repositories/{args.repo_enc}/pullRequests/'
        f'{args.pull_request_id}?api-version=7.2-preview'
    )
    changes_url = (
        f'https://dev.azure.com/{args.org_enc}/{args.project_enc}/_apis/git/repositories/{args.repo_enc}/pullRequests/'
        f'{args.pull_request_id}/iterations/{args.iteration_id}/changes?api-version=7.2-preview'
    )

    pr_payload = request_json(pr_url, args.auth_basic)
    source_branch = parse_branch(pr_payload.get('sourceRefName', ''))
    target_branch = parse_branch(pr_payload.get('targetRefName', ''))

    changes_payload = request_json(changes_url, args.auth_basic)
    files = []

    for change_entry in changes_payload.get('changeEntries', []):
        item = change_entry.get('item') or {}
        path = item.get('path') or change_entry.get('originalPath')
        if not path:
            continue

        is_folder = bool(item.get('isFolder', False))
        output_entry = {
            'path': path,
            'changeType': change_entry.get('changeType'),
            'changeTrackingId': change_entry.get('changeTrackingId'),
            'isFolder': is_folder,
        }

        if is_folder:
            output_entry['baseExists'] = False
            output_entry['prExists'] = False
            output_entry['lineMap'] = {
                'hunkCount': 0,
                'totalAdded': 0,
                'totalDeleted': 0,
                'totalContext': 0,
                'hunks': [],
            }
            files.append(output_entry)
            continue

        base_content, base_exists = request_item_content(
            args.org_enc,
            args.project_enc,
            args.repo_enc,
            path,
            target_branch,
            args.auth_basic,
        )
        pr_content, pr_exists = request_item_content(
            args.org_enc,
            args.project_enc,
            args.repo_enc,
            path,
            source_branch,
            args.auth_basic,
        )

        output_entry['baseExists'] = base_exists
        output_entry['prExists'] = pr_exists
        output_entry['lineMap'] = build_line_map(base_content, pr_content)
        files.append(output_entry)

    result = {
        'pullRequestId': str(args.pull_request_id),
        'iterationId': str(args.iteration_id),
        'sourceBranch': source_branch,
        'targetBranch': target_branch,
        'count': len(files),
        'files': files,
    }

    print(json.dumps(result))
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
