# Codex Project Context (SpendingApp)

## Purpose
Build a personal finance PWA for Damian (KL-based full‑stack dev) with **automatic transaction ingestion** from Malaysian banking app notifications via iOS Shortcuts.

## Core Concept
**Transaction ingestion pipeline:**
1. iOS Shortcut triggers on banking app notification (e.g., Maybank, Touch ’n Go)
2. Shortcut POSTs raw notification text to a FastAPI backend
3. Backend uses an LLM to parse merchant, amount, category
4. Data saved to DB and reflected in the app UI

This auto‑categorisation is the core differentiator.

## Stack Decisions
- Frontend: React (PWA, hosted on Vercel)
- Backend: Python / FastAPI
- Database: SQLite (dev) → Postgres (prod)
- LLM: Claude API (transaction parsing, categorisation)
- Hosting: Vercel (FE), Railway or Render (BE)
- Notifications: Web Push API
- iOS ingestion: iOS Shortcuts → POST to backend

## Feature Scope (Core)
- Transaction log (auto‑ingested + manual fallback)
- LLM auto‑categorisation (editable)
- Monthly budget limits per category
- Alerts when approaching budget limit
- Dashboard: spend so far, remaining budget, top categories

## Agentic Workflow (Learning Goal)
Multi‑agent pipeline with **handoff files** as the communication layer.

**Agents:**
- Backend agent → builds API + writes handoffs/be-summary.md
- Frontend agent → reads be-summary, builds UI + writes handoffs/fe-summary.md
- QA agent → reads both, runs tests, writes handoffs/qa-report.md; routes fixes back to BE/FE

**Handoff files:**
- handoffs/be-summary.md
- handoffs/fe-summary.md
- handoffs/qa-report.md

## Folder Expectations
- docs/requirements.md
- docs/api-contract.md
- codex.md (global)
- frontend/codex.md
- backend/codex.md
- qa/codex.md

## Key Constraints
- Subagents do **not** share chat history.
- Each agent needs its **own** codex.md.
- Communication happens only via handoff files. Be concise and summarized in detail for the next agent to understand clearly.

## Handoff Protocol
See **docs/handoff-protocol.md** for complete specification and templates.

**Quick Reference:**
- `handoffs/be-summary.md` → API endpoints, DB schema, assumptions, files created
- `handoffs/fe-summary.md` → components built, integration points, state patterns, dependencies
- `handoffs/qa-report.md` → test results (summary | coverage | failures), sign-off status

Each handoff must follow the mandatory section structure defined in docs/handoff-protocol.md.

## Next Immediate Steps
1. Write docs/requirements.md (feature requirements, user stories, acceptance criteria)
2. Write codex.md (global) + per-agent codex.md
3. Define API contract before coding
4. Scaffold monorepo structure
5. Review docs/handoff-protocol.md to align on agent communication contract
