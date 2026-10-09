# Slack

*Checked September 2026. Follow Slack's current page where it differs.*

## Can the harness files live here?

**No — Slack is context, not a home.** It is where a team's real rules often hide: pinned messages, channel canvases, the thread where a decision was actually made. Read it to find foundations and decisions, then record what you found in the harness.

## Connecting the AI

Slack runs an official MCP server at `https://mcp.slack.com/mcp`. A **workspace admin must approve** the integration before anyone can connect.

**Claude apps:** **Customize → Connectors**, add Slack, and sign in.

**Claude Code:** install Slack's plugin — `claude plugin install slack` — which configures the server and prompts for sign-in.

Official page: <https://docs.slack.dev/ai/slack-mcp-server/connect-to-claude/>

## Rules for reading Slack

- **Read-only while gathering context.** Never post, react or edit — see `../scope/context.md`.
- **Summarise and cite; never copy people's messages** into foundations.
- **Sample, don't crawl.** Start with the channels the person names.

## What to record in `config/connections.md`

The channels read, the admin who approved the integration, and the date. Decisions found in Slack become decision records in the harness, with a link to the thread.
