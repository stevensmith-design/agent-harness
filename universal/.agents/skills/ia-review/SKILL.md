---
name: ia-review
description: >
  Audit the information architecture of a product — navigation structure, content hierarchy,
  labeling, grouping, and progressive disclosure. Use when reviewing a new screen or flow for
  structural clarity, when users report confusion about where things are, when navigation labels
  feel ambiguous, when the tab bar or menu structure is being designed or reconsidered, or when
  asking "does this make sense?", "is this easy to find?", "why are users getting lost?".
  Complements ui-design-review (visual quality) — this skill covers structural clarity.
  Runs in two modes: flow review (given screens or code, audit the structure) and label audit
  (audit naming consistency and clarity across navigation, headings, and CTAs).
---

# IA Review

Structural clarity skill. Covers how content is organised and labelled — not how it looks.
For visual quality, use `ui-design-review`. For implementation guardrails, use `ui-design-principles`.

---

## Review framework

Every IA review works through three layers in order.

**Layer 1 — Structure: Is the organisation logical?**
Are screens grouped by user intent? Does the navigation model match how users think about the product, not how the backend is organised? Structural problems at this layer mean users can never find things, regardless of labeling.

**Layer 2 — Labels: Are names clear and consistent?**
Navigation labels, section headings, and CTAs must be unambiguous on their own — no decoding required. Inconsistent naming (same concept, two names) is a Layer 2 failure even if the structure is sound.

**Layer 3 — Disclosure: Is complexity managed well?**
Is essential information surfaced immediately? Is secondary complexity deferred until needed? Overloaded screens and buried critical actions are Layer 3 failures.

---

## Mode detection

Read the request and pick the mode before starting.

| Signal | Mode |
|--------|------|
| "Review this screen / flow", shares screens or code | **Flow review** |
| "Check the labels / navigation naming", shares nav structure | **Label audit** |
| Ambiguous — default to Flow review and run Label audit as a sub-step |

---

## Mode 1 — Flow review

Given: screenshots, a Figma link, screen names, or source files.

### Step 1: Map the structure

List every screen and its position in the navigation hierarchy. If source code is provided, search it (any code-search tool — ripgrep, grep, editor search, IDE symbol search) for route definitions, tab bar items, and screen names first — don't try to hold the structure in memory.

```
Nav structure:
├── Tab 1: [label]
│   ├── Screen A
│   └── Screen B → Screen C (modal)
├── Tab 2: [label]
└── Tab 3: [label]
```

### Step 2: Run the IA checklist

Read `references/ia-principles.md` for the full rule set. Check each category:

**Navigation model**
- [ ] The number of top-level destinations matches the cognitive load budget (≤ 5 tabs / nav items)
- [ ] Each top-level destination has a single clear purpose — no catch-all tabs
- [ ] Navigation items are parallel in scope (not mixing "Home" with a verb like "Search")
- [ ] The active section is always clear to the user
- [ ] Back navigation is unambiguous — user always knows where "back" leads

**Navigation placement** — every action has exactly one correct home:
- [ ] Frequent / global actions → primary nav (tab bar, bottom nav)
- [ ] Contextual actions → screen-level (header button, FAB, inline row)
- [ ] Rare / account-level / destructive actions → settings or profile screen — never in global nav
- [ ] Flag any action placed in a catch-all menu (hamburger, "More") that belongs in one of the above categories. Common failure: logout in a hamburger nav — it belongs in account/profile settings.

**Content hierarchy**
- [ ] The most important information on each screen is above the fold on a standard phone viewport (375pt)
- [ ] Secondary information is accessible but does not compete with primary content
- [ ] Related items are grouped; unrelated items are separated by space or a divider — grouping follows user mental model, not backend or implementation structure
- [ ] Items within a group are ordered by user priority (importance, frequency of use, recency) — never by insertion order, API response order, or internal ID
- [ ] Lists are sorted by a logic the user would expect (recency, frequency, alphabetical, status) — the sort logic is explicit and consistent across similar lists

**Information scent**
- [ ] Each navigation item predicts its contents — tapping it delivers what the label implies
- [ ] Section headings describe what follows, not what the section is called internally
- [ ] Empty states explain what belongs here and how to add it — not just "Nothing here yet"
- [ ] Error states tell the user what happened and what to do next

