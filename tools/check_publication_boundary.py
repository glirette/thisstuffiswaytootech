#!/usr/bin/env python3
"""Check common internal-metadata leaks in a proposed public source tree.

This is a local heuristic, not a secrets scanner or source-truth adjudicator.
No network requests or repository mutations are performed.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote


PUBLIC_REPOSITORIES = {
    "notarygeekpublicknowledgeworker",
    "thisstuffiswaytootech",
}
OWNED_REFERENCE = re.compile(r"(?<![\w.-])glirette/([a-z0-9_.-]+)", re.I)
PRIVATE_METADATA = re.compile(
    r"private.*(?:repository|repo|revision|commit|provenance|pullrequest|pr|issue)",
    re.I,
)
PRODUCTION_FIELDS = {
    "markdownsourceprepared",
    "documentgenerationqueued",
    "documentgenerated",
}


def check_text(path: str, content: str) -> list[str]:
    findings = []
    decoded = unquote(unquote(content))
    if any(m.group(1).casefold() not in PUBLIC_REPOSITORIES
           for m in OWNED_REFERENCE.finditer(decoded)):
        findings.append(f"{path}: unexpected publisher-owned repository reference")

    if not path.endswith(".json"):
        return findings
    try:
        document = json.loads(content.lstrip("\ufeff"))
    except json.JSONDecodeError:
        return findings + [f"{path}: invalid JSON"]

    def inspect(value):
        if isinstance(value, dict):
            for key, child in value.items():
                normalized = re.sub(r"[^a-z0-9]", "", key.casefold())
                if PRIVATE_METADATA.search(normalized) or normalized in PRODUCTION_FIELDS:
                    findings.append(f"{path}: internal provenance or production metadata field")
                inspect(child)
        elif isinstance(value, list):
            for child in value:
                inspect(child)

    inspect(document)
    return findings


def check_repository(root: Path) -> tuple[int, list[str]]:
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=root, check=True, stdout=subprocess.PIPE,
    )
    findings = []
    checked = 0
    for name in sorted(set(result.stdout.decode().split("\0")) - {""}):
        path = root / name
        if not path.is_file():
            continue
        try:
            content = path.read_bytes().decode("utf-8")
        except UnicodeDecodeError:
            continue
        checked += 1
        findings.extend(check_text(name, content))
    return checked, findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    checked, findings = check_repository(args.root.resolve())
    for finding in findings:
        print(finding)
    print(f"Checked {checked} UTF-8 files; {len(findings)} boundary findings.")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
