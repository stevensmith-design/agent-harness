#!/usr/bin/env bash
# Shared helpers. Sourced by every script in scripts/. No external deps beyond
# coreutils, grep, sed, awk — the harness must run on a bare CI image.

set -euo pipefail

HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG="$HARNESS_ROOT/harness.config.yaml"

# Minimal YAML reader for the two-level shape this config uses:
#   cfg section.key [default]   or   cfg key [default]
# Deliberately not a YAML parser. If you need deeper nesting in a script,
# install `yq` and swap this function out — nothing else changes.
#
# It DOES understand block-style lists, because falling back to a default when
# the user wrote their list the other legal way is how a narrowed policy
# silently widens itself:
#     allowed_licenses:            ->  "MIT, Apache-2.0"
#       - MIT
#       - Apache-2.0
#
# `cfg` cannot distinguish "absent" from "present but equal to the default".
# When that distinction matters — and for anything security-relevant it always
# does — use `cfg_req`, which fails when the key is missing.

_cfg_missing_config() {
  [ -f "$CONFIG" ] && return 1
  [ "${HARNESS_CFG_OPTIONAL:-0}" = 1 ] && return 0
  fail "harness.config.yaml not found at $CONFIG — refusing to run on defaults.
    Every gate reads its policy from that file. Without it a gate cannot tell
    'the policy allows this' from 'I could not find the policy', and would
    report clean either way. Run 'make harness-init' or restore the file."
}

# _cfg_raw <section> <key> — prints the value, or nothing if the key is absent.
# Exit status is 0 when the key was FOUND (even with an empty value), 1 when not.
_cfg_raw() {
  local section="$1" key="$2" out rc
  out=$(SECTION="$section" KEY="$key" awk '
    BEGIN { sec=ENVIRON["SECTION"]; k=ENVIRON["KEY"]; inSec=(sec=="");
            found=0; listing=0; list="" }
    function emit(v) {
      sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]+#.*$/,"",v); return v
    }
    # A block-list item belonging to the key we just matched.
    listing && /^[[:space:]]*-[[:space:]]*/ {
      item=$0; sub(/^[[:space:]]*-[[:space:]]*/,"",item); sub(/[[:space:]]+#.*$/,"",item)
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",item)
      if (item != "") list = (list == "" ? item : list ", " item)
      next
    }
    listing && /^[[:space:]]*#/ { next }
    listing { listing=0 }              # anything else ends the list
    /^[[:space:]]*#/ { next }
    /^[^[:space:]#]/ {
      top=$0; sub(/:.*/,"",top); gsub(/[[:space:]]/,"",top)
      inSec = (sec != "" && top == sec)
      if (sec == "" && top == k) { found=1; v=emit($0); if (v=="") { listing=1 } else { print v; exit } }
      next
    }
    inSec && /^[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*:/ {
      line=$0; sub(/^[[:space:]]+/,"",line)
      kk=line; sub(/:.*/,"",kk)
      if (kk == k) { found=1; v=emit(line); if (v=="") { listing=1 } else { print v; exit } }
    }
    END { if (found && list != "") print list; exit (found ? 0 : 1) }
  ' "$CONFIG") && rc=0 || rc=$?
  printf '%s' "$out"
  return "$rc"
}

# cfg <path> [default] — always succeeds; prints the default when absent.
cfg() {
  local path="$1" default="${2-}" out section key rc=0
  _cfg_missing_config && { printf '%s\n' "$default"; return 0; }
  case "$path" in
    *.*) section="${path%%.*}"; key="${path#*.}" ;;
    *)   section=""; key="$path" ;;
  esac
  out=$(_cfg_raw "$section" "$key") || rc=$?
  out="${out%"${out##*[![:space:]]}"}"
  case "$out" in
    \"*\") out="${out%\"}"; out="${out#\"}" ;;
    "'"*"'") out="${out%\'}"; out="${out#\'}" ;;
  esac
  if [ "$rc" = 0 ] && [ -n "$out" ]; then printf '%s\n' "$out"; else printf '%s\n' "$default"; fi
}

# cfg_has <path> — 0 if the key is present in the config, 1 if absent.
cfg_has() {
  local path="$1" section key
  _cfg_missing_config && return 1
  case "$path" in
    *.*) section="${path%%.*}"; key="${path#*.}" ;;
    *)   section=""; key="$path" ;;
  esac
  _cfg_raw "$section" "$key" >/dev/null
}

