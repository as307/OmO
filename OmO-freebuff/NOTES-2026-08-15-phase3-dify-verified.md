# Notes — 2026-08-15 · Phase 3: Dify fully wired via API + verified end-to-end

Dated continuation from **Buffy (Freebuff)** — picks up where
`NOTES-2026-08-15-phase2-dify-local.md` stopped. Follows the repo convention
(dated files over editing the other agent's notes).

## TL;DR — the phase-2 "remaining UI steps" are DONE

Phase 2 ended with *"Remaining (browser/UI steps — the only manual part
left): (A) import custom tool, (B) register provider, (C) import workflow
DSL."* The continuation session completed **all three via API + headless
browser** and **verified the workflow end-to-end**:

| Step | State | Evidence |
|---|---|---|
| Login | ✅ `as@omanai.co` (Dify admin, created 09:09 UTC) | `dify-login*.mjs` in `/tmp` |
| (B) Model provider | ✅ OpenAI-API-compatible → OmniRouter `:20128`, `local-key`, `auto/best-chat` | `providers` row valid since 10:36 UTC |
| (A) Custom tool | ✅ `memory_hub` tool imported (OpenAPI spec) | `tool_api_providers` row, 10:40 UTC |
| (C) Workflow DSL | ✅ App **"Memory Hub Entrypoint"** imported (`advanced-chat`) | app `cb5f9e31-9a72-4825-8185-28d78b2869fd`, 10:57 UTC |
| End-to-end run | ✅ **5 successful runs** (10:57–11:18 UTC) | `workflow_runs` all `succeeded`, tokens 359–808 |
| Memory log-back | ✅ **confirmed in the hub** — 16 L0 messages on Strategist block | `chat-memory/layer` → `msg-9a3c71caa9ed` etc. |

One real run's output (last, `48512b70…`): recall → empty (nothing stored
yet), LLM answered *"the team memory does not contain a Q3 launch plan…"*,
log-back node returned `{"imported":true,"block_id":"chat_memory-team-22skqxyoio-agt-22sksndvox","accepted_count":2}`.

So the **Dify orchestrator is live and proven**: user query → recall team
memory → OmniRouter answer → write exchange back to Strategist memory.

## What changed this session

1. **Committed the verified workflow DSL** (`7b39ce3`): `workflow-entrypoint.yml`
   converted to Dify 1.16's `advanced-chat` schema (was simple `chat`) — the
   exact version that imported and ran successfully. `mode: advanced-chat` +
   `model_config`, `sys.query` references, per-node `timeout` objects.
   `workflow-entrypoint.generated.yml` (real key, gitignored) was re-rendered
   14:57 and is what the app was imported from.
2. **Note this in the phase-2 README-implied steps:** the two "one-time UI
   steps" are no longer needed — provider + tool + DSL are all in already.
   Only the app **publish** step remains (draft-only so far).

## Blocker: OmniRouter is DOWN (Dify's LLM node can't reach it)

- The OmniRouter codespace (`redesigned-potato-r7759jrw6gqg25665`) is
  **Shutdown**, which killed the `:20128` port-forward (pid 63461) that
  pointed Dify at OmniRouter via `host.containers.internal:20128`.
- Dify itself is healthy (15 containers, api healthy) and Memory Hub is up —
  only the LLM gateway is unreachable, so new runs would fail at the answer
  node until it's back.
- **Restore options:**
  1. **Start the codespace + re-forward** (documented setup):
     `gh codespace start redesigned-potato-r7759jrw6gqg25665` then
     `setsid nohup gh codespace ports forward 20128:20128 -c redesigned-potato-r7759jrw6gqg25665`
  2. **Run OmniRouter locally** (`~/start-router.sh`) — ⚠️ risky right now:
     only ~672Mi free, swap 100% full (Dify + Memory Hub + Eliza + Claude all
     resident). OmniRouter was moved off local for exactly this reason.

## Also verified this session

- Dify version: `1.16.1` (api/web/agent-backend), plugin daemon `0.6.10`.
- Wiki allocator finished: **5/5 tdai-memory agents bound to
  `omanai-playbooks`** (`wiki-5hp5bhvp`) at 13:15.
