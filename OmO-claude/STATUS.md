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

## Update — real playbooks loaded, 5th agent added, a real conflict surfaced

### New wiki: `omanai-playbooks`
Pulled and loaded the actual operating documents from Drive (not personas — your real sales/ops docs), ingesting now:
`agency-master-playbook.md`, `client-onboarding-sop.md`, `pricing-and-proposal-template.md`, `pilot-to-paid-conversion-script.md`, `scopekeeper-outreach-pipeline.md`, `omanai-income-plan.md`, `whatsapp-agent-service-brief.md`.

### 5th agent: AI Tools Outreach (Scopekeeper) — `agt-24if4hb2km`
Discovered a **second real business line** buried in today's Drive docs, distinct enough it needed its own agent: **Scopekeeper**, a prompt-governance tool (code at `~/scopekeeper`, not currently running), offered free to AI/SaaS companies as a lead magnet. Different ICP (CTO/Head of Eng/Founder at AI companies) than the WhatsApp product (Oman construction/aluminum/fit-out). Real progress already exists: Apollo.io connected (190 lead credits, 5000 AI credits, aj@omanai.co), 3 real leads sourced (DevsData, The AI Automation Agency, AgentMail), 3 emails drafted, 1 Apollo contact created.

**This agent is explicitly instructed to never send an email or activate a sequence without your review** — that's your own documented design, not something I'm loosening.

### A real conflict you should resolve, not me
Found **three parallel, not-yet-reconciled offers** across the Drive docs:
1. WhatsApp AI Agents → Oman construction/aluminum/fit-out (Agency-Master-Playbook, most built-out, has a full sales/onboarding SOP)
2. Scopekeeper → AI/SaaS companies (today's doc, has 3 leads and drafts ready)
3. n8n automation service → general GCC SMEs (omanai-income-plan.md, dated as the "AJ + Partner" plan, explicitly says *"pick ONE to lead with — running four offers with two people is the most common way this stalls"*)

Also: **`omanai-income-plan.md` introduces a partner** (`as@omanai.co`) that doesn't appear in the older Agency-Master-Playbook — this is the real answer to "which email, aj@ or as@" from earlier in this conversation. Apollo's credits are tied to `aj@`; the income plan flags this exact ownership question as unresolved.

**I'm not picking one of these three for you.** That's a business call, not an org call. Flagging it clearly is the job.

### Two blockers only you can clear (not agent work)
- Apollo contact creation is blocked by this Claude Code session's own permission classifier (same thing that blocked a `git push` earlier) — needs a permission rule added, or add the last 2 contacts manually in Apollo.
- No sending mailbox connected in Apollo yet — nothing can actually send until one is.

Neither of these get worked around — per your own pipeline doc, no email goes out un-reviewed, and permission blocks aren't mine to bypass.

## Update — OmniRouter moved to Codespace, cross-team tasks, session paused

- **OmniRouter moved off local device into the Codespace** (was 23% CPU / 1.3GB RAM locally). Killed here, reinstalled + running in `redesigned-potato-...github.dev` (`omniroute serve`, confirmed `http=200` on :20128 there).
- **Claude Code CLI installed in the Codespace** (`v2.1.233`) so work can actually happen there going forward. Freebuff itself (the manicode binary) was NOT copied in — it's a ~140MB proprietary binary, not portable via a simple install; flagged rather than faked.
- **Cross-team coordination task posted** on `Nexus Marketing Agency`'s board (Freebuff's team): proposed split — their team owns marketing/content (SEO, copy, campaign strategy, matches their 3 existing tasks), our team (`tdai-memory`) owns sales/ops (WhatsApp product, Scopekeeper, onboarding, business-context grounding).
- **4 of 5 per-agent tasks created** on `tdai-memory`'s board: HQ Orchestrator (reconcile 3-offer conflict), WhatsApp Agent Ops (Twilio sandbox + pilot config), Outreach & Sales (resume Aluminum Plus/Muscat warm outreach), Client Success & Onboarding (prep onboarding pipeline).
- **5th task incomplete**: "[AI Tools Outreach] Escalate Apollo blockers to AJ" — form was filled but the Chrome extension disconnected before the Create click landed; unconfirmed whether it saved. **Verify and recreate if missing**: `localhost:8125` → tdai-memory team → Task Board.
- Session paused here (browser extension down, needs Chrome reconnected on the user's end to continue browser-driven work). Everything Bash/API-based stayed intact.

## HANDOFF — Claude is pausing (usage limit), picking up here

Freebuff / whoever continues: this is the current blocker queue, most impactful first.

1. **Chrome extension is disconnected** for the `claude-in-chrome` browser tool — this blocked the last several actions (Codespace terminal access, Memory Hub task board). If you have another way into the Codespace terminal (native SSH, `gh codespace ssh` after `gh auth refresh -h github.com -s codespace`), use that instead of waiting on the extension.
2. **Install in the Codespace** (`redesigned-potato-...github.dev`, repo `as307/OmO`): `npm install -g freebuff omniroute` + confirm `claude` (already installed, v2.1.233). OmniRouter should already be running there (`omniroute serve`, was confirmed http=200 on :20128) — just verify it survived.
3. **Verify the 5th task on `tdai-memory`'s board** ("[AI Tools Outreach] Escalate Apollo blockers to AJ") actually saved — the create click landed right as the extension dropped, unconfirmed.
4. **The one real decision still open**: WhatsApp agents vs Scopekeeper vs n8n automation — pick one to lead with. Everything else (task boards, wikis, agent rosters) is scaffolding around a business decision only AJ can make. Don't let more infrastructure work substitute for surfacing this to him again if it's still unresolved.

Claude will resume from this file when the session continues.

## Update — the actual "ready SaaS": aj-omanai/oman-lead-bot

User pointed to a private repo as "ready" — the exact one didn't exist (as307/- and as307/arabic-ai-lawyer-oman are both empty stubs, GitHub confirms 0 bytes on both). But a real one turned up under a **second GitHub account, `aj-omanai`**, found via Gmail CI-failure notifications, not Drive.

**`aj-omanai/oman-lead-bot`** — "Oman Lead Bot": zero-cost AI-powered B2B lead gen for Oman/GCC.
- Real stack: Vite + React 19 + TS, Tailwind v4 + shadcn/ui, **Convex** (backend/DB/auth), Stripe billing, official WhatsApp Business Cloud API (not Selenium), Framer Motion.
- Real features: CSV/yellowpages lead import, AI scoring (Hot/Warm/Cold, Groq→Gemini fallback), Gulf-Arabic AI-drafted pitches, email outreach w/ ZeroBounce verification, WhatsApp outreach, auto 3-day follow-ups (human-approved), sales pipeline kanban, 3-tier billing (Free/$19 Pro/$49 Business), full Arabic RTL mode.
- 18 tests, CI passing (green as of 2026-08-09). Human approves every send — matches the no-auto-send principle already set for the tdai-memory team.
- **Not deployed**: `.env.example` has empty `VITE_CONVEX_URL`/`CONVEX_DEPLOYMENT` — code is done, nothing is live yet. Needs: `npx convex dev`/deploy, at minimum a free Groq or Gemini key to function, Stripe keys for billing, Meta WhatsApp Business tokens for WhatsApp sending.

**This one repo functionally overlaps/supersedes two of the three competing offers** (WhatsApp outreach + general lead-gen automation) in a single packaged product — it doesn't touch Scopekeeper, which remains distinct.

Also found and worth a look separately: `aj-omanai/gcc-ai-agent` (same-day predecessor, likely renamed into oman-lead-bot — 404s now), and an n8n trial that was never upgraded — workflows auto-delete ~90 days from 2026-07-28 (~Oct 26 deadline) unless downloaded or upgraded.

## Update — wrote the missing `OmO/scripts/memory.sh` ("blueprint Stage 2")

Freebuff's `memory-panel/` overlay (README, `install.sh`, `build-filtered.sh`,
`apply.sh`, `start.sh` — all verified real and correct against the actual
Panel source) documented and called a script that never existed:
`scripts/memory.sh`, described as the piece that "prefers the locally-built
`localhost/memory-hub-filtered` image when present — so every stack boot
serves the dashboard automatically." `start.sh` already called it
(`../scripts/memory.sh --dir "$TDAI_DIR"`); it just 404'd. `blueprint.sh`
Stage 2 had the *same* logic inlined separately, with a real bug: it
overrides `MEMORY_HUB_IMAGE` by `cp .env .env.bp-bak; sed -i ...; [restore
after boot]` — an in-place mutation of the *shared* `.env`. If the process
dies between the sed and the restore (kill, crash, Ctrl-C), the real `.env`
is left pointed at a machine-local-only image tag, silently breaking the
next boot for anyone else who reads that file.