# cfg_req <path> — print the value, or abort. Use for any key whose absence
# would make a check pass by accident.
cfg_req() {
  local path="$1" v
  cfg_has "$path" || fail "harness.config.yaml is missing '$path'.
    A gate depends on it, and a missing policy is not the same as a permissive
    one — refusing to guess. Add the key, or set it explicitly to 'off'."
  v="$(cfg "$path")"
  [ -n "$v" ] || fail "harness.config.yaml has '$path' but its value is empty.
    Set it explicitly rather than leaving it blank."
  printf '%s\n' "$v"
}

# policy <path> <default> — read an error|warn|off policy key. Any other value
# is a config error, not a silent "off": the whole point of naming a policy is
# that an unrecognised one must be noisy.
policy() {
  local path="$1" default="$2" v
  v="$(cfg "$path" "$default")"
  case "$v" in
    error|warn|off) printf '%s\n' "$v" ;;
    true|yes|on|ERROR|Error) fail "harness.config.yaml: '$path' is '$v'. Use one of: error, warn, off." ;;
    *) fail "harness.config.yaml: '$path' is '$v', which is not a policy. Use one of: error, warn, off." ;;
  esac
}

# --- Fail-closed helpers -------------------------------------------------------
# `grep || true` is the most common way a gate silently stops working: grep exits
# 1 for "no match" and 2+ for "I broke" (bad regex, unreadable file, missing
# binary), and `|| true` flattens both into "clean". These wrappers keep the
# distinction, so a broken checker fails the build instead of passing it.

# sgrep <args...> — grep that treats "no match" as empty output and any real
# error as fatal. Use everywhere a gate greps.
sgrep() {
  local out rc=0
  # `|| rc=$?` is load-bearing: without it `set -e` kills the shell on grep's
  # exit 1 before we can tell "no match" apart from "broken".
  out=$(grep "$@") || rc=$?
  case "$rc" in
    0) printf '%s\n' "$out" ;;
    1) : ;;                       # no match — legitimately empty
    *) fail "grep failed (exit $rc) on: $* — refusing to report 'clean' from a broken check" ;;
  esac
}

# must <description> <command...> — run a command whose failure must abort the
# gate rather than yield an empty result.
must() {
  local what="$1"; shift
  "$@" || fail "$what failed — refusing to continue with an unknown result"
}

# scount <args...> — grep -c that keeps the same distinction. `grep -c || echo 0`
# is the counting flavour of the same bug: an unreadable file counts as zero.
scount() {
  local out rc=0
  out=$(grep -c "$@") || rc=$?
  case "$rc" in
    0) printf '%s\n' "$out" ;;
    1) printf '0\n' ;;            # no match — a real zero
    *) fail "grep -c failed (exit $rc) on: $* — refusing to report a count from a broken check" ;;
  esac
}

