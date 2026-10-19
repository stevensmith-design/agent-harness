#!/usr/bin/env bash
# PreToolUse guard for commands deliberately excluded from the macOS sandbox.
# Exclusion restores SSH and credential access; it must not become arbitrary
# unsandboxed Git/GitHub execution. Only direct, predictable lifecycle shapes
# pass. The pre-push hook independently validates the refs that Git will update.
# ci-parity: none — command execution happens before CI; pre-push and repository protections independently constrain the resulting refs
set -o pipefail

PAYLOAD=$(cat 2>/dev/null || true)
command -v python3 >/dev/null 2>&1 || {
  echo "guard-git-network: python3 is required to inspect an unsandboxed command" >&2
  exit 2
}

printf '%s' "$PAYLOAD" | python3 -c '
import json, re, shlex, sys

def block(reason):
    print(f"guard-git-network: {reason}", file=sys.stderr)
    print("Stop after this attempt. Report the blocked shape, likely cause, and safe options; do not reword it to evade this guard.", file=sys.stderr)
    raise SystemExit(2)

try:
    payload = json.load(sys.stdin)
except Exception:
    block("could not parse the tool payload")

if payload.get("tool_name") != "Bash":
    raise SystemExit(0)
cmd = (payload.get("tool_input") or {}).get("command")
if not isinstance(cmd, str) or not cmd.strip():
    block("Bash command is missing")
try:
    words = shlex.split(cmd)
except ValueError:
    block("command quoting is not balanced")
if "$(" in cmd or "`" in cmd or "\n" in cmd:
    block("command substitutions, backticks, and multiline shell are not allowed in unsandboxed lifecycle commands; use a reviewed body file")

# Commands outside the network lifecycle are not this hooks responsibility.
if not words or words[0] not in {"git", "gh"}:
    raise SystemExit(0)
if any(w in {"&&", "||", ";", "|", "&"} for w in words):
    block("run network lifecycle commands separately, without chains or pipes")

branch = re.compile(r"^(?!-)(?!.*\.\.)(?:refs/heads/)?[A-Za-z0-9][A-Za-z0-9._/-]*$")
forbidden = {"main", "master", "refs/heads/main", "refs/heads/master"}

if words[0] == "git":
    if len(words) < 2 or words[1] not in {"fetch", "pull", "push"}:
        raise SystemExit(0)
    if words in (["git", "fetch", "origin", "--prune"], ["git", "fetch", "--prune", "origin"]):
        raise SystemExit(0)
    if len(words) == 5 and words[:4] == ["git", "pull", "--ff-only", "origin"]:
        if branch.fullmatch(words[4]):
            raise SystemExit(0)
    if len(words) == 5 and words[:4] == ["git", "push", "-u", "origin"]:
        if branch.fullmatch(words[4]) and words[4] not in forbidden:
            raise SystemExit(0)
    if len(words) == 4 and words[:3] == ["git", "push", "origin"]:
        if branch.fullmatch(words[3]) and words[3] not in forbidden:
            raise SystemExit(0)
    if len(words) == 5 and words[:4] == ["git", "push", "origin", "--delete"]:
        if branch.fullmatch(words[4]) and words[4] not in forbidden:
            raise SystemExit(0)
    block("use fetch --prune, pull --ff-only, or push an explicit owned non-default branch; alternate programs, hook bypasses, refspecs, and force options are refused")

if len(words) < 3 or words[1] != "pr" or words[2] not in {"create", "view", "checks", "update-branch", "merge"}:
    raise SystemExit(0)
if words[2] == "merge" and any(w == "--admin" or w.startswith("--admin=") for w in words[3:]):
    block("gh pr merge --admin bypasses repository protections")
raise SystemExit(0)
'
