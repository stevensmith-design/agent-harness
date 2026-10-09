# Deriving a pack for a domain the kit has never seen

**This is the normal path, not the fallback.** Five packs exist. There are not five domains. The
kit's whole reason for being universal is that *the next domain is always the one nobody
catalogued* — so a request for a legal-ops, recruiting, customer-support, clinical-ops or
grant-writing harness is not an edge case the kit tolerates. It is the case it was built for.

If a pack exists for the domain, read it and save yourself the derivation. If one does not, derive
the same three variables from the person in front of you. **Nothing downstream can tell the
difference** — `harness-build` consumes the three variables, not the file they came from.

---

## The one rule that makes this safe

**Derive from THEIR context. Never from your own knowledge of the domain.**

You know things about project management, recruiting and clinical operations. That knowledge is the
single biggest hazard in this procedure, because it produces a pack that reads exactly like a
derived one and is backed by nothing. This kit already contains a worked example of the failure:
`project/PACK.md` was inferred from the anatomy alone, is marked **sketch**, and says of itself that
building it as a pack may be a category error.

The test, applied to every line you write: **can you name the sentence they said, the file they
showed you, or the piece of work they rejected that this came from?** If not, it is not derived, it
is remembered — and a harness built on it enforces someone else's standard against their work.

Where a domain genuinely has an external, citable standard — WCAG, a regulator's rule, a published
schema — that transfers, and you may bring it. That is the whole of what "pre-package what is
externally standardised" licenses. Everything else comes from them.

---

## 1 · The verbs — what "check" means here

Ask what a wrong output looks like, then ask what would have caught it. The answers are the verbs.

Do not start from the word "check". In code it means compile, lint, test. In design it means
contrast ratio, token drift, spec conformance. In business development it means *did this go out
with the wrong client's name in it*. The verb list is short, concrete, and always theirs.

**Harvest before asking.** "Help me create a harness for our bid team" has already told you the
domain, roughly who uses it, and that the standard is probably a judgement nobody has written down.
Asking any of that back is the fastest way to lose the room.

## 2 · The foundations — what the AI must not invent

The highest-value question in the whole engagement: **what would be actively harmful for an agent
to make up here?** Prices. Client names. Legal positions. Dosages. Availability. Precedent.

That list is the foundations organ, and it is domain-specific in content and universal in shape.
A domain where nothing is dangerous to invent is a domain that may not need a harness at all —
which the fitness recommendation should already have said out loud.

## 3 · The starting rung — follows from the standard, not the team

Ask: **is the standard written down anywhere, in any form?**

- Written and mechanically checkable → L2 is available now.
- Written but only a person can apply it → L1 with a rubric, and a gate later if it firms up.
- Not written down, and they know it when they see it → **L1, corpus first.** Build the judged
  examples before any check exists. This is the commonest answer and it is not a failure state.

**Never set the rung from how technical the team is.** A small non-technical business can run
git, hooks and gates with deliberately no CI. Technicality predicts tooling comfort; it does not
predict whether a standard is scorable, and only the second one decides the rung.

---

## 4 · Then decide what the harness actually contains

The three variables tell you what varies. They do not tell you what to build. Walk the anatomy and
decide, per organ, whether this domain needs it thick, thin, or not yet — and what runtime artifact
that implies:

| If the domain needs | It becomes |
|---|---|
| A step people repeat and get wrong differently each time | A **procedure**, which `sync-skills.sh` renders as an invokable skill |
| A violation stateable as a rule that a script can decide | A **gate** in `scripts/gates/`, plus a self-test case that proves it can fail |
| A standard a person applies but no script can yet | A **rubric**, prose, L1, with the corpus that will eventually make it scorable |
| Something that must be true before every session | A line in the **constitution**, inside the budget |
| Something that must fire without anyone remembering | A **hook** |
| A judgement that must be re-checked as the corpus grows | An **eval** — the kit does not ship a runner; say so rather than implying one |

**An organ you skip is a hole where a failure gets through, not weight saved.** Say which organs
you left thin and why, in the architecture document. An organ silently omitted is indistinguishable
from an organ nobody thought of.

---

## 5 · Write it down, and do not promote it

Record the derivation in the harness's own `decisions/`, not as a new pack in the kit.

**A pack is earned by an engagement, never authored from intuition.** If the same domain comes back
a second time and the derivation held, that is the moment it becomes a pack — and it ships marked
with what backs it, the way the complete three are. A pack that claims more than it has is the same
defect as a config key nothing reads: it looks like capability to anyone skimming, and the next
person builds on it.
