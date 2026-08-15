# Design Systems (DESIGN.md)

Ready-to-use `DESIGN.md` files (Google Stitch format) for brand-consistent UI
generation. Source: [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md)
— analyzed from real brand design systems.

## Usage

Drop a `DESIGN.md` into your project root and tell the agent:
> "Build a page that looks like this" — or — "follow the design system in DESIGN.md"

Agents (and Google Stitch) read it to generate UI that matches the brand's
colors, type, spacing, and component language.

## Available here

| Directory | Brand | When to use |
|---|---|---|
| `linear.app/` | Linear | Clean SaaS product UI — dashboards, lists, settings |
| `claude/` | Anthropic Claude | Warm editorial/AI-brand feel — marketing pages |
| `framer/` | Framer | Modern web/agency portfolio feel |
| `cursor/` | Cursor | Developer-tool dark UI |

Full catalog (74 brands incl. airbnb, apple, figma, notion, coinbase…):
`~/reviews/awesome-design-md/design-md/` or upstream.

## Notes

- These are analysis files (version: alpha) — good starting points; tune the
  tokens to the actual brand before client delivery.
- `DESIGN.md` complements `AGENTS.md` (how to build) with how it should look.
