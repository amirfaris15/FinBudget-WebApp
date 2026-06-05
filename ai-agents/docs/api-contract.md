# API Contract: FinBudget

This file is the shared source of truth for backend, frontend, and QA agents. Backend implementation must match this contract. Frontend must not assume fields that are not defined here. QA should test against this contract.

Status: MVP contract. Post-MVP sections are placeholders until implementation is requested.

## Base URL

Local development:

```text
http://localhost:8000
```

All endpoints are prefixed with:

```text
/api
```

## Authentication

Protected endpoints require:

```http
Authorization: Bearer <access_token>
```

Unauthenticated endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/transactions/ingest`

`POST /api/transactions/ingest` is unauthenticated for MVP only if protected by an ingestion token header. The backend must reject requests without this header.

```http
X-Ingestion-Token: <secret_token>
```

Frontend-authenticated routes use JWT bearer auth. iOS Shortcuts ingestion uses `X-Ingestion-Token` because Shortcuts should not store a user JWT.

## Shared Types

### Currency

```ts
type Currency = "MYR" | "GBP";
```

### Category

```ts
type Category =
  | "food"
  | "transport"
  | "entertainment"
  | "utilities"
  | "salary"
  | "transfer"
  | "shopping"
  | "other";
```

Do not use `"uncategorized"` as a stored category. Low-confidence parsing is represented by `categorization_status`.

### CategorizationStatus

```ts
type CategorizationStatus = "auto" | "needs_review" | "manual";
```

Rules:

- LLM confidence `>= 80`: `categorization_status = "auto"`
- LLM confidence `< 80`: `categorization_status = "needs_review"`
- User edits category: `categorization_status = "manual"`

Frontend may display `needs_review` transactions as "Uncategorized", but must still send a valid `Category` when updating.

### Flow

```ts
type Flow = "in" | "out";
```

### Sort

```ts
type TransactionSort = "date_desc" | "date_asc" | "amount_desc" | "amount_asc";
```

## Money and Date Rules

- Money is always represented as integer minor units.
- RM10.50 is `1050`.
- GBP10.50 is `1050`.
- API month values use `YYYY-MM`.
- Transaction dates use `YYYY-MM-DD`.
- Timestamps use ISO 8601 UTC strings, for example `2026-06-05T10:00:00Z`.
- Database may store month fields as first day of month internally, but API payloads use `YYYY-MM`.

## Error Response

All non-2xx errors return:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Amount must be greater than zero",
    "details": {}
  }
}
```

Common error codes:

| HTTP | Code | Meaning |
|------|------|---------|
| 400 | `VALIDATION_ERROR` | Request body or query params are invalid |
| 401 | `UNAUTHORIZED` | Missing or invalid auth credentials |
| 403 | `FORBIDDEN` | Authenticated but not allowed |
| 404 | `NOT_FOUND` | Resource does not exist or does not belong to user |
| 409 | `DUPLICATE_RESOURCE` | Duplicate transaction or unique constraint conflict |
| 429 | `RATE_LIMITED` | LLM or API rate limit |
| 500 | `INTERNAL_ERROR` | Unexpected server error |

## Auth Endpoints

### POST /api/auth/register

Request:

```json
{
  "email": "damian@example.com",
  "password": "secure-password",
  "display_name": "Damian"
}
```

Response `201`:

```json
{
  "user": {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "damian@example.com",
    "display_name": "Damian",
    "home_currency": "MYR",
    "created_at": "2026-06-05T10:00:00Z"
  },
  "access_token": "jwt_access_token",
  "refresh_token": "opaque_refresh_token"
}
```

### POST /api/auth/login

Request:

```json
{
  "email": "damian@example.com",
  "password": "secure-password"
}
```

Response `200`:

```json
{
  "user": {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "damian@example.com",
    "display_name": "Damian",
    "home_currency": "MYR",
    "created_at": "2026-06-05T10:00:00Z"
  },
  "access_token": "jwt_access_token",
  "refresh_token": "opaque_refresh_token"
}
```

### POST /api/auth/refresh

Request:

```json
{
  "refresh_token": "opaque_refresh_token"
}
```

Response `200`:

