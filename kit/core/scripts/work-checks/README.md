# Work checks

Put checks for the actual work here. `scripts/check.sh` runs these plus the
always-cheap data boundary. Keep harness governance in `scripts/gates/`; it runs
through `scripts/harness-check.sh` only when the harness itself changes.

An absent kind of check is not a stub. Record why it is not applicable in the
surface or procedure that would otherwise need it.
