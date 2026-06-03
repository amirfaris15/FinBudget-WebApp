# Handoff Protocol for Multi-Agent Pipeline

**Purpose:** Define the structure, content, and format for agent-to-agent communication via handoff files.

---

## Overview

Three agents communicate sequentially via markdown files in `/handoffs/`:
1. **Backend Agent** writes → `be-summary.md`
2. **Frontend Agent** reads `be-summary.md`, writes → `fe-summary.md`
3. **QA Agent** reads both, runs tests, writes → `qa-report.md`

**If QA finds failures:** routes back to BE or FE for fixes, then re-runs.

---

## be-summary.md (Backend Agent Output)

### Purpose
Tell the FE agent: "Here's what I built. Here's how to use it. Here's what might trip you up."

### Mandatory Sections

#### 1. API Endpoints
Clear table of all endpoints. Use this format:

```markdown
### API Endpoints

| Method | Path | Request | Response | Notes |
|--------|------|---------|----------|-------|
| POST | /api/transactions | `{ notification_text: string }` | `{ id, merchant, amount, category, created_at }` | Parses & categorizes via Claude |
| GET | /api/transactions | query: `?month=2026-06&category=food` | `{ transactions: [ {...} ] }` | Paginated if > 50 items |
| PUT | /api/transactions/:id | `{ category: string }` | `{ id, merchant, amount, category }` | User can override LLM category |
```

**Why:** FE agent needs exact request/response shapes. No ambiguity.

#### 2. Database Schema
Show every table, primary keys, foreign keys, relationships.

```markdown
### Database Schema

**transactions**
- id (UUID, PK)
- user_id (FK → users)
- merchant (string)
- amount (decimal)
- category (string, enum: food|transport|entertainment|...)
- raw_notification_text (text, original input)
- created_at (timestamp)
- updated_at (timestamp)

**budgets**
- id (UUID, PK)
- user_id (FK → users)
- category (string)
- limit_myr (decimal, monthly)
- month (YYYY-MM)
- created_at (timestamp)

Relationships:
- transactions → users (many-to-one)
- budgets → users (many-to-one)
```

**Why:** FE needs to know what data exists and how to query it.

#### 3. Authentication / Authorization
How does the backend handle it? Session? JWT? API key?

```markdown
### Auth Pattern

- **Mechanism:** JWT tokens in Authorization header
- **Token format:** Bearer {JWT}
- **Payload:** { user_id, email, iat, exp }
- **Expiry:** 24 hours
- **Refresh:** POST /api/auth/refresh returns new token
- **FE expectation:** Store in localStorage, include in all requests

Unauthenticated routes:
- POST /api/auth/register
- POST /api/auth/login
```

**Why:** FE needs to know how to attach credentials to requests.

#### 4. Key Assumptions
What did you assume about FE? List them:

```markdown
### Key Assumptions

- FE will handle JWT token storage & refresh
- User is logged in before accessing transaction endpoints
- Frontend will validate form inputs (email format, amount > 0)
- Claude API key is sourced from env var, not passed by FE
- Category enum is fixed server-side (can be updated later)
```

**Why:** If FE does something different, you've flagged it early.

#### 5. Implementation Notes
What might be confusing or fragile?

```markdown
### Implementation Notes

- **LLM parsing:** Claude sometimes returns unexpected categories. FE should show "uncategorized" option if response is NULL.
- **Transaction creation timing:** Parsing may take 2-5s. Consider showing loading state.
- **Duplicate prevention:** We store raw_notification_text to detect duplicates. Don't send same text twice.
- **Rate limiting:** Claude API has per-minute limits. If FE hammers endpoint, you'll get 429 errors.
```

**Why:** FE avoids surprises and knows how to handle edge cases.

#### 6. Files Created / Modified
Quick reference so FE knows the BE structure:

```markdown
### Files Created

- backend/app.py (main FastAPI app)
- backend/models.py (SQLAlchemy models)
- backend/routes/transactions.py (transaction endpoints)
- backend/routes/auth.py (auth endpoints)
- backend/services/llm_parser.py (Claude integration)
- backend/config.py (env var loading)
```

**Why:** FE can navigate the backend codebase if needed.

#### 7. Known Issues / Blockers
Anything FE should know about that's incomplete?

```markdown
### Known Issues

- ⚠️ CSV export endpoint not implemented (low priority)
- ⚠️ Rate limiting not enforced yet (do in next sprint)
- ✅ Auth fully working
```

