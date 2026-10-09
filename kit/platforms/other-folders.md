# Dropbox, Box, iCloud Drive and a local folder

*Checked September 2026.*

## Can the harness files live here?

**Yes.** Any folder that is really on the computer works, synced or not.

- **Make sure files are on the device, not online-only.** Each sync app has a setting to keep a folder available offline. Use it for the harness folder, so the AI and the checks read real files.
- **Expect conflict copies** in any synced folder when two people edit at once — "conflicted copy" names, numbered copies. `doctor` flags them.
- **A local folder that nobody else uses** is fine for one person. Back it up; nothing else will.

## Connecting the AI to what lives there

If the harness folder is also where the documents are, the AI reads them directly — no connector needed. For content elsewhere in these services, check the vendor's current documentation for an official connector or MCP server before recommending one, and record what you found.

## Checkpoint

No commit here. The finish-time hook where the AI tool runs hooks, and `bash scripts/checkpoint.sh` as the last step of every procedure. File version history in these services can recover a file; it does not record which rules changed together, so keep `learning/changelog.md`.

## Moving to a repository later

The layout is identical, so it is a move, not a rewrite: `git init` in the folder, commit, and turn on the commit checkpoint. See `../SUBSTRATES.md`.
