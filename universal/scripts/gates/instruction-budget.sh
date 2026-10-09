#!/usr/bin/env bash
# Instruction-budget gate. An instruction file nobody can hold in their head is
# an instruction file agents skim. Budgets are the only thing that stops drift.
. "$(dirname "$0")/../lib.sh"

check() {
  local file="$1" max="$2" what="$3"
  # Named here, so its absence is reported rather than skipped. `|| return 0`
  # meant deleting AGENTS.md made this gate greener.
  opt_input "$file" || return 0
  # scount, not `grep -c || echo 0`: an unreadable file must abort, not measure
  # as zero lines and pass. This was the one gate not using the fail-closed
  # helpers, and it was the one gate that could be silenced by a chmod.
  local n; n=$(scount -vE -e '^[[:space:]]*(<!--|$)' -- "$HARNESS_ROOT/$file")
  if [ "$n" -gt "$max" ]; then
    warn "$file is $n lines ($what budget: $max). Move detail into docs/ or a skill."
    return 1
  fi
  return 0
}

# Pointer files exist to route, not to hold rules. Left uncapped they slowly
# re-accumulate rule text and fork from the canonical doc — and because they are
# generated here, a hand-edit is also silently overwritten.
check_pointer() {
  local file="$1" max_bytes=1024
  opt_input "$file" || return 0
  local b; b=$(wc -c < "$HARNESS_ROOT/$file" | tr -d ' ')
  if [ "$b" -gt "$max_bytes" ]; then
    warn "$file is $b bytes (pointer budget: $max_bytes). A pointer routes; it does not hold rules."
    return 1
  fi
  return 0
}

# --- the set-level budget ---------------------------------------------------
# Per-file caps catch one bloated file. They cannot catch the attention cost of
# the always-loaded SET, which is what an agent actually pays before it reads a
# line of your code. Cap only AGENTS.md and the content moves next door.
always_loaded_files() {
  printf '%s\n' AGENTS.md CLAUDE.md
  for f in "$HARNESS_ROOT"/.agents/rules/*.md; do
    [ -f "$f" ] || continue
    # `trigger: always` in the frontmatter is the definition — read it from the
    # rules themselves, never from a hand-maintained list in a doc. A list of
    # what is always loaded is one more thing that can be wrong.
    local t; t=$(awk '/^---/{n++} n==1 && /^trigger:/{sub(/^trigger:[[:space:]]*/,"");gsub(/[[:space:]]/,"");print;exit}' "$f")
    [ "$t" = "always" ] && printf '.agents/rules/%s\n' "$(basename "$f")"
  done
}

check_set() {
  local budget total=0 n rows=""
  budget=$(cfg harness.always_loaded_budget 200)
  case "$budget" in ''|*[!0-9]*) fail "harness.always_loaded_budget is '$budget' — must be a number of lines" ;; esac
  while IFS= read -r rel; do
    opt_input "$rel" || continue
    n=$(scount -vE -e '^[[:space:]]*(<!--|$)' -- "$HARNESS_ROOT/$rel")
    total=$((total + n))
    rows="$rows$(printf '    %-34s %4s\n' "$rel" "$n")"$'\n'
  done < <(always_loaded_files)
  if [ "$total" -gt "$budget" ]; then
    warn "the always-loaded set is $total lines (budget: $budget):"
    printf '%s' "$rows" >&2
    warn "    Every agent reads all of this before it looks at one line of your code."
    warn "    Moving a section between these files changes nothing — the cost is the set."
    return 1
  fi
  info "always-loaded set: $total/$budget lines across $(always_loaded_files | wc -l | tr -d ' ') files"
  return 0
}

