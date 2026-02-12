#!/usr/bin/env python3
"""Import issues from an upstream repo into this fork and generate auto-close text."""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Iterable, List, Tuple

API_ROOT = "https://api.github.com"
USER_AGENT = "8814au-issue-importer"
MARKER_RE = re.compile(r"Upstream-Issue:\s*([\w.-]+)/([\w.-]+)#(\d+)", re.IGNORECASE)


def gh_request(method: str, url: str, token: str, payload: Dict | None = None) -> Dict | List:
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "User-Agent": USER_AGENT,
        "X-GitHub-Api-Version": "2022-11-28",
    }
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub API {method} {url} failed ({exc.code}): {detail}") from exc


def list_repo_issues(owner: str, repo: str, token: str, state: str) -> Iterable[Dict]:
    page = 1
    while True:
        q = urllib.parse.urlencode({"state": state, "per_page": 100, "page": page})
        url = f"{API_ROOT}/repos/{owner}/{repo}/issues?{q}"
        issues = gh_request("GET", url, token)
        if not issues:
            break
        for issue in issues:
            if "pull_request" not in issue:
                yield issue
        page += 1


def build_existing_map(target_owner: str, target_repo: str, token: str) -> Dict[Tuple[str, str, int], int]:
    result: Dict[Tuple[str, str, int], int] = {}
    for issue in list_repo_issues(target_owner, target_repo, token, state="all"):
        body = issue.get("body") or ""
        m = MARKER_RE.search(body)
        if m:
            key = (m.group(1), m.group(2), int(m.group(3)))
            result[key] = issue["number"]
    return result


def render_import_body(src_owner: str, src_repo: str, src_issue: Dict) -> str:
    body = src_issue.get("body") or ""
    body = body.strip()
    return textwrap.dedent(
        f"""
        Imported from upstream for tracking and auto-close in this fork.

        Upstream-Issue: {src_owner}/{src_repo}#{src_issue['number']}
        Upstream-URL: {src_issue['html_url']}
        Opened-By: @{src_issue['user']['login']}

        ---

        {body if body else '_No body provided in upstream issue._'}
        """
    ).strip()


def create_target_issue(target_owner: str, target_repo: str, token: str, payload: Dict) -> Dict:
    url = f"{API_ROOT}/repos/{target_owner}/{target_repo}/issues"
    return gh_request("POST", url, token, payload)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Import issues from upstream repo into target repo")
    p.add_argument("--source-owner", required=True)
    p.add_argument("--source-repo", required=True)
    p.add_argument("--target-owner", required=True)
    p.add_argument("--target-repo", required=True)
    p.add_argument("--token", required=True)
    p.add_argument("--state", default="open", choices=["open", "all"])
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--label", action="append", default=["imported-from-upstream"])
    p.add_argument("--close-keywords-file", default="auto-close-keywords.md")
    p.add_argument("--mapping-file", default="imported-issue-map.json")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    existing = build_existing_map(args.target_owner, args.target_repo, args.token)

    imported: List[Dict[str, int | str]] = []
    for src_issue in list_repo_issues(args.source_owner, args.source_repo, args.token, args.state):
        key = (args.source_owner, args.source_repo, src_issue["number"])
        if key in existing:
            imported.append({
                "source": src_issue["number"],
                "target": existing[key],
                "action": "already_exists",
            })
            continue

        title = f"[upstream #{src_issue['number']}] {src_issue['title']}"
        payload = {
            "title": title,
            "body": render_import_body(args.source_owner, args.source_repo, src_issue),
            "labels": args.label,
        }

        if args.dry_run:
            imported.append({"source": src_issue["number"], "target": -1, "action": "would_create"})
            continue

        created = create_target_issue(args.target_owner, args.target_repo, args.token, payload)
        imported.append({"source": src_issue["number"], "target": created["number"], "action": "created"})

    with open(args.mapping_file, "w", encoding="utf-8") as fp:
        json.dump(imported, fp, indent=2)

    target_numbers = [i["target"] for i in imported if isinstance(i["target"], int) and i["target"] > 0]
    with open(args.close_keywords_file, "w", encoding="utf-8") as fp:
        if target_numbers:
            fp.write("\n".join(f"Closes #{n}" for n in target_numbers) + "\n")
        else:
            fp.write("<!-- No target issues imported or found. -->\n")

    print(f"Processed {len(imported)} upstream issues.")
    created = sum(1 for i in imported if i["action"] == "created")
    exists = sum(1 for i in imported if i["action"] == "already_exists")
    print(f"Created: {created}, already existed: {exists}, dry-run: {args.dry_run}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
