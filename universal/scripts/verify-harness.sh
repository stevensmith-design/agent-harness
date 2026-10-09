#!/usr/bin/env bash
# Is the harness itself intact? Three levels, each a superset of the last.
#   --level 1  structure   — the instruction graph exists and is wired
#   --level 2  enforcement — gates, hooks and CI are present and runnable
#   --level 3  governance  — L3 records validate; evidence trail exists
# Output doubles as GitHub Actions annotations when GITHUB_ACTIONS=true.
. "$(dirname "$0")/lib.sh"

LEVEL=1
PORTABILITY_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --level) LEVEL="$2"; shift 2;;
    # Just the harness's own code hygiene — no structure ladder, no config
    # grading. Cheap enough for `make check`, valid on an uninitialised tree.
    --portability) PORTABILITY_ONLY=1; shift;;
    --level=*) LEVEL="${1#*=}"; shift;;
    *) shift;;
  esac
done

RC=0
STUBS=0
note() {  # note <ok|stub|fail> <message>
  case "$1" in
    ok)   ok "$2" ;;
    # A stub is not a failure — a freshly installed harness is ALL stubs, and
    # failing there would make the first run red for a reason the user cannot
    # yet fix. It is counted and reported, so "installed" and "configured" stop
    # looking identical.
    stub) STUBS=$((STUBS+1)); info "$2" ;;
    *)    RC=1
          if [ "${GITHUB_ACTIONS:-}" = "true" ]; then echo "::error::$2"; else warn "$2"; fi ;;
  esac
}
# Presence is not a boolean — but only for the files that have a
# template -> configured lifecycle. A path that exists tells you the template
# was unpacked, not that anyone filled it in, and reporting a plain tick for an
# unfilled register is how a harness looks installed and is not.
#
#   missing    the path is not there
#   stub       there, but still the shipped template
#   populated  someone has put real content in it
#
# Only those three are mechanically decidable. A fourth — `stale`, meaning
# populated but no longer true — is a review judgement. Pretending a timestamp
# could detect it would be exactly the decorative check this harness keeps
# finding, so it is named in the guide and left to a human.
#
# Scope matters: most of the harness ships COMPLETE. A skill or the Makefile
# containing `<name>` is documentation, not an unfilled blank. Grading those
# produced nine false stubs on a correct tree, so the ladder applies only to the
# artefacts listed in has_configured() below.
grade() {
  local f="$HARNESS_ROOT/$1"
  [ -e "$f" ] || { printf 'missing'; return; }
  [ -f "$f" ] || { printf 'populated'; return; }
  # An unfilled angle-bracket placeholder of the shape harness-init replaces.
  # Any unfilled angle-bracket blank: <product>, <name>, and prose blanks like
  # "<one sentence, product language, no mechanism>". Excludes real HTML tags and
  # comparison operators, which is why the first character must be a letter and
  # the run must not contain a slash or an equals sign.
  if grep -qE '<[A-Za-z][^<>/=]{1,60}>' "$f" 2>/dev/null; then printf 'stub'; return; fi
  # A markdown table with a header and a separator but no data rows.
  if grep -qE '^\|[[:space:]]*:?-+' "$f" 2>/dev/null; then
    local rows; rows=$(scount -E -e '^\|' -- "$f")
    [ "${rows:-0}" -le 2 ] && { printf 'stub'; return; }
  fi
  printf 'populated'
}

has()  { [ -e "$HARNESS_ROOT/$1" ] && note ok "$1" || note fail "missing: $1"; }
exec_ok() { [ -x "$HARNESS_ROOT/$1" ] && note ok "$1 executable" || note fail "not executable: $1"; }

# For the artefacts a project is supposed to fill in.
has_configured() {
  local g; g=$(grade "$1")
  case "$g" in
    populated) note ok "$1" ;;
    stub)      note stub "$1 — present but still the shipped template" ;;
    missing)   note fail "missing: $1" ;;
  esac
}

