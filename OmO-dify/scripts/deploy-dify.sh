#!/usr/bin/env bash
# =============================================================================
# deploy-dify.sh — Phase 1: deploy Dify (orchestrator) and make it reach the
# host's Memory Hub + OmniRouter from inside its containers.
#
#   ./scripts/deploy-dify.sh                # deploy with defaults
#   DIFY_DIR=/opt/dify ./scripts/deploy-dify.sh
#   DIFY_PORT=8080 ./scripts/deploy-dify.sh # expose nginx on a custom port
#   DIFY_VECTOR_STORE=pgvector ./scripts/deploy-dify.sh   # low-RAM vector store
#   ./scripts/deploy-dify.sh --dry-run      # print the plan, change nothing
#
# Env: DIFY_DIR, DIFY_REPO, DIFY_PORT, DIFY_VECTOR_STORE, OMNIROUTER_URL,
#      OMNIROUTER_API_KEY, DIFY_ADMIN_EMAIL, DIFY_ADMIN_PASSWORD
#
# After the containers are up you still do two one-time UI steps (documented
# in ../README.md §4): create the admin account and register the model
# provider (OpenAI-API-compatible → OmniRouter). The workflow + Memory Hub
# tool are then imported via ../scripts/wire-memoryhub.sh.
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

DIFY_DIR="${DIFY_DIR:-$HOME/dify}"
DIFY_REPO="${DIFY_REPO:-https://github.com/langgenius/dify.git}"
DIFY_PORT="${DIFY_PORT:-80}"
VECTOR_STORE="${DIFY_VECTOR_STORE:-}"
OMNIROUTER_URL="${OMNIROUTER_URL:-http://localhost:20128}"
OMNIROUTER_API_KEY="${OMNIROUTER_API_KEY:-local-key}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

step() { echo; printf '%s── %s ────────────────────────────────────────%s\n' "$CYAN" "$*" "$RESET"; }

run() { # cmd... — dry-run aware
  if [[ $DRY_RUN -eq 1 ]]; then printf '   [dry] %s\n' "$*"; return 0; fi
  "$@"
}

