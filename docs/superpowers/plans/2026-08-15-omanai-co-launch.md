# omanai.co Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the existing `oman-lead-bot` SaaS to production (Convex + Vercel), then build and deploy the `omanai.co` landing page listing it and Scopekeeper as the company's two real, sellable services.

**Architecture:** Part A takes an already-built, tested, CI-green codebase (`aj-omanai/oman-lead-bot` — Vite/React/Convex/Stripe/WhatsApp) from "code complete, not deployed" to a live production URL. Part B is a new, separate static marketing site (Vite/React/Tailwind, same stack family for team consistency) deployed under the `omanai.co` apex domain, with the product living at a subdomain. The landing page is intentionally thin — it lists two real services and links out; it does not duplicate any of `oman-lead-bot`'s logic.

**Tech Stack:** Vite, React 19, TypeScript, Tailwind, Convex (backend/DB/auth), Vercel (hosting for both apps), Vitest + Testing Library (landing page tests).

**Spec:** No separate spec doc exists — this plan's Architecture section and Global Constraints below are the spec, informed by `OmO-claude/STATUS.md` and `HQ_STATUS.md` (github.com/as307/OmO) and the interview that produced this plan.

## Global Constraints

- **No auto-send.** Any code path that sends a WhatsApp message, email, or outbound outreach requires explicit human approval before dispatch — this is already how `oman-lead-bot` is built; do not weaken it during deploy.
- **Never commit secrets.** Groq/Gemini/Stripe/WhatsApp/Convex deploy keys go into Convex environment variables and Vercel project environment variables only — never into a repo, commit, or this plan file.
- **Landing page lists exactly two services**: AI Lead Generation & Outreach (`oman-lead-bot`) and AI Prompt Governance (Scopekeeper). No unbuilt ideas (ERP/Odoo, Fawtarati, AI Lawyer) get listed — confirmed via interview.
- **Domain split**: `omanai.co` apex → landing page. `app.omanai.co` → `oman-lead-bot` production frontend.
- Every task ends with a verification step you can actually run and check the output of — no "it should work now" without a command.

---

## Part A — Deploy `oman-lead-bot` to production

### Task 1: Clone and prepare the repo

**Files:**
- Create (via clone): `~/oman-lead-bot/` (full existing repo tree from `aj-omanai/oman-lead-bot`)

**Interfaces:**
- Produces: a local checkout at `~/oman-lead-bot` with dependencies installed, used by every later task in Part A.

- [ ] **Step 1: Clone the repo**

```bash
git clone https://github.com/aj-omanai/oman-lead-bot.git ~/oman-lead-bot
cd ~/oman-lead-bot
```

- [ ] **Step 2: Install dependencies**

```bash
cd ~/oman-lead-bot && bun install
```

Expected: completes without error, `node_modules/` and `bun.lock` (already committed) match.

- [ ] **Step 3: Run the existing test suite to confirm the clone is healthy**

```bash
cd ~/oman-lead-bot && bun run test
```

