#!/usr/bin/env bash
# Community health files — for public repositories only.
#
# GitHub's community profile looks for seven things in a public repository:
# README, LICENSE, CODE_OF_CONDUCT, CONTRIBUTING, SECURITY, issue templates and
# a pull request template. They are easy to leave off, and their absence is
# what an outside contributor meets first: no licence means no permission to
# use the code at all, and no security policy means a vulnerability report
# arrives as a public issue.
#
# What this proves: each of the seven is present in a place GitHub reads (the
# root, docs/ or .github/), and none still carries a {{PLACEHOLDER}} from the
# harness's templates or is still the harness's own README.
# What it CANNOT prove: that the contents are right — that the contact address
# is monitored, that the licence is the one the owner meant, or that private
# vulnerability reporting is switched on in the repository settings.
#
# Silent unless project.visibility is public. A private repository — most
# client work — sees no output and no change in exit status.
#
# Advisory by default: project.community_files is warn (report, exit 0). Set it
# to error to make it a gate, or off to silence it on a public repository.
#
# reader of: project.visibility, project.community_files
. "$(dirname "$0")/../lib.sh"

VIS=$(cfg project.visibility private)
case "$VIS" in
  private) exit 0 ;;
  public) ;;
  *) fail "harness.config.yaml: project.visibility is '$VIS'. Use public or private." ;;
esac

POLICY=$(policy project.community_files warn)
[ "$POLICY" != off ] || exit 0

PLACEHOLDER_RE='\{\{[A-Z][A-Z0-9_]*\}\}'
checked=0; problems=0
report=""
line() { report="$report
$1"; }

for kind in $COMMUNITY_KINDS; do
  checked=$((checked + 1))
  label=$(community_label "$kind")
  path=$(community_locate "$kind")
  if [ -z "$path" ]; then
    problems=$((problems + 1))
    line "  ! $(printf '%-16s' "$label") missing"
    continue
  fi
  # A directory (issue templates, a PR template folder) is checked file by file.
  if [ -d "$HARNESS_ROOT/$path" ]; then
    left=$( cd "$HARNESS_ROOT" && find "$path" -maxdepth 1 -type f -print0 \
              | xargs -0 grep -l -E -e "$PLACEHOLDER_RE" -- 2>/dev/null | LC_ALL=C sort | tr '\n' ' ' ) || true
  else
    left=$(sgrep -o -E -e "$PLACEHOLDER_RE" -- "$HARNESS_ROOT/$path" | LC_ALL=C sort -u | tr '\n' ' ')
  fi
  if [ -n "$left" ]; then
    problems=$((problems + 1))
    line "  ! $(printf '%-16s' "$label") $path still has placeholders: ${left% }"
    continue
  fi
  # install.sh writes the harness's own README into a project that had none.
  if [ "$kind" = readme ] && [ "$(head -1 "$HARNESS_ROOT/$path" 2>/dev/null)" = "# Universal Harness" ]; then
    problems=$((problems + 1))
    line "  ! $(printf '%-16s' "$label") $path is still the harness's own README, not this project's"
    continue
  fi
  line "  ✓ $(printf '%-16s' "$label") $path"
done

if [ "$problems" -eq 0 ]; then
  ok "community files (public repository): checked $checked, all present$report"
  exit 0
fi

msg="community files (public repository): checked $checked, $problems missing or unfinished$report
    Run the harness-community-files skill to scaffold the missing ones; it asks
    for every value and never invents a licence or a contact address."
if [ "$POLICY" = error ]; then
  fail "$msg"
fi
warn "$msg"
exit 0
