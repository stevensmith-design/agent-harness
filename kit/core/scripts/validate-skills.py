#!/usr/bin/env python3
"""Validate skill frontmatter against the portable Skills packaging subset."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ALLOWED = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
SKIP = {".git", "__pycache__", "node_modules", "evals"}


def parse(text: str) -> tuple[dict[str, object] | None, str | None]:
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, re.S)
    if not match:
        return None, "missing or unclosed YAML frontmatter"
    lines = match.group(1).splitlines()
    result: dict[str, object] = {}
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line.strip() or line.lstrip().startswith("#"):
            index += 1
            continue
        key_match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):[ \t]*(.*)$", line)
        if not key_match:
            return None, f"cannot parse frontmatter line {index + 1}: {line!r}"
        key, value = key_match.group(1), key_match.group(2).strip()
        if value in {">", ">-", "|", "|-"}:
            folded = value.startswith(">")
            block: list[str] = []
            index += 1
            while index < len(lines) and (not lines[index].strip() or lines[index].startswith((" ", "\t"))):
                block.append(lines[index].strip())
                index += 1
            result[key] = " ".join(x for x in block if x) if folded else "\n".join(block)
            continue
        if value == "":
            nested: dict[str, str] = {}
            index += 1
            while index < len(lines) and (not lines[index].strip() or lines[index].startswith((" ", "\t"))):
                nested_match = re.match(r"^\s+([A-Za-z_][A-Za-z0-9_.-]*):[ \t]*(.*)$", lines[index])
                if nested_match:
                    nested[nested_match.group(1)] = nested_match.group(2).strip()
                index += 1
            result[key] = nested
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        result[key] = value
        index += 1
    return result, None


def nested_skill_files(root: Path) -> list[Path]:
    found: list[Path] = []
    for directory, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP]
        if "SKILL.md" in files:
            found.append(Path(directory) / "SKILL.md")
    return sorted(found)


def validate(directory: Path) -> list[str]:
    errors: list[str] = []
    skill_file = directory / "SKILL.md"
    if not skill_file.is_file():
        return ["no SKILL.md at the skill root"]
    nested = [p.relative_to(directory) for p in nested_skill_files(directory) if p != skill_file]
    if nested:
        errors.append("more than one packaged SKILL.md: " + ", ".join(map(str, nested)))
    frontmatter, error = parse(skill_file.read_text(encoding="utf-8"))
    if error or frontmatter is None:
        return errors + [error or "frontmatter parse failed"]
    unexpected = sorted(set(frontmatter) - ALLOWED)
    if unexpected:
        errors.append("unsupported top-level key(s): " + ", ".join(unexpected))
    name = frontmatter.get("name")
    if not isinstance(name, str) or not name.strip():
        errors.append("missing non-empty name")
    else:
        name = name.strip()
        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) or len(name) > 64:
            errors.append("name must be kebab-case, without doubled hyphens, and at most 64 characters")
        if name != directory.name:
            errors.append(f"name {name!r} does not match directory {directory.name!r}")
    description = frontmatter.get("description")
    if not isinstance(description, str) or not description.strip():
        errors.append("missing non-empty description")
    else:
        description = description.strip()
        if "<" in description or ">" in description:
            errors.append("description contains an angle bracket, which portable upload rejects")
        if len(description) > 1024:
            errors.append(f"description is {len(description)} serialized characters; maximum is 1024")
    compatibility = frontmatter.get("compatibility")
    if isinstance(compatibility, str) and len(compatibility.strip()) > 500:
        errors.append("compatibility exceeds 500 characters")
    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate-skills.py <skills-root>", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"skills root not found: {root}", file=sys.stderr)
        return 2
    directories = sorted(p for p in root.iterdir() if p.is_dir())
    bad = 0
    checked = 0
    for directory in directories:
        if not (directory / "SKILL.md").exists():
            continue
        checked += 1
        errors = validate(directory)
        if errors:
            bad += 1
            print(f"FAIL {directory.name}", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
    if bad:
        print(f"skill frontmatter: {bad} invalid of {checked}", file=sys.stderr)
        return 1
    print(f"skill frontmatter ({checked} portable skill(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