# --- Portability and hygiene -------------------------------------------------
#
# Checks on the HARNESS'S OWN CODE: BSD-safe sed and grep, bash-pinned shebangs,
# no authority taken from the environment, sane file modes. Unlike the structure
# ladder below, none of them depend on whether a project has been initialised,
# so they are valid on any tree from the first minute.
#
# They lived inside `--level 2`, which runs in CI and in `make verify-harness`
# but NOT in `make check`. So the person most likely to trip them — someone who
# just installed the harness and is about to edit a gate — was the one person
# who never saw them. `--portability` runs this and nothing else, and `make
# check` calls it.
portability_checks() {
  # Portability lint. `grep PATTERN -- FILE` puts the end-of-options marker
  # AFTER an operand: GNU grep permutes arguments and tolerates it, BSD grep
  # (macOS) reads `--` as a filename and exits 2. That turned the fail-closed
  # helper into a fail-OPEN one on every Mac. Use `-e PATTERN --` instead.
  badgrep=$(awk '
    FILENAME ~ /verify-harness\.sh$/ { next }
    /(^|[^A-Za-z_])(grep|sgrep|scount)[[:space:]]/ {
      line=$0
      # find a quoted pattern immediately followed by whitespace and "--"
      n=split(line, ch, "")
      for (i=1; i<=n; i++) {
        q=ch[i]
        if (q != "\"" && q != "'"'"'") continue
        j=i+1; while (j<=n && ch[j]!=q) j++
        if (j>n) break
        k=j+1; while (k<=n && ch[k]==" ") k++
        if (!(ch[k]=="-" && ch[k+1]=="-")) { i=j; continue }
        # the correct form is  -e PATTERN --  : look for "-e " just before the quote
        if (i>=4 && ch[i-1]==" " && ch[i-2]=="e" && ch[i-3]=="-") { i=j; continue }
        printf "%s:%d:%s\n", FILENAME, FNR, line
        break
      }
    }
  ' "$HARNESS_ROOT"/scripts/*.sh "$HARNESS_ROOT"/scripts/gates/*.sh "$HARNESS_ROOT"/scripts/adapters/*.sh 2>/dev/null || true)

  # GNU-only commands macOS does not ship. Caught by hand once (md5sum, added in
  # v1.9.1 and removed the same hour) — a lint is the only fix that survives.
  gnuonly=$(grep -rnE '(^|[^A-Za-z_.-])(md5sum|sha[0-9]+sum|readlink -f|realpath|date -[dr] |stat -c|find [^|]* -printf|xargs -r|mapfile|readarray|grep -P)' \
              "$HARNESS_ROOT"/scripts/*.sh "$HARNESS_ROOT"/scripts/gates/*.sh "$HARNESS_ROOT"/scripts/adapters/*.sh 2>/dev/null \
            | grep -v 'verify-harness.sh' \
            | grep -vE ':[0-9]+:[[:space:]]*#' || true)
  if [ -n "$gnuonly" ]; then
    note fail "GNU-only command (absent or different on macOS):"
    printf '%s\n' "$gnuonly" | sed 's/^/      /' >&2
  else
    note ok "no GNU-only coreutils in scripts"
  fi

  # `sed -i EXPR FILE` is GNU-only. BSD/macOS sed takes a MANDATORY backup
  # suffix immediately after -i, so it reads EXPR as the suffix and then treats
  # FILE as the expression: the command fails, or rewrites the wrong thing.
  #
  # This used to be one clause inside the alternation above: `sed -i +[^.'"]`.
  # It EXCLUDED a following quote — which is to say it skipped
  # `sed -i 's/a/b/'`, the exact form it existed to catch, and could only ever
  # have fired on an unquoted expression nobody writes. A lint that cannot fail
  # on the defect it names is the decorative machinery this harness hunts, so it
  # is now its own check, with a self-test in both directions.
  #
  # Safe: `sed -i '' EXPR F` (BSD), `sed -i.bak EXPR F && rm -f F.bak`, or
  # `scripts/sub.sh EXPR F`, which uses no -i at all and preserves the mode.
  #
  # Second clause: a `\n` in an s/// REPLACEMENT is also GNU-only — BSD sed
  # emits a literal `n`. That one is worse than -i, because it does not fail:
  # it silently writes the wrong bytes and every check downstream then measures
  # the wrong tree. Found once here, hidden behind an otherwise-portable
  # `sed -i.bak`, which is why it survived four reviews.
  #
  # This file is scanned like every other: there is no exclusion and no escape
  # marker. An earlier draft had one, honoured only here, and it ended up with
  # exactly one user — a diagnostic message that happened to quote the shape.
  # Rewording the message removed the need, and an exclusion mechanism with one
  # user is the machinery-pointing-at-nothing pattern this harness exists to
  # catch. The lint now lints itself.
  # A single awk pass over the same file set as the grep lint above. It runs on
  # file CONTENT, keyed by FILENAME/FNR — an earlier draft piped `grep -rn`
  # output into a second grep, and the repository's own absolute path (which
  # contains `s/` in "sessions/" and "scripts/") matched the pattern, so every
  # file in the tree was reported. A lint whose first version flagged 24 clean
  # lines is a lint people turn off.
  badsed=$(awk '
    /^[[:space:]]*#/ { next }
    /(^|[^A-Za-z_.-])sed[[:space:]]+-i/ {
      # safe: -i.suffix, or -i followed by an empty '"'"''"'"' / "" argument
      if ($0 !~ /sed[[:space:]]+-i\.[A-Za-z0-9]+/ && $0 !~ /sed[[:space:]]+-i[[:space:]]+('"'"''"'"'|"")/) {
        printf "%s:%d: GNU-only in-place sed (BSD needs a backup suffix after -i):%s\n", FILENAME, FNR, $0
        next
      }
    }
    /(^|[^A-Za-z_.-])sed[[:space:]]/ {
      # a \n in an s/// REPLACEMENT. Escaped delimiters count as one character,
      # or `src\/theme\n` would slip past the character class and the one real
      # instance in this repo would go unreported.
      if ($0 ~ /s\/([^\/\\]|\\.)*\/([^\/\\]|\\.)*\\n/ ||
          $0 ~ /s\|([^|\\]|\\.)*\|([^|\\]|\\.)*\\n/ ||
          $0 ~ /s#([^#\\]|\\.)*#([^#\\]|\\.)*\\n/) {
        printf "%s:%d: GNU-only  \\n in an s/// replacement (BSD sed emits a literal n):%s\n", FILENAME, FNR, $0
      }
    }
  ' "$HARNESS_ROOT"/scripts/*.sh "$HARNESS_ROOT"/scripts/gates/*.sh "$HARNESS_ROOT"/scripts/adapters/*.sh 2>/dev/null || true)
  # Production scars — failure modes a generic framework does not anticipate but
  # a shipped harness hits. Both were clean when these were written; the lints
  # exist so they stay clean, because "we fixed it once" is not a check.
  #
  # SCAR 1 — the ambient shell is not necessarily bash. A user's login shell may
  # be zsh, and zsh differs on the two constructs this codebase leans on hardest:
  # unmatched globs (zsh errors instead of passing the pattern through) and
  # `[[ ]]` word-splitting. Every script here declares a bash shebang so the
  # ambient shell never decides. A hook is the dangerous one: it is invoked by
  # git or by an agent runtime, not by us, so its shebang is the ONLY thing
  # standing between this code and whatever shell happens to be in front of it.
  noshebang=""
  for f in $(git -C "$HARNESS_ROOT" ls-files '*.sh' 2>/dev/null) \
           $(git -C "$HARNESS_ROOT" ls-files '.githooks/*' '.claude/hooks/*' 2>/dev/null); do
    [ -f "$HARNESS_ROOT/$f" ] || continue
    case "$f" in *.md|*.json|*.yml|*.yaml) continue ;; esac
    head -1 "$HARNESS_ROOT/$f" | grep -q '^#!.*bash' \
      || noshebang="$noshebang
      $f — first line is: $(head -1 "$HARNESS_ROOT/$f")"
  done
  if [ -n "$noshebang" ]; then
    note fail "scripts and hooks must declare a bash shebang (the ambient shell may be zsh):"
    printf '%s\n' "$noshebang" | grep -v '^$' >&2
  else
    note ok "every script and hook pins bash (zsh cannot change their meaning)"
  fi

  # SCAR 2 — authority must not come from the environment. Two failures wear the
  # same shape.
  #
  # An exported variable does not survive separate tool calls, so a check whose
  # authority lives in one silently measures nothing the moment it runs in a new
  # shell — and it measures nothing SILENTLY, which is the worst kind.
  #
  # Worse, when it does survive, it survives too well. HARNESS_HUMAN_APPROVED=1
  # and HARNESS_ALLOW_SELF_EDIT=1 were exactly this: exported once into a shell
  # profile or a CI job, they approved every subsequent change including the ones
  # nobody looked at. Both were replaced by scripts/declare-intent.sh, which is
  # bound to a branch and carries a reason. This lint is what stops the next one
  # being added — a waiver reachable by `export`, or by any single command, is
  # not a waiver, it is an off switch with a polite name.
  #
  # A variable the script ASSIGNS itself is a local, not an environment input
  # (scripts/install.sh's FORCE comes from a --force flag), so each file is read
  # twice: once to collect its own assignments, once to check what it reads.
  envauth=""
  for f in $(git -C "$HARNESS_ROOT" ls-files 'scripts/*.sh' 'scripts/*/*.sh' '.githooks/*' '.claude/hooks/*' 2>/dev/null); do
    [ -f "$HARNESS_ROOT/$f" ] || continue
    case "$f" in *.md|*.json) continue ;; esac
    hit=$(awk -v fname="$f" '
      # pass 1: names this file assigns are its own, not the environment s
      NR==FNR {
        if (match($0, /^[[:space:]]*[A-Z][A-Z0-9_]*=/)) {
          n=substr($0, RSTART, RLENGTH-1); gsub(/[[:space:]]/,"",n); mine[n]=1
        }
        next
      }
      /^[[:space:]]*#/ { next }
      {
        line=$0
        while (match(line, /\$\{?[A-Z][A-Z0-9_]*/)) {
          v=substr(line, RSTART, RLENGTH); sub(/^\$\{?/, "", v)
          line=substr(line, RSTART+RLENGTH)
          if (v in mine) continue
          if (v ~ /^(HARNESS_ROOT|HARNESS_RUN_ID|CI|GITHUB_[A-Z_]*|TMPDIR|HOME|PATH|PWD|BASH_SOURCE|BASHPID|IFS|LC_ALL|LANG|OSTYPE|SHELL|USER|EDITOR|TERM|COLUMNS|NO_COLOR|PYTHONPATH|VIRTUAL_ENV)$/) continue
          if (v ~ /(ALLOW|APPROV|SKIP|FORCE|BYPASS|OVERRIDE|DISABLE|NOCHECK|NO_VERIFY|UNSAFE|IGNORE)/) {
            printf "      %s:%d: $%s — authority from the environment:%s\n", fname, FNR, v, $0
          }
        }
      }
    ' "$HARNESS_ROOT/$f" "$HARNESS_ROOT/$f") || true
    [ -n "$hit" ] && envauth="$envauth
$hit"
  done
  if [ -n "$envauth" ]; then
    note fail "a check must not take its authority from an environment variable:"
    printf '%s\n' "$envauth" | grep -v '^$' >&2
    printf '      use ./scripts/declare-intent.sh — branch-bound, reasoned, and it expires\n' >&2
  else
    note ok "no gate takes its authority from an environment variable"
  fi

  # Shipped file modes. Two failures, one check.
  #
  # (a) No owner-write bit. The v1.13.0 .skill shipped seven files without one,
  #     two of them registers a human is supposed to EDIT. git cannot catch
  #     this — it stores the executable bit and nothing else — so the check
  #     stats the working tree, and scripts/package-skill.sh and
  #     scripts/install.sh now normalise modes so an archive cannot carry it.
  #     `[ -w ]` is the portable test; note it is always true for root, so a
  #     container that builds as root will not see this. That is a real limit
  #     of the check and is why the normalisation, not this, is the fix.
  #
  # (b) A .sh or .py under scripts/ that is not executable. `make check` calls
  #     gates by path, so a non-executable gate is not a failing check — it is
  #     a check that silently stops running.
  modebad=""
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$HARNESS_ROOT/$f" ] || continue
    [ -w "$HARNESS_ROOT/$f" ] || modebad="$modebad
      $f — no owner-write bit"
    case "$f" in
      scripts/*.sh|scripts/*.py)
        [ -x "$HARNESS_ROOT/$f" ] || modebad="$modebad
      $f — under scripts/ and not executable" ;;
    esac
  done <<MODES
$(git -C "$HARNESS_ROOT" ls-files 2>/dev/null)
MODES
  if [ -n "$modebad" ]; then
    note fail "tracked files with wrong modes:"
    printf '%s\n' "$modebad" | grep -v '^$' >&2
    printf '      documents and config ship 0644, executables 0755\n' >&2
  else
    note ok "tracked file modes are sane (owner-writable; scripts executable)"
  fi

  if [ -n "$badsed" ]; then
    note fail "GNU-only sed (fails or corrupts on BSD/macOS sed):"
    printf '%s\n' "$badsed" | sed 's/^/      /' >&2
    printf "      use: scripts/sub.sh EXPR FILE   (no -i at all, and it keeps the file mode)\n" >&2
  else
    note ok "sed invocations are BSD-safe"
  fi


  if [ -n "$badgrep" ]; then
    note fail "grep with a bare pattern before '--' (breaks on BSD/macOS grep):"
    printf '%s\n' "$badgrep" | sed 's/^/      /' >&2
    printf '      use: grep -e PATTERN -- FILE\n' >&2
  else
    note ok "grep invocations are BSD-safe"
  fi
}

if [ "$PORTABILITY_ONLY" = 1 ]; then
  portability_checks
  [ "$RC" -eq 0 ] && ok "harness portability and modes" || warn "harness portability/mode checks failed"
  exit "$RC"
fi

info "level 1 — structure"
has_configured AGENTS.md
has CLAUDE.md
has_configured harness.config.yaml
has Makefile
has .agents/rules
has .agents/skills
has .agents/memory/MEMORY.md
has docs/decisions
[ -n "$(find "$HARNESS_ROOT/.agents/skills" -name SKILL.md 2>/dev/null)" ] \
  && note ok "at least one skill" || note fail "no SKILL.md found under .agents/skills/"
if [ -n "$(find "$HARNESS_ROOT/.claude/skills" -mindepth 1 -maxdepth 1 -type l 2>/dev/null)" ]; then
  broken=$(find "$HARNESS_ROOT/.claude/skills" "$HARNESS_ROOT/.claude/rules" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
  [ -z "$broken" ] && note ok "skill/rule symlinks resolve" || note fail "broken symlinks (re-run 'make link-skills'): $broken"
  # A skill with no link is invisible to Claude Code, and nothing says so — a
  # path that does not resolve loads nothing, silently. link-skills only runs at
  # setup, so a skill added afterwards stayed unlinked.
  unlinked=""
  for d in "$HARNESS_ROOT"/.agents/skills/*/; do
    [ -f "$d/SKILL.md" ] || continue
    n=$(basename "$d"); [ -L "$HARNESS_ROOT/.claude/skills/$n" ] || unlinked="$unlinked $n"
  done
  [ -z "$unlinked" ] && note ok "every skill is linked into .claude/skills" \
    || note fail "skills not linked into .claude/skills (run 'make link-skills'):$unlinked"
else
  note fail "skills not linked into .claude/ — run 'make link-skills'"
fi
grep -q '@AGENTS.md' "$HARNESS_ROOT/CLAUDE.md" 2>/dev/null \
  && note ok "CLAUDE.md imports AGENTS.md" || note fail "CLAUDE.md does not import AGENTS.md"
grep -q '<product>' "$HARNESS_ROOT/harness.config.yaml" 2>/dev/null \
  && note fail "harness.config.yaml still has <placeholders> — run /harness-init" \
  || note ok "config filled in"

if [ "$LEVEL" -ge 2 ]; then
  info "level 2 — enforcement"
  for g in scripts/gates/design-tokens.sh scripts/gates/secret-scan.sh scripts/gates/data-boundary.sh \
           scripts/gates/spec-clarity.sh scripts/gates/protected-paths.sh \
           scripts/gates/instruction-budget.sh scripts/gates/branch-hygiene.sh \
           scripts/gates/rule-coverage.sh scripts/gates/supply-chain.sh \
           scripts/gates/dependency-safety.sh \
           scripts/gates/skill-frontmatter.sh scripts/gates/skill-trust.sh \
           scripts/gates/skills-integrity.sh scripts/gates/requirements.sh \
           scripts/gates/policy.sh scripts/gates/design-system.sh; do exec_ok "$g"; done
  has scripts/validate-tokens.py
  has .agents/skills/ui-design-system/SKILL.md
  exec_ok scripts/gate-selftest.sh
  exec_ok scripts/install.sh
  exec_ok scripts/harness-sync.sh
  exec_ok scripts/ci-gen.sh
  exec_ok scripts/deploy.sh
  exec_ok scripts/doctor.sh
  has .github/workflows/gates.yml
  has .github/pull_request_template.md
  has .githooks/pre-commit
  if [ "$(git -C "$HARNESS_ROOT" config core.hooksPath 2>/dev/null)" = ".githooks" ]; then
    note ok "git hooks installed"; else note fail "git hooks not installed — run 'make install-hooks'"; fi
  # Security-layer presence: these are the files whose absence is silent.
  has .agents/rules/security.md
  has docs/security.md
  has_configured docs/product/requirements.md
  has_configured docs/product/decisions.md
  has_configured docs/product/PRD.md
  has .agents/skills/harness-threat-model/SKILL.md
  has .agents/skills/harness-security-review/SKILL.md
  portability_checks

  if "$HARNESS_ROOT/scripts/harness-sync.sh" --check >/dev/null 2>&1; then
    note ok "generated tool files in sync"; else note fail "tool files have drifted — run 'make harness-sync'"; fi
  if "$HARNESS_ROOT/scripts/ci-gen.sh" --check >/dev/null 2>&1; then
    note ok "generated CI files in sync"; else note fail "CI files have drifted — run 'make ci-gen'"; fi
fi

if [ "$LEVEL" -ge 3 ]; then
  info "level 3 — governance"
  if [ "$(cfg governance.enabled false)" = "true" ]; then
    has .harness/workflows
    has .harness/schemas
    if command -v python3 >/dev/null 2>&1; then
      if python3 "$HARNESS_ROOT/.harness/scripts/validate_governance.py" --all >/dev/null 2>&1; then
        note ok "governance fixtures validate"
      else note fail "governance validator failed — run 'make governance-check'"; fi
    else note fail "python3 required for the governance validator"; fi
  else
    note ok "governance disabled in config (level 3 not claimed)"
  fi
fi

if [ "$STUBS" -gt 0 ]; then
  info ""
  info "$STUBS file(s) are still the shipped template. That is expected on a fresh"
  info "  install and is not a failure — but until they hold real content, a green"
  info "  run here means 'the harness is present', not 'the harness is configured'."
fi
[ "$RC" -eq 0 ] && ok "harness verified at level $LEVEL" || warn "harness verification failed at level $LEVEL"
exit "$RC"
