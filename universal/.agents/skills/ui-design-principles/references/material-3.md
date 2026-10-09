# Material 3 — system adoption guide

Read this reference when the user explicitly requests Material Design, the product targets Android,
or the existing codebase uses Material 3 components or tokens. Verify current component guidance
against the live official documentation and the installed library version before implementation.
Material evolves; this file supplies the durable reasoning model.

## Contents

1. Adoption boundary
2. System layers
3. Component and interaction discipline
4. Adaptive layout
5. Expressiveness without style drift
6. Implementation and review gate
7. Official sources

## 1. Adoption boundary

Material is a design system, not a rounded-card aesthetic.

- **Android:** prefer the current platform Material implementation and native navigation/system
  behavior. Do not fight system gestures, insets, text scaling, or accessibility services.
- **Web or cross-platform:** Material tokens and components may be adopted, but Android navigation
  patterns are not automatically correct for web, iOS, or desktop.
- **Existing non-Material product:** do not import isolated Material components merely because they
  are convenient. Either adapt them to the authoritative product system or make Material adoption
  an explicit system-level decision.

Record whether the project is **Material-native**, **Material-adapted**, or merely
**Material-compatible**. This prevents accidental hybrids.

## 2. System layers

Model the system in three layers:

1. **Reference values:** source tonal palettes and raw scales.
2. **System roles:** colour, type, shape, spacing, motion, and elevation roles used by the product.
3. **Component tokens:** values for a component, variant, and state that resolve back to system
   roles.

Prefer roles such as surface/on-surface, primary/on-primary, outline, error/on-error, and container
pairs over raw colour names. Every foreground/background pair is evaluated together. Elevation is a
relationship and interaction cue, not a decoration budget.

Define typography by role and use, not a loose list of font sizes. Define shape as a deliberate
scale; expressive shapes are assigned to named components or moments rather than sampled randomly.

## 3. Component and interaction discipline

For every Material component:

- Read its current **anatomy, variants, behavior, placement, and accessibility** guidance.
- Use the platform/library component when it meets the need; preserve semantics rather than
  rebuilding its appearance from `div` elements.
- Specify enabled, hover (where relevant), focus, pressed, dragged, selected, disabled, loading,
  and error behavior as applicable.
- Treat state layers as feedback within a component system. Do not use opacity overlays as a
  substitute for a persistent selected/error signal.
- Keep selection distinct from action. Use the minimum sufficient combination of fill/value,
  border, weight, indicator, shape, and iconography.
- Preserve predictable focus movement, keyboard behavior, touch targets, and accessible names.

Choose a component from the job and content, not from visual resemblance. A card is not the default
container; a dialog is not the default explanation; a floating action button is not a generic
“important button.”

## 4. Adaptive layout

Design adaptation as component and navigation changes, not only fluid resizing.

- Identify compact, medium, and expanded conditions using the current platform/library guidance;
  verify the exact thresholds rather than copying stale numbers into the design contract.
- Choose a canonical structure from the task: list-detail, feed, supporting pane, or another
  documented layout pattern.
- Let navigation change form when the available window and task warrant it (for example, compact
  bottom navigation to a wider rail/pane), while keeping destinations, labels, and state stable.
- Decide what is shown simultaneously, what moves to a pane/sheet/page, and what remains reachable.
- Test split-screen, rotation, text scaling, keyboard/inset changes, and long localized labels where
  the target platform supports them.

The narrow layout is not a compressed desktop screen, and the expanded layout is not empty margins
around a phone screen.

## 5. Expressiveness without style drift

Material 3 Expressive expands shape, motion, type, colour, and component choices. Treat this as an
available vocabulary, not an instruction to maximize every dial.

- Start from the product's emotional register and task frequency.
- Spend expression on a few named high-value moments; keep repetitive work surfaces quieter.
- Use contrasting shapes only when they clarify grouping, priority, state, or brand character.
- Use motion to show cause, continuity, hierarchy, and destination. It stays interruptible and has a
  reduced-motion equivalent.
- Keep expressive variants systematic across sibling components and states.
- Re-run hierarchy and accessibility checks after expression is added. Novelty does not compensate
  for a weak reading order or ambiguous control.

## 6. Implementation and review gate

Before code:

- confirm adoption boundary and target platform;
- identify the current Material library/version and authoritative component docs;
- map project tokens to Material roles without creating a second competing token source;
- choose adaptive structure and navigation behavior;
- list required component states and non-default screen states.

Before sign-off:

- inspect narrow and expanded layouts, not only one screenshot;
- test keyboard/touch, focus, pressed, selected, disabled, loading, error, and reduced motion as
  applicable;
- verify role pairs and state signals on the actual surfaces;
- confirm component variants match content and action weight;
- check that expressive shape, colour, and motion form one grammar rather than a sampler;
- record any divergence from official component behavior and the product reason for it.

Use `ui-design-system` for token mapping/coherence and `ui-design-review` for rendered sign-off.

## 7. Official sources

- [Material Design 3](https://m3.material.io/)
- [Foundations](https://m3.material.io/foundations)
- [Components](https://m3.material.io/components)
- [Interaction states](https://m3.material.io/foundations/interaction/states/overview)
- [Canonical layouts](https://m3.material.io/foundations/layout/canonical-examples/overview)

These links are the authority for current details; this reference deliberately avoids freezing
component measurements or release-specific inventories.
