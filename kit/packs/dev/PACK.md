# Pack: Development

**Status:** complete. The universal harness is a complete, hardened implementation of this pack, with self-tested gates and stack adapters. Do not rebuild it; instantiate it.

**Location:** `universal/` at the root of this repository.

## The verbs

`lint · format · typecheck · test · build` — supplied by a stack adapter so no gate and no CI file needs to know the stack. Six ship: `generic · react-web · react-native · flutter · node-api · python-api`.

**A verb you genuinely do not have stays undefined** — skipped with a warning, which is honest. A verb stubbed out to pass is a lie the harness will repeat for a year.

## The foundations

Stack · source and test roots · accepted architecture decisions · API contracts · design tokens (if there is a UI) · the requirement register.

## Starting rung: **L2**

Code is the one domain where the standard is largely mechanical on day one — it compiles or it does not, the test passes or it does not, the token is used or a raw hex is. The check is writable before the corpus exists.

**Exception:** anything about *craft* — is this the right abstraction, is this readable — is judgement, and belongs at L1 with a human gate until the corpus says otherwise.

## What this pack adds beyond core

- Stack adapters, and generated CI rendered from config
- `spec → plan → tasks`, and a requirement register where status lives (**the PRD stays narrative and holds no mutable state**)
- Branch and commit hygiene gates
- Supply-chain gates: pinned actions, lockfiles, template files that must contain only placeholders
- Deploy modules per target, with the human gate between deploy and traffic cutover

## Facts worth not re-deriving

- **Supabase migrations have no rollback.** Recovery is restore plus a compensating forward migration.
- **Cloud Run is the only common deploy target with a real rollback** — immutable revisions, traffic is a pointer.
- **Vercel has no keyless path in.** OIDC is outbound only; the token is long-lived.
- **Generated files must never also be inputs.** A tool file whose tail was read back out of itself let an injected instruction survive regeneration, invisibly.
