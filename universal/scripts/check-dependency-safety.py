#!/usr/bin/env python3
"""Reject dependency shapes that execute unreviewed or mutable code."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from urllib.parse import urlparse


def csv(value: str) -> set[str]:
    return {item.strip().strip("'\"") for item in value.strip("[]").split(",") if item.strip()}


def main() -> int:
    if len(sys.argv) != 5:
        print("usage: check-dependency-safety.py ROOT ALLOWED_NON_REGISTRY ALLOWED_LIFECYCLE ALLOWED_HOSTS", file=sys.stderr)
        return 2
    root = Path(sys.argv[1])
    allowed_non_registry, allowed_scripts, allowed_hosts = map(csv, sys.argv[2:])
    problems: list[str] = []
    manifest = root / "package.json"
    lock = root / "package-lock.json"
    if manifest.is_file():
        try:
            package = json.loads(manifest.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            print(f"package.json cannot be parsed: {error}", file=sys.stderr)
            return 1
        for group in ("dependencies", "devDependencies", "optionalDependencies", "peerDependencies"):
            values = package.get(group, {})
            if not isinstance(values, dict):
                problems.append(f"package.json {group} must be an object")
                continue
            for name, spec in values.items():
                if not isinstance(spec, str):
                    problems.append(f"{group}.{name} has a non-string version")
                    continue
                lowered = spec.lower().strip()
                mutable = lowered in {"*", "latest", "next", "beta", "alpha", "canary"}
                non_registry = lowered.startswith(("git:", "git+", "github:", "http:", "https:", "file:", "link:"))
                if mutable:
                    problems.append(f"{group}.{name} uses mutable version {spec!r}; pin a real range/version")
                if non_registry and name not in allowed_non_registry:
                    problems.append(f"{group}.{name} uses non-registry source {spec!r}; review and allow the package explicitly")
        scripts = package.get("scripts", {})
        if isinstance(scripts, dict):
            for name in ("preinstall", "install", "postinstall"):
                if name in scripts and name not in allowed_scripts:
                    problems.append(f"package.json script {name!r} runs during install; review and allow it explicitly")

    if lock.is_file():
        try:
            data = json.loads(lock.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            print(f"package-lock.json cannot be parsed: {error}", file=sys.stderr)
            return 1
        packages = data.get("packages", {})
        if not isinstance(packages, dict):
            problems.append("package-lock.json packages must be an object")
        else:
            for location, entry in packages.items():
                if not location or not isinstance(entry, dict):
                    continue
                name = entry.get("name") or location.rsplit("node_modules/", 1)[-1]
                resolved = entry.get("resolved")
                if isinstance(resolved, str) and resolved.startswith(("http://", "https://")):
                    host = urlparse(resolved).hostname or ""
                    if host not in allowed_hosts:
                        problems.append(f"lock entry {name} resolves from unapproved host {host!r}")
                if resolved and isinstance(resolved, str) and resolved.startswith("http") and not entry.get("integrity"):
                    problems.append(f"lock entry {name} has no integrity hash")
                if entry.get("hasInstallScript") and name not in allowed_scripts:
                    problems.append(f"dependency {name} declares an install script; inspect it and allow the package explicitly")

    for problem in problems:
        print(f"dependency safety: {problem}", file=sys.stderr)
    if problems:
        return 1
    print("dependency safety (sources, integrity, lifecycle scripts)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
