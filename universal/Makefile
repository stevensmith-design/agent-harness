# Universal Harness — the command surface.
#
# One vocabulary for humans and agents. Real toolchain commands live only in
# scripts/adapters/<adapter>.sh; nothing here knows your stack. Agents are told
# to go through `make` so options stay consistent and there is one place to
# change how something runs.

.DEFAULT_GOAL := help
SHELL := /bin/bash
RUN := ./scripts/run.sh

.PHONY: help setup env-init install-hooks deps dev dev-mock check lint format \
        format-check typecheck test cov codegen codegen-watch build e2e verify \
        check-tokens check-secrets check-data check-spec check-protected check-budget check-branch \
        check-rules check-supply pin-actions migrate migrate-status migrate-new db-reset \
        ci-gen ci-gen-check deploy deploy-plan deploy-promote deploy-rollback deploy-status \
        harness-package doctor requirements-check check-product \
        harness-sync harness-sync-check harness-verify harness-init \
        tier-explore tier-build tier-release skills-list skills-add skills-verify \
        skills-update skills-vendored check-skills \
        governance-check evals ci check-hooks check-evidence findings \
        check-invariants check-learning check-api check-agreements retro-evidence render-audit

help: ## List every command
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

## ---------- Setup ----------
setup: env-init install-hooks link-skills ## Prepare the harness without installing third-party code
	@echo
	@$(MAKE) --no-print-directory doctor
	@echo
	@echo "→ next: 'make harness-init', then run /harness-dependency-intake before 'make deps'"

doctor: ## What this machine is missing, and how to fix it
	@./scripts/doctor.sh

env-init: ## Create .env from .env.sample if missing
	@[ -f .env ] || cp .env.sample .env; echo ".env ready"

