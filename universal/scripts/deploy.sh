#!/usr/bin/env bash
# Run a deploy verb against every target configured for an environment.
#
#   scripts/deploy.sh <env> <verb>
#     env  : preview | staging | production
#     verb : plan | apply | promote | rollback | status
#
# Targets run in the order they are listed in harness.config.yaml, which is how
# migrations land before the app that depends on them.
. "$(dirname "$0")/lib.sh"

DEPLOY_ENV="${1:?usage: deploy.sh <env> <verb>}"
VERB="${2:?usage: deploy.sh <env> <verb>}"
export DEPLOY_ENV

[ "$(cfg deploy.enabled false)" = "true" ] || { warn "deploy is disabled (deploy.enabled in harness.config.yaml)"; exit 0; }

# Read the targets for this environment out of the deploy.environments list.
targets=$(DE="$DEPLOY_ENV" awk '
  /^deploy:/ {inD=1; next}
  /^[^[:space:]#]/ {inD=0}
  inD && /^[[:space:]]+environments:/ {inE=1; next}
  inE && /^[[:space:]]*-[[:space:]]*name:/ {
    cur=$0; sub(/.*name:[[:space:]]*/,"",cur); gsub(/[[:space:]]/,"",cur); next
  }
  inE && cur==ENVIRON["DE"] && /^[[:space:]]*targets:/ {
    t=$0; sub(/^[[:space:]]*targets:[[:space:]]*/,"",t); gsub(/[]["'\'']/,"",t); gsub(/,/," ",t); print t; exit
  }
' "$CONFIG")

[ -n "$targets" ] || { warn "no targets configured for environment '$DEPLOY_ENV'"; exit 0; }

# shellcheck source=scripts/deploy/_lib.sh
. "$HARNESS_ROOT/scripts/deploy/_lib.sh"

for t in $targets; do
  f="$HARNESS_ROOT/scripts/deploy/$t.sh"
  [ -f "$f" ] || fail "deploy module '$t' not found at $f"
  info "── $t · $VERB · $DEPLOY_ENV"
  # Load in a subshell so two modules cannot clobber each other's functions.
  ( # shellcheck disable=SC1090
    . "$f"
    if declare -f "deploy_$VERB" >/dev/null; then
      "deploy_$VERB"
    else
      fail "module '$t' does not implement '$VERB'"
    fi
  ) || fail "$t: $VERB failed for $DEPLOY_ENV"
done

# Every deploy leaves a trace. A deploy nobody can reconstruct later is an
# outage nobody can explain later.
"$HARNESS_ROOT/scripts/emit-evidence.sh" "execute_tool" "${HARNESS_ACTOR:-runner:local}" pass \
  "deploy $VERB $DEPLOY_ENV [$targets]" >/dev/null
ok "$VERB complete for $DEPLOY_ENV"