# --- detect runtime + compose -------------------------------------------------
detect_compose() {
  local docker_bin; docker_bin="$(command -v docker || true)"
  RUNTIME=""
  # The 'docker' CLI may be podman emulation (podman-docker) — detect it.
  if [[ -n "$docker_bin" ]]; then
    if docker --version 2>/dev/null | grep -qi podman; then RUNTIME="podman"; else RUNTIME="docker"; fi
  fi
  [[ -z "$RUNTIME" ]] && command -v podman >/dev/null 2>&1 && RUNTIME="podman"
  [[ -z "$RUNTIME" ]] && fail "no container runtime found (need docker or podman)"

  # Prefer the compose provider, in order.
  if [[ -n "$docker_bin" ]] && docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
  elif command -v podman-compose >/dev/null 2>&1; then
    COMPOSE=(podman-compose)
  else
    fail "no compose found (need docker compose, docker-compose, or podman-compose)"
  fi

  # podman: the compose provider (e.g. delegated docker-compose v1) talks to
  # the Docker API socket — make sure podman.socket is up and DOCKER_HOST points at it.
  if [[ "$RUNTIME" == "podman" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      log "   [dry] systemctl --user start podman.socket; export DOCKER_HOST=unix://\$XDG_RUNTIME_DIR/podman/podman.sock"
    else
      systemctl --user start podman.socket 2>/dev/null \
        || warn "could not start podman.socket — set DOCKER_HOST manually"
      export DOCKER_HOST="${DOCKER_HOST:-unix://$XDG_RUNTIME_DIR/podman/podman.sock}"
      ok "podman socket ready (DOCKER_HOST=$DOCKER_HOST)"
    fi
  fi
}

# Host gateway so containers can reach services running on the host
# (Memory Hub :8125, OmniRouter :20128). podman: host.containers.internal
# (automatic). docker-on-linux: host.docker.internal needs extra_hosts.
host_gateway() {
  if [[ "$RUNTIME" == "podman" ]]; then echo "host.containers.internal"; return; fi
  if [[ "$(uname -s)" == "Darwin" || "$(uname -s)" == "MINGW"* || "$(uname -s)" == "MSYS"* ]]; then
    echo "host.docker.internal"; return
  fi
  echo "host.docker.internal"  # on Linux we add extra_hosts via override file
}

# --- main ---------------------------------------------------------------------
log "OmO Phase 1 — deploy Dify"
log "  work dir  : $DIFY_DIR"
log "  port      : $DIFY_PORT"
log "  dry run   : $([ $DRY_RUN -eq 1 ] && echo yes || echo no)"

step "Step 1 · detect runtime + compose"
detect_compose
ok "runtime=$RUNTIME compose=${COMPOSE[*]}"
GATEWAY="$(host_gateway)"
ok "containers will reach the host via: $GATEWAY"

step "Step 2 · fetch Dify (sparse: docker/ only)"
if [[ -d "$DIFY_DIR/docker" ]]; then
  ok "Dify already present at $DIFY_DIR/docker"
else
  run mkdir -p "$DIFY_DIR"
  run git clone --depth 1 --filter=blob:none --sparse "$DIFY_REPO" "$DIFY_DIR" \
    || fail "clone failed — check DIFY_REPO / network"
  run git -C "$DIFY_DIR" sparse-checkout set docker
  [[ $DRY_RUN -eq 1 ]] && log "   [dry] (sparse checkout set to docker/)"
fi
DOCKER_DIR="$DIFY_DIR/docker"
if [[ $DRY_RUN -eq 0 ]]; then
  [[ -f "$DOCKER_DIR/docker-compose.yaml" || -f "$DOCKER_DIR/docker-compose.yml" ]] \
    || fail "no docker-compose found in $DOCKER_DIR"
else
  log "   [dry] (docker-compose presence check skipped in dry run)"
fi

step "Step 3 · configure .env"
ENV_FILE="$DOCKER_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  run cp "$DOCKER_DIR/.env.example" "$ENV_FILE"
  warn "created $ENV_FILE from .env.example"
fi

# RAM-aware vector store: default weaviate (Dify's default); pgvector if the
# user asked for it or the box is tight (it reuses the postgres container).
if [[ -z "$VECTOR_STORE" ]]; then
  AVAIL_GB="$(free -g 2>/dev/null | awk '/^Mem:/{print $7+0}')"
  if [[ -n "$AVAIL_GB" && "$AVAIL_GB" -lt 4 ]]; then
    VECTOR_STORE="pgvector"
    warn "available RAM ${AVAIL_GB}G < 4G → using VECTOR_STORE=pgvector (reuses postgres; lighter than weaviate)"
  else
    VECTOR_STORE="weaviate"
  fi
fi
run sed -i "s|^VECTOR_STORE=.*|VECTOR_STORE=$VECTOR_STORE|" "$ENV_FILE"
run sed -i "s|^EXPOSE_NGINX_PORT=.*|EXPOSE_NGINX_PORT=$DIFY_PORT|" "$ENV_FILE"
# Point the built-in OpenAI provider at OmniRouter as a bonus (custom
# OpenAI-API-compatible provider is still configured in the UI — see README).
run sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=$OMNIROUTER_API_KEY|" "$ENV_FILE"
run sed -i "s|^OPENAI_API_BASE_URL=.*|OPENAI_API_BASE_URL=$OMNIROUTER_URL/v1|" "$ENV_FILE"
run sed -i "s|^#\? *SECRET_KEY=.*|SECRET_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 40)|" "$ENV_FILE"
ok "env: VECTOR_STORE=$VECTOR_STORE EXPOSE_NGINX_PORT=$DIFY_PORT"

# docker-on-Linux: add host gateway so Dify containers can reach the host.
if [[ "$RUNTIME" == "docker" && "$GATEWAY" == "host.docker.internal" && $DRY_RUN -eq 0 ]]; then
  OVERRIDE="$DOCKER_DIR/docker-compose.override.yml"
  if [[ ! -f "$OVERRIDE" ]]; then
    cat > "$OVERRIDE" <<'YAML'
services:
  api:
    extra_hosts:
      - "host.docker.internal:host-gateway"
  worker:
    extra_hosts:
      - "host.docker.internal:host-gateway"
  plugin_daemon:
    extra_hosts:
      - "host.docker.internal:host-gateway"
YAML
    ok "wrote $OVERRIDE (host.docker.internal → host-gateway)"
  else
    ok "$OVERRIDE already present"
  fi
fi

step "Step 4 · start the stack"
(
  cd "$DOCKER_DIR" || fail "cd $DOCKER_DIR failed"
  run "${COMPOSE[@]}" up -d
)
[[ $DRY_RUN -eq 1 ]] && { log "   [dry] compose up -d (would pull images and start ~7 containers)"; }

step "Step 5 · wait for health + report"
if [[ $DRY_RUN -eq 0 ]]; then
  for i in $(seq 1 60); do
    if curl -sf -m 3 -o /dev/null "http://localhost:$DIFY_PORT/health"; then
      ok "Dify is up: http://localhost:$DIFY_PORT/ (console at /console)"
      break
    fi
    [[ $i -eq 60 ]] && warn "health check timed out — check: cd $DOCKER_DIR && ${COMPOSE[*]} ps"
    sleep 3
  done
else
  log "   [dry] wait for http://localhost:$DIFY_PORT/health"
fi

echo
ok "DIFY DEPLOYED"
echo "  Next (one-time, in the UI):"
echo "    1. Open http://localhost:${DIFY_PORT}/console and create the admin"
echo "       account (first run)."
echo "    2. Settings → Model Provider → add 'OpenAI-API-compatible':"
echo "       Base URL  http://${GATEWAY}:20128/v1"
echo "       API Key   ${OMNIROUTER_API_KEY}"
echo "       Model     auto/best-chat   (see \$ curl $OMNIROUTER_URL/v1/models)"
echo "    3. Import the Memory Hub tool + workflow:"
echo "       ./scripts/wire-memoryhub.sh"
echo
echo "  View Dify:      http://localhost:${DIFY_PORT}/"
echo "  Stop:           (cd $DOCKER_DIR && ${COMPOSE[*]} down)"
echo "  Logs:           (cd $DOCKER_DIR && ${COMPOSE[*]} logs -f api)"
