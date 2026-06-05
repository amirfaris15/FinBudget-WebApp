# Frontend Codex Context (SpendingApp)

## Purpose
Build the React PWA UI for the personal finance app with a focus on **transaction ingestion visibility**, **budgeting**, and **dashboard insights**.

## Stack
- React (PWA)
- Vite (unless specified otherwise)
- TypeScript
- Tailwind library

## UX Priorities
- Fast, clear **transaction log** (auto + manual)
- Easy **category editing**
- Simple **budget status** (progress + alerts)
- Dashboard with **spend so far**, **remaining budget**, **top categories**

## UI Sections (MVP)
- Dashboard
- Transactions
- Budgets
- Insights
- Settings (for iOS Shortcut token + preferences)

## Data Contracts (from backend)
Read from `docs/api-contract.md` and `handoffs/be-summary.md`. Do not assume fields not defined there.

## Frontend Responsibilities
- Build views and components based on API contract
- Add client-side validation for manual transaction entry
- Provide inline editing for categories
- Display alerts when budget thresholds are reached

## Handoff Output
Write to `handoffs/fe-summary.md`:
- Pages/components created
- Assumptions and pending API gaps
- Any UI decisions needing backend support

## Constraints
- No hidden stateful logic without user visibility
- Keep pages mobile-first
- Keep components modular and reusable

## Next Steps for the Agent
1. Read `docs/requirements.md`
2. Read `docs/api-contract.md`
3. Read `handoffs/be-summary.md`
4. Implement UI based on those sources
5. Write `handoffs/fe-summary.md`