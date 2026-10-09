# Google Workspace — Drive, Docs, Sheets

*Checked September 2026. Follow Google's and Anthropic's current pages where they differ.*

## Can the harness files live here?

**Yes, in a Drive folder synced to the computer by Google Drive for desktop.**

- **Keep the harness folder available offline.** Drive for desktop streams files by default, so a file may not really be on disk until it is opened. Mark the harness folder available offline (or mirror it) so the AI and the checks read real files.
- **Write harness files as plain text or markdown.** A native Google Doc, Sheet or Slides file appears in the synced folder as a small link file (`.gdoc`, `.gsheet`, `.gslides`), not its content. Neither the AI nor a script can read it from there. `doctor` fails if one sits inside a folder the AI is meant to read, and `detect.sh` counts them.
- **Expect conflict copies** when two people edit at once. `doctor` flags a numbered copy that sits beside its original.

## Connecting the AI to what lives in Drive

**Claude apps (web, desktop).** The Google Drive connector reads Google Docs, Sheets, Slides, PDFs and Office files — text only, embedded images are not processed. Actions that change Drive ask for approval first. On Team and Enterprise plans an Owner must enable the connector before members can connect. Members connect under **Customize → Connectors**.
Official page: <https://support.claude.com/en/articles/10166901-use-google-workspace-connectors>

**Claude Code and other MCP clients.** Google publishes official MCP servers for Drive, Docs, Sheets, Slides, Gmail, Calendar and Chat. As of this check they are a **Developer Preview**: they need a Google Cloud project, the matching APIs enabled, and your own OAuth client. That is an admin-level decision; recommend it and link the page, do not set it up for them.
Official page: <https://developers.google.com/workspace/guides/configure-mcp-servers>

## What to record in `config/connections.md`

The Drive folder that holds the harness, who owns it, and each Doc or Sheet the harness reads as a foundation — by title and link, with the connector used to read it.

## Checkpoint

No commit here. The finish-time hook where the AI tool runs hooks, and `bash scripts/checkpoint.sh` as the last step of every procedure. Drive's per-file version history helps you recover a file, but it is not a record of which rules changed together — keep `learning/changelog.md` up to date.
