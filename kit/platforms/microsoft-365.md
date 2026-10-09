# Microsoft 365 — OneDrive, SharePoint, Teams, Outlook

*Checked September 2026. Follow Microsoft's and Anthropic's current pages where they differ.*

## Can the harness files live here?

**Yes, in a OneDrive or SharePoint library synced to the computer by the OneDrive app.**

- **Keep the harness folder on the device.** OneDrive can leave files online-only until they are opened. Set the harness folder to always stay on the device, so the AI and the checks read real files.
- **Write harness files as plain text or markdown.** Word and Excel files are not text a script can check. Keep reference documents in Word if the team prefers, and read them through the connector.
- **Expect conflict copies** when two people edit at once. `doctor` flags them.

## Connecting the AI to what lives in Microsoft 365

**Claude apps.** The Microsoft 365 connector searches and reads SharePoint, OneDrive, Outlook and Teams. It is read-only unless write tools are explicitly enabled. It needs a Microsoft Entra tenant on a Microsoft business plan — personal Outlook or Hotmail accounts cannot connect — and a one-time consent from a Microsoft Entra Global Administrator. On Team and Enterprise plans the connector is enabled in organisation settings first; members then connect under **Customize → Connectors**.
Official page: <https://support.claude.com/en/articles/12542951-set-up-the-microsoft-365-connector>

**Claude Code and other MCP clients.** The connector above is set up through the Claude apps. For another tool, check Microsoft's current documentation for an official server before recommending anything, and record what you found.

## What to record in `config/connections.md`

The library or folder that holds the harness, the tenant admin who granted consent and when, whether write tools are on, and each document or list the harness reads.

## Checkpoint

No commit here. The finish-time hook where the AI tool runs hooks, and `bash scripts/checkpoint.sh` as the last step of every procedure. Library version history does not replace `learning/changelog.md`.
