#!/usr/bin/env python3
"""Import issues from an upstream repo into this fork and generate auto-close text."""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Iterable, List, Tuple

API_ROOT = "https://api.github.com"
USER_AGENT = "8814au-issue-importer"
MARKER_RE = re.compile(r"Upstream-Issue:\s*([\w.-]+)/([\w.-]+)#(\d+)", re.IGNORECASE)


def encode_component(value: str) -> str:
    return urllib.parse.quote(value, safe="")


def safe_output_path(filename: str) -> str:
    return filename.rsplit("/", 1)[-1].rsplit("\\", 1)[-1]


def gh_request(method: str, url: str, token: str, payload: Dict | None = None, retries: int = 3) -> Dict | List:
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
    attempt = 0
    while True:
        attempt += 1
        try:
            with urllib.request.urlopen(req) as resp:
                raw = resp.read().decode("utf-8")
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            if exc.code in (403, 429) and attempt <= retries:
                time.sleep(min(2**attempt, 10))
                continue
            raise RuntimeError(f"GitHub API {method} {url} failed ({exc.code}): {detail}") from exc


def list_repo_issues(owner: str, repo: str, token: str, state: str) -> Iterable[Dict]:
    page = 1
    while True:
        q = urllib.parse.urlencode({"state": state, "per_page": 100, "page": page})
        url = f"{API_ROOT}/repos/{encode_component(owner)}/{encode_component(repo)}/issues?{q}"
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
        match = MARKER_RE.search(body)
        if match:
            key = (match.group(1), match.group(2), int(match.group(3)))
            result[key] = issue["number"]
    return result


def ensure_labels(target_owner: str, target_repo: str, token: str, labels: List[str]) -> None:
    for label in labels:
        read_url = f"{API_ROOT}/repos/{encode_component(target_owner)}/{encode_component(target_repo)}/labels/{urllib.parse.quote(label, safe='')}"
        try:
            gh_request("GET", read_url, token)
            continue
        except RuntimeError as exc:
            if "(404)" not in str(exc):
                raise

        create_url = f"{API_ROOT}/repos/{encode_component(target_owner)}/{encode_component(target_repo)}/labels"
        gh_request(
            "POST",
            create_url,
            token,
            {"name": label, "color": "1D76DB", "description": "Imported from upstream repository"},
        )


def render_import_body(src_owner: str, src_repo: str, src_issue: Dict) -> str:
    body = (src_issue.get("body") or "").strip()
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
    url = f"{API_ROOT}/repos/{encode_component(target_owner)}/{encode_component(target_repo)}/issues"
    return gh_request("POST", url, token, payload)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import issues from upstream repo into target repo")
    parser.add_argument("--source-owner", required=True)
    parser.add_argument("--source-repo", required=True)
    parser.add_argument("--target-owner", required=True)
    parser.add_argument("--target-repo", required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--state", default="open", choices=["open", "all"])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--label", action="append", default=["imported-from-upstream"])
    parser.add_argument("--max-issues", type=int, default=0, help="Stop after N issues (0 = no limit)")
    parser.add_argument("--close-keywords-file", default="auto-close-keywords.md")
    parser.add_argument("--mapping-file", default="imported-issue-map.json")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    existing = build_existing_map(args.target_owner, args.target_repo, args.token)

    if not args.dry_run:
        ensure_labels(args.target_owner, args.target_repo, args.token, args.label)

    imported: List[Dict[str, int | str]] = []
    for source_issue in list_repo_issues(args.source_owner, args.source_repo, args.token, args.state):
        key = (args.source_owner, args.source_repo, source_issue["number"])
        item: Dict[str, int | str] = {
            "source": source_issue["number"],
            "source_url": source_issue["html_url"],
            "target": -1,
            "action": "would_create",
        }

        if key in existing:
            item["target"] = existing[key]
            item["action"] = "already_exists"
        else:
            payload = {
                "title": f"[upstream #{source_issue['number']}] {source_issue['title']}",
                "body": render_import_body(args.source_owner, args.source_repo, source_issue),
                "labels": args.label,
            }
            if args.dry_run:
                item["action"] = "would_create"
            else:
                created = create_target_issue(args.target_owner, args.target_repo, args.token, payload)
                item["target"] = created["number"]
                item["action"] = "created"

        imported.append(item)
        if args.max_issues > 0 and len(imported) >= args.max_issues:
            break

    with open(safe_output_path(args.mapping_file), "w", encoding="utf-8") as file_handle:
        json.dump(imported, file_handle, indent=2)

    target_numbers = [item["target"] for item in imported if isinstance(item["target"], int) and item["target"] > 0]
    with open(safe_output_path(args.close_keywords_file), "w", encoding="utf-8") as file_handle:
        if target_numbers:
            file_handle.write("\n".join(f"Closes #{number}" for number in target_numbers) + "\n")
        else:
            file_handle.write("<!-- No target issues imported or found. -->\n")

    created_count = sum(1 for item in imported if item["action"] == "created")
    existing_count = sum(1 for item in imported if item["action"] == "already_exists")
    print(f"Processed {len(imported)} upstream issues.")
    print(f"Created: {created_count}, already existed: {existing_count}, dry-run: {args.dry_run}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
