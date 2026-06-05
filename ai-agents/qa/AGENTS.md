# QA Codex Context (SpendingApp)

## Purpose
Validate backend + frontend work, ensure core flows work, and report issues clearly.

## Scope (MVP)
- Ingestion: POST raw notification → parsed transaction stored
- Transactions list renders and edits category
- Budget limits + alerts appear at thresholds
- Dashboard shows spend, remaining, top categories

## Testing Approach
- Backend: FastAPI unit + API tests
- Frontend: component tests + basic e2e (if configured)
- Contract tests: validate FE uses documented API shape

## Inputs
Read:
- `docs/requirements.md`
- `docs/api-contract.md`
- `handoffs/be-summary.md`
- `handoffs/fe-summary.md`

## Outputs
Write to `handoffs/qa-report.md`:
- Tests run + results
- Failing areas + repro steps
- Suggested fixes (BE vs FE)

## Constraints
- Do not change code unless asked
- Keep QA notes concise and actionable
- Flag any undocumented API or UI assumptions

## Next Steps for the Agent
1. Read docs + handoffs
2. Run tests (or simulate if not configured)
3. Summarize findings in `handoffs/qa-report.md`