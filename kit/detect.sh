#!/usr/bin/env bash
# detect.sh — read a target and decide which motion applies. WRITES NOTHING.
#
# Without this, the agent guesses which motion it is in, and the guess decides
# whether it creates files or reviews what is already there. On someone's real
# repository that is the difference between helpful and destructive.
#
# Four motions, decided in priority order, FAIL CLOSED: when the evidence is
# ambiguous, resolve toward the motion that writes least. `greenfield` is the
# only one that scaffolds freely, so it is the one that must be earned.
#
#   harness    — a kit harness is already here. Review it; never scaffold.
#   overlay    — another tool's harness, or substantial work that is not ours.
#   scattered  — AI material exists and nothing organises it. Transform it.
#   greenfield — genuinely nothing. Only then, create.
#
# Usage: ./detect.sh /path/to/target [/another/target ...]
#
# Context rarely arrives as one directory. With several targets, each is
# detected on its own and keeps its own motion for what happens inside it; the
# OVERALL line is the most conservative motion found, for the same reason the
# single-target decision fails closed. Files only: collaboration tools (Slack,
# Notion, ...) are read by the agent through connectors — see scope/context.md.

set -uo pipefail

if [ "$#" -gt 1 ]; then
  overall=greenfield; rank=0; rc=0; n_ok=0
  for t in "$@"; do
    out=$(bash "$0" "$t"); r=$?
    printf '%s\n' "$out"
    [ "$r" -eq 0 ] || { rc=$r; continue; }
    n_ok=$((n_ok + 1))
    m=$(printf '%s\n' "$out" | sed -n 's/^.*MODE: \([a-z]*\).*$/\1/p' | head -1)
    case "$m" in harness) k=3 ;; overlay) k=2 ;; scattered) k=1 ;; *) k=0 ;; esac
    [ "$k" -gt "$rank" ] && { rank=$k; overall=$m; }
  done
  printf 'OVERALL: %s  (%s of %s target(s) examined; most conservative motion wins)\n' "$overall" "$n_ok" "$#"
  printf '  Each target keeps its own motion. Collaboration tools are not visible here — see scope/context.md.\n\n'
  exit "$rc"
fi
TARGET="${1:-.}"
[ -d "$TARGET" ] || { printf 'not a directory: %s\n' "$TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
cd "$TARGET" || exit 1

B=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
[ -t 1 ] || { B=""; DIM=""; RST=""; }

# substantial FILE — has real content, not a stub. Presence is not content.
# `grep -c` prints its count AND exits 1 when that count is zero, so
# `$(grep -c ... || printf 0)` yields "0\n0" and every arithmetic test on it
# errors. This is the FIFTH time this trap has been hit in this codebase — and
# it happened here because detect.sh does not source lib.sh, so the nlines()
# helper written to prevent it was out of reach. A helper only helps where it
# can be reached; this file now carries its own copy.
_n() {
  local n; n=$(grep -cve '^[[:space:]]*$' -- "$1" 2>/dev/null)
  case "${n:-}" in ''|*[!0-9]*) n=0 ;; esac
  printf '%s\n' "$n"
}
substantial() { [ -f "$1" ] && [ "$(_n "$1")" -ge 15 ]; }

found() { printf '  %-34s %s\n' "$1" "$2"; }

printf '\n%sdetect%s %s\n\n' "$B" "$RST" "$TARGET"

# ── instruction files, per host ──────────────────────────────────────────────
INSTR=""; n_instr=0
for f in AGENTS.md CLAUDE.md GEMINI.md .cursorrules .clinerules \
         .cursor/rules .github/copilot-instructions.md .windsurf/rules .codex .agent .agents; do
  [ -e "$f" ] || continue
  n=""
  if [ -f "$f" ]; then n="$(grep -cve '^[[:space:]]*$' -- "$f" 2>/dev/null || printf 0) lines"
  else n="$(find "$f" -type f 2>/dev/null | wc -l | tr -d ' ') files"; fi
  INSTR="$INSTR $f"; n_instr=$((n_instr + 1)); found "$f" "$n"
done
[ "$n_instr" -eq 0 ] && found "(no instruction files)" ""

# ── skills, hooks, MCP ───────────────────────────────────────────────────────
n_skills=0
for d in .claude/skills .agent/skills .agents/skills .cursor/skills skills; do
  [ -d "$d" ] || continue
  c=$(find "$d" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$c" -eq 0 ] && c=$(find "$d" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  n_skills=$((n_skills + c)); found "$d" "$c skill(s)"
done
[ -f .claude/settings.json ] && found ".claude/settings.json" "$(grep -ce 'hooks' -- .claude/settings.json 2>/dev/null || printf 0) hook block(s)"
[ -f .mcp.json ] && found ".mcp.json" "MCP servers declared"

# ── gates already present ────────────────────────────────────────────────────
n_gates=0
[ -d .github/workflows ] && { c=$(find .github/workflows -name '*.y*ml' | wc -l | tr -d ' '); n_gates=$((n_gates+c)); found ".github/workflows" "$c workflow(s)"; }
[ -d .githooks ] && { n_gates=$((n_gates+1)); found ".githooks" "git hooks"; }
[ -f Makefile ] && found "Makefile" "$(grep -ce '^[a-z][a-z0-9-]*:' -- Makefile 2>/dev/null || printf 0) targets"

# ── scattered context: substantial prose nobody organised ────────────────────
n_ctx=0; CTX=""
for f in $(find . -maxdepth 2 -name '*.md' -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null); do
  case "$f" in ./AGENTS.md|./CLAUDE.md|./GEMINI.md) continue ;; esac
  substantial "$f" || continue
  n_ctx=$((n_ctx + 1)); CTX="$CTX $f"