# --- cache stability -----------------------------------------------------------
# The always-loaded set is the prompt prefix every request pays for. Providers
# cache on an EXACT prefix match, so one volatile byte in it — a timestamp, a run
# id, a commit SHA — turns every request into a cache miss. Nothing errors,
# nothing looks wrong, and the only symptom is the bill and the latency. This is
# the cheapest possible check for the most invisible possible failure.
check_cache_stability() {
  local bad=0 rel hits
  while IFS= read -r rel; do
    opt_input "$rel" || continue
    hits=$(sgrep -nE -e '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}|\b[0-9a-f]{40}\b|\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-|[Gg]enerated (on|at) ' -- "$HARNESS_ROOT/$rel" || true)
    if [ -n "$hits" ]; then
      warn "$rel carries content that changes between runs:"
      printf '%s\n' "$hits" | head -5 | sed 's/^/      /' >&2
      bad=1
    fi
  done < <(always_loaded_files)
  if [ "$bad" = 1 ]; then
    warn "    Everything above is in the always-loaded prefix. Providers cache on an"
    warn "    exact prefix match, so a value that changes each run makes every request"
    warn "    a cache miss — silently. Move it to a file that loads on demand."
    return 1
  fi
  # Generation must also be deterministic: a generator that stamps the time
  # produces a different prefix on every sync, with the same effect.
  if [ -x "$HARNESS_ROOT/scripts/harness-sync.sh" ]; then
    local a b
    # cksum, not md5sum: macOS ships `md5`, not `md5sum`. The harness lints for
    # BSD-unsafe grep and would have missed this one.
    a=$("$HARNESS_ROOT/scripts/harness-sync.sh" --check 2>&1 | cksum)
    b=$("$HARNESS_ROOT/scripts/harness-sync.sh" --check 2>&1 | cksum)
    [ "$a" = "$b" ] || { warn "harness-sync is not deterministic — the generated prefix differs between runs"; return 1; }
  fi
  return 0
}

# --size: print "<lines> <bytes>" for the always-loaded set and stop. Read by
# scripts/retro-evidence.sh, so the retro records the size this gate enforces
# from the same file list and the same line rule — not from a second parser.
if [ "${1:-}" = "--size" ]; then
  req_input AGENTS.md "the canonical instruction file"
  lines=0; bytes=0
  while IFS= read -r rel; do
    opt_input "$rel" || continue
    lines=$((lines + $(scount -vE -e '^[[:space:]]*(<!--|$)' -- "$HARNESS_ROOT/$rel")))
    bytes=$((bytes + $(wc -c < "$HARNESS_ROOT/$rel" | tr -d ' ')))
  done < <(always_loaded_files)
  printf '%s %s\n' "$lines" "$bytes"
  exit 0
fi

rc=0
# The one input this gate cannot do without. Everything below measures the
# always-loaded set; with no canonical file there is no set, and a total of 0
# is under every budget.
req_input AGENTS.md "the canonical instruction file"
check_set || rc=1
check_cache_stability || rc=1
check AGENTS.md 80 "canonical instructions" || rc=1
check .agents/memory/MEMORY.md 200 "memory index" || rc=1
# CLAUDE.md only. `.github/copilot-instructions.md` is deliberately a full
# generated VIEW of AGENTS.md, not a pointer — Copilot reads it directly, so
# routing it somewhere else would leave that tool with no rules at all.
check_pointer CLAUDE.md || rc=1
for f in "$HARNESS_ROOT"/.agents/rules/*.md; do
  [ -f "$f" ] || continue
  check ".agents/rules/$(basename "$f")" 60 "path rule" || rc=1
done
for f in "$HARNESS_ROOT"/.agents/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  check ".agents/skills/$(basename "$(dirname "$f")")/SKILL.md" 200 "skill" || rc=1
done
blind_spots
if [ "$rc" -ne 0 ]; then
  warn ""
  warn "Net-zero rule: to add a line to an always-loaded file, name one to remove."
  warn "  Hitting the limit means something in there has stopped earning its place —"
  warn "  move it to docs/, a path-scoped rule, or a skill. Do not raise the budget."
  fail "instruction budget exceeded"
fi
ok "instruction budgets"