```json
{
  "access_token": "new_jwt_access_token",
  "refresh_token": "new_opaque_refresh_token"
}
```

## Transaction Endpoints

### POST /api/transactions/ingest

Purpose: iOS Shortcuts posts raw banking notification text. Backend parses with LLM, deduplicates, saves, and returns the transaction.

Auth: `X-Ingestion-Token` header required.

Request:

```json
{
  "raw_notification_text": "Payment received: RM500 from SALARY_EMPLOYER",
  "source_provider": "shortcut"
}
```

Response `201`:

```json
{
  "transaction": {
    "id": "00000000-0000-0000-0000-000000000000",
    "transaction_date": "2026-06-05",
    "merchant": "SALARY_EMPLOYER",
    "amount_minor": 50000,
    "currency": "MYR",
    "category": "salary",
    "categorization_status": "auto",
    "confidence": 94.5,
    "flow": "in",
    "raw_notification_text": "Payment received: RM500 from SALARY_EMPLOYER",
    "source_provider": "shortcut",
    "is_unusual": false,
    "is_recurring": false,
    "recurring_label": null,
    "expected_flag": false,
    "created_at": "2026-06-05T10:00:00Z",
    "updated_at": "2026-06-05T10:00:00Z"
  },
  "duplicate": false,
  "budget_alerts": []
}
```

Duplicate response `200`:

```json
{
  "transaction": {
    "id": "00000000-0000-0000-0000-000000000000",
    "transaction_date": "2026-06-05",
    "merchant": "SALARY_EMPLOYER",
    "amount_minor": 50000,
    "currency": "MYR",
    "category": "salary",
    "categorization_status": "auto",
    "confidence": 94.5,
    "flow": "in",
    "created_at": "2026-06-05T10:00:00Z",
    "updated_at": "2026-06-05T10:00:00Z"
  },
  "duplicate": true,
  "budget_alerts": []
}
```

Notes:

- Backend computes and stores `raw_notification_hash`.
- Backend must not create another row for the same `(user_id, raw_notification_hash)`.
- If LLM confidence is below 80, backend still stores a valid `category` and sets `categorization_status = "needs_review"`.
- If parsing fails due to LLM rate limits, return `429 RATE_LIMITED`.

### POST /api/transactions

Purpose: manual transaction fallback.

Auth: bearer JWT required.

Request:

```json
{
  "transaction_date": "2026-06-05",
  "merchant": "Grab",
  "amount_minor": 1250,
  "currency": "MYR",
  "category": "transport",
  "flow": "out"
}
```

Response `201`:

```json
{
  "transaction": {
    "id": "00000000-0000-0000-0000-000000000000",
    "transaction_date": "2026-06-05",
    "merchant": "Grab",
    "amount_minor": 1250,
    "currency": "MYR",
    "category": "transport",
    "categorization_status": "manual",
    "confidence": 100,
    "flow": "out",
    "source_provider": "manual",
    "is_unusual": false,
    "is_recurring": false,
    "recurring_label": null,
    "expected_flag": false,
    "created_at": "2026-06-05T10:00:00Z",
    "updated_at": "2026-06-05T10:00:00Z"
  },
  "budget_alerts": []
}
```

### GET /api/transactions

Auth: bearer JWT required.

Query params:

| Name | Required | Format | Default | Notes |
|------|----------|--------|---------|-------|
| `month` | No | `YYYY-MM` | current month | Month filter |
| `category` | No | `Category` | none | Category filter |
| `page` | No | integer >= 1 | `1` | Page number |
| `page_size` | No | integer 1-100 | `50` | Default requirement is 50 |
| `sort` | No | `TransactionSort` | `date_desc` | Sort order |

Response `200`:

```json
{
  "items": [
    {
      "id": "00000000-0000-0000-0000-000000000000",
      "transaction_date": "2026-06-05",
      "merchant": "Grab",
      "amount_minor": 1250,
      "currency": "MYR",
      "category": "transport",
      "categorization_status": "auto",
      "confidence": 91.2,
      "flow": "out",
      "source_provider": "shortcut",
      "is_unusual": false,
      "is_recurring": false,
      "recurring_label": null,
      "expected_flag": false,
      "created_at": "2026-06-05T10:00:00Z",
      "updated_at": "2026-06-05T10:00:00Z"
    }
  ],
  "page": 1,
  "page_size": 50,
  "total": 1
}
```

