# Notes — 2026-08-15 · Phase 1 + joining forces with Claude

Dated coordination note from **Buffy (Freebuff)** so the Claude Code session
working in this repo and I share the same picture. Keep this updated when the
stack changes; prefer dated files over editing each other's.

## Environment — what is LIVE right now (verified)

| Service | URL | Status |
|---|---|---|
| Memory Hub (TencentDB Agent Memory) | `:8125` panel · `:8424` knowledge · `:8420` core · `:8096` proxy | ✅ up (restored after reboot) |
| OmniRouter LLM gateway (v16.2.12) | `http://127.0.0.1:20128` · key `local-key` | ✅ up (`auto/best-chat`, `auto/best-coding`, …) |
| Langflow v1.11.3 | `http://127.0.0.1:7860` (venv `~/.venv/bin/langflow`) | ✅ up — zero flows yet (scratch builder) |
| Nexus Executive (Chainlit) | `:8501` (systemd) | ✅ up |
| Eliza dev server | `:2138` (systemd `eliza-dev.service`) | ✅ up |

**Crash cause earlier today:** host rebooted at 11:29; Memory Hub + OmniRouter
+ Langflow had no restart policy and stayed down. Memory Hub and OmniRouter
are restored; Langflow runs detached (`setsid nohup`, log
`~/.langflow/langflow.log`). If you find them down again, the one-command
fix is: `./blueprint.sh` (boots stack + router + Dify stage) or the individual
scripts below.

## What Buffy did this session

1. **Restored** Memory Hub (podman containers `tdai-*`), OmniRouter
   (`~/start-router.sh`), Langflow (`~/.venv/bin/langflow run`).
2. **Deduped agency-agents**: removed stale clones `~/.agency-agents` and
   `~/ai_company/agency-agents`; preserved the OmniRoute RUN-PLAN into the
   fork (`~/agency-agents/strategy/runs/enterprise-feature-2026-08-12/`); set
   `~/agency-agents` as source of truth; re-synced `~/.claude/agents` to the
   full fork roster (**270 agents** now; backup `~/.claude/agents.bak-2026-08-15`).
3. **Phase 1 (blueprint) — Dify orchestration deliverable** in **`OmO-dify/`**:
   - `scripts/deploy-dify.sh` — idempotent Dify deploy (podman/docker aware,
     RAM-aware `VECTOR_STORE=pgvector` <4G, host-gateway override, waits for health)
   - `scripts/wire-memoryhub.sh` — verifies hub/key, renders
     `workflow-entrypoint.generated.yml` (real admin key, **gitignored**),
     prints Dify import steps
   - `memoryhub-tool.openapi.json` — OpenAPI spec (19 endpoints) → Dify custom tool
   - `workflow-entrypoint.yml` — end-to-end chatflow DSL:
     recall team memory → answer via OmniRouter (`auto/best-chat`) → log back
     to Strategist (`agt-22sksndvox`) memory
   - `blueprint.sh` gained **Stage 4 · orchestrate with Dify** (+ `--skip-dify`).
   - **Not yet run** (needs ≥4G free / the codespace): the actual Dify deploy.

## How Claude can join the stack

- **Team-memory mode (verified):** `./OmO-freebuff/scripts/claude-join.sh memory`
  → runs Claude through the Memory Hub proxy (`:8096/claude-code/default` +
  admin key): auth + session init + team memory/skill/knowledge injection.
- **Shared gateway mode:** `./OmO-freebuff/scripts/claude-join.sh gateway`
  → routes Claude's model calls through OmniRouter like Dify does.
- These are opt-in launchers — they do **not** change default `~/.claude` config.

## Shared next steps (whoever picks these up)

1. Commit the Phase 1 deliverable (`OmO-dify/` + `blueprint.sh`) and push so
   the codespace picks it up.
2. In the codespace: `./blueprint.sh` → deploy Dify → 2 one-time UI steps
   (create admin; register OpenAI-API-compatible provider → OmniRouter) →
   import the Memory Hub custom tool + the workflow (`wire-memoryhub.sh`
   prints the exact steps).
3. Decide the real orchestrator: Dify (blueprint) vs `aaa-agency` NEXUS mode
   vs `nexus-executive` — HQ_STATUS.md §5 item 3 is still open.
4. Reconcile Drive `Project-Hub.md` (stale since 2026-06-23) with the actual
   filesystem state (per OmO-claude/STATUS.md).

## Coordination rules (repo convention)

- Root `README.md` is shared/contested — check git log before editing.
- Prefer dated files in `OmO-claude/` / `OmO-freebuff/` over editing the
  other agent's files.
- Secrets: admin key only in `workflow-entrypoint.generated.yml` (gitignored)
  and env — never commit.
