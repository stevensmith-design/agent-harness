#!/usr/bin/env python3
"""Verify capability-skill provenance and content hashes."""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from pathlib import Path


def hash_tree(root: Path) -> str:
    digest = hashlib.sha256()
    for directory, dirs, files in os.walk(root):
        dirs.sort()
        for filename in sorted(files):
            path = Path(directory) / filename
            relative = path.relative_to(root).as_posix()
            digest.update(relative.encode())
            digest.update(b"\0")
            digest.update(path.read_bytes())
            digest.update(b"\0")
    return digest.hexdigest()


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--hash":
        print(hash_tree(Path(sys.argv[2])))
        return 0
    if len(sys.argv) != 3:
        print("usage: verify-capabilities.py CAPABILITIES_ROOT LOCKFILE", file=sys.stderr)
        print("       verify-capabilities.py --hash CAPABILITY_DIR", file=sys.stderr)
        return 2
    root, lock_path = Path(sys.argv[1]), Path(sys.argv[2])
    try:
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"capabilities lock cannot be parsed: {error}", file=sys.stderr)
        return 1
    entries = lock.get("skills", {})
    if lock.get("version") != 1 or not isinstance(entries, dict):
        print("capabilities lock needs version 1 and a skills object", file=sys.stderr)
        return 1
    on_disk = {p.name: p for p in root.iterdir() if p.is_dir() and (p / "SKILL.md").is_file()}
    problems: list[str] = []
    for name in sorted(set(on_disk) - set(entries)):
        problems.append(f"{name} is on disk but absent from capabilities-lock.json")
    for name in sorted(set(entries) - set(on_disk)):
        problems.append(f"{name} is locked but absent from capabilities/")
    for name in sorted(set(entries) & set(on_disk)):
        entry = entries[name]
        if not isinstance(entry, dict):
            problems.append(f"{name} lock entry is not an object")
            continue
        for field in ("source", "license", "contentHash", "reviewedBy", "reviewedAt"):
            if not isinstance(entry.get(field), str) or not entry[field].strip():
                problems.append(f"{name} lock entry is missing {field}")
        commit = entry.get("commit")
        pin = entry.get("pin")
        if not (isinstance(commit, str) and re.fullmatch(r"[0-9a-f]{40}", commit)) and pin != "content-hash":
            problems.append(f"{name} needs an immutable 40-character commit or pin: content-hash")
        expected = entry.get("contentHash")
        actual = hash_tree(on_disk[name])
        if isinstance(expected, str) and expected != actual:
            problems.append(f"{name} content differs from its reviewed hash")
    for problem in problems:
        print(f"capability safety: {problem}", file=sys.stderr)
    if problems:
        return 1
    print(f"capability provenance ({len(on_disk)} pinned skill(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
