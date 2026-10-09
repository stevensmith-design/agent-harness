# Product decisions

Decisions that change direction, scope, or an agreed requirement. Managed by the
`decisions` skill.

Architecture decisions go in `../decisions/` as ADRs — this file is *what the
product does*, not *how it is built*.

**The test:** would someone picking this up in three months be in trouble not
knowing it? No → do not write it here.

`🔴` changed direction · `✅` confirmed · `❌` killed · `⏸` out of scope for now

## YYYY-MM

| ID | Date | Decision | Detail |
|----|------|----------|--------|
| MM-DD | | |

---

## Decided against — do not re-propose

Read this before proposing or implementing anything that resembles an entry.
If what you are about to build is on this list, **stop and ask**.

Each line: what, when, and a reason that answers the question rather than
restating the decision. "Out of scope" tells the next person nothing and they
will raise it again.

<!-- - **<thing>** — YYYY-MM-DD · <reason> · DEC-NNN -->

---

## Open

Questions not yet decided live in `questions.md`, with who raised them and what
closed them. One place, so a question closed there is closed everywhere.
