# Notion

*Checked September 2026. Follow Notion's current page where it differs.*

## Can the harness files live here?

**No.** Notion pages cannot hold or run the harness's scripts. Keep the harness in a folder — a repository, a synced drive or a local folder — and leave the team's knowledge in Notion. Record each Notion page the harness depends on as an external foundation: the verdict is *skip — it lives in Notion*, never a stale copy (see `../packs/_scattered.md`).

## Connecting the AI

Notion runs an official hosted MCP server at `https://mcp.notion.com/mcp`, and it signs in with OAuth — there is no token to store. After someone authorises it, the AI can read **and update** whatever that person can access in the chosen workspace, so start with the person whose access matches what the harness should see.

**Claude Code:** `claude mcp add --transport http notion https://mcp.notion.com/mcp`, then run `/mcp` in a session to sign in. For a shared setup, the entry is in `templates/mcp.json.example`.

**Claude apps:** look for Notion under **Customize → Connectors**; if it is not listed, add a custom connector with the address above.

Official page: <https://developers.notion.com/guides/mcp/get-started-with-mcp>

## Limits worth saying out loud

- Sign-in must be completed interactively; a scheduled, unattended run cannot authorise itself.
- No script can check a Notion page. A foundation or procedure kept in Notion is reviewed by a person against its rubric. Write that into the architecture document.

## What to record in `config/connections.md`

Each Notion page or database the harness reads, whose access the connection uses, and whether writing is allowed for any procedure.