**Progressive disclosure**
- [ ] Screens have a single primary action; secondary actions are subordinate or deferred
- [ ] Advanced or destructive actions require one additional step (confirmation, sheet, submenu)
- [ ] Onboarding complexity is deferred — users see value before being asked for input or permissions
- [ ] Forms collect only what is needed at this step; optional fields are clearly marked

**Consistency**
- [ ] The same concept has the same name everywhere (nav label = page title = CTA = any reference in copy)
- [ ] Interaction patterns are consistent — if swipe-to-delete exists on one list, it exists on all similar lists
- [ ] Modal vs. push navigation is used consistently for the same types of tasks

### Step 3: Findings

Report findings by layer. Every finding uses the same schema:

- **Finding**: the specific structural/label/disclosure problem
- **Affected flow / label / screen**: where it occurs (name the screen, path, or label verbatim)
- **Evidence**: what shows it — the observed structure, the label text, the nav position (not a guess)
- **Severity**: **Blocker** (user cannot complete a core task / gets lost) · **Major** (frequent confusion or wrong turns) · **Minor** (friction or inconsistency)
- **Recommendation**: the specific fix. For a structural finding resolved here (*IA (resolve
  here)*), make it implementation-ready — name the cause in the structure, the exact-or-bounded
  change, the affected screens/labels, and a check that confirms it — the same bar the review skills
  apply via their `repair-prescriptions.md`.
- **Handoff target**: where the fix actually lands when it is not pure IA — visual hierarchy → `ui-design-review`, implementation → `ui-design-principles`, naming/token consistency → `ui-design-system`, or *IA (resolve here)* when structural

Do not report things that are subjective preferences — only findings with a clear user impact rationale.

### Output format

```
## IA Review — [Product / Screen name]

### Nav structure
[Mapped hierarchy]

### Findings
| # | Finding | Affected flow/label | Evidence | Severity | Recommendation | Handoff target |
|---|---------|--------------------|----------|----------|----------------|----------------|
| 1 | Logout buried in hamburger "More" | Global nav → More | Logout sits in a catch-all menu; account actions belong in profile | Major | Move logout to Profile/Account settings | IA (resolve here) |

### By layer
- **Layer 1 — Structure:** [findings or ✅ No structural issues]
- **Layer 2 — Labels:** [findings or ✅ Labels are clear and consistent]
- **Layer 3 — Disclosure:** [findings or ✅ Complexity is appropriately managed]

### Summary
[2–3 sentences: what is working well and what are the highest-priority fixes]
```

---

## Mode 2 — Label audit

Given: a list of navigation labels, section headings, screen titles, or a nav structure.

### Step 1: Extract all labels

Collect every user-visible label into a flat list: tab names, screen headings, section titles, CTAs, empty state headlines.

### Step 2: Run label checks

**Clarity**
- [ ] Each label is understandable without context — a new user could predict what it contains
- [ ] No internal jargon, product codenames, or backend terminology exposed to users
- [ ] Verbs are used for actions ("Save", "Share"), nouns for destinations ("Settings", "History")
- [ ] Labels are as short as possible without losing meaning (≤ 3 words for nav items)

**Consistency**
- [ ] The same action/destination has the same label everywhere it appears
- [ ] Labels within the same level are parallel in form (all nouns, or all verb phrases — not mixed)
- [ ] Capitalisation is consistent (Title Case for nav, Sentence case for body — pick one and apply it)

**Ambiguity**
- [ ] No two labels could reasonably be confused for each other
- [ ] Generic labels ("More", "Other", "Misc") are absent or minimised
- [ ] Negative labels ("Don't show this") are rewritten as positive actions ("Hide")

### Output format

```
## Label Audit — [Scope]

### Labels reviewed
[Flat list of all labels audited]

### Clarity issues
[Findings or ✅ Clear]

### Consistency issues
[Findings or ✅ Consistent]

### Ambiguity issues
[Findings or ✅ Unambiguous]

### Recommended revisions
| Current | Recommended | Reason |
|---------|-------------|--------|
```

---

## What this skill does not cover

- Visual design quality / visual hierarchy → `ui-design-review`
- Implementation guardrails → `ui-design-principles`
- Naming/label tokens, design-system consistency → `ui-design-system`
- Accessibility (WCAG) → `ui-design-review` checklist / dedicated a11y audit
- User research / usability testing → use a research skill or conduct user sessions
- Product decisions (what features to build, what to cut) — IA review surfaces confusion; product decisions require business context this skill does not have

If a finding feels like a product decision, flag it as "worth discussing with the team" rather than a definitive recommendation.