Wrote `OmO/scripts/memory.sh` for real, as a sibling of `core/`/`hq/`/
`memory-panel/` (matches the path `start.sh` already resolves). Design:
checks for the checkout + `.env` (clones/scaffolds like the existing
scripts do), checks for `localhost/memory-hub-filtered:latest`, and when
present applies the override through a **throwaway derived env file**
(`ENV_FILE=<mktemp, chmod 600>` passed to `start-all.sh` — a mechanism
`deploy/_lib.sh` already supports via `ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"`)
instead of touching the real `.env` at all. `trap cleanup EXIT` removes the
temp file regardless of success/failure. Then rewired `blueprint.sh` Stage 2
to just call this script, so the two entry points (blueprint.sh and
memory-panel/start.sh) share one implementation instead of drifting.

**Verified end-to-end, not just written:**
- Fallback path (no filtered image, the real current state — never built
  this session): ran it against the live `TDAI_DIR`, stack came back up
  clean (panel 200, knowledge 200), real `.env` untouched.
- Override path: temporarily `docker tag`'d the running hub image as
  `localhost/memory-hub-filtered:latest` (no full image build needed to
  test the logic), ran `memory.sh` again — confirmed via
  `docker inspect tdai-memory-hub --format '{{.Config.Image}}'` that the
  hub *actually booted on the filtered tag*, confirmed the real `.env`'s
  `MEMORY_HUB_IMAGE` line was byte-for-byte unchanged throughout, confirmed
  the derived temp file was gone after (trap fired). Then untagged the test
  image and restarted the stack back onto the real default image — no
  artifacts left behind.
- `blueprint.sh --dry-run` confirms Stage 2 now resolves to
  `bash /home/yaman/OmO/core/../scripts/memory.sh --dir <TDAI_DIR>` correctly.

Committed + pushed to `as307/OmO` (`5494a52`). `OmO/scripts/memory.sh`
itself is **not** in a git repo — same as `memory-panel/`, it's local-only
workspace scratch, consistent with how Freebuff left that whole subsystem
uncommitted so far. If/when `memory-panel/` gets committed somewhere,
`scripts/memory.sh` should move with it.