---

## fe-summary.md (Frontend Agent Output)

### Purpose
Tell the QA agent: "Here's what I built. Here's what I used from BE. Here's what might break."

### Mandatory Sections

#### 1. Components Built
List all new/modified React components:

```markdown
### Components Built

**Pages:**
- src/pages/Dashboard.tsx (displays budget overview, top spending categories)
- src/pages/TransactionLog.tsx (list view, supports filtering by month/category)
- src/pages/AddTransaction.tsx (manual entry form + shortcut upload)

**Shared Components:**
- src/components/BudgetCard.tsx (shows category, limit, spent, remaining)
- src/components/TransactionRow.tsx (merchant, amount, category chip)
- src/components/CategoryFilter.tsx (dropdown for category filtering)

**Hooks:**
- src/hooks/useTransactions.ts (fetch/cache transactions, handle pagination)
- src/hooks/useBudgets.ts (fetch budgets, calculate remaining)
```

**Why:** QA knows what to test.

#### 2. API Integration Points
Which components call which endpoints?

```markdown
### API Integration Points

**Dashboard.tsx:**
- GET /api/transactions?month={currentMonth} (fetch current month transactions)
- GET /api/budgets?month={currentMonth} (fetch budgets)
- POST /api/budgets (create new budget, if modal opened)

**TransactionLog.tsx:**
- GET /api/transactions?month={month}&category={category} (with filters)
- PUT /api/transactions/{id} (edit category on row click)
- DELETE /api/transactions/{id} (if delete button clicked)

**AddTransaction.tsx:**
- POST /api/transactions (manual entry)
- POST /api/transactions/upload (shortcut file upload, if implemented)
```

**Why:** QA knows which endpoints to mock/verify in tests.

#### 3. State Management
How are you managing state?

```markdown
### State Management

- **Global state:** Redux store (transactions slice, budgets slice, auth slice)
- **Local state:** React hooks for form inputs, UI toggles
- **Caching:** useQuery (React Query) with 5-min stale time for transactions
- **Async requests:** Redux Thunk middleware
```

**Why:** QA knows where to inject test data and how state flows.

#### 4. Dependencies Added
What npm packages did you add?

```markdown
### Dependencies Added

- react-query (data fetching & caching)
- redux / react-redux (state management)
- axios (HTTP client, configured with auth headers)
- react-hook-form (form validation)
- date-fns (date parsing, formatting)
- tailwind@3.4 (styling, already in project)
```

**Why:** QA knows if they need to mock these libraries.

#### 5. Key Assumptions
What did you assume the BE would do? What about the user?

```markdown
### Key Assumptions

- JWT token always in localStorage under key "auth_token"
- BE returns 401 if token expired (FE handles refresh)
- Categories are fixed set: food, transport, entertainment, ...
- Dates are ISO 8601 strings (FE parses with date-fns)
- User is logged in before accessing app (no public routes)
- Budget month is always YYYY-MM format
```

**Why:** If any of these are wrong, QA flags it immediately.

#### 6. Known Issues / TODOs
What's incomplete?

```markdown
### Known Issues / TODOs

- ⚠️ CSV export button not hooked up yet (BE endpoint pending)
- ⚠️ Responsive design not tested on mobile (Tailwind applied, but no device testing)
- ✅ Form validation working
- ✅ API error handling (shows toast on 4xx/5xx)
- TODO: Add loading skeleton for Dashboard (currently shows spinner)
```

**Why:** QA knows what not to test yet.

#### 7. Files Created / Modified
FE structure reference:

```markdown
### Files Created / Modified

**New:**
- src/pages/Dashboard.tsx
- src/pages/TransactionLog.tsx
- src/pages/AddTransaction.tsx
- src/components/BudgetCard.tsx
- src/hooks/useTransactions.ts
- src/redux/slices/transactionsSlice.ts
- src/store.ts

**Modified:**
- src/App.tsx (added routes)
- src/index.tsx (added Redux Provider)
```

---

## qa-report.md (QA Agent Output)

### Purpose
Report test results and sign-off status. If failures, route back to the right agent.

### Mandatory Sections

#### 1. Test Summary
High-level results:

```markdown
### Test Summary

- **Total:** 42 tests
- **Passed:** 39 ✅
- **Failed:** 3 ❌
- **Skipped:** 0
- **Coverage:** 78%
```

#### 2. Coverage by Module
Breakdown per layer:

