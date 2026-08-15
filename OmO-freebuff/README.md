# OmO-freebuff — Claude Code ↔ device agents bridge

This is Buffy's (Freebuff agent) take on connecting **Claude Code** to the AI
agents and tools on this device, built for the
[`as307/OmO`](https://github.com/as307/OmO) repo (workspace: `~/OmO/core`) so
it works when the repo is opened in a GitHub Codespace.

## What's inside

| File | Purpose |
| --- | --- |
| `.mcp.json` | Project-scoped MCP config (copy to repo root to activate for everyone who clones). Only portable, credential-free servers live here so it always health-checks green. |
| `scripts/connect-agents.sh` | Idempotent installer — registers the full agent mesh at **user scope** in `~/.claude.json` via `claude mcp add`. Safe to re-run; skips what's already registered. |

## What gets connected

| Server | What it gives Claude | When it's registered |
| --- | --- | --- |
| `graphify` | Local knowledge-graph MCP (query/path/explain over codebases, tools + resources) | Always (fixed: was missing the `mcp` module in its uv env) |
| `chrome-devtools` | Browser automation, screenshots, network/perf analysis | Always |
| `gitkraken` | Git + GitHub operations | If the GitKraken CLI is installed (reuses existing `GitKraken` registration) |
| `composio` | 250+ app integrations (Slack, Gmail, Notion, …) | If `COMPOSIO_API_KEY` is set |
| `freebuff` | The remote Freebuff/Buffy agent | If `FREEBUFF_MCP_URL` is set |

## How to use

```bash
# 1. Register all available servers (user scope, idempotent)
./OmO-freebuff/scripts/connect-agents.sh

# 2. With credentials (add to ~/.bashrc or the Codespace secrets):
export COMPOSIO_API_KEY="..."
export FREEBUFF_MCP_URL="https://..."
export FREEBUFF_MCP_TOKEN="..."   # optional bearer token
./OmO-freebuff/scripts/connect-agents.sh

# 3. Activate the project-scoped config for everyone cloning the repo:
cp OmO-freebuff/.mcp.json .mcp.json   # commit this

# 4. Verify
claude mcp list
```

## Current status (as of setup)

```
graphify:        graphify-mcp                  ✔ Connected
chrome-devtools: npx chrome-devtools-mcp@latest ✔ Connected
GitKraken:       gk mcp --host=claude-cli      ✔ Connected
domotz:          https://mcp.domotz.com/mcp     ✔ Connected
composio:        skipped (no COMPOSIO_API_KEY)  — set the key, re-run
freebuff:        skipped (no FREEBUFF_MCP_URL)  — paste the URL, re-run
```

## Design notes (why this is a good setup)

- **Idempotent** — safe to run after every environment reset or `git clean`.
- **Green by default** — the committed `.mcp.json` has no servers that need
  credentials, so nothing fails health checks in a fresh Codespace.
- **Secrets stay out of git** — keyed servers are registered from env vars by
  the script, never committed.
- **Self-healing** — the script detects and reports missing/broken tools
  (e.g. graphify-mcp was broken; this setup fixed it and registers it).
- **No duplicates** — reuses the pre-existing `GitKraken` registration instead
  of registering a second copy.

## Not MCP (for reference)

- **OmniRouter** (`http://127.0.0.1:20128`) — OpenAI-compatible LLM gateway,
  not an MCP server. Point Claude Code at it via
  `export ANTHROPIC_BASE_URL="http://127.0.0.1:20128"` if you want to route
  Claude's model calls through it. Start it with `~/start-router.sh`.
