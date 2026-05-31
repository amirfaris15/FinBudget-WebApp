# Backend Codex Context (SpendingApp)

## Purpose
Build the FastAPI backend that powers **transaction ingestion**, **categorisation**, and **budgeting**.

## Stack
- Python + FastAPI
- SQLite (dev) → Postgres (prod)
- SQLAlchemy or SQLModel (decide in requirements)
- Claude API for transaction parsing

## Core Responsibilities
- Ingestion endpoint for iOS Shortcuts (raw notification text)
- LLM parsing → merchant, amount, category
- Persist transactions and budgets
- Serve API contract used by frontend
- Push notifications for budget alerts (if applicable)

## API Contract
Follow `docs/api-contract.md` exactly. Do not add fields/endpoints without updating it.

## Data Model (MVP)
- Transaction (raw_text, merchant, amount, category, timestamp, source)
- Category (name, budget_limit, rollover?)
- Budget (month, category, limit, spent)

## Handoff Output
Write to `handoffs/be-summary.md`:
- Endpoints implemented
- DB schema decisions
- Assumptions and open questions for FE/QA

## Constraints
- Validate all input from iOS Shortcuts
- Keep idempotency in ingestion (avoid duplicate transactions)
- Minimal auth (token in header) unless spec says otherwise

## Next Steps for the Agent
1. Read `docs/requirements.md`
2. Define `docs/api-contract.md`
3. Implement FastAPI endpoints + DB models
4. Write `handoffs/be-summary.md`