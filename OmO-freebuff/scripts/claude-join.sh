#!/usr/bin/env bash
# =============================================================================
# claude-join.sh — start a Claude Code session JOINED to the OmO stack.
#
#   ./scripts/claude-join.sh              # team-memory mode (default)
#   ./scripts/claude-join.sh memory       # team-memory injection (Memory Hub proxy)
#   ./scripts/claude-join.sh gateway      # shared LLM gateway (OmniRouter)
#   ./scripts/claude-join.sh normal       # plain claude (env vars cleared)
#
# What the modes do (this does NOT change your default ~/.claude config —
# the env vars only apply to the session this script launches):
#
#   memory   ANTHROPIC_BASE_URL=http://127.0.0.1:8096/claude-code/default
#            ANTHROPIC_AUTH_TOKEN=<Memory Hub admin key>
#            → Claude runs through the Memory Hub proxy: auth + session init
#              + team memory / skill / knowledge injection into the prompt.
#              Upstream model comes from the stack .env (PROXY_UPSTREAM_MODEL).
#
#   gateway  ANTHROPIC_BASE_URL=http://127.0.0.1:20128
#            → Claude routes model calls through OmniRouter, the same gateway
#              Dify/gpt-researcher use (models: auto/best-chat, auto/best-coding…).
#
# Env: TDAI_DIR (stack dir, default ~/tencentdb-agent-memory),
#      OMNIROUTER_URL, OMNIROUTER_API_KEY, CLAUDE_BIN
# =============================================================================
set -uo pipefail

if [ -t 1 ]; then
  GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; CYAN=$'\033[0;36m'; RESET=$'\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi
log()  { printf '%s%s%s\n' "$CYAN" "$*" "$RESET"; }
ok()   { printf '%s✔ %s%s\n' "$GREEN" "$*" "$RESET"; }
warn() { printf '%s⚠ %s%s\n' "$YELLOW" "$*" "$RESET"; }
fail() { printf '%s✘ %s%s\n' "$RED" "$*" "$RESET" >&2; exit 1; }

MODE="${1:-memory}"
shift  # remove the mode from "$@" so it is not passed to claude
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || true)}"
[[ -n "$CLAUDE_BIN" ]] || fail "claude CLI not found in PATH"
TDAI_DIR="${TDAI_DIR:-$HOME/tencentdb-agent-memory}"
OMNIROUTER_URL="${OMNIROUTER_URL:-http://127.0.0.1:20128}"
OMNIROUTER_API_KEY="${OMNIROUTER_API_KEY:-local-key}"
KEY_FILE="$TDAI_DIR/deploy/global-images/.admin-key"

case "$MODE" in
  memory)
    [[ -s "$KEY_FILE" ]] || fail "Memory Hub admin key not found at $KEY_FILE (start the stack first)"
    curl -sf -m 5 -o /dev/null "$TDAI_DIR/deploy/global-images/.admin-key" 2>/dev/null \
      || curl -sf -m 5 -o /dev/null "http://127.0.0.1:8096/health" \
      || warn "proxy at :8096 not responding — is the Memory Hub stack up?"
    ADMIN_KEY="$(cat "$KEY_FILE")"
    export ANTHROPIC_BASE_URL="http://127.0.0.1:8096/claude-code/default"
    export ANTHROPIC_AUTH_TOKEN="$ADMIN_KEY"
    log "Claude joined via Memory Hub proxy (:8096) — team memory/skills injected."
    log "  upstream: see PROXY_UPSTREAM_MODEL in $TDAI_DIR/deploy/global-images/.env"
    ;;
  gateway)
    curl -sf -m 10 -o /dev/null -H "Authorization: Bearer $OMNIROUTER_API_KEY" "$OMNIROUTER_URL/v1/models" \
      || warn "OmniRouter at $OMNIROUTER_URL not responding — start it: ~/start-router.sh"
    export ANTHROPIC_BASE_URL="$OMNIROUTER_URL"
    log "Claude joined via OmniRouter gateway ($OMNIROUTER_URL) — same models as Dify."
    ;;
  normal)
    unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
    log "Plain Claude — default model routing."
    ;;
  *)
    echo "usage: $0 [memory|gateway|normal]" >&2; exit 1 ;;
esac

exec "$CLAUDE_BIN" "$@"
