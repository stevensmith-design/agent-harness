# Routing cases — the kit's front door

Twenty opening requests and the skill that should claim each one. **The subject is
the kit's three skills only** (`harness-scope`, `harness-build`, `harness-audit`),
because that is where a routing failure has actually been observed: for six
versions *"help me create a harness for X"* — the sentence almost every engagement
opens with — matched only `harness-build`, the skill that requires an
already-agreed architecture document and skips fitness entirely.

**Generalised** means most of these do not use the word *harness*. A marketing
lead or a bizdev team describing their problem will not, and a front door that
only opens for the internal vocabulary is a front door for people who already
know the product.

`none` is a real answer and four cases expect it. A kit that claims every request
is not routing; it is advertising.

| # | The opening request | Expected | Why |
|---|---|---|---|
| R01 | *"Help me create a harness for our content team."* | `harness-scope` | The origin defect. Names the thing, and "create" must not pull it to build. |
| R02 | *"Build me a harness for the design team."* | `harness-scope` | The word **build** is the trap. No architecture document exists yet. |
| R03 | *"Set up a harness for this repo."* | `harness-scope` | Same, with "set up". |
| R04 | *"Our AI output is inconsistent between people. Can you set up something so it comes out the same way every time?"* | `harness-scope` | The problem stated without the vocabulary. This is the product's actual pitch. |
| R05 | *"I want Claude to always follow our brand rules when it writes for us. How do we make that stick?"* | `none` | **Amended after run 1.** It reads like the ratchet described by a newcomer, and the first version expected `harness-scope`. It is a request for brand guidelines. Where a brand-voice skill exists it should win, and the kit claiming this is the over-reach R17–R20 guard against. |
| R06 | *"Every new person on the team gets different results from AI. I want to fix that properly."* | `harness-scope` | Consistency across contributors — the thing the kit is for. |
| R07 | *"Turn this shared Drive folder into something the team can actually work in with Claude."* | `harness-scope` | The workspace substrate, and the second way in (adopt an existing workspace). |
| R08 | *"We keep correcting the same mistakes in AI drafts. I want the corrections to hold."* | `harness-scope` | A repeated correction is the strongest signal a harness is warranted. |
| R09 | *"Can you make a setup so our bizdev people run our sales plays without inventing client facts?"* | `harness-scope` | Foundations and a data boundary, described as a business problem. |
| R10 | *"I've read the anatomy doc. I know what I want — surfaces, gates, the ratchet. Go ahead and build it."* | `harness-scope` | Fluent in the vocabulary, but **no architecture document exists**. Confidence is not sign-off. |
| R11 | *"Just copy the template into my project, I don't need the whole interview."* | `harness-scope` | The person may decline the assessment; scope still owns the entry and records the decision. Fitness is advisory, not a gate — but skipping straight to build loses the context gathering too. |
| R12 | *"The architecture document is signed off. Instantiate it."* | `harness-build` | The one precondition build requires, stated. |
| R13 | *"We agreed the design in decisions/0001-architecture.md last week — install it into the repo."* | `harness-build` | Agreed architecture, named artifact. |
| R14 | *"We have a harness already. Review it and tell me what's weak."* | `harness-audit` | Existing harness, review intent, no edits. |
| R15 | *"Our checks are all green and nobody believes them. Can you work out why?"* | `harness-audit` | The meaningless-green-tree symptom, in a person's words. |
| R16 | *"We're handing this project to another team next month. Is the harness ready?"* | `harness-audit` | Pre-handover review is a stated audit trigger. |
| R17 | *"Write me a blog post about design systems."* | `none` | Ordinary work. The kit has no business claiming it. |
| R18 | *"Fix the failing test in src/auth.ts."* | `none` | A task, not an environment. This is the "machinery for work that cannot use it" boundary. |
| R19 | *"Review this Figma screen for accessibility."* | `none` | A design review. Adjacent domain, not a harness request — and the kit is domain-general on purpose. |
| R20 | *"Make me a Claude skill that summarises meeting notes."* | `none` | Skillify, not harnessify. The nearest neighbour to the product, and the one most likely to be over-claimed. |

## What a run of this cannot see

- **What else was competing.** A judge run as a subagent inherits its host
  session's whole skill catalogue, so the kit's three are not the only candidates
  even though they are the only ones named in the prompt. That is closer to a real
  session than a three-way choice, and it is why R05 was lost to a brand-voice
  skill in run 1. **The catalogue is a condition of the run** and every run record
  states it; a score from one catalogue does not transfer to another.
- **One model, one phrasing.** A pass is evidence about this phrasing on the model
  that ran it, not about routing in general. Re-run after any description edit.
- **Nothing here tests what the skill then does.** A correct route into a skill that
  behaves badly still scores as a pass. That is `harness-audit`'s job, not this file's.
