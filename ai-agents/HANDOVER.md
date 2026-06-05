# Project Handover: FinBudget

## What This Is

FinBudget is a personal finance PWA for Damian, a full-stack developer based in Kuala Lumpur. The goal is a one-for-all personal finance OS with automatic transaction ingestion from Malaysian banking app notifications.

## Core Concept

Transaction ingestion pipeline:

1. iOS Shortcut triggers on a banking app notification, such as Maybank or Touch 'n Go.
2. Shortcut posts raw notification text to the FastAPI backend.
3. Backend uses OpenAI API to parse merchant, amount, currency, category, confidence, date, and flow.
4. Backend stores the transaction in Supabase Postgres.
5. Frontend reflects the transaction in dashboard, transaction log, and budget summaries.

Automatic categorisation is the core differentiator.

## Decided Stack

| Layer | Choice |
|-------|--------|
| Frontend | React PWA, hosted on Vercel |
| Backend | Python / FastAPI |
| Database | Supabase Postgres |
| LLM | OpenAI API for transaction parsing and categorisation |
| Hosting | Vercel for frontend, Railway or Render for backend |
| Notifications | Web Push API |
| iOS ingestion | iOS Shortcuts POST to backend |

## Core Feature List

- Transaction log with auto-ingested and manual transactions
- LLM-based categorisation with user edits
- Low-confidence parsing via `categorization_status = "needs_review"`
- Monthly budget limits per category
- Budget alerts at approaching and exceeded thresholds
- Dashboard with spend so far, remaining budget, and top categories

## Agentic Workflow

The `ai-agents` folder is a multi-agent planning and handoff package.

Agents:

- Backend agent builds API and writes `handoffs/be-summary.md`
- Frontend agent reads backend handoff, builds UI, and writes `handoffs/fe-summary.md`
- QA agent reads both handoffs, runs tests, and writes `handoffs/qa-report.md`

Subagents do not share chat history. Communication happens through docs and handoff files.

## Agent Files

```text
ai-agents/
  AGENTS.md
  docs/
    requirements.md
    api-contract.md
    handoff-protocol.md
  backend/
    AGENTS.md
    schema.sql
    .env.example
    migrations/
      001_initial_schema.sql
  frontend/
    AGENTS.md
  qa/
    AGENTS.md
  handoffs/
    be-summary.md
    fe-summary.md
    qa-report.md
```

## Current Build Order

1. Backend agent reads `docs/requirements.md`, `docs/api-contract.md`, `backend/schema.sql`, and `backend/AGENTS.md`.
2. Backend agent implements FastAPI, Supabase Postgres models/migrations, auth, ingestion, transactions, budgets, dashboard summary, and handoff.
3. Frontend agent reads `docs/api-contract.md`, `handoffs/be-summary.md`, and `frontend/AGENTS.md`.
4. Frontend agent implements React PWA views and handoff.
5. QA agent reads requirements, API contract, both handoffs, and `qa/AGENTS.md`.
6. QA agent runs or defines tests and reports blockers.

## Important Decisions

- PWA over native app.
- iOS Shortcuts for notification ingestion.
- Shortcut ingestion uses `X-Ingestion-Token`, not a user JWT.
- Frontend-authenticated routes use JWT bearer auth.
- Supabase is used as hosted Postgres; business logic remains in FastAPI.
- Money is stored and returned as integer minor units.
- The category enum does not include `uncategorized`; low-confidence items use `categorization_status`.

## Context About Damian

- Full-stack developer at EY Malaysia.
- Comfortable with React, Python, FastAPI, and API design.
- Starting MSc AI in the UK in September 2026.
- Malaysian banking apps in use: Maybank and Touch 'n Go.
- Will eventually need MYR and GBP support.
- Prefers clean, direct communication.