install-hooks: ## Point git at .githooks
	@cur=$$(git config --get core.hooksPath 2>/dev/null || true); \
	if [ -n "$$cur" ] && [ "$$cur" != ".githooks" ]; then \
	  echo "! core.hooksPath is already '$$cur' (husky/lefthook?). Not overwriting it."; \
	  echo "  Chain the harness hook from yours, or run: git config core.hooksPath .githooks"; \
	else \
	  git config core.hooksPath .githooks && chmod +x .githooks/* 2>/dev/null; echo "hooks installed"; \
	fi

link-skills: ## Symlink .agents/skills into .claude/skills (one tree, many tools)
	@mkdir -p .claude/skills .claude/rules
	@# `[ -d "$$d" ] ||continue` is load-bearing: with .agents/ absent the glob
	@# expands to itself and this used to create symlinks literally named '*',
	@# which harness-verify then reported forever and link-skills could not repair.
	@for d in .agents/skills/*/; do [ -d "$$d" ] || continue; n=$$(basename $$d); t=".claude/skills/$$n"; \
	  if [ -e "$$t" ] && [ ! -L "$$t" ]; then rm -rf "$$t"; fi; \
	  [ -L "$$t" ] || ln -s "../../$$d" "$$t"; done
	@for f in .agents/rules/*.md; do [ -f "$$f" ] || continue; n=$$(basename $$f); t=".claude/rules/$$n"; \
	  if [ -e "$$t" ] && [ ! -L "$$t" ]; then rm -f "$$t"; fi; \
	  [ -L "$$t" ] || ln -s "../../$$f" "$$t"; done
	@# Clean up the literal-glob symlinks an older version could leave behind.
	@rm -f ".claude/skills/*" ".claude/rules/*.md" 2>/dev/null || true
	@echo "skills + rules linked"

deps: ## Install dependencies (adapter)
	@$(RUN) deps

## ---------- Run ----------
dev: ## Run the app against real services
	@$(RUN) dev
dev-mock: ## Run against stubs — no backend needed (see docs/mock-mode.md)
	@$(RUN) dev_mock

retro-evidence: ## What happened since the last retro, and whether one is due (writes nothing)
	@./scripts/retro-evidence.sh

## ---------- Deterministic gates ----------
check: ## Everything CI runs
	@# `: >` not `rm -f`: truncating is idempotent and needs no delete rights,
	@# which matters in sandboxes and CI images where the runner cannot unlink.
	@mkdir -p .agents/runs && : > .agents/runs/.stubs
	@HARNESS_STUB_SUMMARY=end $(MAKE) --no-print-directory check-all
	@./scripts/check-summary.sh
check-overlay-gates: ## Run the gates declared by any applied overlay
	@for g in $$(./scripts/overlay.sh gates); do \
	  [ -x "scripts/gates/$$g.sh" ] || { echo "✗ overlay declares gate '$$g' but scripts/gates/$$g.sh is missing or not executable"; exit 1; }; \
	  ./scripts/gates/$$g.sh || exit 1; \
	done
check-all: lint format-check typecheck test check-tokens check-design check-secrets check-data check-spec check-budget check-branch check-rules check-supply check-skills check-product check-invariants check-learning check-api check-agreements check-policy check-protected check-hooks check-overlay-gates

lint: ## Static analysis (adapter)
	@$(RUN) lint
format: ## Auto-format (adapter)
	@$(RUN) format
format-check: ## Verify formatting, change nothing (adapter)
	@$(RUN) format_check
typecheck: ## Type check (adapter)
	@$(RUN) typecheck
test: ## Run tests (adapter)
	@$(RUN) test
cov: ## Tests with coverage (adapter)
	@$(RUN) coverage
e2e: ## End-to-end tests (adapter)
	@$(RUN) e2e

check-tokens: ## Design-token drift gate (raw hex, magic numbers)
	@./scripts/gates/design-tokens.sh
check-design: ## Design-system coherence — do the tokens actually relate correctly?
	@./scripts/gates/design-system.sh
check-secrets: ## Secret scan
	@./scripts/gates/secret-scan.sh
check-data: ## Sensitive paths and structured personal data
	@./scripts/gates/data-boundary.sh
check-spec: ## Fail while any [NEEDS CLARIFICATION] remains
	@./scripts/gates/spec-clarity.sh
check-branch: ## Branch name, commit shape, and branch size
	@./scripts/gates/branch-hygiene.sh
check-rules: ## Every rule actually loads (no dead path globs)
	@./scripts/gates/rule-coverage.sh
check-supply: ## CI pins, dependency sources/scripts, templates, lockfiles
	@./scripts/gates/supply-chain.sh
	@./scripts/gates/dependency-safety.sh
check-product: ## Requirement register integrity
	@./scripts/gates/requirements.sh
requirements-check: check-product ## Alias for check-product
check-invariants: ## Invariant register: every domain rule names the side that enforces it
	@./scripts/gates/invariants.sh
check-learning: ## Questions close into rules; every defect names its gap, sweep and lesson
	@./scripts/gates/learning.sh
render-audit: ## Measure rendered pages (tap targets, text size, overflow, overlap) at phone and desktop width; writes a contact sheet
	@pages=$$(grep -vE '^[[:space:]]*(#|$$)' docs/quality/render-pages.txt 2>/dev/null | sed "s|^/|$${RENDER_BASE_URL:-http://localhost:3000}/|"); \
	  [ -n "$$pages" ] || { echo "✗ no pages in docs/quality/render-pages.txt — list the screens to audit, with the stress fixture loaded"; exit 2; }; \
	  node scripts/render-audit.mjs $$pages
check-api: ## Every proposed operation carries a status and a unique operationId
	@./scripts/gates/api-contract.sh
check-agreements: ## An agreed API shape has not moved without a ledger row
	@./scripts/gates/api-agreements.sh
check-skills: ## Skills: portable metadata, trusted instructions, licence + pin integrity
	@./scripts/gates/skill-frontmatter.sh
	@./scripts/gates/skill-trust.sh
	@./scripts/gates/skills-integrity.sh
	@./scripts/gates/skill-namespace.sh
	@./scripts/verify-harness.sh --portability
check-protected: ## Fail if a PR mixes harness and product changes
	@./scripts/gates/protected-paths.sh
check-policy: ## Resolve the change to its surfaces and apply that surface's rung
	@./scripts/gates/policy.sh
check-budget: ## Instruction-file size budgets
	@./scripts/gates/instruction-budget.sh
check-hooks: ## Every hook declares the CI gate that enforces the same rule
	@./scripts/gates/hook-parity.sh
check-evidence: ## A run that changed source left an evidence record (warns locally, fails in CI)
	@./scripts/gates/evidence.sh
findings: ## Findings on this branch, with stale ones flagged
	@./scripts/finding.sh list
overlay-list: ## What overlays exist, and which are applied
	@./scripts/overlay.sh list
overlay-apply: ## Apply an overlay: make overlay-apply NAME=ai-product
	@./scripts/overlay.sh apply "$${NAME:?NAME= required}"
overlay-verify: ## Applied overlays: sources unchanged, base still compatible
	@./scripts/overlay.sh verify
gate-selftest: ## Prove every gate REJECTS what it exists to reject
	@./scripts/gate-selftest.sh
install-into: ## Install this harness into another repo: make install-into DEST=../app
	@./scripts/install.sh "$${DEST:?DEST= required}"

## ---------- Database (adapter; omit these verbs for a project with none) ----------
migrate: ## Apply pending migrations
	@$(RUN) migrate
migrate-status: ## Show which migrations have run
	@$(RUN) migrate_status
migrate-new: ## Scaffold a migration: make migrate-new NAME=add_x
	@$(RUN) migrate_new "$${NAME:?NAME= required}"
db-reset: ## Drop and rebuild the LOCAL database (refuses non-local DATABASE_URL)
	@$(RUN) db_reset

## ---------- Build / evidence ----------
codegen: ## Run code generation (adapter)
	@$(RUN) codegen
codegen-watch: ## Watch and regenerate (adapter)
	@$(RUN) codegen_watch
build: ## Production build (adapter)
	@$(RUN) build
verify: ## Prove the app actually runs, and record the evidence
	@./scripts/verify.sh

## ---------- The harness itself ----------
harness-init: ## Interactive fill-in of harness.config.yaml
	@./scripts/harness-init.sh
pin-actions: ## Resolve CI action tags to commit SHAs (a tag is mutable; a SHA is not)
	@./scripts/pin-actions.sh
ci-gen: ## Render CI files from harness.config.yaml (github/gitlab/bitrise)
	@./scripts/ci-gen.sh
ci-gen-check: ## Fail if a generated CI file has drifted
	@./scripts/ci-gen.sh --check

## ---------- Deploy (targets in scripts/deploy/) ----------
deploy-plan: ## Show what would change. ENV=preview|staging|production
	@./scripts/deploy.sh $${ENV:-preview} plan
deploy: ## Deploy. ENV=… — production also needs DEPLOY_CONFIRM=1
	@./scripts/deploy.sh $${ENV:-preview} apply
deploy-promote: ## Cut traffic over to what was deployed. ENV=…
	@./scripts/deploy.sh $${ENV:-preview} promote
deploy-rollback: ## Return to the previous good state. ENV=…
	@./scripts/deploy.sh $${ENV:-preview} rollback
deploy-status: ## What is live right now. ENV=…
	@./scripts/deploy.sh $${ENV:-preview} status
harness-package: ## Build harness-init.skill from this tree (a build artifact, not a source file)
	@./scripts/package-skill.sh $${OUT:-}
harness-sync: ## Regenerate CLAUDE.md / .cursor/rules / copilot instructions
	@./scripts/harness-sync.sh
harness-sync-check: ## Fail if any generated tool file has drifted
	@./scripts/harness-sync.sh --check
harness-verify: ## Is the harness intact? LEVEL=1|2|3
	@./scripts/verify-harness.sh --level $${LEVEL:-2}

tier-explore: ## Read-only permission tier
	@cp .claude/tiers/explore.settings.json .claude/settings.json && echo "tier: explore (read-only)"
tier-build: ## Default working tier
	@cp .claude/tiers/build.settings.json .claude/settings.json && echo "tier: build"
tier-release: ## Adds push/deploy, behind approval
	@cp .claude/tiers/release.settings.json .claude/settings.json && echo "tier: release"

skills-list: ## List available skills
	@for f in .agents/skills/*/SKILL.md; do \
	  printf "  \033[36m%-18s\033[0m %s\n" "$$(basename $$(dirname $$f))" \
	  "$$(grep -m1 '^description:' $$f | cut -c14- | cut -c1-80)"; done
skills-add: ## Vendor a capability skill. REPO=owner/repo SKILL=path [REF=tag]
	@./scripts/skills.sh add "$${REPO:?REPO= required}" "$${SKILL:?SKILL= required}" $${REF:+--ref $$REF}
skills-verify: ## Vendored skills still match their pins
	@./scripts/skills.sh verify
skills-update: ## Re-pin vendored skills deliberately. NAME= for one
	@./scripts/skills.sh update $${NAME:-}
skills-vendored: ## What is vendored, with licence and pin
	@./scripts/skills.sh list

## ---------- Opt-in modules ----------
governance-check: ## L3: validate governance records against schemas + semantic rules
	@python3 .harness/scripts/validate_governance.py --all
evals: ## L4: run the eval cases (exit 2 = judge scorers ungraded, which is not a pass)
	@./evals/run-evals.sh

ci: check harness-sync-check ci-gen-check harness-verify overlay-verify gate-selftest check-evidence ## What CI runs