Expected: PASS — 18 tests (per the repo's own README), no external services required.

- [ ] **Step 4: Typecheck**

```bash
cd ~/oman-lead-bot && bun tsc -b --noEmit
```

Expected: no type errors.

- [ ] **Step 5: Commit nothing yet** — this task only establishes the local checkout. No git changes are made to the product repo. Verify clean tree:

```bash
cd ~/oman-lead-bot && git status --short
```

Expected: empty output.

---

### Task 2: Deploy the Convex backend to production

**Files:**
- Modify: `~/oman-lead-bot/.env.local` (created by the Convex CLI, gitignored — never commit this file)

**Interfaces:**
- Consumes: the healthy checkout from Task A1.
- Produces: a live Convex production deployment URL (format `https://<deployment-name>.convex.cloud`), consumed by Task A3.

- [ ] **Step 1: Log in to Convex** (interactive — requires a human to complete the browser OAuth flow; do not attempt to script around this)

```bash
cd ~/oman-lead-bot && npx convex login
```

Expected: opens a browser, confirms login in the terminal.

- [ ] **Step 2: Deploy to a new production project**

```bash
cd ~/oman-lead-bot && npx convex deploy
```

Expected: CLI prints a production deployment URL — copy it, it's needed in Task A3 as `VITE_CONVEX_URL`.

- [ ] **Step 3: Set the minimum required environment variables in the Convex dashboard** (Settings → Environment Variables, production deployment)

Required for the app to function at all:
- `GROQ_API_KEY` — free key from console.groq.com/keys, no credit card.
- `GEMINI_API_KEY` — free key from aistudio.google.com/apikey (fallback if Groq is rate-limited).

Optional, add when ready to enable that feature (not required for initial deploy):
- `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` — billing.
- `ZEROBOUNCE_API_KEY` — email verification.
- `WHATSAPP_TOKEN` / `WHATSAPP_PHONE_NUMBER_ID` / `WHATSAPP_VERIFY_TOKEN` — WhatsApp sending.

- [ ] **Step 4: Verify the deployment is live**

```bash
curl -s -o /dev/null -w "convex http=%{http_code}\n" "$(npx convex env get CONVEX_SITE_URL 2>/dev/null)"
```

Expected: `http=200` or `http=404` (Convex's root path is often unrouted — a response at all confirms the deployment is up, a connection error does not).

- [ ] **Step 5: No commit** — Convex config lives server-side; nothing to commit locally from this step.

---

### Task 3: Deploy the frontend to Vercel, wired to production Convex

**Files:**
- Create: `~/oman-lead-bot/vercel.json` (if not already present in the cloned repo — check first)

**Interfaces:**
- Consumes: the `VITE_CONVEX_URL` produced in Task A2.
- Produces: a live `https://<project>.vercel.app` URL, later pointed at `app.omanai.co` in Task B6.

- [ ] **Step 1: Check whether vercel.json already exists**

```bash
cat ~/oman-lead-bot/vercel.json 2>/dev/null || echo "not present"
```

- [ ] **Step 2: If not present, create it** (SPA rewrite so client-side routing works on refresh)

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

Write this to `~/oman-lead-bot/vercel.json` only if Step 1 printed "not present".

- [ ] **Step 3: Log in to Vercel** (interactive)

```bash
cd ~/oman-lead-bot && npx vercel login
```

- [ ] **Step 4: Link and deploy**

```bash
cd ~/oman-lead-bot && npx vercel link --yes
npx vercel env add VITE_CONVEX_URL production
# paste the Convex production URL from Task A2 Step 2 when prompted
npx vercel env add CONVEX_SITE_URL production
# paste the same value, or the CONVEX_SITE_URL if different — check with:
#   npx convex env get CONVEX_SITE_URL
npx vercel --prod
```

Expected: CLI prints a production URL (`https://oman-lead-bot-*.vercel.app` or similar).

- [ ] **Step 5: Verify the live site loads and auth works**

```bash
curl -s -o /dev/null -w "vercel http=%{http_code}\n" "<the production URL from Step 4>"
```

Expected: `http=200`. Then manually open the URL, go to `/auth`, request an email OTP, confirm the email arrives and sign-in completes.

- [ ] **Step 6: Commit `vercel.json` if it was newly created**

```bash
cd ~/oman-lead-bot
git add vercel.json 2>/dev/null
git commit -m "chore: add Vercel SPA rewrite config" 2>/dev/null || echo "nothing to commit — vercel.json already existed"
git push origin main
```

---

## Part B — `omanai.co` landing page

### File Structure

```
~/omanai-co/
  package.json
  vite.config.ts
  tsconfig.json
  tailwind.config.ts
  postcss.config.js
  index.html
  vercel.json
  src/
    main.tsx
    App.tsx
    index.css
    data/
      services.ts              -- the two real services, typed
    components/
      Header.tsx
      Hero.tsx
      ServiceCard.tsx
      Services.tsx
      Footer.tsx
      __tests__/
        ServiceCard.test.tsx
        Services.test.tsx
  .github/workflows/ci.yml
  README.md
```

Each component is single-responsibility: `ServiceCard` renders one service, `Services` maps the data array through it, `Hero`/`Header`/`Footer` are static presentation with no shared state — no component needs to reach outside its own props.

---

### Task 4: Scaffold the project

**Files:**
- Create: `~/omanai-co/package.json`, `vite.config.ts`, `tsconfig.json`, `tailwind.config.ts`, `postcss.config.js`, `index.html`, `src/main.tsx`, `src/index.css`

**Interfaces:**
- Produces: a running Vite dev server at `localhost:5173`, consumed by every later task in Part B.

- [ ] **Step 1: Scaffold with Vite**

```bash
cd ~ && npm create vite@latest omanai-co -- --template react-ts
cd ~/omanai-co && npm install
```

- [ ] **Step 2: Add Tailwind**

```bash
cd ~/omanai-co && npm install -D tailwindcss postcss autoprefixer @tailwindcss/vite
```

`vite.config.ts`:

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

`src/index.css` (replace the Vite default entirely):

```css
@import "tailwindcss";

:root {
  --ink: #142322;
  --paper: #eff2ee;
  --teal-700: #1a5551;
  --gold-600: #b07f28;
  --line: rgba(20, 35, 34, 0.14);
}

body {
  background: var(--paper);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
```

- [ ] **Step 3: Add test tooling**

```bash
cd ~/omanai-co && npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

`vite.config.ts` — add the test block:

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: "./src/test-setup.ts",
  },
});
```

Create `src/test-setup.ts`:

```typescript
import "@testing-library/jest-dom/vitest";
```

`package.json` — add to `"scripts"`:

```json
"test": "vitest run"
```

- [ ] **Step 4: Verify the dev server runs**

```bash
cd ~/omanai-co && timeout 5 npm run dev 2>&1 | head -10
```

Expected: prints a `Local: http://localhost:5173/` line before the timeout kills it.

- [ ] **Step 5: Verify tests run** (no tests exist yet — expect a clean "no test files" pass, not an error)

```bash
cd ~/omanai-co && npm run test 2>&1 | tail -10
```

Expected: vitest reports 0 tests found, exits 0 — not a crash.

- [ ] **Step 6: Init git and commit**

```bash
cd ~/omanai-co
git init
git add -A
git commit -m "chore: scaffold omanai-co with Vite, React, Tailwind, Vitest"
```

---

### Task 5: Services data + `ServiceCard` component (TDD)

**Files:**
- Create: `src/data/services.ts`
- Create: `src/components/ServiceCard.tsx`
- Test: `src/components/__tests__/ServiceCard.test.tsx`

**Interfaces:**
- Produces: `Service` type and `services` array (consumed by Task B3's `Services.tsx`), `ServiceCard` component with props `{ service: Service }`.

- [ ] **Step 1: Write the failing test**

```typescript
// src/components/__tests__/ServiceCard.test.tsx
import { render, screen } from "@testing-library/react";
import { ServiceCard } from "../ServiceCard";
import type { Service } from "../../data/services";

const sample: Service = {
  id: "lead-bot",
  name: "AI Lead Generation & Outreach",
  status: "live",
  description: "AI-scored leads, Gulf-Arabic pitches, WhatsApp and email outreach, and a sales pipeline — self-serve.",
  ctaLabel: "Try it free",
  ctaHref: "https://app.omanai.co",
};

test("renders the service name, description, and status", () => {
  render(<ServiceCard service={sample} />);
  expect(screen.getByText("AI Lead Generation & Outreach")).toBeInTheDocument();
  expect(screen.getByText(/AI-scored leads/)).toBeInTheDocument();
  expect(screen.getByText("Live")).toBeInTheDocument();
});

test("the CTA links to the correct href", () => {
  render(<ServiceCard service={sample} />);
  const link = screen.getByRole("link", { name: "Try it free" });
  expect(link).toHaveAttribute("href", "https://app.omanai.co");
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd ~/omanai-co && npm run test -- ServiceCard 2>&1 | tail -20
```

Expected: FAIL — `Cannot find module '../ServiceCard'` and `'../../data/services'`.

- [ ] **Step 3: Write the data file**

```typescript
// src/data/services.ts
export type ServiceStatus = "live" | "early-access";

export interface Service {
  id: string;
  name: string;
  status: ServiceStatus;
  description: string;
  ctaLabel: string;
  ctaHref: string;
}

export const services: Service[] = [
  {
    id: "lead-bot",
    name: "AI Lead Generation & Outreach",
    status: "live",
    description:
      "AI-scored leads, Gulf-Arabic pitches, WhatsApp and email outreach, and a sales pipeline — self-serve.",
    ctaLabel: "Try it free",
    ctaHref: "https://app.omanai.co",
  },
  {
    id: "scopekeeper",
    name: "AI Prompt Governance",
    status: "early-access",
    description:
      "Free custom Scopekeeper build for AI and software teams — structures every prompt and blocks unauthorized requests until approved.",
    ctaLabel: "Request early access",
    ctaHref: "mailto:aj@omanai.co?subject=Scopekeeper%20early%20access",
  },
];
```

- [ ] **Step 4: Write the component**

```typescript
// src/components/ServiceCard.tsx
import type { Service } from "../data/services";

const statusLabel: Record<Service["status"], string> = {
  live: "Live",
  "early-access": "Early access",
};

export function ServiceCard({ service }: { service: Service }) {
  return (
    <div className="rounded-md border border-[var(--line)] bg-white/60 p-6 flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-lg">{service.name}</h3>
        <span className="text-xs uppercase tracking-wide text-[var(--teal-700)]">
          {statusLabel[service.status]}
        </span>
      </div>
      <p className="text-sm text-[var(--ink)]/80">{service.description}</p>
      <a
        href={service.ctaHref}
        className="mt-2 inline-block text-sm font-medium text-[var(--gold-600)] hover:underline"
      >
        {service.ctaLabel} →
      </a>
    </div>
  );
}
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd ~/omanai-co && npm run test -- ServiceCard 2>&1 | tail -20
```

Expected: PASS — 2 tests.

- [ ] **Step 6: Commit**

```bash
cd ~/omanai-co
git add src/data/services.ts src/components/ServiceCard.tsx src/components/__tests__/ServiceCard.test.tsx
git commit -m "feat: add services data and ServiceCard component"
```

---

### Task 6: `Services` section, `Hero`, `Header`, `Footer`, assemble `App`

**Files:**
- Create: `src/components/Services.tsx`, `src/components/Hero.tsx`, `src/components/Header.tsx`, `src/components/Footer.tsx`
- Test: `src/components/__tests__/Services.test.tsx`
- Modify: `src/App.tsx`

**Interfaces:**
- Consumes: `services` array and `ServiceCard` from Task B2.
- Produces: `App` — the full assembled page, no further tasks depend on its internals.

- [ ] **Step 1: Write the failing test**

```typescript
// src/components/__tests__/Services.test.tsx
import { render, screen } from "@testing-library/react";
import { Services } from "../Services";

test("renders one card per service", () => {
  render(<Services />);
  expect(screen.getByText("AI Lead Generation & Outreach")).toBeInTheDocument();
  expect(screen.getByText("AI Prompt Governance")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd ~/omanai-co && npm run test -- Services 2>&1 | tail -20
```

Expected: FAIL — `Cannot find module '../Services'`.

- [ ] **Step 3: Write `Services.tsx`**

```typescript
// src/components/Services.tsx
import { services } from "../data/services";
import { ServiceCard } from "./ServiceCard";

export function Services() {
  return (
    <section id="services" className="max-w-4xl mx-auto px-6 py-16">
      <h2 className="text-2xl font-semibold mb-8">What we build</h2>
      <div className="grid gap-6 sm:grid-cols-2">
        {services.map((service) => (
          <ServiceCard key={service.id} service={service} />
        ))}
      </div>
    </section>
  );
}
```

- [ ] **Step 4: Run to verify it passes**

```bash
cd ~/omanai-co && npm run test -- Services 2>&1 | tail -20
```

Expected: PASS.

- [ ] **Step 5: Write the static components** (no tests required — no logic, pure presentation)

```typescript
// src/components/Header.tsx
export function Header() {
  return (
    <header className="max-w-4xl mx-auto px-6 py-6 flex items-center justify-between">
      <span className="font-semibold tracking-tight">OmanAI</span>
      <a href="#services" className="text-sm text-[var(--teal-700)] hover:underline">
        Services
      </a>
    </header>
  );
}
```

```typescript
// src/components/Hero.tsx
export function Hero() {
  return (
    <section className="max-w-4xl mx-auto px-6 py-20 text-center">
      <h1 className="text-4xl sm:text-5xl font-semibold tracking-tight text-balance">
        AI automation, built in Oman, for the Gulf.
      </h1>
      <p className="mt-4 text-lg text-[var(--ink)]/70 max-w-xl mx-auto">
        Two real products, not slideware — see what's live below.
      </p>
    </section>
  );
}
```

```typescript
// src/components/Footer.tsx
export function Footer() {
  return (
    <footer className="max-w-4xl mx-auto px-6 py-10 mt-10 border-t border-[var(--line)] text-sm text-[var(--ink)]/60 flex justify-between">
      <span>OmanAI · Muscat</span>
      <a href="mailto:aj@omanai.co" className="hover:underline">
        aj@omanai.co
      </a>
    </footer>
  );
}
```

- [ ] **Step 6: Assemble `App.tsx`**

```typescript
// src/App.tsx
import { Header } from "./components/Header";
import { Hero } from "./components/Hero";
import { Services } from "./components/Services";
import { Footer } from "./components/Footer";

export default function App() {
  return (
    <div>
      <Header />
      <Hero />
      <Services />
      <Footer />
    </div>
  );
}
```

- [ ] **Step 7: Run the full test suite**

```bash
cd ~/omanai-co && npm run test 2>&1 | tail -20
```

Expected: PASS — all tests from Task B2 and B3.

- [ ] **Step 8: Visually verify** — start the dev server and confirm the page renders both service cards, the hero, and the footer with a working mailto link.

```bash
cd ~/omanai-co && npm run dev
```

Open `http://localhost:5173`, check manually, then stop the server (Ctrl+C).

- [ ] **Step 9: Commit**

```bash
cd ~/omanai-co
git add src/components/Services.tsx src/components/Hero.tsx src/components/Header.tsx src/components/Footer.tsx src/components/__tests__/Services.test.tsx src/App.tsx
git commit -m "feat: assemble landing page — hero, services, header, footer"
```

---

### Task 7: CI workflow

**Files:**
- Create: `~/omanai-co/.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `npm run test` and `tsc` from earlier tasks.
- Produces: nothing consumed by later tasks — this is a terminal verification task.

- [ ] **Step 1: Write the workflow**

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - run: npm run test
      - run: npx tsc -b --noEmit
```

- [ ] **Step 2: Verify the YAML is syntactically valid**

```bash
python3 -c "import yaml; yaml.safe_load(open('/home/yaman/omanai-co/.github/workflows/ci.yml'))" && echo "valid"
```

Expected: `valid`.

- [ ] **Step 3: Commit**

```bash
cd ~/omanai-co
git add .github/workflows/ci.yml
git commit -m "ci: add test + typecheck workflow"
```

---

### Task 8: Create the GitHub repo and push

**Files:** none new — this task pushes the existing local repo.

**Interfaces:**
- Consumes: the full local `~/omanai-co` repo from Tasks B1-B4.
- Produces: `https://github.com/aj-omanai/omanai-co`, consumed by Task B6's Vercel deploy.

- [ ] **Step 1: Create the repo on GitHub**

```bash
gh repo create aj-omanai/omanai-co --public --source=/home/yaman/omanai-co --remote=origin --push
```

Expected: prints the new repo URL, pushes `main`.

- [ ] **Step 2: Verify CI runs and passes on the push**

```bash
sleep 15 && gh run list --repo aj-omanai/omanai-co --limit 1 --json status,conclusion
```

Expected: `"status":"completed"`, `"conclusion":"success"` (may need to poll again if still `in_progress`).

- [ ] **Step 3: No further commit** — this task is the push itself.

---

### Task 9: Deploy to Vercel under `omanai.co`, wire DNS, verify both sites live

**Files:**
- Create: `~/omanai-co/vercel.json` (only if the app needs SPA rewrites — a static multi-section page on one route does not, but add it for future routes)

**Interfaces:**
- Consumes: the live GitHub repo from Task B5, the `oman-lead-bot` production URL from Task A3.
- Produces: `https://omanai.co` (landing page) and `https://app.omanai.co` (product) both live — the final deliverable of this plan.

- [ ] **Step 1: Deploy to Vercel**

```bash
cd ~/omanai-co
npx vercel link --yes
npx vercel --prod
```

Expected: prints a `https://omanai-co-*.vercel.app` URL.

- [ ] **Step 2: Add the apex domain in the Vercel project dashboard**

Vercel dashboard → omanai-co project → Settings → Domains → add `omanai.co`. Vercel will show the DNS records to add (typically an `A` record to `76.76.21.21` or a `CNAME`).

- [ ] **Step 3: Add the DNS records at the domain registrar** (wherever `omanai.co` is registered — per earlier session notes, likely Namecheap)

Add the apex record Vercel specified for `omanai.co`, and a `CNAME` for `app` pointing at the `oman-lead-bot` Vercel project's domain (from Task A3).

- [ ] **Step 4: Add `app.omanai.co` in the `oman-lead-bot` Vercel project**

Vercel dashboard → oman-lead-bot project → Settings → Domains → add `app.omanai.co`.

- [ ] **Step 5: Wait for DNS propagation, then verify both**

```bash
sleep 60
curl -s -o /dev/null -w "omanai.co http=%{http_code}\n" https://omanai.co
curl -s -o /dev/null -w "app.omanai.co http=%{http_code}\n" https://app.omanai.co
```

Expected: both `http=200`. DNS propagation can take longer than 60s — if either fails, wait and retry rather than treating it as broken.

- [ ] **Step 6: Update the shared status record**

```bash
cat >> ~/OmO/core/OmO-claude/STATUS.md << 'EOF'

## Update — omanai.co is live

- **https://app.omanai.co** — oman-lead-bot, production (Convex + Vercel).
- **https://omanai.co** — landing page, listing AI Lead Generation & Outreach (live) and AI Prompt Governance / Scopekeeper (early access, mailto CTA).
- Both deployed per docs/superpowers/plans/2026-08-15-omanai-co-launch.md.
EOF
cd ~/OmO/core && git add OmO-claude/STATUS.md && git commit -m "docs: omanai.co is live" && git push origin HEAD
```

---

## Self-Review

**Spec coverage:** deploy target (Convex + Vercel) → Task A2/A3. Landing page for omanai.co → Part B. Services list, Tier 1 + 2 only → `services.ts` in Task B2, confirmed no Tier 3/4 items included. Domain split (apex vs. `app.`) → Task B6. No-auto-send constraint → inherited from `oman-lead-bot`'s existing design, explicitly called out in Global Constraints so no task weakens it during deploy.

**Placeholder scan:** no TBD/TODO markers; every code step has real, complete code; every infra step has a real, runnable command with an expected result to check against.

**Type consistency:** `Service` type defined once in `src/data/services.ts` (Task B2), imported by `ServiceCard.tsx` (Task B2) and `Services.tsx` (Task B3) — no redefinition, no drift.