### PUT /api/transactions/{id}

Purpose: edit transaction category after ingestion.

Auth: bearer JWT required.

Request:

```json
{
  "category": "food"
}
```

Response `200`:

```json
{
  "transaction": {
    "id": "00000000-0000-0000-0000-000000000000",
    "category": "food",
    "categorization_status": "manual",
    "updated_at": "2026-06-05T10:05:00Z"
  }
}
```

### DELETE /api/transactions/{id}

Auth: bearer JWT required.

Response `204`: no body.

## Budget Endpoints

### POST /api/budgets

Auth: bearer JWT required.

Request:

```json
{
  "category": "food",
  "budget_month": "2026-06",
  "limit_minor": 100000,
  "currency": "MYR",
  "rollover_enabled": false,
  "payday_day": 1
}
```

Response `201`:

```json
{
  "budget": {
    "id": "00000000-0000-0000-0000-000000000000",
    "category": "food",
    "budget_month": "2026-06",
    "limit_minor": 100000,
    "currency": "MYR",
    "rollover_enabled": false,
    "payday_day": 1,
    "created_at": "2026-06-05T10:00:00Z",
    "updated_at": "2026-06-05T10:00:00Z"
  }
}
```

### GET /api/budgets

Auth: bearer JWT required.

Query params:

| Name | Required | Format | Default | Notes |
|------|----------|--------|---------|-------|
| `month` | No | `YYYY-MM` | current month | Budget month |

Response `200`:

```json
{
  "items": [
    {
      "id": "00000000-0000-0000-0000-000000000000",
      "category": "food",
      "budget_month": "2026-06",
      "limit_minor": 100000,
      "currency": "MYR",
      "spent_minor": 42000,
      "remaining_minor": 58000,
      "percent_used": 42,
      "status": "ok",
      "rollover_enabled": false,
      "payday_day": 1,
      "created_at": "2026-06-05T10:00:00Z",
      "updated_at": "2026-06-05T10:00:00Z"
    }
  ]
}
```

Budget status values:

```ts
type BudgetStatus = "ok" | "approaching" | "exceeded";
```

Status rules:

- `ok`: `< 80%`
- `approaching`: `>= 80%` and `< 100%`
- `exceeded`: `>= 100%`

### PUT /api/budgets/{id}

Auth: bearer JWT required.

Request:

```json
{
  "limit_minor": 120000,
  "rollover_enabled": true,
  "payday_day": 25
}
```

Response `200`:

```json
{
  "budget": {
    "id": "00000000-0000-0000-0000-000000000000",
    "category": "food",
    "budget_month": "2026-06",
    "limit_minor": 120000,
    "currency": "MYR",
    "rollover_enabled": true,
    "payday_day": 25,
    "updated_at": "2026-06-05T10:05:00Z"
  }
}
```

### DELETE /api/budgets/{id}

Auth: bearer JWT required.

Response `204`: no body.

## Dashboard Endpoints

### GET /api/dashboard/summary

Auth: bearer JWT required.

Query params:

| Name | Required | Format | Default | Notes |
|------|----------|--------|---------|-------|
| `month` | No | `YYYY-MM` | current month | Dashboard month |

Response `200`:

```json
{
  "month": "2026-06",
  "currency": "MYR",
  "total_income_minor": 500000,
  "total_spent_minor": 210000,
  "safe_to_spend_minor": 90000,
  "top_categories": [
    {
      "category": "food",
      "spent_minor": 82000,
      "percent_of_spend": 39
    }
  ],
  "budgets": [
    {
      "id": "00000000-0000-0000-0000-000000000000",
      "category": "food",
      "limit_minor": 100000,
      "spent_minor": 82000,
      "remaining_minor": 18000,
      "percent_used": 82,
      "status": "approaching"
    }
  ],
  "alerts": [
    {
      "id": "00000000-0000-0000-0000-000000000000",
      "category": "food",
      "alert_type": "approaching",
      "message": "Food budget at 82% (RM820 of RM1000 spent)",
      "triggered_at": "2026-06-05T10:00:00Z",
      "dismissed_at": null
    }
  ]
}
```

