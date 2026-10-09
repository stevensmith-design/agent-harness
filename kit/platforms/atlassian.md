# Atlassian — Confluence and Jira

*Checked September 2026. Follow Atlassian's current page where it differs.*

## Can the harness files live here?

**No.** Confluence pages cannot hold or run scripts. Keep the harness in a folder, and read Confluence and Jira through Atlassian's connector. A Confluence space is often the richest source of foundations and decision records — adopt what is there as external sources rather than copying it.

## Connecting the AI

Atlassian runs an official remote MCP server at `https://mcp.atlassian.com/v2/mcp`, covering Confluence, Jira, Jira Service Management and more. It signs in with OAuth 2.1 by default. API tokens work only where an organisation admin has enabled them, and Jira Service Management needs one. Organisation admins control which AI tools may connect, and IP allowlisting still applies.

**Claude Code:** `claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp`, then run `/mcp` in a session to sign in. The shared entry is in `templates/mcp.json.example`.

**Claude apps:** search for Atlassian in the app's connector directory and install it there.

Official page: <https://atlassian.github.io/atlassian-mcp-server/>

## What to record in `config/connections.md`

The spaces and projects the harness reads, the admin who allowed the connection, whether it signs in with OAuth or an API token (never the token itself), and any write access.

## Checkpoint

The harness folder carries the checkpoint. Content in Confluence is checked by a reviewer against its rubric.
