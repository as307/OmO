#!/usr/bin/env bash
# =============================================================================
#  NEXUS AI MARKETING AGENCY — EXECUTABLE FINALIZE BLUEPRINT
#  OmO core workspace · run once on a local device / GitHub Codespace
# =============================================================================
#  What this does (4 stages, all idempotent):
#   1. CONNECT   — register MCP servers so Claude Code reaches the device's
#                  agents/tools (graphify, chrome-devtools, GitKraken, …)
#   2. BOOT      — start the Memory Hub stack (memory-core + hub + proxy)
#                  with the filtered dashboard image when available
#   3. PROVISION — create the Nexus Marketing Agency team: 5 agents,
#                  6 skills, 3 tasks, kickoff memory, per-agent API keys
#   4. REPORT    — print endpoints, credentials, and connection status
#
#  Usage:
#    ./blueprint.sh              # run everything
#    ./blueprint.sh --dry-run    # print the plan, change nothing
#    ./blueprint.sh --stack-dir /path/to/TencentDB-Agent-Memory
#    ./blueprint.sh --skip-claude --skip-stack --skip-team   # selective
#  Env: TDAI_DIR, ADMIN_KEY, API_BASE, INSTANCE
# =============================================================================
set -uo pipefail

# --- helpers ---------------------------------------------------------------
if [ -t 1 ]; then
  GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; CYAN=$'\033[0;36m'; RESET=$'\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi
log()  { printf '%s%s%s\n' "$CYAN" "$*" "$RESET"; }
ok()   { printf '%s✔ %s%s\n' "$GREEN" "$*" "$RESET"; }
warn() { printf '%s⚠ %s%s\n' "$YELLOW" "$*" "$RESET"; }
fail() { printf '%s✘ %s%s\n' "$RED" "$*" "$RESET" >&2; }
step() { echo; printf '%s── %s ────────────────────────────────────────%s\n' "$CYAN" "$*" "$RESET"; }

DRY_RUN=0
SKIP_CLAUDE=0
SKIP_STACK=0
SKIP_TEAM=0
TDAI_DIR="${TDAI_DIR:-$HOME/tencentdb-agent-memory}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)        DRY_RUN=1 ;;
    --skip-claude)    SKIP_CLAUDE=1 ;;
    --skip-stack)     SKIP_STACK=1 ;;
    --skip-team)      SKIP_TEAM=1 ;;
    --stack-dir)      TDAI_DIR="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