info()  { printf '\033[36m•\033[0m %s\n' "$*"; }
ok()    { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m!\033[0m %s\n' "$*" >&2; }

# `exit` inside a command substitution or a pipeline element only ends the
# SUBSHELL. The parent then carries on with an empty string — which is precisely
# the "clean result from a broken check" the fail-closed helpers exist to
# prevent, and nearly every gate calls them as `x=$(sgrep ...)`. So when fail()
# notices it is not the top-level shell, it signals the top-level shell too.
trap 'exit 1' TERM
fail() {
  printf '\033[31m✗\033[0m %s\n' "$*" >&2
  [ "${BASHPID:-$$}" = "$$" ] || kill -TERM $$ 2>/dev/null
  exit 1
}

# --- Three results, not two ------------------------------------------------------
# PASS, FAIL, and NOT VERIFIED: the check could not run, or ran over a stub.
# NOT VERIFIED lets ordinary work continue — a fresh install has stub adapters
# and must still be usable — but it can never satisfy closure, merge, release or
# the Definition of done. In a readiness context (CI, or HARNESS_STRICT=1) it
# fails exactly like FAIL; everywhere else it is printed and returns.
strict() { [ -n "${CI:-}" ] || [ "${HARNESS_STRICT:-}" = 1 ]; }
not_verified() {
  printf '\033[33m?\033[0m NOT VERIFIED — %s\n' "$*" >&2
  if strict; then fail "NOT VERIFIED is not a pass in a readiness context (CI or HARNESS_STRICT=1)"; fi
  return 0
}

# --- Declared vs discovered inputs ---------------------------------------------
# `[ -f "$f" ] || continue` over a GLOB is correct: the glob is a discovery and
# no matches is a real zero. The identical line over a path the gate NAMED is a
# different thing entirely — the file drops out of the output and the gate
# reports success by saying nothing. That is not hypothetical: this harness's
# own instruction-budget gate skipped AGENTS.md if AGENTS.md was missing, and
# went green.
#
# So a gate must say which kind of input it is looking at:
#   req_input <path> <what>  — absent means the gate cannot do its job. Abort.
#   opt_input <path>         — absent is legitimate, but it is RECORDED and
#                              printed, so a check never claims coverage it lacked.
#
# The rule this encodes: a check may report "clean", or it may report "I did not
# look" — it may never report the second as the first.
SKIPPED_INPUTS=""

req_input() {
  local rel="$1" what="${2:-a declared input}"
  [ -f "$HARNESS_ROOT/$rel" ] && return 0
  fail "$rel is missing, and this gate names it as $what.
    A gate that quietly skips a file it named reports success by saying nothing.
    Restore the file, or stop naming it here if it is genuinely optional."
}

# 0 when present; 1 when absent (and the absence is recorded).
opt_input() {
  local rel="$1"
  [ -f "$HARNESS_ROOT/$rel" ] && return 0
  skipped "$rel"
  return 1
}

# skipped <thing> — record something this run did not examine. Use for anything
# a gate meant to cover and could not, including non-file blind spots.
skipped() {
  case $'\n'"$SKIPPED_INPUTS" in *$'\n'"$1"$'\n'*) return 0 ;; esac
  SKIPPED_INPUTS="$SKIPPED_INPUTS$1"$'\n'
}

# blind_spots — print what was not covered. Call before the closing ok().
# Deliberately not a failure: the point is that the check-mark stops being
# ambiguous, not that every absence becomes an error.
blind_spots() {
  [ -n "$SKIPPED_INPUTS" ] || return 0
  local n; n=$(printf '%s' "$SKIPPED_INPUTS" | grep -c . || true)
  warn "not examined ($n):"
  # Capped: a blind-spot list long enough to scroll past is one nobody reads,
  # and the count above is the part that matters.
  printf '%s' "$SKIPPED_INPUTS" | head -10 | sed 's/^/      /' >&2
  [ "$n" -gt 10 ] && warn "      … and $((n - 10)) more"
  warn "    The result below covers everything else. It does not cover the above."
  return 0
}

# --- Declared intent -----------------------------------------------------------
# `HARNESS_HUMAN_APPROVED=1` and `HARNESS_ALLOW_SELF_EDIT=1` were booleans: no
# reason, no scope, no trace, and — worst — no expiry. Exported once in a shell
# profile or a CI job, they authorised every later change in that session,
# including the ones nobody looked at.
#
# A declaration is branch-bound and reasoned. It is honoured only while the
# branch it was recorded on is the branch you are on, so it cannot leak into the
# next piece of work, and it leaves a sentence saying what it was for.
#
# The file is gitignored on purpose: an intent that survives in the repo is an
# intent that authorises somebody else's change.
INTENT_FILE="${HARNESS_INTENT_FILE:-$HARNESS_ROOT/.harness-intent}"

# intent_reason <scope> — prints the reason and returns 0 when a live
# declaration covers <scope>; returns 1 otherwise.
intent_reason() {
  local scope="$1" f_scope f_branch f_reason branch
  [ -f "$INTENT_FILE" ] || return 1
  f_scope=$(sed -n 's/^scope=//p'  "$INTENT_FILE" | head -1)
  f_branch=$(sed -n 's/^branch=//p' "$INTENT_FILE" | head -1)
  f_reason=$(sed -n 's/^reason=//p' "$INTENT_FILE" | head -1)
  [ "$f_scope" = "$scope" ] || return 1
  branch=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')
  # No branch means no binding, and an unbindable declaration is not a
  # declaration. Refuse rather than accept it everywhere.
  [ -n "$branch" ] && [ "$branch" = "$f_branch" ] || return 1
  [ -n "$f_reason" ] || return 1
  printf '%s\n' "$f_reason"
}

# --- Unimplemented adapter verbs ------------------------------------------------
# A TODO stub that exits 0 is indistinguishable from a check that ran and passed.
# The shipped `generic` adapter stubbed lint, format, test and verify, so a fresh
# install printed "✓ all deterministic gates passed" having proved nothing — and
# `make verify` wrote an evidence record saying `result: pass`. Stubs are fine
# while you fill an adapter in. They must never be mistaken for evidence.
# A fixed path, not a $$-scoped temp file: `make check` runs each verb in its
# own process, so the record of "this verb was a stub" has to outlive them and
# reach the summary line at the end. Cleared by `make check` before it starts.
STUB_MARK="${HARNESS_STUB_MARK:-$HARNESS_ROOT/.agents/runs/.stubs}"
todo() {
  warn "TODO: $* — not implemented in adapter '${ADAPTER_NAME:-?}'"
  mkdir -p "$(dirname "$STUB_MARK")" 2>/dev/null || true
  printf '%s\n' "$*" >> "$STUB_MARK" 2>/dev/null || true
}
stubbed() { [ -s "$STUB_MARK" ]; }
stub_summary() {
  stubbed || return 0
  # Inside `make check` the summary is printed once, at the end, by
  # check-summary.sh. Printing it after every verb repeated a growing copy four
  # times in one run — noise a person scrolls past and an agent pays for in
  # tokens on every check. Never in CI: there this is the failure, not a message.
  if [ "${HARNESS_STUB_SUMMARY:-}" = end ] && ! strict; then return 0; fi
  warn ""
  warn "This run used $(wc -l < "$STUB_MARK" | tr -d ' ') unimplemented adapter verb(s):"
  sed 's/^/    /' "$STUB_MARK" >&2
  warn "  Nothing was proved about them. Fill them in in scripts/adapters/${ADAPTER_NAME:-<adapter>}.sh."
  if strict; then
    fail "refusing to report success in CI with unimplemented verbs — a stub is not a passing check"
  fi
}

# Load the adapter selected in harness.config.yaml.
load_adapter() {
  local a; a="$(cfg harness.adapter generic)"
  local f="$HARNESS_ROOT/scripts/adapters/$a.sh"
  [ -f "$f" ] || fail "adapter '$a' not found at $f"
  # shellcheck disable=SC1090
  . "$f"
  ADAPTER_NAME="$a"
}

# Adapters define cmd_* functions. A verb the adapter does not implement is a
# clean skip, not a crash — a Flutter repo has no `typecheck`, a Go repo has no
# `codegen`. Silence here is a deliberate design choice: the harness must run
# end to end on a partially-filled adapter.
run_verb() {
  local verb="$1"; shift || true
  if declare -f "cmd_$verb" >/dev/null; then
    "cmd_$verb" "$@"
  else
    warn "adapter '$ADAPTER_NAME' does not implement '$verb' — skipped"
  fi
}

# --- Path helpers --------------------------------------------------------------
# One implementation of glob → anchored POSIX ERE, used by every gate that reads
# a `paths:` list. There used to be two copies; they were already drifting.

# glob_re <glob> — a single glob as an anchored regex.
glob_re() {
  printf '%s' "$1" \
    | sed 's/\./\\./g; s|\*\*/|<ANYDIR>|g; s/\*\*/<ANY>/g; s|\*|[^/]*|g; s|<ANYDIR>|(.*/)?|g; s/<ANY>/.*/g' \
    | sed 's/^/^/; s/$/$/'
}

# glob_alt <glob-list> — a bracketed/comma list as ONE alternation. Globs in a
# `paths:` list are alternatives (OR); ANDing them was a real bug once.
glob_alt() {
  printf '%s' "$1" | tr -d '[]"'"'" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' \
  | sed 's/\./\\./g; s|\*\*/|<ANYDIR>|g; s/\*\*/<ANY>/g; s|\*|[^/]*|g; s|<ANYDIR>|(.*/)?|g; s/<ANY>/.*/g' \
  | paste -sd'|' - | sed 's/^/^(/; s/$/)$/'
}

# harness_prefix — where the harness sits inside the git repo, as a path prefix
# ("" at the repo root, "packages/app/" in a monorepo). `git diff --name-only`
# speaks repo-relative paths; every gate's globs speak harness-relative ones.
# Without this, a harness installed in a subdirectory sees no path it recognises
# and passes everything.
harness_prefix() {
  local top; top=$(git -C "$HARNESS_ROOT" rev-parse --show-toplevel 2>/dev/null) || { printf ''; return 0; }
  local abs; abs=$(cd "$HARNESS_ROOT" && pwd -P)
  top=$(cd "$top" && pwd -P)
  [ "$abs" = "$top" ] && { printf ''; return 0; }
  printf '%s/' "${abs#"$top"/}"
}

# changed_files [base-ref] — harness-relative paths changed against the base.
# Files outside the harness directory are dropped, and git's C-quoting of
# non-ASCII paths is undone (a quoted path matches no glob, so an ordinary
# source file with an accent in its name was being classified as harness code).
changed_files() {
  local base="${1:-}" pfx raw
  pfx="$(harness_prefix)"
  if [ -n "$base" ] && git -C "$HARNESS_ROOT" rev-parse --verify "$base" >/dev/null 2>&1; then
    raw=$(git -C "$HARNESS_ROOT" -c core.quotepath=false diff --name-only "$base...HEAD" 2>/dev/null) || raw=""
  else
    raw=$(git -C "$HARNESS_ROOT" -c core.quotepath=false diff --name-only HEAD 2>/dev/null) || raw=""
  fi
  printf '%s\n' "$raw" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in \"*\") f="${f%\"}"; f="${f#\"}" ;; esac
    if [ -n "$pfx" ]; then
      case "$f" in "$pfx"*) f="${f#"$pfx"}" ;; *) continue ;; esac
    fi
    printf '%s\n' "$f"
  done
}

# repo_files — every file a gate should examine: tracked files PLUS the working
# tree. Scanning only `git ls-files` meant a gate could not see the file that was
# just written — which is the exact moment the agent loop runs `make check`.
repo_files() {
  {
    git -C "$HARNESS_ROOT" -c core.quotepath=false ls-files 2>/dev/null || true
    git -C "$HARNESS_ROOT" -c core.quotepath=false ls-files --others --exclude-standard 2>/dev/null || true
  } | sed 's/^"//; s/"$//' | sort -u | grep -v '^$' || true
}
