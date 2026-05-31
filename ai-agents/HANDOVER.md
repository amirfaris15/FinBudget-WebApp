# Project Handover: Personal Finance App (SpendingApp)
gh
## What this is

A personal finance PWA + native iOS app for Damian, a full stack developer (React, Python, FastAPI) based in KL. The goal is a **one-for-all personal finance OS** with automatic transaction ingestion from Malaysian banking app notifications.

-----

## Core Concept

**Transaction ingestion pipeline:**

1. iOS Shortcut triggers on banking app notification (e.g. Maybank, Touch ’n Go)
1. Shortcut POSTs raw notification text to a FastAPI backend
1. Backend uses an LLM to parse merchant, amount, category
1. Data saved to DB and reflected in the app UI

This is the killer feature — automatic categorisation without manual entry.

-----

## Decided Stack

|Layer        |Choice                                          |
|-------------|------------------------------------------------|
|Frontend     |React (PWA, hosted on Vercel)                   |
|Backend      |Python / FastAPI                                |
|Database     |SQLite (dev) → Postgres (prod)                  |
|LLM          |Claude API (transaction parsing, categorisation)|
|Hosting      |Vercel (FE), Railway or Render (BE)             |
|Notifications|Web Push API                                    |
|iOS ingestion|iOS Shortcuts → POST to backend                 |

-----

## Feature List

### Core

- Transaction log (auto-ingested via Shortcut + manual fallback)
- LLM-based auto-categorisation (editable)
- Monthly budget limits per category
- Alerts when approaching budget limit
- Dashboard — spend so far, remaining budget, top categories

### Budgeting

- Set monthly budgets per category (food, transport, entertainment etc)
- Rollover vs reset logic
- “Safe to spend” number (after bills and savings targets)
- Pay cycle awareness (reset on payday, not 1st of month)

### Insights

- Spending trends month over month
- Merchant breakdown
- Unusual spend detection
- Subscription/recurring charge auto-detection

### Goals

- Savings goals with progress bars
- Auto-allocate % of income toward goals

### Net Worth

- Manual input: assets (savings, ASB, EPF Akaun Fleksibel, investments)
- Liabilities (car loan etc)
- Net worth number updated monthly

### Nice to Haves

- Multi-currency support (useful when Damian moves to UK for MSc)
- CSV export
- Weekly spending digest notification

-----

## Build Approach: Multi-Agent Pipeline (Learning Goal)

Damian wants to use this project to **learn agentic AI coding**, not just ship the app. He’s coming from GitHub Copilot with manual prompting and wants to level up to a proper multi-agent Claude Code setup.

### Agent Structure

```
/CLAUDE.md                  ← global: stack, conventions, project overview
/frontend/CLAUDE.md         ← React structure, component patterns, Tailwind rules
/backend/CLAUDE.md          ← API design, DB schema, auth patterns
/qa/CLAUDE.md               ← testing conventions, tools, coverage expectations
```

### Pipeline Flow

```
You (one prompt)
      │
      ▼
Orchestrator agent
      │
      ├──► Backend agent   → writes code + /handoffs/be-summary.md
      ├──► Frontend agent  → reads be-summary, writes code + /handoffs/fe-summary.md
      └──► QA agent        → reads both, runs tests, writes /handoffs/qa-report.md
                                        │
                           If failures → routes back to BE or FE agent to fix
                                        │
                           QA re-runs until clean
```

### Handoff Files Convention

Each agent writes a summary after completing its task:

- `/handoffs/be-summary.md` — what was built, API contracts, assumptions
- `/handoffs/fe-summary.md` — what was built, component structure, assumptions
- `/handoffs/qa-report.md` — test results, failures, what needs fixing

-----

## What Needs to Be Done Next

### Immediate next steps:

1. **Write `/docs/requirements.md`** — full feature requirements, user stories, acceptance criteria
1. **Write `/CLAUDE.md`** — global project context for all agents
1. **Write per-agent CLAUDE.md files** — frontend, backend, QA
1. **Define API contract** — list of endpoints, request/response shapes, before any agent starts coding
1. **Set up folder structure** — scaffold the monorepo before firing up agents

### Suggested folder structure:

```
/
├── CLAUDE.md
├── docs/
│   ├── requirements.md
│   └── api-contract.md
├── handoffs/
│   ├── be-summary.md
│   ├── fe-summary.md
│   └── qa-report.md
├── frontend/
│   ├── CLAUDE.md
│   └── (React app)
├── backend/
│   ├── CLAUDE.md
│   └── (FastAPI app)
└── qa/
    ├── CLAUDE.md
    └── (tests)
```

-----

## Context About Damian

- Full stack dev at EY Malaysia (React, Python, Azure)
- Comfortable with React, FastAPI, API design
- Starting MSc AI at a UK university in September 2026
- Malaysian banking apps in use: Maybank, Touch ’n Go
- Will eventually need multi-currency (MYR + GBP)
- Prefers clean, direct communication — no fluff

-----

## Key Decisions Already Made

- ✅ PWA over native app (no $99 Apple Developer account)
- ✅ iOS Shortcuts for notification ingestion (not Wallet API — Apple restricts that)
- ✅ Claude API for LLM parsing
- ✅ Multi-agent pipeline for learning purposes, not because the project requires it
- ✅ Subagents do NOT share chat history — handoff files are the communication layer
- ✅ Each agent needs its own CLAUDE.md even in a multi-agent setup