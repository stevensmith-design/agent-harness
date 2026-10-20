#!/usr/bin/env bash
# Guard the narrow repository-network commands that may run outside Claude
# Code's macOS sandbox. The pre-push hook separately validates actual refs.
set -o pipefail

PAYLOAD=$(cat 2>/dev/null || true)
command -v python3 >/dev/null 2>&1 || {
  echo "guard-git-network: python3 is required to inspect an unsandboxed command" >&2
  exit 2
}

printf '%s' "$PAYLOAD" | python3 -c '
import json, os, re, shlex, sys

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
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|")
    lex.whitespace_split = True
    words = list(lex)
except ValueError:
    # Unbalanced quoting is irrelevant to this hook unless the command even
    # names Git/GitHub. The shell will report ordinary quoting errors itself.
    if not re.search(r"(^|[;&|\s])(?:[^/\s]*/)?(?:git|gh)(?=\s|$)", cmd):
        raise SystemExit(0)
    block("command quoting is not balanced")

operators = {"&&", "||", ";", "|", "&"}

def executable(word):
    return os.path.basename(word) if isinstance(word, str) else word

def git_shape(start):
    """Return (subcommand, subcommand-index, used-global-options)."""
    i = start + 1
    used = []
    takes_value = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env"}
    flags = {"--bare", "--no-replace-objects", "--literal-pathspecs", "--glob-pathspecs", "--noglob-pathspecs", "--icase-pathspecs", "--no-optional-locks", "--no-pager", "--paginate", "-p", "--version", "--help"}
    while i < len(words) and words[i] not in operators:
        w = words[i]
        if w == "--":
            used.append(w); i += 1; break
        if w in takes_value:
            used.append(w)
            if i + 1 >= len(words) or words[i + 1] in operators:
                return (None, i, used)
            used.append(words[i + 1]); i += 2; continue
        if any(w.startswith(x + "=") for x in takes_value if x.startswith("--")):
            used.append(w); i += 1; continue
        if w in flags:
            used.append(w); i += 1; continue
        if w.startswith("-"):
            used.append(w); i += 1; continue
        return (w, i, used)
    return (None, i, used)

# Decide scope before rejecting substitutions, newlines, chains or pipes. This
# hook is installed on every Bash call; timing wrappers around make check and
# local read-only Git pipelines must remain ordinary sandboxed commands.
network = []
starts = [0] + [i + 1 for i, w in enumerate(words) if w in operators and i + 1 < len(words)]
for i in starts:
    # Environment assignments may precede a command. An actual wrapper around a
    # network command is detected and then rejected below because it is not a
    # direct lifecycle shape; words such as "git" in echo/printf arguments are
    # not mistaken for commands.
    while i < len(words) and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", words[i]):
        i += 1
    if i >= len(words):
        continue
    exe = executable(words[i])
    if exe == "git":
        sub, sub_i, globals_used = git_shape(i)
        if sub in {"fetch", "pull", "push"}:
            network.append(("git", i, sub_i, globals_used))
    elif exe == "gh":
        network.append(("gh", i, i + 1, []))
if not network:
    raise SystemExit(0)
if "$(" in cmd or "`" in cmd or "\n" in cmd:
    block("command substitutions, backticks, and multiline shell are not allowed in unsandboxed lifecycle commands; use a reviewed body file")
if len(network) != 1 or network[0][1] != 0 or any(w in operators for w in words):
    block("run one network lifecycle command directly, without wrappers, chains, or pipes")

branch = re.compile(r"^(?!-)(?!.*\.\.)(?:refs/heads/)?[A-Za-z0-9][A-Za-z0-9._/-]*$")
forbidden = {"main", "master", "refs/heads/main", "refs/heads/master"}

kind, start, sub_i, globals_used = network[0]
if kind == "git":
    if globals_used:
        block("Git global options are not permitted for network operations; -C, -c, alternate programs and configuration overrides can change the repository or bypass policy")
    # From here the accepted shapes intentionally have the subcommand at 1.
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

# GitHub CLI is deny-by-default. In particular, gh api can update refs, merge
# PRs and bypass the intent of a friendly-looking command permission.
if len(words) < 3 or words[1] != "pr" or words[2] not in {"create", "view", "checks", "update-branch", "merge"}:
    block("GitHub CLI operation is not in the lifecycle allowlist; gh api and all non-approved commands are denied")
if words[2] == "merge" and any(w == "--admin" or w.startswith("--admin=") for w in words[3:]):
    block("gh pr merge --admin bypasses repository protections")
raise SystemExit(0)
'
