#!/usr/bin/env bash
# An AI surface with no evals does not ship.
#
# For ordinary code, the tests are the safety net and a gate can check they run.
# For a model-backed feature there is no equivalent: the code can be perfect and
# the behaviour still wrong, and it can change without you touching the repo —
# a provider updates a model, a retrieval index drifts, a prompt gets a word
# added. Evals are the only artefact that notices.
#
# So this gate asks one question: does the repo have model-facing code and no
# way to tell whether it still works?
. "$(dirname "$0")/../lib.sh"

# The `ai` surface is what defines "model-facing" — one definition, in the config,
# shared with the policy gate. If the overlay is applied there is an `ai` surface.
ai_paths() {
  awk '
    /^surfaces:/ { inb=1; next }
    /^[^[:space:]#]/ { inb=0 }
    !inb { next }
    /^[[:space:]]*-[[:space:]]*id:[[:space:]]*ai[[:space:]]*$/ { found=1; next }
    found && /^[[:space:]]*paths:/ { v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); print v; exit }
    found && /^[[:space:]]*-[[:space:]]*id:/ { exit }
  ' "$CONFIG"
}

PATHS="$(ai_paths)"
[ -n "$PATHS" ] || { info "no 'ai' surface declared — nothing for this gate to check"; ok "ai evals (no ai surface)"; exit 0; }

RE=$(glob_alt "$PATHS")
[ -n "$RE" ] && [ "$RE" != '^()$' ] || { ok "ai evals (ai surface has no paths)"; exit 0; }

FILES=$(repo_files | sgrep -E -e "$RE" -- || true)
if [ -z "$FILES" ]; then
  info "no model-facing files yet (surface 'ai': $PATHS)"
  ok "ai evals (nothing model-facing yet)"
  exit 0
fi

n_ai=$(printf '%s\n' "$FILES" | scount .)
CASES_DIR="$HARNESS_ROOT/$(cfg evals.cases_dir evals/cases)"
n_cases=0
# `[ -d ] && n=...` left n_cases at 0 when the directory was missing, which is
# the same number a present-but-empty directory produces. "No cases" and "no
# case directory" then read identically, and the second is a broken config.
if [ -d "$CASES_DIR" ]; then
  n_cases=$(find "$CASES_DIR" -name '*.json' -type f | scount .)
else
  info "$CASES_DIR does not exist"
fi

rc=0
if [ "$(cfg evals.enabled false)" != "true" ]; then
  warn "$n_ai model-facing file(s) present, but evals.enabled is false."
  warn "    A model-backed feature can break without the repo changing — a provider"
  warn "    updates a model, an index drifts, a prompt gains a word. Evals are the"
  warn "    only thing that notices. Turn them on, or drop the 'ai' surface."
  rc=1
elif [ "$n_cases" -eq 0 ]; then
  warn "$n_ai model-facing file(s) present, and $CASES_DIR holds no cases."
  warn "    Evals are switched on and empty, which is the same as off but harder to see."
  warn "    Write one case that fails against a deliberately wrong answer first —"
  warn "    see .agents/skills/harness-eval-design."
  rc=1
fi

# Cases existing is not the same as cases being decided. A judge scorer with no
# live verdict leaves the run UNGRADED (run-evals.sh exit 2) — and for a
# model-backed feature the rubric is usually the criterion that matters, so
# treating "not judged" as "fine" grades the easy half and calls it the whole.
# --judge-coverage, not a full run: the deterministic scorers describe an agent
# task and legitimately fail until that task has been performed, so executing
# them here would make this gate red for reasons that have nothing to do with
# what it checks.
if [ "$rc" -eq 0 ] && [ "$n_cases" -gt 0 ] && [ -x "$HARNESS_ROOT/evals/run-evals.sh" ]; then
  ev=0; "$HARNESS_ROOT/evals/run-evals.sh" --judge-coverage >/dev/null 2>&1 || ev=$?
  if [ "$ev" != 0 ]; then
    if [ "$(cfg evals.require_graded false)" = "true" ]; then
      warn "judge scorer(s) in $CASES_DIR have no live verdict — the suite is ungraded, not green."
      warn "    For a model-backed feature the rubric is usually the criterion that matters."
      warn "    Run 'make evals' to see which, then ./evals/grade.sh to record a verdict."
      rc=1
    else
      warn "judge scorer(s) have no live verdict (evals.require_graded is false, so this is not blocking)."
      warn "    Once the cases are yours rather than the shipped examples, turn it on."
    fi
  fi
fi

[ "$rc" -eq 0 ] || fail "ai evals"
ok "ai evals ($n_ai model-facing file(s), $n_cases case(s), all judged)"
