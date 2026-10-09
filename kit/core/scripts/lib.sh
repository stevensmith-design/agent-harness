#!/usr/bin/env bash
# lib.sh — shared gate plumbing.
#
# Three lessons are encoded here. Each cost a real defect somewhere:
#
# 1. fail() inside $( ) only kills the subshell. Almost every gate does
#    x=$(something), so a naive fail() makes the whole fail-closed mechanism
#    weaker than it looks. We signal the top-level shell instead.
# 2. `grep PATTERN -- FILE` is a BSD/macOS trap. GNU permutes arguments; BSD
#    reads `--` as a filename and exits 2. Always `grep -e PATTERN -- FILE`.
# 3. A gate must report its denominator. "✓ secret scan" cannot be
#    distinguished from "I examined nothing".

set -uo pipefail

trap 'exit 1' TERM
# NOT exported, and never inherited. `$$` stays constant inside command
# substitutions and subshells of THIS script, while BASHPID changes — which is
# exactly the discrimination fail() needs. Exporting it instead let a child
# gate signal its parent: running the selftest killed the selftest.
HARNESS_TOP_PID=$$

RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'
[ -t 1 ] || { RED=""; GRN=""; YEL=""; DIM=""; RST=""; }

_FAILED=0

# fail MESSAGE — record a failure and abort the whole run, not just a subshell.
fail() {
  printf '%s✗ %s%s\n' "$RED" "$*" "$RST" >&2
  _FAILED=1
  if [ "${BASHPID:-$$}" != "$HARNESS_TOP_PID" ]; then
    kill -TERM "$HARNESS_TOP_PID" 2>/dev/null
  fi
  return 1
}

# warn MESSAGE — reported, does not fail the run.
warn() { printf '%s! %s%s\n' "$YEL" "$*" "$RST" >&2; }

# pass MESSAGE COUNT — success, WITH its denominator. Never call without one.
# A missing denominator is itself a failure, and it escapes a subshell the same
# way fail() does — otherwise the very check that enforces evidence could be
# silently swallowed.
pass() {
  local msg="$1" n="${2-}"
  if [ -z "$n" ]; then
    printf '%s✗ %s reported no denominator — a tick with no count is not evidence%s\n' "$RED" "$msg" "$RST" >&2
    _FAILED=1
    if [ "${BASHPID:-$$}" != "$HARNESS_TOP_PID" ]; then
      kill -TERM "$HARNESS_TOP_PID" 2>/dev/null
    fi
    return 1
  fi
  printf '%s✓%s %s %s(%s)%s\n' "$GRN" "$RST" "$msg" "$DIM" "$n" "$RST"
}

# todo MESSAGE — an unimplemented check. Recorded, and never green.
# Uses the same subshell escape as fail(): a `_FAILED=1` set inside $( ) is
# lost, which would let a stub print and the run still exit 0.
todo() {
  printf '%s… %s (STUB — not implemented)%s\n' "$YEL" "$*" "$RST" >&2
  mkdir -p "${HARNESS_ROOT:-.}/runs/.state"
  printf '%s\n' "$*" >> "${HARNESS_ROOT:-.}/runs/.state/stubs"
  _FAILED=1
  if [ "${BASHPID:-$$}" != "$HARNESS_TOP_PID" ]; then
    kill -TERM "$HARNESS_TOP_PID" 2>/dev/null
  fi
  return 1
}

finish() { [ "$_FAILED" -eq 0 ] || exit 1; exit 0; }

# nlines [FILE] — count non-empty lines, from a file or stdin, always safely.
#
# `grep -c` prints its count AND exits 1 when that count is zero, so the
# idiomatic `n=$(grep -c ... || echo 0)` produces the string "0\n0" and every
# arithmetic test on it then errors. This trap has been hit FIVE times in this
# codebase, three of them after being written down — the fifth because detect.sh
# does not source this file, and a helper only helps where it can be reached.
# A helper is still the only fix that survives being forgotten.
nlines() {
  local n
  if [ $# -gt 0 ]; then n=$(grep -ce . -- "$1" 2>/dev/null); else n=$(grep -ce . 2>/dev/null); fi
  case "${n:-}" in ''|*[!0-9]*) n=0 ;; esac
  printf '%s\n' "$n"
}

