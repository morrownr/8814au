#!/usr/bin/env python3
"""Bulk-close GitHub issues for a repository.

Designed for maintainers performing a one-time cleanup or transition.
"""

from __future__ import annotations

import argparse
import json
import time
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Iterable, List

API_ROOT = "https://api.github.com"
USER_AGENT = "8814au-maintenance-script"


def encode_component(value: str) -> str:
    return urllib.parse.quote(value, safe="")


def github_request(method: str, url: str, token: str, payload: Dict | None = None, retries: int = 3) -> Dict | List:
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
            details = exc.read().decode("utf-8", errors="replace")
            if exc.code in (403, 429) and attempt <= retries:
                time.sleep(min(2**attempt, 10))
                continue
            raise RuntimeError(f"GitHub API {method} {url} failed ({exc.code}): {details}") from exc


def list_open_issues(owner: str, repo: str, token: str) -> Iterable[Dict]:
    owner_q = encode_component(owner)
    repo_q = encode_component(repo)
    page = 1
    while True:
        query = urllib.parse.urlencode({"state": "open", "per_page": 100, "page": page})
        url = f"{API_ROOT}/repos/{owner_q}/{repo_q}/issues?{query}"
        items = github_request("GET", url, token)
        if not items:
            break
        for issue in items:
            if "pull_request" not in issue:
                yield issue
        page += 1


def close_issue(owner: str, repo: str, issue_number: int, token: str, comment: str) -> None:
    owner_q = encode_component(owner)
    repo_q = encode_component(repo)
    comment_url = f"{API_ROOT}/repos/{owner_q}/{repo_q}/issues/{issue_number}/comments"
    github_request("POST", comment_url, token, {"body": comment})

    issue_url = f"{API_ROOT}/repos/{owner_q}/{repo_q}/issues/{issue_number}"
    github_request("PATCH", issue_url, token, {"state": "closed"})


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Close all currently-open issues in a repository.")
    parser.add_argument("--owner", required=True, help="Repository owner (e.g. morrownr)")
    parser.add_argument("--repo", required=True, help="Repository name (e.g. 8814au)")
    parser.add_argument("--token", required=True, help="GitHub token with repo scope")
    parser.add_argument(
        "--comment",
        default=(
            "Closing as part of the maintainer backlog reset. "
            "If this is still reproducible with current main, please open a new issue "
            "using the latest issue template and include fresh logs."
        ),
        help="Comment to post before closing each issue.",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.2,
        help="Delay between close operations to avoid secondary rate limits.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List matching issues without closing them.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    print(f"Processing open issues in {args.owner}/{args.repo}...")
    issues_processed = 0
    for issue in list_open_issues(args.owner, args.repo, args.token):
        issues_processed += 1
        number = issue["number"]
        title = issue["title"]
        print(f"- #{number}: {title}")
        if args.dry_run:
            continue
        close_issue(args.owner, args.repo, number, args.token, args.comment)
        time.sleep(args.sleep_seconds)

    if issues_processed == 0:
        print("No open issues found.")
        return 0

    if args.dry_run:
        print(f"Dry run complete. Found {issues_processed} issues. No issues were modified.")
    else:
        print(f"Completed closing all {issues_processed} open issues.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
