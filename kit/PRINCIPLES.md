# Principles — the review rubric

`ANATOMY.md` describes the organs. This file is the **rubric**: the short, checkable form used to review a harness — yours or a client's.

It deliberately restates nothing. Each row names the claim, the organ it tests, and the anti-pattern it catches.

**How to use it:** one lens per pass, rotating. A fixed checklist run every time calcifies into something that passes trivially. `skills/harness-audit/SKILL.md` runs this.

---

## A. Authority

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| A1 | Exactly one authoritative rulebook, and it forbids restating its content elsewhere | Constitution | **Instruction sprawl** — the same rule in three files, drifting independently |
| A2 | The constitution is budgeted, and the budget has never been raised to accommodate growth | Constitution | **The manual** — an unbudgeted constitution nobody finishes reading |
| A3 | Every rule traces to a named failure or an external constraint | Constitution | **Aspiration as rule** — advice that has never prevented anything |
| A4 | Conflicts between layers resolve by a written precedence order, without asking | Authority chain | **Last-read wins** |
| A5 | Documents earn their place by being referenced; nothing is orphaned | Authority chain | **Orphan docs** — files nothing points at, which agents still read and obey |
| A6 | What the AI must never invent is written down, and "stop and say so" is the instructed behaviour when it is missing | Foundations | **Fluent invention** |
| A7 | Every decision record names its revisit trigger | Decision record | **Permanent by accident** |
| A8 | The always-loaded **set** is budgeted, not one file in it | Constitution | **The second always-loaded file** — content moves sideways and the budget goes green |
| A9 | Every described mechanism names what runs it | Constitution · all | **Spec ahead of executable** — a wish shaped like documentation |

## B. Partition

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| B1 | Every surface is classified, and unmatched paths fail closed to the highest risk | Surfaces | **The unclassified lane** |
| B2 | Blast radius and approval tier are tracked separately | Surfaces | **Conflated risk** — "low risk" used to skip a human read |
| B3 | Enforcement depth differs by surface, and each surface's rung is deliberate | Surfaces | **Uniform heaviness**, and its twin, uniform thinness |
| B4 | A path that exists is not graded as a pass | Surfaces · Foundations | **Presence mistaken for content** — an unpacked template scoring as a configured harness |

## C. Work

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| C1 | Each procedure owns one altitude and names what its neighbours own | Procedures | **Overlapping lanes** — inconsistent choices at the seam |
| C2 | Every procedure declares what it Consumes and what its Human gate is | Procedures | **Untraceable output** — a bad result with no path back to its cause |
| C3 | A contract missing a required field blocks the work rather than being filled in by inference | Contracts | **Done by assertion** |

## D. Enforcement

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| D1 | Machine checks run before AI judgment, which runs before human attention | Gates | **Human as first filter** |
| D2 | Nothing important is signed off by whoever produced it | Gates | **Self-certifying agent** |
| D3 | Every gate reports its denominator | Gates | **The bare tick** — `✓` that cannot be distinguished from "examined nothing" |
| D4 | Every gate has been observed failing, by a test that rigs the violation | Gates | **Never-red gate** — passes only because it has only met clean trees |
| D5 | A stub, a skip, or a missing input is never reported as a pass | Gates | **False green** |
| D6 | Review lanes are read-only; mutation is opt-in and isolated | Gates | **Ambient write permission** |
| D7 | Harness health and work compliance are separate commands with separate verdicts | Doctor≠validate | **The meaningless green tree** |
| D8 | Rules are encoded as detectable patterns wherever possible | Gates | **Prose rule** — decays; a detectable rule compounds |
| D9 | The same command runs locally and in CI | Gates | **Local-only green** |
| D10 | Secrets, personal data, and untrusted external text each have a stated rule | Data boundary | **The green PII gate** mistaken for a clean file |
| D11 | Harness edits require declared intent and cannot travel with content in one change | Self-protection | **The gate edited to go green** |
| D12 | Protection is deny-by-default: content is enumerated, everything else is protected | Self-protection | **The unprotected new file** |
| D13 | Every gate suite says what it cannot see, and names who looks there | Gates · Human gate | **The complete-looking green** — a pass that reads as "checked everything" when it checked what was written |

## E. State

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| E1 | A fresh agent can reconstruct state from files alone | Evidence | **Context-window state** — a harness that depends on chat history is not one |
| E2 | Every run records its procedure, the foundations it consumed, and the commit | Evidence | **Untraceable run** |
| E3 | Approvals are logged with approver, date, exact scope, and what they unlock | Evidence | **Inferred approval** |

