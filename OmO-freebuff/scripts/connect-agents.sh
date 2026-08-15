#!/usr/bin/env bash
# connect-agents.sh — register MCP servers so Claude Code can reach the
# device's AI agents & tools (graphify, chrome-devtools, GitKraken, composio,
# freebuff). Idempotent: already-registered servers are skipped, so it is safe
# to run repeatedly and after every environment reset.
#
# Usage:
#   ./connect-agents.sh                      # register user-scope (default)
#   MCP_SCOPE=project ./connect-agents.sh    # write project .mcp.json instead
#
# Optional env:
#   COMPOSIO_API_KEY   registers the composio MCP server (needs a key)
#   FREEBUFF_MCP_URL   registers the Freebuff MCP server (needs a URL)
#   FREEBUFF_MCP_TOKEN optional bearer token for the Freebuff server
#   GITKRAKEN_BIN      path to the GitKraken CLI (auto-detected if unset)
set -u

SCOPE="${MCP_SCOPE:-user}"
CLAUDE_BIN="$(command -v claude || true)"

# --- colors (silent when piped) -------------------------------------------------
if [ -t 1 ]; then
  GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; CYAN=$'\033[0;36m'; RESET=$'\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi
log()  { printf '%s%s%s\n' "$CYAN" "$*" "$RESET"; }
ok()   { printf '%s✔ %s%s\n' "$GREEN" "$*" "$RESET"; }
warn() { printf '%s⚠ %s%s\n' "$YELLOW" "$*" "$RESET"; }
fail() { printf '%s✘ %s%s\n' "$RED" "$*" "$RESET" >&2; }

if [ -z "$CLAUDE_BIN" ]; then
  fail "claude CLI not found in PATH — install Claude Code first."
fi

log "== OmO core (as307/OmO): connecting Claude Code to agents (scope: $SCOPE) =="

# --- helpers ----------------------------------------------------------------
has_server() { "$CLAUDE_BIN" mcp get "$1" >/dev/null 2>&1; }

add_stdio() { # name cmd [args...]
  local name="$1"; shift
  if has_server "$name"; then ok "already registered: $name"; return 0; fi
  if "$CLAUDE_BIN" mcp add -s "$SCOPE" "$name" -- "$@"; then
    ok "registered: $name ($*)"
  else
    fail "could not register $name"
  fi
}

add_http() { # name url [header]
  local name="$1" url="$2"; shift 2
  if has_server "$name"; then ok "already registered: $name"; return 0; fi
  local -a extra=()
  [ -n "${1:-}" ] && extra=(-H "$1")
  if "$CLAUDE_BIN" mcp add -s "$SCOPE" --transport http "$name" "$url" "${extra[@]}"; then
    ok "registered: $name ($url)"
  else
    fail "could not register $name"
  fi
}

# --- 1) graphify — local knowledge-graph MCP (tools + resources) ---------------
if command -v graphify-mcp >/dev/null 2>&1; then
  add_stdio graphify graphify-mcp
else
  warn "graphify-mcp not found in PATH — skipping (uv tool install graphifyy)"
fi

# --- 2) chrome-devtools — browser automation MCP --------------------------------
add_stdio chrome-devtools npx -y chrome-devtools-mcp@latest

# --- 3) GitKraken — git/GitHub MCP (only if the CLI is installed) --------------
# Reuse the existing 'GitKraken' registration if present (avoids duplicates).
if has_server GitKraken; then
  ok "already registered: GitKraken"
elif has_server gitkraken; then
  ok "already registered: gitkraken"
else
  GK="${GITKRAKEN_BIN:-/home/yaman/.config/Code/User/globalStorage/eamodio.gitlens/gk}"
  if [ -x "$GK" ]; then
    add_stdio gitkraken "$GK" mcp --host=claude-cli
  else
    warn "GitKraken CLI not found at $GK — skipping (set GITKRAKEN_BIN)"
  fi
fi

# --- 4) composio — 250+ app integrations (needs COMPOSIO_API_KEY) --------------
if [ -n "${COMPOSIO_API_KEY:-}" ]; then
  if has_server composio; then
    ok "already registered: composio"
  elif "$CLAUDE_BIN" mcp add -s "$SCOPE" composio \
         -e "COMPOSIO_API_KEY=$COMPOSIO_API_KEY" -- npx -y @composio/mcp@latest; then
    ok "registered: composio (npx @composio/mcp@latest)"
  else
    fail "could not register composio"
  fi
else
  warn "COMPOSIO_API_KEY not set — skipping composio (export it, then re-run)"
fi

# --- 5) freebuff — the remote Freebuff agent (needs FREEBUFF_MCP_URL) ----------
if [ -n "${FREEBUFF_MCP_URL:-}" ]; then
  if [ -n "${FREEBUFF_MCP_TOKEN:-}" ]; then
    add_http freebuff "$FREEBUFF_MCP_URL" "Authorization: Bearer $FREEBUFF_MCP_TOKEN"
  else
    add_http freebuff "$FREEBUFF_MCP_URL"
  fi
else
  warn "FREEBUFF_MCP_URL not set — skipping freebuff (export it, then re-run)"
fi

# --- 6) health check ------------------------------------------------------------
echo
log "== MCP server status =="
"$CLAUDE_BIN" mcp list
echo
ok "Done. Run 'claude mcp list' any time to re-check."
