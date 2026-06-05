# Requirements: FinBudget Personal Finance PWA

**Product:** Personal Finance PWA with automatic transaction ingestion from Malaysian banking app notifications  
**User:** Damian (full-stack developer, KL-based, moving to UK for MSc AI in Sept 2026)  
**Core Goal:** One-for-all personal finance OS with zero-friction transaction entry via iOS Shortcuts + OpenAI LLM parsing

---

## 1. System Overview

### 1.1 Architecture
- **Frontend:** React PWA (mobile-first) hosted on Vercel
- **Backend:** Python / FastAPI hosted on Railway or Render
- **Database:** Supabase Postgres
- **LLM:** OpenAI API (transaction parsing, categorization, anomaly detection)
- **Ingestion:** iOS Shortcuts → FastAPI POST endpoint
- **Notifications:** Web Push API (browser)

### 1.2 Key Principle
**Automatic transaction ingestion > Manual entry**  
The killer feature is parsing Malaysian banking notifications (Maybank, Touch 'n Go) into the app without user friction.

---

## 2. Core Features (MVP)

### 2.1 Transaction Ingestion & Categorization

**Feature:** Automatic transaction capture from banking app notifications

**User Story:**  
> As Damian, when I receive a Maybank notification like "Payment received: RM500 from SALARY_EMPLOYER", I want the iOS Shortcut to post this to the app backend, which parses it with OpenAI, extracts merchant/amount/category, and saves it—all automatically—so I never manually enter transactions.

**Requirements:**
- iOS Shortcut listener accepts raw notification text via POST to `/api/transactions/ingest`
- Backend sends text to OpenAI API with prompt: extract merchant, amount (MYR), category
- Backend returns structured JSON: `{ merchant, amount, category, confidence }`
- If confidence < 80%, set `categorization_status = "needs_review"` and show "Uncategorized" in UI
- Duplicate detection: store `raw_notification_text` hash, skip if exists
- Category enum (fixed, server-side): food, transport, entertainment, utilities, salary, transfer, shopping, other
- User can manually edit category after ingestion (optimistic UI update + backend PUT)

**Acceptance Criteria:**
- ✅ Shortcut sends notification text to `/api/transactions/ingest`
- ✅ OpenAI parses text and returns merchant, amount, category
- ✅ Transaction saved to database with created_at timestamp
- ✅ UI reflects new transaction within 2 seconds
- ✅ Duplicate notifications ignored
- ✅ User can edit category, changes persist
- ✅ Handles OpenAI API rate limits gracefully (show error toast)

**Notes:**
- OpenAI parsing may take 2-5 seconds; show loading indicator
- Shortcut should not be manually entered by user (iOS Automation app)
- Support both MYR and GBP amounts (future: multi-currency)

---

### 2.2 Transaction Log

**Feature:** Browsable, filterable list of all transactions

**User Story:**  
> As Damian, I want to see all my transactions in a searchable, filterable list by month and category, so I can review spending history and spot anomalies.

**Requirements:**
- Paginated list view (50 items per page)
- Filters: date range (month selector), category dropdown
- Sort: by date (desc by default), by amount
- Columns: date, merchant, amount, category, edit icon
- Inline edit category: click category chip → dropdown → save
- Delete transaction (with confirmation)

**Acceptance Criteria:**
- ✅ List loads transactions for selected month
- ✅ Filters update list without page reload
- ✅ Pagination works (prev/next buttons)
- ✅ Inline edit updates category
- ✅ Delete removes transaction permanently
- ✅ Handles empty state (no transactions this month)

---

### 2.3 Dashboard / Overview

**Feature:** At-a-glance spending summary

**User Story:**  
> As Damian, I want to see my spending summary on the dashboard—total spent this month, remaining budget by category, and top spending categories—so I know if I'm on track.

**Requirements:**
- Card layout showing:
  - **Total spent (MYR)** this month
  - **Budget summary** (if budgets exist)
    - By category: spent / limit (progress bar)
    - Color coding: green (< 50%), yellow (50-80%), red (> 80%)
  - **Top 5 categories** (pie chart or bar chart, by amount)
  - **Remaining budget** (after bills and savings)
- Empty state if no budgets set

**Acceptance Criteria:**
- ✅ Dashboard loads in < 2s
- ✅ Shows current month's data
- ✅ Budget cards update when user edits category
- ✅ Charts render without errors (handle no data)
- ✅ Responsive on mobile (single column, cards stack)

---

### 2.4 Budget Management

**Feature:** Set monthly budget limits per category

**User Story:**  
> As Damian, I want to set monthly budgets for each category (e.g., RM1000 for food, RM500 for transport), so I have guardrails and get alerts when I exceed them.

**Requirements:**
- Create/edit budget: category selector, amount input (MYR), month picker (default: current month)
- List view: table of budgets for selected month
- Edit: click budget row → modal → update amount → save
- Delete budget: confirmation dialog
- Budget roll-over logic:
  - **Reset:** budget resets to 0 spent on 1st of month (default)
  - **Rollover:** unspent amount carries to next month (optional toggle, TBD with Damian)
- Pay cycle awareness: allow user to set "payday" date (not hardcoded to 1st)
- Display "Safe to spend" number: remaining budget after bills and savings targets

**Acceptance Criteria:**
- ✅ User can create budget (category, amount, month)
- ✅ Budget saved and appears in list
- ✅ User can edit budget amount
- ✅ User can delete budget
- ✅ Dashboard shows spent vs. limit for each budget
- ✅ Spending > limit triggers alert (dashboard + optional toast)
- ✅ Pay cycle date configurable

---

### 2.5 Budget Alerts

**Feature:** Notifications when approaching or exceeding budget

**User Story:**  
> As Damian, I want to get alerts when I'm near my budget limit (80%) or exceed it, so I can adjust spending proactively.

**Requirements:**
- Alert threshold: 80% of budget
- Trigger on transaction ingest: if new transaction pushes category spend to ≥ 80% or ≥ 100%, show alert
- UI: toast notification (5s) on dashboard
- Optional: Web Push notification (if user grants permission)
- Alert types:
  - **Approaching limit:** "🟡 Food budget at 82% (RM820 of RM1000 spent)"
  - **Over limit:** "🔴 Food budget exceeded: RM1050 spent, limit RM1000 (+RM50)"

**Acceptance Criteria:**
- ✅ Toast appears when transaction pushes category to 80%
- ✅ Toast dismissible
- ✅ Alert text is clear and actionable
- ✅ No duplicate alerts for same category in same minute

**Priority:** Low (ship after MVP)

---

## 3. Secondary Features

### 3.1 Insights & Analytics

**Feature:** Spending trends and anomaly detection

**User Story:**  
> As Damian, I want to see spending trends month-over-month, identify unusual spending patterns, and detect recurring subscriptions, so I understand my financial habits and catch fraud/waste.

**Requirements:**
- **Spending trends:** line chart comparing same category across 3-6 months
- **Merchant breakdown:** top 10 merchants by total spend (month view)
- **Unusual spend detection:**
  - Transactions > 2x average for category → flag as "Unusual"
  - Show in transaction list with ⚠️ icon
  - User can mark as "Expected" to ignore
- **Recurring charges auto-detection:**
  - Algorithm: same merchant, amount (±5%), within 3-5 days of previous occurrence
  - Label transaction as "Recurring (Monthly)" or "Recurring (Bi-weekly)" etc.
  - Calculate estimated annual cost for recurring charges

**Acceptance Criteria:**
- ✅ Trends chart renders for selected month range
- ✅ Merchant breakdown shows top 10 with amounts
- ✅ Unusual transactions flagged (visual indicator)
- ✅ Recurring charge detection works for common subscriptions
- ✅ Estimated annual recurring cost displayed on dashboard

**Priority:** Low (ship after MVP)

---

### 3.2 Savings Goals

**Feature:** Track progress toward savings targets

**User Story:**  
> As Damian, I want to set savings goals (e.g., "RM10,000 for UK move by Dec 2026") and auto-allocate a % of income toward them, so I stay motivated and on track.

**Requirements:**
- Create goal: name, target amount (MYR), target date, optional monthly contribution
- Progress tracking: visual progress bar (current / target)
- Auto-allocation: user can set % of income to allocate to goal; system calculates how much to set aside
- Achieved badge: goal turned green when reached
- List of active + archived goals

**Acceptance Criteria:**
- ✅ User can create goal with amount and date
- ✅ Progress bar updates as goal progresses
- ✅ Auto-allocation calculates correctly
- ✅ User can delete or archive goal

**Priority:** Medium

---

### 3.3 Net Worth Tracking

**Feature:** Manual net worth entry and tracking

**User Story:**  
> As Damian, I want to track my net worth by entering assets (savings, investments, EPF) and liabilities (car loan, credit card), so I can see my financial health over time.

**Requirements:**
- Asset categories (Malaysian context):
  - Savings (checking/savings accounts)
  - ASB (Amanah Saham Bumiputera)
  - EPF Akaun Fleksibel
  - Investments (stocks, ETFs)
  - Other (cash, property — later)
- Liability categories:
  - Car loan
  - Credit card debt
  - Personal loan
  - Other
- Monthly entry: user manually inputs snapshot of assets/liabilities
- Net worth calculation: total assets - total liabilities
- Net worth trend: line chart showing monthly progression
- Entry history: list of past net worth entries with editable notes

**Acceptance Criteria:**
- ✅ User can add asset and liability entries
- ✅ Net worth calculated correctly
- ✅ Monthly trend chart renders
- ✅ User can edit past entries

**Priority:** Low (ship after MVP)

---

## 4. Nice-to-Have Features (Post-MVP)

### 4.1 Multi-Currency Support
- Support MYR and GBP (for Damian's move to UK)
- Exchange rate from open API (daily update)
- User can select home currency (affects all displays)
- Transactions can be tagged with currency

### 4.2 CSV Export
- Export transactions as CSV (month range, all categories or filtered)
- Export budgets summary
- Export net worth history

### 4.3 Weekly Digest Notification
- Email or Web Push: weekly summary (total spent, top categories, budget status)
- Sent on Sunday night
- Optional: include anomalies detected

### 4.4 Data Import
- Import transactions from CSV (manual fallback if Shortcut fails)
- Batch categorization (OpenAI parses all rows in one call)

### 4.5 Authentication & Multi-Device
- User login via email + password (or OAuth later)
- Data syncs across devices
- Mobile PWA + desktop browser support

---

## 5. Acceptance Criteria by Layer

### 5.1 Backend (FastAPI)

**Authentication:**
- ✅ User registration & login (JWT tokens)
- ✅ Token refresh (24h expiry)
- ✅ Authenticated endpoints protected

**Transaction Endpoints:**
- ✅ POST /api/transactions/ingest (raw text → OpenAI → save)
- ✅ GET /api/transactions (paginated, filters: month, category)
- ✅ PUT /api/transactions/:id (edit category)
- ✅ DELETE /api/transactions/:id

**Budget Endpoints:**
- ✅ POST /api/budgets (create)
- ✅ GET /api/budgets (list by month)
- ✅ PUT /api/budgets/:id (edit amount)
- ✅ DELETE /api/budgets/:id

**Database:**
- OK users table (id, email, password_hash, created_at)
- OK transactions table (id, user_id, merchant, amount_minor, currency, category, categorization_status, raw_notification_text, raw_notification_hash, created_at)
- OK budgets table (id, user_id, category, limit_minor, currency, budget_month, created_at)
- OK indexes on user_id, created_at for fast queries

**LLM Integration:**
- ✅ OpenAI API calls for transaction parsing
- ✅ Fallback if OpenAI rate-limited (return error to FE)
- ✅ Prompt engineering: clear instructions to extract merchant, amount, category

**Error Handling:**
- ✅ Return 400 for invalid input
- ✅ Return 401 for unauthorized
- ✅ Return 500 for server errors (log to Sentry or similar)

---

### 5.2 Frontend (React PWA)

**UI Components:**
- ✅ Dashboard (overview cards, budget progress, top categories chart)
- ✅ Transaction log (paginated list, filters, inline edit)
- ✅ Budget manager (create, edit, delete, list by month)
- ✅ Login/signup forms
- ✅ Responsive design (mobile-first, works on iPhone)

**State Management:**
- ✅ Redux store (transactions, budgets, auth, UI state)
- ✅ Caching (React Query or similar, 5-min stale time)
- ✅ Error boundaries for graceful failures

**API Integration:**
- ✅ All endpoints from BE-summary.md consumed
- ✅ JWT token attached to requests
- ✅ Error toasts for 4xx/5xx responses
- ✅ Loading states on async operations

**PWA Features:**
- ✅ Installable to home screen
- ✅ Works offline (cached data via service worker)
- ✅ Web Push notification support (if user grants permission)

---

### 5.3 QA & Testing

**Unit Tests:**
- ✅ Backend: transaction parsing logic, budget calculations, auth
- ✅ Frontend: component rendering, state updates, form validation

**Integration Tests:**
- ✅ Backend: API endpoints + database
- ✅ Frontend: API calls, Redux state syncing

**End-to-End Tests:**
- ✅ Full flow: user login → ingest transaction → view dashboard → set budget → edit category
- ✅ Error scenarios: invalid input, rate limit, network timeout

**Coverage Target:** 75% overall (backend 85%, frontend 65% acceptable for UI)

---

## 6. User Story Map

### Phase 1: Core (Week 1-2)
1. User registers and logs in
2. User sends iOS Shortcut notification → transaction ingested & categorized
3. User views transaction log
4. User edits transaction category
5. User views dashboard (total spent)

### Phase 2: Budgeting (Week 2)
6. User sets monthly budget per category
7. User views budget progress on dashboard
8. User gets alert when near/over budget

### Phase 3: Analytics (Week 3)
9. User views spending trends
10. User sees unusual transactions flagged
11. User sees recurring charges detected

### Phase 4: Extended (Week 4+)
12. User tracks net worth
13. User sets savings goals
14. User exports CSV

---

## 7. Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| **API Response Time** | < 500ms for GET endpoints |
| **Transaction Ingestion** | < 5s (OpenAI parsing + DB save) |
| **Dashboard Load** | < 2s |
| **Database** | Supabase Postgres |
| **Uptime** | 99% (single-region backend okay for now) |
| **Data Retention** | Indefinite (user can delete) |
| **Concurrent Users** | 1 (single-user app for now) |
| **Security** | HTTPS only, JWT tokens, env var secrets |
| **Mobile** | iPhone 12+, iOS 15+, PWA |

---

## 8. Known Constraints & Decisions

| Decision | Reason |
|----------|--------|
| **PWA not native app** | No Apple Developer account ($99/year) |
| **iOS Shortcuts (not Wallet API)** | Apple restricts Wallet API for this use case |
| **OpenAI API (not local LLM)** | Cost-effective, accurate parsing for Malaysian banking language |
| **Single-user app** | Built for Damian, can add multi-user later |
| **MYR primary (GBP later)** | Damian in KL now, moves to UK in Sept 2026 |
| **Manual net worth entry** | No banking API integration (complex auth) |

---

## 9. Success Metrics

- ✅ **Zero manual transaction entry** — 100% of transactions ingested via Shortcut
- ✅ **LLM accuracy** — OpenAI correctly categorizes ≥ 95% of transactions
- ✅ **Time to insight** — user can view full spending summary < 2 clicks from home screen
- ✅ **User adoption** — Damian uses it daily within 1 week of launch
- ✅ **Learning goal met** — Damian understands multi-agent agentic AI pipeline & can extend it

---

## 10. Future Roadmap (Out of Scope)

- [ ] Multi-user support (share budgets with spouse)
- [ ] Telegram/WhatsApp bot for quick category tags
- [ ] Banking API integration (Maybank, Touch 'n Go)
- [ ] Investing features (stock portfolio tracking)
- [ ] Tax reporting & deductions
- [ ] Mobile app (native iOS/Android)


