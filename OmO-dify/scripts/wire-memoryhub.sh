#!/usr/bin/env bash
# =============================================================================
# wire-memoryhub.sh — Phase 1: wire Dify to the Memory Hub.
#
#   1. Verifies the Memory Hub is up and the admin key works.
#   2. Renders ../workflow-entrypoint.yml → workflow-entrypoint.generated.yml
#      with the real admin key and the correct host gateway, so the file can
#      be imported into Dify as-is (no secrets are committed to git).
#   3. Prints the exact Dify UI steps for importing the Memory Hub custom tool
#      (../memoryhub-tool.openapi.json) and the workflow.
#
#   ./scripts/wire-memoryhub.sh
#   TDAI_DIR=/path/to/tencentdb-agent-memory ./scripts/wire-memoryhub.sh
#   ./scripts/wire-memoryhub.sh --dry-run
#
# Env: TDAI_DIR, API_BASE, INSTANCE, DIFY_DIR, DIFY_PORT
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

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

TDAI_DIR="${TDAI_DIR:-$HOME/tencentdb-agent-memory}"
API_BASE="${API_BASE:-http://localhost:8125/api/v1}"
INSTANCE="${INSTANCE:-default}"
KEY_FILE="${TDAI_DIR}/deploy/global-images/.admin-key"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_SPEC="$SCRIPT_DIR/../memoryhub-tool.openapi.json"
WF_TEMPLATE="$SCRIPT_DIR/../workflow-entrypoint.yml"
WF_OUT="$SCRIPT_DIR/../workflow-entrypoint.generated.yml"

step() { echo; printf '%s── %s ────────────────────────────────────────%s\n' "$CYAN" "$*" "$RESET"; }

# --- 1 · hub + key -------------------------------------------------------------
step "Step 1 · verify Memory Hub + admin key"
if ! curl -sf -m 5 "$API_BASE/meta/instances" >/dev/null 2>&1; then
  fail "Memory Hub not reachable at $API_BASE — start the stack first (blueprint Stage 2 or ./start-all.sh)"
fi
[[ -s "$KEY_FILE" ]] || fail "admin key not found at $KEY_FILE"
ADMIN_KEY="$(cat "$KEY_FILE")"
AUTH="$(curl -s -m 8 -X POST "$API_BASE/meta/auth/verify" \
  -H "x-tdai-service-id: $INSTANCE" \
  -H "x-tdai-user-key: $ADMIN_KEY" -H "Content-Type: application/json" \
  -d "{\"user_key\":\"$ADMIN_KEY\"}")"
python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('code')==0 and d.get('data',{}).get('valid') else 1)" <<<"$AUTH" \
  || fail "admin key rejected by the hub"
ok "hub reachable, admin key valid"

# --- 2 · host gateway ----------------------------------------------------------
if command -v docker >/dev/null 2>&1 && docker info 2>/dev/null | grep -qi podman; then
  GATEWAY="host.containers.internal"
else
  GATEWAY="host.docker.internal"
fi
ok "containers reach the host via: $GATEWAY"

# --- 3 · render workflow with real values --------------------------------------
step "Step 3 · render workflow-entrypoint.generated.yml"
if [[ ! -f "$WF_TEMPLATE" ]]; then fail "template missing: $WF_TEMPLATE"; fi
if [[ $DRY_RUN -eq 1 ]]; then
  log "   [dry] render $WF_OUT with admin key + gateway $GATEWAY"
else
  sed -e "s|<admin-key>|$ADMIN_KEY|g" \
      -e "s|host\.containers\.internal:$GATEWAY|&|g" \
      -e "s|http://host\.containers\.internal:|http://$GATEWAY:|g" \
      -e "s|http://host\.docker\.internal:|http://$GATEWAY:|g" \
      "$WF_TEMPLATE" > "$WF_OUT"
  chmod 600 "$WF_OUT"
  # the file contains the admin key → never commit it
  if [[ -f "$SCRIPT_DIR/../.gitignore" ]]; then
    grep -q "workflow-entrypoint.generated.yml" "$SCRIPT_DIR/../.gitignore" \
      || printf 'workflow-entrypoint.generated.yml\n' >> "$SCRIPT_DIR/../.gitignore"
  fi
  ok "rendered $WF_OUT (contains the admin key — gitignored, do not commit)"