# assert_runtime — prove the shell and userland can do what this kit assumes,
# on THIS machine, before anything depends on it.
#
# The kit is developed on Linux with bash 5 and GNU coreutils, and run on macOS
# with bash 3.2 and BSD userland. Three constructs differ, and all three fail
# SILENTLY rather than loudly:
#
#   sort -z        BSD sort without it returns nothing for a NUL-delimited
#                  stream, so all_files0 yields an empty set and every gate
#                  reports "0 examined" under a green tick. That is the worst
#                  failure available here: a denominator of zero that looks
#                  like a pass.
#   read -d ''     without it, path enumeration silently stops at the first NUL.
#   empty arrays   bash before 4.4 treats "${a[@]}" on an empty array as an
#                  unbound variable under `set -u`, which is fatal mid-run.
#
# "It works on macOS" is a claim. This is the check behind it, and it runs
# wherever the kit runs rather than wherever it was written.
assert_runtime() {
  local probe
  probe=$(printf 'b\0a\0a\0' | sort -zu 2>/dev/null | tr '\0' '|')
  [ "$probe" = "a|b|" ] || {
    printf '%s✗ this shell/userland cannot sort a NUL-delimited stream (got %s)%s\n' "$RED" "'${probe:-nothing}'" "$RST" >&2
    printf '%s  Every file set would be EMPTY and every gate would report a green zero.%s\n' "$RED" "$RST" >&2
    printf '%s  On macOS: install GNU coreutils, or run the kit under a shell whose sort has -z.%s\n' "$RED" "$RST" >&2
    return 1
  }
  probe=""
  while IFS= read -r -d '' _x; do probe="$probe$_x"; done < <(printf 'x\0y\0')
  [ "$probe" = "xy" ] || {
    printf '%s✗ this shell cannot read a NUL-delimited stream (read -d) — path enumeration would stop at the first NUL%s\n' "$RED" "$RST" >&2
    return 1
  }
  ( set -u; _e=(); : "${#_e[@]}"; : ${_e[@]+"${_e[@]}"}; ) 2>/dev/null || {
    printf '%s✗ this bash errors on an empty array under `set -u` (bash %s)%s\n' "$RED" "${BASH_VERSION:-?}" "$RST" >&2
    printf '%s  Every run with no files to examine would die instead of reporting zero.%s\n' "$RED" "$RST" >&2
    return 1
  }
  return 0
}

# harness_root — locate the harness root from anywhere beneath it.
harness_root() {
  local d="${1:-$PWD}"
  # Absolute first: `dirname .` returns `.` forever, so a relative start with
  # no harness above it hung the shell. A hung pre-commit hook gets bypassed.
  case "$d" in /*) ;; *) d="$PWD/${d#./}" ;; esac
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    [ -f "$d/harness.yaml" ] && { printf '%s\n' "$d"; return 0; }
    d=$(dirname "$d")
  done
  printf '%s✗ no harness.yaml found above %s%s\n' "$RED" "${1:-$PWD}" "$RST" >&2
  return 1
}

# all_files0 / repo_files0 — TWO SETS, and conflating them was a real defect.
#
#   all_files0  — every file that could be CHANGED. The right denominator for
#                 classification: runs/ is a declared surface (the low-risk lane
#                 where you are meant to experiment), so excluding it from
#                 resolution made that lane's pattern match nothing.
#   repo_files0 — every file the gates should READ as a document. Excludes
#                 runs/, because dated output is not a source of references and
#                 scanning it makes the reference graph unreadable.
#
# One enumerator, two views. When these were one function the surfaces table
# declared a lane whose own files were outside the set being classified.
#
# NUL, not newline, because a path is not a line. A filename containing a
# newline produced a phantom record AND a duplicate of a real file in a
# line-based reader — the denominator went UP while a real file went
# unclassified. `-z` also stops git C-quoting non-ASCII paths, which silently
# dropped every Japanese and accented filename on one machine and not another,
# since core.quotepath is a per-clone setting.
#
# `git ls-files` alone cannot see the file just written, which is the exact
# moment a check runs — hence the union with `find`.
#
# SYMLINKS ARE EXCLUDED, both branches, deliberately. Including them fixed one
# inconsistency (a tracked symlink was examined, an untracked one was not) and
# bought a worse one: doctor ran `bash -n` on a dangling `*.sh` symlink and
# reported "syntax error" for a file that does not exist, and a `CLAUDE.md ->
# AGENTS.md` link — a very common layout — double-counted its target's
# placeholders. Excluding them in BOTH branches settles the inconsistency
# without that cost. A symlink is not classified; say so rather than
# half-examining it.
#
# The prefix is applied per path, never with `sed "s|^|$root/|"` — a root
# containing `|` or `&` rewrote the paths it was supposed to prefix.
all_files0() {
  # A trailing slash makes git's branch emit `root//f` and find's `root/f` —
  # two strings for one file, and `sort -zu` cannot dedupe what is not identical.
  local root="${1:-.}"; root="${root%/}"; [ -n "$root" ] || root="/"
  {
    git -c core.quotepath=false -C "$root" ls-files -z 2>/dev/null \
      | while IFS= read -r -d '' f; do
          # REGULAR FILES ONLY, and only ones that exist. `git ls-files` reports
          # INDEX entries, so a tracked-but-deleted file was being classified
          # into a lane and counted in the denominator, while doctor blamed it
          # for a "syntax error" it could not have. The --changed branch already
          # guarded existence; its sibling did not.
          #
          # `[ ! -L ]` matters as much as `[ -f ]`: `-f` follows a symlink to a
          # regular file, while `find -P -type f` does not, so without it git's
          # branch and find's branch disagree about every symlink — the same
          # inconsistency, reintroduced from the other side.
          [ -f "$root/$f" ] && [ ! -L "$root/$f" ] && printf '%s\0' "$root/$f"
        done
    find "$root" -type f \
      -not -path '*/.git/*' -not -path '*/node_modules/*' \
      -not -name '.DS_Store' -print0 2>/dev/null
  } | sort -zu
}

repo_files0() {
  all_files0 "${1:-.}" | while IFS= read -r -d '' f; do
    case "$f" in */runs/*|runs/*|./runs/*) continue ;; esac
    printf '%s\0' "$f"
  done
}

# repo_files — the newline-delimited view, kept for callers that only ever look
# at extensions. Anything reasoning about the SET — counting it, classifying it
# — must use one of the NUL forms, or it inherits the newline bug above.
repo_files() { repo_files0 "${1:-.}" | tr '\0' '\n'; }

# cfg KEY [DEFAULT] — read a top-level or one-deep key from harness.yaml.
# Deliberately minimal. cfg_has distinguishes "absent" from "equals default" —
# conflating those silently widens a rule instead of narrowing it.
# TOP-LEVEL keys only — no leading whitespace. An indentation-blind match
# picked up a nested key of the same name from anywhere in the file, ahead of
# the real one, and reported the wrong value with a green tick.
cfg() {
  local key="$1" def="${2-}" root; root=$(harness_root) || return 1
  local v
  v=$(sed -n "s/^${key}:[[:space:]]*//p" "$root/harness.yaml" 2>/dev/null | head -1 | sed 's/[[:space:]]*#.*$//' | tr -d '"'"'")
  [ -n "$v" ] && printf '%s\n' "$v" || printf '%s\n' "$def"
}