```markdown
### Coverage by Module

| Module | Tests | Passed | Coverage | Notes |
|--------|-------|--------|----------|-------|
| Backend API | 18 | 18 | 85% | All endpoints working |
| Backend LLM Parser | 8 | 8 | 92% | Edge cases handled |
| Frontend Components | 10 | 8 | 65% | See failures below |
| Frontend Hooks | 4 | 3 | 70% | useTransactions flaky |
| End-to-End | 2 | 2 | 100% | Full flow working |
```

#### 3. Failures (if any)
List each failure with context:

```markdown
### Failures ❌

**1. TransactionRow component — category edit not persisting**
- Test: `src/components/__tests__/TransactionRow.test.tsx`
- Error: Expected category "food" but got "uncategorized"
- Root cause: useTransactions hook not invalidating cache on PUT
- Fix needed: **FE Agent** — add query invalidation in useBudgets.ts

**2. useTransactions hook — pagination broken on filter change**
- Test: `src/hooks/__tests__/useTransactions.test.tsx`
- Error: API called with old page number instead of resetting to page 1
- Root cause: Filter state not triggering pagination reset
- Fix needed: **FE Agent** — reset page to 0 when category/month changes

**3. Auth token refresh timing out**
- Test: `src/__tests__/e2e/auth.test.tsx`
- Error: POST /api/auth/refresh returns 500
- Root cause: Backend token issued without `exp` field (BE bug)
- Fix needed: **BE Agent** — add expiry to JWT payload
```

**Format per failure:**
- Test name & file
- What the test expected vs. what happened
- Root cause (if known)
- Which agent should fix it (BE, FE, or both)

#### 4. Test Commands
How to reproduce:

```markdown
### Test Commands

Run all tests:
```bash
npm run test
```

Run specific suite (e.g., FE components):
```bash
npm run test -- src/components/__tests__
```

Run with coverage:
```bash
npm run test:coverage
```

Run E2E tests (requires backend running on http://localhost:8000):
```bash
npm run test:e2e
```
```

#### 5. Sign-Off Status
Final verdict:

```markdown
### Sign-Off Status

🔴 **NOT READY FOR PRODUCTION**

**Blockers:**
1. Auth token refresh timeout (BE must fix)
2. Transaction category edits not persisting (FE must fix)

**Next Steps:**
1. Route to **BE Agent** → fix JWT expiry
2. Route to **FE Agent** → add query invalidation
3. QA re-runs tests after fixes
```

Or if all green:

```markdown
### Sign-Off Status

✅ **READY FOR STAGING / PRODUCTION**

All tests passing. Coverage 78% (target: 75%). No blockers.

Next: Deploy to staging, run smoke tests, proceed to production.
```

---

## Template Checklist for Agents

Before submitting a handoff file, the agent should verify:

### Backend Agent (be-summary.md)
- [ ] All endpoints documented with request/response examples
- [ ] Database schema clear (all tables, keys, relationships)
- [ ] Auth mechanism explicitly stated
- [ ] Key assumptions about FE behavior listed
- [ ] Implementation notes for edge cases included
- [ ] Files created/modified referenced
- [ ] Known issues / blockers noted

### Frontend Agent (fe-summary.md)
- [ ] All new components listed with file paths
- [ ] API integration points mapped (which component calls which endpoint)
- [ ] State management approach clear
- [ ] Dependencies added listed
- [ ] Assumptions about BE responses documented
- [ ] Known issues / incomplete features noted
- [ ] Files created/modified referenced

### QA Agent (qa-report.md)
- [ ] Test summary (total | passed | failed | skipped)
- [ ] Coverage broken down by module
- [ ] Each failure has: test name, error, root cause, which agent to fix
- [ ] Test commands provided (how to reproduce)
- [ ] Clear sign-off (✅ ready OR 🔴 blockers + next steps)

---

## Communication Tips

**For downstream agents reading handoffs:**
1. Scan headers first — find what you need quickly
2. Tables are scannable — prefer tables over prose
3. Assumptions = alerts — if you assume differently, flag it back to the previous agent
4. If something is missing, the handoff is incomplete — ask for clarification (don't guess)

**For agents writing handoffs:**
1. Be exhaustive in mandatory sections — the next agent shouldn't have to re-read code
2. Link to files where relevant (e.g., "see `backend/models.py` for schema")
3. Flag ambiguities & edge cases early
4. Keep it concise — summaries, not full documentation
