# Capability skills

Third-party and organisation-specific skills live here only after the
`capability-intake` procedure has completed. A skill is executable instruction,
not merely documentation.

Each child directory contains one portable `SKILL.md`. Its source, immutable
pin or content-only pin, licence, reviewer, review date, and content hash are
recorded in `capabilities-lock.json`. The capability-safety gate rejects an
unlocked directory, changed content, unsafe install or prompt-override shapes,
and metadata that a strict host would refuse.

Do not point a runtime directly at a download or an unreviewed checkout. Stage
outside this harness, inspect it, then copy the reviewed files here and pin the
exact bytes.