## F. Learning

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| F1 | A write-back loop exists and has actually run | Ratchet | **The document** — a harness that only grows by authorship sessions |
| F2 | Candidates need repeat occurrences before becoming rules | Ratchet | **The one-off rule** firing forever |
| F3 | Findings are routed to the most specific and most mechanical owner available | Ratchet | **Everything into the constitution** |
| F4 | Rejected candidates are recorded with reasons | Ratchet | **Invisible non-decisions** |
| F5 | Judged examples accumulate with their reasons | Corpus | **Adjectives instead of examples** |
| F6 | The quality spec has changed at least once since contact with real output | Corpus | **The ignored spec** — stable because nobody consults it |
| F7 | This review does not repeat the last one | Ratchet | **The recurring finding** — no longer about the work, and now about the team |
| F8 | A rule stays prose until someone adopts it, then earns a check | Ratchet | **Eager formalisation** — machine-checkability implied on someone else's behalf |
| F9 | Every finding leaves a lesson, written to the most mechanical owner its gap allows | Ratchet | **The fixed instance** — the defect is gone and nothing stops its sibling |
| F10 | A finding is swept across every place its standard applies before it is closed | Ratchet | **One at a time** — the same break found by hand, screen after screen |
| F11 | A standard broken again after its lesson moves up a rung; the same lesson is never recorded twice | Ratchet | **The lesson that did not hold** — rewritten, and believed, every time |
| F12 | A question about intent closes into a decision where the work reads it, never in the thread it was asked in | Decision record | **The answer in the ticket** — given once, asked again from the next screen |

## G. Lifecycle

| # | The claim | Organ | Anti-pattern |
|---|---|---|---|
| G1 | Someone assessed whether this work needs a harness, and the recommendation and the decision are both recorded | Fitness | **Machinery for work that cannot use it** |
| G2 | Creation logic lives outside the harness | Constructor | **Residue on transplant** — the previous project's assumptions travelling forward |
| G3 | Config and variables are separated from invariants | Constructor | **The un-transplantable harness** |
| G4 | On overlay: existing artifacts are adopted as canonical, not rewritten | Constructor | **Parallel truth** — a new file competing with the client's real one |
| G5 | Nothing is installed, credentialed, or configured on someone's behalf — and what was skipped is reported | Constructor | **Silent inaction** — indistinguishable from completion |

---

## The one that catches the others

**Every claim in the harness must name what enforces or produces it.**

This is the most common failure in harnesses — machinery that points at something nothing produces. It looks like: a config block read by zero lines of code; a design tokens path set by an installer with no skill that creates a token layer; a PRD referenced by four files and owned by nothing; a quality checklist referenced by nothing at all.

It is the hardest defect class to see, because adversarial review is excellent at *"does this code do what it says"* and blind to *"is there any code here at all"*.

The lesson is worth writing into the header of every config file:

> *If you add a FIELD, the script must be taught to read it in the same commit. Config nothing reads is worse than none, because it looks like enforcement to anyone skimming.*

### Its sharper form: the spec that runs ahead of the executable

Dead config is the visible half. The harder half is a **behaviour described in one file and absent from the file that would actually run it** — a doc that reads as documentation of something implemented, where nothing implements it.

The distinction is worth holding, because the two need different instruments:

| | Dead config | Spec ahead of executable |
|---|---|---|
| Shape | A key, path or file nothing consumes | A described behaviour nothing performs |
| Reads as | Configuration | Documentation |
| Caught by | `dead-config.sh` | Nothing mechanical. A reader who checks the implementation |

The pattern has a reliable signature: **where behaviour lives in a script it is careful and correct; where behaviour is "the agent reads this section and does the right thing", it is frequently described in one place and absent from the place that would run it.** Prose has no compiler, so a specification and a wish are the same artifact until someone checks.

Three shapes it takes, even where the authors know this rule:

- A consent mechanism documented across four files as protecting against plan drift. It hashes path *strings*, never file contents, and verification re-hashes the proposal's own stored fields — so it detects tampering with the proposal and nothing else. The drift-diagnosis example in its own protocol document describes output the code cannot produce.
- A review agent documented as reading a rubric's scope block and downgrading severity on a scope mismatch. The agent's specification never mentions scope, personas, or the mismatch code. The single best idea in that rubric system exists only in the guide.
- A three-occurrence threshold for promoting a rule, routinely waived under a "fast-track" exception that appears in no criteria document.

**The check is one question, asked while reading:** *what would I run to see this happen?* If the answer is "the agent would read this and comply", it is a wish — which is legitimate, and should be labelled as guidance rather than as a mechanism.

`core/scripts/gates/dead-config.sh` is the mechanical version of the first column. It starts from the config and the docs and asks what reads each key and what produces each referenced path. **Run it before believing any other result in this file.**
