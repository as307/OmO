# Notes — 2026-08-15 · Phase 2: Dify deployed LOCALLY (codespace disk was the blocker)

Dated note from **Buffy (Freebuff)** — follows the repo convention (dated files
over editing `OmO-claude/STATUS.md`). Picks up from `NOTES-2026-08-15.md` +
`NOTES-2026-08-15-phase1-join-claude.md`.

## What changed this session

1. **`omanai-playbooks` wiki ingestion re-triggered + allocator running.**
   The wiki (`wiki-5hp5bhvp`) was stuck `failed / "interrupted by restart"`
   after the 11:29 host reboot killed ingestion mid-run and the background
   watcher died with it. Re-triggered `POST /v3/wiki/ingest` → now
   `processing/ingesting` again. Restarted the allocator detached:
   `setsid nohup bash OmO-freebuff/scripts/wait-and-allocate-wiki.sh wiki-5hp5bhvp`
   (pid 134072, log `/tmp/wiki-allocate-watch.log`). It resolves the 5 active
   tdai-memory agents dynamically and allocates once ready.

2. **5th task recreated on the tdai-memory board.** Claude's handoff said the
   "[AI Tools Outreach] Escalate Apollo blockers to AJ" task save was
   unconfirmed — confirmed it was **missing** (only 4 tasks existed) and
   recreated it: `task-28kffndifi`, linked to `agt-24if4hb2km`, risk medium.

3. **Phase 1 deliverable committed + pushed** (`ea3454d`): `OmO-dify/`
   (deployer, wiring, OpenAPI tool spec, workflow DSL), `blueprint.sh`
   Stage 4, `claude-join.sh`, phase-1 notes. Verified **no real admin key in
   committed files** (`workflow-entrypoint.generated.yml` stays gitignored).
   Codespace synced: remote fixed `nexus-ai-marketing-agency` → `as307/OmO`,
   pulled to `ea3454d`.

4. **Dify deployed — LOCALLY, not in the codespace.** The codespace volume is
   **32G and hit 100%** mid-pull (Dify images ≈10.3G + ~13G system), wedging
   the deploy. The local machine has 54G free AND already hosts the Memory
   Hub + admin key, so Dify reaches the hub with no tunnel. Switched direction
   per AJ's call ("build everything here, then push").

## Local Dify stack (all verified working)

- URL: **http://localhost:8080/** (console `/console`) — port 8080 because
  rootless podman can't bind :80/:443.
- 15 containers up (api healthy, worker, web, nginx, postgres, pgvector,
  redis, sandboxes…). `VECTOR_STORE=pgvector` (RAM-aware, <4G free).
- Memory Hub reachable from Dify containers via `host.containers.internal:8125`
  (verified with real admin key from inside `docker-api-1`).
- OmniRouter reachable from Dify containers via
  `host.containers.internal:20128` → **port-forward** to the codespace
  (`gh codespace ports forward 20128:20128`, pid 63461) — OmniRouter stays
  in the codespace where Claude moved it.
- Admin account created via API: `aj@omanai.co` (password in
  `/tmp/dify-local-deploy3.log` area / ask AJ).
- Wiring rendered: `OmO-dify/workflow-entrypoint.generated.yml` with real
  admin key + `host.containers.internal` gateway; team `team-22skqxyoio` and
  Strategist `agt-22sksndvox` sanity-checked against the hub.

## Podman gotchas fixed (documented so deploys are repeatable)

- **Compose v1 is too old** for Dify's compose file (`env_file` object form,
  `depends_on.required`). Installed standalone **Compose v2.39.2** to
  `~/.local/bin/docker-compose` (first in PATH).
- **nginx resolver hardcodes Docker's `127.0.0.11`** — podman's DNS lives at
  the network gateway. Patched `~/dify/docker/nginx/conf.d/{default.conf,
  default.conf.template}` to `resolver 10.89.2.1` and reloaded. (Gateway is
  per-network: `podman network inspect docker_default`.)
- **Rootless podman can't bind :80/:443** → `EXPOSE_NGINX_PORT=8080` +
  `EXPOSE_NGINX_SSL_PORT=8443` in `~/dify/docker/.env`.

## Remaining (browser/UI steps — the only manual part left)

Per `wire-memoryhub.sh` output: (A) import `memoryhub-tool.openapi.json` as
custom tool with `X-Tdai-Service-Id=default` + admin key; (B) register
OpenAI-API-compatible provider → `http://host.containers.internal:20128/v1`,
key `local-key`, model `auto/best-chat`; (C) import
`workflow-entrypoint.generated.yml` DSL in Studio. Login needs the UI
(RSA-encrypted password — not API-automatable).

## Background processes to keep alive (all on the local machine)

| Process | What | Restart |
|---|---|---|
| wiki allocator (pid 134072) | allocates `omanai-playbooks` when ready | `setsid nohup bash OmO-freebuff/scripts/wait-and-allocate-wiki.sh wiki-5hp5bhvp` |
| OmniRouter port-forward (pid 63461) | `localhost:20128` → codespace | `setsid nohup gh codespace ports forward 20128:20128 -c redesigned-potato-r7759jrw6gqg25665` |

## Repos handed over for evaluation (AJ)

- **thedotmack/claude-mem** (cloned `~/reviews/claude-mem`) — persistent
  cross-session memory for Claude Code: SQLite + Chroma hybrid search, 5
  lifecycle hooks, Bun worker + web UI, MCP search tools (3-layer
  progressive-disclosure pattern). Local-first, installs via
  `npx claude-mem install` or `/plugin marketplace add thedotmack/claude-mem`.
  Complements the team-level Memory Hub with per-session context.
- **affaan-m/ECC** (cloned `~/reviews/ECC`) — agent-harness system: 68 agents,
  284 skills, hooks, rules, continuous learning, AgentShield security
  scanning. MIT. Heavy overlap with the existing `agency-agents` roster +
  `~/.claude/agents` — would need the same dedup discipline applied to
  `agency-agents` earlier. Install via `/plugin marketplace add
  https://github.com/affaan-m/ECC` + `/plugin install ecc@ecc`.

Both slot into the **Claude Code session side** (`claude-join.sh` /
`connect-agents.sh`), not the Dify orchestrator — which is now live locally.
