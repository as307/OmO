#!/usr/bin/env bash
# wait-and-allocate-wiki.sh — poll a Memory Hub wiki until ingestion is ready,
# then allocate it to every active agent in the tdai-memory team.
#
# Used to finish the last session's work: the omanai-playbooks wiki was created
# and 7 raw docs uploaded, but ingestion was never triggered. This script waits
# for ingestion to finish (free-tier LLM: ~4-5 min per doc) and then allocates
# the ready wiki to all active team agents so their llm_wiki capability has
# content. Target agents resolve dynamically (no hardcoded ids).
#
# Usage:
#   ./wait-and-allocate-wiki.sh <wiki_id> [--agents "id1 id2 ..."]
# Env: ADMIN_KEY, API_BASE, KB_BASE, INSTANCE, AGENTS
set -uo pipefail

API_BASE="${API_BASE:-http://localhost:8125/api/v1}"
KB_BASE="${KB_BASE:-http://localhost:8424/v3}"
INSTANCE="${INSTANCE:-default}"
KEY_FILE="${ADMIN_KEY:-$HOME/tencentdb-agent-memory/deploy/global-images/.admin-key}"
TEAM_ID="team-2z1n59cudp"

WIKI_ID="${1:-wiki-5hp5bhvp}"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "✘ admin key not found at $KEY_FILE" >&2; exit 1
fi
USER_KEY="$(cat "$KEY_FILE")"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# Resolve target agents dynamically: every active agent in the team.
AGENTS="${AGENTS:-}"
if [[ -z "$AGENTS" ]]; then
  AGENTS="$(curl -s -m 10 -X POST "$API_BASE/meta/agent/list" \
    -H "x-tdai-service-id: $INSTANCE" -H "x-tdai-user-key: $USER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"team_id\":\"$TEAM_ID\",\"status\":\"active\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(' '.join(a['agent_id'] for a in d.get('data',{}).get('items',[])))" 2>/dev/null)"
  log "resolved ${AGENTS:-none} from team $TEAM_ID"
fi

wiki_status() {
  curl -s -m 10 -X POST "$KB_BASE/wiki/get" \
    -H "x-tdai-service-id: $INSTANCE" -H "x-tdai-user-key: $USER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"team_id\":\"$TEAM_ID\",\"wiki_id\":\"$WIKI_ID\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d['status'], d.get('internal_status'), d.get('page_count'))" 2>/dev/null
}

log "waiting for wiki $WIKI_ID to finish ingestion (free tier ≈ 4-5 min/doc)..."
for i in $(seq 1 120); do
  st="$(wiki_status)"
  log "  [$i] $st"
  case "$st" in
    ready*)
      log "✔ wiki ready — allocating to agents"
      ok=0
      for agent in $AGENTS; do
        resp="$(curl -s -m 15 -X POST "$API_BASE/knowledge/allocate" \
          -H "x-tdai-service-id: $INSTANCE" -H "x-tdai-user-key: $USER_KEY" \
          -H "Content-Type: application/json" \
          -d "{\"knowledge_id\":\"$WIKI_ID\",\"agent_id\":\"$agent\",\"team_id\":\"$TEAM_ID\"}")"
        if echo "$resp" | grep -q '"code":0'; then
          log "  ✔ allocated -> $agent"
          ok=$((ok+1))
        elif echo "$resp" | grep -q 'ALREADY_ALLOCATED'; then
          log "  · already allocated -> $agent"
          ok=$((ok+1))
        else
          log "  ✘ allocate failed -> $agent : $resp"
        fi
      done
      log "✔ done — $ok/$(echo "$AGENTS" | wc -w) agents bound to $WIKI_ID"
      exit 0
      ;;
    failed*)
      log "✘ ingestion failed for $WIKI_ID — check the hub logs" >&2
      exit 1
      ;;
  esac
  sleep 30
done
log "✘ timed out after 60 min — $WIKI_ID still not ready" >&2
exit 1
