#!/usr/bin/env bash
# =============================================================================
#  NEXUS AI MARKETING AGENCY — EXECUTABLE FINALIZE BLUEPRINT
#  OmO core workspace · run once on a local device / GitHub Codespace
# =============================================================================
#  What this does (5 stages, all idempotent):
#   1. CONNECT    — register MCP servers so Claude Code reaches the device's
#                   agents/tools (graphify, chrome-devtools, GitKraken, …)
#   2. BOOT       — start the Memory Hub stack (memory-core + hub + proxy)
#                   with the filtered dashboard image when available
#   3. PROVISION  — create the Nexus Marketing Agency team: 5 agents,
#                   6 skills, 3 tasks, kickoff memory, per-agent API keys
#   4. ORCHESTRATE — Phase 1: deploy Dify (orchestrator) and wire it to the
#                    Memory Hub (OmO-dify/scripts/deploy-dify.sh + wire-memoryhub.sh)
#   5. REPORT     — print endpoints, credentials, and connection status
#
#  Usage:
#    ./blueprint.sh              # run everything
#    ./blueprint.sh --dry-run    # print the plan, change nothing
#    ./blueprint.sh --stack-dir /path/to/TencentDB-Agent-Memory
#    ./blueprint.sh --skip-claude --skip-stack --skip-team --skip-dify  # selective
#  Env: TDAI_DIR, ADMIN_KEY, API_BASE, INSTANCE, DIFY_DIR, DIFY_PORT
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
SKIP_DIFY=0
TDAI_DIR="${TDAI_DIR:-$HOME/tencentdb-agent-memory}"
DIFY_DIR="${DIFY_DIR:-$HOME/dify}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)        DRY_RUN=1 ;;
    --skip-claude)    SKIP_CLAUDE=1 ;;
    --skip-stack)     SKIP_STACK=1 ;;
    --skip-team)      SKIP_TEAM=1 ;;
    --skip-dify)      SKIP_DIFY=1 ;;
    --stack-dir)      TDAI_DIR="$2"; shift ;;
    --dify-dir)       DIFY_DIR="$2"; shift ;;
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
  # scripts/memory.sh owns checkout/.env checks, filtered-image preference
  # (via a throwaway derived env file — never edits the real .env), and the
  # start-all.sh call. Single source of truth: memory-panel/start.sh calls
  # the same script, so this and the dashboard installer never drift apart.
  # OmO/scripts/ is a sibling of OmO/core (this repo), not inside it — same
  # path memory-panel/start.sh resolves via ../scripts/memory.sh.
  run bash "$REPO_ROOT/../scripts/memory.sh" --dir "$TDAI_DIR" \
    || { fail "Stage 2 failed — see scripts/memory.sh output above"; exit 1; }
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

# --- stage 4 · orchestrate with Dify (Phase 1) ---------------------------------------
if [[ $SKIP_DIFY -eq 0 ]]; then
  step "Stage 4 · orchestrate with Dify (Phase 1)"
  # Dify needs an LLM endpoint — boot OmniRouter when the launcher is present.
  if [[ -x "$HOME/start-router.sh" ]]; then
    run bash "$HOME/start-router.sh"
  else
    warn "OmniRouter launcher not found at ~/start-router.sh — Dify can use any OpenAI-compatible provider"
  fi
  DIFY_SCRIPT="$REPO_ROOT/OmO-dify/scripts/deploy-dify.sh"
  WIRE_SCRIPT="$REPO_ROOT/OmO-dify/scripts/wire-memoryhub.sh"
  if [[ -x "$DIFY_SCRIPT" ]]; then
    DIFY_DIR="$DIFY_DIR" run bash "$DIFY_SCRIPT" \
      || warn "Dify deploy step failed — see OmO-dify/README.md"
  else
    warn "Dify deploy script missing at $DIFY_SCRIPT"
  fi
  if [[ -x "$WIRE_SCRIPT" ]]; then
    run bash "$WIRE_SCRIPT"
  else
    warn "Memory Hub wiring script missing at $WIRE_SCRIPT"
  fi
else
  [[ $DRY_RUN -eq 1 ]] || warn "Stage 4 skipped (--skip-dify)"
fi

# --- stage 5 · report ---------------------------------------------------------------
step "Stage 5 · final report"
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
  DIFY_PORT="${DIFY_PORT:-80}"
  if curl -sf -m 3 -o /dev/null "http://127.0.0.1:$DIFY_PORT/health"; then
    ok "Dify orchestrator → http://localhost:$DIFY_PORT/ (console /console) — wired to Memory Hub per OmO-dify/README.md"
  else
    warn "Dify not up (or skipped) — run OmO-dify/scripts/deploy-dify.sh"
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
