# The scattered motion

**Greenfield:** nothing exists. **Overlay:** it exists and belongs to someone else.

**Scattered:** it exists, it is yours, and nothing organises it. A `CLAUDE.md` someone wrote in a hurry, a `.cursorrules` from a different project, three README-adjacent docs, a Slack thread nobody can find, and a Figma link in a comment.

**This is the commonest real starting state.** Almost nobody arrives greenfield. They arrive with two or three years of accumulated AI material that was never designed.

Run `./detect.sh <target> [<target>…]` first. It decides the motion and fails closed — when the evidence is ambiguous it resolves toward the motion that writes least. **Scattered material is rarely only in files**: the rules a team actually follows are often pinned in Slack or buried in Notion. `../scope/context.md` covers reading those, and every verdict below applies to them too.

---

## What makes this motion different — and more valuable than it looks

A greenfield harness has to *invent* its foundations. **A scattered one mostly has to find them.** The brand rules exist. The conventions exist. The things that must never be said exist. They are in four files that have never been read side by side.

Which produces the real prize, and the thing to tell whoever owns this:

> **Scattered material is not just disorganised. It is usually contradictory — and nobody knows, because no two of these files have ever been read together.**

`CLAUDE.md` says one thing about tone, the old `.cursorrules` says another, the README implies a third, and the agent obeys whichever it loaded. **Surfacing those contradictions is the highest-value output of this motion**, often more valuable than the harness itself, and it is invisible until someone consolidates.

So: expect to find conflicts, treat each one as a finding rather than a merge problem, and **do not resolve them silently.** Every one is a decision somebody needs to make, and it belongs in `decisions/` with its reasoning.

---

## The stance: adopt before creating

Same discipline as overlay, for a different reason. There it protects someone else's work; here it protects **the only record of how this team actually operates.** A rule someone wrote after a real failure is worth more than anything you would write from first principles, even when it is badly phrased.

Four verdicts per organ:

| Verdict | Meaning | When |
|---|---|---|
| **Adopt** | An existing file becomes canonical for this organ. Content moves; the reasoning is preserved. | Something real exists |
| **Review** | Adopt it, and record what would improve it | It exists and is thin or stale |
| **Create** | Write it from the template | Nothing exists and the organ is load-bearing |
| **Skip** | Do not build it — it lives somewhere else | It exists outside this repo |

**"Skip" means "exists elsewhere", never "absent"** — and may not be decided by inference. Ask where it lives. If nobody knows, the verdict stays open and marked unverified.

---

## Mapping what you found

| Found | Becomes | Note |
|---|---|---|
| `CLAUDE.md`, `.cursorrules`, `copilot-instructions.md` | The **constitution**, merged | Where they disagree, that is a finding, not a merge |
| Substantial README / DESIGN / CONTRIBUTING prose | **Foundations** | Usually the richest source. Split "what is true" from "how we work" |
| Existing skills | **Procedures**, or left where they are | Do not rewrite a working skill to fit a template |
| CI, hooks, linters | **Gates**, already earned | These are the surfaces already at L2. Do not rebuild them |
| Decision docs, ADRs, RFCs | **Decision records** | Add the revisit trigger each one is missing |
| A folder of "good ones" and rejected drafts | **The corpus** — the rarest and most valuable find | If it exists, this harness starts far ahead |
| Anything nobody can explain | Leave it. Note it. | An unexplained file is someone's undocumented reason |

---

## Order

**1. Detect and report before touching anything.** Show what was found, the proposed verdict per organ, and the contradictions. Get agreement.

**2. Foundations first.** Adopt the prose that already exists. Mark what you inferred as inferred. **Never invent to fill a slot** — an empty foundation is honest; a plausible one is the failure this whole thing exists to prevent.

**3. Contradictions become decisions.** One record each: what disagreed, which wins, why, and the revisit trigger.

**4. Constitution last of the authority layer.** It routes; it does not contain. Merged rules that are path-specific go to a surface, not the constitution — a scattered repo's rules files are usually full of these, and dumping them all into the constitution blows the budget on day one.

**5. Classify surfaces from what is actually there.** A scattered repo tells you where work lands, because the files are already sitting in those places.

**6. Set rungs from what already exists.** A repo with CI and hooks already has surfaces at L2 — do not demote them to L1 because the harness is new.

**7. One real piece of work through it**, then the first corpus entry.

---

## What not to do

**Do not reorganise the repository.** You are adding a layer, not restructuring someone's project. Files stay where they are unless their owner asks.

**Do not delete anything.** Supersede in place with a pointer. The original stays until its owner approves removal — and in a scattered repo, the person who wrote the file may not be present to ask.

**Do not resolve contradictions silently.** Covered above, and it is the one most likely to be broken under time pressure, because resolving quietly feels like progress.

**Do not treat existing gates as beneath you.** A pre-commit hook someone wrote three years ago encodes a real failure. It outranks anything the template ships.

**Do not promote every found rule.** A scattered repo accumulates rules nobody has followed since the person who wrote them left. Adopting all of them produces a constitution nobody reads. Ask which are still true.