run() { # cmd... — dry-run aware
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '   [dry] %s\n' "$*"
    return 0
  fi
  "$@"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

# =============================================================================
log "NEXUS AI MARKETING AGENCY — finalize blueprint"
log "  workspace : $REPO_ROOT"
log "  stack dir : $TDAI_DIR"
log "  dry run   : $([ $DRY_RUN -eq 1 ] && echo yes || echo no)"
# =============================================================================

# --- stage 0 · environment -----------------------------------------------------
step "Stage 0 · environment check"
for bin in curl python3; do
  command -v "$bin" >/dev/null 2>&1 || { fail "missing required tool: $bin"; exit 1; }
done
CLAUDE_BIN="$(command -v claude || true)"
DOCKER_BIN="$(command -v docker || true)"
if [[ -z "$DOCKER_BIN" ]]; then
  warn "docker/podman not found — stack stage will be skipped"
  SKIP_STACK=1
fi
[[ -n "$CLAUDE_BIN" ]] && ok "claude CLI: $CLAUDE_BIN" || warn "claude CLI not found — connect stage skipped"
[[ -n "$DOCKER_BIN" ]] && ok "container runtime: $DOCKER_BIN"
ok "python3 + curl present"

# --- stage 1 · connect Claude to agents -----------------------------------------
if [[ $SKIP_CLAUDE -eq 0 && -n "$CLAUDE_BIN" && -x "$REPO_ROOT/OmO-freebuff/scripts/connect-agents.sh" ]]; then
  step "Stage 1 · connect Claude Code to device agents (MCP)"
  run bash "$REPO_ROOT/OmO-freebuff/scripts/connect-agents.sh"
  [[ $DRY_RUN -eq 1 ]] || {
    ok "MCP servers registered — 'claude mcp list' shows the mesh"
    warn "composio / freebuff need COMPOSIO_API_KEY / FREEBUFF_MCP_URL — set and re-run if you have them"
  }
else
  [[ $DRY_RUN -eq 1 ]] || warn "Stage 1 skipped (missing claude CLI or OmO-freebuff script)"
fi

# --- stage 2 · boot the Memory Hub stack ------------------------------------------
if [[ $SKIP_STACK -eq 0 && -n "$DOCKER_BIN" ]]; then
  step "Stage 2 · boot Memory Hub stack"
  if [[ ! -d "$TDAI_DIR/deploy/global-images" ]]; then
    warn "stack source not at $TDAI_DIR — cloning upstream"
    run git clone --depth 1 https://github.com/TencentCloud/TencentDB-Agent-Memory.git "$TDAI_DIR" \
      || { fail "clone failed — set TDAI_DIR to an existing checkout"; exit 1; }
  fi
  ENV_FILE="$TDAI_DIR/deploy/global-images/.env"
  if [[ ! -f "$ENV_FILE" ]]; then
    run cp "$TDAI_DIR/deploy/global-images/.env.example" "$ENV_FILE"
    fail "create $ENV_FILE from .env.example and fill the LLM keys, then re-run"
    exit 1
  fi
  # Prefer the locally-built filtered hub image (keeps the dashboard filter live).
  FILTERED_IMAGE="localhost/memory-hub-filtered:latest"
  if run bash -c "docker image inspect '$FILTERED_IMAGE' >/dev/null 2>&1"; then
    ok "using filtered dashboard image: $FILTERED_IMAGE"
    run cp "$ENV_FILE" "$ENV_FILE.bp-bak"
    run sed -i "s|^MEMORY_HUB_IMAGE=.*|MEMORY_HUB_IMAGE=$FILTERED_IMAGE|" "$ENV_FILE"
  else
    warn "no local filtered image — hub will use the image in .env (dashboard filter not included)"
  fi
  run bash "$TDAI_DIR/deploy/global-images/start-all.sh"
  run cp "$ENV_FILE.bp-bak" "$ENV_FILE" 2>/dev/null || true
  ok "stack started (memory-core :8420 · hub :8125/:8424 · proxy :8096)"
else
  [[ $DRY_RUN -eq 1 ]] || warn "Stage 2 skipped"
fi

# --- stage 3 · provision the agency team -------------------------------------------
if [[ $SKIP_TEAM -eq 0 ]]; then
  step "Stage 3 · provision Nexus Marketing Agency team"
  TEAM_SCRIPT="$TDAI_DIR/scripts/buffy-team-setup.sh"
  if [[ -x "$TEAM_SCRIPT" ]]; then
    run bash "$TEAM_SCRIPT"
  else
    warn "team setup script not found at $TEAM_SCRIPT — is the stack checkout up to date?"
    warn "  (it lives in TencentDB-Agent-Memory/scripts/buffy-team-setup.sh — pull or copy it)"
  fi
fi

# --- stage 4 · report ---------------------------------------------------------------
step "Stage 4 · final report"
PANEL_URL="http://localhost:8125"
if [[ $DRY_RUN -eq 0 ]] && curl -sf -m 3 -o /dev/null "$PANEL_URL/"; then
  ok "Memory Hub panel  → $PANEL_URL/#/"
  ok "Knowledge service → http://localhost:8424/health"
  KEY_FILE="$TDAI_DIR/deploy/global-images/.admin-key"
  if [[ -s "$KEY_FILE" ]]; then
    ok "admin key  → $(cat "$KEY_FILE")"
    warn "agent keys → $TDAI_DIR/deploy/global-images/.agent-keys.json (mode 600)"
  fi
  PROXY_PORT="${PROXY_PORT:-8096}"
  if curl -sf -m 3 -o /dev/null "http://127.0.0.1:$PROXY_PORT/"; then
    ok "proxy ready — Claude Code via: export ANTHROPIC_BASE_URL=http://127.0.0.1:$PROXY_PORT/claude-code/default"
  fi
else
  [[ $DRY_RUN -eq 1 ]] && ok "dry run complete — no changes made"
fi
echo
ok "BLUEPRINT COMPLETE — the agency is ready to run."
echo "  Tips:"
echo "   · Log into the panel with the admin key, switch team to 'Nexus Marketing Agency'"
echo "   · Skills page now filters by search / status / owner"
echo "   · Re-run this blueprint any time — every stage is idempotent"
