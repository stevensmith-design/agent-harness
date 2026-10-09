#!/usr/bin/env bash
# Surface policy gate — the engine behind `surfaces:` in harness.config.yaml.
#
# The harness's headline idea is "choose the rung per SURFACE, not per repo":
# an auth change and a docs change should not face the same ceremony. That block
# existed in the config, and the config pointed at this file — which did not
# exist. Nothing read `surfaces:`. The most-advertised concept in the harness was
# decorative, and decorative config is worse than none, because it reads as
# enforcement to anyone skimming.
#
# What this does now:
#   1. resolves the changed files to the surfaces they touch
#   2. takes the HIGHEST risk and the HIGHEST rung among them
#   3. fails when a change claims a rung the repo has not switched on, or when a
#      high-risk surface is touched without the evidence that rung requires
#
#   ./scripts/gates/policy.sh [base-ref]
. "$(dirname "$0")/../lib.sh"

BASE="${1:-$(cfg git.main_branch main)}"

# surfaces: is a list of maps. Emit id<TAB>paths<TAB>risk<TAB>level per entry.
surfaces() {
  awk '
    /^surfaces:/ { inb=1; next }
    /^[^[:space:]#]/ { if (inb) { flush(); inb=0 } }
    !inb { next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*-[[:space:]]*id:/ {
      flush()
      v=$0; sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/,"",v); sub(/[[:space:]]+#.*$/,"",v)
      gsub(/["\x27]/,"",v); id=v; next
    }
    /^[[:space:]]+[a-z_]+:/ {
      line=$0; sub(/^[[:space:]]+/,"",line)
      k=line; sub(/:.*/,"",k)
      v=line; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]+#.*$/,"",v)
      gsub(/[[:space:]]+$/,"",v)
      if (k=="paths") paths=v; else if (k=="risk") { gsub(/["\x27]/,"",v); risk=v }
      else if (k=="level") { gsub(/["\x27]/,"",v); level=v }
    }
    function flush() {
      if (id != "") printf "%s\t%s\t%s\t%s\n", id, paths, risk, level
      id=""; paths=""; risk=""; level=""
    }
    END { flush() }
  ' "$CONFIG"
}

risk_rank() { case "$1" in low) echo 1 ;; medium) echo 2 ;; high) echo 3 ;; *) echo 0 ;; esac; }
lvl_rank()  { case "$1" in L1) echo 1 ;; L2) echo 2 ;; L3) echo 3 ;; L4) echo 4 ;; *) echo 0 ;; esac; }

CHANGED=$(changed_files "$BASE")
[ -n "$CHANGED" ] || { ok "surface policy (no changes against $BASE)"; exit 0; }

SURF=$(surfaces)
[ -n "$SURF" ] || { info "no surfaces: defined — every change is treated the same"; ok "surface policy (no surfaces declared)"; exit 0; }

touched=""; max_risk="low"; max_lvl="L1"; unclassified=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  hit=0
  while IFS=$'\t' read -r id paths risk level; do
    [ -n "$id" ] || continue
    re=$(glob_alt "$paths"); [ -n "$re" ] || continue
    if printf '%s\n' "$f" | grep -qE "$re"; then
      hit=1
      case ",$touched," in *",$id,"*) : ;; *) touched="${touched:+$touched,}$id" ;; esac
      [ "$(risk_rank "$risk")" -gt "$(risk_rank "$max_risk")" ] && max_risk="$risk"
      [ "$(lvl_rank "$level")" -gt "$(lvl_rank "$max_lvl")" ] && max_lvl="$level"
    fi
  done <<< "$SURF"
  [ "$hit" = 1 ] || unclassified="${unclassified}${f}"$'\n'
done <<< "$CHANGED"

if [ -z "$touched" ]; then
  info "no declared surface matches this change"
else
  info "surfaces touched: $touched   risk: $max_risk   required rung: $max_lvl"
fi

rc=0

