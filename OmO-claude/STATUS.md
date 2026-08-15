# OmO-claude — Claude Code's working notes

Kept separate from `OmO-freebuff/` and the root `README.md` on purpose, so
Claude and Freebuff/Buffy don't overwrite each other's files while both are
active on this repo (one locally, one via the Codespace).

## What Claude did in this repo
- Renamed `nexus-ai-marketing-agency` -> `OmO` on GitHub (2026-08-15).
- Rewrote root `README.md` to map the whole HQ: this repo, the blueprint
  repo (`as307/---`), the agency-agents roster, the live Memory Hub, and
  `OmO-freebuff/`.
- Full status report lives in the blueprint repo:
  https://github.com/as307/---/blob/main/HQ_STATUS.md

## Coordination note for whoever reads this next (human or agent)
- Root `README.md` is shared/contested ground — check git blame/log before
  editing it again, both Claude and Freebuff have touched it.
- Prefer adding your own dated file in `OmO-claude/` or `OmO-freebuff/`
  over editing the other agent's files.

## Update — same session, later

### Live agent team created in the dashboard
Memory Hub (`http://localhost:8125/#/team/agents`) now has 4 real agents (team `tdai-memory` / `team-2z1n59cudp`), each with a role prompt grounded in the actual OmanAI business (not generic templates):

| Agent | ID | Role |
|---|---|---|
| HQ Orchestrator | `agt-22xb7h1qt7` | Routes tasks across the team, tracks blueprint checklist phases, pulls specialists from the 316-agent roster when needed |
| WhatsApp Agent Ops | `agt-22uw3uv7zr` | Owns the Twilio+Claude WhatsApp AI agent product (the actual revenue service) |
| Outreach & Sales | `agt-22vr3ycxtf` | Runs the Scopekeeper outreach pipeline, pilot-to-paid conversion, pricing |
| Client Success & Onboarding | `agt-22wibafbgv` | Client-Onboarding-SOP, monthly reporting |

Each has `skills` / `code_graph` / `llm_wiki` / `chat_memory` capability slots — currently empty (0 wiki sources, 0 skills ingested yet). Next real step: point Wiki Knowledge Base at the `agency-agents` repo and the OmanAI Drive playbooks so these agents actually have something to draw on.

### OmniRouter started
Local OpenAI-compatible LLM gateway now running on `http://127.0.0.1:20128` (`~/start-router.sh`) — gives Dify/gpt-researcher/etc. a local model endpoint without needing new external API keys.

### Google Drive sweep — the real business context
Confirmed from `/Omanai-ops/` (owner `aj@omanai.co`), dated back to 2026-06-23:
- **OmanAI** = solo AI-native marketing agency, Muscat, Oman. Lead product: **WhatsApp AI Agents** for construction/aluminum/interior-fit-out clients (Phase 1), F&B (Phase 2).
- Domain `omanai.co` (Namecheap), Google Workspace Business Starter, email `aj@omanai.co` — all live.
- Planned stack: Claude API + Twilio WhatsApp Sandbox + Python/Flask backend — **Twilio and the Flask backend were still "pending" as of the last Drive update**; check whether `ai_company_server`/`ai-os` superseded this.
- **Composio was evaluated and explicitly parked (Q3 2026 review) — "failed Scout gate, no production agents yet."** Don't re-introduce it into the blueprint stack without knowing why it failed.
- Existing real playbooks already written and usable, not yet linked into any of this: `Agency-Master-Playbook.md`, `Client-Onboarding-SOP.md`, `Pricing-and-Proposal-Template.md`, `Monthly-Client-Report-Template.md`, `Pilot-to-Paid-Conversion-Script.md`, `Scopekeeper Outreach Pipeline`, `omanai-income-plan.md`, plus recurring `ops-digest-*` / `company-digest-*` docs (twice-daily, June–July 2026) suggesting an existing automated reporting habit worth continuing.
- A large (11MB) Gemini Canvas doc, "Omani AI Lawyer Brain SaaS/ERP" — a separate product idea, not evaluated here.

**Gap to flag:** `Project-Hub.md` (the Drive status doc) hasn't been updated since 2026-06-23, while `~/ai_company`, `~/ai-os`, `~/agency-agents`, `~/aaa-agency` show heavy activity through Aug 13-15. The Drive record and the actual filesystem state have drifted apart — worth reconciling so Drive reflects reality again.

## Update — wired the Wiki to agency-agents

Created a Team Wiki Pool knowledge base named `agency-agents` (`wiki-tw5ysnnv`) in Memory Hub and seeded it with 6 curated agent personas (condensed, with links back to the full source in `aj-omanai/agency-agents`), chosen for direct relevance to the real OmanAI business rather than uploading all 316:

- `agents-orchestrator.md` — pipeline/task orchestration
- `specialized-chief-of-staff.md` — coordination, process ownership
- `sales-outbound-strategist.md` — signal-based outreach (maps to Scopekeeper pipeline)
- `sales-proposal-strategist.md` — win themes, pricing narrative
- `finance-bookkeeper-controller.md` — close process, reconciliation
- `marketing-content-creator.md` — editorial/content strategy

Ingestion is running server-side via the `MEMORY_LLM_*` config in `.env` (OpenRouter, `openai/gpt-oss-20b:free`) — each doc gets a real LLM analysis pass, ~minutes per doc on the free tier, so this finishes on its own in the `tdai-memory-hub` container; no need to keep a browser open. Once status flips from "Processing" to "Ready" (`localhost:8125/#/wiki`), use "Allocate" to attach it to the 4 agents so their `llm_wiki` capability actually has content.

**Not done / next:** the other ~310 agency-agents personas aren't in this wiki — added only what's relevant now. Add more by the same "Markdown" paste flow if a task needs a division not covered here.
