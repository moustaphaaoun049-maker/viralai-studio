# ViralAI Studio

A responsive, dark-violet website and product UI preview for ViralAI Studio.

## Current status

This repository contains a static front-end preview in `index.html`: a public landing page, features, pricing, responsive workspace shell, Simple/Pro mode selection, creation brief form and navigation previews.

**Not yet connected:** authentication, database, AI generation providers, billing, social-platform APIs, scheduled publishing, analytics data, or a secured owner/admin console. The creation form is a local preview only; it does not submit jobs or spend credits. This is not yet a production SaaS.

## Deploy to Cloudflare Pages

Static site; no build command is required.
1. Open Cloudflare **Workers & Pages** → **Create** → **Pages** → **Connect to Git**.
2. Select `moustaphaaoun049-maker/viralai-studio`, branch `main`.
3. Framework preset: **None**.
4. Leave **Build command** empty; set **Build output directory** to `/`.
5. Deploy. Add a custom domain from the Pages project later.

## Next engineering milestones

1. Add a tested React/TypeScript application and automated build checks.
2. Add Supabase authentication, migrations, storage and strict row-level security.
3. Implement server-side authorization and a private owner console.
4. Add AI providers behind server-side functions with usage metering, consent and hard spending limits.
5. Add payments only after merchant setup and explicit approval.
6. Add official social OAuth/API connections and compliant publishing.
7. Complete legal pages, security review, monitoring and production tests.

## Budget guardrail

No paid API usage, provider credits, hosting upgrades or purchases are initiated by this repository.