# A change that lands on an L3 surface while governance is off is a change
# claiming a rung the repo has not switched on.
GOV_ON=$(cfg governance.enabled false)
GOV_LVL=$(cfg governance.level L3)
if [ "$(lvl_rank "$max_lvl")" -ge 3 ] && [ "$GOV_ON" != "true" ]; then
  warn "this change touches '$touched', declared at $max_lvl, but governance.enabled is false."
  warn "    Either switch L3 on (governance.enabled: true), or lower the surface's level."
  warn "    A surface declared at a rung the repo does not run is a promise nothing keeps."
  rc=1
fi
if [ "$(lvl_rank "$max_lvl")" -ge 3 ] && [ "$GOV_ON" = "true" ] && [ "$(lvl_rank "$GOV_LVL")" -lt "$(lvl_rank "$max_lvl")" ]; then
  warn "surface '$touched' requires $max_lvl but governance.level is $GOV_LVL."
  rc=1
fi

# High risk means a person is supposed to decide. What this gate can actually
# check is narrower, and the wording now says so.
#
# What "recorded" means changed in v1.12.0. It used to be HARNESS_HUMAN_APPROVED=1
# — a boolean with no reason, no scope and no expiry, so one export in a job or a
# shell profile approved every high-risk change that followed. A declaration is
# bound to the branch it was made on and carries a sentence saying why, so it
# cannot outlive the change it was written for.
#
# What it is NOT, and what this gate used to imply that it was: authentication.
# scripts/declare-intent.sh proves a declaration was made, not that a human made
# it — any agent that can run repository scripts can author one, including the
# agent whose change is being approved. So this gate requires an APPROVAL
# DECLARATION (trust: self_reported), and no longer claims to require a human
# approval. If a real one is needed, it has to come from a channel that issues
# identity — a GitHub required review or a protected environment — and this
# harness reads neither today. That gap is named in HARNESS-GUIDE.md rather than
# papered over here.
if [ "$max_risk" = "high" ]; then
  reason=$(intent_reason high-risk) && have_intent=1 || have_intent=0
  if [ "$have_intent" = 1 ]; then
    ok "high-risk surface — approval DECLARED (self-reported, not authenticated): $reason"
  elif [ -n "${CI:-}" ]; then
    warn "high-risk surface touched ($touched) — this change needs a recorded approval declaration before merge."
    warn "    Record it from the job that runs AFTER a required review, not the one that builds:"
    warn "      ./scripts/declare-intent.sh high-risk \"<who reviewed it, and where>\""
    warn "    The declaration is bound to this branch and does not carry to the next one."
    warn "    Note: this records a claim, it does not verify one. Only a required"
    warn "    reviewer on the PR makes the approval something a person actually gave."
    rc=1
  else
    info "high-risk surface ($touched) — CI will require a declared approval on this PR."
    info "  Run /security-review before opening it; that is what the escalation tier means."
  fi
fi

if [ -n "$unclassified" ]; then
  if [ "$(cfg policy.surfaces_exhaustive false)" = "true" ]; then
    warn "these changed files match no declared surface, and surfaces_exhaustive is on:"
    printf '%s' "$unclassified" | sed 's/^/    /'
    rc=1
  else
    # Not an error while surfaces_exhaustive is off — but the risk this gate
    # reports is the max over MATCHED files only, so an unmatched file has been
    # assessed as "low" by default rather than by decision. Name it.
    while IFS= read -r u; do [ -n "$u" ] && skipped "$u (matches no surface — risk not assessed)"; done <<< "$unclassified"
  fi
fi
blind_spots

[ -n "${GITHUB_OUTPUT:-}" ] && {
  printf 'surfaces=%s\n' "$touched" >> "$GITHUB_OUTPUT"
  printf 'risk=%s\n'     "$max_risk" >> "$GITHUB_OUTPUT"
  printf 'level=%s\n'    "$max_lvl"  >> "$GITHUB_OUTPUT"
}

[ "$rc" -eq 0 ] || fail "surface policy — see harness.config.yaml surfaces:"
ok "surface policy (${touched:-no surface}, risk $max_risk)"
