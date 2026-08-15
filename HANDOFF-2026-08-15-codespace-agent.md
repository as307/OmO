# Welcome, second agent (Freebuff in the codespace)

Written by **Buffy** (Freebuff, on the local machine) so a fresh agent
starting in this codespace can pick up the same picture without re-deriving
it. This repo (`as307/OmO`) is the shared truth — both agents work here,
push, and pull. **Read this whole file before doing anything.**

## Division of labor (as agreed)

- **Local machine (this repo, pushed from here):** owns the running stack —
  Memory Hub (team memory + agents + wikis), Dify orchestrator (Phase 1),
  MCP wiring (`connect-agents.sh`), OmniRouter port-forward. Buffy works
  here and pushes.
- **You (in this codespace):** code work — edits to this repo, the
  `agency-agents` roster, or anything pulled via git. You pull what Buffy
  pushes, work, and push back. **Never edit `OmO-claude/STATUS.md` or
  `OmO-freebuff/` notes — prefer a new dated file** (repo convention).

## What is LIVE right now (verified)

| Service | Where | URL / how to reach |
|---|---|---|
| Memory Hub (TencentDB Agent Memory) | local machine | panel `http://localhost:8125` · knowledge `:8424` · proxy `:8096` — **reachable from this codespace** via reverse tunnel (`localhost:8125`/`:8424`/`:8096` here) |
| Admin key | local machine | `~/tencentdb-agent-memory/deploy/global-images/.admin-key` (staged in this codespace at the same path, mode 600) |
| Dify orchestrator | local machine | `http://localhost:8080/console` (admin `aj@omanai.co` created; provider/tool/workflow import still needs UI steps — see `OmO-dify/README.md`) |
| OmniRouter LLM gateway | **this codespace** | `http://localhost:20128` · key `local-key` · models `auto/best-chat`, `auto/best-coding` |
| Claude Code CLI | this codespace | `claude` v2.1.233 |
| serena (IDE MCP) | local machine | registered in `connect-agents.sh` — run `uv tool install -p 3.13 serena-agent && serena init` here too if you want it |

## Team state (tdai-memory, `team-2z1n59cudp`)

- **5 agents:** HQ Orchestrator `agt-22xb7h1qt7` · WhatsApp Agent Ops
  `agt-22uw3uv7zr` · Outreach & Sales `agt-22vr3ycxtf` · Client Success &
  Onboarding `agt-22wibafbgv` · AI Tools Outreach (Scopekeeper)
  `agt-24if4hb2km`.
- **Wikis:** `agency-agents` (`wiki-tw5ysnnv`) ready + allocated; `omanai-playbooks`
  (`wiki-5hp5bhvp`) re-ingesting after a restart interruption — a watcher on
  the local machine allocates it to all 5 agents when ready.
- **5 tasks** on the board, all running — incl. the recreated
  `[AI Tools Outreach] Escalate Apollo blockers to AJ` (`task-28kffindifi`).

## The one real business decision (still open — surface it, don't decide)

WhatsApp AI Agents vs Scopekeeper vs n8n automation: **WhatsApp AI Agents is
the lead** (full operating system + running code; Twilio creds + Meta
approval still needed from AJ). Scopekeeper is a free-POC side channel. n8n
is parked. Don't let infrastructure work substitute for surfacing this to AJ
again if it's unresolved.

## Quick-start for you

```bash
# in this codespace
cd /workspaces/nexus-ai-marketing-agency
git pull --ff-only origin main        # get Buffy's latest
# Memory Hub API is at localhost:8125 (admin key above) if you need it
# OmniRouter is at localhost:20128 if you need an LLM
```

## Background tunnels (from the local machine — don't kill them)

- Reverse tunnel: local Memory Hub ports → codespace `localhost:8125/:8424/:8096`.
- OmniRouter port-forward: codespace `:20128` → local `localhost:20128`.
