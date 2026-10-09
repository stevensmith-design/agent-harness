# IA Principles Reference

Extended rationale and edge-case guidance for `ia-review`. Read this file when the checklist item is ambiguous or the finding needs justification.

---

## Table of contents

1. [Navigation models](#navigation-models)
2. [Content hierarchy](#content-hierarchy)
3. [Information scent](#information-scent)
4. [Progressive disclosure](#progressive-disclosure)
5. [Label standards](#label-standards)
6. [Consistency rules](#consistency-rules)

---

## Navigation models

### The cognitive load budget

Top-level navigation (tab bars, side navs, bottom navs) should have 3–5 items. Below 3 feels arbitrary. Above 5 requires the user to scan rather than recognise. If the product genuinely needs more than 5 top-level destinations, the structure should be reconsidered — typically some destinations belong one level deeper.

### Single-purpose tabs

Each top-level tab must have one purpose a user could name without ambiguity. "Home" is acceptable if it acts as a dashboard. "More" is a failure — it means "we ran out of room and gave up." If a tab holds only one item, that item should be promoted or merged.

### Scope parallelism

Navigation items at the same level must be parallel in scope. A tab bar mixing "Home" (a destination) with "Search" (a behaviour) and "Profile" (a subject) is incoherent. Acceptable patterns:
- All destinations: Home / Library / Explore / Profile
- All actions (rare, for tools): Write / Edit / Publish / Review

### Modal vs. push

Push navigation (drill-down) signals: "this is a deeper view of what you were looking at."
Modal navigation (sheet, overlay) signals: "this is a separate task; you will return."

Using modals for drill-down breaks the back model — users cannot tell where "back" leads. Using push for separate tasks (e.g., a settings screen pushed onto a product list) implies false relationship.

---

## Content hierarchy

### The fold

On a 375pt viewport with a standard tab bar and nav bar, the safe visible area is approximately 550–580pt tall. The primary value prop, primary action, and primary data must appear within this window. Content below the fold is acceptable for supplementary detail but must not contain anything the user needs before acting.

### Grouping logic

Group by: relationship (same entity, same task, same status), not by implementation (same API call, same database table, same team that owns it). Common failure: grouping "account settings" with "notification settings" with "privacy settings" because they all live in a settings microservice — fine. Grouping "order history" with "payment methods" with "addresses" because they all touch the commerce backend — not fine from a user perspective; these are different mental models.

### List ordering

Default list ordering should follow the user's most likely mental model:
- Activity feeds: reverse chronological (most recent first)
- Search results: relevance, then recency
- Settings: frequency of use (most-used near top) or categorical grouping
- People lists: alphabetical unless there is a relationship signal (friends before strangers)

Never use backend insertion order as the default sort for user-facing lists.

---

## Information scent

### Navigation prediction

Before auditing, ask: "If a new user taps this label, what do they expect to find?" Then check whether the screen delivers exactly that. Failures come in two forms:
1. **Under-delivery**: the label promises more than the screen provides ("Explore" leads to a thin feature list)
2. **Over-delivery**: the screen is richer than the label implies (a tab called "Me" that contains a full social graph, activity history, and settings)

### Empty states

An empty state is not a failure state — it is a navigation moment. Users who land on an empty screen need to understand:
1. What belongs here (the concept)
2. Why it's empty (haven't added anything yet / no results match / requires a permission)
3. How to populate it (the action)

A blank screen with a generic icon is an IA failure. An empty state with "No items yet. Tap + to add one" is acceptable. An empty state that explains the feature and surfaces the first meaningful action is excellent.

### Error states

Error copy must answer: what happened, why it matters, and what the user can do. "Something went wrong" answers none of these. "Couldn't load your orders — check your connection and try again" answers all three.

---

## Progressive disclosure

### The primary action rule

Every screen should have one thing the user is most likely to do next. That thing should be the most visually prominent interactive element. If two actions are equally prominent, the screen has not made a decision — it has deferred to the user, which increases cognitive load.

Acceptable: one solid CTA + one ghost/text secondary action
Not acceptable: three equally weighted buttons, a bottom sheet full of options at equal weight, a grid of feature tiles with no hierarchy

### Dangerous action distance

Destructive or irreversible actions (delete, cancel subscription, send to all, publish) must require at least one additional confirmation step beyond the initial tap. The confirmation must be non-trivial — a tooltip or a brief animation is not a confirmation. A sheet with a clear description of consequences + a labelled confirm button is.

Reversible actions (archive, mute, hide) do not require a confirmation step, but should offer an undo affordance for 4–6 seconds post-action.

### Permissions and onboarding

The first screen a user sees should show them value — not ask for permissions. Request permissions at the moment of relevance (camera permission when they first try to take a photo; location permission when they first search nearby; notification permission after they complete a meaningful action). Pre-emptive permission requests on launch are an IA failure regardless of conversion statistics.

---

## Label standards

### Verb vs. noun

- Navigation destinations: nouns or noun phrases ("Profile", "Order History", "Settings")
- Actions / CTAs: verbs or verb phrases ("Save", "Share", "Add to cart", "Start free trial")
- Section headings: nouns or participles that describe what follows ("Recent activity", "Upcoming", "In progress")

Mixed forms within the same nav or the same list are a consistency failure.

### Length limits

| Element | Max length |
|---------|-----------|
| Tab bar item | 12 characters (longer labels are truncated on small devices) |
| List section header | 24 characters |
| Screen title / page heading | 32 characters |
| CTA button | 24 characters |
| Sheet title | 40 characters |

These are display limits, not writing targets. Shorter is almost always better.

### Internal terminology

Product codenames, feature flags, backend service names, and team names must never appear in user-facing labels. Common failures: "V2 profile", "Legacy checkout", "ML recommendations", "GDPR settings" (should be "Privacy"). If auditing code, grep for labels and cross-check against this pattern.

---

## Consistency rules

### Naming consistency

A concept must have exactly one name across: the tab bar, the screen title, section headers, in-product copy, empty states, error messages, and any onboarding references. Auditing technique: pick three concepts from the nav, search the codebase for every string that references those concepts, and check for synonyms.

### Interaction consistency

If a pattern exists for one instance of a type, it must exist for all instances:
- If one list has swipe-to-delete, all similar lists must have it (or none should)
- If one card is tappable, all visually similar cards should be tappable (or there must be a clear visual signal distinguishing tappable from non-tappable)
- If one form autosaves, all forms should autosave (or there must be explicit Save buttons everywhere)

Inconsistent interactions are not a visual design problem — they are an IA trust problem. Users form mental models from the first instance; the second instance either confirms or breaks the model.

### Capitalisation

Pick one convention and apply it everywhere within a surface:
- **Title Case**: Home, Order History, My Profile — common for tab bars and headings
- **Sentence case**: Home, Order history, My profile — increasingly preferred for modern mobile UI

Mixing conventions within the same nav level is a failure. Mixing across different levels (Title Case for tabs, Sentence case for section headers) is acceptable.