Notes:

- `total_spent_minor` includes only transactions with `flow = "out"`.
- `total_income_minor` includes only transactions with `flow = "in"`.
- `top_categories` excludes income categories unless the backend explicitly documents otherwise in `handoffs/be-summary.md`.
- `safe_to_spend_minor` is MVP best effort: total remaining monthly budget after recorded spending. Bills and savings-target deductions may be added later.

## Budget Alert Endpoints

Budget alerts are created automatically during transaction ingestion or manual transaction creation.

### GET /api/budget-alerts

Auth: bearer JWT required.

Query params:

| Name | Required | Format | Default |
|------|----------|--------|---------|
| `month` | No | `YYYY-MM` | current month |

Response `200`:

```json
{
  "items": [
    {
      "id": "00000000-0000-0000-0000-000000000000",
      "category": "food",
      "alert_type": "approaching",
      "threshold_percent": 80,
      "spent_minor": 82000,
      "limit_minor": 100000,
      "currency": "MYR",
      "message": "Food budget at 82% (RM820 of RM1000 spent)",
      "triggered_at": "2026-06-05T10:00:00Z",
      "dismissed_at": null
    }
  ]
}
```

### PUT /api/budget-alerts/{id}/dismiss

Auth: bearer JWT required.

Request: empty JSON object.

```json
{}
```

Response `200`:

```json
{
  "alert": {
    "id": "00000000-0000-0000-0000-000000000000",
    "dismissed_at": "2026-06-05T10:05:00Z"
  }
}
```

## Settings Endpoints

### GET /api/settings/me

Auth: bearer JWT required.

Response `200`:

```json
{
  "user": {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "damian@example.com",
    "display_name": "Damian",
    "home_currency": "MYR",
    "created_at": "2026-06-05T10:00:00Z",
    "updated_at": "2026-06-05T10:00:00Z"
  }
}
```

### PUT /api/settings/me

Auth: bearer JWT required.

Request:

```json
{
  "display_name": "Damian",
  "home_currency": "MYR"
}
```

Response `200`:

```json
{
  "user": {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "damian@example.com",
    "display_name": "Damian",
    "home_currency": "MYR",
    "updated_at": "2026-06-05T10:05:00Z"
  }
}
```

## Post-MVP Contracts

These features are documented in requirements and have schema support, but their API contracts are intentionally deferred until implementation starts.

### Insights and Analytics

Status: Post-MVP. Contract TBD.

Likely endpoints:

- `GET /api/insights/spending-trends`
- `GET /api/insights/merchant-breakdown`
- `GET /api/insights/recurring`
- `PUT /api/transactions/{id}/expected`

### Savings Goals

Status: Post-MVP. Contract TBD.

Likely endpoints:

- `POST /api/savings-goals`
- `GET /api/savings-goals`
- `PUT /api/savings-goals/{id}`
- `DELETE /api/savings-goals/{id}`
- `POST /api/savings-goals/{id}/contributions`

### Net Worth

Status: Post-MVP. Contract TBD.

Likely endpoints:

- `POST /api/net-worth/snapshots`
- `GET /api/net-worth/snapshots`
- `GET /api/net-worth/snapshots/{id}`
- `PUT /api/net-worth/snapshots/{id}`
- `DELETE /api/net-worth/snapshots/{id}`

### CSV Export

Status: Post-MVP. Contract TBD.

Likely endpoints:

- `GET /api/export/transactions.csv`
- `GET /api/export/budgets.csv`
- `GET /api/export/net-worth.csv`

### Web Push

Status: Post-MVP. Contract TBD.

Likely endpoints:

- `POST /api/push/subscriptions`
- `DELETE /api/push/subscriptions/{id}`

## Contract Change Rules

- Any endpoint field change must be updated here before backend or frontend code changes.
- Backend agent must document implemented differences in `handoffs/be-summary.md`.
- Frontend agent must flag any missing contract field in `handoffs/fe-summary.md`.
- QA agent should treat undocumented request or response fields as contract drift.
