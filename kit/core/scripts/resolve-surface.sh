#!/usr/bin/env bash
# resolve-surface.sh — every file resolves to exactly one surface, or the run says why not.
#
# THE SINGLE READER of config/surfaces.tsv. doctor.sh asks it about the whole
# tree; scripts/gates/surface-resolution.sh asks it about a change set. That is
# not tidiness: doctor used to carry its own parser of the same table, reading
# only field 1 and globbing with `find -path` while this file globs with `case`
# — and the two disagreed about a pattern naming a directory, which doctor
# scored as covered and this file could never match. Two readers of one table
# eventually disagree, and the disagreement arrives as a green tick.
#
# doctor.sh already proved the FORWARD direction: each declared pattern matches
# at least one file, so no glob is decorative. That said nothing about whether
# every FILE matches a pattern — and it was green while 30 of the 51 files in
# this template belonged to no surface at all, every gate script among them.
#
#     "these lanes are described"  vs  "every change is in a known lane"
#
# The four answers, and they are the contract:
#   exactly one match  — that surface's risk and approval tier
#   zero matches       — high / owner. config/surfaces.tsv's own header says
#                        "Anything unmatched is treated as HIGH. Fail closed."
#                        That sentence had nothing behind it until this file.
#   two or more        — FAIL. Ambiguous. Taking the max risk would silently
#                        resolve a
#                        contradiction in the config: risk has a maximum,
#                        approval does not, and picking between two approval
#                        tiers invents policy inside a config reader.
#   malformed row      — FAIL before resolving anything. A stray tab in a prose
#                        field shifts `risk` into `approval` and classifies on.
#
# And the fifth, which is not an answer about a file at all:
#   no files examined  — reported WITH its denominator. "✓ surfaces resolved"
#                        over an empty set is the shape of every false green in
#                        this kit's study notes. Every branch that can produce
#                        an empty set has to say WHY it is empty.
#
# WHAT THIS DOES NOT DO. Classifying a file high does not stop anything today.
# Nothing consumes the approval tier — approval records are still a gap. So this
# reports, and fails only on ambiguity and malformed config. Saying that here is
# cheaper than someone inferring enforcement from a tick.
#
# Usage:
#   resolve-surface.sh --all              every file the gates see (runs/ excluded)
#   resolve-surface.sh --changed          the changed set; needs git
#   resolve-surface.sh FILE [FILE...]     explicit paths
#   resolve-surface.sh -                  paths on stdin, one per line
#   ... --records                         TSV on stdout instead of the summary
#
# Exit 0 when the config is well-formed and no file is ambiguous. Exit 1 otherwise.
# Unclassified files do not fail the run; they are counted, named, and warned about.

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

# Before anything depends on NUL-delimited enumeration. doctor and the gate both
# reach the resolver, so checking here covers every caller — and a machine that
# cannot do this must say so, not return an empty set and a tick.
assert_runtime || { fail "resolve-surface: this machine cannot run the file enumeration this gate depends on"; exit 1; }

MODE=""; RECORDS=0; ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --all)      MODE=all ;;
    --changed)  MODE=changed ;;
    --records)  RECORDS=1 ;;
    -)          MODE=stdin ;;
    --)         shift; while [ $# -gt 0 ]; do ARGS+=("$1"); shift; done; break ;;
    -*)         fail "resolve-surface: unknown option '$1'"; exit 1 ;;
    *)          ARGS+=("$1") ;;
  esac
  shift
done
[ -n "$MODE" ] || MODE=args
n_args=0; for _a in ${ARGS[@]+"${ARGS[@]}"}; do n_args=$((n_args + 1)); done
[ "$MODE" = "args" ] && [ "$n_args" -eq 0 ] && { fail "resolve-surface: no file set — pass --all, --changed, - , or paths"; exit 1; }

SF=$(cfg surfaces_file config/surfaces.tsv)
[ -s "$SF" ] || { fail "surfaces file '$SF' is missing or empty — nothing is classified, so nothing fails closed"; exit 1; }

