#!/usr/bin/env bash
# PreToolUse on Edit|Write|Bash. Direct edits and recognizable shell writes to
# harness-owned files are blocked unless an operator-approved, branch-bound
# harness intent exists. Declaration files themselves can only be changed by
# their declaration commands, whose permission entries are in the ask list.
#
# This recognizes common write shapes; it is not a shell-language sandbox. CI's
# protected-path gate remains the independent backstop.
# ci-parity: scripts/gates/protected-paths.sh
set -o pipefail

PAYLOAD=$(cat 2>/dev/null || true)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
command -v python3 >/dev/null 2>&1 || {
  echo "block-protected: python3 is required to inspect protected writes" >&2
  exit 2
}

printf '%s' "$PAYLOAD" | PROJECT_DIR="$PROJECT_DIR" python3 -c '
import json, os, platform, re, shlex, subprocess, sys
from pathlib import Path

def stop(display, declaration=False):
    if declaration:
        print(f"Blocked: {display} is an operator-controlled declaration.", file=sys.stderr)
        print("Use the matching declaration command; it must cross the explicit approval boundary.", file=sys.stderr)
    else:
        print(f"Blocked: {display} is harness configuration. Changing it during product work is how gates get quietly relaxed.", file=sys.stderr)
        print("If this is genuinely needed, obtain operator approval for:", file=sys.stderr)
        print("  ./scripts/declare-intent.sh harness-edit \"<why, in a sentence>\"", file=sys.stderr)
    print("If this classification looks wrong, stop after this attempt. Report the matched path and safe options; do not switch tools or rewrite the edit to evade the hook.", file=sys.stderr)
    raise SystemExit(2)

try:
    payload = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
tool = payload.get("tool_name")
ti = payload.get("tool_input") or {}
project = Path(os.environ.get("PROJECT_DIR", ".")).resolve()

def shell_targets(command):
    out = []
    # Ordinary output redirects: > file, >>file, 2>file. Here-doc input is not
    # a write target and is deliberately absent from this expression.
    redirect = re.compile(r"(?:^|[;|&\s])(?:\d*)>{1,2}\s*(?:\"([^\"]+)\"|\x27([^\x27]+)\x27|([^\s;&|]+))")
    for m in redirect.finditer(command):
        out.append(next(x for x in m.groups() if x is not None))
    try:
        lex = shlex.shlex(command, posix=True, punctuation_chars=";&|")
        lex.whitespace_split = True
        words = list(lex)
    except ValueError:
        return out
    ops = {";", "&&", "||", "|", "&"}
    segments, current = [], []
    for word in words + [";"]:
        if word in ops:
            if current: segments.append(current)
            current = []
        else:
            current.append(word)
    for seg in segments:
        exe = os.path.basename(seg[0])
        args = seg[1:]
        if exe == "tee":
            out.extend(a for a in args if not a.startswith("-"))
        elif exe in {"touch", "truncate", "rm", "unlink"}:
            out.extend(a for a in args if not a.startswith("-"))
        elif exe in {"cp", "mv", "install"}:
            vals = [a for a in args if not a.startswith("-")]
            if vals: out.append(vals[-1])
        elif exe == "sed" and any(a == "-i" or a.startswith("-i") for a in args):
            out.extend(a for a in args if not a.startswith("-") and not a.startswith("s/"))
    return out

targets = []
if tool in {"Edit", "Write"}:
    value = ti.get("file_path")
    if isinstance(value, str) and value: targets.append(value)
elif tool == "Bash":
    value = ti.get("command")
    if isinstance(value, str) and value: targets.extend(shell_targets(value))
else:
    raise SystemExit(0)

def git_root(path):
    probe = path if path.is_dir() else path.parent
    while not probe.exists() and probe != probe.parent:
        probe = probe.parent
    try:
        raw = subprocess.check_output(["git", "-C", str(probe), "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL, text=True).strip()
        return Path(raw).resolve()
    except Exception:
        return project

def norm(value):
    return value.casefold() if platform.system() == "Darwin" else value

def protected(rel):
    r = norm(rel)
    exact = {norm(x) for x in ["AGENTS.md", "harness.config.yaml", ".harness-intent", ".dependency-intent", "scripts/lib.sh", "scripts/declare-intent.sh", "scripts/declare-dependency-change.sh"]}
    if r in exact: return True
    prefixes = [".agents/", ".claude/", ".githooks/", ".github/workflows/", "docs/decisions/", "scripts/gates/"]
    return any(r.startswith(norm(p)) for p in prefixes)

def declaration(rel):
    return norm(rel) in {norm(".harness-intent"), norm(".dependency-intent")}

def intent_ok(root):
    f = root / ".harness-intent"
    try:
        values = {}
        for line in f.read_text(encoding="utf-8").splitlines():
            if "=" in line:
                k, v = line.split("=", 1); values.setdefault(k, v)
        branch = subprocess.check_output(["git", "-C", str(root), "rev-parse", "--abbrev-ref", "HEAD"], stderr=subprocess.DEVNULL, text=True).strip()
        return values.get("scope") == "harness-edit" and bool(values.get("reason")) and branch not in {"", "HEAD"} and values.get("branch") == branch
    except Exception:
        return False

for raw in targets:
    # Dynamic shell paths are not guessed at here; the CI backstop classifies
    # the resulting diff. Recognizable literal writes are blocked immediately.
    if not raw or any(ch in raw for ch in "$`*?{}"):
        continue
    path = Path(raw)
    if not path.is_absolute(): path = project / path
    path = path.resolve(strict=False)
    root = git_root(path)
    try:
        rel = path.relative_to(root).as_posix()
    except ValueError:
        continue
    if not protected(rel):
        continue
    if declaration(rel):
        stop(rel, declaration=True)
    if not intent_ok(root):
        stop(rel)
raise SystemExit(0)
'
