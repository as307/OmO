# OmO

**Oman AI automation services — operations hub.** This repo is where we organize the data, tools, and work for turning AI automation into a real tech-services business, online and in Oman.

> Formerly `nexus-ai-marketing-agency` — renamed to `OmO` on 2026-08-15 to reflect its actual role as the org's operations repo, not a single marketing-agency product.

## What lives where

| Piece | Where | What it is |
|---|---|---|
| **This repo** | `github.com/as307/OmO` | Operations hub — org data, tools, execution tracking. |
| **Blueprint** | [`as307/---`](https://github.com/as307/---) (locally `~/OmO/hq`) | Architecture reference: target stack (Dify + gpt-researcher + agent-browser + memory layer + nanobot), 10-skill matrix, phased rollout checklist (EN+AR). Not runnable code — read this before building. |
| **Agent roster** | [`aj-omanai/agency-agents`](https://github.com/aj-omanai/agency-agents) (locally `~/agency-agents`) | 316 named specialist subagent personas across 17 divisions (engineering, marketing, sales, finance, security, ...) — the actual capability catalog. |
| **Memory layer** | `~/tencentdb-agent-memory` → running at `http://localhost:8125/` | TencentDB Agent Memory — Panel UI, Knowledge API, shared team memory. Chosen memory backend per the blueprint. Start/stop: `./deploy/global-images/start-all.sh` / `stop-all.sh`. |
| **Claude ↔ device agents bridge** | [`OmO-freebuff/`](./OmO-freebuff) | Built by Freebuff/Buffy — wires Claude Code to the device's MCP tools (graphify, chrome-devtools, GitKraken, composio, freebuff itself). Run `./OmO-freebuff/scripts/connect-agents.sh` to register them. |
| **Orchestration layer (candidate)** | `~/aaa-agency` | "NEXUS" orchestrator wrapping the agent roster — evaluate against the blueprint's Dify recommendation before committing to one. |

## Full status report

See [`HQ_STATUS.md` in the blueprint repo](https://github.com/as307/---/blob/main/HQ_STATUS.md) for the complete picture: what's live, what's duplicated, what's still Phase 0, and open decisions.

## Fast links

- Memory Hub (live): http://localhost:8125/
- Blueprint checklist: `~/OmO/hq/INTEGRATION_CHECKLIST.md`