- Admin account in Dify DB is `as@omanai.co` (the phase-2 note said `aj@` —
  corrected here).
- Deploy log confirms the podman port-443 bind error on first `up` (rootless
  podman, unprivileged port) — resolved via `EXPOSE_NGINX_PORT=8080`; that's
  why Dify is at `:8080`, not `:80`.

## Update — model switched to OpenRouter free (OmniRouter no longer needed)

AJ: *"use openrouter free models"* → Dify's LLM node now calls **OpenRouter**
(`https://openrouter.ai/api/v1`) with the existing key from
`tencentdb-agent-memory/deploy/global-images/.env` (`MEMORY_LLM_API_KEY`)
and model **`openai/gpt-oss-20b:free`** (picked by Buffy — the free model
already proven in this stack via Memory Hub ingestion; 16 free models were
available). Done + verified:

- Provider model registered: `openai/gpt-oss-20b:free` on
  `langgenius/openai_api_compatible/openai_api_compatible` (valid).
- DSL (`workflow-entrypoint.yml`) + generated re-rendered with the model;
  README + `wire-memoryhub.sh` steps updated to OpenRouter.
- App re-imported (new id `685c7dc8-…`, old `cb5f9e31-…` deleted) and **ran
  successfully end-to-end**: recall → OpenRouter answer (335 tokens) →
  log-back `imported: true, accepted_count: 2`.
- Note: provider-level PUT needed a `credential_id` (400); the
  **model-level** credentials POST (201) is what the workflow uses, so the
  switch is complete without it.

## Update — memory seeding paused pending other-team confirmation (AJ rule)

AJ: *"both teams work as one together not over each other — need to confirm
with the other team that you will do a&b&c"*. Two Memory Hub teams exist:
- **Nexus Marketing Agency** (`team-22skqxyoio`, 5 agents, Buffy's side) —
  the team the Dify workflow recalls from. Has a `Combined-force
  coordination` task (`task-26qa7hi1od`).
- **tdai-memory** (`team-2z1n59cudp`, 5 agents, Claude's side) — owns the
  playbook WIKIS (agency-agents + omanai-playbooks, both `ready`).

The Dify workflow's recall (`chat-memory/team-assets` for
`team-22skqxyoio`) returns 0 items because (a) nothing is seeded there and
(b) `team-assets` only lists blocks with `visibility: team` — the Strategist
block is private. So the LLM answers "no memory".

Seeding plan (a/b/c), posted for confirmation:
- a) Import playbook summaries + Q3/omanai.co launch plan as L0 into the
  Nexus Strategist chat-memory block (`chat-memory/import`).
- b) Flip the block private → team (`chat-memory/patch-scope`).
- c) Re-run the Dify workflow, verify recall returns content, let the
  L1/L2/L3 distillation pipeline summarize.

**Status: PAUSED — no seeding done yet.** Confirmation task posted to the
other team's board: `task-3miwghgett` (tdai-memory, linked to HQ
Orchestrator `agt-22xb7h1qt7`); mirror note on the Nexus board:
`task-3mjbiti1vi`. Resume a/b/c only after the other team confirms (or AJ
overrides). Content sources ready: `docs/superpowers/plans/
2026-08-15-omanai-co-launch.md` (real Q3/omanai.co launch plan) + the
DECISION doc + playbook wiki content.

## Next steps (whoever picks this up)

1. **Publish the app** in Dify (Studio → the app → Publish) so it's callable
   from the web/API, not just draft-debug; optionally create an API key.
2. **Feed the team memory** — the recall node returned 0 items because the
   hub has nothing for `team-22skqxyoio` yet; seed it (playbook summaries,
   Q3 plan) so answers stop being "no memory".
3. Decide the real orchestrator if not settled (Dify vs `aaa-agency` NEXUS vs
   `nexus-executive`) — HQ_STATUS.md §5 item 3 remains open.
4. OmniRouter (down) is no longer required by Dify; it's only needed for
   tools that still point at `:20128`. Restore it only if something needs it.
