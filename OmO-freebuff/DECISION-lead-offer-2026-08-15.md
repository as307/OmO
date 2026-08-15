# Offer Strategy Decision — 2026-08-15

**Decision: WhatsApp AI Agents is the lead offer.** Scopekeeper stays as a
low-cost lead-generation channel; the n8n automation service is parked until
its claimed package actually exists on disk.

## The three offers (as found in the Drive playbooks wiki)

| | WhatsApp AI Agents | Scopekeeper | n8n automation service |
|---|---|---|---|
| Docs | `agency-master-playbook.md`, `whatsapp-agent-service-brief.md`, `pricing-and-proposal-template.md`, `client-onboarding-sop.md`, `pilot-to-paid-conversion-script.md` | `scopekeeper-outreach-pipeline.md` | `omanai-income-plan.md` |
| Customer | Construction / aluminum / fit-out, Oman (Muscat-first), 5–50 staff | CTO / Head of Eng / Founder at 10–200 person AI/SaaS companies | General GCC SMEs drowning in manual WhatsApp/Excel work |
| Revenue model | Recurring: Starter OMR149 / Pro OMR299 / Full Ops OMR499 per month, pilot-to-paid (OMR999 founding offer) | Free custom build as proof-of-concept — lead magnet, no revenue model | Service fee — package claimed "already built" |
| What's real today | Full playbook (15-question discovery + scoring, 10 scripted objections, closing, onboarding SOP with 7 steps + QA bar, escalation protocol). Apex server (`ai_company_server`) **running**; Twilio connector coded but credentials **not set** in `.env` | Tool built (`~/scopekeeper`, Flask + OpenRouter + n8n webhook), **not running**. Apollo connected (190 lead credits, 0 used); 3 leads sourced; 3 emails drafted; 1 of 3 Apollo contacts created | n8n has **1 workflow** on disk, workflows dir empty, **not running** — the "5 workflows + installer, demo-ready" claim does not match disk reality |
| Blockers | Twilio creds + Meta WhatsApp Business API approval (1–3 business days), no paying clients yet | No sending mailbox connected in Apollo; sequence not built; permission classifier blocked 2 of 3 contact creates | Package doesn't exist yet; partner (`as@omanai.co`) ownership vs `aj@omanai.co` unresolved; n8n not running |

## Why WhatsApp AI Agents leads

1. **Only offer with a complete, executable operating system.** Discovery
   scoring, pricing tiers, proposal template, onboarding SOP (Day0–Day30 with a
   hard QA bar: 18/20 standard, all safety scenarios must pass), escalation
   protocol, pilot-to-paid script — everything needed to close, deliver, and
   retain a client already exists as written procedure.
2. **Only offer with running code.** The Apex automation server is live; the
   Twilio WhatsApp connector is implemented (inbound webhook with
   X-Twilio-Signature validation, outbound via the Messages API). The gap is
   configuration (Twilio creds, Meta Business API approval), not engineering.
3. **Clear, defensible positioning.** "Only agency in Oman for the
   construction/aluminum niche" with a bilingual (AR+EN) edge. The docs are
   explicit that the free 2-week pilot is the strongest close in Oman's
   trust-based market.
4. **The n8n "recommended lead" is contradicted by disk evidence.** The income
   plan recommends n8n *because* it's "already packaged, demo-ready" — but
   there is 1 workflow, an empty workflows dir, and no running instance. Picking
   it as lead would mean building first, then selling. WhatsApp is sellable
   after ~1–3 days of configuration.
5. **Scopekeeper is a lead magnet, not a revenue line.** It has no pricing and
   no delivery SOP. Its value is cheap inbound interest for a second ICP —
   keep it running on autopilot, don't staff it.

## Sequencing (not simultaneous full effort)

1. **Lead — WhatsApp AI Agents (all effort).** Finish configuration: set
   `TWILIO_ACCOUNT_SID` / `TWILIO_AUTH_TOKEN` / `TWILIO_WHATSAPP_FROM` in
   `~/ai_company/.env`, start Meta WhatsApp Business API approval, then run the
   existing playbook: warm outreach (Aluminum Plus network, Sas for
   Excellence) → discovery call → proposal → free 2-week pilot → pilot-to-paid
   conversion.
2. **Side channel — Scopekeeper (zero new effort).** Connect a sending mailbox
   in Apollo, finish the 2 remaining contact creates, run the 3 drafted emails
   paused with human review before activation. Generates a second ICP's inbound
   interest at near-zero cost. No email goes out un-reviewed — that stays the
   rule.
3. **Parked — n8n automation service.** Revisit only after the WhatsApp line
   has its first 1–2 paying clients AND the claimed package (5 workflows +
   installer) actually exists on disk. The income plan's "pick ONE to lead
   with" guidance is respected: WhatsApp is that one.

## What this means for the agents

- **HQ Orchestrator** routes WhatsApp-agent work first; Scopekeeper is a
  side channel; n8n is not scheduled until un-parked.
- **WhatsApp Agent Ops** owns the revenue line end-to-end (pilot → paid →
  onboarding).
- **Outreach & Sales** owns Scopekeeper as the secondary channel and supports
  WhatsApp outreach.
- **Client Success & Onboarding** runs the onboarding SOP for new WhatsApp
  clients.

## Open items that are still human decisions (not agent work)

- `aj@omanai.co` vs `as@omanai.co` account ownership (Apollo credits are tied
  to `aj@`; the income plan introduces `as@` as a partner).
- Twilio/Meta account credentials — the operator must supply these.
- Apollo sending mailbox — must be connected by the operator.

---
*Decision recorded by Buffy (Freebuff) on 2026-08-15 after reviewing the five
Drive playbook docs in the `omanai-playbooks` wiki and the on-disk state of
`~/scopekeeper`, `~/ai_company`, and the n8n data directory.*
