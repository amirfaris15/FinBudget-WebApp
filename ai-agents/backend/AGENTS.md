# Backend Codex Context (SpendingApp)

## Purpose
Build the FastAPI backend that powers **transaction ingestion**, **categorisation**, and **budgeting**.

## Stack
- Python + FastAPI
- Supabase Postgres
- SQLAlchemy or SQLModel targeting PostgreSQL types
- OpenAI API for transaction parsing

## Core Responsibilities
- Ingestion endpoint for iOS Shortcuts (raw notification text)
- LLM parsing -> merchant, amount, category
- Persist transactions and budgets
- Serve API contract used by frontend
- Push notifications for budget alerts (if applicable)

## API Contract
Follow `docs/api-contract.md` exactly. Do not add fields/endpoints without updating it.

## Data Model (MVP)
- Transaction (raw_notification_text, merchant, amount_minor, currency, category, categorization_status, transaction_date, source_provider)
- Budget (budget_month, category, limit_minor, currency, rollover_enabled, payday_day)
- Budget alert (category, alert_type, threshold_percent, spent_minor, limit_minor, message)

## Handoff Output
Write to `handoffs/be-summary.md`:
- Endpoints implemented
- DB schema decisions, migrations, and Supabase environment variables
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

