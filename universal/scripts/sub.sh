#!/usr/bin/env bash
# Portable in-place substitution — `sed -i` without the platform trap.
#
#   scripts/sub.sh 's/old/new/' path/to/file
#
# Why this exists. `sed -i EXPR FILE` is GNU-only. BSD/macOS sed takes a
# MANDATORY backup suffix immediately after -i, so it reads EXPR as the suffix
# and then treats FILE as the expression: the command fails, or edits the wrong
# thing. Eighteen call sites in this repo had the GNU form, and the lint that
# was supposed to catch them was written so it skipped exactly that shape.
#
# The fix is not per-platform branching at every call site — that is eighteen
# places to get it wrong again. It is to stop using -i. `sed` to a temp file and
# write the bytes back through the ORIGINAL inode with `cat >`, which is
# portable everywhere and preserves the file's mode, owner and hard links.
# `mv` would not: it would replace the inode and reset the mode to whatever the
# umask gave the temp file, which is how a tree ends up with the 0444 files this
# same release had to fix.
set -uo pipefail

[ $# -eq 2 ] || { printf 'usage: sub.sh <sed-expression> <file>\n' >&2; exit 2; }
expr=$1; file=$2

[ -f "$file" ] || { printf 'sub.sh: not a regular file: %s\n' "$file" >&2; exit 1; }
[ -w "$file" ] || { printf 'sub.sh: not writable: %s\n' "$file" >&2; exit 1; }

tmp="${TMPDIR:-/tmp}/sub.$$.$(basename "$file")"
trap 'rm -f "$tmp"' EXIT

sed "$expr" "$file" > "$tmp" || { printf 'sub.sh: sed failed on %s\n' "$file" >&2; exit 1; }
cat "$tmp" > "$file" || { printf 'sub.sh: could not write back to %s\n' "$file" >&2; exit 1; }
