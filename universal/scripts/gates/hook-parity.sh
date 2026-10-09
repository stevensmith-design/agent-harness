#!/usr/bin/env bash
# Every rule a hook enforces must also be enforced somewhere that cannot be
# switched off.
#
# A hook runs on one machine, in one tool, for whoever has it installed. It is
# the fastest feedback in the harness and the easiest thing in the harness to
# disable — delete a line from settings.json, or just use a different editor,
# and the rule silently stops existing. Nothing reports that. The repo still
# looks compliant, because the only thing that was checking has gone quiet.
#
# So a hook is a CONVENIENCE, never the sole enforcement. Each one declares the
# CI-side gate that enforces the same rule fail-closed:
#
#     # ci-parity: scripts/gates/protected-paths.sh
#
# and this gate checks the declaration exists and points at something real. That
# makes the pairing mechanical rather than a habit — the failure mode it prevents
# is a hook added in a hurry that quietly becomes the only enforcement.
#
# `# ci-parity: none — <reason>` is allowed for hooks that genuinely have no CI
# half (a formatter that only makes sense at edit time). It must say why, because
# "there is no CI equivalent" is a claim, and an unexamined claim here means a
# rule that exists only on one laptop.
. "$(dirname "$0")/../lib.sh"

HOOKS="$HARNESS_ROOT/.claude/hooks"
[ -d "$HOOKS" ] || { ok "hook parity (no hooks directory)"; exit 0; }

shopt -s nullglob
hooks=("$HOOKS"/*.sh)
shopt -u nullglob
[ "${#hooks[@]}" -gt 0 ] || { ok "hook parity (no hooks)"; exit 0; }

rc=0; n=0; exempt=0; why=""
for h in "${hooks[@]}"; do
  rel=".claude/hooks/$(basename "$h")"
  decl=$(sgrep -m1 -E -e '^#[[:space:]]*ci-parity:' -- "$h" | sed 's/^#[[:space:]]*ci-parity:[[:space:]]*//')
  if [ -z "$decl" ]; then
    warn "$rel enforces a rule but declares no CI counterpart."
    warn "    Add '# ci-parity: scripts/gates/<gate>.sh' naming the gate that enforces"
    warn "    the same rule fail-closed, or '# ci-parity: none — <why>' if there is none."
    rc=1; continue
  fi
  case "$decl" in
    none*)
      case "$decl" in
        none' '*[!' ']*)
          why="${decl#none }"; why="${why#— }"; why="${why#- }"
          info "$rel — no CI half: $why"; exempt=$((exempt+1)) ;;
        *) warn "$rel declares 'ci-parity: none' with no reason. Say why the rule needs no CI half."; rc=1 ;;
      esac
      ;;
    *)
      # The declaration must point at a file that exists. A parity claim naming a
      # gate nobody wrote is the same defect one level up.
      if [ -f "$HARNESS_ROOT/$decl" ]; then
        n=$((n+1))
      else
        warn "$rel declares parity with '$decl', which does not exist."
        warn "    A hook whose CI counterpart is imaginary is the only thing enforcing that rule."
        rc=1
      fi
      ;;
  esac
done

[ "$rc" -eq 0 ] || fail "hook parity"
ok "hook parity ($n hook(s) paired with a CI gate, $exempt exempt with a stated reason)"
