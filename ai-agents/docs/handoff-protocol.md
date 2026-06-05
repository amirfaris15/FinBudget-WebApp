# Handoff Protocol for Multi-Agent Pipeline

## Purpose

This file defines how backend, frontend, and QA agents communicate through markdown handoff files. Handoffs must be concrete enough that the next agent does not need chat history.

## Pipeline

1. Backend agent writes `handoffs/be-summary.md`.
2. Frontend agent reads `be-summary.md` and writes `handoffs/fe-summary.md`.
3. QA agent reads both and writes `handoffs/qa-report.md`.
4. If QA finds blockers, route each blocker to Backend, Frontend, or both.

## Backend Handoff: be-summary.md

Backend handoff tells frontend exactly what was built and how to consume it.

Required sections:

### 1. API Endpoints

Use this table shape:

```markdown
| Method | Path | Request | Response | Notes |
|--------|------|---------|----------|-------|
| POST | /api/transactions/ingest | `{ raw_notification_text, source_provider }` | `{ transaction, duplicate, budget_alerts }` | Uses `X-Ingestion-Token`; parses via OpenAI |
| GET | /api/transactions | `?month=2026-06&category=food&page=1&page_size=50` | `{ items, page, page_size, total }` | Paginated |
| PUT | /api/transactions/{id} | `{ category }` | `{ transaction }` | Sets `categorization_status = "manual"` |
| POST | /api/budgets | `{ category, budget_month, limit_minor, currency }` | `{ budget }` | `budget_month` is `YYYY-MM` |
```

Do not invent shapes outside `docs/api-contract.md`. If implementation differs, update the contract first.

### 2. Database Schema

Summarize tables, keys, relationships, and indexes.

Use current naming:

- `amount_minor`, not `amount`
- `limit_minor`, not `limit_myr`
- `budget_month`, not `month`
- `categorization_status`, not `uncategorized` category
- `UUID` IDs
- `TIMESTAMPTZ` timestamps

Example:

```markdown
**transactions**
- id (UUID, PK)
- user_id (UUID, FK -> users.id)
- transaction_date (date)
- merchant (text)
- amount_minor (integer)
- currency (MYR|GBP)
- category (food|transport|entertainment|utilities|salary|transfer|shopping|other)
- categorization_status (auto|needs_review|manual)
- raw_notification_text (text)
- raw_notification_hash (text)
- created_at / updated_at (timestamptz)
```

### 3. Authentication and Authorization

Document:

- JWT auth for frontend routes
- Refresh token behavior
- `X-Ingestion-Token` behavior for iOS Shortcuts
- Which routes are unauthenticated, if any

### 4. Environment Variables

List every env var used. Do not include real secrets.

Expected baseline:

- `DATABASE_URL`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`
- `INGESTION_TOKEN`
- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- `BACKEND_CORS_ORIGINS`

### 5. Implementation Notes

Document edge cases:

- Low confidence means `categorization_status = "needs_review"`.
- Frontend may display needs-review transactions as "Uncategorized".
- Duplicate detection uses `(user_id, raw_notification_hash)`.
- OpenAI rate limits return `429 RATE_LIMITED`.
- Ingestion may take 2-5 seconds.

### 6. Files Created or Modified

List backend files with a short purpose for each.

### 7. Known Issues or Blockers

State what is incomplete and who should handle it next.

## Frontend Handoff: fe-summary.md

Frontend handoff tells QA what UI was built and which backend contract it uses.

Required sections:

### 1. Components Built

List pages, shared components, hooks, stores, and routes.

### 2. API Integration Points

Map components to endpoints.

Example:

```markdown
Dashboard:
- GET /api/dashboard/summary?month=YYYY-MM

Transactions:
- GET /api/transactions
- PUT /api/transactions/{id}
- DELETE /api/transactions/{id}

Budgets:
- GET /api/budgets
- POST /api/budgets
- PUT /api/budgets/{id}
- DELETE /api/budgets/{id}
```

### 3. State Management

Document state tools, cache invalidation, auth storage, and loading/error handling.

### 4. Dependencies Added

List packages added and why.

### 5. Assumptions

Flag assumptions about backend responses, auth, date formats, and display rules.

### 6. Known Issues or TODOs

Be clear about what QA should not treat as a regression yet.

### 7. Files Created or Modified

List frontend files with a short purpose for each.

## QA Handoff: qa-report.md

QA handoff reports test status, failures, and sign-off.

Required sections:

### 1. Test Summary

```markdown
- Total:
- Passed:
- Failed:
- Skipped:
- Coverage:
```

### 2. Coverage by Module

Use a table covering backend API, backend services, frontend components, frontend hooks, and E2E where applicable.

### 3. Failures

For each failure include:

- Test name and file
- Expected behavior
- Actual behavior
- Root cause if known
- Fix owner: Backend, Frontend, or both

### 4. Test Commands

List exact commands used.

### 5. Sign-Off Status

Use one of:

- `READY FOR STAGING`
- `NOT READY - BLOCKERS`
- `PARTIAL - TEST GAPS`

## Handoff Rules

- The API contract is authoritative.
- Handoffs describe implementation details, not new contracts.
- If a handoff contradicts `docs/api-contract.md`, fix the contract or implementation before proceeding.
- Empty handoff files are acceptable before agents run.
- Do not include secrets in handoffs.

