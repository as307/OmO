# OmO-dify — Phase 1: Dify orchestrator wired to the Memory Hub

This directory is the **Phase 1 (MVP)** deliverable of the blueprint
(`as307/---` checklist, `INTEGRATION_CHECKLIST.md`): deploy **Dify** as the
workflow orchestrator and connect it to the **Memory Hub** (TencentDB Agent
Memory, running at `http://localhost:8125`) as its shared team-memory backend.

| Piece | File | What it is |
|---|---|---|
| Deployer | `scripts/deploy-dify.sh` | Idempotent Dify deployment (docker or podman; RAM-aware vector store; makes host services reachable from Dify's containers). |
| Wiring | `scripts/wire-memoryhub.sh` | Verifies the hub + admin key, renders the workflow with real values, prints the Dify import steps. |
| Tool spec | `memoryhub-tool.openapi.json` | OpenAPI 3.0 spec for the Memory Hub API → import as a Dify **custom tool**. |
| Workflow | `workflow-entrypoint.yml` | Dify chatflow **DSL** — the one end-to-end workflow entrypoint. |
| Rendered | `workflow-entrypoint.generated.yml` | Produced by the wiring script (real admin key + host gateway). **Gitignored** — contains a secret. |

## Flow

```
user query
  → Dify chatflow (workflow-entrypoint)
      → HTTP node 1: recall team memory   POST /api/v1/chat-memory/team-assets
      → LLM node:   answer grounded in memory  (OpenRouter, openai/gpt-oss-20b:free)
      → HTTP node 2: log exchange back    POST /api/v1/chat-memory/import (→ Strategist)
  → answer returned
```

Every run recalls the Nexus Marketing Agency team's shared memory, answers
grounded in it, and writes the exchange back so the team memory compounds.

## Quick start (in the codespace / on a device with ≥4G free RAM)

```bash
# 1. Deploy Dify (clones sparse, starts ~7 containers, waits for health)
./scripts/deploy-dify.sh

# 2. One-time UI: create the admin account at http://localhost/console

# 3. One-time UI: register the model provider
#    Settings → Model Provider → OpenAI-API-compatible:
#      Base URL  https://openrouter.ai/api/v1
#      API Key   sk-or-…  (OpenRouter key; Memory Hub already has one in
#                 tencentdb-agent-memory/deploy/global-images/.env)
#      Model     openai/gpt-oss-20b:free

# 4. Wire the Memory Hub (validates hub, renders workflow, prints import steps)
./scripts/wire-memoryhub.sh

# 5. In the Dify UI: import the custom tool + the workflow per the printed steps.
```

> **Low-RAM box?** `deploy-dify.sh` auto-switches the vector store to
> `pgvector` when <4G is free (reuses postgres instead of running Weaviate).
> Force it with `DIFY_VECTOR_STORE=pgvector`.

## What each script does

### `scripts/deploy-dify.sh`
- Detects the runtime: `docker compose` → `docker-compose` (with podman-socket
  fallback) → `podman-compose`.
- Clones Dify sparse (only `docker/`) into `~/dify` if missing.
- Configures `.env`: `VECTOR_STORE` (RAM-aware), `EXPOSE_NGINX_PORT`
  (`DIFY_PORT`, default 80), random `SECRET_KEY`, and points the built-in
  OpenAI provider at OmniRouter as a bonus.
- On docker-on-Linux writes `docker-compose.override.yml` with
  `host.docker.internal: host-gateway` so Dify's api/worker/plugin_daemon can
  reach the host's Memory Hub (`:8125`).

> **Model provider:** the workflow LLM node calls **OpenRouter**
> (`https://openrouter.ai/api/v1`, model `openai/gpt-oss-20b:free`) via the
> OpenAI-API-compatible provider — no local OmniRouter needed. The OpenRouter
> key is already in `~/tencentdb-agent-memory/deploy/global-images/.env`
> (`MEMORY_LLM_API_KEY`); paste the same value into Dify's provider config.
- Starts the stack, waits for `/health`, prints the UI next-steps.

### `scripts/wire-memoryhub.sh`
- Checks the hub is up and the admin key
  (`~/tencentdb-agent-memory/deploy/global-images/.admin-key`) verifies.
- Detects the correct host gateway (podman vs docker) and renders
  `workflow-entrypoint.generated.yml` with the real admin key — **no secret
  ever lands in git** (the file is gitignored).
- Sanity-checks the team/agent ids referenced by the workflow against the hub.
- Prints the exact Dify UI steps for the custom-tool import and the workflow
  import.

### `memoryhub-tool.openapi.json`
Curated OpenAPI 3.0 spec for the hub's panel API (auth/verify, team, agent,
task, skill, chat-memory, knowledge/wiki). Import as a Dify **custom tool** so
any Dify workflow or agent can call the hub directly. When adding it, set:
- `X-Tdai-Service-Id` = `default`
- `X-Tdai-User-Key` = the admin key (or a per-agent key from the hub)

