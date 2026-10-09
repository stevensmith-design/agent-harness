#!/usr/bin/env bash
# dead-config.sh — the gate that catches machinery pointing at nothing.
#
# This is the most common defect class in harnesses. It looks like: a config
# block read by zero lines of code; a tokens path set by an installer with no
# skill that creates a token layer; a PRD referenced by four files and owned
# by nothing; a checklist referenced by nothing at all.
#
# Adversarial review does not catch it. Review is excellent at "does this code
# do what it says" and blind to "is there any code here at all".
#
# Three checks:
#   1. CONFIG   — every key in harness.yaml is read by something
#   2. TARGETS  — every path referenced in the harness exists
#   3. ORPHANS  — every harness file is referenced by something
#
# Written for bash 3.2 (macOS ships it). No mapfile, no associative arrays.

# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"

ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

# Files that make claims: the config, and every markdown in the harness.
# IFS=newline throughout: word-splitting on unquoted $DOCS skipped every file
# whose name contains a space, while the denominator still counted it — a count
# reported over a different set than was examined.
IFS=$(printf '\n\b'); IFS=${IFS%?}
DOCS=$(repo_files "." | grep -e '\.md$' -- || true)
SCRIPTS=$(repo_files "." | grep -e '\.\(sh\|py\|js\|mjs\|ts\)$' -- || true)
SEARCHABLE=$(printf '%s\n%s\n' "$DOCS" "$SCRIPTS" | grep -e . -- || true)

# ── 1. CONFIG ────────────────────────────────────────────────────────────────
# Every key in harness.yaml must be named by a script or a doc. A key nothing
# reads looks like enforcement to anyone skimming, which is worse than absent.

CONFIG_KEYS=$(sed -n 's/^[[:space:]]*\([a-z_][a-z0-9_]*\):.*/\1/p' harness.yaml 2>/dev/null | sort -u)
n_keys=0; dead_keys=""
for k in $CONFIG_KEYS; do
  n_keys=$((n_keys + 1))
  # Read by a script, or explained by a doc that is not harness.yaml itself.
  if printf '%s\n' "$SEARCHABLE" | while read -r f; do
       [ -n "$f" ] || continue
       case "$f" in ./harness.yaml) continue ;; esac
       grep -qle "$k" -- "$f" 2>/dev/null && { printf 'hit'; break; }
     done | grep -qe hit --; then
    :
  else
    dead_keys="$dead_keys $k"
  fi
done

if [ -n "$dead_keys" ]; then
  for k in $dead_keys; do
    fail "config key '$k' is read by nothing. Teach a script to read it in the same change, or delete it."
  done
else
  pass "config keys have a reader" "$n_keys keys"
fi

# ── 2. TARGETS ───────────────────────────────────────────────────────────────
# Every relative path the harness names must exist. A rule pointing at a
# missing file is a rule that silently never applies.

n_refs=0
MISS=$(mktemp 2>/dev/null) || MISS=""
[ -n "$MISS" ] && [ -w "$MISS" ] || fail "cannot create a temp file — refusing to report a result"
: > "$MISS"
for f in $DOCS; do
  [ -f "$f" ] || continue
  d=$(dirname "$f")
  # Markdown links (path.md) and backticked paths — relative, no protocol.
  refs=$( { grep -oe '](\.\{0,2\}/\{0,1\}[A-Za-z0-9_./-]*)' -- "$f" 2>/dev/null | sed 's/^](//;s/)$//'
            grep -oe '`[A-Za-z0-9_-]\{1,\}/[A-Za-z0-9_./-]*`' -- "$f" 2>/dev/null | tr -d '`'; } )
  for r in $refs; do
    case "$r" in
      ""|http*|"#"*|*"{{"*|*"<"*|*"*"*) continue ;;
    esac
    n_refs=$((n_refs + 1))
    if [ ! -e "$d/$r" ] && [ ! -e "./$r" ]; then
      printf '%s -> %s\n' "$f" "$r" >> "$MISS"
    fi
  done
done

n_miss=$(nlines "$MISS")
if [ "$n_miss" -gt 0 ]; then
  # Not a pipeline: a `while read` in a pipe runs in a subshell, and a fail()
  # there — or a final line with no trailing newline — is lost silently. That
  # is the exact defect class this gate exists to catch.
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] && fail "broken reference: $line"
  done < "$MISS"
else
  pass "references resolve" "$n_refs refs in $(printf '%s\n' "$DOCS" | nlines) docs"
fi
rm -f "$MISS"

# ── 3. ORPHANS ───────────────────────────────────────────────────────────────
# A doc nothing points at is dead weight — and agents may still read and obey
# it. Entry points are exempt: they are the roots of the citation graph.

ENTRY='^\./\(README\.md\|AGENTS\.md\|CLAUDE\.md\|ANATOMY\.md\|PRINCIPLES\.md\|LADDER\.md\|SUBSTRATES\.md\|harness\.yaml\)$'
# Append-only RECORDS are not documents in a citation graph. A judged example, a
# dated review and an ADR are each written once and never pointed at
# individually — their directory is what gets cited. Requiring an inbound edge
# made every artifact the harness produces fail this gate at the moment of
# creation, which meant the first real piece of work through a harness turned
# it red. That is the step the kit says never to skip.
RECORDS='^\./\(learning/corpus/\|learning/reviews/\|learning/journal/\|decisions/\|runs/\|memory/\)'
n_docs=0; orphans=""
for f in $DOCS; do
  [ -f "$f" ] || continue
  printf '%s\n' "$f" | grep -qe "$ENTRY" -- && continue
  printf '%s\n' "$f" | grep -qe "$RECORDS" -- && continue
  n_docs=$((n_docs + 1))
  base=$(basename "$f")
  # Referenced by any OTHER file?
  if printf '%s\n' "$SEARCHABLE" | while read -r g; do
       [ -n "$g" ] && [ "$g" != "$f" ] || continue
       grep -qle "$base" -- "$g" 2>/dev/null && { printf 'hit'; break; }
     done | grep -qe hit --; then
    :
  else
    # Newline-separated, never space-separated: people name files "Old Meeting
    # Notes.md", and sync tools write conflict copies as "AGENTS (1).md". A
    # space-joined list reported one such file as three orphans that don't exist.
    orphans="$orphans
$f"
  fi
done

n_orph=$(printf '%s\n' "$orphans" | grep -ce . -- || true)
case "${n_orph:-}" in ''|*[!0-9]*) n_orph=0 ;; esac
if [ "$n_orph" -gt 0 ]; then
  for o in $(printf '%s\n' "$orphans" | grep -e . --); do
    fail "orphan: $o is referenced by nothing — cite it from the instruction map in the constitution, or delete it."
  done
else
  pass "citation graph" "$n_docs non-entry docs, 0 orphaned"
fi

finish