done
[ "$n_ctx" -gt 0 ] && found "substantial .md files" "$n_ctx (potential foundations)"

# ── decision records and judged examples ─────────────────────────────────────
for d in docs/decisions decisions adr docs/adr; do
  [ -d "$d" ] && found "$d" "$(find "$d" -name '*.md' | wc -l | tr -d ' ') decision record(s)"
done
n_corpus=0
for d in examples corpus docs/examples; do
  [ -d "$d" ] && { n_corpus=$((n_corpus + $(find "$d" -type f | wc -l | tr -d ' '))); found "$d" "possible judged examples"; }
done

# ── where this lives: repository, or a plain / synced folder ─────────────────
# A harness for a non-developer team will often live in a shared drive, not a
# repository. That changes what can enforce anything (no commit, no diff), what
# the agent can read (a synced Google Doc is a link, not text) and which setup
# guide applies. Report it; never assume git.
if git -C . rev-parse --git-dir >/dev/null 2>&1; then
  SUBSTRATE="repository"; SYNC=""
else
  SUBSTRATE="workspace"; SYNC="local folder, no sync service recognised"
  case "$TARGET" in
    *"/CloudStorage/GoogleDrive-"*|*"/Google Drive/"*|*"/My Drive"*|*"/Shared drives/"*) SYNC="Google Drive" ;;
    *"/CloudStorage/OneDrive-"*|*"/OneDrive"*|*"/SharePoint"*) SYNC="OneDrive / SharePoint" ;;
    *"/Dropbox"*|*"/CloudStorage/Dropbox"*) SYNC="Dropbox" ;;
    *"/CloudStorage/Box-"*|*"/Box/"*) SYNC="Box" ;;
    *"/Mobile Documents/com~apple~CloudDocs"*) SYNC="iCloud Drive" ;;
  esac
fi
n_short=$(find . -type f \( -name '*.gdoc' -o -name '*.gsheet' -o -name '*.gslides' \) -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
[ "$n_short" -gt 0 ] && { [ "$SUBSTRATE" = "workspace" ] && [ "$SYNC" = "local folder, no sync service recognised" ] && SYNC="Google Drive (from its shortcut files)"; found "Google Docs/Sheets/Slides shortcuts" "$n_short (links, not readable text)"; }

# ── decide, fail closed ──────────────────────────────────────────────────────
if [ -f harness.yaml ]; then
  MODE=harness; WHY="harness.yaml is present — this is already a kit harness"
  NEXT="Run ./scripts/doctor.sh, then the harness-audit skill. Do NOT scaffold."
elif [ "$n_skills" -gt 0 ] || [ -d .codex ] || [ -d .agent ] || [ -d .agents ] || [ -d .cursor/rules ]; then
  MODE=overlay; WHY="another tool's harness is present ($n_skills skill(s) and/or a tool rules directory)"
  NEXT="Read packs/_overlay.md before anything else. Additive only; never modify their tooling."
elif [ "$n_instr" -gt 0 ] || [ "$n_ctx" -gt 0 ] || [ "$n_gates" -gt 0 ]; then
  MODE=scattered; WHY="AI material exists ($n_instr instruction file(s), $n_ctx substantial doc(s), $n_gates gate source(s)) and nothing organises it"
  NEXT="Read packs/_scattered.md. Adopt what is there before creating anything."
else
  MODE=greenfield; WHY="no instruction files, no skills, no substantial docs, no gates"
  NEXT="Run the harness-scope skill. It gathers any other context and recommends whether a harness is required."
fi

printf '\n%sSUBSTRATE: %s%s' "$B" "$SUBSTRATE" "$RST"
if [ "$SUBSTRATE" = "workspace" ]; then
  printf '  %s(%s)%s\n' "$DIM" "$SYNC" "$RST"
  printf '  %sNo git here, so nothing can check at commit. Set substrate: workspace in harness.yaml,\n  and read SUBSTRATES.md and platforms/README.md for checkpoints and connector setup.%s\n' "$DIM" "$RST"
else
  printf '\n'
fi
printf '\n%sMODE: %s%s\n' "$B" "$MODE" "$RST"
printf '  %s\n' "$WHY"
printf '  %s%s%s\n\n' "$DIM" "$NEXT" "$RST"

# The counts are the denominator. A mode decided over nothing examined is a guess.
printf '%sexamined:%s %s instruction file(s) · %s skill(s) · %s gate source(s) · %s substantial doc(s) · %s possible example(s)\n\n' \
  "$DIM" "$RST" "$n_instr" "$n_skills" "$n_gates" "$n_ctx" "$n_corpus"
printf '%s(read only — nothing was written)%s\n\n' "$DIM" "$RST"