### `workflow-entrypoint.yml`
Dify chatflow DSL (import via Studio → Import DSL). References
`team-22skqxyoio` (Nexus Marketing Agency) and `agt-22sksndvox` (Strategist,
the memory write target). The `<admin-key>` placeholder must be replaced —
`wire-memoryhub.sh` does this automatically.

> ⚠️ If the DSL import rejects the file (schema version drift between Dify
> releases), build the same flow by hand in ~5 minutes:

### §5 — Manual workflow build (fallback)
1. **Studio → Create app → Chatflow** (name: `OmO HQ`).
2. **Start** node: keep `sys.query`.
3. **HTTP request** node (title: *Recall team memory*):
   - Method `POST`, URL `http://host.docker.internal:8125/api/v1/chat-memory/team-assets`
     (podman: `host.containers.internal`)
   - Headers: `X-Tdai-Service-Id: default`, `X-Tdai-User-Key: <admin key>`
   - Body (JSON): `{"team_id":"team-22skqxyoio"}`
   - Connect Start → this node.
4. **LLM** node (title: *Answer grounded in memory*):
   - Provider `OpenAI-API-compatible`, model `openai/gpt-oss-20b:free`
   - System prompt: *"Answer using ONLY the team memory provided. If the
     memory lacks an answer, say so and suggest what to store next."*
   - User prompt: `Team memory (JSON): {{#recall-memory.body#}}\n\nUser
     question: {{#start.sys.query#}}`
   - Connect the HTTP node → this node.
5. **HTTP request** node (title: *Log exchange to memory*):
   - `POST http://host.docker.internal:8125/api/v1/chat-memory/import`, same
     headers, body:
     `{"team_id":"team-22skqxyoio","agent_id":"agt-22sksndvox","messages":[{"role":"user","content":"{{#start.sys.query#}}"},{"role":"assistant","content":"{{#answer.text#}}"}]}`
   - Connect LLM → this node.
6. **End** node: output `{{#answer.text#}}`. Connect and publish.

## Blueprint integration
`blueprint.sh` now calls this stage (Stage 5 · Dify). Run the whole thing:
```bash
./blueprint.sh                 # stages 1-5 (add --skip-dify to skip this)
./blueprint.sh --skip-dify     # memory stack + team only
```

## Notes & gotchas
- **Memory:** Dify's default stack wants 4–6G. On this laptop (7G total,
  often <2G free) the full stack only fits if heavy apps are paused; the
  codespace (8–16G) is the intended home for it — which is exactly where this
  repo is opened.
- **Model provider is a UI step** — Dify has no supported env-var path for
  the OpenAI-API-compatible provider, so `deploy-dify.sh` stops at "deployed"
  and prints the two UI steps.
- **Secrets:** the admin key only ever appears in the rendered
  `workflow-entrypoint.generated.yml` (gitignored) and in your Dify tool
  config — never in committed files.
- **The workflow LLM node** uses the *OpenAI-API-compatible* provider; if you
  prefer a hosted model (OpenRouter etc.), just swap the provider in the LLM
  node after import.
