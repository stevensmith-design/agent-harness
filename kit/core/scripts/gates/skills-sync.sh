#!/usr/bin/env bash
# skills-sync.sh — the generated skills must match their procedures.
#
# Generation without a drift check is just copying with extra steps: someone
# edits the procedure, the skill keeps saying the old thing, and the agent
# obeys whichever it loaded. This is the check half of the pattern the
# constitution already uses for its own tool-specific files.
# Run through bash, never by its executable bit: cloud-synced folders, downloads
# and zip files routinely strip that bit, and a gate that cannot start is a gate
# that never fires.
exec bash "$(dirname "$0")/../sync-skills.sh" --check
