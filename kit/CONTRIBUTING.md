# Contributing to the kit

For people changing the kit itself — its skills, packs and theory. Using the kit needs none of this; start at [`README.md`](README.md).

Run `./check-kit.sh` before and after every change, and `./check-kit-selftest.sh` whenever you touch a check. **When you change anything in `core/`, also install it into a throwaway project and run its `scripts/doctor.sh` and `scripts/gate-selftest.sh`** — `check-kit.sh` does not run the template's own gates, so a doc that trips one (a backticked example that looks like a path, say) only shows up there. A check no case can kill is a check nobody is maintaining.

## The kit stands alone

Research and example harnesses shape what the kit knows. They never appear in it. Write each lesson as a principle with its reasoning, never as a pointer to a harness, project, company or folder — nobody else's copy has those, so the pointer is dead the moment it ships.

`check-kit.sh` enforces this. It fails on personal machine paths, on language that cites outside harnesses as evidence, and on any term listed in `.private-terms`. That file is gitignored on purpose: keep the private names you want guarded there, one per line, because committing the list would publish the very names it protects.

## Writing a kit skill

Every `skills/<name>/SKILL.md` carries this frontmatter. `check-kit.sh` enforces
all of it, so a skill that omits any of it fails the check rather than shipping.

| Field | Required | What it does |
|---|---|---|
| `name` | yes | Must match the directory name |
| `description` | yes | **The only text a host matches on before the skill fires.** The routing boundary has to be here, not in the body — a reader who has to open the file has already lost the routing decision |
| `metadata.harness.entry` | yes, `"true"` or `"false"` | Which skill owns an opening request. The kit-specific field lives under portable `metadata`, because top-level `entry` is rejected by strict skill packaging. **Exactly one skill may declare `"true"`** — today `harness-scope`. Zero and two are both hard failures. |
| `allowed-tools` | yes | Qualify the grant. A skill that says "reports and stops, never edits" and holds unqualified `Bash` has a read-only contract enforced by prose alone |

A skill is capped at **200 lines**, the same budget and the same counting rule
(blank lines and HTML comments excluded) as the harness this kit produces. Detail
past that belongs in `references/`, loaded when the skill actually runs.

`check-kit.sh` also scans install/privilege instructions, prompt-override text,
coercive activation language, and runtime downloads. A legitimate quoted test
fixture may be allowlisted in `skill-trust-allow.tsv` by path and exact line
substring with a reason; file-wide and pattern-wide exceptions are not accepted,
and stale rows fail.

Note the kit deliberately has no `claims:` field. One existed, declared by all
three skills in two incompatible formats, and no script ever read it — routing is
derived from `description:`. A second declaration that nothing parses is the
kit's own "machinery pointing at something nothing produces" defect, one level up.