cfg_has() {
  local key="$1" root; root=$(harness_root) || return 1
  grep -qe "^${key}:" -- "$root/harness.yaml" 2>/dev/null
}

# cfg_int KEY DEFAULT — a config value used in arithmetic MUST be validated.
# `[ "$n" -gt "60 lines" ]` errors, and in `[ ]` the error branch is the false
# branch — so a malformed budget silently became a passing budget.
cfg_int() {
  local key="$1" def="$2" v; v=$(cfg "$key" "$def")
  case "$v" in
    ''|*[!0-9]*) fail "harness.yaml: '$key' must be a whole number, got '$v'"; printf '%s\n' "$def"; return 1 ;;
    *) printf '%s\n' "$v" ;;
  esac
}

# content_status FILE — a four-state presence ladder.
#
#   Do NOT grade a check as passing just because the path exists. A docs/
#   directory whose content is stale or mismatched is present-but-stale, not healthy.
#
# A file that exists is not a file that says anything, and `-e` cannot tell the
# difference between a configured harness and an unpacked template.
#
#   missing   — not there
#   stub      — there, but carries no substantive content: only headings,
#               comments, blank lines, table rules and unfilled placeholders
#   populated — has real content
#
# The fourth state, `stale`, needs a reference point a script does not have.
# It is a judgement the review lens makes, not a check. Saying so is better
# than approximating it with a timestamp and calling the result a fact.
content_status() {
  local f="$1"
  [ -f "$f" ] || { printf 'missing\n'; return; }
  local n
  n=$(grep -ve '^[[:space:]]*$' -- "$f" 2>/dev/null \
      | grep -ve '^[[:space:]]*#' -- \
      | grep -ve '^[[:space:]]*<!--' -- \
      | grep -ve '^[[:space:]]*|[[:space:]]*[-:| ]*|[[:space:]]*$' -- \
      | grep -ve '^[[:space:]]*[-*][[:space:]]*\[none' -- \
      | grep -ve '{{[^}]*}}' -- \
      | wc -l | tr -d ' ')
  if [ "${n:-0}" -lt 3 ]; then printf 'stub\n'; else printf 'populated\n'; fi
}