# ── 1. Validate the surfaces file BEFORE resolving one file against it ────────
# Resolving against a malformed table produces classifications that look
# authoritative and are not. Order matters here.
PATS=(); RISKS=(); APPRS=(); LINES=()
n_rows=0; n_bad=0; lineno=0
while IFS= read -r raw || [ -n "${raw:-}" ]; do
  lineno=$((lineno + 1))
  raw="${raw%$'\r'}"                                   # a CRLF checkout put \r into `requires`
  case "$raw" in ""|\#*) continue ;; esac
  # Six fields read from five: `extra` is non-empty only when a stray tab split
  # a prose field. That is the malformed row this catches.
  IFS=$'\t' read -r pat risk appr why req extra <<< "$raw"
  n_rows=$((n_rows + 1))
  if [ -n "${extra:-}" ]; then
    fail "$SF line $lineno: more than 5 tab-separated fields — a tab inside the prose shifts every field after it"
    n_bad=$((n_bad + 1)); continue
  fi
  if [ -z "${pat:-}" ] || [ -z "${risk:-}" ] || [ -z "${appr:-}" ] || [ -z "${why:-}" ] || [ -z "${req:-}" ]; then
    fail "$SF line $lineno: needs 5 tab-separated fields (pattern, risk, approval, why, requires)"
    n_bad=$((n_bad + 1)); continue
  fi
  case "$risk" in
    low|medium|high) ;;
    *) fail "$SF line $lineno: risk must be low, medium or high — got '$risk'"; n_bad=$((n_bad + 1)); continue ;;
  esac
  # A CLOSED vocabulary, deliberately. An open one means a typo'd approver reads
  # as a new tier nobody has to be, which is the quietest way to lose a review.
  case "$appr" in
    owner|reviewer|none) ;;
    *) fail "$SF line $lineno: approval must be owner, reviewer or none — got '$appr'"; n_bad=$((n_bad + 1)); continue ;;
  esac
  case "$pat" in
    /*)        fail "$SF line $lineno: pattern '$pat' is absolute — patterns are harness-relative"; n_bad=$((n_bad + 1)); continue ;;
    *..*)      fail "$SF line $lineno: pattern '$pat' escapes the harness with '..'"; n_bad=$((n_bad + 1)); continue ;;
    *\\*)      fail "$SF line $lineno: pattern '$pat' contains a backslash — patterns are globs, not regexes"; n_bad=$((n_bad + 1)); continue ;;
    *' '*)     fail "$SF line $lineno: pattern '$pat' contains a space — the field separator is a tab"; n_bad=$((n_bad + 1)); continue ;;
    ./*)       fail "$SF line $lineno: pattern '$pat' starts with './' — paths are compared without it"; n_bad=$((n_bad + 1)); continue ;;
  esac
  dup=0
  for existing in ${PATS[@]+"${PATS[@]}"}; do
    [ "$existing" = "$pat" ] && { dup=1; break; }
  done
  if [ "$dup" = 1 ]; then
    fail "$SF line $lineno: pattern '$pat' is declared twice — the second row can never be the one that applies"
    n_bad=$((n_bad + 1)); continue
  fi
  PATS+=("$pat"); RISKS+=("$risk"); APPRS+=("$appr"); LINES+=("$lineno")
done < "$SF"

[ "$n_rows" -eq 0 ] && { fail "'$SF' declares no surfaces"; exit 1; }
[ "$n_bad" -gt 0 ] && { fail "$SF: $n_bad malformed row(s) of $n_rows — refusing to classify against a broken table"; exit 1; }

# ── 1b. Nesting overlap, found at write time rather than at detonation time ───
# Per-file ambiguity (section 3) only fires once somebody creates a file in the
# overlap — which means the config author writes `zzC/*` and `zzC/never/*`, sees
# every gate go green, and the failure lands months later on whoever first adds
# a file under zzC/never/. That is the person who did not write the config.
#
# HONEST SCOPE: this catches NESTING — one pattern matching the other as a
# literal string, which is the shape of every fallback-plus-override anyone
# actually writes. It is not a decision procedure for glob intersection:
# `zzB/?.md` and `zzB/[ab].md` overlap without either matching the other, and
# only the per-file check will catch that pair. The backstop stays.
n_over=0; i=0
while [ "$i" -lt "${#PATS[@]}" ]; do
  j=$((i + 1))
  while [ "$j" -lt "${#PATS[@]}" ]; do
    a="${PATS[$i]}"; b="${PATS[$j]}"; ov=0
    # SELF-MATCH GUARD. The evidence here is "pattern b, read as a literal
    # filename, matches pattern a" — which is only evidence of anything if b is
    # a filename a could ever see. `runs/[!0-9]*` is not: its literal text
    # begins with `[`, which `runs/[0-9]*` happily matches, so two provably
    # disjoint patterns (a character is a digit or it is not) were rejected with
    # a message asserting something false, and no override existed.
    case "$b" in $b) case "$b" in $a) ov=1 ;; esac ;; esac
    case "$a" in $a) case "$a" in $b) ov=1 ;; esac ;; esac
    if [ "$ov" = 1 ]; then
      fail "$SF: '$a' (line ${LINES[$i]}) and '$b' (line ${LINES[$j]}) overlap — patterns must be disjoint"
      fail "  Approval tiers have no maximum, so a file matching both has no defensible lane."
      n_over=$((n_over + 1))
    fi
    j=$((j + 1))
  done
  i=$((i + 1))
done
[ "$n_over" -gt 0 ] && { fail "$SF: $n_over overlapping pattern pair(s) — a fallback with narrow overrides is not expressible here"; exit 1; }

# ── 2. Assemble the file set, NUL-delimited ──────────────────────────────────
# NUL because a path is not a line. Each branch must be able to say "nothing",
# and say it with a reason: a set empty for a structural reason (no git) is not
# the same finding as a set empty because nothing changed, and one tick cannot
# honestly mean both.
FSET=(); SET_NOTE=""

# norm PATH — one spelling per file. `${f#./}` strips ONE prefix, so `x`,
# `./x`, `././x` and `.//x` were four different answers for the same file — and
# `.//x` was reported as ABSOLUTE, a wrong diagnosis on top of a wrong answer.
# Collapse duplicate slashes first, then strip every leading './'.
norm() {
  local f="$1"
  while [ "$f" != "${f//\/\///}" ]; do f="${f//\/\///}"; done
  while [ "$f" != "${f#./}" ]; do f="${f#./}"; done
  printf '%s' "$f"
}

case "$MODE" in
  all)
    # all_files0, NOT repo_files0: runs/ is a declared surface, so excluding it
    # made runs/* a pattern matching nothing while its files went unexamined.
    # The set being classified must be the set that can change.
    while IFS= read -r -d '' f; do FSET+=("$(norm "$f")"); done < <(all_files0 ".")
    SET_NOTE="whole tree"
    ;;
  args|stdin)
    if [ "$MODE" = "stdin" ]; then
      ARGS=(); while IFS= read -r f; do [ -n "$f" ] && ARGS+=("$f"); done
      SET_NOTE="paths on stdin"
    else
      SET_NOTE="explicit paths"
    fi
    for f in ${ARGS[@]+"${ARGS[@]}"}; do
      f=$(norm "$f")
      case "$f" in
        /*)   fail "resolve-surface: '$f' is absolute — paths are harness-relative"; exit 1 ;;
        *..*) fail "resolve-surface: '$f' escapes the harness with '..'"; exit 1 ;;
      esac
      # A directory is not a file, and giving one a lane is a category error —
      # `scripts/gates` used to resolve to scripts/*'s risk and approval.
      [ -d "$f" ] && { fail "resolve-surface: '$f' is a directory — pass files, or use --all"; exit 1; }
      FSET+=("$f")
    done
    ;;
  changed)
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      # Not a hedge, and not a free pass either: on a workspace substrate there
      # is no diff to resolve, but `substrate: repository` with no git is a
      # harness whose change-set check can never run — which is exactly the
      # "gate that never fires" this kit exists to catch. Template mode is
      # exempt because nothing has been set up yet.
      if [ "$(cfg substrate workspace)" = "repository" ] && [ "$(cfg mode template)" = "instance" ]; then
        fail "substrate is 'repository' but this is not a git repository — the change-set check can never run here"
        fail "  Either 'git init', or set substrate: workspace in harness.yaml."
        finish
      fi
      pass "surfaces not resolved against a change set" "no git; substrate=$(cfg substrate workspace), mode=$(cfg mode template)"
      finish
    fi
    BASE=$(cfg main_branch main)
    RANGE="$BASE"
    git rev-parse --verify -q "$BASE" >/dev/null 2>&1 || RANGE="HEAD"
    # `git diff` speaks REPOSITORY-relative paths; every pattern here speaks
    # HARNESS-relative ones. With the harness in a subdirectory of a larger
    # repo the two never matched, every diffed path failed the existence test,
    # and the gate reported green over 2 of 31 changed files — in the very
    # repository this kit is developed in.
    PFX=$(git rev-parse --show-prefix 2>/dev/null)
    # -c core.quotepath=false and -z: without them git C-quotes any non-ASCII
    # path ("zzw/na\303\257ve.md"), which then matches no file and vanishes from
    # the denominator. quotepath is per-clone, so this failed on one machine and
    # passed on another.
    G="git -c core.quotepath=false"
    while IFS= read -r -d '' f; do
      case "$f" in "$PFX"*) f="${f#"$PFX"}" ;; *) continue ;; esac  # outside the harness
      f=$(norm "$f")
      # A deleted file has no surface to land on; classifying it reports a lane
      # for something that is not there.
      [ -n "$f" ] && [ -e "$f" ] && FSET+=("$f")
    done < <( { $G diff -z --name-only "$RANGE"...HEAD 2>/dev/null
                $G diff -z --name-only 2>/dev/null
                $G diff -z --cached --name-only 2>/dev/null
                # NO --full-name. `git diff` speaks repo-root-relative paths and
                # needs the $PFX strip below; `ls-files --others` speaks
                # cwd-relative ones and needs the $PFX prefix. --full-name makes
                # it repo-relative too, so it got BOTH — prefixed here and
                # stripped below into a path that exists nowhere, and every
                # untracked file dropped out of the change set under a green
                # tick. New files are what a change-set gate is for.
                $G ls-files -z --others --exclude-standard 2>/dev/null \
                  | while IFS= read -r -d '' o; do printf '%s\0' "$PFX$o"; done
              } | sort -zu )
    SET_NOTE="changed against $RANGE${PFX:+, harness at $PFX}"
    ;;
esac

# Counted by iteration, not `${#FSET[@]}`. macOS ships bash 3.2, this set is
# empty on every no-change run, and an unbound-variable error there is fatal —
# a risk not worth carrying for a character count when the guarded form is free.
n_files=0; for _f in ${FSET[@]+"${FSET[@]}"}; do n_files=$((n_files + 1)); done

# ── 3. Resolve ───────────────────────────────────────────────────────────────
# `case` glob semantics: `*` crosses `/`, so foundations/* covers
# foundations/a/b.md. `|` inside an expanded pattern is a literal — case
# alternation is parsed before expansion — so a pattern cannot inject one.
n_low=0; n_med=0; n_high=0; n_uncl=0; n_amb=0
UNCL=(); MATCHED_ANY=()
i=0; while [ "$i" -lt "${#PATS[@]}" ]; do MATCHED_ANY[$i]=0; i=$((i + 1)); done

for f in ${FSET[@]+"${FSET[@]}"}; do
  # A newline in a path is now classified CORRECTLY — the set is NUL-delimited —
  # but --records is line-based, so such a path splits its own record and
  # forges a second one. check-kit.sh parses those records with `cut -f4`, and a
  # file named "x<newline>foundations/y.md" would hand it a fabricated row.
  # Refuse the path rather than emit a record no parser can trust.
  case "$f" in
    *$'\n'*|*$'\t'*)
      fail "path contains a newline or tab: $(printf '%q' "$f") — no line-based record can represent it"
      n_amb=$((n_amb + 1)); continue ;;
  esac
  hits=0; hit_risk=""; hit_appr=""; hit_pat=""; all_hits=""
  i=0
  while [ "$i" -lt "${#PATS[@]}" ]; do
    p="${PATS[$i]}"
    case "$f" in
      $p) hits=$((hits + 1)); hit_pat="$p"; hit_risk="${RISKS[$i]}"; hit_appr="${APPRS[$i]}"
          MATCHED_ANY[$i]=1
          all_hits="${all_hits:+$all_hits, }$p" ;;
    esac
    i=$((i + 1))
  done
  if [ "$hits" -gt 1 ]; then
    n_amb=$((n_amb + 1))
    fail "ambiguous: $f matches $hits surfaces ($all_hits) — one file, one lane"
    [ "$RECORDS" = 1 ] && printf '%s\tAMBIGUOUS\tAMBIGUOUS\t%s\n' "$f" "$all_hits"
  elif [ "$hits" -eq 1 ]; then
    case "$hit_risk" in low) n_low=$((n_low + 1)) ;; medium) n_med=$((n_med + 1)) ;; high) n_high=$((n_high + 1)) ;; esac
    [ "$RECORDS" = 1 ] && printf '%s\t%s\t%s\t%s\n' "$f" "$hit_risk" "$hit_appr" "$hit_pat"
  else
    n_uncl=$((n_uncl + 1)); UNCL+=("$f")
    [ "$RECORDS" = 1 ] && printf '%s\thigh\towner\t(unclassified)\n' "$f"
  fi
done

# ── 3b. Forward direction, only meaningful over the whole tree ───────────────
# A glob matching nothing is a lane nobody can be in — the commonest way a
# harness looks installed and is not. doctor used to check this with a second
# parser of its own; it asks here now, so one reader answers both questions.
n_dead=0
if [ "$MODE" = "all" ]; then
  i=0
  while [ "$i" -lt "${#PATS[@]}" ]; do
    if [ "${MATCHED_ANY[$i]}" = 0 ]; then
      fail "surface pattern matches no file: ${PATS[$i]} (line ${LINES[$i]})"
      n_dead=$((n_dead + 1))
    fi
    i=$((i + 1))
  done
fi

# ── 4. Report, always with the denominator ───────────────────────────────────
if [ "$RECORDS" = 0 ]; then
  if [ "$n_files" -eq 0 ]; then
    pass "no files to resolve" "0 examined; $n_rows surface(s) declared; $SET_NOTE"
    finish
  fi
  if [ "$n_uncl" -gt 0 ]; then
    warn "$n_uncl of $n_files file(s) match no declared surface — treated as high/owner, by default rather than by decision:"
    n=0; for u in ${UNCL[@]+"${UNCL[@]}"}; do
      n=$((n + 1)); [ "$n" -gt 20 ] && break
      printf '      %s\n' "$u" >&2
    done
    [ "$n_uncl" -gt 20 ] && printf '      … and %s more\n' "$((n_uncl - 20))" >&2
    warn "  Classify them in $SF, or accept high as the answer and say so in a row."
  fi
  [ "$n_amb" -eq 0 ] && [ "$n_dead" -eq 0 ] && pass "every file resolves to at most one surface" \
    "$n_files examined, $n_rows surfaces: ${n_high} high, ${n_med} medium, ${n_low} low, ${n_uncl} unclassified→high; $SET_NOTE"
fi

finish
