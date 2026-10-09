#!/usr/bin/env python3
"""Scan skill trees for instruction and supply-chain patterns unsafe for agents."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

TEXT = {".md", ".txt", ".toml", ".json", ".yaml", ".yml", ".csv", ".tsv", ".html", ".sh", ".py", ".mjs", ".js", ".cjs", ".ts"}
CODE = {".sh", ".py", ".mjs", ".js", ".cjs", ".ts"}
SKIP = {".git", "__pycache__", "node_modules"}
PATTERNS = {
    "T1-install": re.compile(r"\bsudo\s+[a-z]|\b(brew|apt|apt-get|yum|dnf|pacman|winget|choco|scoop)\s+install\b|\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z|fi)?sh\b|\bpip3?\s+install\b|\bnpm\s+(i|install)\s+(-g|--global)\b|\bnpx\s+(-y|--yes)\b|\bInvoke-Expression\b|\biex\s*\(", re.I),
    "T2-override": re.compile(r"\b(ignore|disregard|forget)\s+(all\s+|any\s+|the\s+)?(previous|prior|above|earlier|preceding)\s+(instructions|prompts|messages|rules)|^\s*system\s+prompt\s*:|\byou\s+are\s+now\b|</?system>", re.I),
}
COERCION = re.compile(r"\b(must|always|shall)\s+(be\s+)?(use|used|invoke|invoked|load|loaded|consult|consulted)\b[^.]{0,30}\bskill\b|\balways[\s-]+active\b|\bmandatory\b|\bregardless\s+of\s+(any\s+|other\s+|the\s+)*(instructions|skills|tools|requests?)\b|\b(do\s+not|never)\s+skip\s+this\s+skill\b", re.I)
DOWNLOAD = re.compile(r"(\bfetch\s*\(|\bhttps?\.(get|request)\s*\(|\baxios(\.\w+)?\s*\(|\burlopen\s*\(|\burlretrieve\s*\(|\brequests\.(get|post|put|request)\s*\(|\b(curl|wget)\s)[^\n]{0,80}?['\"`]https?://(?!(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]))[^\s'\"`]+", re.I)


def description(text: str) -> str:
    match = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not match:
        return ""
    lines = match.group(1).splitlines()
    output: list[str] = []
    active = False
    for line in lines:
        if line.startswith("description:"):
            active = True
            output.append(re.sub(r"^description:\s*[>|]?-?\s*", "", line))
        elif active and (line.startswith((" ", "\t")) or not line.strip()):
            output.append(line.strip())
        elif active:
            break
    return " ".join(x for x in output if x).strip("'\" ")


def load_allow(path: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    if not path.is_file():
        return rows
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 3 or not parts[2].strip():
            rows.append({"bad": f"{path}:{number}: expected path<TAB>exact substring<TAB>reason"})
        else:
            rows.append({"path": parts[0], "substring": parts[1], "used": False})
    return rows


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: scan-skill-trust.py <skills-root> <allowlist>", file=sys.stderr)
        return 2
    root, allow_path = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    if not root.is_dir():
        print(f"skills root not found: {root}", file=sys.stderr)
        return 2
    allow = load_allow(allow_path)
    findings: list[tuple[str, str, str]] = []
    for row in allow:
        if "bad" in row:
            findings.append(("STALE", str(row["bad"]), ""))

    def allowed(relative: str, line: str) -> bool:
        result = False
        for row in allow:
            if "bad" not in row and row["path"] == relative and str(row["substring"]) in line:
                row["used"] = True
                result = True
        return result

    checked = 0
    for directory, dirs, files in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in SKIP)
        for filename in sorted(files):
            path = Path(directory) / filename
            if path.suffix.lower() not in TEXT:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            checked += 1
            relative = path.relative_to(root).as_posix()
            if filename == "SKILL.md":
                match = COERCION.search(description(text))
                if match and not allowed(relative, match.group(0)):
                    findings.append(("T3-coercion", f"{relative} description", match.group(0)))
            for number, line in enumerate(text.splitlines(), 1):
                if len(line) > 4000:
                    continue
                for rule, regex in PATTERNS.items():
                    match = regex.search(line)
                    if match and not allowed(relative, line):
                        findings.append((rule, f"{relative}:{number}", match.group(0)))
                if path.suffix.lower() in CODE:
                    code = "" if re.match(r"^\s*(#|//|\*)", line) else line
                    match = DOWNLOAD.search(code)
                    if match and not allowed(relative, line):
                        findings.append(("T4-download", f"{relative}:{number}", match.group(0)))
    for row in allow:
        if "bad" not in row and not row["used"]:
            findings.append(("STALE", f"allowlist row for {row['path']}", str(row["substring"])))
    seen: set[tuple[str, str]] = set()
    for rule, where, excerpt in findings:
        if (rule, where) in seen:
            continue
        seen.add((rule, where))
        print(f"{rule} {where} — {excerpt[:100]}", file=sys.stderr)
    if seen:
        print(f"skill trust: {len(seen)} finding(s)", file=sys.stderr)
        return 1
    print(f"skill trust ({checked} text file(s), no unsafe instruction shapes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