fi

# --- 4 · sanity-check the agent/team ids in the workflow ------------------------
step "Step 4 · sanity-check ids referenced by the workflow"
# team/list requires user_id (or user_key) — resolve the admin's id from auth/verify.
ADMIN_ID="$(python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['user_id'])" <<<"$AUTH" 2>/dev/null || echo "")"
TEAM_ID="$(grep -oE '"team_id":"[a-z0-9-]+"' "$WF_TEMPLATE" | head -1 | cut -d'"' -f4)"
AGENT_ID="$(grep -oE '"agent_id":"[a-z0-9-]+"' "$WF_TEMPLATE" | head -1 | cut -d'"' -f4)"
if [[ -n "$TEAM_ID" && -n "$ADMIN_ID" ]]; then
  RESP="$(curl -s -m 8 -X POST "$API_BASE/meta/team/list" -H "x-tdai-service-id: $INSTANCE" \
    -H "x-tdai-user-key: $ADMIN_KEY" -H "Content-Type: application/json" -d "{\"user_id\":\"$ADMIN_ID\"}")"
  python3 -c "
import sys,json
d=json.load(sys.stdin)
ids=[t['team_id'] for t in d.get('data',{}).get('items',[])]
sys.exit(0 if '${TEAM_ID}' in ids else 1)" <<<"$RESP" \
    && ok "team $TEAM_ID exists" || warn "team $TEAM_ID not found — update the workflow template"
else
  warn "could not resolve admin user id or team id — skipping team check"
fi
if [[ -n "$AGENT_ID" ]]; then
  RESP="$(curl -s -m 8 -X POST "$API_BASE/meta/agent/get" -H "x-tdai-service-id: $INSTANCE" \
    -H "x-tdai-user-key: $ADMIN_KEY" -H "Content-Type: application/json" -d "{\"agent_id\":\"$AGENT_ID\"}")"
  python3 -c "
import sys,json
d=json.load(sys.stdin)
sys.exit(0 if d.get('code')==0 and d.get('data',{}).get('agent_id') else 1)" <<<"$RESP" \
    && ok "agent $AGENT_ID exists (memory write target)" || warn "agent $AGENT_ID not found — update the workflow template"
fi

# --- 5 · print Dify import steps -------------------------------------------------
step "Step 5 · Dify import steps (do these in the Dify UI)"
DIFY_URL="http://localhost:${DIFY_PORT:-80}"
echo "  A. Memory Hub custom tool"
echo "     1. Open ${DIFY_URL}/console → Tools → Custom → 'Create custom tool'"
echo "     2. Import: $TOOL_SPEC"
echo "     3. In the tool's auth/parameters set:"
echo "          X-Tdai-Service-Id = ${INSTANCE}"
echo "          X-Tdai-User-Key   = ${ADMIN_KEY}"
echo "     4. Save → the team/agent/skill/chat-memory actions are now callable"
echo "        from Dify workflows and agents."
echo
echo "  B. End-to-end workflow entrypoint"
echo "     1. Studio → Import DSL → $WF_OUT"
echo "        (or build by hand — recipe in ../README.md §5)"
echo "     2. Make sure the model provider is configured first (README §4):"
echo "        OpenAI-API-compatible → Base URL http://${GATEWAY}:20128/v1"
echo "        · API key local-key · model auto/best-chat"
echo "     3. Open the app and try: 'What is our Q3 launch plan?'"
echo
echo "  C. Verify the loop"
echo "     After a run, check Memory Hub → ${INSTANCE} → Strategist memory"
echo "     for the logged exchange (chat-memory/import target)."
echo
ok "WIRING READY — workflow rendered at $WF_OUT"
